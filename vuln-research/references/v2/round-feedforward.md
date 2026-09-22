# Round Feed-Forward (C7)

> How a later audit round **reuses** the prior round's work instead of recomputing it. Source of truth: `db/schema.sql` (`round_ledger` table + the `round_id` / `carried_from_bypass_id` columns on `agent_steps`, `defense_bypasses`, and `fuzz_artifacts`) + this doc. Companion: `references/v2/db-logging-and-context.md` (what gets persisted) + `references/v2/suspicious-point-tier.md` (the SP screening tier whose raw factors fetch (7) carries forward) — this doc is the *fetch* half of "more efficient fetching in next rounds."

The old pipeline ran every audit cold: it re-discovered the same sources, re-ranked the same functions, re-walked the same cleared paths, and — the gap the user flagged — a confirmed defense bypass in one run was **never used** to steer the next. A **round** is one full Phase 0→5 pass over a `(repo_url, commit_sha)`. Rounds accumulate; round N+1 opens by reading round N's residue and starting from it.

---

## 1. `round_ledger` lifecycle

The orchestrator (single writer) opens a ledger row at round entry and closes it at exit:

```sql
-- Round entry: allocate the round, chaining to the prior round on the same target.
INSERT INTO round_ledger (id, target_id, round_no, audit_run_id, effort_tier,
                          parent_round_id, started_at, priors_fetched_json)
VALUES (?, ?, ?, ?, 'deep',
        (SELECT MAX(id) FROM round_ledger WHERE target_id = ?),  -- parent = latest prior round
        CURRENT_TIMESTAMP, ?);
```

- `round_no` increments per `(target_id, audit_run_id)`; the `UNIQUE (target_id, round_no, audit_run_id)` key makes re-entry idempotent.
- `effort_tier` is stored lowercase (`'low'|'medium'|'deep'`) — the CHECK enum. (Methodology prose uses LOW/MEDIUM/DEEP for the same tiers.)
- `parent_round_id` is a self-FK chaining rounds so the fetch in § 2 can walk ancestry, not just the immediately prior round.
- Every `agent_steps` row this round sets `round_id` to this ledger id, so all artifacts (findings, observations, bypasses via their step) are scoped to the round that produced them.

At exit the orchestrator stamps `ended_at`, `seed_summary_json`, and `coverage_carry_json` (§ 3).

---

## 2. Round-entry Fetch protocol

Before Phase 0 planning, the orchestrator runs the prior-round fetch (scoped to `parent_round_id` ancestry on this `target_id`) and folds the results into the seed. Ten parameterized fetches:

```sql
-- (1) Prior confirmed findings — don't re-report; do re-test if the commit moved.
SELECT id, sink_id, source_id, finding_kind, severity, config_state
FROM confirmed_vulns WHERE target_id = ?;

-- (2) Reusable bypasses — the Ask-5 link. Reproduced bypasses pre-seed this round.
SELECT id, defense_id, bypass_family, technique, stage_reached
FROM defense_bypasses
WHERE reproduced = TRUE
  AND agent_step_id IN (SELECT id FROM agent_steps WHERE round_id IN (<ancestry>));

-- (3) Reusable reasoning — skip cleared paths, assume proven invariants, target blind spots.
SELECT obs_kind, symbol_path, body, confidence
FROM agent_observations
WHERE reusable = TRUE AND obs_kind IN ('dead_end','invariant','blind_spot','assumption')
  AND target_id = ?;

-- (4) Prior critical-function ranking — carry the registry + its factors forward.
-- Read the v_critical_fn_ranked VIEW (rank_score recomputed from scoring_config
-- weights, recurrence folded in), NOT the stored rank_score column.
SELECT symbol_path, cf_category, rank_tier, rank_score_computed,
       factor_bypass_prior, factor_recurrence_prior
FROM v_critical_fn_ranked WHERE target_id = ? ORDER BY rank_score_computed DESC;

-- (5) Prior slice coverage — know what was already walked and what was deferred.
SELECT s.slice_kind, s.callee_set_hash, a.coverage_json
FROM input_slices s JOIN agent_steps a ON a.slice_id = s.id
WHERE s.target_id = ? AND a.round_id IN (<ancestry>);

-- (6) Prior fuzz artifacts/frontiers — resume dynamic testing instead of cold-starting.
SELECT fa.artifact_kind, fa.content_hash, fa.payload, fa.payload_sidecar_path,
       fa.metadata_json, fr.entry_point, fr.engine, fr.coverage_json
FROM fuzz_artifacts fa
LEFT JOIN fuzz_runs fr ON fr.id = fa.fuzz_run_id
WHERE fa.target_id = ?
  AND fa.round_id IN (<ancestry>)
  AND fa.artifact_kind IN ('corpus_manifest','queue_checkpoint','engine_state',
                           'coverage_frontier','seed_retained','seed_symbolic',
                           'state_trace','dictionary','crash_reproducer')
ORDER BY fa.round_id DESC, fa.created_at DESC;

-- (7) Prior Suspicious-Point RAW FACTORS — carry the durable signal, NOT the composite score.
-- The SP composite is a within-round percentile-rank (data-derived, never stored); it is only
-- meaningful against the round that produced it, so carrying it would compare incomparable
-- populations. The raw factor rows are the durable signal: round N+1 re-derives its own
-- v_suspicious_points_ranked from them. Carry only the SP-specific factors — recurrence/bypass
-- priors are already carried by fetch (4)/(2). See references/v2/suspicious-point-tier.md § 4.
SELECT sp.symbol_path, sp.region_hash, sp.vuln_class, sp.lane,
       spf.factor_name, spf.raw_value, spf.evidence_ref, spf.producer_lane
FROM suspicious_point_factor spf
JOIN suspicious_points sp ON sp.id = spf.sp_id
WHERE sp.target_id = ?
  AND sp.screening_verdict = 'kept'
  AND sp.agent_step_id IN (SELECT id FROM agent_steps WHERE round_id IN (<ancestry>))
  AND spf.factor_name NOT IN ('factor_recurrence_prior','factor_bypass_prior')  -- already carried by (4)/(2)
ORDER BY sp.round_id DESC, sp.created_at DESC;

-- (8) Prior methodology blind-spots — the Phase-1.6 meta-pass output. These ARE the
-- "possible directions/lanes" the prior round's two identical-independent blindspot lanes
-- merged (union-dedup). Unconsumed directions (open_direction = promoted_to_round_id IS NULL)
-- are this round's candidate lanes, picked FIRST; both-lane agreement + recurrence rank them
-- inside the view. When the orchestrator acts on one (schedules a lane / re-prioritizes a
-- region from it) it stamps promoted_to_round_id = THIS round's id — the feed-forward closure
-- + change-visibility (which prior gaps actually became work). The view already filters/orders;
-- no <ancestry> join is needed (rows are target-scoped and carry their own promotion state).
SELECT id, gap_class, title, proposed_lane, symbol_path, agreement, dedup_cluster_size
FROM v_methodology_blindspots_ranked
WHERE target_id = ? AND open_direction;

-- (9) Prior refutations + needs_attention sightings — don't re-hunt; re-test only if moved.
-- refutations has no target_id/symbol_path/finding_hash of its own: it carries finding_id +
-- agent_step_id. Scope + identity come from the joins (gr_findings for target_id/finding_hash,
-- agent_steps for round ancestry). The moved-check fingerprint lives on finding_sightings.
SELECT f.finding_hash, f.sink_id, r.refutation_reason, fs.slice_fingerprint
FROM refutations r
JOIN gr_findings f  ON f.id = r.finding_id
JOIN agent_steps s  ON s.id = r.agent_step_id
LEFT JOIN finding_sightings fs ON fs.finding_hash = f.finding_hash
WHERE f.target_id = ? AND s.round_id IN (<ancestry>)
UNION ALL
SELECT fs.finding_hash, NULL, 'needs_attention', fs.slice_fingerprint
FROM finding_sightings fs
JOIN agent_steps s ON s.id = fs.agent_step_id
WHERE fs.target_id = ? AND fs.verdict = 'needs_attention'
  AND s.round_id IN (<ancestry>);

-- (10) Prior promising lanes — open directions the prior round's static-analysis lanes surfaced.
-- Unconsumed (open_direction), not-already-covered first; each becomes a candidate lane THIS round.
-- Acting on one stamps promoted_to_round_id = THIS round's id (feed-forward closure).
-- TWO sources enter via this same fetch:
--   (a) Distilled prior-art leads: promising_lanes rows with derived_from_cve_id /
--       derived_from_writeup_id set, emitted by Phase L-1 prior_art_intake_lane at run START.
--       Round-1 consumption stamps promoted_to_round_id.
--   (b) Overlooked-lane self-audit overflow: Phase 1.7 overlooked_lane_audit_lane cap-gated
--       SPAWNS top-N in-run; lanes beyond the cap persist here and feed forward to round N+1.
SELECT id, proposed_lane_kind, vuln_class, symbol_path, severity, promise,
       already_covered, dedup_cluster_size,
       derived_from_cve_id, derived_from_writeup_id
FROM v_promising_lanes_ranked
WHERE target_id = ? AND open_direction
ORDER BY already_covered, promise DESC;
```

> `<ancestry>` is a placeholder, **not literal SQL**. Resolve it as the set of `round_ledger.id` rows reachable from this round via `parent_round_id` — either a recursive CTE joined into the query, or a bound `?,?,…` parameter list the orchestrator builds from the ancestry it already holds. **Never** string-concatenate round ids into the query text: every value in these ten fetches binds through a placeholder (single-writer orchestrator, parameterized reads only).

Each fetch result steers planning differently:

| Fetch | Effect on this round |
|---|---|
| (1) confirmed findings | De-dup: a still-present finding is not re-hunted, only re-verified if `commit_sha` changed |
| (2) reproduced bypasses | **Re-seed `critical_functions.factor_bypass_prior`** for the broken defense's CF (§ 4) → re-ranks before planning |
| (3) `dead_end` / `invariant` | Suppress: lanes skip cleared paths and assume invariants instead of re-proving them |
| (3) `blind_spot` | **Target**: a prior coverage hole becomes this round's priority lane (often the highest-value new ground) |
| (4) CF ranking | Seed the registry so the hunt refines factors rather than rebuilding from zero |
| (5) coverage_json `deferred_edges` | Become this round's TODO — the un-walked edges are where new depth goes |
| (6) fuzz artifacts/frontiers | Resume Phase 1.5 from retained corpus/checkpoints and promote uncovered frontier nodes into this round's fuzz/directed-symbolic plan |
| (7) SP raw factors | **Re-seed `suspicious_point_factor` for kept SPs**: this round re-emits the carried raw factors so `v_suspicious_points_ranked` re-derives a within-round score from them (the composite is *not* carried — it is a within-round percentile-rank). A region many prior rounds flagged starts already factor-rich, steering Phase 1.5 fuzz + Phase 2 confirm queue first |
| (8) methodology blind-spots | **Direct**: each unconsumed merged direction becomes a candidate lane/priority THIS round (process gaps → a new/widened lane or enumeration pass; coverage gaps → slice/fuzz the named region first). Acting on one stamps its `promoted_to_round_id` |
| (9) refutations + `needs_attention` | **Suppress re-hunting**: a refuted candidate is skipped unless its `slice_fingerprint` changed (code under it moved), mirroring how fetch (1) re-tests a confirmed finding only when `commit_sha` moved. `needs_attention` sightings are re-surfaced for re-verification; they are not re-hunted from scratch |
| (10) promising lanes | **Direct**: each open, not-already-covered lead becomes a candidate lane/priority THIS round (orchestrator MAY materialize a non-mandatory `agent_step` or re-prioritize the named region); `already_covered` leads are surfaced but de-prioritized (already an SP/finding under work). Acting on one stamps its `promoted_to_round_id` |

### C1 + C2 — two sources that share the fetch (10) path

**C1 — `prior_art_intake_lane` (Phase L-1, run START).** Emits at the very beginning of a run, before Phase 0. Mines NVD/GHSA/OSV/exploit-db CVEs + web writeups for the scoped target → `cves` / `writeups` rows, then DISTILS high-yield leads into `promising_lanes` with `derived_from_cve_id` / `derived_from_writeup_id` set. Round 1 picks these up via fetch (10) and stamps `promoted_to_round_id` when a lead is acted on. Documented-skip when no scope or no network.

**C2 — `overlooked_lane_audit_lane` (Phase 1.7, run END).** Runs last among discovery phases, after the Phase 1.6 blind-spot sweep. Cap-gated SPAWNS the top-N-by-promise lanes **in-run** (cap = `fetch-budgets.yml promising_lanes row_cap × tier_multiplier`); this is the **deliberate bounded exception** to feed-forward-only doctrine. Lanes beyond the cap are NOT dropped — they persist as `promising_lanes` rows and enter round N+1 via the same fetch (10) path. Both C1 and C2 are first-class citizens of `v_promising_lanes_ranked`; the view's `ORDER BY already_covered, promise DESC` naturally interleaves them with organically-surfaced leads by promise score.

---

## 2a. Deterministic priority + per-phase budgets (#4)

The ten fetches are not poured in unbounded — they fill a **budget-capped, deterministically-ranked** seed, so the same DB state always produces the same fetched set (no nondeterministic truncation), and the only tuning surface is config, not code. The prompt-context budget also includes top accepted knowledge chunks, so the budget source list is a superset of the eight round-entry SQL fetches.

**Priority order** (highest value first), the order the orchestrator walks when filling a phase's budget:

1. **reusable observations** — `dead_end` / `invariant` / `blind_spot` (fetch 3): cheapest, highest reuse. Ordered by `hit_score DESC` (from `v_fact_hitscore`) so budget truncation keeps the objectively-most-useful rows.
2. **reproduced bypasses** — `defense_bypasses.reproduced = TRUE` (fetch 2): immediately re-seed broken defenses and their critical functions.
3. **refutations** — prior refuted candidates + `needs_attention` sightings (fetch 9): a known negative is cheaper certainty than a one-off candidate; ranked above `findings_above_recurrence_bar` so confirmed negatives are never re-hunted.
4. **fuzz resume artifacts** — retained corpus manifests/checkpoints/frontiers from `fuzz_artifacts` (fetch 6): cheapest way to avoid cold-starting Phase 1.5.
5. **prior slice coverage** — already-walked/deferred `input_slices` coverage (fetch 5): suppress repeats and target open edges.
6. **tier-1 critical functions** — from `v_critical_fn_ranked` ORDER BY `rank_score_computed DESC` (fetch 4).
7. **kept-SP raw factors** — carried `suspicious_point_factor` rows for prior-round `kept` SPs (fetch 7): re-seed the screening tier so a recurring suspect region starts factor-rich, ranked next round by `v_suspicious_points_ranked` (raw factors only — the composite is within-round, not carried).
8. **findings above the recurrence bar** — confirmed/recurring findings whose normalized `factor_recurrence_prior` clears `recurrence_bar` (fetch 1), so one-off candidates don't flood the seed.
9. **unconsumed methodology blind-spots** — `v_methodology_blindspots_ranked WHERE open_direction` (fetch 8): the prior round's merged meta-pass directions, both-lane-agreement first, fed in as candidate lanes/priorities before promising lanes.
10. **open promising lanes** — `v_promising_lanes_ranked WHERE open_direction` (fetch 10): the prior round's static-analysis leads, not-already-covered first then `promise DESC`, each a candidate lane/region-priority THIS round, ranked below blind-spots (a positive lead is opportunistic, a gap is a known hole) and above knowledge chunks.
11. **top knowledge chunks by acceptance** — `v_chunk_acceptance` ORDER BY `acceptance_score DESC` (#5: a sort key, **never a gate** — no chunk is excluded by acceptance alone).

Ties inside each source break by the source's own `ORDER BY` then `id ASC`, so the result is stable across re-runs.

**Budgets** live in **`db/seed/fetch-budgets.yml`** (alongside `scoring.yml`), granular **per fetch phase**, with hard per-source `row_caps` and a soft `token_budget` ceiling; once a phase's accumulated token estimate crosses the ceiling, lower-priority rows are dropped even if their `row_cap` was not hit. Reproduced bypasses (fetch 2) and prior slice coverage (fetch 5) are budgeted explicitly as `reproduced_bypasses` and `prior_slice_coverage`; they are not implicit unbounded structural fetches. `tier_multipliers` (LOW 0.4 / MEDIUM 0.7 / DEEP 1.0) scale every cap so the tier-gating in § 5 reuses one budget set rather than duplicating it. These are operational knobs, tunable both inter-workflow (edit the YAML) and intra-workflow (the orchestrator may scale caps by `effort_tier` mid-run).

All ten fetches still bind through placeholders (single-writer, parameterized reads) — the budget caps are `LIMIT ?` / post-fetch truncation, never string-built SQL.

---

## 2b. Realized-yield carry — effort order tracks yield, not class prestige

The fetches above carry *priors and predictions* forward (a CF's predicted rank, a lead's
predicted `promise`). The round must also carry each vein's **realized confirmed-yield** — the
count of findings that actually reached `confirmation_status='confirmed'` through that vein in
prior rounds — and fold it into next-round lane priority as a multiplicative factor. A vein
that returned **zero confirmed findings across N rounds is down-funded**; a vein with high
yield-per-effort is front-loaded. This is the realized-result complement to the prediction-only
`promise = novelty × est_severity × reachability_prior × ledger_history_factor` formula: prediction
proposes, realized yield disposes.

The motivating failure is **effort-order inversion** — when lane order tracks *bug-class
prestige* ("RCE = Critical by class") instead of yield, the highest-prestige/lowest-yield vein
consumes the most budget while the genuine bug sits in the least-funded surface, audited last.
Yield-weighting inverts that: effort follows the veins that have actually produced.

**Cold-start ramp.** Round 1 has no yield history, so realized-yield down-funding **ramps in
from round 2+** — round 1 weights by predicted severity/`promise` alone, and a vein is only
down-funded after it has had at least one round to deliver. This prevents the allocator from
starving a vein before it has had a chance to produce. The per-vein realized-yield tally is
read from the prior round(s)' confirmed `gr_findings` lineage and carried alongside the § 3
JSON columns; it lands on the same next-round priority surface the ten fetches feed. Companion
prose: [`references/v2/pipeline-architecture.md`](pipeline-architecture.md) § Promising-Lane
Feed-Forward (yield-weighted scheduling).

---

## 3. The three carry-forward JSON columns

The ledger records *what it carried* so the chain is auditable and the next round's fetch is cheap (read compact provenance, not unbounded bodies across history):

```jsonc
// priors_fetched_json — provenance, written at entry. Counts + ids, not bodies.
{"from_round_id": 3, "confirmed": [11,14], "reused_bypasses": [22],
 "reused_observations": {"dead_end": 9, "invariant": 4, "blind_spot": 2},
 "carried_cf": 17,
 "fuzz_artifacts": [91,92,104],
 "carried_sp_factors": {"kept_sps": 6, "factor_rows": 23}}  // raw SP factors re-seeded (fetch 7); composite NOT carried

// seed_summary_json — the compressed seed handed to Phase 0, written at exit.
{"cf_preseeded_bypass_prior": [{"cf_id": 5, "from_bypass_id": 22, "new_factor": 0.7}],
 "blind_spots_promoted_to_lanes": ["pkg/proto.decodeExt"],
 "dead_ends_suppressed": 9,
 "fuzz_artifacts_resumed": [91,92,104]}

// coverage_carry_json — slice coverage achieved, so re-runs skip it. Written at exit.
{"slices_fully_covered": ["<callee_set_hash>", "..."],
 "deferred_edges_open": [{"symbol_path": "pkg/h.dispatch", "reason": "unresolved_dynamic_dispatch"}],
 "fuzz_frontiers_open": [{"entry_point":"proto_dispatch", "uncovered_frontier":["parseExt"]}]}
```

---

## 4. Cross-round bypass feed-forward (Ask 5)

This is the cross-run half of the loop whose intra-run half lives in `references/v2/critical-function-hunt.md` § 5. When fetch (2) returns a reproduced bypass from a prior round:

1. The orchestrator finds this round's `critical_functions` row for the broken defense (match on `defense_id` / `symbol_path`).
2. It seeds that CF's `factor_bypass_prior` **before ranking** (so the boost is baked into `rank_score` from the start of the round, not discovered mid-run).
3. The new `defense_bypasses` rows this round set `carried_from_bypass_id` = the prior bypass's id and `round_id` = this round — preserving the chain so round N+2 sees the lineage.

The effect: a defense that was bypassed in round 3 makes its critical function start round 4 already tier-promoted, so the fuller both-directions data-flow treatment (source→CF reachability **and** CF→downstream slice) runs *first*, not last. The bypass hunt stops being a terminal artifact and becomes the next round's primary lead — directly closing "the bypass hunt … wasn't used after that."

---

## 5. Tier gating

| Tier | Round-entry fetch depth |
|---|---|
| **LOW** | Fetches (1) + (3-`blind_spot`) + **(9) refutations** — de-dup findings, inherit known coverage holes, suppress known negatives; no CF/coverage carry. Fetch (3) ordered by `hit_score DESC` from `v_fact_hitscore`. |
| **MEDIUM** | Above + (2) bypasses and (4) CF ranking + **(10) promising lanes** (open, not-already-covered leads as candidate lanes). Full `v_fact_hitscore` ordering on all reusable sources; truncation visibility (`priors_fetched_json.truncated` map written). No approximate recall. |
| **DEEP** | All ten fetches (incl. (7) SP raw factors + (8) methodology blind-spots + (9) refutations + (10) promising lanes) + full `coverage_carry_json` and `fuzz_artifacts` reconciliation + `v_fact_similar` approximate recall (soft source, lower-priority leads tagged `approximate`) + full truncation feed-forward (`blind_spot` emission for dropped reusable facts). |

### Truncation visibility (`priors_fetched_json.truncated`)

When a phase's budget cap drops rows from a reusable source, the orchestrator records it in `round_ledger.priors_fetched_json` under a `truncated` map — no silent forgetting:

```jsonc
// priors_fetched_json — provenance, written at entry (extended at MEDIUM/DEEP).
{
  "from_round_id": 3, "confirmed": [11,14], "reused_bypasses": [22],
  "reused_observations": {"dead_end": 9, "invariant": 4, "blind_spot": 2},
  "carried_cf": 17, "fuzz_artifacts": [91,92,104],
  "carried_sp_factors": {"kept_sps": 6, "factor_rows": 23},
  // Truncation map (MEDIUM+DEEP): per-source drop accounting.
  "truncated": {
    "reusable_observations": {"available": 47, "loaded": 40, "min_score_loaded": 0.31}
  }
}
```

`available` is the total rows matching the fetch query; `loaded` is the rows actually seeded (capped at `row_cap`); `min_score_loaded` is the `hit_score` of the lowest-ranked row that made it in. At **DEEP** tier, when the dropped rows are *reusable* facts, the orchestrator also emits a `blind_spot` `agent_observations` row so the truncation becomes a tracked coverage hole re-surfaced by next round's fetch (3).

The fetch is always cheaper than rediscovery — even LOW pays for itself by not re-reporting a known finding. Single-writer holds throughout: only the orchestrator reads the prior round and writes the ledger; lanes receive their slice of the seed as prompt context, never a DuckDB handle.
