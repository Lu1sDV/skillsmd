# Suspicious Point Screening Tier (C9)

> A **domain-agnostic, high-recall screening tier** that sits *before* the `gr_findings` confirmation tier: a growing, coverage-gated catalog of weighted criteria over region-level vulnerability hypotheses, scored deterministically read-time by DuckDB, graduating into a `gr_findings` candidate when its taint-reach DAG closes or a reproduction lands. Source of truth: `db/schema.sql` (`suspicious_points` + `suspicious_point_factor` + `sp_factor_config` + the `v_suspicious_points_ranked` / `v_sp_factor_coverage` views) + this doc.
>
> This is **methodology, not a bundled detector.** Like every other lane, agents emit row events to the queue and the orchestrator is the single DuckDB writer. The SP tier adds **no new mandatory lane** — it is a side-output row-type emitted by the existing Phase 1 Hunt and the fuzz lanes.

---

## 0. What a Suspicious Point is

A **Suspicious Point (SP)** is a *domain-agnostic, high-recall, region-level vulnerability hypothesis*. It marks an attacker-relevant code region as worth deeper attention before any confirmation work begins.

- **Region-level, not line-level.** An SP's `description` names **control-flow LANDMARKS** — the function/region anchor (`symbol_path`), the branch/guard/loop structure, the dangerous operation reached — **never line numbers**. LLMs hallucinate line#s; landmarks re-hash stably (`region_hash`) and survive a commit that shifts the file.
- **Spans all vuln classes, fuzzing and non-fuzzing.** `vuln_class` is open vocab (`heap_overflow | sqli | ssrf | xss | sanitizer_bypass | …`). An SP can come from a static Hunt lane or a fuzz lane; the object does not assume a crash.
- **Deliberately noisy.** The SP set is *high-recall on purpose*. It holds hypotheses that are too speculative for `gr_findings` but too valuable to drop. Precision is the confirmation tier's job, not the SP tier's.

### Why a separate tier — the transferred discipline

The headline insight transferred from FuzzingBrain V2 (arXiv:2605.21779) is **not** its crash-shaped schema — it is the **recall-first discipline**. FuzzingBrain generated 1,277 SPs at a **~91% false-positive rate** yet achieved **97.2% recall** and found **9/9 hard bugs** via SP-targeted depth. The lesson: a deliberately-noisy, high-recall hypothesis set, kept *apart* from the precision-oriented confirmation table and used only to *steer depth*, finds bugs that a precision-first pipeline walks past. The SP object exists to hold that noisy set without polluting `gr_findings`.

What we **did not** adopt: the paper's crash-shaped object, its OSS-Fuzz/Redis/MongoDB/MCP-core infrastructure assumptions, its libFuzzer/C-C++-only scope, and its LLM-based deduplicator (replaced by DB-native dedup, § 5). The SP here is generalized: domain-agnostic and spanning both research modalities.

---

## 1. Lifecycle / graduation

```
emit (Phase 1 Hunt + fuzz lanes)
   →  screen (orchestrator, RECALL-FIRST: only screened_out at HIGH certainty)
        →  rank read-time (v_suspicious_points_ranked)
             →  steer Phase 1.5 fuzz targeting + Phase 2 Confirm queue
                  →  ADJUDICATE every kept SP to a verdict by report time
                        (adjudication_verdict ∈ {graduated, refuted_benign, oracle_unrun}):
                     →  GRADUATE when G1 taint-reach DAG closes OR a crash/PoC lands:
                           link one gr_findings(candidate); set sp.graduated_finding_id; five-gate Confirm takes over
                     →  REFUTED_BENIGN when its oracle ran and returned safe (a proven-invariant / intended-feature kill)
                     →  ORACLE_UNRUN only when no applicable oracle exists (RED if one exists and was never run)
        →  SCREENED-OUT  →  fuzz seed (existing fuzzing-lane.md § 10 path)
```

- **Emit.** The Phase 1 Hunt and the fuzz lanes emit SP row events alongside their existing output. No dedicated SP lane is scheduled.
- **Screen (recall-first).** The orchestrator sets `screening_verdict` to `kept` or `screened_out`. Default is `kept`: an SP is only `screened_out` **at high certainty** (a proven invariant refutes it, an intended-feature classification covers it). When in doubt, keep it — the whole point is recall.
- **Rank read-time.** `v_suspicious_points_ranked` orders the kept set within the round (§ 4). The composite is a *within-round prioritizer*, nothing more.
- **Steer.** The ranking steers Phase 1.5 fuzz entry-point selection and the Phase 2 Confirm queue order. An SP is a *lead*, not a finding.
- **Graduate.** When an SP's **G1 taint-reach DAG closes** (a real source path to the region is proven) **or a crash/PoC lands**, the orchestrator links/spawns one `gr_findings(candidate)` row and sets `suspicious_points.graduated_finding_id` to it. From that point the **five-gate Confirm doctrine is unchanged** (`references/v2/confirmation-rigor-doctrine.md`) and owns the rest.
- **Adjudicate — every kept SP reaches a verdict.** Screening is recall-first (intake), but recall is only half the loop: every `kept` SP MUST reach one of `{graduated, refuted_benign, oracle_unrun}` by report time, recorded in `suspicious_points.adjudication_verdict`. *Recall without a closing oracle is noise accumulation, not a processed queue* — a `kept` SP that neither graduated nor was driven to a verdict is an ever-growing carry that the cross-round novelty signal preferentially re-surfaces forever. `refuted_benign` means the SP's oracle ran and returned safe; `oracle_unrun` is admissible **only** when no applicable oracle exists for the SP's `vuln_class`. **A `kept` SP with an applicable oracle and no recorded oracle execution is RED** — `v_sp_oracle_coverage` (HARD-RED) flags it, and the round is not done while any such SP stands.
- **Screened-out → fuzz seed.** A `screened_out` SP is not discarded — it feeds the existing fuzz-seed path (`fuzzing-lane.md` § 10, `seed_replay`), the same way refutations do.

**The SP carries no `confirmation_status`, no PoC columns, no five-gate machinery.** Those live on `gr_findings`. The SP tier never duplicates them — `graduated_finding_id` is the one-way link, and `gr_findings` owns confirmation from graduation onward.

---

## 2. The EAV factor catalog (3 sources)

Criteria are an **open, growing set** held in an EAV store, not wide columns (DuckDB cannot `ALTER ADD … CHECK`, and "more is better" must stay cheap). Adding a criterion = one `sp_factor_config` row plus a producer — **zero `ALTER`, zero schema churn**.

`+` boost · `−` penalty · `⛔` gate. **Producer** = where the raw value comes from. **Source-3 factors are registered at `weight=0`** (inert) until their producers exist — `v_sp_factor_coverage` flags them, and they contribute nothing to the score until a producer lands and the weight is tuned up.

### Source 1 — FuzzingBrain criteria (de-crash-ified)
| `factor_name` | type | producer |
|---|---|---|
| `dangerous_sink_class` | + | `sinks` (Phase 0) |
| `attacker_input_influence` | + | `sources` + taint (Phase 0–1) |
| `uncertain_protection` | + | `defenses` gap analysis (Phase 0.75) |
| `oracle_applicable` | ⛔ | oracle catalog per `vuln_class` (*new: small mapping seed*) |
| `reachable_from_entry` | ⛔ | call graph / `critical_fn_reach` (Phase 0–1) |
| `recall_band` | + | emitting lane verdict |

### Source 2 — already in the skill (reused as factors)
| `factor_name` | type | producer |
|---|---|---|
| `factor_recurrence_prior` | + (hi) | round feed-forward |
| `factor_bypass_prior` | + (hi) | `defense_bypasses` cross-round |
| `critical_fn_rank` | + | `v_critical_fn_ranked` |
| `taint_reach_G1` | ⛔ | Confirm gate 1 |
| `defense_gap_G2` | + | Confirm gate 2 |
| `intended_feature_G3` | − | `intended_feature_classification` |
| `blind_spot` / `deferred_edge` | + | `agent_observations` / coverage carry |
| `sink_severity` | + | `sinks` |
| `config_reachable` | + | `config_state` |

### Source 3 — NEW (registered at `weight=0` until producers exist)
| `factor_name` | type | producer |
|---|---|---|
| `change_churn` | + | git (Phase L0 recency) |
| `call_depth` | + | call graph (Phase 0) |
| `guard_distance` | + | static analysis (*new producer*) |
| `complexity` | + | static metric (*new producer*) |
| `taint_fanin` | + | taint graph |
| `oracle_count` | + | oracle catalog |
| `dedup_cluster_size` | + | `suspicious_points` (DB-native) |
| `failed_poc_attempts` | + | PoC/fuzz loop |
| `proximity_to_confirmed` | + | call-graph distance to `confirmed_vulns` |
| `sink_class_base_rate` | + | `eval_corpus` history |
| `proven_invariant` | − | `agent_observations(obs_kind='invariant')` |

The knobs live in `sp_factor_config` (`weight`, `direction`, `is_gate`, `expected_producer`) — a **dedicated** table, not `scoring_config` (whose `scope` CHECK is closed and cannot be widened in place). Producers emit raw rows into `suspicious_point_factor`; the catalog says how to weigh them.

---

## 3. Read-time scoring (`v_suspicious_points_ranked`)

The score is **never stored** — it is a view, recomputed read-time from the catalog weights, exactly mirroring the `v_critical_fn_ranked` rule. DuckDB 1.1.3 has no triggers, no stored procedures, and no STORED generated columns, so the DB does the work read-time and agents only emit raw factor rows.

- **Composite** = `Σ weight × signed percentile-rank` over the non-gate factors, **WITHIN-ROUND** and **data-derived**:
  `PERCENT_RANK() OVER (PARTITION BY target_id, round_id, factor_name ORDER BY raw_value)`. Penalties (`direction = −1`) use `(1 − rank)`.
- **Gate factors** (`is_gate`) are **hard 0/1 conditions, not percentile-ranked**. An unsatisfied gate (`raw_value = 0`) **floors** the SP's score / drops it from the active queue. Gates encode "no oracle applies" or "not reachable from any entry" — conditions under which a high boost-score is meaningless.
- **Degenerate population** (n = 1 or zero-variance for a factor within the round) → deterministic neutral **`0.5`** via a `COUNT(*) OVER (…) <= 1` guard, so a lone SP isn't spuriously ranked 0 or 1.
- A scalar **`MACRO`** encapsulates the per-factor signed-rank transform, so the formula lives in **one** place (the stored-procedure substitute).

**Cross-round feed-forward carries RAW FACTORS, not the composite score.** The composite is a within-round percentile-rank — it is only meaningful relative to *this* round's population, so it cannot be compared across rounds. The durable signal is the raw factor values themselves (see `references/v2/round-feedforward.md`, fetch 7). Re-ranking next round from carried raw factors reproduces a stable score against next round's population; carrying the composite would compare apples to a different round's oranges.

---

## 4. Factor-coverage gating (`v_sp_factor_coverage`)

A registered factor that *no producer populated this round* would otherwise be scored silently-neutral — a coverage blind spot disguised as a real signal. `v_sp_factor_coverage` (mirrors `v_lane_coverage`) reports, for each `sp_factor_config` row with `weight <> 0`, whether a producer populated it this round: `ok` / `MISSING`.

**R9 refinement.** When a factor is flagged `MISSING` and the gap is genuine (the producer *should* have run for this surface but didn't), the orchestrator **may spawn a targeted Phase 0–1 preliminary lane** to fill it — rather than letting the score treat the factor as silently-neutral. That spawned lane:

- takes a **strategy id ≥ 12** (the non-seed id-space; `db/schema.sql` seeds reserve ids ≤ 11),
- is **NON-MANDATORY** — it is **not** added to `v_required_deep_lanes`, so it never gates DEEP completion,
- exists only to close a real coverage gap, not to inflate the roster.

A factor registered at `weight=0` (Source-3, no producer yet) is *inert by design* and is not a coverage failure — `v_sp_factor_coverage` only flags `weight <> 0` factors.

---

## 5. DB-native dedup

There is **no LLM deduplicator** (the paper used one; we offload it to the engine). Dedup is the natural key:

```
UNIQUE (target_id, symbol_path, vuln_class, lane, region_hash)
```

Re-emitting the same region from the same lane is an idempotent merge: `ON CONFLICT` increments `dedup_cluster_size` instead of inserting a duplicate row. `dedup_cluster_size` is therefore the **idempotent merge-hit count** — and doubles as a Source-3 boost factor (an SP independently re-emitted many times is a stronger signal). `region_hash` is the stable hash of the normalized control-flow description (§ 0), so the same region re-hashes identically across emissions and rounds.

---

## 6. Wiring summary

- **No new mandatory lane.** The SP is a side-output row-type from the existing **Phase 1 Hunt** + **fuzz lanes**. `v_required_deep_lanes` is untouched; only the optional § 4 gap-filling lane (id ≥ 12, non-mandatory) may be spawned.
- **Single-writer.** Lanes emit SP and SP-factor **row events**; the orchestrator is the only DuckDB writer and flushes per phase under one transaction. Idempotency is the UNIQUE natural keys above plus the stable `region_hash`.
- **No-file-artifacts.** SPs are DB rows, never files.
- **Read-only-determinism.** The score is a view (never stored); reads are parameterized; weights/budgets are knobs in `sp_factor_config`.

Row event shape:

```jsonc
{"kind": "suspicious_points", "row": {
  "target_id": 1,
  "round_id": 3,
  "agent_step_id": 88,
  "symbol_path": "pkg/png.readChunk:void(*Chunk)",
  "region_hash": "<sha256 of normalized control-flow landmark description>",
  "description": "length field read before bounds check; memcpy into fixed buf inside the IDAT branch",
  "vuln_class": "heap_overflow",
  "oracle": "sanitizer_crash",
  "lane": "boundary_fuzz_lane",
  "screening_verdict": "kept"
  // NO confirmation_status, NO score, NO PoC — gr_findings owns those.
  // graduated_finding_id set only on graduation; dedup_cluster_size managed by the orchestrator.
  // adjudication_verdict ∈ {graduated, refuted_benign, oracle_unrun} set by the orchestrator at adjudication (§ 1).
}}
```

The accompanying factor rows are separate events into `suspicious_point_factor` (`sp_id`, `factor_name`, `raw_value`, `evidence_ref`, `producer_lane`), one per criterion the producing lane could populate.
