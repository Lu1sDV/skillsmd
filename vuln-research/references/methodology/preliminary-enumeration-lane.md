# Preliminary Enumeration Lane (`preliminary_enumeration_lane`)

> **Load when:** running Phase 0 Decompose, or when the orchestrator needs to understand
> how the whole-tree `sources` / `sinks` / `defenses` / `critical_functions` inventory is
> produced and gated for completeness.
>
> **Strategy:** `preliminary_enumeration_lane` (id 15, seeded in `db/seed/strategies.yml`)
> **Phase:** 0 — Decompose (phase token `phase0_decompose`; runs **first**, before any Hunt
> agent and before any finding exists)
> **Tiers:** Required at **DEEP** (blocking via `v_required_deep_lanes`); signal-gated at MEDIUM

---

## Purpose

The lane produces the **exhaustive, finding-agnostic, whole-tree** inventory of every
`sources`, `sinks`, `defenses`, and `critical_functions` instance in the in-scope tree
**before the hunt** — every callsite is recorded because it is *there*, never because a
smell or a chased bug led to it. Completeness is the goal: a defense/sink/source missing
because no finding pointed at it is a lane failure, not an acceptable economy.

This is the enumeration tier the rest of the pipeline assumes. Ranking
(`v_critical_fn_ranked`, `phase0_priorities`) **orders** this complete set; it never narrows
what is enumerated. The failure this lane exists to prevent: an inventory populated only
around the bugs an agent happened to chase, leaving the completion gate GREEN against a
partial inventory because it only checks attack-coverage of whatever is stored.

---

## Discovery Protocol

The lane builds its inventory from the **union of four** sweeps over the whole in-scope
tree. Each sweep is **non-filtering** — every match is recorded regardless of suspected
reachability or exploitability. Reachability and rank are labels computed downstream, never
discovery gates.

### Sweep 1 — Whole-tree pattern sweep

Grep/AST pattern match every in-scope file for source, sink, and defense constructs per the
detected stack (`references/sinks/<lang>.md` for sinks; untrusted-input entry points for
sources; sanitizer/allowlist/blacklist/validator constructs for defenses). Each match that
is not already a row → emit a new `sources` / `sinks` / `defenses` row. The sweep covers the
tree, not a bug-adjacent neighbourhood.

### Sweep 2 — AST + taint role discovery

Walk function definitions and assign taint roles (`source` / `transform` / `validate` /
`sink`). A `validate`/`transform` function gating attacker-controlled data → a `defenses`
candidate; a function performing a dangerous operation → a `sinks` candidate; an
auth/authz/deser/validator/crypto/parser/canonicalizer function → a `critical_functions`
candidate (`cf_category` per `references/v2/critical-function-hunt.md`). Functions found by
both Sweep 1 and Sweep 2 carry higher confidence.

### Sweep 3 — Semgrep callsite sweep

Run the matched per-language Semgrep packs (curated public + custom mega-packs, e.g.
`semgrep-rules/php/`) across the tree. Each callsite hit that is not already a row → emit
one. Semgrep callsites are hypotheses to enumerate, not findings — they enter as inventory
rows, never as `gr_findings`.

### Sweep 4 — Whole-tree regex mapping (MANDATORY)

**Every single regex construction in the in-scope tree MUST be mapped** into the `regexes`
table. This is **inventory-only** at map time — no ReDoS analysis, no bypass attempts, no
fuzz work happens here. The mapping exists so the downstream defense-bypass and fuzz lanes
can find bypasses for and fuzz every regex without re-discovering them. Downstream lanes
consume `regexes` as their authoritative source; completeness is enforced by the
`regexes_unmapped` HARD-RED gate (see Completeness Contradiction Gates below).

Detection patterns to match, by language:

| Language | Construction patterns |
|---|---|
| JavaScript / Perl / Ruby | `/…/` regex literals |
| Python | `re.compile`, `re.match`, `re.search` |
| Java | `Pattern.compile` |
| JavaScript / TypeScript | `new RegExp(` |
| PHP | `preg_match`, `preg_replace`, `preg_split`, `mb_ereg`, `mb_ereg_match`, `mb_ereg_replace` |
| Go | `regexp.MustCompile`, `regexp.Compile` |
| C# | `new Regex(`, `Regex.Match`, `Regex.IsMatch` |
| Rust | `Regex::new(` |
| C++ | `boost::regex`, `std::regex` |

For each match emit one `regexes` row (schema below). If the raw pattern text exceeds 16 KB,
store it at a sidecar path and set `pattern_sidecar_path`; leave `pattern_src` empty.

**`regexes` table schema** (migration: `db/migrations/0027-regex-mapping.sql`):

| Column | Type / constraint | Notes |
|---|---|---|
| `id` | PK | |
| `target_id` | FK → `targets` | |
| `pattern_src` | TEXT | raw regex text; empty when sidecar used |
| `pattern_sidecar_path` | TEXT NULLABLE | set when `pattern_src` > 16 KB |
| `flags` | TEXT NULLABLE | e.g. `gi`, `re.IGNORECASE` |
| `file` | TEXT | in-scope file path |
| `symbol_path` | TEXT NULLABLE | enclosing function/class |
| `line` | INTEGER | source line |
| `language` | TEXT | OPEN free-text (e.g. `python`, `go`, `php`) |
| `role` | TEXT | CLOSED CHECK IN (`guard`,`validator`,`filter`,`parser`,`extractor`,`router`,`other`) |
| `defense_id` | FK → `defenses` NULLABLE | set when the regex implements a defense row |
| `created_at` | TIMESTAMPTZ | |
| NK | UNIQUE(target_id, file, line, pattern_src) | |

**Role classification:** `guard` / `validator` / `filter` are defense-shaped (the regex is
a security check). `parser` / `extractor` / `router` are structural (the regex processes or
routes data). `other` is the catch-all. When a regex directly implements a stored `defenses`
row, set `defense_id` to that row's id — this is the linkage the bypass lane uses to target
defense-implementing regexes first.

### Blind spots

Every pattern, file, or symbol the lane attempted but could not fully resolve (dynamic
dispatch to an unknown class, an unparseable vendor blob, a generated file) → a
`agent_observations` row with `obs_kind = 'blind_spot'`, `reusable = true`, so the next round
skips re-deriving it. A logged blind spot is a waivable gap; a silent miss is a broken gate.

---

## `coverage_json` Self-Attestation

When the lane finishes it stamps its `agent_steps.coverage_json` with the proof that the
sweep was exhaustive, not bug-adjacent:

| Key | Meaning |
|---|---|
| `files_swept` | count of in-scope files actually swept |
| `patterns_run[]` | the pattern/rule set names executed per language |
| `semgrep_callsites_seen` | count of Semgrep callsite hits enumerated |
| `sources_found` | `sources` rows emitted/enriched this run |
| `sinks_found` | `sinks` rows emitted/enriched this run |
| `defenses_found` | `defenses` rows emitted/enriched this run |
| `critical_functions_found` | `critical_functions` rows emitted this run |
| `regexes_found` | `regexes` rows emitted this run |

`patterns_run[]` MUST include the regex-construction detection patterns from Sweep 4
(e.g. `re.compile`, `Pattern.compile`, `regexp.MustCompile`, `/…/`, `new RegExp`,
`preg_match`, `Regex::new`, `boost::regex`, etc.) alongside the Sweep 1/3 patterns.

A lane MUST NOT report success without a `coverage_json` proving every in-scope file was
swept; the orchestrator verifies this at flush.

---

## Completeness Contradiction Gates

The lane answers to three **count-free contradiction signals** in `v_coverage` — each is a
structural cross-check that an inventory built only around chased findings will trip
(SKILL.md § DEEP Completion Gate; `references/v2/db-logging-and-context.md` § 12):

| Signal | Severity | Red-gate | Contradiction it catches |
|---|---|---|---|
| `guards_on_paths_without_defense_row` | HARD-RED | `> 0` | A guard observed on a reach path has no `defenses` row → defense enumeration under-populated |
| `validator_cfs_without_defense_link` | HARD-RED | `> 0` | A validator/sanitizer `critical_functions` row has no linked `defenses` row → defense enumeration gap |
| `dangerous_sink_cfs_without_sink_row` | HARD-RED | `> 0` | A dangerous-sink `critical_functions` row has no `sinks` row → sink enumeration gap |
| `regexes_unmapped` | **HARD-RED** | EXISTS | `preliminary_enumeration_lane` ran (≥ 1 step with status `success` or `exhausted`) but zero `regexes` rows exist for this target → Sweep 4 was skipped or incomplete. Count-free EXISTS/NOT-EXISTS check — no %-floor. Unlike `promising_lanes_unpromoted` (which is a SIGNAL), this gate is MANDATORY/HARD-RED. Schema: `db/migrations/0027-regex-mapping.sql`. |

These are completeness checks, not attack-coverage checks: they fire when the inventory
contradicts itself (a guard or critical-fn exists but its sibling inventory row does not,
or the regex sweep was never run), exactly the signature of an inventory populated only
near bugs the hunt chased.

---

## Lane-Done Gate

The lane is complete when **both** hold:

1. Every in-scope file was swept (`coverage_json.files_swept` accounts for the tree; any
   unswept file is a documented `blind_spot`), **and**
2. Each completeness contradiction signal is `0`, **or** carries a documented `blind_spot`
   observation justifying the residual (e.g. the missing `defenses` row is a vendor blob the
   sweep could not parse).

A lane with unswept files and no blind-spot record, or a non-zero contradiction signal with
no justification, is a BLOCKING gate failure at DEEP (via `v_required_deep_lanes`) and a
MEDIUM signal the orchestrator must resolve or consciously waive. The DEEP roster entry
materializes at Phase 0.5 like every other lane: a never-spawned lane stays `scheduled` and
surfaces as `MISSING`.

---

## Relationship to Downstream

This lane produces the **complete** inventory the rest of the pipeline consumes:

1. **Phase 0.5 (Plan)** — `v_critical_fn_ranked` and `phase0_priorities` **rank** this
   complete set to choose which functions get both-direction data-flow. Ranking orders,
   never narrows: a low rank de-prioritizes a row, it never removes it from the inventory.
2. **Phase 0.75 (Defense Pre-Break)** — attacks the **whole** `defenses` inventory
   finding-agnostically (`defenses_without_bypass_attempt` only makes sense against a
   complete inventory; if the inventory is partial, that gate passes GREEN over a subset).
3. **Phase 1 (Hunt)** and downstream — hunt agents enrich these rows
   (`references/v2/db-logging-and-context.md` § 7) but the enumeration itself is already
   complete before the hunt opens. The hunt narrows attention; it does not backfill the
   inventory.

The lane's contract in one line: **enumerate everything once, up front, finding-agnostically
— then let ranking and the hunt prioritise within a set that is already complete.**

---

## References

- Phase 0 writes: `commands/vuln-swarm.md` § Phase 0 — Decompose (Orchestrator writes)
- Completeness contract: `SKILL.md` § Preliminary-inventory completeness contract
- Completion gate: `SKILL.md` § DEEP Completion Gate; `references/v2/db-logging-and-context.md` § 12
- Critical-function taxonomy + ranking: `references/v2/critical-function-hunt.md`
- Roster materialization/skip/gate: `references/v2/db-logging-and-context.md` § 13
- Strategy seed: `db/seed/strategies.yml` — `preliminary_enumeration_lane` (id 15)
- Gate view: `v_required_deep_lanes` in `db/schema.sql` (DEEP blocking gate)
- Sink catalogs (Sweep 1/3): `references/sinks/<lang>.md`, `references/sinks-catalog.md`
