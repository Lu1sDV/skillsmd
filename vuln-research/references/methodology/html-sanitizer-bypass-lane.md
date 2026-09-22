# HTML Sanitizer Bypass Lane (`html_sanitizer_bypass_lane`)

> **Load when:** running Phase 0.75 Defense Pre-Break and the Phase-0 `defenses` inventory
> includes HTML sanitizers, allowlists, or regex filters; or when the orchestrator needs to
> understand how the lane discovers, enriches, harnesses, and verdicts each such defense.
>
> **Strategy:** `html_sanitizer_bypass_lane` (id 11, seeded in `db/seed/strategies.yml`)
> **Phase:** 0.75 — Defense Pre-Break (runs **late** in 0.75, after `defense_base_lane` has
> warmed the `defenses` table from which this lane draws its reuse source)
> **Tiers:** Required at **MEDIUM + DEEP**

---

## Purpose

The lane catalogues **every** HTML sanitizer, allowlist, and regex filter in the target
codebase with rich, queryable labels, then drives a target-agnostic bypass corpus through
each attacker-reachable sanitizer via a PHP+JS harness and a semantic jsdom oracle — storing
a deterministic per-sanitizer verdict. It is a Phase 0.75 lane: findings are
**defense-keyed and finding-agnostic**, so the defeated-defense set is fully populated
before the first Hunt agent spawns.

---

## Position in Phase 0.75

Phase 0.75 schedules the following lanes in order. The HTML sanitizer bypass lane runs
**last** among the pre-break lanes because it depends on the `defenses` rows that the
earlier lanes populate:

1. `defense_base_lane` — Stage A enumerate → B skip-with-reason → C lazy-fetch per defence
2. `defense_context_verification_lane` — confirms the defence fires on each catalogued callsite
3. `isolation_fuzz_lane` (DEEP) — isolation-fuzz per `isolation_eligible` defence
4. **`html_sanitizer_bypass_lane`** — HTML-specific enrichment, reachability, corpus run,
   oracle verdict (MEDIUM + DEEP)

`defense_base_lane`'s earlier run is the **reuse source** for discovery step (1) below.
Scheduling the lane late in Phase 0.75 ensures those rows are present before the lane reads
them.

---

## Discovery (C1 — R14)

The lane builds its working set from the **union of three** sources. Every matched sanitizer
becomes a `defenses` row; a sanitizer found by more than one source ranks higher.

### Source 1 — Reuse existing `defenses` rows

Read the existing `defenses` rows already written by `defense_base_lane` /
`defense_context_verification_lane` for this target, filtering by the **coarse** `defense_type`
the column actually holds — `'sanitizer_function'`, `'allowlist'`, or `'blacklist'` (the
`schema.sql` CHECK admits only these three). The fine-grained `mechanism` superset
(escape / strip / allowlist / denylist / regex_filter / validator / markdown_safe) is written
**by this lane** as enrichment, so it is not available as a reuse filter on the first round;
HTML-relevance is decided by the enrichment + reachability steps below, not by the coarse type.
Set `discovery_method = 'reuse'`. No new row is created; the lane enriches the label columns on
existing rows (see Rich Labels below).

### Source 2 — HTML-sanitizer pattern sweep

Grep/AST pattern match against the target source for the constructs below. Each match that
is not already a `defenses` row → emit a new row with `discovery_method = 'pattern_sweep'`.

| Language | Patterns |
|---|---|
| PHP | `htmlspecialchars`, `htmlentities`, `strip_tags`, `preg_replace` with HTML-filter context, scheme/tag allowlist arrays, `markdown safe_mode`, `*Validator::validate` |
| JavaScript / Node | `DOMPurify.sanitize`, `xss()`, `sanitizeHtml()`, `marked` safe-mode, `.innerHTML =` guarded by allowlist |
| Python | `bleach.clean`, `html.escape`, `MarkupSafe.escape`, `defusedxml` sinks |
| Java / other | `ESAPI.encoder().encodeForHTML`, `StringEscapeUtils.escapeHtml`, `HtmlUtils.htmlEscape` |

Pattern sweep is **non-filtering**: every match produces (or enriches) a row regardless of
reachability. Completeness is the goal; reachability is a label, not a gate.

### Source 3 — AST + taint role-based discovery

Walk the existing `input_slices` and `critical_fn_reach` data to find functions that:

- appear on a path from an untrusted `sources` row to an HTML-output sink (`sink_category`
  ∈ {xss, html_render, template_output}), **and**
- have a taint role of `transform` or `validate` (i.e., the function processes attacker-
  controlled data before it reaches the HTML sink)

Each such function that is not already a `defenses` row → emit a new row with
`discovery_method = 'ast_taint'`. Functions found by both pattern sweep and AST/taint
get `discovery_method = 'ast_taint'` (most specific) and a higher `discovery_confidence`.

### Confidence scoring

| Sources that found this sanitizer | `discovery_confidence` |
|---|---|
| Only one source | 0.4 |
| Two sources agree | 0.7 |
| All three agree | 1.0 |

### Completeness check — blind spots

At the end of discovery, the lane logs a `agent_observations` row with
`obs_kind = 'blind_spot'` for every pattern that was attempted but could not be fully
resolved (e.g., dynamic dispatch to an unknown sanitizer class, a vendor blob that could
not be parsed). Blind-spot rows carry `reusable = true` so the next round skips re-deriving
them.

---

## Rich Labels on `defenses` Rows

For every row in the working set the lane enriches the following label columns from static
analysis of the matched sanitizer's source:

| Column | Values (CHECK domain in `schema.sql`) | How it is derived |
|---|---|---|
| `mechanism` | escape \| strip \| allowlist \| denylist \| regex_filter \| validator \| markdown_safe | Match function signature / logic |
| `enforcement_mode` | transform \| reject \| filter | Output differs from input → transform; exception/false → reject; partial removal → filter |
| `input_context` | html_text \| attribute \| url \| css \| js | Caller context from taint path |
| `fail_mode` | fail_open \| fail_closed | Does the function return raw input on exception? |
| `library_origin` | builtin \| framework \| thirdparty \| custom | Import path / composer/npm dependency |
| `reachability` | proven \| suspected \| none | Computed from callsite join (see below) |
| `discovery_method` | reuse \| pattern_sweep \| ast_taint | Highest-specificity source that found it |
| `discovery_confidence` | REAL 0.0 – 1.0 | Multi-source table above |

Variable-length literals (regex source, allowlist array, flags) are written into the
**existing** `parsed_logic_json` column as structured JSON: `{regex_src, allowlist[], flags, ...}`.
The coarse `defense_type` column is kept as-is — `mechanism` is the fine-grained superset
and does not replace or widen `defense_type`.

These enrichments are emitted as `agent_observations` rows anchored to the defense's
`symbol_path`; the orchestrator applies the field changes at flush (agents never mutate
rows directly).

---

## Reachability Computation (R8)

Reachability is a **stored label, not a discovery filter**. Every sanitizer is catalogued;
reachability governs which ones get the expensive corpus run.

For each `defenses` row in the working set, join its callsites against the existing
`sources` and `critical_fn_reach` data:

| Condition | `reachability` label |
|---|---|
| At least one callsite appears in a `critical_fn_reach` row with `reach_status = 'reaches'` and its source is attacker-controllable | `proven` |
| Callsite appears in a slice path but reachability is `unproven` or uncertain | `suspected` |
| No callsite found in any slice / no attacker-controllable source reaches this callsite | `none` |

**Stored + skipped for `none`:** rows with `reachability = 'none'` are stored (catalogue
completeness) but handed a documented skip rather than a corpus run. A
`agent_observations` row with `obs_kind = 'blind_spot'` records the skip reason so the
next round can re-evaluate if new sources are discovered.

---

## Engine — Out-of-Band Subprocess

The bypass corpus run is performed by the agnostic engine at:

```
engines/html-sanitizer-bypass/
  sanitizer_runner.php   # isolates the target sanitizer, runs corpus, writes out.json to tmp
  oracle.js              # jsdom semantic oracle; reads out.json, emits row-shaped JSON to stdout
  build_corpus.js        # builds versioned corpus.json from corpus_data/ families
  corpus_data/           # 21 agnostic payload family files (injection_context + input_vector tags)
  package.json           # jsdom ^29.1.1
```

The lane agent spawns the engine as a **subprocess**; corpus data and intermediate `out.json`
live in a scratch `tmpdir` that is deleted after the run. The engine emits **compact
row-shaped JSON to stdout only** — no file artifacts, no DuckDB connection. The orchestrator
is the sole DuckDB writer and flushes the row queue.

### Isolate contract

For each reachable sanitizer the lane generates a per-sanitizer **isolate shim** —
a short PHP file that `require`s the target's actual sanitizer source and exposes:

```php
function sanitize(string $input): string { … }
```

The shim runs **real target code** with no mocks, no stub structs, no patched binaries.
The isolate lives in the scratch tmpdir and is deleted with it after the run.

### Corpus

The engine consumes one shared, fixed-and-versioned corpus (`corpus.json`) built from the
21 `corpus_data/` family files. Each payload record carries:

- `injection_context` — the HTML context the payload targets (html_text / attribute_value /
  url_attr / css / js_context)
- `input_vector` — how the attacker delivers the payload (markdown_link / img_src /
  autolink / raw_html / url_param)
- `corpus_category` — the family filename (open-vocab TEXT column)
- `corpus_version` — content hash of the corpus manifest, stamped at build time

The corpus is consumed **in its entirety** against each reachable sanitizer in one batch
subprocess invocation — not synthesised per-sanitizer. Agents never ingest the corpus into
their context.

---

## Oracle (C3 — R3, R10)

After `sanitizer_runner.php` produces `out.json` (the array of per-payload sanitized
outputs), `oracle.js` parses each output in jsdom and checks for live sinks **per
injection context**:

| Condition in jsdom | `sink_reached` label | `capability` label |
|---|---|---|
| `<script>` node executes | `script_exec` | `xss_exec` |
| `on*` event handler fires | `event_handler` | `xss_exec` |
| `href` / `src` resolved to `javascript:` or `data:` | `url_scheme` | `open_redirect` or `xss_exec` |
| CSS `expression()` or `url()` loaded | `css_expression` | `xss_exec` |
| `id` / `name` attribute clobbers a global | `dom_clobbering` | `xss_exec` |
| None of the above | PASS | — |

The sink set checked is **selected per `injection_context`**: a payload targeting
`url_attr` checks `url_scheme` first; a payload targeting `html_text` checks `script_exec`
and `event_handler` first. This keeps the oracle adaptive and reduces false positives from
context mismatch.

**BYPASS** = the sanitized output, when reparsed in jsdom, reaches a live sink for its
`injection_context`. **PASS** = no live sink reached. The verdict is deterministic given
fixed corpus + jsdom version.

---

## Result Storage (C4 — R6, R7, R12)

### Per-bypass rows — `defense_bypasses`

Each BYPASS hit → one `defense_bypasses` row (emitted by oracle.js as stdout JSON, flushed
by the orchestrator). New columns populated by this lane:

| Column | Source |
|---|---|
| `sink_reached` | oracle.js: script_exec / event_handler / url_scheme / css_expression / dom_clobbering |
| `capability` | oracle.js: xss_exec / open_redirect / html_injection |
| `payload_technique` | corpus record metadata (open-vocab TEXT) |
| `corpus_category` | corpus record `corpus_category` field (open-vocab TEXT) |
| `injection_context` | corpus record `injection_context` |
| `input_vector` | corpus record `input_vector` |

PASS payloads produce no row. Large payloads (> 16 KB) spill to `db/sidecars/` via
`payload_sidecar_path`.

### Per-sanitizer aggregate — `sanitizer_bypass_runs`

After the full corpus run for one sanitizer, the oracle emits a trailing aggregate JSON
object which the orchestrator flushes as one `sanitizer_bypass_runs` row:

| Column | Notes |
|---|---|
| `defense_id` | FK → `defenses.id` of the sanitizer under test |
| `run_verdict` | `bypassed` / `clean` / `inconclusive` (CHECK constraint) |
| `corpus_version` | content hash from the corpus manifest |
| `payloads_total` | count of corpus records attempted |
| `payloads_bypassed` | count of BYPASS hits |
| `runtime_ms` | wall time of the subprocess |
| `injection_contexts_json` | array of contexts exercised |
| `inconclusive_reason` | non-NULL when `run_verdict = 'inconclusive'` |
| `emitted_bypass_ids` | JSON array of the `defense_bypasses.id` values flushed for this run |
| `sanitizer_run_hash` | UNIQUE — derived from `(defense_id, corpus_version)` at flush |
| `round_id` | FK → current `round_ledger.id` |

**3-valued verdict semantics:**

- **`bypassed`** — at least one BYPASS hit; `emitted_bypass_ids` is populated.
- **`clean`** — full corpus, zero BYPASS hits. This is a **first-class robustness result**:
  a clean verdict is stored and is never needlessly re-run for the same
  `(defense_id, corpus_version)`. Before attempting a run, the orchestrator checks for an
  existing `sanitizer_bypass_runs` row with `run_verdict = 'clean'` and the same
  `corpus_version` — if one exists, the lane records a documented skip with
  `termination_reason = 'clean_verdict_cached'` rather than re-running.
- **`inconclusive`** — isolate generation failed or the harness errored.
  `inconclusive_reason` is populated; the lane does not count this as a bypass or as clean.
  Because `sanitizer_run_hash` is keyed on `(defense_id, corpus_version)`, a retry does **not**
  insert a second row (the harness emits `INSERT … ON CONFLICT DO NOTHING`). The orchestrator
  instead **updates** the existing `inconclusive` row in place to its final `bypassed` / `clean`
  verdict via `vrdb exec` — the same status-transition discipline `gr_findings` uses — so an
  inconclusive result is superseded, never duplicated.

---

## Lane-Done Gate

The lane is complete when every `defenses` row with `reachability ∈ {proven, suspected}`
has either:

1. A stored `sanitizer_bypass_runs` row (`run_verdict` ∈ {bypassed, clean}), **or**
2. A documented skip (`agent_steps.status = 'skipped'`, non-empty `termination_reason`)
   explaining why the sanitizer could not be isolated (e.g., requires a database connection
   at runtime, dynamic dispatch not resolvable, `inconclusive` after retry).

Rows with `reachability = 'none'` are catalogued and require only their stored label — no
corpus run, no skip required.

The DEEP-tier gate is enforced by `v_required_deep_lanes` (blocking). MEDIUM requirement is
encoded in the tier-gating table in `commands/vuln-swarm.md` and this prose, consistent
with how `defense_base_lane` and siblings are handled — there is no separate
`v_required_medium_lanes` view (D3 resolution).

---

## Defeated-Defense Feed-Forward

When a sanitizer's verdict is `bypassed`, its `defenses` row enters the **defeated-defense
set** exactly as other Phase 0.75 lanes produce it. The three consumers are unchanged:

1. **Hunt (Phase 1)** — hunters do not log a `dead_end` on a path "protected" by a
   bypassed HTML sanitizer.
2. **Confirm G2 (Phase 2)** — a defence in the defeated set is non-neutralising for
   G2 purposes.
3. **Critical-function pre-rank** — if a bypassed sanitizer maps to a `critical_functions`
   row (via `defense_id` / `symbol_path`), the orchestrator raises `factor_bypass_prior`,
   recomputes `rank_score`, and schedules supplementary slices at the 0.75→1 boundary.

`clean` verdicts do NOT enter the defeated-defense set — a clean sanitizer remains a valid
G2 defence.

---

## Row-Shape Invariants

Row events emitted to the orchestrator queue follow the standard invariants:

- `target_id` is copied from the pinned audit value — the lane never invents a `target_id`.
- `defense_id` holds an id from `defenses`; it is never confused with a `sink_id`,
  `source_id`, or `critical_functions.id`.
- `sanitizer_bypass_runs.sanitizer_run_hash` is derived by the orchestrator at flush, not
  supplied by the lane agent or engine.
- `defense_bypasses` rows emitted by this lane carry the same column set as those from
  other Phase 0.75 lanes (including `round_id`); the harness FK pre-validates
  `defense_id` before insert.

**Engine stdout → DuckDB column mapping (flush-time renames and resolutions):**

- **Aggregate row** (`sanitizer_bypass_runs`): the oracle's trailing aggregate carries
  `verdict` (bypassed|clean|inconclusive) — the orchestrator MUST write this to
  `run_verdict` (rename: `verdict` → `run_verdict`). The fields `corpus_version`,
  `payloads_total`, `payloads_bypassed`, and `runtime_ms` map 1:1. The columns
  `target_id`, `defense_id`, `agent_step_id`, and `round_id` are **not** in engine stdout
  — the orchestrator populates them from the lane's run context at flush.
- **Per-bypass rows** (`defense_bypasses`): the oracle emits engine-local identifiers
  `defense_symbol` (the sanitizer's symbol path) and `payload_id` (corpus record id) which
  are NOT `defense_bypasses` columns. The orchestrator MUST resolve `defense_symbol` →
  `defenses.id` and write that id to `defense_id`; `payload_id` is used only to attach the
  payload text before flush, then discarded. The remaining per-bypass fields
  (`sink_reached`, `capability`, `payload_technique`, `corpus_category`,
  `injection_context`, `input_vector`, `payload`) map 1:1 onto `defense_bypasses` columns.
- **FK id-space discipline**: `defense_bypasses.defense_id` must hold a `defenses.id`
  value — never a `sinks.id`, `sources.id`, or `critical_functions.id`. The harness
  FK pre-validator rejects a wrong-id-space value with a clear message before insert,
  surfacing any `defense_symbol` resolution error at write time rather than query time.

---

## `agent_steps` Lifecycle

```
scheduled ──► running ──► success
                │  │
                │  └────► exhausted
                │
                └───────► failed | timed_out | skipped
```

The orchestrator inserts one `agent_steps` row with `status = 'scheduled'` and
`strategy_id = 11` during Phase 0.5 materialization. The lane transitions to `running` at
start, then to one of:

- `success` — at least one `defense_bypasses` row was flushed (bypass found).
- `exhausted` — full corpus run completed, zero bypasses (lane iterated every `proven`/
  `suspected` sanitizer without finding a bypass). The `coverage_json` MUST include:
  `sanitizers_attempted`, `sanitizers_clean`, `sanitizers_inconclusive`,
  `corpus_version`, `payloads_total`.
- `skipped` — no `proven`/`suspected` sanitizers in the target's `defenses` table; or
  PHP/Node runtime absent (recorded as a `blind_spot` observation).
- `failed` / `timed_out` — harness error or subprocess timeout.

A lane MUST NOT mark itself `exhausted` without the `coverage_json` proving every
applicable sanitizer was attempted. The orchestrator verifies this at flush.

---

## References

- Engine: `engines/html-sanitizer-bypass/` (agnostic PHP runner + jsdom oracle + corpus
  builder + corpus_data)
- Schema: `db/schema.sql` — `defenses` (new label columns), `defense_bypasses` (new label
  columns), `sanitizer_bypass_runs` (new table, migration 0009)
- Migration: `db/migrations/0009-html-sanitizer-bypass-lane.sql` (0008 is `fuzz-artifacts-and-strategy-v2`)
- Strategy seed: `db/seed/strategies.yml` — `html_sanitizer_bypass_lane` (id 11)
- Gate view: `v_required_deep_lanes` in `db/schema.sql` (DEEP blocking gate)
- Tier gating: `commands/vuln-swarm.md` § Tier Gating (MEDIUM + DEEP, Phase 0.75 row)
- Bypasses catalogue: `references/v2/bypass-catalogue.md` (stage ladder / exhaustion
  contract — phase-agnostic, applies to this lane's corpus runs)
- Logging contract: `references/v2/db-logging-and-context.md` (agent_observations,
  enrichment protocol, single-writer rule)
- Phase 0.75 doctrine: `commands/vuln-swarm.md` § Phase 0.75
