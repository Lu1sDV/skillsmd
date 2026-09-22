# Per-File Vulnerability Rating (`file_vuln_rating`)

> **Load when:** running Phase 0 Decompose (first step), understanding how the audit
> worklist is ordered hottest-first, or reasoning about the `v_file_vuln_ranked` view and
> its relationship to `phase0_priorities` and the Suspicious-Point tier.
>
> **Phase:** 0 — Decompose (first step, before artifact enumeration)
> **Tiers:** All tiers (LOW / MEDIUM / DEEP)

---

## Purpose

Before any other Phase 0 work, a cheap per-file P(critical/high) rating orders the audit
worklist. Every in-scope file gets a score; the score governs queue order, never
eligibility. A low-rated file sits at the back of the queue — it is always reachable.

The rating is a two-pass design: a heuristic covers all files cheaply, and LLM triage is
spent only on the ambiguous middle band. As analysis surfaces critical points (SP regions,
findings, reachable sinks), those signals feed back as additional raw factors and the view
reranks the remaining queue — a cold file can escalate to hot mid-audit.

---

## Position in Phase 0

Phase 0 (Decompose) runs these steps in order:

1. **`file_vuln_rating` — THIS STEP** — per-file P(crit/high) heuristic + LLM triage;
   `v_file_vuln_ranked` orders the worklist
2. `defense_base_lane` / `source_sink_enumeration` — populate `sources`, `sinks`,
   `defenses` for ranked files first
3. `attention_deficit_lane` (Phase L2) — per-module heuristic (orthogonal; file rating
   is the pre-filter; attention-deficit is the per-module focus scorer)
4. Remaining Phase 0 artifact enumeration in ranked order

---

## Heuristic Signals (all files)

The heuristic runs on every in-scope file without LLM involvement. It reads the file's AST
as evidence and combines the following raw factors:

### Attention-deficit signals (reusing existing Phase L2 signals)

| Factor | Schema column | Signal |
|---|---|---|
| `security_commit_churn` | `factor_security_commit_churn` | Count of security-keyword commits touching this file (from `git log`) |
| `test_coverage_inverse` | `factor_test_coverage_inverse` | Inverse of fuzzing/testing presence (fuzz targets, test files for this path) |
| `code_glamour` | `factor_code_glamour` | Parser/crypto/auth/serialization role proxy (AST pattern match) |
| `external_exposure` | `factor_external_exposure` | File contains exported entry points reachable from `sources` rows (Phase L1 endpoint map) |
| `code_age` | `factor_code_age` | Staleness/un-revisited age signal (older un-revisited = higher attention) |

### CPG signals (when available from Phase 0 tooling)

| Factor | Schema column | Signal |
|---|---|---|
| `cpg_signal` | `factor_cpg_signal` | Composite CPG/static signal (sink density, source reachability, call-graph centrality); a single optional-producer column rather than three separate columns |

`factor_cpg_signal` is NULL when the CPG has not yet been built for this target — the view
COALESCEs to 0, so the heuristic produces a valid ordering using only the attention-deficit
signals when CPG data is absent (same pattern as Source-3 SP factors).

The file's AST is evidence the rater reads — syntax structure, export patterns, import
chains — not a separate scoring unit. The unit of rating is always the **file**.

---

## Banding

After computing raw factors for all files, the heuristic classifies each into one of three
bands:

| Band | Condition | Action |
|---|---|---|
| **Hot** | Clear-hot: multiple strong signals (e.g., security commits + sink density + external exposure) | Assigned `preliminary_band = 'hot'`; no LLM triage needed |
| **Ambiguous** | Mixed or borderline signals | LLM triage pass (§ LLM Triage) |
| **Cold** | Clear-cold: few/no signals | Assigned `preliminary_band = 'cold'`; no LLM triage needed |

The band boundaries are not fixed thresholds — they are computed as a within-target
percentile split (e.g., top 20% hot, bottom 30% cold, middle 50% ambiguous). The
orchestrator applies these splits heuristically; the exact percentages are operational
choices, not schema-enforced constants.

LLM budget is spent only on the ambiguous middle. On a large repo, this keeps LLM cost
proportional to uncertainty, not file count.

---

## LLM Triage (ambiguous band only)

For each ambiguous file, the LLM:

1. Reads the file's AST summary (function signatures, import list, exported symbols, key
   data-flow patterns — not the full source unless the file is small)
2. Estimates P(critical/high finding) for this file given the signals already computed
3. Emits an `llm_triage_score` (REAL 0.0–1.0) and a one-line `rationale`

The triage output is one additional raw factor (`llm_triage_score`) stored alongside the
heuristic factors. It does not replace the heuristic — both are raw factors in the view.

---

## Storage — Raw Factors, No Stored Score

Scores are **never stored**. Raw factors are stored; the read-time view computes the
ranking. This matches the Suspicious-Point no-stored-score pattern (`v_suspicious_points_ranked`).

Raw factors are stored in a file-level artifact table. If `phase0_priorities.artifact_kind`
is not a closed CHECK, a new `artifact_kind = 'file_vuln_rating'` row is added there
(one row per file, carrying factors in a `factors_json` column). If `artifact_kind` is a
closed CHECK that cannot be widened in DuckDB in place, a small companion table
(`file_vuln_factors`) is created via a recreate-migration — the "unavoidable" case per the
spec constraint.

The storage decision is determined at migration time by inspecting the CHECK constraint on
`phase0_priorities.artifact_kind`. Either path produces the same raw-factor surface; only
the table name differs.

---

## Read-Time View — `v_file_vuln_ranked`

`v_file_vuln_ranked` orders files hottest-first within the current round. It is a read-time
view, never materialized. It follows the same pattern as `v_critical_fn_ranked` and
`v_suspicious_points_ranked`:

- **Composite** = `Σ weight × percentile-rank` over the raw factors, within-round and
  data-derived: `PERCENT_RANK() OVER (PARTITION BY target_id, round_id ORDER BY <factor>)`.
- Factor weights are **hardcoded in `v_file_vuln_ranked`** (0.55 / 0.20 / 0.15 / 0.10
  across the four factor groups). Unlike `v_suspicious_points_ranked` — whose weights live
  in `sp_factor_config` — the file-vuln view uses fixed view-internal weights. To change
  weighting, edit the view definition; the raw-factor rows require no DML.
- Files with more raw-factor data rank more reliably; files with only heuristic signals
  rank by heuristic alone until CPG/analysis data arrives.

The view is the canonical worklist order. The orchestrator reads it to determine which files
to dispatch to Phase 0 enumeration lanes first.

---

## ORDER-ONLY: No Gates

The file rating is an ordering mechanism, never a gate:

- A `cold` file is never excluded from analysis — it sits at the back of the queue.
- A file with no rating (e.g., generated code, vendor blobs) defaults to `preliminary_band
  = 'cold'` and sits at the back.
- Every in-scope file is eventually analyzed; low rating only means it is analyzed later.

This is the same principle as Phase L2 attention-deficit mapping (which orders per-module
fan-out depth) — the rating provides focus, not exclusion.

---

## Analysis Feed-Back (Rerank)

After analysis starts and populates SP regions, findings, and reachable sinks, those signals
feed back as additional raw factors for files not yet analyzed:

| Analysis signal | Feed-back schema column |
|---|---|
| SP emitted for a region in file F | `factor_sp_region_density` += 1 on file F |
| `gr_findings` candidate linked to file F | `factor_finding_proximity` += 1 on file F |
| `critical_fn_reach` row points to file F | `factor_reachable_sink_count` += 1 on file F |

These are additional raw-factor rows written by the orchestrator at each phase boundary. The
view reranks automatically because it reads raw factors at query time. A file initially
classified cold can escalate to the top of the queue when analysis reveals it as an
intermediate step in a critical-function reach chain.

---

## Relationship to `phase0_priorities` and the Suspicious-Point Tier

| Layer | Unit | Scope | Purpose |
|---|---|---|---|
| `file_vuln_rating` (this doc) | File | Phase 0 worklist | Orders files for initial decomposition |
| `phase0_priorities` | Artifact (source/sink/defense/slice/CF) | Phase 0 artifact ranking | Orders artifacts within a file for deep analysis |
| `v_suspicious_points_ranked` | Region (landmark) | Phase 1–2 | Steers Hunt depth and Confirm queue |

The three layers are orthogonal: file rating narrows which file the next agent works on,
`phase0_priorities` orders which artifacts within that file are analyzed first, and the SP
tier steers depth within the region identified by artifact analysis. A high-rated file
generates higher-confidence `phase0_priorities` artifacts earlier; those artifacts feed the
SP tier. No layer gates another — all three are ordering surfaces.

---

## Lane-Done Gate

Phase 0 decomposition may begin as soon as `v_file_vuln_ranked` is populated (at least a
heuristic score exists for every in-scope file). The LLM triage pass for the ambiguous band
completes asynchronously — partial triage is acceptable as a start signal, because the view
reranks as triage results arrive.

The rating pass is complete when:

1. Every in-scope file has at least heuristic raw-factor rows stored, **and**
2. `coverage_json` on the rating step records: `files_scored`, `hot_count`, `cold_count`,
   `ambiguous_count`, `llm_triaged_count`, `families_skipped[]` (vendor/generated blobs).

---

## Row-Shape Invariants

- `target_id` is copied from the pinned audit value.
- One raw-factor set per file per round; re-scoring the same file in the same round is an
  idempotent upsert keyed on `(target_id, file_path, round_id)`.
- `preliminary_band` is a string label written once by the heuristic pass; it does not
  change when analysis feed-back adds new raw factors (the view reranks without altering the
  label).
- `v_file_vuln_ranked` ranks ALL files for the current `target_id` and `round_id`; a query
  without a `LIMIT` clause returns the full ordered worklist.
- Factor weights are in the config table; changing a weight re-ranks without any DML on the
  raw-factor rows.

---

## References

- Schema: `db/schema.sql` — `file_vuln_ratings` companion table (companion, not
  `phase0_priorities` extension — the `artifact_kind` CHECK is closed),
  `v_file_vuln_ranked` (read-time view with hardcoded weights)
- Migration: `db/migrations/0012-file-vuln-rating.sql`
- Attention-deficit signals: `references/phases/attention-deficit.md` (Phase L2 per-module
  heuristic — this lane reuses the same signal taxonomy at file granularity)
- SP no-stored-score pattern: `references/v2/suspicious-point-tier.md` §3 (template for
  raw-factor + read-time view design)
- `phase0_priorities` ranking: `references/v2/critical-function-hunt.md` (artifact ranking
  within a file once decomposed)
- DB-native determinism: `db/seed/scoring.yml` (weight surface precedent)
