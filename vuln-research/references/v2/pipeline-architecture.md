# v2 Pipeline Architecture — Full Spec

> Canonical reference for the DuckDB-persisted phase pipeline, schema gates, row-shape
> invariants, and mandatory roster. Pointed to by SKILL.md; do not duplicate load-bearing
> contracts there.

---

## Numbering Schemes — Legend

Three coexist; neither supersedes the others:

| Scheme | Range | Scope |
|--------|-------|-------|
| **v2 Phase 0–5** | 0, 0.5, 0.75, 1, 1.4, 1.5, 1.6, 2, 3, 4, 5 | DuckDB pipeline phases — orchestrator + swarm row production |
| **swarm P / P2a / P2.5** | P0–P4 (legacy) | swarm-pipeline.md notation; largely superseded by v2 Phase labels — cross-reference `references/methodology/swarm-pipeline.md` § Effort Tiers |
| **L0–L8** | L0–L8 | Audit methodology lanes — what a researcher walks through; orthogonal to v2 phases, both coexist in one audit |

---

## Phase Table

The skill runs a DuckDB-persisted phase pipeline. Every artifact (sources, sinks, defenses, critical functions, slices, critical-function reachability, agent steps, agent observations, findings, refutations, audit outcomes, critic notes, knowledge chunks, defense bypasses, fuzz runs, fuzz artifacts, suspicious points, suspicious-point factors, suspicious-point factor config, round ledger) lives in a single DuckDB database keyed by stable hashes. Schema: [`db/schema.sql`](../../db/schema.sql). Forward-only migrations: [`db/migrations/`](../../db/migrations/). Oversize payload sidecars: `db/sidecars/` today → `.vuln-research/sidecars/` once the workspace follow-on lands (any payload > 16 KB stored on disk, referenced by `payload_sidecar_path`; see *Workspace Convention* below).

| Phase | Name | Writers | What it produces |
|---|---|---|---|
| **L-1** | Prior-Art Intake | orchestrator | `cves` + `writeups` rows mined from NVD/GHSA/OSV/exploit-db + web writeups for the in-scope target; high-yield leads DISTILLED into `promising_lanes` (provenance cols `derived_from_cve_id` / `derived_from_writeup_id`); consumed by Round 1 via fetch (10). **Bug-bounty-mode mandatory when scope provided**; documented-skip when no scope or no network. Schema: `db/migrations/0026-prior-art-intake.sql` |
| **0** | Decompose | orchestrator | **first step:** a preliminary per-file vuln-probability rating (cheap heuristic P(crit/high) over every in-scope file, LLM triage on the ambiguous middle band) that **orders** the audit worklist read-time via `v_file_vuln_ranked` and **never gates** (a low/absent rating de-prioritizes but never excludes); then opens `round_ledger` (+ prior-round priors fetch); `sources`, `sinks`, `defenses` (**exhaustive, finding-agnostic — every callsite in the whole in-scope tree, not just near suspected bugs**), `critical_functions` (**exhaustive enumeration, then ranked**), `phase0_priorities`, `intended_feature_classification` (Semgrep + LLM batch) |
| **0.5** | Plan | orchestrator | `input_slices` (incl. `critical_fn_forward`), `critical_fn_reach` (source→CF reachability), scheduled `agent_steps` |
| **0.75** | Defense Pre-Break (MEDIUM+) | swarm → queue → orchestrator flush | `defense_bypasses` against the Phase-0 defense inventory, **finding-agnostically** — defeated-defense set relaxes Confirm's G2 and feeds the Hunt (DEEP drives every isolation-eligible defense to isolation-fuzz exhaustion). DEEP also runs `concolic_bypass_lane` (C/C++/Java) — symbolic+concolic solving of a guard's path constraints to synthesize an input that passes a regex/sanitizer guard yet reaches the guarded function (`defense_bypasses(reproduced=true)`) |
| **1.4** | Seed-Corpus Generation (DEEP) | swarm → queue → orchestrator flush | two identical, independent LLM seed-corpus lanes (`llm_seed_corpus_lane_a`, `llm_seed_corpus_lane_b`) → `fuzz_artifacts(artifact_kind='seed_initial')`, union deduped by `content_hash`; runs **before** Phase 1.5 consumes the merged corpus (complements the existing inline seed mechanism) |
| **1** | Hunt | swarm → queue → orchestrator flush | `gr_findings` (status=candidate), `agent_observations` (reasoning capture + enrichment of preliminary artifacts) |
| **1.5** | Fuzzing (DEEP) | swarm → queue → orchestrator flush | `fuzz_runs` (per-run config/coverage/skip accounting) + `fuzz_artifacts` (resumable corpus/checkpoints/frontiers) + `gr_findings` (`finding_kind='fuzz_crash'` or `fuzz_divergence`); mandatory-attempt crash/divergence discovery with applicable engines + sanitizers, after checking for an existing pipeline |
| **1.6** | Methodology Blind-Spot Sweep (DEEP) | swarm → queue → orchestrator flush | runs **after all discovery sweeps** (Phase 1 Hunt + Phase 1.5 Fuzzing). Two **identical, independent** lanes (`methodology_blindspot_lane_a`, `methodology_blindspot_lane_b`) answer one question — *"find any blind spot in our codebase-analysis methodology"* — critiquing **process gaps** (HOW we analyzed) and **coverage gaps** (WHAT we never reached), clearly separated by `gap_class`. Their output is **merged by content-hash union-dedup** into `methodology_blind_spots` (agreement=`both` when both lanes flag the same gap); the ranked directions **feed forward into the next round** (`v_methodology_blindspots_ranked`) and do **not** spawn work this run |
| **1.7** | Overlooked-Lane Self-Audit (DEEP) | swarm → queue → orchestrator flush | runs **after Phase 1.6**, before Confirm — the LAST discovery step. One lane (`overlooked_lane_audit_lane`, strategy 26) asks two self-questions: *"what high-yield lanes did we not run?"* (generative) and *"did we erroneously ignore a lane?"* (audit). DB-grounded: diffs roster vs `agent_steps`, inspects emitted-but-unpromoted `promising_lanes`, and reads `v_coverage`/enumeration signals. ALWAYS emits ≥ 1 `promising_lanes` row, then cap-gated SPAWNS the top-N-by-promise lanes IN-RUN (cap = `fetch-budgets.yml promising_lanes row_cap × tier_multiplier` — no magic constant); overflow feeds forward via fetch (10). The in-run spawn is the **deliberate bounded exception** to feed-forward-only doctrine. Schema: `db/migrations/0028-overlooked-lane-audit.sql` |
| **2** | Confirm | swarm → queue → orchestrator flush | `gr_findings` status updates + `refutations` — **no finding is set `reproduced=true`/`confirmed` until an adversarial, DAG-independent refutation has RUN and FAILED to refute it** (default-skeptical; over-claiming is the documented failure mode — see [`references/v2/confirmation-rigor-doctrine.md`](confirmation-rigor-doctrine.md)) |
| **3** | Bypass-Recheck (thin) | swarm → queue → orchestrator flush | finding-specific `defense_bypasses` only where Phase 0.75 pre-break could not settle a defense in the confirmed finding's exact sink context + intra-run cascade triggers (cascade-on-bypass / cascade-on-reach) |
| **4** | Proof | swarm → queue → orchestrator flush | `gr_findings.payload`, `audit_outcomes` |
| **5** | Report | critic agent → orchestrator | `critic_findings`; final report |

---

## Load-Bearing Rules

### Preliminary-Inventory Completeness Contract

Phase 0's `sources`, `sinks`, `defenses`, and `critical_functions` are **whole-tree enumerations, not by-products of bug-hunting** — enumerate every instance in scope *before* any finding is chased; a defense/sink/source is recorded because it is *there*, never because a smell led to it. Ranking (`v_critical_fn_ranked`, `phase0_priorities`) orders this complete set; it never narrows what is enumerated. The completion gate enforces this two ways: `preliminary_enumeration_lane` must materialize and run (or record a documented skip), and `v_coverage`'s count-free contradiction signals (`guards_on_paths_without_defense_row`, `validator_cfs_without_defense_link`, `dangerous_sink_cfs_without_sink_row`) flag an inventory populated only around chased findings.

### Single-Writer Rule (load-bearing)

The orchestrator is the only DuckDB writer. Swarm agents emit row-shaped JSON events to an in-memory queue; the orchestrator flushes per phase under one transaction. This preserves idempotency (every NK has a UNIQUE constraint, every payload row has a stable hash) and lets re-runs over the same `commit_sha` update rather than duplicate.

### Incremental Lane Checkpointing (narrows the queue-loss window)

"Flush per phase" is the transaction boundary, **not** a license to batch every lane's events to phase-end. The orchestrator flushes each lane's `agent_steps` status transition (`scheduled → running → completed/skipped`) **plus that lane's row-events incrementally, the moment the lane completes** — still single-writer (the orchestrator alone writes), but the in-memory queue is drained per-lane so an OOM/crash mid-phase loses at most the one in-flight lane, not the whole phase. On crash/OOM **resume**, read `agent_steps.status` + `round_ledger` to re-enter at the last completed lane and re-spawn only what is still `scheduled`/`running`. Rationale: OOM-resumed workflows that batched to phase-end produced no output file and left lanes `MISSING` in the gate, because the queue evaporated with the process. See [`references/v2/db-logging-and-context.md`](db-logging-and-context.md) § 1.

### RAM-Aware Concurrency — Weight Lanes by Host Memory, Not Token Budget

Classify each lane by the process weight it spawns and cap concurrency accordingly:

| Weight | Lanes | Concurrency cap |
|---|---|---|
| **HEAVY** | own JVM / large process — Joern/CPG slicing, Jazzer/fuzzing, concolic KLEE/SymCC | **≤ 2 concurrent**; default to sequential small batches |
| **MEDIUM** | large-fetch LLM lanes (full module fan-out, big context loads) | ~4–6 concurrent |
| **LIGHT** | thin LLM lanes, short queries | higher fan-out OK |

Rationale: 10 concurrent Opus agents OOM-killed a DEEP run (single `parallel()` barrier) — the Joern JVM alone exhausts host memory at scale. Default HEAVY to sequential batches of 2; widen MEDIUM/LIGHT only after HEAVY tenants drain. Weight tiers are seeded in [`db/seed/fetch-budgets.yml`](../../db/seed/fetch-budgets.yml) (`lane_weights`).

### DuckDB Is the Sole Source of Truth — No File Artifacts

Subagents MUST NOT write any intermediate or output files during a run (`.txt`, `.json`, `.md`, `.csv`, or any other extension): no `COPY … TO '<file>'`, no shell redirects, no scratch files. All data flows through the queue → orchestrator flush path. Any violating subagent's output is rejected; the orchestrator flags it as a `blind_spot` observation.

---

## Workspace Convention — `.vuln-research/` (Target Convention, Not Yet Wired)

**Status: design target, not yet implemented.** The Go harness + engines still hardcode the old scattered paths (`db/sidecars/`, `db/harness/temp/`, `~/.local/share/vuln-research/` for the catalogue, per-engine tmpdirs) and do **not** yet resolve under `.vuln-research/`. The workspace below is the **intended** consolidation layout; rooting every disk write there is an enumerated follow-on. Until that follow-on lands, the live locations are the harness-hardcoded paths, not the `.vuln-research/` paths below.

The target layout — a single `.vuln-research/` directory at the **audited repo's root** — does **not** relax the subagent rule; subagents still emit via queue → orchestrator → DuckDB only.

| Path (target convention) | Holds | Current live location |
|---|---|---|
| `.vuln-research/<run>.duckdb` | the per-run audit DB(s) | scattered / harness-configured |
| `.vuln-research/catalogue.duckdb` | the bypass catalogue, per-repo | `~/.local/share/vuln-research/` |
| `.vuln-research/sidecars/` | oversize payload sidecars (> 16 KB) | `db/sidecars/` |
| `.vuln-research/tmp/` | scratch / ad-hoc analytics output | `db/harness/temp/` |
| `.vuln-research/fuzz/` | fuzz corpora + crashes | per-engine scattered |
| `.vuln-research/build/` | C5 instrumented/concolic targets | per-engine scattered |
| engine tmpdirs | per-engine scratch (e.g. `engines/html-sanitizer-bypass/`) | scattered |

The catalogue is **per-repo** — an accepted trade-off losing cross-target sharing.

---

## Extended Pipeline Doctrine

### Bypass Doctrine: "There Always Is a Bypass"

**Phase 0.75 (Defense Pre-Break)** runs *before the Hunt*, attacking the Phase-0 defense inventory *finding-agnostically* (`defense_bypasses` is keyed on `defense_id`, not on any finding): the defeated-defense set feeds the Hunt and relaxes Confirm's G2, and only finding-specific gaps spill to the thin **Phase 3 (Bypass-Recheck)**. A bypass lane reporting `exhausted` MUST have evidence it iterated every applicable corpus family on the target `defense_type`. **The corpus spans both input-filter defenses (`sanitizer_function`/`blacklist`/`allowlist`, defeat ⇒ injection) and complex logical / authorization checks (`logic_guard`, defeat ⇒ *escalation*)** — the guard *is* the access control, so breaking it crosses a user/tenant boundary or reaches a privileged function. Four `logic_guard` families: cross-user object access / IDOR-BOLA (`WHERE id=:id` with no `AND owner_id=:current_user`), missing function-level authz / BFLA (`if (user != null) deleteUser()` — needs `isAdmin`), broken state machine (`POST /checkout/confirm` before `/pay`), and confused-deputy / parameter-tampering (`{"role":"admin"}` accepted on `PATCH /me`). The Stage-2 LLM is a corpus-anchored oversight agent — it may **not** detach from the known-bypass corpus to invent novel categories. Categories, payload patterns, and `parsed_logic_json` triggers live in the per-repo catalogue (`bypasses` table in `.vuln-research/catalogue.duckdb`). Source: [`db/catalogue/bypasses.json`](../../db/catalogue/bypasses.json); schema + loader: [`db/catalogue/schema.sql`](../../db/catalogue/schema.sql) + [`db/catalogue/load.sql`](../../db/catalogue/load.sql); tiered fetch: [`references/v2/bypass-catalogue.md`](bypass-catalogue.md). **Every regex in the in-scope tree MUST be mapped into the `regexes` table** (the 5th `preliminary_enumeration_lane` category, inventory-only) so the bypass/fuzz lanes can find ReDoS / validator-filter evasion; enforced by `v_coverage.regexes_unmapped` (HARD-RED). See [`references/v2/bypass-catalogue.md`](bypass-catalogue.md) and [`references/methodology/preliminary-enumeration-lane.md`](../methodology/preliminary-enumeration-lane.md).

### Critical-Function Registry + Forward Data-Flow

Phase 0's critical-function hunt builds a ranked `critical_functions` registry — the auth checks, deserializers, validators, crypto, and parsers a security property depends on, each weighted (`rank_score` → `rank_tier`). Phase 0.5 then plans forward data-flow in **both** directions around the top-ranked functions: source→CF reachability (`critical_fn_reach`) and CF→downstream-effect slices (`input_slices.slice_kind = 'critical_fn_forward'`). Identification + ranking: [`references/v2/critical-function-hunt.md`](critical-function-hunt.md); CPGQL + coverage measurement: [`references/methodology/joern-forward-slicing.md`](../methodology/joern-forward-slicing.md); lane wiring: [`references/methodology/forward-slicing-lanes.md`](../methodology/forward-slicing-lanes.md).

### Execution-Path-First Slicing (LLMxCPG)

The same `forward_slice_lane` also emits a focused source→sink snippet as `input_slices.slice_kind = 'execution_path'` — the LLMxCPG (`arXiv:2507.16585`) construction: extract the path (`sink.reachableByFlows(source)`), enrich with **interacters** (identifiers sharing a path line), then take a path-union backward slice (`reachableByFlows(cpg.all)`). This is **not a new lane** — `v_required_deep_lanes` and the completion gate are unchanged. The bounded CPGQL query-generation loop (generate → run → feed the Joern error back → retry ≤ 3 → else `dead_end`) logs every attempt to the `query_attempts` table for change-visibility. Integration summary + concept map: [`references/methodology/llmxcpg.md`](../methodology/llmxcpg.md); recipe + query-loop sub-procedure + anti-brittleness doctrine: [`references/methodology/joern-forward-slicing.md`](../methodology/joern-forward-slicing.md) §§ 7–9.

### Slice-End Codebase Coverage

When the Hunt's slicing lanes finish for a `(target, round)`, the **non-mandatory `cpg_coverage`** step (strategy id 16, deliberately *not* in `v_required_deep_lanes`) measures — over the UNION of every slice's nodes — how much of the codebase the slices collectively touched, and saves it as one `cpg_slice_coverage` row: a **raw** ratio (first-party methods, the literal "% on codebase") and a **frontier** ratio (attacker-reachable ∪ sink-bearing ∪ critical-function methods, the bug-finding signal). Percentages are computed read-time by `v_cpg_slice_coverage` (never stored). Each *uncovered frontier* method is emitted as a reusable `agent_observations(obs_kind='blind_spot')` so the next round slices it first (round feed-forward). Enforced by the count-free gate `v_coverage.slices_without_codebase_coverage` — there is **no percentage floor** (slicing is selective by design; a low % is inspected, not failed). Recipe: [`references/methodology/joern-forward-slicing.md`](../methodology/joern-forward-slicing.md) § 10; schema: [`db/migrations/0017-cpg-slice-coverage.sql`](../../db/migrations/0017-cpg-slice-coverage.sql).

### Methodology Blind-Spot Sweep (Phase 1.6, Post-Hunt)

After **all discovery sweeps** finish for a `(target, round)` — the Phase 1 Hunt and (DEEP) Phase 1.5 Fuzzing — two **identical, independent** lanes (`methodology_blindspot_lane_a`, `methodology_blindspot_lane_b`; the dual-seed-corpus precedent, diversity from LLM stochasticity) answer one question: *"find any blind spot in our codebase-analysis methodology."* Each critiques **two clearly-separated classes**: **process gaps** (`gap_class='process'` — HOW we analyzed: bug classes never checked, lanes that should exist but don't, assumptions left untested, source/sink/defense types not enumerated) and **coverage gaps** (`gap_class='coverage'` — WHAT this run never reached). Their output is **merged by content-hash union-dedup** into the `methodology_blind_spots` table (DB-native: `blindspot_hash` UNIQUE → ON CONFLICT; when both lanes independently flag the same gap the orchestrator flips `agreement='both'` and bumps `dedup_cluster_size` — agreement is a confidence signal). The merged, ranked directions (`v_methodology_blindspots_ranked`: unconsumed first, both-lane agreement above single, recurrence next) **feed forward into the next round** — they become candidate directions/lanes the next round picks up first (`promoted_to_round_id` records the closure), and do **not** spawn work this run. These are deliberately **distinct** from the frontier-coverage `agent_observations(obs_kind='blind_spot')` rows emitted by `cpg_coverage`; each merged row also emits one reusable `blind_spot` observation so the every-phase observation flush and the existing round-entry fetch see it. Contract: [`references/v2/methodology-blindspot-sweep.md`](methodology-blindspot-sweep.md); schema: [`db/migrations/0018-methodology-blindspot-sweep.sql`](../../db/migrations/0018-methodology-blindspot-sweep.sql).

### Suspicious-Point Screening Tier

A **Suspicious Point** is a domain-agnostic, high-recall, region-level vulnerability hypothesis flagged *before* the precision-oriented `gr_findings` tier. SPs are **not a new mandatory lane** — a side-output emitted by existing Phase 1 Hunt and Phase 1.5 fuzz lanes (roster and `v_required_deep_lanes` unchanged). Each SP is a `suspicious_points` row (region anchor + `vuln_class` + emitting `lane`; never a stored score, `confirmation_status`, or PoC); its composite is computed **read-time** by `v_suspicious_points_ranked` (within-round percentile-rank over non-gate factors + hard 0/1 gates, never persisted — mirroring `v_critical_fn_ranked`). An SP **graduates** into a `gr_findings(candidate)` when its taint-reach DAG closes (G1) or a crash/PoC lands — the unchanged five-gate Confirm then takes over and `sp.graduated_finding_id` links the two; an SP that screens out becomes a fuzz seed. Factor coverage is gated by `v_sp_factor_coverage` (a `weight<>0` factor with no producer this round is `MISSING`); the orchestrator MAY spawn a **non-mandatory** preliminary lane to fill it (never added to `v_required_deep_lanes`). Dedup is DB-native (UNIQUE natural key + `ON CONFLICT`). Contract: [`references/v2/suspicious-point-tier.md`](suspicious-point-tier.md).

### Promising-Lane Feed-Forward

A **promising lane** is a POSITIVE static-analysis **lead**: a concrete new investigation direction worth a dedicated lane (e.g. *"custom template engine → SSTI-fuzz lane @ `render()`"*). Any **DuckDB-backed static-analysis lane** (Phase 1 Hunt, Agent Sweep S2, Phase 0.75 code-reading, Phase L3/L4) MAY **opportunistically and non-mandatorily** surface one — it is a **side-output**, **not** a new mandatory roster lane (roster and `v_required_deep_lanes` unchanged, no blocking gate, no `v_phase_status` phase row — the Suspicious-Point / `cpg_coverage` precedent). It is deliberately **distinct** from a `methodology_blind_spots` gap (negative — what we missed) and a `suspicious_points` region hypothesis (`vuln_class@region`): a promising lane is a *direction*. **Feed-forward only**: a lead never schedules work in its own run; it **persists** and becomes a ranked candidate direction the **next round picks up first** (the `methodology_blind_spots` action model — `promoted_to_round_id` records the closure when a later round consumes it). Each is a `promising_lanes` row (region anchor + `proposed_lane_kind`/`vuln_class` + verbose `body`; the `promise` composite and `est_severity` weight are **never stored** — computed **read-time** by `v_promising_lanes_ranked`: `promise = novelty × est_severity × reachability_prior × ledger_history_factor`, COALESCE-neutral, ordered unconsumed-first → not-already-covered-first → `promise DESC` → `dedup_cluster_size DESC` → `created_at`, mirroring `v_critical_fn_ranked`). Overlaps with an existing SP or finding are **flagged + down-ranked read-time** (`overlaps_sp_id`/`overlaps_finding_id` → `already_covered`), never deleted (no silent loss). **Single-writer**: subagents emit row-shaped `promising_lanes` events to the in-memory queue; the orchestrator alone flushes (incremental per-lane), stamps `lane_hash`/`overlaps_*`/`ledger_history_factor`, and bumps `dedup_cluster_size` on `ON CONFLICT (lane_hash)`. Round-entry **fetch (10)** carries open leads forward ([`references/v2/round-feedforward.md`](round-feedforward.md) § 2). Schema: [`db/migrations/0025-promising-lanes.sql`](../../db/migrations/0025-promising-lanes.sql) (`promising_lanes` table + `pl_severity_weight` macro + `v_promising_lanes_ranked` + `v_coverage.promising_lanes_unpromoted` inspect-SIGNAL).

**Yield-weighted scheduling — effort follows realized yield, not bug-class prestige.** The `est_severity` factor above is a *prediction*; lane priority must also carry each vein's **realized confirmed-yield** from prior rounds. After each round the orchestrator carries per-vein confirmed-yield (count of findings that reached `confirmation_status='confirmed'` via this vein) into the next round's lane priority as a multiplicative factor: a vein that returned **zero confirmed findings across N rounds is down-funded**, and a vein with high yield-per-effort is front-loaded. This is the structural correction to effort-order inversion — the failure where "RCE = Critical by class" front-loads a zero-yield geometry vein for days while the genuine bug sits in the least-funded surface, audited last. **Effort order tracks yield, not class prestige.** To avoid cold-start starvation (round 1 has no yield history and would otherwise let the allocator strangle a vein before it produced), the yield factor **ramps in from round 2+**: round 1 weights by predicted severity alone, and realized-yield down-funding only takes hold once a vein has had at least one round to deliver. This is the realized-yield complement to the prediction-only `promise` formula and feeds the same next-round priority surface as [`references/v2/round-feedforward.md`](round-feedforward.md) carries.

### Prior-Art Intake (Phase L-1)

The `prior_art_intake_lane` (strategy 25) runs **before Phase 0** — the first thing an audit does when a scope target is provided. It mines NVD/GHSA/OSV/exploit-db CVEs and web writeups for the in-scope target into the `cves` and `writeups` tables, then DISTILS high-yield leads into `promising_lanes` rows stamped with provenance cols `derived_from_cve_id` / `derived_from_writeup_id`. Round 1 consumes these leads via fetch (10); acting on one stamps `promoted_to_round_id`. Distillation is **distillation-first, per-source**: `coverage_json` records `sources_queried[]` + per-source counts so the orchestrator can see exactly which CVE/writeup sources contributed leads and which were dry. **Bug-bounty-mode mandatory when scope is provided**; records a documented skip (`status='skipped'` + `termination_reason`) when no scope or no network is available — never silent. Schema: [`db/migrations/0026-prior-art-intake.sql`](../../db/migrations/0026-prior-art-intake.sql).

### Overlooked-Lane Self-Audit (Phase 1.7)

The `overlooked_lane_audit_lane` (strategy 26) is **DEEP-only mandatory** and runs **last** among discovery phases — after Phase 1.6 blind-spot sweep, before Confirm. It asks two self-questions: (1) generative — *"what additional high-yield lanes does this codebase warrant that we did not run?"*; (2) audit — *"did we erroneously ignore or skip a lane that should have run?"* Both questions are **DB-grounded via triple reference**: roster-vs-`agent_steps` diff (what was scheduled but not executed), emitted-but-unpromoted `promising_lanes` rows (leads no lane acted on), and `v_coverage`/enumeration signals (coverage holes). The lane **ALWAYS emits** ≥ 1 `promising_lanes` row (even if the answer is "nothing missed"), then **cap-gated SPAWNS** the top-N-by-promise lanes **in-run** — cap = `fetch-budgets.yml promising_lanes row_cap × tier_multiplier`, no magic constant. Lanes beyond the cap are not dropped: they **feed forward** via fetch (10) into the next round. The in-run spawn is the **deliberate bounded exception** to feed-forward-only doctrine — the one place a lane is allowed to schedule live work mid-run, bounded by the config cap to prevent runaway fan-out. Schema: [`db/migrations/0028-overlooked-lane-audit.sql`](../../db/migrations/0028-overlooked-lane-audit.sql).

### Rich Logging + Round Feed-Forward

Agents persist reasoning — not just findings — as `agent_observations` rows (hypotheses, dead-ends, invariants, blind spots), flagged `reusable` when they should survive the run. **Every executed phase MUST flush ≥ 1 `agent_observations` row** — at minimum a `dead_end`, `invariant`, or `blind_spot` — so no phase is silent (`v_observation_coverage`, below). Every hunt agent is also **encouraged to enrich** the preliminary Phase-0/0.5 artifacts (`sources`, `sinks`, `defenses`, `critical_functions`, candidate `gr_findings`) by emitting anchored observations (keyed on `symbol_path`) the orchestrator applies at flush — never a direct DB write. A later **round** over the same target opens a `round_ledger` row and fetches the prior round's confirmed findings, reproduced bypasses, reusable observations, CF ranking, slice coverage, and fuzz resume artifacts instead of recomputing them; a reproduced bypass raises its critical function's `factor_bypass_prior` (re-ranking it this round and pre-seeding the next), and fuzz checkpoints/frontiers resume Phase 1.5 at the prior frontier. Logging contract: [`references/v2/db-logging-and-context.md`](db-logging-and-context.md) (enrichment in § 7); round-entry fetch: [`references/v2/round-feedforward.md`](round-feedforward.md).

### Fuzzing (Phase 1.5, DEEP — Mandatory-Attempt)

A DEEP audit always *attempts* dynamic sanitizer-finding discovery and coverage deepening. A dedicated lane first recons for an **existing fuzzing pipeline** (OSS-Fuzz target, in-tree harness, seed corpus) and reuses it before building fresh, then drives the applicable engines + sanitizers per language at high-value boundaries (parsers, FFI shims, decoders) — see the Contract for the per-language engine/sanitizer matrix, the Munch-derived FS/SF hybrid rule for coverage stalls, and protocol/session modeling (inputs as **messages**/**traces**, measuring state/transition coverage). For C/C++, **leak discovery is a first-class objective**, not a secondary diagnostic: enable LSan where supported, treat deterministic leak reports as distinct `fuzz_crash` candidates (reproducer input + sanitizer report), dedupe by leak stack/signature, and record them with the same run/finding/artifact discipline as crashes. Crashes and deterministic leaks land as `gr_findings` (`finding_kind='fuzz_crash'`, G4-satisfied by construction for memory-safety crashes and by the reproducer + LSan report for leaks); divergence/property/state oracles use `fuzz_divergence` or `fuzz_crash` as appropriate. Every run — **including a skip on a non-fuzzable target** — is accounted in `fuzz_runs` with a `skip_reason`, and resumable seeds/corpora/frontiers/checkpoints persist in `fuzz_artifacts`. **Maximum coverage is a first-class, measured, gated objective** (v0.29): every *ran* row must record a coverage measurement (`edges`/`blocks`/`function_coverage_pct`) **and** `uncovered_frontier[]` (the reachable functions/states it did not reach — the next-round worklist, fed forward as `blind_spot` observations + a `coverage_frontier` artifact). Two count-free `v_coverage` gates — the dynamic mirror of `slices_without_codebase_coverage` — enforce this: `fuzz_runs_without_coverage_measurement` (a ran row that never measured coverage) and `fuzz_skips_unrecorded` (a `boundary_fuzz_lane` step with no `fuzz_runs` row). A run is coverage-complete only at a **plateau with FS/SF escalation exhausted** (no magic %-floor — coverage maximization is monotonic *across rounds* via the carried frontier). Read it back with `v_fuzz_coverage` (read-time per-run rollup, the `v_cpg_slice_coverage` analogue: `edges`/`function_coverage_pct`/`uncovered_frontier_n` ordered by `round_id` → the round-over-round trend). The lane logs under `boundary_fuzz_lane`, distinct from Phase 0.75's `isolation_fuzz_lane`. Contract: [`references/v2/fuzzing-lane.md`](fuzzing-lane.md) (§ 8/§ 8a coverage contract + saturation); tables: [`db/migrations/0003-fuzzing-lane.sql`](../../db/migrations/0003-fuzzing-lane.sql) + [`db/migrations/0008-fuzz-artifacts-and-strategy-v2.sql`](../../db/migrations/0008-fuzz-artifacts-and-strategy-v2.sql) + [`db/migrations/0022-fuzz-coverage-aim-and-tracking.sql`](../../db/migrations/0022-fuzz-coverage-aim-and-tracking.sql).

### REPORT Critic

Every confirmed finding goes through three checks (comprehension / eligibility / attack-scenario). WARNING is stored structurally; CRITICAL blocks the report. Rubric with worked examples: [`references/v2/critic-rubric.md`](critic-rubric.md).

### Canonical Table Name

The findings table is `gr_findings`; `confirmed_vulns` is a view selecting `confirmation_status = 'confirmed'`.

---

## DuckDB Harness (Go)

All writes go through [`db/harness/`](../../db/harness/) — a small Go module exposing `vrdb.Open / Put / Fetch` (library) and a `vrdb` CLI (`put TABLE`, `fetch SQL`, `exec SQL` — all `--db PATH`, JSONL in/out; `exec` emits `{"rows_affected": N}`). It embeds [`db/schema.sql`](../../db/schema.sql), applies it idempotently on Open, auto-assigns missing `id`, and emits `INSERT … ON CONFLICT DO NOTHING` — this is what enforces the single-writer + idempotency rules above. Every file ships with a 3-line header (what / why / how + when). **Expansion clause:** ad-hoc analytics, one-off migrations, and exploratory scripts go under [`db/harness/temp/`](../../db/harness/temp/) (throwaway scratchpad, each with a 3-line header; promote anything durable into `db/harness/` proper). `db/harness/temp/` relocates to `.vuln-research/tmp/` as part of the harness follow-on.

**Put contract — `skipped` is success, never data loss.** `vrdb put TABLE` emits a per-call JSON summary `{"table": ..., "inserted": N, "skipped": M, "errors": K}`. `skipped` counts the `INSERT … ON CONFLICT DO NOTHING` no-ops — rows whose natural key already exists. This is **idempotency working as designed** (a re-flush over the same `commit_sha`, a crash-recovery replay, two agents corroborating the same observation), NOT lost data: the orchestrator MUST treat `skipped > 0` as a SUCCESS signal and only `errors > 0` as a write failure to surface. Conflating `skipped` with loss has caused spurious re-flush loops; the count exists so the single writer can distinguish a benign conflict from a real reject.

**Preflight — run `vrdb selftest` before the audit.** Begin each run by invoking `vrdb selftest` (alias `vrdb doctor`): it opens the DB, applies the embedded schema + migrations, and round-trips a put/fetch so a broken toolchain, an unmigrated schema, or a wrong DuckDB version is caught *before* Phase 0 rather than mid-flush. For the DuckDB v1.1.3 FK-`UPDATE` quirk (and the harness workaround the put/exec paths use), see [`db/harness/NOTES.md`](../../db/harness/NOTES.md).

---

## Environment Preflight (DEEP)

A DEEP audit begins with an **environment preflight subagent** that runs before Phase 0 and records its findings as `agent_observations`. It establishes which capabilities are available so no later phase silently skips work it was expected to do:

- **Language toolchain + build** — can the target compile/run? (gates all dynamic phases)
- **Static-analysis tooling** — Joern, Semgrep, LSP presence and reachability (gates CPG-based slice plans in Phase 0.5)
- **Fuzzing engines + sanitizers, per language** — AFL++/libFuzzer/honggfuzz + ASan/UBSan/MSan for C/C++; KLEE/SymCC/SymQEMU for directed symbolic escalation; cargo-fuzz + Miri for Rust; `go test -fuzz` for Go; Jazzer for JVM; AFLNet/StateAFL/boofuzz-style tooling for stateful protocols when applicable (gates Phase 1.5; a skip is only honest when recorded here)
- **Git history depth** — number of reachable commits (gates Phase L0; fewer than 3 → skip recorded)

A phase that could not run because a required tool was absent MUST be recorded as a documented gap (`obs_kind: "blind_spot"`, `reusable: true`) in `agent_observations`. The completion gate below reads these records — a gap that is logged is waivable; a gap that is silent is a broken gate.

---

## Mandatory DEEP Lane Roster

A DEEP audit defines 18 required lanes. Every lane must either execute at least one `agent_steps` row OR record a documented skip before the orchestrator may declare completion.

| Phase | Lane name (exact `strategies.name`) | Doc |
|---|---|---|
| Phase L-1 Prior-Art Intake | `prior_art_intake_lane` (`phase_l1_prior_art`) | `db/migrations/0026-prior-art-intake.sql` |
| Phase 0 Decompose | `preliminary_enumeration_lane` | `references/methodology/preliminary-enumeration-lane.md` |
| Phase 1 Hunt | `forward_slice_lane` | |
| Phase 1 Hunt | `backward_sink_lane` | |
| Phase 1 Hunt | `critical_function_dataflow_lane` | |
| Phase 0.75 Defense Pre-Break | `defense_base_lane` | |
| Phase 0.75 Defense Pre-Break | `defense_context_verification_lane` | |
| Phase 0.75 Defense Pre-Break | `isolation_fuzz_lane` | |
| Phase 0.75 Defense Pre-Break | `html_sanitizer_bypass_lane` | `references/methodology/html-sanitizer-bypass-lane.md` |
| Phase 0.75 Defense Pre-Break | `concolic_bypass_lane` (C/C++/Java) | `references/methodology/cpp-java-concolic-bypass-lane.md` |
| Phase 1.4 Seed-Corpus Gen | `llm_seed_corpus_lane_a` | `references/v2/seed-corpus-generation-lane.md` |
| Phase 1.4 Seed-Corpus Gen | `llm_seed_corpus_lane_b` | `references/v2/seed-corpus-generation-lane.md` |
| Phase 1.5 Fuzzing | `boundary_fuzz_lane` | |
| Phase 1.5 Fuzzing | `fuzzgpt_history_lane` | `references/v2/fuzzgpt-history-lane.md` |
| Phase 1.6 Methodology Blind-Spot | `methodology_blindspot_lane_a` | `references/v2/methodology-blindspot-sweep.md` |
| Phase 1.6 Methodology Blind-Spot | `methodology_blindspot_lane_b` | `references/v2/methodology-blindspot-sweep.md` |
| Phase 1.7 Self-Audit | `overlooked_lane_audit_lane` (`phase1_7_self_audit`) | `db/migrations/0028-overlooked-lane-audit.sql` |
| Phase 5 Report | `report_critic` | |

**Not required:** `autoload_seed_lane` and `autoload_expand_lane` are knowledge plumbing and are NOT in the mandatory roster.

**Confirm is a budgeted roster lane, not an unsized downstream consequence.** Confirm/Proof are still gated by `v_phase_status` + `v_coverage`, but Confirm is given a **reserved share of the round's compute/session budget** and is **scheduled interleaved with discovery** — confirm the round-N candidates while the Hunt works round N+1, not strictly after all discovery drains. A recall-maximizing front end with an *output-proportional, unreserved* back end starves the back end every time discovery over-produces; the reservation is what keeps verification from being the first thing a finite budget drops.

**Emission governor.** When the open-candidate count (`v_coverage.findings_candidate_open`) exceeds a per-round cap, the orchestrator **stops spawning new discovery lanes and drains the confirm queue** before resuming. Completion requires **`confirm_backlog_drained`** — the count of candidates *entering* Phase 2 equals the count of candidate+refuted *leaving* it; a run may not declare done with an un-adjudicated backlog. The governor pauses *new* discovery without violating the perpetual-loop divergence rule: it **drains, then resumes divergence next round** — mandatory divergence is satisfied per round, the drain just defers the next round's new emission until the current candidates are adjudicated. Cross-ref the perpetual loop's three-register sequence in [`references/methodology/perpetual-loop-mode.md`](../methodology/perpetual-loop-mode.md).

**Enforcement bar:** For the DEEP tier, every lane in the roster MUST either (a) execute at least one agent_step, OR (b) record a documented skip — an `agent_steps` row with `status='skipped'` AND a non-empty `termination_reason` explaining why the lane is N/A for this target. A required lane with zero executed steps and no documented skip is a BLOCKING gate failure. This permits honest N/A skips while killing silent omission.

Phase 0.5 (Plan) **materializes** the roster — the orchestrator inserts one `agent_steps` row per required lane with `status='scheduled'`. A lane that is never spawned stays `scheduled` with zero executed steps and is caught by the gate, so 'defined in the skill but never spawned' becomes a queryable, blocking delta rather than a silent omission.

**Closures barrier (Phase 0.5).** Roster materialization is no longer unconditional. Before inserting a lane's `scheduled` row, the orchestrator consults the **`closures`** table (`surface_hash`, `closure_kind ∈ dead_end/exhausted/refuted_class`, `closed_in_round`, `reopen_condition`). A lane targeting a `surface_hash` with an **open closure whose `reopen_condition` has not fired** is scheduled `status='skipped'` with `termination_reason='closed@round_N'` — it is *not* run. This makes closure a typed *scheduling constraint*, not feedback-memory advice an agent may forget under compaction. Re-opening requires the `reopen_condition` to **fire** as a checkable event (the code under the `slice_fingerprint` moved, a new primitive landed) — never LLM discretion. Closures are written by the negative-result stopping rule (`swarm-pipeline.md` § Analog Cascade) and by the perpetual loop's Learn step; the hard pre-spawn dedup that pairs with this barrier is `swarm-pipeline.md` § Wave Init. A `skipped`-for-closure lane satisfies the completion gate exactly like a documented N/A skip.

The roster lives in `v_required_deep_lanes(lane_name, phase)` and the per-lane ledger in `v_lane_coverage(lane_name, phase, strategy_id, steps_total, steps_scheduled, steps_executed, steps_skipped_documented, gate_status)` (both defined in `db/schema.sql`). Full materialization, skip, and gate mechanics are in `references/v2/db-logging-and-context.md` §13.

---

## DEEP Completion Gate

**Gates are round-scoped.** The completion gate views below (process + outcome-justification) must be evaluated against the **current `round_id`** — a lane that ran in round 1 does not satisfy the gate for round 2. Scope every gate query to the active round by joining on `round_ledger.round_id` or filtering `agent_steps.round_id = :current_round`.

**Mechanical gate verb:** `vrdb gate --db PATH [--tier deep]` runs the completion gate views below (process + outcome-justification) and exits non-zero if any hard-red signal fires. Run it instead of hand-running individual SELECTs; the exit code is the authoritative pass/fail signal.

Before the orchestrator declares a DEEP audit complete it MUST run both coverage views and resolve every red signal — either by fixing the gap or by recording an accepted-gap justification in `agent_observations`:

```sql
SELECT * FROM v_phase_status;
```
Every phase that was expected to run must have `ran = true` and non-zero `rows_populated`. A zero-row phase with no recorded preflight gap is a red gate — the orchestrator does not declare done. Canonical phase token for Phase 0.75 in all views: `phase0_75_prebreak` (the legacy `phase0_75_prebreak_and_recheck` token was unified to this string in v0.30; use only `phase0_75_prebreak` in any new view or gate query).

```sql
SELECT * FROM v_coverage;
```
Named gap metrics the orchestrator must inspect and resolve (or waive):

| Column | Red-gate condition |
|---|---|
| `findings_candidate_open` | `> 0` — Confirm (Phase 2) did not finish |
| `defenses_without_bypass_attempt` | `> 0` — Phase 0.75 did not cover the full defense inventory |
| `guards_on_paths_without_defense_row` | `> 0` — a guard on a reach path has no `defenses` row → Phase 0 defense enumeration under-populated |
| `validator_cfs_without_defense_link` | `> 0` — a validator/sanitizer critical-fn has no `defenses` row → defense enumeration gap |
| `dangerous_sink_cfs_without_sink_row` | `> 0` — a dangerous-sink critical-fn has no `sinks` row → sink enumeration gap |
| `confirmed_without_critic` | `> 0` — a confirmed finding bypassed the Phase 5 REPORT critic |
| `confirmed_without_refutation` | `> 0` — a confirmed finding has no adversarial refutation attempt on record (mirrors `confirmed_without_critic`; enforces the refute-before-confirm mandate mechanically) |
| `lanes_stuck_running` | `> 0` — an `agent_steps` row is still `status='running'` at completion time, indicating a crashed/OOM lane whose process died without writing a terminal status; treat as HARD RED — do not declare done while any lane is stuck running |
| `confirmed_missing_severity` | `> 0` — a confirmed finding has no severity set |
| `executed_steps_without_observation` | `> 0` — RED. An executed `agent_steps` row flushed zero `agent_observations` — a phase ran without leaving a reasoning trace |
| `defenses_below_validator_cf_floor` | `> 0` — RED. The stored `defenses` count is below the count of distinct validator/sanitizer critical functions — a recon under-enumeration floor breach |
| `slices_without_codebase_coverage` | `> 0` — RED. `input_slices` exist but no `cpg_slice_coverage` row — the union-of-slices codebase coverage was never measured/saved when slices ended. Count-free; **not** a %-floor |
| `fuzz_runs_without_coverage_measurement` | `> 0` — RED. A `fuzz_runs` row that **ran** (`skip_reason IS NULL`) records no coverage measurement in `coverage_json`. Count-free, **not** a %-floor |
| `fuzz_skips_unrecorded` | `> 0` — RED. A `boundary_fuzz_lane` step that ran or was documented-skipped emitted no `fuzz_runs` row |
| `distinct_target_ids` | `> 1` — target_id drift (rows from multiple targets mixed in one DB) |
| `fuzz_runs_skipped` | `> 0` — inspect each skip_reason for honesty (signal, not an auto-red) |

These are signals the orchestrator must inspect, resolve, or waive — not auto-pass conditions.

```sql
SELECT lane_name, phase, steps_executed, steps_skipped_documented, gate_status
FROM v_lane_coverage WHERE gate_status = 'MISSING';
```
Any row returned by this query is a required DEEP lane that was neither executed nor documented-skipped — a HARD RED gate. The orchestrator does NOT declare done while any lane is `MISSING`. The three `gate_status` values are: `'ok'` (lane has ≥1 executed step), `'skipped'` (lane has a documented N/A via `status='skipped'` + non-empty `termination_reason`), `'MISSING'` (no executed steps and no documented skip — blocks completion).

```sql
SELECT * FROM v_observation_coverage;
```
Per-phase observation accounting. `gate_status` is one of: `'ok'` (the executed phase flushed ≥ 1 `agent_observations` row), `'not_run'` (the phase did not execute — no observation expected), `'NO_OBSERVATION'` (the phase executed but flushed zero observations). A `NO_OBSERVATION` row is a **HARD RED** gate — the orchestrator does NOT declare done while any phase is `NO_OBSERVATION`. This pairs with `v_coverage.executed_steps_without_observation` (the step-level view of the same hole) and enforces the *every-phase observation flush* rule.

---

## Row-Shape Invariants

Three load-bearing write-time invariants every agent and flush must respect:

**target_id is pinned once per audit.** The orchestrator sets `target_id` when it opens the audit DB; every row in every table carries that same value. Lanes must not invent their own `target_id`. `v_coverage.distinct_target_ids` flags drift — any value above 1 means rows from a different target contaminated this DB.

**FK columns carry the parent table's id space.** A `sink_id` column holds an id from `sinks`; a `defense_id` holds an id from `defenses`. Never write a `critical_functions.id` into a `sink_id` or `defense_id` field — this has surfaced repeatedly as cryptic `key id:N does not exist` errors in production. The harness now pre-validates every cross-table FK column before insert and rejects a wrong-id-space value with a clear message (e.g. `Put: defense_bypasses.defense_id=62 references missing defenses.id (FK id-space mismatch)`), so the bug surfaces at write time rather than at query time.

**Status is updated, not re-inserted.** Finding lifecycle transitions (`candidate → confirmed → refuted`) are `UPDATE`s issued via `vrdb exec "UPDATE gr_findings SET confirmation_status='confirmed' WHERE id=N" --db PATH`, which returns `{"rows_affected": 1}`. They are not new inserts, and not workarounds that abuse `fetch`. The harness exposes the `exec` verb for this purpose — a missing `rows_affected: 1` is an immediate signal that the update targeted the wrong row.
