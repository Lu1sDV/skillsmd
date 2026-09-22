# Seed Corpus Generation Lanes (`llm_seed_corpus_lane_a`, `llm_seed_corpus_lane_b`)

> **Load when:** running Phase 1.4 seed generation, understanding how the merged seed corpus
> for `boundary_fuzz_lane` is built, or debugging seed-dedup or budget-knob behavior.
>
> **Strategies:** `llm_seed_corpus_lane_a` (id TBD-next-free), `llm_seed_corpus_lane_b`
> (id TBD-next-free) — seeded in `db/seed/strategies.yml`
> **Phase:** 1.4 — preliminary seed generation (runs **before** `boundary_fuzz_lane` at 1.5)
> **Tiers:** Mandatory-attempt at **DEEP** (LOW + MEDIUM do not run this lane)

---

## Purpose

Two **identical, independent** LLM-driven lanes synthesize a seed corpus for the boundary
fuzz lane before it runs. Both lanes execute the same prompt/strategy; diversity arises
entirely from LLM stochasticity. Their output union is content-hash-deduped into
`fuzz_artifacts(artifact_kind='seed_initial')` and fed to `boundary_fuzz_lane` at Phase 1.5
as an initial corpus. The two-lane design is not redundant — empirically, two independent
draws from the same distribution produce a meaningfully wider format-family coverage than
one draw at double the budget.

The **existing inline seed mechanism** in `boundary_fuzz_lane` is unchanged and
complementary: it still generates seeds from sample/PCAP/OpenAPI sources. The Phase 1.4
lanes add an LLM-synthesized layer on top.

A **third** Phase 1.4 lane, `fuzzgpt_history_lane` (history-driven LLM fuzzing, FuzzGPT /
arXiv:2304.02014 — `references/v2/fuzzgpt-history-lane.md`), **coexists** with this dual
seed-corpus pair. It is a different technique — it mines the *target's own bug history*
into edge-case programs rather than synthesizing from input-format families — but emits the
same `fuzz_artifacts(seed_initial)` into the merged corpus. The three lanes are
complementary layers, not replacements for one another.

---

## Position in Phase 1.4

Phase 1.5 `boundary_fuzz_lane` calls `fuzz_artifacts` to hydrate its initial corpus. Phase
1.4 populates that store:

1. **Phase 1.4 — `llm_seed_corpus_lane_a`** — independent LLM seed synthesis run A
2. **Phase 1.4 — `llm_seed_corpus_lane_b`** — independent LLM seed synthesis run B
   (scheduled in parallel with A; both may run concurrently)
3. **Dedup merge** — orchestrator content-hash-dedupes the union of A ∪ B into
   `fuzz_artifacts(artifact_kind='seed_initial')`; duplicates are discarded
4. **Phase 1.5 — `boundary_fuzz_lane`** — resumes from the merged seed corpus (plus the
   existing inline seeds it generates itself)

The lanes run after the Phase 1 Hunt has populated `sources`, `sinks`, `critical_functions`,
and `input_slices` — this context is what the LLM reads to understand what input formats the
target consumes.

---

## Stop Condition (per lane)

Each lane halts at whichever comes first:

1. **Format-family coverage target** — the lane has generated at least one syntactically
   valid seed for every distinct input-format family it identified from the target's source,
   `sources` rows, and `critical_functions` registry. A format family is a distinct
   grammar/schema group (e.g., PNG chunks, JWT payloads, gRPC message shapes, archive
   headers). Coverage target is met when `coverage_json.families_covered == families_identified`.
2. **Per-lane token budget** — the lane has exhausted its budget stored as
   `run_config.value` for key `seed_corpus_budget_tokens` (tier-scaled; see Budget Knob
   below).

Both conditions are evaluated after each batch of seeds is emitted. The lane MUST NOT
continue past the budget even if format-family coverage is incomplete — budget exhaustion is
a legitimate stop, recorded as `termination_reason = 'budget_exhausted'`.

---

## Budget Knob

The per-lane token budget is a DB config knob, not a YAML constant:

| `run_config` key | Description |
|---|---|
| `seed_corpus_budget_tokens` | Per-lane LLM token budget (soft cap: stop after current batch) |

The knob is tier-scaled by the LOW/MED/DEEP multipliers already used for other config
surfaces. Because LOW does not run this lane, the effective tiers are:

| Tier | Typical multiplier | Budget |
|---|---|---|
| MEDIUM | baseline | `seed_corpus_budget_tokens` as stored |
| DEEP | 3× | 3 × `seed_corpus_budget_tokens` |

LOW receives no entry; the lane's `agent_steps` row is not scheduled at LOW.

Budget knob is stored in `run_config` (a generic key-value config table), consistent with
the DB-native determinism constraint. It is NOT stored in `scoring_config` (whose `scope`
CHECK is closed and cannot be widened in DuckDB in place).

---

## Lane Execution

### 1. Discovery — identify input-format families

From the already-populated Phase 0/1 data:

- Read `sources` rows: extract `source_kind`, `input_format` hints, and `symbol_path`
- Read `critical_functions` rows with `cf_category ∈ {parser_decoder, validator_sanitizer}`
- Read `fuzz_runs.entry_point` from any prior rounds (resume case)
- Grep the target source for grammar/schema definitions, file-format magic bytes, protocol
  headers, OpenAPI specs, proto files

Emit one `agent_observations(obs_kind='coverage_gap')` row per format family identified,
recording its name and the source of the identification. This list becomes
`coverage_json.families_identified`.

### 2. Synthesis — generate seeds per format family

For each identified format family, the LLM generates a batch of seed inputs covering:

- A syntactically valid baseline sample
- Edge-case variants: max-length fields, nested/recursive structures, boundary values
- Format-family-specific interesting values (e.g., PNG: all standard chunk types; JWT:
  alg:none, kid injection; archive: deeply nested, large header counts)

Seeds are emitted as `fuzz_artifacts` row events. Each seed:

| Column | Value |
|---|---|
| `artifact_kind` | `seed_initial` |
| `label` | `llm_seed_<family>_<n>` (lane-local label) |
| `content_hash` | SHA-256 of the seed payload bytes |
| `payload` | seed bytes (inline if ≤ 16 KB; sidecar if larger) |
| `metadata_json` | `{"format_family": "…", "lane": "llm_seed_corpus_lane_a", "rationale": "…"}` |
| `fuzz_run_id` | NULL at emission (filled by orchestrator when boundary_fuzz_lane consumes it) |

### 3. Dedup merge

After both lanes complete, the orchestrator:

1. Collects all `fuzz_artifacts(artifact_kind='seed_initial')` rows for this `target_id`
   and `round_id` emitted by lanes A and B
2. Deduplicates by `content_hash` (exact-byte dedup); the second row with a duplicate hash
   is dropped with `ON CONFLICT DO NOTHING`
3. Records the **unique-seed delta** as a metric (§ Unique-Seed Delta)

The merged corpus is what `boundary_fuzz_lane` resumes from at Phase 1.5.

---

## Unique-Seed Delta

The unique-seed delta is the diversity signal that justifies the two-lane design. The
orchestrator records it after dedup:

```jsonc
{"kind": "agent_observations", "row": {
  "target_id": 1,
  "obs_kind": "metric",
  "symbol_path": null,
  "observation": "seed_corpus_unique_delta",
  "evidence_json": {
    "lane_a_seeds": 42,
    "lane_b_seeds": 39,
    "union_before_dedup": 81,
    "unique_after_dedup": 68,
    "duplicates_dropped": 13,
    "delta_vs_single_lane": 26,
    "format_families_covered": ["png", "jwt", "zip"],
    "families_identified": ["png", "jwt", "zip"]
  },
  "reusable": true,
  "round_id": 3
}}
```

`delta_vs_single_lane` = `unique_after_dedup` − max(`lane_a_seeds`, `lane_b_seeds`). A
positive delta confirms the two-lane design added coverage beyond what one lane alone would
have produced. The orchestrator logs this even when delta = 0 — zero delta is a valid
outcome (it means both LLM draws converged) and is not a failure.

---

## Mandatory-Attempt Discipline

DEEP MUST schedule both lanes. Two legitimate end states per lane:

1. **Ran** — at least one `fuzz_artifacts(seed_initial)` row was emitted; `coverage_json`
   records `families_identified`, `families_covered`, `seeds_emitted`, `termination_reason`
   (`coverage_target_met` or `budget_exhausted`).
2. **Skipped-with-reason** — the target has no fuzzable entry point (no parser, no format
   boundary, no attacker-reachable input path). The skip reason is recorded in
   `agent_steps.termination_reason = 'no_fuzzable_entry_point'` and a `coverage_json`
   listing the recon steps that established this. A skipped lane does not emit seed rows; the
   dedup merge step is a no-op.

The bar for skipping is the same as for `boundary_fuzz_lane`: no fuzzable entry point, not
"generating seeds is hard." Both lanes MUST produce a skip-with-reason or a ran result —
silent absence is not acceptable.

When both lanes skip, `boundary_fuzz_lane` at Phase 1.5 starts from its existing inline
seed mechanism only; no change to that lane's behavior.

---

## Lane-Done Gate

A lane is complete when:

1. `agent_steps.status ∈ {success, exhausted, skipped}` with a non-empty
   `termination_reason`, **and**
2. `coverage_json` contains: `families_identified`, `families_covered`, `seeds_emitted`,
   `termination_reason`; on a skip: `reason`, `checked[]` substantiating the skip.

The orchestrator rejects a lane claiming completion without a `coverage_json` proving what
ran (or why it was skipped), rewriting the step to `failed` with
`termination_reason='incomplete_seed_coverage'`.

The DEEP gate is enforced at the `boundary_fuzz_lane` level: Phase 1.5 verifies that Phase
1.4 lanes have completed (ran or skipped-with-reason) before consuming the merged corpus.

---

## Row-Shape Invariants

- `target_id` is copied from the pinned audit value — lanes never invent a `target_id`.
- `fuzz_artifacts.artifact_kind` is `seed_initial` for all seeds emitted by these lanes;
  no other `artifact_kind` is written by Phase 1.4.
- `fuzz_artifacts.content_hash` is the SHA-256 of the seed bytes — the natural dedup key.
- Lane-A and lane-B row events are flushed by the orchestrator under a single transaction;
  the dedup merge is a second pass in the same transaction.
- Both lanes write their `fuzz_artifacts` rows with their own `agent_step_id`; the
  orchestrator populates `round_id` and `target_id` at flush, not the lane agent.
- `fuzz_run_id` is NULL at Phase 1.4 emission; the orchestrator back-fills it when
  `boundary_fuzz_lane` at Phase 1.5 claims the seeds (via a targeted UPDATE keyed on
  `target_id + artifact_kind='seed_initial'`).

**`agent_steps` status semantics for these lanes:**

- `success` — at least one seed emitted; coverage target met.
- `exhausted` — budget exhausted before coverage target met; seeds still emitted.
- `skipped` — no fuzzable entry point; `termination_reason` populated; no seeds emitted.
- `failed` / `timed_out` — harness error or LLM API failure.

---

## References

- Schema: `db/schema.sql` — `fuzz_artifacts` (`artifact_kind='seed_initial'`), `run_config`
  (budget knob), `agent_steps`
- Migration: `db/migrations/0011-seed-corpus-generation-lane.sql` (new strategies + budget
  knob seed + `schema_version`)
- Strategy seeds: `db/seed/strategies.yml` — `llm_seed_corpus_lane_a`,
  `llm_seed_corpus_lane_b`
- Consumer: `references/v2/fuzzing-lane.md` — Phase 1.5 `boundary_fuzz_lane` resumes from
  the merged corpus; inline seed mechanism still runs (complementary)
- Sibling Phase 1.4 lane: `references/v2/fuzzgpt-history-lane.md` +
  `references/methodology/fuzzgpt-history-driven-lane.md` — `fuzzgpt_history_lane`
  (history-driven LLM fuzzing, FuzzGPT/arXiv:2304.02014) coexists at Phase 1.4; mines the
  target's bug history into edge-case `seed_initial` programs (different technique, same
  artifact kind)
- Fuzz artifacts schema: `db/migrations/0008-fuzz-artifacts-and-strategy-v2.sql`
  (`fuzz_artifacts` table + `artifact_kind` open-vocab column)
- Budget knob storage rationale: `references/v2/suspicious-point-tier.md` §2 (SP uses same
  pattern — dedicated config table, not `scoring_config` whose `scope` CHECK is closed)
