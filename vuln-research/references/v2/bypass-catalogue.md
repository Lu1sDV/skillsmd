# Bypass Catalogue — Fetch Protocol

> The known-bypass corpus lives in a **global DuckDB catalogue** (separate from per-target audit DBs), built from `vuln-research/db/catalogue/bypasses.json` via `schema.sql` + `load.sql`. Runtime path: `${XDG_DATA_HOME:-~/.local/share}/vuln-research/catalogue.duckdb`.
>
> S2 bypass-hunting lanes (spec §9) MUST query the catalogue rather than load any markdown corpus. Fetches are tiered to keep agent context minimal: enumerate cheaply, filter on tags, retrieve payloads only when actually attempting a family.

---

## 1. Schema (essentials)

```
bypasses(id, defense_type, family, description, applies_when, applies_when_tags TEXT[], examples TEXT[])
```

- `defense_type` ∈ {`sanitizer_function`, `blacklist`, `allowlist`, `logic_guard`, `generic`}
- `id` is stable (e.g., `sanitizer.encoding`, `allowlist.suffix_injection`, `logic_guard.cross_user_object_ref`) — used as the `defense_bypasses.technique` value.
- `applies_when_tags` are normalized predicate tags the lane matches against the defense's `parsed_logic_json` tag set.

> **`logic_guard` — complex logical / authorization checks (defeat ⇒ escalation).** The first three types are input-filter defenses: defeating them yields *injection* (XSS/SQLi/RCE). `logic_guard` is a real per-target defense (a stored `defenses` row, unlike the catalogue-only `generic` class) whose check **is** the access control — so defeating it yields **escalation**: crossing a user/tenant boundary or invoking a privileged function. Phase 0.75 breaks it finding-agnostically like any other defense, matched by `defense_type = 'logic_guard'` ∧ tag-overlap (it is **not** unioned via the `generic` clause). Four families:
>
> | id | class | one-line trigger | concise example |
> |---|---|---|---|
> | `logic_guard.cross_user_object_ref` | IDOR / BOLA | object id from input, no ownership/tenant predicate | `WHERE id = :id` — missing `AND owner_id = :current_user` |
> | `logic_guard.missing_function_authz` | BFLA | privileged op gated on *authenticated* not *authorized* (or nothing server-side) | `if (user != null) deleteUser()` — needs `isAdmin(user)` |
> | `logic_guard.broken_state_machine` | workflow/state escalation | later/privileged state reachable out of order; one-time token replay | `POST /checkout/confirm` before `/pay` → ships unpaid |
> | `logic_guard.confused_deputy_param_tamper` | mass assignment / TOCTOU authz | role/tenant/owner field trusted from input, or re-checked after it can change | `{"role":"admin"}` accepted on `PATCH /me` |

## 1a. Mandatory Regex Mapping (pre-bypass prerequisite)

**Every regex construction in the in-scope tree MUST be mapped into the `regexes` table
before any bypass or fuzz work begins.** The bypass and fuzz lanes consume `regexes` as
their authoritative source for ReDoS candidates and validator/filter evasion targets —
they do not re-discover regexes ad hoc. Attempting bypass work before the mapping is
complete produces an incomplete technique space and is a gate violation.

The mapping is performed by `preliminary_enumeration_lane` (Phase 0, Sweep 4). Defense
regexes — those that implement a stored `defenses` row — are linked via
`regexes.defense_id`. When targeting a defense for bypass, the lane MUST join
`regexes ON regexes.defense_id = defenses.id` to retrieve all regex patterns that
implement it, then include ReDoS and filter-evasion families in the Stage-A enumeration
for that defense.

**Completeness is enforced mechanically:** `v_coverage.regexes_unmapped` is a HARD-RED
gate that fires when `preliminary_enumeration_lane` ran but zero `regexes` rows exist for
the target. A bypass lane that runs against an unmapped target operates in violation of
this gate; the orchestrator MUST block or flag such a lane at flush.

Schema: `db/migrations/0027-regex-mapping.sql`. Role classification for `regexes.role`:
`guard` / `validator` / `filter` are defense-shaped (primary bypass targets); `parser` /
`extractor` / `router` are structural (ReDoS / input-shaping targets); `other` is the
catch-all.

## 2. Three-Stage Fetch Protocol

Lanes MUST follow this order. Each stage fetches only the columns it needs.

### Stage A — Enumerate applicable families (cheap, no payloads)

```sql
SELECT id, family, applies_when_tags
FROM bypasses
WHERE defense_type = ?
  AND (defense_type = 'generic' OR applies_when_tags && ?::TEXT[]);
```

- `?1` = the defense's `defense_type` (string).
- `?2` = parsed-logic tags extracted by Phase 0 from `parsed_logic_json`.
- Returns ≤ 10 rows per defense_type. **Do not pull `description` or `examples` here.** This is the lane's working list.
- Always union with `generic` families (cross-cutting).

### Stage B — Skip-with-reason record

Before fetching payloads, the lane records which families it will attempt and which it will skip:

```json
{
  "categories_attempted": ["sanitizer.encoding", "sanitizer.unicode_normalization"],
  "categories_skipped": [
    {"id": "sanitizer.null_byte_truncation", "reason": "sink is not byte-buffer"}
  ]
}
```

Skip reasons MUST cite either `not applicable to defense_type` or `parsed_logic shows mitigation` (spec §9.4).

### Stage C — Retrieve payload material for one family at a time

```sql
SELECT description, applies_when, examples
FROM bypasses
WHERE id = ?;
```

- One row, ~200–400 bytes.
- Fetched lazily — only when the lane is about to attempt that family in Stage 1 (corpus) or Stage 2 (LLM-anchored extension).
- The Stage 2 LLM prompt MUST receive only this row + the defense's `parsed_logic_json` — never the full catalogue.

## 3. Coverage Contract

A lane reporting `agent_steps.status = 'exhausted'` MUST have a coverage_json whose `stage1_corpus.categories_attempted ∪ stage1_corpus.categories_skipped` covers exactly the Stage-A row set for its `(defense_type, parsed_logic_tags)`. The orchestrator verifies this against a fresh Stage-A query before accepting the exhaustion.

## 4. Updating the Catalogue

1. Edit `vuln-research/db/catalogue/bypasses.json`.
2. Bump `catalogue_version` row in `schema.sql` if the schema itself changed.
3. Re-run `schema.sql` then `load.sql` (idempotent — upserts by `id`).
4. Bump `version:` in `vuln-research/SKILL.md` (minor for new family, patch for description/example fix).

## 5. Why a Global Catalogue (not a per-audit Markdown)

- **Reuse across audits.** One install, every project queries the same evolving corpus.
- **Context minimization.** Stage A returns labels only; full payload data enters context only at attempt time. Markdown corpus had to be loaded whole.
- **Coverage auditable.** Orchestrator can re-query Stage A and diff against `categories_attempted` to prove exhaustion.
- **Corpus-anchoring (R4) enforced mechanically.** LLM Stage 2 receives a single catalogue row, not free reign over a markdown file.

---

## 6. Recording the hunt: `defense_bypasses` (per-target)

> §§ 1–5 cover the **global `bypasses` catalogue** (the reusable corpus of techniques). §§ 6–8 cover the **per-target `defense_bypasses` table** in the audit DB — how a bypass lane records what it tried, how deep it went, and how a confirmed bypass feeds forward. Two different tables, two recorded columns: a per-target hit copies the catalogue's `bypasses.id` (e.g. `sanitizer.encoding`) into `defense_bypasses.technique` (§1), and the catalogue's `bypasses.family` grouping into `defense_bypasses.bypass_family`. Don't conflate the reusable corpus with the per-target hit log.
>
> **Ordering (the lane runs pre-hunt).** The bulk of bypass-hunting runs *before* the Hunt, in **Phase 0.75 — Defense Pre-Break**, which breaks the Phase-0 defense inventory **finding-agnostically**. This is possible because `defense_bypasses` is keyed on `defense_id`, **not on any finding** — the row records "this defense was bypassed," so no candidate finding need exist yet. A thin **Phase 3 — Bypass-Recheck** after Confirm re-runs only the finding-specific checks pre-break could not settle (e.g. a bypass whose viability depends on the confirmed finding's exact sink context). Both phases write the same `defense_bypasses` table with the same stage ladder and the same exhaustion contract below; only the trigger and timing differ — so §§ 6–8 apply verbatim to either phase.

### Stage-reached depth ladder

`defense_bypasses.stage_reached` records how far the hunt got on a defense (the deepest rung reached). It reuses the § 2 fetch-stage names plus an isolation rung:

| `stage_reached` | Meaning | Terminal for |
|---|---|---|
| `stage_a` | Applicable families enumerated, none committed (legitimate only when Stage A returns ∅) | — (rare) |
| `stage_b` | Attempt/skip set recorded, but every family was skipped-with-reason | a defense the corpus genuinely doesn't apply to |
| `stage_c` | ≥ 1 family's payloads fetched and attempted | **MEDIUM** normal terminal |
| `isolation_fuzz` | Escalated to the isolation harness (`isolation_fuzz_lane`, `isolation_harness_ran = TRUE`) | **DEEP** default for `defenses.isolation_eligible = TRUE` within `isolation_cost_json` budget |

DEEP drives every isolation-eligible defense to `isolation_fuzz`; MEDIUM stops at `stage_c`. A lane may not claim `exhausted` (forward-slicing-lanes.md § Termination Contract) below its tier's required rung.

## 7. Exhaustion Log

`defense_bypasses.exhaustion_log` is the machine-checkable proof that the technique space was covered — the § 3 Coverage Contract, serialized:

```jsonc
{
  "stage_a_families": ["sanitizer.encoding","sanitizer.unicode_normalization","sanitizer.null_byte_truncation"],
  "categories_attempted": [
    {"id": "sanitizer.encoding", "outcome": "bypassed", "emitted_bypass_id": 42},
    {"id": "sanitizer.unicode_normalization", "outcome": "no_bypass"}
  ],
  "categories_skipped": [
    {"id": "sanitizer.null_byte_truncation", "reason": "sink is not a byte buffer"}
  ],
  "stage_reached": "stage_c",
  "isolation_fuzz": {"ran": false, "reason": "defense not isolation_eligible"}
}
```

**Invariant (orchestrator-verified):** `categories_attempted ∪ categories_skipped` MUST equal the fresh Stage-A row set for the defense's `(defense_type, parsed_logic tags)`. At flush the orchestrator re-runs the § 2 Stage-A query and rewrites any `exhausted` lane that fails the diff to `failed` / `termination_reason = 'incomplete_coverage'`. Skip reasons obey § 2 Stage B (`not applicable to defense_type` | `parsed_logic shows mitigation`). `parsed_logic_json` snapshots `defenses.parsed_logic_json` at attempt time, so a later re-parse can detect that the defense changed under the recorded bypass.

## 8. Cascade

A reproduced bypass (`reproduced = TRUE`) is **never terminal** — it feeds three things. This is the loop closure for "the bypass hunt was shallow and wasn't used after that":

1. **Cascade-on-bypass (intra-run).** The payload becomes a new `sources` row (`source_kind = 'bypass_derived'`) that enters Phase 1 Hunt; the emitted finding/source ids are recorded in `cascade_emitted_finding_ids` / `cascade_emitted_source_ids`, and the new Hunt lane's `agent_steps.parent_step_id` points back at the bypass step (forward-slicing-lanes.md § Cascade Semantics 1). With the pre-hunt ordering this is the *common, cheap* path: a bypass found in **Phase 0.75** seeds a `bypass_derived` source that the *upcoming* Phase 1 Hunt consumes directly — no lane re-spawn, because the Hunt has not run yet. Only a bypass found by the thin **Phase 3** recheck (after the Hunt) re-enters as a fresh Hunt lane the old way.
2. **Cascade-on-critical-function (intra-run).** If the broken defense maps to a `critical_functions` row (via `critical_functions.defense_id` / `symbol_path`), the orchestrator raises that CF's `factor_bypass_prior`, recomputes `rank_score`, and re-plans its data-flow lanes **this round** when it crosses a tier (critical-function-hunt.md § 5; forward-slicing-lanes.md § Cascade Semantics 3).
3. **Feed-forward (cross-run).** The row sets `carried_from_bypass_id` and `round_id`, so the **next** round's entry fetch pre-seeds `factor_bypass_prior` before ranking (round-feedforward.md § 4). A bypass found in round N makes its critical function start round N+1 already tier-promoted.

All cascades fire at orchestrator flush (single-writer); lanes queue intents, never spawn lanes directly.
