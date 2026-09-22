---
name: vuln-swarm
description: >
  Multi-phase SAST swarm pipeline for deep vulnerability research, adapted to the
  v2 DuckDB-persisted phase architecture. Drives the orchestrator through Decompose →
  Plan → Defense Pre-Break → Hunt → Fuzzing → Methodology Blind-Spot Sweep → Confirm → Bypass-Recheck → Proof → Report → Invariant Promotion, with single-writer DuckDB
  flush per phase. Tier-gated (LOW / MEDIUM / DEEP) and freeform-posture-aware.
argument-hint: "<target-repo-path> [--effort=low|medium|deep] [--freeform=detached|grounded]"
---

# Vulnerability Research — Swarm Pipeline (v2 DuckDB)

Target: `$ARGUMENTS`

> **This command owns the SWARM SHAPE, TIER GATING, and HANDOFF DISCIPLINE.**
> **The `vuln-research` skill owns TAXONOMY, SINK CATALOGS, BUG CLASSES, GATES, DOCTRINE.**
> Do not re-specify what the skill already specifies — invoke it.
>
> Mode: **SAST-first**. Phase 4 Proof exercises an unmodified production-equivalent
> deployment per skill §Phase L5 PoC constraints; no rule engines, no DAST scanners.
> Persistence: **DuckDB only** — **subagents write no filesystem artifacts.** The
> orchestrator/harness/engine disk output (run DB, sidecars, fuzz corpora/crashes,
> C5 build artifacts, engine tmpdirs, the per-repo catalogue) consolidates under the
> gitignored `.vuln-research/` workspace at the audited repo root (SKILL.md
> § Workspace convention). Oversize payloads (> 16 KB) spill to
> `.vuln-research/sidecars/` via the schema (A1), referenced by `payload_sidecar_path`.

## Flags

- `--effort=low|medium|deep` (default: `medium`) — selects the effort tier. See § Tier Gating below.
  - **LOW**: P0 (preliminary subset — L0 + L1-core + L2 crown-jewel + sink-loading; see § Preliminary Phase Gating) → P0.5 → P1 (≤ 2 freeform agents) → P2 (single re-check). Skips P0.75 Defense Pre-Break, P1.5 Fuzzing, P3 Bypass-Recheck, P4 Proof, and P5 Report critic. Findings stay at `gr_findings.confirmation_status = 'candidate'`.
  - **MEDIUM**: full P0 (preliminary subset + L2 attention-deficit + Semgrep packs) → P5 once. Module fan-out with ≥ 2 orthogonal strategies; **P0.75 Defense Pre-Break** of the defense inventory (defeated-defense set relaxes Confirm G2) + thin P3 Bypass-Recheck; 2-check confirm; PoC build with `config_state` recorded; REPORT critic with WARNING/CRITICAL classification.
  - **DEEP**: MEDIUM + **every preliminary lane fully** (PATCH SEEDS, full attention-deficit scan, custom mega-packs/binary triggers, full dependency CVE sweep; see § Preliminary Phase Gating) + Forward-Slicing Lanes (C2) with every applicable `slice_kind` per promoted module + optional CodeQL/CPG/LSP function-context strategy for selected targets + **P0.75 pre-break driven to isolation-fuzz exhaustion** + **P1.5 Fuzzing** (mandatory-attempt crash discovery with applicable engines + sanitizers, Munch-style FS/SF concolic handoff, and stateful message/trace coverage; see § Phase 1.5 — Fuzzing); 3-check confirm (re-trace + judge + DAG-independent); autoload knowledge layer **expand** pass (cap 50, version-pinned); REPORT critic with all 17 rubric examples loaded.

- `--freeform=detached|grounded` (default: `detached`) — freeform-agent posture for the Hunt phase. See `references/methodology/freeform-detached.md`.
  - **detached** (default): hunt agent runs without skill taxonomy; emits raw observations as `gr_findings.candidate` row events, which still pass through Phase 2 Confirm gates and Phase 5 REPORT critic. See `references/methodology/freeform-detached.md`.
  - **grounded**: hunt agent is briefed with the skill's sink catalogs and bug-class taxonomy before analysis.

Load the `vuln-research` skill (`SKILL.md` § v2 Phase Architecture). Also load: `db/schema.sql` (table contracts), `references/v2/confirmation-rigor-doctrine.md` (C1 five gates), `references/methodology/forward-slicing-lanes.md` (C2 slice tuple + cascade semantics), `references/v2/autoloading-knowledge-layer.md` (C3 seed/expand), `references/phases/report-phase.md` + `references/v2/critic-rubric.md` (C4 critic), `references/v2/bypass-catalogue.md` (S2 tiered fetch + §§ 6–8 stage ladder/exhaustion/cascade — driven pre-hunt in Phase 0.75), `references/v2/fuzzing-lane.md` (C8 Phase 1.5 mandatory-attempt crash discovery, DEEP), `references/v2/critical-function-hunt.md` (C5 ranked critical-function registry), `references/methodology/joern-forward-slicing.md` (C2 Joern CPGQL + coverage measurement), `references/v2/db-logging-and-context.md` (C6 `agent_observations` capture + `finding_sightings` identity + `mutation_log` meta-logging), `references/v2/round-feedforward.md` (C7 round-entry priors + deterministic priority fetch), `db/seed/scoring.yml` (externalized `scoring_config` weights), `db/seed/fetch-budgets.yml` (per-phase fetch budgets), and `references/methodology/swarm-pipeline.md` (surviving strategy patterns — module decomposition, orthogonal strategies, analog cascade, weighted scoring).

---

## ═══ Single-Writer Discipline (load-bearing) ═══

The orchestrator is the **only DuckDB writer**. Swarm agents emit row-shaped JSON events to an in-memory queue; the orchestrator flushes per phase under one transaction. This preserves idempotency (every NK has a UNIQUE constraint, every payload row has a stable hash) and lets re-runs over the same `(repo_url, commit_sha)` update rather than duplicate.

If any subagent tries to open the DuckDB connection directly, abort that subagent and re-spawn it with a queue handle only. Agents that cannot write rows cannot corrupt the audit.

**Flush incrementally per lane.** "Per phase" is the transaction boundary, not a batch-to-phase-end mandate: the orchestrator drains each lane's queued events and writes that lane's `agent_steps` status transition + row-events the moment the lane completes — still single-writer. This narrows the crash/OOM queue-loss window to one in-flight lane. On resume, read `agent_steps.status` + `round_ledger` to re-enter at the last completed lane and re-spawn only `scheduled`/`running` lanes.

**Preflight + put contract.** Run `vrdb selftest` (alias `doctor`) before Phase 0 — it migrates the schema and round-trips a put/fetch so a broken toolchain or wrong DuckDB version fails fast. Each `vrdb put` returns `{"table","inserted","skipped","errors"}`; **`skipped` (ON CONFLICT no-op) is SUCCESS, never data loss** — only `errors > 0` is a write failure. DuckDB v1.1.3 FK-`UPDATE` workaround: `db/harness/NOTES.md`.

**RAM-aware concurrency.** Swarm fan-out is bounded by host memory, not token budget. Cap **HEAVY** lanes (own JVM / large process — Joern/CPG slice lanes, fuzzing, concolic) to **≤ 2 concurrent** (prefer sequential batches of 2); MEDIUM (large-fetch LLM) ~4–6; LIGHT higher. A DEEP run OOM-killed from 10 concurrent agents under one `parallel()` barrier (Joern JVM heaviest); weight tiers seed in `db/seed/fetch-budgets.yml` (`lane_weights`).

---

## ═══ Tier Gating ═══

| v2 Phase | Writer model | LOW | MEDIUM | DEEP |
|---|---|---|---|---|
| **0 — Decompose** (`round_ledger`, `sources`, `sinks`, `defenses`, `critical_functions`, `phase0_priorities`, `intended_feature_classification`) — opens the round + fetches prior-round priors, then runs the preliminary lanes; the whole-tree, finding-agnostic enumeration of `sources`/`sinks`/`defenses`/`critical_functions` runs as the gated `preliminary_enumeration_lane` (strategy id 15, phase token `phase0_decompose`; materialized at Phase 0.5, surfaces as MISSING if never spawned); see § Round Entry and § Preliminary Phase Gating | orchestrator | ✓ subset (L0 + L1-core + L2-crown-jewel + sink-loading) + top-2 critical-fn floor | ✓ + L2 attention-deficit + Semgrep packs + full critical-fn hunt & ranking + optional PATCH SEEDS | ✓ **all preliminary lanes** + PATCH SEEDS + mega-packs/binary triggers + full CVE sweep + critical-fn both-direction reachability |
| **0.5 — Plan** (`input_slices` incl. `critical_fn_forward`, `critical_fn_reach`, scheduled `agent_steps`) | orchestrator | ✓ (single slice family) | ✓ + `critical_fn_forward` for tier-1 critical fns | ✓ (every applicable `slice_kind` per promoted module) + source→CF `critical_fn_reach` for tier-1/2 |
| **0.75 — Defense Pre-Break** (`defense_bypasses`, defense-keyed/finding-agnostic; defeated-defense set; cascade-on-CF pre-rank) — breaks the Phase-0 defense inventory *before* the hunt; see § Phase 0.75 | swarm → queue → flush | — | ✓ Stage A enumerate → B skip-with-reason → C lazy-fetch per catalogued defense; defeated defenses feed Hunt + relax Confirm G2; broken-defense CF re-rank pre-seeds the hunt; `html_sanitizer_bypass_lane` (runs **late** in 0.75, after `defense_base_lane` warms the reuse source) enriches HTML-sanitizer `defenses` rows + runs bypass corpus via `engines/html-sanitizer-bypass/` + emits `defense_bypasses` + `sanitizer_bypass_runs` rows | ✓ + driven to `isolation_fuzz` exhaustion per isolation-eligible defense + cross-round feed-forward via `carried_from_bypass_id`; `html_sanitizer_bypass_lane` also required at DEEP (see MEDIUM cell); + `concolic_bypass_lane` (C/C++/Java, mandatory DEEP) solves a guard's path constraints to synthesize a guard-passing input that reaches the guarded fn |
| **1 — Hunt** (`gr_findings` status=`candidate`, `agent_observations`; **may enrich any Phase 0/0.5 artifact** — see § Phase 1) | swarm → queue → flush | ≤ 2 freeform agents, no module decomposition; log `dead_end`+`blind_spot` | module fan-out + sink-hunter, ≥ 2 orthogonal strategies; + `hypothesis`/`invariant`/`guard_observed`/`assumption` | + Forward-Slicing Lanes C2 (`forward_taint`, `backward_sink`, `defense_callsite`, `critical_fn_forward`) per promoted module; all obs_kinds incl. `partial_trace`/`tool_output` |
| **1.4 — Seed-Corpus Gen** (`fuzz_artifacts` `artifact_kind=seed_initial`) — preliminary dual LLM seed-gen feeding Phase 1.5; see § Phase 1.4 and `references/v2/seed-corpus-generation-lane.md` | swarm → queue → flush | — | — | ✓ two identical independent lanes (`llm_seed_corpus_lane_a`/`_b`); per-lane stop = format-family coverage OR DB-stored token budget; union deduped by `content_hash`; ran or skip-with-reason (no fuzzable entry point) |
| **1.4 — History-Driven Fuzzing** (`fuzz_artifacts` `artifact_kind=seed_initial`; + quarantined `gr_findings` `finding_kind=differential_divergence`) — `fuzzgpt_history_lane`, history-driven LLM fuzzing (FuzzGPT, arXiv:2304.02014), **coexists** with the dual seed lanes; see `references/v2/fuzzgpt-history-lane.md` + `references/methodology/fuzzgpt-history-driven-lane.md` | swarm → queue → flush | — | — | ✓ mine the target's bug history (gh issues/PRs/commits) → label each snippet's "fuzz target" (the **unit** — API/flag/SQL-feature/syscall/opcode/field; NOT a libFuzzer harness) → few-shot CoT / zero-shot / retrieval (RT, selector in `engines/fuzzgpt-retrieval/`) → emit edge-case programs as `seed_initial` into the merged corpus; target-agnostic differential-oracle sub-mode (impl/version/opt-level/config/reference) QUARANTINES divergences as `gr_findings(finding_kind='differential_divergence', severity=NULL, confirmation_status='unconfirmed')`, OUT of the HIGH/MED/LOW rankings until triage shows a security path; ran or skip-with-reason (`no_minable_bug_history`) |
| **1.5 — Fuzzing** (`fuzz_runs` + `gr_findings` `finding_kind=fuzz_crash/fuzz_divergence`) — mandatory-attempt crash/divergence discovery; see § Phase 1.5 and `references/v2/fuzzing-lane.md` | swarm → queue → flush | — | — | ✓ consumes the Phase 1.4 merged seed corpus; existing-pipeline recon first, then fuzz the top-ranked reachable native/parser/FFI/protocol boundaries selected by `critical_functions`, patch seeds, and attention-deficit budget with available engines + sanitizers (AFL++/libFuzzer/honggfuzz/cargo-fuzz/go-test-fuzz/Jazzer + ASan/UBSan/MSan, concolic on stalls via FS/SF handoff, stateful trace fuzzing when applicable); non-fuzzable target records a skip-with-reason `fuzz_runs` row |
| **1.6 — Methodology Blind-Spot Sweep** (`methodology_blind_spots` + companion `agent_observations`) — post-Hunt meta pass; see § Phase 1.6 and `references/v2/methodology-blindspot-sweep.md` | swarm → queue → flush | — | — | ✓ two identical independent lanes (`methodology_blindspot_lane_a`/`_b`) run **after all discovery sweeps**; single goal "find any blind spot in our codebase-analysis methodology"; emit `process` + `coverage` gap rows, **merged by content-hash union-dedup** (agreement=`both` on cross-lane hit); ranked directions **feed the next round** (round-feedforward fetch 8), do NOT spawn work this run; ran or skip-with-reason |
| **2 — Confirm** (`gr_findings` status updates + `refutations`; **G2 consults the Phase 0.75 defeated-defense set**; **no `reproduced=true`/`confirmed` until an adversarial DAG-independent refutation has RUN and FAILED to refute** — default-skeptical, over-claiming is the documented failure mode) | swarm → queue → flush | single re-check, five-gate doctrine still applied | 2-check (re-trace + judge), five-gate doctrine | 3-check (+ DAG-independent), five-gate doctrine |
| **3 — Bypass-Recheck** (`defense_bypasses` finding-specific + cascade triggers) — thin recheck of defenses on a finding's path; see § Phase 3 | swarm → queue → flush | — | ✓ `defense_context_verification_lane` confirms the defense fires on this finding's callsite + `config_state`; targeted bypass only where pre-break didn't already defeat it | ✓ + cascade-on-bypass spawns a new Hunt lane (`bypass_derived` source) |
| **4 — Proof** (`gr_findings.payload`/`config_state`, `audit_outcomes`) | swarm → queue → flush | — | ✓ (PoC against unmodified deployment, `config_state` recorded) | ✓ + paired step-by-step and bundled forms per skill §Phase L5 |
| **5 — Report** (`critic_findings`; final report) | critic agent → orchestrator | — | ✓ (comprehension / eligibility / attack-scenario; WARNING stored, CRITICAL blocks) | ✓ + all 17 rubric examples loaded; CRITICAL findings demoted to `refuted` at flush |
| **6 — Invariant Promotion** (canonical `references/methodology/triage-invariants.md` + `CHANGELOG.md` edits; backed by `v_invariant_promotion_coverage`) — terminal cross-target write-back; see § Phase 6 | orchestrator → CANONICAL skill | ✓ promote-or-skip every high-confidence reusable invariant; gate `v_invariant_promotion_coverage` HARD RED until cleared | ✓ | ✓ |

**LOW exit criteria.** After Phase 2, the run terminates with all surviving findings at `confirmation_status = 'candidate'`. LOW does not produce confirmed vulnerabilities — it produces a triage backlog. Gate 4 (reproduction artifact w/ `config_state`) is structurally unreachable without P4 Proof, so the five-gate doctrine refuses promotion. This is intentional.

**MEDIUM/DEEP exit criteria.** Pipeline runs end-to-end. A finding reaches `confirmation_status = 'confirmed'` only if all four C1 gates pass (taint reach, defense gap, intended-feature filter, reproduction artifact with `config_state`) AND its Phase 5 critic verdict does not raise CRITICAL.

**Lane-coverage gating is DEEP-only, by design (decision D3).** The blocking lane-coverage gate — `v_lane_coverage` over `v_required_deep_lanes` — runs only at DEEP. At MEDIUM the required lanes (Phase 0.75 pre-break, the two hunt slice lanes, `critical_function_dataflow_lane`, `report_critic`) are enumerated in prose + the tier tables and are **signal-gated**, not blocking-gated: the orchestrator inspects `v_coverage` (notably `defenses_without_bypass_attempt > 0`, `findings_candidate_open > 0`, and the three preliminary-inventory completeness signals `guards_on_paths_without_defense_row > 0`, `validator_cfs_without_defense_link > 0`, `dangerous_sink_cfs_without_sink_row > 0` — each flags an inventory populated only around chased findings) and must resolve or consciously waive each signal. These three completeness signals are **signal-gated at MEDIUM** here, and **blocking-gated at DEEP** via the `preliminary_enumeration_lane` roster entry. There is deliberately no `v_required_medium_lanes` view — a MEDIUM skip surfaces as a `v_coverage` signal to resolve, not a hard stop (DEEP is the rigor tier; MEDIUM trades a hard gate for lower latency).

**Observation + recon-floor gate signals (DEEP).** Every executed phase MUST flush ≥ 1 `agent_observations` row (min `dead_end`/`invariant`/`blind_spot`). The completion gate adds: `v_observation_coverage` — `gate_status='NO_OBSERVATION'` (executed phase with zero observations) is a **HARD RED**, `not_run` is benign, `ok` passes; `v_coverage.executed_steps_without_observation > 0` (step-level view of the same hole, RED); and `v_coverage.defenses_below_validator_cf_floor > 0` (RED recon-under-enumeration floor — stored `defenses` count is below the distinct validator/sanitizer critical-function count, so Phase 0 under-enumerated the defense inventory). The orchestrator does NOT declare done while any of these is red.

---

## ═══ Phase 0 — Decompose (orchestrator, sequential) ═══

Phase 0 runs the skill's **preliminary lanes** before any Hunt agent spawns. Each preliminary lane is a **first-class, tier-gated step**: DEEP runs every lane fully (it includes everything); LOW and MEDIUM run subsets. These lanes are the skill's L-lane methodology (orthogonal to these v2 mechanics phases per SKILL.md § Audit Methodology Lanes) — Phase 0 is where they execute and flush to DuckDB.

### Round Entry (prior-round priors)

Before any preliminary lane runs, the orchestrator opens this audit's `round_ledger` row and — if a prior round exists for the same `target_id` — runs the round-entry fetch protocol from `references/v2/round-feedforward.md` § 2. The six prior-round fetches (confirmed findings, reproduced bypasses, reusable `agent_observations`, critical-function ranking, slice coverage, fuzz artifacts/frontiers) fold into the Phase 0 seed so this round resumes at the prior frontier instead of cold. Crucially, a prior-round **reproduced bypass pre-seeds `critical_functions.factor_bypass_prior`** for the broken defense's critical function *before* the hunt ranks (feeds § Critical-Function Hunt below), and prior fuzz artifacts resume Phase 1.5 instead of cold-starting. Tier gating: LOW fetches confirmed findings + blind-spots only; MEDIUM adds bypasses + CF ranking; DEEP runs all of these plus full `coverage_carry_json` reconciliation **and** fetch (8) — the prior round's unconsumed **methodology blind-spot directions** (`v_methodology_blindspots_ranked WHERE open_direction`), which become this round's candidate lanes/priorities first (stamping `promoted_to_round_id` when acted on). Every `agent_steps` row this round sets `round_id` to the ledger id. First round on a target: the fetch is empty and `parent_round_id` is NULL.

The fetches are **not poured in unbounded** (#4, per `references/v2/round-feedforward.md` § 2a). The orchestrator fills each phase's seed by walking a fixed **deterministic priority order** (reusable observations → fuzz resume artifacts/frontiers → tier-1 critical functions → findings above the `recurrence_bar` → top knowledge chunks by acceptance), so the same DB state always yields the same fetched set. The caps live in `db/seed/fetch-budgets.yml` — hard per-source `row_caps` and a soft `token_budget` per fetch phase — and `tier_multipliers` (LOW 0.4 / MEDIUM 0.7 / DEEP 1.0) scale one budget set across tiers rather than duplicating it. All caps are applied as `LIMIT ?` / post-fetch truncation; the six fetches always bind through placeholders (single-writer, parameterized reads), never string-built SQL. Knowledge-chunk acceptance (#5) is a **sort key, never a gate** — no chunk is excluded by acceptance alone.

### Critical-Function Hunt (ranked registry)

Per `references/v2/critical-function-hunt.md`. After sinks/defenses are catalogued, the orchestrator runs a critical-function hunt that identifies the functions a security property depends on (auth/authz checks, deserializers, input validators, crypto operations, parsers, path/URL canonicalizers — the `cf_category` taxonomy) and writes ranked `critical_functions` rows. Each row carries the **six** weighted factors (`factor_reachability`, `factor_blast_radius`, `factor_attention_deficit`, `factor_privilege_delta`, `factor_bypass_prior`, `factor_recurrence_prior`) → `rank_score` → `rank_tier` ∈ {tier1, tier2, tier3}, plus `cf_category`, `sink_id`/`defense_id` links, and `classification_evidence_json`. **The factor weights are not hard-coded:** they live in the `scoring_config` table (`scope = 'rank_score'`, seeded from `db/seed/scoring.yml`), and the authoritative score is recomputed read-time by the `v_critical_fn_ranked` view (`rank_score_computed`), so re-weighting is a config edit — never a code change. A prior-round bypass (§ Round Entry) raises `factor_bypass_prior` before scoring, and `factor_recurrence_prior` carries forward how often this function — or a 1-hop `call_edges` neighbour — has historically anchored confirmed findings (`references/v2/critical-function-hunt.md` § 7), so a previously-bypassed or recurrently-vulnerable function starts already tier-promoted. Tier gating: LOW persists a top-2 floor; MEDIUM runs the full hunt + ranking; DEEP additionally drives source→CF reachability (Phase 0.5 `critical_fn_reach`). The ranked registry (read via `v_critical_fn_ranked ORDER BY rank_score_computed DESC`) drives which functions get both-direction data-flow in Phase 0.5.

### Preliminary Phase Gating

| Preliminary lane (skill) | LOW | MEDIUM | DEEP |
|---|---|---|---|
| **File Vuln-Rating** (`references/v2/file-vuln-rating.md`) — **first step of Phase 0**; cheap heuristic P(crit/high) over every in-scope file + LLM triage on the ambiguous middle; orders the worklist read-time via `v_file_vuln_ranked`; **never gates** (low/absent rating de-prioritizes, never excludes); analysis-derived signals (SP regions, findings, reachable sinks) feed back as raw factors and rerank the remaining queue | ✓ heuristic ordering (no LLM middle-band triage) | ✓ heuristic + LLM middle-band triage | ✓ heuristic + LLM middle-band triage + full feedback rerank |
| **L0 — Latest-Commits Recency** (`references/phases/phase-L0-recency.md`) | ✓ recency subagent (no PATCH SEEDS persisted) | ✓ recency subagent + optional PATCH SEEDS | ✓ + **PATCH SEEDS** persisted as `sources(source_kind='patch_seed')` |
| **L1 — Recon** (`references/phases/recon-checklist.md`) | ✓ core: stack fingerprint + runtime version gates + input-vector map | ✓ full: + endpoint map + dependency manifest + known-CVE lookup + stateful/protocol inventory when applicable | ✓ full + `patch-package`/overlay hunk read + full dependency CVE sweep + trace/response/state abstraction inventory |
| **L2 — Crown-Jewel Mapping** | ✓ light: data assets + privilege boundaries | ✓ full 4-category (data / privilege / trust transitions / business logic) | ✓ full 4-category |
| **L2 — Attention-Deficit Mapping** (`references/phases/attention-deficit.md`) | — skipped (LOW does no module fan-out) | ✓ heuristics on candidate modules | ✓ full scan, all five signals → feeds `phase0_priorities` + `promotion_score` |
| **L3.5 — Tech-Stack Sink Loading** (`references/sinks-catalog.md`) | ✓ matched per-language sink file only | ✓ + curated public Semgrep packs | ✓ + custom packs (PHP 439-rule `semgrep-rules/php/`, C/C++ 555-rule `semgrep-rules/c-cpp/`) + binary-stack triggers (`references/binary/binary-stack-triggers.md`) when compiled artifacts present |
| **Intended-Feature Classification** (Semgrep + LLM batch, spec §3) | ✓ (G3 gate needs it in every tier) | ✓ | ✓ |
| **Autoload knowledge seed** (top-K=10, `references/v2/autoloading-knowledge-layer.md`) | ✓ | ✓ | ✓ (DEEP also runs the **expand** pass post-Confirm — see § Autoload Knowledge Layer) |

A lane marked "—" is intentionally skipped at that tier, not deferred. **DEEP has no "—": it runs every preliminary lane.** Each lane's own skill-side fallbacks (e.g. Phase L0: no git / < 3 commits / docs-only / subagent failure) still apply within its tier.

**Orchestrator writes (one transaction).** The `sources`, `sinks`, `defenses`, and `critical_functions` writes are **whole-tree, finding-agnostic enumerations produced before the hunt** — every instance in the in-scope tree is recorded because it is *there*, never because a smell or chased bug led to it. Ranking orders this complete set; it never narrows what is enumerated (SKILL.md § Preliminary-inventory completeness contract). This enumeration runs as the gated `preliminary_enumeration_lane` (strategy id 15, phase token `phase0_decompose`; materialized at Phase 0.5 like other roster lanes, surfacing as MISSING if never spawned).
- `round_ledger` — this round's row (opened at entry per § Round Entry), `effort_tier` lowercased, `parent_round_id` chained to the prior round; stamped with `priors_fetched_json` at entry, `seed_summary_json`/`coverage_carry_json` at exit
- `targets` (NK: `repo_url, commit_sha`) — created/upserted
- `sources` — **every** untrusted-input entry point in the whole in-scope tree (not just near suspected bugs), with `evidence_path:evidence_line` and `rank_score`
- `sinks` — **every** dangerous callee in the whole in-scope tree with `sink_category`, `evidence_path:evidence_line`, `rank_score`
- `defenses` — **every** sanitizer/blacklist/allowlist callsite in the whole in-scope tree (exhaustive, before the hunt — not only defenses adjacent to chased findings) with `defense_type`, `tier`, `parsed_logic_json`
- `critical_functions` — ranked registry (§ Critical-Function Hunt): `cf_category`, six weighted factors (incl. `factor_recurrence_prior`) → `rank_score` → `rank_tier`, `sink_id`/`defense_id` links, `classification_evidence_json`, NK `cf_hash`; weights externalized to `scoring_config`, authoritative score recomputed by `v_critical_fn_ranked`
- `phase0_priorities` — crown-jewel + attention-deficit ranking driving Phase 0.5 plan (attention-deficit factors populated MEDIUM + DEEP only)
- `intended_feature_classification` — Semgrep+LLM "this sink is the feature, not the bug" rows

**PATCH SEEDS** (MEDIUM optional, **DEEP required**, LOW skipped): the skill's Phase L0 deliverable. Stored as additional `sources` rows tagged with `source_kind = 'patch_seed'` whose `evidence_path:evidence_line` cites the fix hunk; the variant query lives in the symbol_path metadata. Downstream Hunt agents pull these via `SELECT … WHERE source_kind = 'patch_seed' AND target_id = ?`. LOW omits this persistence (its L0 pass is recency-only).

---

## ═══ Phase 0.5 — Plan (orchestrator, sequential) ═══

Per `references/methodology/forward-slicing-lanes.md` § Slice Tuple. The orchestrator decomposes the target into 8–15 modules (per `references/methodology/swarm-pipeline.md` § Module Decomposition), then emits `input_slices` rows with `slice_kind` chosen per tier:

- **LOW**: one `forward_taint` slice family per high-priority source.
- **MEDIUM**: `forward_taint` and `backward_sink` per module; `defense_callsite` per defense row.
- **DEEP** (promoted modules only): every applicable `slice_kind` per the applicability matrix in `references/methodology/swarm-pipeline.md` § Slice Types. Promotion uses `promotion_score` (crown-jewel +2, attention-deficit +2, patch-seed +1; floor = top-2 attention-deficit).

**Critical-function forward data-flow** (per `references/v2/critical-function-hunt.md` + `references/methodology/joern-forward-slicing.md`): for each ranked `critical_functions` row, the orchestrator plans data-flow in **both** directions:
- **source → critical-function reachability** — emit `critical_fn_reach` rows (`reach_status` ∈ {reaches, blocked, unproven}, `hop_count`, `guard_path_json`) proving whether an attacker-controllable source can drive the function. MEDIUM does this for tier-1; DEEP for tier-1 + tier-2.
- **critical-function → downstream effect** — emit `input_slices` rows with `slice_kind = 'critical_fn_forward'` and `critical_fn_id` set, slicing forward from the function to its security-relevant sinks. MEDIUM for tier-1; DEEP for every promoted critical function.

Concrete CPGQL for both directions and the explicit `coverage_json` measurement each lane must report live in `references/methodology/joern-forward-slicing.md`.

The orchestrator then schedules `agent_steps` rows pointing at those slices, with `strategy_id` references into the `strategies` seed (see `db/seed/strategies.yml`). Orthogonal-strategy rule from `references/methodology/swarm-pipeline.md` § Orthogonal Strategies applies — across the scheduled pool, ≥ 2 distinct strategies must be present in MEDIUM, every applicable strategy in DEEP.

**Stage 0 context profiling** (MEDIUM + DEEP): before flushing `agent_steps`, the orchestrator runs the relevance-score pass from `references/methodology/swarm-pipeline.md` § Context Profiling and drops below-threshold slices. When the optional `function-context` strategy is selected, DEEP builds VulnLLM-R-style target/context function packets with CodeQL/CPG/LSP call paths, guard helpers, validators, tests, and config gates, persists them as reusable `agent_observations(tool_output)` rows, and lets agents emit `context_insufficient` instead of guessing.

---

## ═══ Phase 0.75 — Defense Pre-Break (swarm → queue → orchestrator flush) ═══ *(MEDIUM + DEEP)*

> **Bypass runs BEFORE the hunt, not after.** The skill's S2 doctrine **"there always is a bypass"** is most useful applied to the *defense inventory* up front: a defense that turns out to be breakable should never make the hunt dead-end on a path through it, and should never let Confirm's G2 gate refute a real finding. Phase 0.75 breaks the Phase-0 `defenses` in isolation — **finding-agnostic** (no findings exist yet) — and hands the resulting **defeated-defense set** to Hunt and Confirm.

Per `references/v2/bypass-catalogue.md` (tiered fetch + §§ 6–8 stage ladder / exhaustion / cascade). `defense_bypasses` is keyed on `defense_id`, **not** on any finding, so pre-break populates it naturally with no schema change. For every defense catalogued in Phase 0 (the `defenses` rows, plus `critical_functions` whose `cf_category` is a validator / sanitizer / canonicalizer), schedule a pre-break lane:

- `defense_base_lane` (strategy id 3) — Stage A enumerate applicable bypass-family labels from the global `bypasses` catalogue (filtered by `defense_type` + `generic`); Stage B record skip-with-reason for non-applicable families; Stage C lazy-fetch one family's payload corpus at attempt time. Payloads stay out of agent context until then.
- `defense_context_verification_lane` (strategy id 4) — for each catalogued `defenses` row, confirm the defense actually **fires at its callsites** (finding-agnostic, callsite-level), so a defense that never fires is known before the hunt and is not mistaken for protection. The finding-*specific* recheck — does it fire on *this* finding's callsite under *this* `config_state` — is the thin Phase 3 use of the same lane. This lane is on the Phase 0.75 roster (`v_required_deep_lanes`; SKILL.md § Mandatory DEEP Lane Roster), not Phase 3 only.
- `isolation_fuzz_lane` (strategy id 5, DEEP) — wrap the sanitizer/validator as a callable and fuzz it against its bypass corpus for every `defenses.isolation_eligible = TRUE` row, within its `isolation_cost_json` budget (`stage_reached = 'isolation_fuzz'`). This is the **defense-corpus** fuzzer — distinct from Phase 1.5's `boundary_fuzz_lane` (`references/v2/fuzzing-lane.md` § 0).
- `html_sanitizer_bypass_lane` (strategy id 11, **MEDIUM + DEEP**) — runs **late** in Phase 0.75, after `defense_base_lane` has populated the `defenses` table (which is the lane's reuse source). Discovers every HTML sanitizer / allowlist / regex filter via union of 3 sources: (1) reuse of existing `defenses` rows, (2) HTML-sanitizer pattern sweep (`htmlspecialchars`/`htmlentities`/`strip_tags`, `preg_replace` filters, scheme/tag allowlists, markdown safe-mode, `*Validator::validate`), (3) AST + taint role-based discovery (transform/validate functions on source→HTML-sink paths via `input_slices`/`critical_fn_reach`). Each row carries `discovery_method` (reuse|pattern_sweep|ast_taint) + `discovery_confidence` (multi-source ranks higher); misses logged as `agent_observations` with `obs_kind='blind_spot'`. Enriches `defenses` rows with rich labels (`mechanism`, `enforcement_mode`, `input_context`, `fail_mode`, `library_origin`) and computes `reachability` (proven|suspected|none) from callsite–source join — stored as a label, never a discovery filter. ALL sanitizers catalogued; only `proven`/`suspected` handed to the engine; `none` stored + skipped. The agnostic engine (`engines/html-sanitizer-bypass/` — PHP runner + jsdom oracle + corpus builder + `corpus_data/`) runs **out-of-band as a subprocess** and emits compact row-shaped JSON to stdout; the orchestrator is the sole DuckDB writer. Oracle: per-payload BYPASS = sanitized output reparsed in jsdom reaches a live sink for the payload's `injection_context`; hit → `defense_bypasses` row; no hit = PASS. Verdict: one `sanitizer_bypass_runs` row per reachable sanitizer — `bypassed` (≥1 hit) / `clean` (full corpus, 0 hits; first-class stored robustness result; existing clean verdict for same `(defense_id, corpus_version)` → skip re-run) / `inconclusive` (harness error). Lane-done gate: every `proven`/`suspected` defense has a stored verdict or documented skip. Reference: `references/methodology/html-sanitizer-bypass-lane.md`. DEEP gate: lane is in `v_required_deep_lanes` (blocking); MEDIUM requirement encoded here + prose (no separate `v_required_medium_lanes` view).

A lane reporting `exhausted` MUST carry `defense_bypasses.exhaustion_log` proving it iterated every applicable family; the orchestrator re-runs the Stage-A enumeration and rewrites any lane whose log fails the diff (`references/v2/bypass-catalogue.md` § 7). **The LLM may not invent novel bypass categories** — corpus-anchored oversight only.

**The defeated-defense set.** Each defense broken in isolation is a `defense_bypasses` row with `reproduced = TRUE`. Their union for this round is the defeated-defense set, which feeds three consumers:

1. **Hunt (Phase 1).** A defeated defense on a candidate path is **not** a safe stop. Hunters fetch the set (`SELECT defense_id … FROM defense_bypasses WHERE reproduced = TRUE AND round_id = ?`) and do not log a `dead_end` on a path a known-broken defense "protects."
2. **Confirm G2 (Phase 2).** G2 (defense gap) treats a defense in the defeated set as **non-neutralising** — it cannot by itself refute a finding whose only protection was shown bypassable this round. (Phase 3 still rechecks that the break applies on the finding's concrete path.)
3. **Critical-function pre-rank.** If a broken defense maps to a `critical_functions` row (via `defense_id` / `symbol_path`), the orchestrator raises that function's `factor_bypass_prior`, recomputes `rank_score`, and — if it crosses a tier — schedules **supplementary** `input_slices` + `agent_steps` for it at the 0.75 → 1 boundary, so the hunt opens already prioritising functions guarded by broken defenses. This is the pre-hunt analogue of the old post-confirm cascade-on-critical-function (`references/v2/critical-function-hunt.md` § 5).

**Cross-round feed-forward.** Each pre-break row sets `carried_from_bypass_id` (when it continues a prior round's bypass) + `round_id`; a defense broken in round N pre-seeds `factor_bypass_prior` for its critical function before round N+1 ranks. The round-entry fetch (`references/v2/round-feedforward.md` § 4) reads prior reproduced bypasses; Phase 0.75 is where this round *produces* them.

`defense_bypasses` rows carry `(defense_id, agent_step_id, technique, bypass_family, payload, parsed_logic_json, exhaustion_log, stage_reached, severity, reproduced, cascade_emitted_finding_ids, cascade_emitted_source_ids, carried_from_bypass_id, round_id)` (`references/v2/bypass-catalogue.md` §§ 6–8). All cascades fire at orchestrator flush (single-writer); lanes queue intents, never spawn lanes directly.

---

## ═══ Phase 1 — Hunt (swarm → queue → orchestrator flush) ═══

For every `agent_steps` row scheduled in Phase 0.5, spawn a hunt agent. The agent receives:

- Its assigned `input_slices` tuple (slice_id, slice_kind, entrypoint, source_nodes[], sink_node, path[], control_guards[], sanitizers_seen[], coverage_json) — **not** raw file blobs
- A one-line sibling-module index (no cross-module file dumps)
- Patch seeds filtered to its module (`source_kind = 'patch_seed'`)
- Strategy prompt resolved from `strategies` table

**Posture per `--freeform`:**
- `detached` (default): agent receives the minimal brief from `references/methodology/freeform-detached.md` § Detached, **no** skill taxonomy
- `grounded`: agent additionally receives `SKILL.md` + matching `references/sinks/<lang>.md`

**Internal three-stage pass per agent** (briefing → class-enrichment → skeptical arbiter, per `references/methodology/swarm-pipeline.md` § Three-Stage Pass). Only candidates that survive the arbiter are emitted as `gr_findings` row events.

When a hunt agent receives a function-context packet, it must preserve `target_function`, `context_functions[]`, `call_paths[]`, `policy_candidates[]`, and `context_sufficiency`. A candidate with insufficient context may be emitted as `gr_findings.confirmation_status='candidate'` (or as an `agent_observations` `blind_spot` / `partial_trace`) with the missing context named in payload; it cannot be promoted to `confirmed` until Confirm resolves those missing facts.

**Sink-hunter lane** (MEDIUM + DEEP): one parallel agent cross-cutting modules, file-anchored, loading the skill's sinks router (`references/sinks-catalog.md`) + matching per-language sinks files for the detected stack, with patch-seed variant queries.

**DEEP — slice-kind fan-out**: each promoted module spawns one hunt agent per applicable `slice_kind`. Findings carry `discoverer_slice_kind` in their payload metadata.

**Row event shape per agent:**
```json
{"kind": "gr_findings", "row": {
  "target_id": ..., "finding_kind": "...", "sink_id": ..., "source_id": ..., "defense_id": ...,
  "agent_step_id": ..., "confirmation_status": "candidate", "config_state": "unknown",
  "payload": {
    "evidence_path": "...", "evidence_line": ...,
    "discoverer_strategy_id": ..., "discoverer_slice_kind": "...",
    "trace_json": {...}
  }
}}
```

The top-level keys are real `gr_findings` columns; everything under `payload` is finding metadata serialized into the `payload` TEXT column (kept inline ≤ 16 KB, else spilled to the sidecar with `payload_sidecar_path` set). `finding_hash` is **not** supplied by the agent — the orchestrator derives it from the NK at flush.

**Reasoning capture — `agent_observations`** (per `references/v2/db-logging-and-context.md`): besides candidate findings, every hunt agent emits structured reasoning rows so the next round reuses them instead of re-deriving. Emit `dead_end` (path looked promising, proved safe), `invariant` (a property that holds), `guard_observed` (a sanitizer/check on the path — feeds Phase 3 targeting + critical-function defense links), `hypothesis`, `assumption`, `blind_spot` (code you could not examine), with `reusable` set true for facts about the code. Row-event shape: `{"kind":"agent_observations","row":{"target_id":…,"agent_step_id":…,"obs_kind":…,"symbol_path":…,"evidence_path":…,"evidence_line":…,"body":…,"confidence":…,"reusable":true}}`; `obs_hash` (sha256 of `agent_step_id|obs_kind|symbol_path|body`) makes replays idempotent. Tier-gated logging depth: LOW = `dead_end`+`blind_spot` only; MEDIUM adds `hypothesis`/`invariant`/`guard_observed`/`assumption`; DEEP adds `partial_trace`/`tool_output`. `dead_end`/`invariant`/`blind_spot` are mandatory in every tier.

**Enriching preliminary artifacts (every hunt agent, all tiers).** Hunt agents are not write-only producers of new findings — **every** hunt agent (freeform, the sink-hunter lane, and every slice-kind fan-out agent) **can and is encouraged to enrich the preliminary artifacts** the earlier phases recorded: the Phase-0/0.5 `sources`, `sinks`, `defenses`, `critical_functions`, and any candidate `gr_findings`. Enrichment is **append-only** and goes through the single-writer queue — never a direct DB write. The agent emits an `agent_observations` row anchored to the target artifact by its `symbol_path` + `evidence_path:evidence_line` (with the artifact's id in the body): e.g. a `guard_observed` deepening a `defense`'s parsed logic, an `invariant` refining a `sink`'s reachability, a `hypothesis` that a Phase-0 `source` is richer than first recorded, a `dead_end`/`note` correcting a misclassification. The next phase and the next round read these (joining on `symbol_path`), so a preliminary artifact accretes a reasoning halo instead of being re-derived. When an enrichment must change the artifact's **own** ranked field (promote a `critical_functions.rank_score`, flip a `critical_fn_reach.reach_status`), the agent flags it on the observation and the **orchestrator** applies the field change at flush, citing the observation — agents still never mutate rows directly. See `references/v2/db-logging-and-context.md` § 7.

**Suspicious-Point emission (side-output, no new lane).** Besides candidate findings and observations, every hunt agent **also** emits **Suspicious Point** row events — domain-agnostic, high-recall, region-level vulnerability hypotheses that screen attacker-relevant regions *before* the precision-oriented `gr_findings` tier. This is a **side-output of the existing hunt lanes, not a new mandatory lane** — the DEEP roster and `v_required_deep_lanes` are unchanged. An agent emits one `suspicious_points` row per flagged region (region anchor + `vuln_class` + emitting `lane`, **no** stored score, **no** `confirmation_status`/PoC) plus raw `suspicious_point_factor` rows (free-TEXT `factor_name` keyed into the `sp_factor_config` catalog). The orchestrator dedups DB-native at flush (UNIQUE natural key + `ON CONFLICT` increments `dedup_cluster_size`); the composite is computed **read-time** by `v_suspicious_points_ranked` (within-round percentile-rank, hard gates, never stored). An SP **graduates** to a `gr_findings(candidate)` when its taint-reach DAG closes (G1) or a crash/PoC lands — the five-gate Confirm is unchanged and `sp.graduated_finding_id` links the two; an SP that screens out becomes a fuzz seed (Phase 1.5, existing `references/v2/fuzzing-lane.md` §10 path). `v_sp_factor_coverage` flags any `weight<>0` factor with no producer this round as `MISSING`; the orchestrator MAY spawn a **non-mandatory** preliminary lane (strategy id ≥ 12, never added to `v_required_deep_lanes`) to fill it. Full contract: `references/v2/suspicious-point-tier.md`.

The orchestrator flushes at end-of-phase. `finding_hash` UNIQUE constraint over the derived NK ensures re-runs over the same `commit_sha` update rather than duplicate; observation rows flush in the same phase transaction.

**Finding identity & sightings (#1, per `references/v2/db-logging-and-context.md` § 8).** `finding_hash` is **commit-independent** — it identifies the *vulnerability*, not the snapshot — so the same bug seen at two commits is one `gr_findings` row, not two. Each time the orchestrator observes a finding (this round, or a later round after the code moved), it appends a `finding_sightings` row keyed on `(finding_hash, commit_sha, change_scope)` carrying `verdict` and, when the code moved, the `from_*` triple. Sightings are **append-only** — staleness is expressed by a newer row, never by mutating an old one — so `v_finding_changes` can show exactly how a finding migrated across commits. A re-observation that did not change verdict is the non-flapping `needs_attention` case (no status mutation, just a sighting).

---

## ═══ Phase 1.5 — Fuzzing (swarm → queue → orchestrator flush) ═══ *(DEEP)*

> **In a deep swarm, fuzzing must happen.** A dedicated lane finds crashes, deterministic C/C++ leaks, and state/property/differential divergences with applicable fuzzing tools available on the host and within budget, then feeds each result into Phase 2 Confirm as a `gr_findings` candidate (`finding_kind = 'fuzz_crash'` or `fuzz_divergence`). Full methodology, tooling matrix, recording contract, and lane identity: `references/v2/fuzzing-lane.md` (C8). Agent steps log under `boundary_fuzz_lane` (strategy id 10) — deliberately distinct from Phase 0.75's `isolation_fuzz_lane` (id 5).

**Mandatory-attempt.** DEEP MUST run this lane; LOW/MEDIUM do not. Two legitimate outcomes only: it **ran** (≥ 1 entry point harnessed + fuzzed under sanitizers, recorded as a `fuzz_runs` row), or it **skipped-with-reason** (a non-fuzzable target — a `fuzz_runs` row with `engine = 'none'`, `entry_point` NULL, and a `skip_reason` whose `coverage_json.checked[]` proves there is no native / parser / FFI / protocol-session attack surface). The orchestrator verifies the skip log before accepting the lane as exhausted — the same discipline as the bypass exhaustion log. The bar to skip is "no harnessable boundary/state surface," never "fuzzing is hard here."

**Existing-pipeline recon first.** Before harnessing anything, recon what already exists — OSS-Fuzz / ClusterFuzzLite integration, in-tree fuzz targets (`fuzz/`, `LLVMFuzzerTestOneInput`, Rust `fuzz_targets/`, Go `FuzzXxx`, Jazzer `@FuzzTest`), seed corpora, CI fuzz jobs — and reuse it. Record the recon in `fuzz_runs.existing_pipeline` and set `reused_existing_pipeline`. A continuously-fuzzed target means the lane targets the *deltas* (patch-seed code, newly added parsers), not covered ground.

**Tooling, always paired with sanitizers** (`references/v2/fuzzing-lane.md` § 3): C/C++ → AFL++ / libFuzzer / honggfuzz + ASan / UBSan / MSan / **LSan**, concolic (KLEE / SymCC) on coverage stalls; Rust → cargo-fuzz + Miri; Go → `go test -fuzz` + `-race`; Java/JVM → Jazzer (+ ASan/UBSan on JNI); protocol/stateful targets → AFLNet/StateAFL/boofuzz-style harnesses where available. For C/C++, LSan leak discovery is equal-priority with crash discovery: deterministic leaks are deduped by leak stack/signature, recorded as `fuzz_crash` candidates with repro input + LSan report, and counted as distinct fuzzing bugs even when non-crashing. Entry-point selection is **surface-driven**: native parsers / decoders / deserializers, protocol/session handlers, FFI/JNI boundaries, tier-1 `critical_functions`, and patch-seed-adjacent code reachable from an untrusted `sources` row.

**Hybrid and stateful coverage** (`references/v2/fuzzing-lane.md` §§ 3a, 4a, 8): when seeds exist, run FS (fuzzing → directed symbolic execution) against uncovered call-graph frontier nodes; when seeds are missing, run SF (symbolic execution → fuzzing) to create diverse seed inputs. For stateful targets, model messages vs traces, define response/state abstraction functions, mutate trace order/drop/repeat/insert/splice/replay, and record states/transitions/response classes in `coverage_json`.

**Recording — BOTH** (`references/v2/fuzzing-lane.md` §§ 5–6):
- Each distinct crash, deterministic C/C++ leak, or divergence (deduped by sanitizer token, stack/leak signature, or state/differential signature) → a `gr_findings` row event with `finding_kind = 'fuzz_crash'` or `fuzz_divergence`, `confirmation_status = 'candidate'`, severity from the sanitizer→severity map or resulting bug class, and the repro input/trace + sanitizer/state evidence in `payload` (sidecar if > 16 KB; sidecar filename = content hash only).
- The run → a `fuzz_runs` row event: `engine`, `sanitizers[]`, `reused_existing_pipeline`, `existing_pipeline`, `coverage_json`, `crash_count` (distinct bugs, not raw crashes), `emitted_finding_ids` (the `gr_findings` ids), `round_id`; or a skip row as above. `fuzz_run_hash` is derived by the orchestrator at flush.
- The resumable state → `fuzz_artifacts` row events for retained seeds/corpus entries, symbolic seeds, dictionaries, queue checkpoints, coverage frontiers, state traces, and crash/divergence reproducers. Do **not** store every attempted mutation by default; store all retained/resumable inputs and enough manifests/checkpoints to continue deterministically.

**Suspicious-Point emission (side-output, no new lane).** Like the Phase 1 hunt lanes, the fuzz lane **also** emits `suspicious_points` + `suspicious_point_factor` row events for attacker-relevant regions it surfaces (e.g. a stalled-coverage frontier function, a near-miss input class) — a side-output, **not** a new mandatory lane, so `v_required_deep_lanes` is unchanged. A crash/PoC that lands **graduates** the corresponding SP to a `gr_findings(candidate)` (`sp.graduated_finding_id` linked, five-gate Confirm unchanged); an SP that screens out becomes a fuzz seed via the existing `references/v2/fuzzing-lane.md` §10 path. Scored read-time by `v_suspicious_points_ranked`, never stored; coverage gated by `v_sp_factor_coverage`. Full contract: `references/v2/suspicious-point-tier.md`.

**Handoff into Confirm.** A `fuzz_crash` is a candidate, not a confirmed vuln; it runs the five-gate doctrine. **G4** (reproduction artifact) is satisfied by construction for a memory-safety crash — the crashing input *is* the artifact — but **G1** (reachable from a real untrusted source in the deployed app, not just the harness), **G2** (no defense on the real path neutralises it — consult the Phase 0.75 defeated-defense set), and **G3** (not a test-only / harness artifact) still gate. A crash reachable only through the synthetic harness is refuted at G1 (`refutation_reason = 'not_reachable'`). A crash inside a `critical_functions` row re-ranks that function (cascade-on-critical-function).

---

## ═══ Phase 1.6 — Methodology Blind-Spot Sweep (swarm → queue → orchestrator flush) ═══ *(DEEP)*

Runs **after all discovery sweeps** for the `(target, round)` — Phase 1 Hunt and Phase 1.5 Fuzzing. Two **identical, independent** lanes (`methodology_blindspot_lane_a`, `methodology_blindspot_lane_b`; the dual-seed-corpus precedent — one prompt, two instances, diversity from LLM stochasticity) answer one goal:

> **"Find any blind spot in our codebase-analysis methodology."**

Each lane returns blind spots in **two clearly-separated classes** (`methodology_blind_spots.gap_class`): **`process`** (HOW we analyzed — a bug class never checked, a lane that should exist but doesn't, an assumption left untested, a source/sink/defense *type* not enumerated) and **`coverage`** (WHAT this run never reached — a module/region no slice or fuzz target touched). This is a **higher-altitude critique**, deliberately distinct from the frontier-coverage `agent_observations(obs_kind='blind_spot')` that `cpg_coverage` already emits.

**Merge = content-hash union-dedup (DB-native).** Each blind spot hashes into `blindspot_hash` (UNIQUE); lane B's duplicate of a lane-A gap hits `ON CONFLICT DO NOTHING` and the orchestrator flips `agreement='both'` + bumps `dedup_cluster_size` — agreement across two independent instances is the confidence signal. No separate merge agent: the UNIQUE constraint *is* the merge.

**Feed-forward, not this-run work.** The merged directions are ranked read-time by `v_methodology_blindspots_ranked` (unconsumed first, both-lane agreement above single, recurrence next) and consumed by the **next round** via round-feedforward fetch (8); the orchestrator stamps `promoted_to_round_id` when it acts on one. They do **not** spawn lanes this run.

**Persistence + gates.** One `methodology_blind_spots` row per merged direction + one companion reusable `agent_observations(obs_kind='blind_spot')` per row (satisfies the every-phase observation flush; `obs_kind` is not widened). Both lanes are in `v_required_deep_lanes` (`phase1_6_blindspot`): each must run or record a documented skip (`v_lane_coverage` MISSING = HARD RED) and leave ≥1 observation (`v_observation_coverage`). `v_coverage.methodology_blindspots_unpromoted` is an inspect-**signal**, not an auto-red (the latest round always has unconsumed directions). Full contract: `references/v2/methodology-blindspot-sweep.md`.

---

## ═══ Phase 2 — Confirm (swarm → queue → orchestrator flush) ═══

For every candidate `gr_findings` row, schedule confirm-agent calls **as separate prompts in separate contexts** — the confirm agents must not be told of each other's verdicts, and must not be the finding's discoverer.

**Per skill § Phase S3 (2-check) and `references/v2/confirmation-rigor-doctrine.md` (C1 five gates):**

1. **RE-TRACE** (all tiers) — independent source→sink walk: does the path exist as claimed? Does the source remain controllable through all transforms? Verdict: pass / fail.
2. **JUDGE** (MEDIUM + DEEP) — semantic-correctness review with **structured DAG** per `references/methodology/dag-reasoning.md` § "Phase S3 Agent-Sweep Verification". JUDGE must close a DAG from an untrusted `source` to a `verified_sink`; a JUDGE pass that cannot close the graph is **fail** — no hedging.
3. **DAG-INDEPENDENT** (DEEP only) — reconstruct the reasoning DAG from scratch against the cited code, independent of the trace prose. Verdict: confirms / contradicts.

**Five-gate doctrine applied at orchestrator flush** (every tier):
- **G1 taint reach**: source actually flows to sink under the cited guards
- **G2 defense gap**: no Tier-1/Tier-2 defense on the path neutralises the taint — **a defense in the Phase 0.75 defeated-defense set does not count as neutralising** (it was shown bypassable this round; Phase 3 rechecks the break on this finding's concrete path)
- **G3 intended-feature filter**: row is NOT classified as `intended_feature_classification` for this sink
- **G4 reproduction artifact with `config_state`**: a payload (inline or sidecar) + a non-`unknown` `config_state`, produced by **Phase 4 Proof** — or already carried by construction on a Phase 1.5 `fuzz_crash`, or forwarded from a prior round. Promotion to `confirmed` happens where G4 is satisfied, which in the normal path is **Phase 4** (§ Phase 4 — Proof), not here. **LOW skips Phase 4**, so G4 is unreachable there and LOW cannot promote.
- **G5 consumer harm**: a sink reached is **not** a consumer harmed. An `impact_proofs` row must name the default-config component that reads/dispatches/trusts the tainted value + its `harm_class` (and the `proven_reachability` / `mechanism_cap` factors severity is derived from). `v_justification_coverage` red-flags any `confirmed` finding lacking one; the `vrdb promote` verb REFUSES a finding with no `impact_proofs` row.

**Verdict combination — Phase 2 yields the agent-check verdict + G1–G3; it does not promote on its own.** Because G4's artifact is a Phase 4 product, a finding cannot satisfy G4 at Phase 2 in the normal path: a finding whose agent checks and G1–G3 all pass stays `candidate` and carries that partial verdict into Phase 4, which supplies G4 and performs the `confirmed` flip. Promotion *at* Phase 2 is the exception, reserved for a finding that **already** carries a G4 artifact — a `fuzz_crash` (artifact by construction) or a prior-round finding whose payload + `config_state` carried forward.
- **LOW**: re-trace pass + G1–G3 pass → stays `candidate` (LOW skips Phase 4, so it terminates at `candidate`); fail → `refuted`, refutation row written carrying the failed gate's `refutation_reason`.
- **MEDIUM**: both checks pass + G1–G3 pass → `candidate` pending Phase 4 (promoted to `confirmed` now only if a G4 artifact already exists); one check passes → `candidate`; both fail → `refuted`.
- **DEEP**: all three checks pass + G1–G3 pass → `candidate` pending Phase 4 (promoted to `confirmed` now only if a G4 artifact already exists); 2 of 3 → `candidate`; ≤ 1 → `refuted`.

Refutations land in `refutations` with `(finding_id, agent_step_id, refutation_reason, evidence_json)` — the `refutation_reason` enum (`not_reachable`/`sanitized`/`intended_feature`/`wrong_role`/`preconditions_unmet`/`env_required`/`other`) records which gate failed.

**Status-transition meta-logging (#6, per `references/v2/db-logging-and-context.md` § 9).** Every `confirmation_status` change the orchestrator applies at flush (candidate→confirmed, candidate→refuted, …) emits an append-only `mutation_log` row: `op = 'status_transition'`, `row_key = finding_hash`, and `delta_json = {"col":"confirmation_status","before":…,"after":…}`. The log is for UPDATEs and status transitions only (not first inserts), with literal before/after for short values and a hash-ref for large payloads — so `v_finding_history` can unify a finding's `finding_sightings` and its `mutation_log` transitions into one ordered timeline, and the `vrdb history|diff|log` CLI can inspect any finding's evolution without re-running the audit.

**Recurrence feed-forward (#2, per `references/v2/critical-function-hunt.md` § 7).** When a finding is **confirmed** (or refuted), the orchestrator accumulates the confirmation-weighted recurrence signal for the `critical_functions` row(s) the finding anchors on: `recurrence_counter` gets a `+1` on confirm, `+0.3` on a still-open candidate, `−1` on refute (a `needs_attention` re-sighting with no verdict change contributes **no** delta), applied via `ON CONFLICT DO UPDATE` so replays are idempotent. The counter has **no time-decay**; it propagates 1 hop along `call_edges` (weight `w_nbr`, a sound under-approximation) and feeds `factor_recurrence_prior` on the CF — which the next round's hunt reads through `v_critical_fn_ranked` (§ Critical-Function Hunt), so a function that has historically anchored confirmed bugs starts the next round already tier-promoted.

---

## ═══ Phase 3 — Bypass-Recheck (swarm → queue → orchestrator flush) ═══ *(MEDIUM + DEEP)*

The heavy bypass work already ran **pre-hunt** in Phase 0.75 against the defense inventory. Phase 3 is the **thin, finding-specific** recheck: for a surviving `candidate`/`confirmed` finding, does the defense actually fire on *this* finding's callsite under *this* `config_state`, and — where Phase 0.75 already proved the defense bypassable — does that break apply on this finding's concrete path? Per `references/v2/bypass-catalogue.md` (the stage ladder / exhaustion / cascade contract is phase-agnostic). For every defense on a `candidate` or `confirmed` finding's path:

- `defense_context_verification_lane` (strategy id 4) — verify the defense actually fires on the cited callsite under the finding's `config_state`. A defense that does not fire here strengthens the finding; a defense that fires and is **not** in the defeated set may refute it (back to Phase 2 G2).
- A **targeted** bypass attempt **only** where Phase 0.75 did *not* already defeat the defense — the family-space exhaustion is done and recorded, so this is not a re-enumeration. Where Phase 0.75 *did* defeat it, this lane just confirms the recorded `defense_bypasses` technique reproduces on this finding's concrete path/payload.

**Cascade triggers** (per `references/methodology/forward-slicing-lanes.md` § Cascade Semantics and `references/v2/bypass-catalogue.md` § 8):
- **cascade-on-bypass** (intra-run): a finding-specific bypass that opens a new path spawns a new Hunt lane back into Phase 1 with the payload as a `bypass_derived` `source` row; the cycle re-enters Phase 2 Confirm. Emitted ids land in `cascade_emitted_finding_ids` / `cascade_emitted_source_ids`, and the new step's `parent_step_id` points back at the recheck step.
- **cascade-on-reach**: a confirm-pass that reaches a sink under a non-`vanilla` `config_state` spawns a `defense_context_verification_lane` to check whether real deployments carry that config.
- **cascade-on-critical-function** + **cross-round feed-forward** now run **pre-hunt** (Phase 0.75 pre-rank + the cross-round entry fetch, `references/v2/round-feedforward.md` § 4). A Phase 3 finding-specific break that maps to a *newly* implicated `critical_functions` row still raises its `factor_bypass_prior` at flush, carrying into the next round.

All cascades fire at orchestrator flush (single-writer); lanes queue intents, never spawn lanes directly. `defense_bypasses` rows carry the same columns as Phase 0.75 (`references/v2/bypass-catalogue.md` §§ 6–8).

---

## ═══ Phase 4 — Proof (swarm → queue → orchestrator flush) ═══ *(MEDIUM + DEEP)*

For every finding still at `candidate` after Phase 2/3 cascades, schedule a proof agent that builds a PoC per skill § Phase L5 PoC Constraints.

**Zero mocking in the testing environment.** PoC runs against the unmodified target in a production-equivalent deployment. `config_state` is recorded as `vanilla`, `non_vanilla`, or `unknown`. The reproduction artifact (payload + harness) is written to `gr_findings.payload`; if > 16 KB it spills to `.vuln-research/sidecars/<finding_hash>.bundle` and the row carries `payload_sidecar_path`.

**Both PoC forms required** (skill § Phase L5):
- Step-by-step explanatory walkthrough (stored in `gr_findings.payload`, or the `.vuln-research/sidecars/<finding_hash>.bundle` when > 16 KB)
- Full bundled `docker compose up && ./poc.sh` directory (stored at `payload_sidecar_path` under `.vuln-research/sidecars/`)

A finding without both forms stays `candidate` — the five-gate doctrine refuses promotion.

**`audit_outcomes`** rows record the triage verdict: `(target_id, audit_run_id, outcome, finding_id, notes_json)` — `outcome ∈ {TP, FP, DUP, INTENDED, UNREACHABLE, INCONCLUSIVE}`, and `notes_json` carries PoC status, repro command, and screenshot/artifact references. The `config_state` lives on `gr_findings`, and the bundled PoC at `gr_findings.payload_sidecar_path`.

At orchestrator flush, candidate rows whose proof passed all five C1 gates get `confirmation_status := 'confirmed'`.

**Concrete gate-clearing sequence (the ONLY path to a GREEN `vrdb gate`).** `confirmed` is reachable solely through the harness verbs — a born-`confirmed` Put is rejected (the lockout). For each finding the orchestrator drives, in order:

1. **Put candidate** — `vrdb put gr_findings` with `confirmation_status='candidate'` (the discovery lane's row).
2. **Refutation** — `vrdb put refutations` with `(finding_id, agent_step_id, refutation_reason, evidence_json)`: the adversarial refute pass RAN and failed to stick (refute-before-confirm mandate).
3. **Critic OK** — `vrdb put critic_findings` with `(finding_id, check_kind='eligibility', severity='OK')`: the REPORT eligibility critic passed.
4. **Impact proof (Gate 5)** — `vrdb impact-proof <finding_id> --consumer-symbol … --harm-class … [--reachability-evidence …] [--proven-reachability proven|conditional|unproven] [--mechanism-cap dos_only|leak|write_what_where|none] --severity-basis "<how severity was derived from the rubric>"`. This writes the `impact_proofs` row naming the harmed default-config consumer. **It is a promote PRECONDITION** — skip it and step 5 refuses.
5. **Promote** — `vrdb promote <finding_id> --severity SEV --rigor-tier shallow|independent|reproduced`. In one tx the verb verifies (1) status=candidate, (2) ≥1 refutation, (3) critic eligibility=OK, (3b) an `impact_proofs` row exists (and `--severity` does not exceed any `mechanism_cap`-implied ceiling), then stamps severity + rigor, writes the `mutation_log` status_transition provenance, and flips to `confirmed`. Any failed precondition rolls back (row stays `candidate`).
6. **Gate** — `vrdb gate --db PATH --tier deep` now reads GREEN for this finding's justification gates (`v_promotion_coverage` JUSTIFIED + `v_justification_coverage` JUSTIFIED), provided the process gates (lanes ran, observations flushed, regexes mapped, etc.) are also satisfied. A finding **without a backing suspicious_point** (a `fuzz_crash` / L0 / direct-Hunt finding) is JUSTIFIED on steps 1–5 alone; an SP-originated finding must additionally show its backing SP carries a passing oracle (`v_sp_oracle_coverage`).

---

## ═══ Phase 5 — Report (critic agent → orchestrator) ═══ *(MEDIUM + DEEP)*

Per `references/phases/report-phase.md` and `references/v2/critic-rubric.md`. The critic agent runs three checks against every `confirmed` finding:

1. **Comprehension check** — does the finding's narrative match the trace? Misread invariants → CRITICAL.
2. **Eligibility check** — is the `config_state` reachable in real deployments? Table:
   - `vanilla` → **Pass**
   - `non_vanilla` → **WARNING** (stored structurally in `critic_findings`, finding still reports)
   - `unknown` → **CRITICAL** (blocks report; finding demoted to `refuted` at flush)
3. **Attack-scenario check** — is the chained-impact claim plausible against a real victim model? Speculative chains → CRITICAL.

**DEEP**: critic loads all 17 worked examples from the rubric (vs. the default subset MEDIUM uses).

**Severity storage contract**: CRITICAL `critic_findings` rows force the corresponding `gr_findings.confirmation_status` to `refuted` at flush, with a `refutations` row whose `refutation_reason = 'other'` cites the critic verdict (the specific failing check is recorded in the `critic_findings` row). The final report excludes them. WARNING rows ship.

**Final report** is rendered from a `SELECT * FROM confirmed_vulns` query (the view over `gr_findings WHERE confirmation_status = 'confirmed'`) joined with `audit_outcomes` and `critic_findings`. No standalone file is written — the report is materialised on demand from DuckDB.

---

## ═══ Phase 6 — Invariant Promotion (orchestrator → CANONICAL skill) ═══ *(terminal, all tiers)*

> **This phase closes the learning loop.** Every prior phase writes lessons to the **per-target DuckDB** — durable for the next round *on this target*, invisible to the next campaign on *any other* target. Phase 6 is the one place a confirmed, reusable invariant is **promoted into the canonical skill** so the next campaign on a different target inherits the guardrail inline. It restores the cross-target "skill-improvement feedback" write-back that the v2 rewrite dropped. Full procedure: `references/methodology/invariant-promotion.md`. The durable registry it writes into is `references/methodology/triage-invariants.md`.

Phase 6 is **terminal** — it runs after Phase 5 Report (after the final `confirmed_vulns` set is fixed) and is the last gate before the run is allowed to declare done. It is **not** target work; it is the orchestrator promoting this campaign's durable lessons.

**The promotion obligation.** For every

```sql
SELECT * FROM agent_observations
WHERE obs_kind = 'invariant' AND reusable = TRUE AND confidence = 'high'
```

row that does **not** already map to a row in `references/methodology/triage-invariants.md`, the orchestrator MUST do **one** of:

1. **Open a promotion entry** — a single atomic promotion comprising **all** of:
   - **Append** an `INV-id` row to `references/methodology/triage-invariants.md` (the append-only registry), generalized to a target-agnostic statement (the cited target becomes evidence, never the rule).
   - **Edit the matching gate / doc** the invariant enforces (the reference / phase doc / gate view that should now carry the cap), so the invariant is *enforced*, not merely catalogued. A registry row with no enforcement edit is an incomplete promotion.
   - **Version bump** the skill (`SKILL.md` frontmatter `version:` + the command, per house wiring rules).
   - **CHANGELOG line** appended to `CHANGELOG.md` in the canonical form: `vX.Y.Z — promoted INV-id (learned in <campaign>, finding ids …) → <gate/doc edited>`.
2. **Record a `promotion_skipped` reason** — an explicit, durable reason the invariant was *not* promoted (e.g. already covered by an existing `INV-id`, target-specific and does not generalize, duplicate of a pending entry). A silent non-promotion is not allowed.

**Gate — `v_invariant_promotion_coverage` (HARD RED).** This view (owned by the schema/harness tier) is **RED while any** `agent_observations(obs_kind='invariant', reusable=TRUE, confidence='high')` row has **neither** a `triage-invariants.md` promotion entry **nor** a recorded `promotion_skipped` reason. The orchestrator does **not** declare the run done while this view is red — the mechanism the audit-doc graveyard always lacked (a recommendation that is *inert unless something fails when it is absent*). Phase 6 is the only phase that can clear it.

**Canonical-only write rule (load-bearing).** ALL Phase 6 edits — `triage-invariants.md`, the gate/doc edit, the version bump, `CHANGELOG.md` — land in the **canonical** skill repo (`/home/x/Personal_Projects/vuln-research`, `Lu1sDV/main`) **only**. The **vendored** copy (`find-ctfs/.agents/skills/vuln-research`, the copy a session actually loads) is **never hand-edited**; it is regenerated by a **re-sync** from canonical. A write to the vendored copy never upstreams; a write to canonical reaches the session only after the re-sync. Procedure and the re-sync step: `references/methodology/invariant-promotion.md`. (Companion guardrail, owned by the harness tier: a `vrdb selftest` preflight warns when the loaded vendored `SKILL.md` version is behind canonical's `min_skill_version`, so a campaign never silently runs guardrails weaker than canonical.)

**Tier gating.** Phase 6 runs in **every tier** — even LOW, which terminates findings at `candidate`, still produces reusable invariants worth promoting. The gate view is consulted at run completion regardless of tier; an empty high-confidence-invariant set passes it trivially (nothing to promote).

**Observation flush.** Phase 6 emits ≥ 1 `agent_observations` row like every executed phase (min an `invariant`/`dead_end`/`blind_spot`): typically an `invariant` recording the promotion decision, or a `blind_spot` when an invariant was skipped for a reason worth carrying forward.

---

## ═══ Autoload Knowledge Layer (C3, cross-phase) ═══

Per `references/v2/autoloading-knowledge-layer.md`:

- **seed** lane (top-K = 10) runs during Phase 0 Decompose to pre-populate `knowledge_chunks` for the detected stack.
- **expand** lane (cap 50, version-pinned) runs **DEEP only**, after Phase 2 Confirm flushes, on the surviving candidate/confirmed set.
- Acceptance is tri-signal (`ref_count`, `repeat_suppressions`, `growth_rate`, `staleness_days`) with bootstrap rule R8 for first-audit single-signal admit; decay sweep runs at end-of-pipeline.

`knowledge_chunks`, `knowledge_seed_log`, `knowledge_acceptance` writes are orchestrator-only.

---

## Handoff contract (applies every phase)

- **No filesystem artifacts written by subagents.** Every subagent output is a DuckDB row event flushed by the orchestrator. Disk output that the orchestrator/harness/engines unavoidably produce (run DB, sidecars, fuzz corpora, C5 build artifacts, engine tmpdirs, per-repo catalogue) consolidates under the gitignored `.vuln-research/` workspace at the audited repo root (SKILL.md § Workspace convention). Inspect via `duckdb <db_path>` queries; the canonical view is `confirmed_vulns`.
- Every `gr_findings` row carries, inside its `payload`, **`evidence_path:evidence_line` + structured `trace_json`** (DAG-shaped per `references/methodology/dag-reasoning.md`).
- Every hunt-agent compressed brief: **its slice tuple + sibling one-line module index + filtered patch-seed `sources` rows** — no raw file dumps, no cross-module blobs.
- Mode: **SAST + targeted sanitizer-backed Fuzzing (Phase 1.5, DEEP) + production-equivalent Proof**; no rule engines, no black-box DAST web scanners.
- **Tooling discipline (every subagent):** Prefer LSP (`goToDefinition`, `findReferences`, `hover`) for symbol resolution, callers, and type info. Use Grep/Glob for discovery (locating files, searching patterns), then read the local context needed for decorators, route registration, middleware, guards, module config, and dynamic dispatch. Grep text matches conflate same-named symbols across scopes and inflate false-positive rates in source→sink traces.
- **Single-writer rule** is non-negotiable: any subagent that opens a DuckDB connection directly is aborted and re-spawned with a queue handle only.

## Final deliverable set

All persisted in the per-target DuckDB (path resolved per spec §B0):

| Table / view | Tiers | Notes |
|---|---|---|
| `targets` | all | NK `(repo_url, commit_sha)` |
| `round_ledger` | all | One row per round; `parent_round_id` chains rounds; carries `priors_fetched_json`/`seed_summary_json`/`coverage_carry_json` |
| `sources`, `sinks`, `defenses` | all | Phase 0 output; patch seeds live in `sources` with `source_kind='patch_seed'` |
| `phase0_priorities`, `intended_feature_classification` | all | Phase 0 ranking + intended-feature filter |
| `critical_functions` | all (top-2 floor LOW) | Ranked registry; `rank_tier` ∈ {tier1,tier2,tier3}; `factor_bypass_prior` carries cross-round |
| `critical_fn_reach` | MEDIUM (tier-1) + DEEP (tier-1/2) | source→critical-fn reachability; `reach_status` ∈ {reaches,blocked,unproven} |
| `input_slices`, `agent_steps` | all | Phase 0.5 schedule; LOW emits a single slice family; `critical_fn_forward` slices for ranked critical fns (MEDIUM+DEEP) |
| `gr_findings` | all | `confirmation_status ∈ {candidate, confirmed, refuted}`; LOW caps at `candidate`; Phase 1.5 (DEEP) adds `finding_kind='fuzz_crash'` rows |
| `refutations` | all | One row per failed C1 gate |
| `agent_observations` | all (`dead_end`/`blind_spot` LOW) | Reasoning capture; `reusable` rows feed the next round's entry fetch |
| `suspicious_points` | all | High-recall screening tier; side-output of Phase 1 Hunt + Phase 1.5 fuzz lanes (**no new mandatory lane**); region anchor + `vuln_class` + emitting `lane`, no stored score/`confirmation_status`/PoC; DB-native dedup via UNIQUE NK + `dedup_cluster_size`; graduates to `gr_findings(candidate)` via `graduated_finding_id` when G1 closes or a crash/PoC lands |
| `suspicious_point_factor` | all | Raw EAV factor rows per SP (free-TEXT `factor_name` keyed into `sp_factor_config`); normalized score never stored — `v_suspicious_points_ranked` computes within-round percentile-rank read-time |
| `sp_factor_config` | all | Knob-driven factor catalog (per-factor `weight`/`direction`/gate); `v_sp_factor_coverage` flags any `weight<>0` factor with no producer this round as `MISSING` |
| `defense_bypasses` | MEDIUM + DEEP | Phase 0.75 pre-break (defense-keyed, finding-agnostic) + Phase 3 finding-specific recheck; exhaustion log proves corpus iteration; `carried_from_bypass_id` feeds the next round; `html_sanitizer_bypass_lane` adds `sink_reached`, `capability`, `injection_context`, `input_vector`, `payload_technique`, `corpus_category` label columns |
| `sanitizer_bypass_runs` | MEDIUM + DEEP | Per-sanitizer aggregate run verdict (`bypassed`/`clean`/`inconclusive`) from `html_sanitizer_bypass_lane`; one row per reachable sanitizer per round; `clean` is a first-class stored robustness result that suppresses re-runs for the same `(defense_id, corpus_version)` |
| `fuzz_runs`, `fuzz_artifacts` | DEEP | Phase 1.5 `boundary_fuzz_lane` per-run config + coverage + mandatory-attempt accounting; resumable seeds/corpora/frontiers/checkpoints; results are `gr_findings` `fuzz_crash` / `fuzz_divergence` rows |
| `audit_outcomes` | MEDIUM + DEEP | Triage verdict (`outcome` enum) + `notes_json`; PoC artifacts live on `gr_findings`/sidecar |
| `critic_findings` | MEDIUM + DEEP | WARNING stored; CRITICAL forces `refuted` at flush |
| `knowledge_chunks`, `knowledge_seed_log`, `knowledge_acceptance` | all (seed) / DEEP (expand) | Autoload C3 |
| `confirmed_vulns` (view) | all | `SELECT … WHERE confirmation_status='confirmed'` — final report source |
| `.vuln-research/sidecars/<finding_hash>.bundle` | MEDIUM + DEEP | PoC payload spillover when > 16 KB |
