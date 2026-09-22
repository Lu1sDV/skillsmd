---
name: vuln-research
version: 0.41.0
description: >
  Use when performing security-focused vulnerability research, bug bounty hunting,
  penetration testing, or exploit development on a specific target codebase or binary.
  Covers taint analysis across 30+ attack domains, sink analysis for 10+ languages,
  SAST/DAST integration, agent sweep, DuckDB-persisted phase pipeline, fuzzing harness,
  stateful fuzzing, directed symbolic execution, history-driven fuzzing, FuzzGPT,
  generate edge-case test programs, differential / metamorphic oracle,
  continuous / perpetual / self-firing
  vuln discovery, keep hunting until N high/critical confirmed, patch diffing,
  supply chain attack surface, find me zero days, sweep everything,
  memory corruption, ROP, firmware audit, kernel driver.
  SKIP for: generic code reading, writing new features, refactoring,
  single-diff review without a security goal, or infra config not being audited
  for vulnerabilities — use code-review or a general coding skill instead.
---

# Vulnerability Research

## v2 Pipeline — Summary

The skill runs a DuckDB-persisted phase pipeline (Phases L-1 → 0 → 0.5 → 0.75 → 1.3 → 1.4 → 1 → 1.5 → 1.6 → 1.7 → 2 → 3 → 4 → 5). Every artifact — sources, sinks, defenses, critical functions, slices, findings, refutations, observations, bypasses, fuzz runs, suspicious points, round ledger — lives in a single DuckDB database keyed by stable hashes; the orchestrator is the **sole writer** (single-writer rule); swarm agents emit row-shaped JSON to an in-memory queue flushed per-lane (not per-phase) so a crash loses at most one in-flight lane. DuckDB is the sole source of truth — subagents MUST NOT write files. Schema: [`db/schema.sql`](db/schema.sql); migrations: [`db/migrations/`](db/migrations/). Run `vrdb selftest` before Phase 0. Load [`references/v2/pipeline-architecture.md`](references/v2/pipeline-architecture.md) for the full v2 pipeline spec, schema gates, row-shape invariants, workspace convention, harness put/fetch contract, environment preflight, bypass doctrine, and per-phase doctrine paragraphs.

### Mandatory DEEP Lane Roster (18 lanes)

| Phase | Lane name (exact `strategies.name`) | Doc |
|---|---|---|
| Phase L-1 Prior-Art Intake | `prior_art_intake_lane` | `references/methodology/prior-art-intake-lane.md` |
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
| Phase 1.4 History-Driven Fuzzing | `fuzzgpt_history_lane` | `references/v2/fuzzgpt-history-lane.md` + `references/methodology/fuzzgpt-history-driven-lane.md` |
| Phase 1.5 Fuzzing | `boundary_fuzz_lane` | |
| Phase 1.6 Methodology Blind-Spot | `methodology_blindspot_lane_a` | `references/v2/methodology-blindspot-sweep.md` |
| Phase 1.6 Methodology Blind-Spot | `methodology_blindspot_lane_b` | `references/v2/methodology-blindspot-sweep.md` |
| Phase 1.7 Overlooked-Lane Self-Audit | `overlooked_lane_audit_lane` | `references/methodology/overlooked-lane-audit-lane.md` |
| Phase 5 Report | `report_critic` | |

Every lane must execute at least one `agent_steps` row OR record a documented skip (`status='skipped'` + non-empty `termination_reason`). A lane with zero steps and no skip is a BLOCKING `gate_status='MISSING'`. Phase 0.5 materializes the roster by inserting one `scheduled` row per lane. DEEP completion requires `vrdb gate --db PATH --tier deep` (exits non-zero on any hard-red signal across the completion gate views — process: `v_phase_status`, `v_coverage`, `v_lane_coverage`, `v_observation_coverage`; plus the outcome-justification gates: `v_promotion_coverage`, `v_justification_coverage`, `v_sp_oracle_coverage`, `v_invariant_promotion_coverage`). All gate queries must be scoped to the active `round_id` — a lane that ran in round 1 does not satisfy the gate for round 2.

**Phase 1.7 — Overlooked-Lane Self-Audit (DEEP).** Runs after Phase 1.6 (Methodology Blind-Spot). A DEEP-only mandatory meta-lane that self-questions for overlooked or erroneously-ignored high-yield lanes via a DB-grounded triple reference (active strategies, prior round_ledger, `methodology_blind_spots`). Always emits at least one `promising_lanes` row. Cap-gated-spawns the top-N overlooked lanes this run; overflow feeds forward to the next round via `v_promising_lanes_ranked`. See `references/methodology/overlooked-lane-audit-lane.md`.

**Phase 1.4 — Seed generation (DEEP).** Three mandatory lanes feed the Phase 1.5 `boundary_fuzz_lane` corpus and coexist: the dual `llm_seed_corpus_lane_a/b` (synthesize seeds from input-format families — `references/v2/seed-corpus-generation-lane.md`) and `fuzzgpt_history_lane` (**history-driven LLM fuzzing**, FuzzGPT / Deng et al., arXiv:2304.02014 — mine the target's own bug history into edge-case `seed_initial` programs; plus a target-agnostic differential-oracle sub-mode whose divergences are quarantined as `differential_divergence`/`unconfirmed` findings kept out of the severity rankings until triage shows a security path). See `references/v2/fuzzgpt-history-lane.md` + `references/methodology/fuzzgpt-history-driven-lane.md` + the preserved paper set `references/fuzzgpt/`; the RT example selector is `engines/fuzzgpt-retrieval/`.

> Load [`references/v2/pipeline-architecture.md`](references/v2/pipeline-architecture.md) for the full v2 pipeline spec, schema, gates, and row-shape invariants.

---

## Philosophy

Find the bug. Prove the bug. Chain the bug. Every claim needs a working exploit or it's noise.

**The Bitter Lesson, applied:** Vulnerability research has historically been 20% computer science and 80% solving giant, domain-specific jigsaw puzzles — learning font internals, memory allocator behavior, protocol edge cases. LLMs are universal jigsaw solvers. They encode documented bug classes and correlations across source code. The structured methodology below channels this capability; the Agent Sweep mode unleashes it. Use both.

**Attention was load-bearing:** Security rested on scarce elite attention, not sound engineering alone. Most code has never been seriously audited. Agent sweep economics change this — you can aim at everything, not just high-status targets.

The phases below are a **recommended workflow, not a rigid sequence** — skip, reorder, or loop as the target demands. **DEEP-tier exception:** that latitude governs ordering/looping and the LOW/MEDIUM tiers — it does NOT license silently dropping a DEEP lane. For a DEEP audit the lane roster is mandatory: each required lane must either run or record a documented skip (see *Mandatory DEEP Lane Roster* below). The sink catalogs are **representative, not exhaustive** — new frameworks ship new dangerous functions daily. If you find a sink not listed here, it's still a sink. The checklists exist to prevent forgetting the obvious, not to replace thinking.

---

## Mode Selection

Choose a mode based on scope and intent before starting work:

| Mode | When to Use | Flow |
|------|-------------|------|
| **Targeted Audit** | Scoped engagement, specific components, compliance-driven | L0 → L1–L7 below (existing workflow) |
| **Agent Sweep** | Full source tree available, maximize coverage, "find me everything" | L0 → S1–S4 → feeds into L6 (Chaining) + L7 (Gate) |
| **Hybrid** | Best of both — sweep for discovery, structured for exploitation | L0 → Agent Sweep for discovery → Crown Jewel Mapping (L2) on findings → L5–L7 |
| **Swarm Pipeline** | Multi-agent SAST with effort tiers; invoked via `/vuln-swarm <path> [--effort=low\|medium\|deep] [--freeform=detached\|grounded]` | See `references/methodology/swarm-pipeline.md` § Effort Tiers. LOW = L0 + freeform + L3-lite; MEDIUM = full module fan-out + 2-check; DEEP = static-first lane + slice-type fan-out + 3-check + cross-slice reconciliation. |
| **Perpetual Loop** | Continuous self-firing discovery — "keep hunting until N high/critical confirmed", unbounded, target-agnostic | divergent generate (Agent Sweep S2 / Phase 1 Hunt in DMN register) → Salience promote (top-K by `promise`) → Executive pursue (Phase 2 Confirm + L5 PoC) → Confirm → Learn (`round_ledger` feed-forward) → self-fire (ScheduleWakeup). See *Perpetual Loop Mode* below. |

### Mode → Tier → v2 Pipeline Binding

Each mode maps to an effort tier and determines whether the v2 DuckDB phase pipeline and DEEP completion gate apply:

| Mode | Effort Tier | v2 DuckDB Pipeline | Phases Run | DEEP Gate + Mandatory Roster |
|------|-------------|-------------------|------------|------------------------------|
| **Targeted Audit** | LOW | No — L-lane workflow only; DuckDB optional for persistence | L0–L7 | No |
| **Agent Sweep** | MEDIUM | Partial — S1–S4 discovery; DuckDB for dedup/feed-forward | S1–S4 + L6–L7 | No |
| **Hybrid** | MEDIUM | Partial — sweep discovery feeds structured L-lane phases | S1–S4 + L2 + L5–L7 | No |
| **Swarm Pipeline (LOW/MEDIUM)** | LOW / MEDIUM | Yes — v2 phases 0–5 with LOW/MEDIUM lane subset | Phase 0–5 (tier-gated phases skipped at LOW) | No (MEDIUM: v_phase_status advisory; LOW: not applied) |
| **Swarm Pipeline (DEEP)** | DEEP | Yes — full v2 phase pipeline, all 18 mandatory lanes | Phase 0–5 including L-1, 0.75, 1.4, 1.5, 1.6, 1.7 | **Yes** — `vrdb gate` must pass before declaring done |
| **Perpetual Loop** | DEEP (per round) | Yes — each round runs the v2 pipeline; `round_ledger` tracks rounds | Phase 0–5 per round (0.75/1.4/1.5/1.6 included per round) | Yes per round — gate applied at each round's completion |

**Default routing:**
- "audit this codebase" / "find vulns" (unscoped) → **Hybrid**
- "check the auth module" / specific component → **Targeted Audit**
- "find me zero days" / "sweep everything" → **Agent Sweep**

**Phase L0 (Latest Commits Security Review)** runs first in every mode whenever the target has git history — a brownfield recency pass before the broader audit. See Phase L0 below.

**Weakness Registry** under v2 is DuckDB-native and DuckDB-only — `gr_findings` rows with `confirmation_status = 'confirmed'` ARE the registry. Cross-audit priors are recovered by querying the per-target DuckDB on `target_id` (or `targets.repo_url`) before Phase L1; `variant-of` / `enables` / `co-occurs-with` edges are derived at read time from `(finding_kind, sink_id, source_id)` overlap rather than persisted as a second store.

---

## Tooling Constraints

**LSP for understanding, Grep/Glob for discovery.**

When tracing where a symbol is defined or finding all references to it, prefer LSP (`goToDefinition`, `findReferences`, `hover`) when available. LSP gives exact results; Grep gives text matches.

Use Grep/Glob for discovery (finding files, searching patterns). Use LSP for understanding (definitions, references, type info), then read the surrounding source needed to understand framework wiring, guards, decorators, module configuration, and dynamic dispatch.

Avoid raw whole-repo dumps; do not avoid local file context that affects exploitability.

**Heavy-native tool launch cap (standing).** Every heavy-native tool launch — CPG builder (Joern), symbolizer, fuzzer, sanitizer/instrumented build — runs under a memory cap (`systemd-run MemoryMax`-style cgroup) with concurrency=1 and a `flock`. This is a standing skill rule, not a per-target lesson: the cap belongs in the tool-launch path so it is enforced rather than re-learned each campaign. The enforcing mechanism is the `vrdb run-tool` wrapper — route every heavy-native launch through it. An uncapped concurrent launch is the modal cause of OOM-kills that corrupt the DuckDB mid-run.

---

## Agent Model Routing

One global routing rule, prepended to every lane prompt header:

- **Analysis / triage / confirm / critic** lanes → the **strongest reasoning model** available. Severity judgment, refutation, DAG closure, consumer-harm reasoning, and the report critic are all analysis.
- **Executor / recon / search** lanes → the **standard tier**. Shell execution, file enumeration, grep/glob discovery, and mechanical retrieval do not need the strongest model.
- **Never the cheapest tier for security judgment** — a model that under-reasons a refutation or a reachability cap silently inflates the finding count.

---

## Standing Lane Contract

Every lane prompt is **prepended with this 5-line contract** — it is boilerplate the agent actually reads, not advice buried in a reference. It replaces 18 per-lane copies with one source:

1. **REFUTE-FIRST** — state the single fact that would kill each finding; a clean refutation is a result, not a failure. Hunt for the kill before defending the claim.
2. **CONSUMER-OR-DEMOTE** — name the default-config component that reads / dispatches / trusts the tainted value and the harm it suffers; if no default-config consumer can be named, the finding auto-demotes to Observation. A sink reached is not a consumer harmed.
3. **SEVERITY IS COMPUTED, NOT TYPED** — emit reachability, let Confirm rate; the bug class is only a ceiling, capped by reachability and build hardening. A server/process-crash claim is verified on the **real deployed surface** with process-liveness (the process the deployment exposes survives or dies), **never a bundled CLI client's exit code**.
4. **MODEL** — run analysis / triage / confirm on the strongest reasoning model (see §Agent Model Routing).
5. **FLUSH** — emit ≥1 observation this phase; route every dropped candidate to a row (dead_end / blind_spot / refuted), never silently delete it.

---

## Agent Sweep Mode (Phases S1–S4)

> **Non-strict by design:** Agent Sweep is the unguarded discovery lane. Agents are file-anchored, not domain-anchored; they consider all bug classes; the catalog is a starting frame, not a fence. The guardrails are downstream — Phase 2 Confirm grounds in skill taxonomy, the five-gate doctrine + DAG closure + critic rubric apply before any finding promotes to `confirmed`. Open at the top, closed at the bottom.

When the goal is maximum coverage across a full source tree, use **file-iteration with independent verification** instead of domain-partitioned analysis (the Carlini methodology adapted for Claude Code). The phases are:

- **S1 Segmentation** — enumerate every source file (excluding vendored/generated), partition by directory, prioritize by Attention Deficit Score (Phase L2), include test files.
- **S2 Discovery Loop** — spawn one parallel agent per file (or cluster) with a file-anchored, *not* domain-anchored prompt. Each agent considers all bug classes, follows imports, prefers LSP for symbol resolution, and emits `gr_findings` / `agent_observations` row events rather than writing files. Stochastic and parallelizable.
- **S3 Verification Loop** — feed each queued candidate payload back through a **fresh, separate-context agent** that re-traces from scratch. Expected filtration ~40–60% surviving. For higher-confidence audits, upgrade to the **2-check variant** (RE-TRACE + JUDGE as two separate agent calls — separation is load-bearing) and optionally the **Structured JUDGE / DAG variant** (forces the closer to construct a closed source→sink DAG; if it can't close, it's a False Positive — no hedging). For high-value or ambiguous targets, optionally borrow the VulnLLM-R function-context strategy: distinguish **target functions** from **context functions**, retrieve callers/callees/call paths via CodeQL/CPG/LSP before judging, require a context-sufficiency check, and narrow final judgment to 2–5 plausible CWE candidates or benign.
- **S4 Dedup, Cluster, Feed Forward** — dedup same-root-cause findings, cluster by bug class and component, feed surviving findings into Phase L6 (Chaining) and Phase L7 (Exploitability Gate). The sweep finds raw bugs; the L lanes score, chain, and prove them.

> **Load `references/methodology/agent-sweep.md`** for: full S1 file-enumeration shell snippet + Attention Deficit scoring weights + batch-size strategy by codebase size; verbatim S2 discovery prompt template and execution strategy notes; full S3 verification prompt + per-bug-class filtration-rate priors + the 2-check and Structured JUDGE/DAG variant prompts; S4 dedup/cluster rules and DuckDB-native feed-forward semantics; binary/decompiled-code adaptation; Targeted-vs-Sweep tradeoff table and Hybrid workflow; tuning, re-sweep cadence, multi-pass strategy.

---

## Perpetual Loop Mode

A self-firing, target-agnostic discovery loop (triple-network model: DMN → Salience →
Executive) layered THIN over the existing engine — zero new tables, maximal reuse. One round:
**divergent generate → Salience promote (top-K by `promise`) → Executive pursue → Confirm →
Learn → self-fire**.

- **DMN / Core (divergent register, the only psychedelic step):** runs the existing **Agent
  Sweep S2 / Phase 1 Hunt** agents in an explicit divergent register — mandatory divergence,
  cross-domain analogy, surfaced hunches, **and free re-litigation of refuted leads** when a
  new angle/analogy/ledger signal justifies another look. *A round emitting only safe,
  already-known candidates has malfunctioned.* Strategy `perpetual_dmn_generate`.
- **Salience (sober):** ranks candidates by `promise = novelty × est_severity ×
  reachability_prior × ledger_history_factor` and promotes top-K — read-time view
  `v_promise_ranked` over existing columns, no stored score (the `v_*_ranked` precedent).
  Strategy `perpetual_salience_promote`.
- **Executive (sober):** **REUSES** the existing **Phase 2 five-gate Confirm** (refute-by-
  default) + **L5 PoC constraints** (vanilla real PoC). No new confirm path.
  Strategy `perpetual_executive_pursue`.
- **Learn:** **IS** `round_ledger` + round feed-forward + `recurrence_counter` — per-class/
  region hit-miss biases the next Core round (down-weight exhausted families, surface
  under-explored regions). No new ledger construct. Strategy `perpetual_ledger_learn`.

The loop **self-fires across turns via `ScheduleWakeup`** and is **unbounded**: it runs until
**N HIGH/CRIT confirmed** (default **N = 20**, overridable) or the user interrupts. No budget
cap, no dry-exit auto-stop — dry rounds are reported as honest progress, not halts; ledger
down-weighting is the only damper. Precision is held downstream by the unchanged Salience +
five-gate Confirm — open at the top, closed at the bottom. Divergence is **Core-only**;
Salience and Executive stay strictly convergent. The four `perpetual_*` strategies are
**non-mandatory** (deliberately absent from `v_required_deep_lanes`, the `cpg_coverage`
precedent), so normal DEEP audits never block on them. Full doctrine + promise factor
estimation: **`references/methodology/perpetual-loop-mode.md`**.

**Promising-lane feed-forward (side-output).** Any DuckDB-backed static-analysis lane (Phase 1 Hunt, Agent Sweep S2, Phase 0.75 code-reading, Phase L3/L4) MAY opportunistically emit a **promising lane** — a positive lead naming a concrete next-round investigation direction (e.g. *"custom template engine → SSTI-fuzz lane @ `render()`"*), distinct from a methodology blind-spot (gap) and a suspicious point (`vuln_class@region`). It is **feed-forward only** and **non-mandatory** (not in `v_required_deep_lanes`, no gate): the orchestrator flushes a `promising_lanes` row event, and the **next round picks open leads up first** via fetch (10) / `v_promising_lanes_ranked`. Doctrine: [`references/v2/pipeline-architecture.md`](references/v2/pipeline-architecture.md) (Promising-Lane Feed-Forward); schema: [`db/migrations/0025-promising-lanes.sql`](db/migrations/0025-promising-lanes.sql).

---

## Domain Reference Map

Routing table: **`references/domain-reference-map.md`**. Load it once on first reference lookup, or `grep` it for a specific trigger keyword (e.g., `grep -i 'ssrf\|xxe' references/domain-reference-map.md`). It covers routing rows across attack-domain references, per-language sink files, binary/RE lifecycle files, the v2 DuckDB schema + migrations + sidecars, the bypass catalogue, the critic rubric, and the C1–C4 doctrine files. **Do not load all reference files at once** — pull only the row(s) that match the active testing domain or v2 phase.

---

## Audit Methodology Lanes (Phase L0–L8)

The phases below are the **audit methodology lanes** — what a researcher walks through. They are orthogonal to the v2 pipeline phases at the top of this document, which describe how the orchestrator + swarm move rows through DuckDB. `L` prefix avoids collision with v2 phase numbers; both layers coexist in one audit.

---

## Phase L-1: Prior-Art Intake

**Bug-bounty-mode mandatory** when a scope target is provided. Mines prior art — NVD/GHSA/OSV/exploit-db CVEs and public web writeups — for the in-scope target, inserting results into the `cves` and `writeups` DuckDB tables. Distils high-yield leads into `promising_lanes` rows (provenance columns `derived_from_cve_id` / `derived_from_writeup_id`), which round 1 picks up first via fetch (10) / `v_promising_lanes_ranked`. **Documented-skip fallback** (same pattern as Phase L0): when no scope is provided or network is unavailable, record `status='skipped'` + `termination_reason` and proceed. See `references/methodology/prior-art-intake-lane.md`.

---

## Phase L0: Latest Commits Security Review

Before the broad audit begins, **spawn one focused subagent** to perform a narrow-scope security review of the repository's most recent commits. Recent diffs are the highest-signal starting surface in a brownfield target: they concentrate attacker-reachable new code, often touch security-adjacent paths (auth, routing, input parsing, config), and receive less scrutiny than older, stable modules. Reviewing them first primes Phase L1 with findings and calibrates the attack surface.

**Single-agent, narrow-scope** — whole-tree coverage belongs in Agent Sweep (Phases S1–S4). A swarm would dilute focus across the small commit surface and produce duplicated, low-signal findings.

> **Load `references/phases/phase-L0-recency.md`** for the verbatim subagent prompt and the optional PATCH SEEDS schema.

### Fallbacks

| Condition | Behavior |
|-----------|----------|
| No `.git` directory / no git history | Skip Phase L0, proceed to Phase L1 |
| Fewer than 3 commits in history | Skip Phase L0, proceed to Phase L1 |
| Recent commits are docs-only or generated files only | Record `NO_CODE_CHANGES` with touched paths, proceed to Phase L1 |
| Subagent fails or times out | Log the failure, proceed to Phase L1 — do not retry inline |

### Feed-Forward

Phase L0 findings plug into the same downstream pipeline as Agent Sweep output:

1. **Dedup** against later Phase L3 (Source Audit) and any Agent Sweep results
2. **Feed** surviving findings into **Phase L6: Vulnerability Chaining**
3. **Gate** each finding through **Phase L7: Exploitability Gate** before reporting

Do not promote a Phase L0 finding to a reported vulnerability without passing Phase L7 — the exploitability gate applies equally to commit-sourced findings.

---

## Phase L1: Recon

Fingerprint the stack, enumerate every input vector, and map every endpoint before touching anything. Recent diffs (Phase L0) tell you *where* the surface is moving; Phase L1 tells you *what* it is — runtime versions and config flags gate which sinks downstream are exploitable. For stateful systems, also collect sample traces (PCAPs, logs, API specs, client workflows), message types, response classes, and candidate protocol-state transitions before fuzzing or taint tracing.

> **Load `references/phases/recon-checklist.md`** for the full stack-enumeration list, the **Runtime Version Gates**, the Input Vector Map, and the Endpoint Map.

**Always qualify findings with the relevant version gate.** A PHP < 8.0 `preg_replace /e` finding is real; the same sink on PHP 8.1 is dead code.

---

## Phase L2: Crown Jewel Mapping

Before testing, identify maximum-damage targets:

1. **Data assets**: PII stores, payment processing, admin credentials, API keys
2. **Privilege boundaries**: admin panels, role escalation paths, multi-tenant isolation
3. **Trust transitions**: internal services, SSO providers, cloud metadata endpoints
4. **Business logic**: financial operations, state machines, approval workflows

Attack the highest-value targets first.

### Attention Deficit Mapping

After identifying crown jewels, identify the **least-examined** code — where bugs survive because nobody looked, not because the code is sound:

| Signal | High Attention (lower bug probability) | Low Attention (higher bug probability) |
|--------|---------------------------------------|---------------------------------------|
| **Security commits** | Has `fix: security`, CVE references, audit comments | No security-related commits in history |
| **Fuzzing/testing** | Fuzz targets exist, high test coverage | No fuzz corpus, low/no test coverage |
| **Code glamour** | Auth module, crypto, payment processing | Parser, format handler, protocol adapter, config loader, migration script |
| **External exposure** | Behind auth wall, internal-only | Processes attacker-controlled input (uploads, webhooks, public API) |
| **Code age** | Recently written/reviewed | Legacy code, "don't touch" modules, vendored-then-forgotten |

**Prioritize: high exposure + low attention.** These are the targets that have never seen a fuzzer. The crown jewels approach finds the highest-*impact* targets; attention deficit mapping finds the highest-*probability* targets. Use both.

**Exhaustive defense enumeration (finding-agnostic mandate).** Before the hunt, enumerate **ALL** defenses across every layer (input validation, authn/authz guards, output encoders, sandboxes, allocators/hardening, rate limits, parsers' own checks) **finding-agnostically** — not anchored to the findings you expect to write. The inventory is built from the surface, not from a hypothesis. A small `defenses` count relative to surface size is an explicit **red flag** the completion gate cannot detect on its own: under-enumeration produces a clean-looking but hollow defense map, and every later "defense gap" claim rests on it.

Quick heuristics — run these against candidate modules when you need a fast Attention Deficit Score before deciding agent fan-out; skip when the target is small enough to audit exhaustively or when you already know the hot paths:

- `git log --format='%s' -- <path> | grep -ic 'secur\|vuln\|cve\|xss\|sqli\|inject'` — zero hits = never audited
- Check for adjacent `*_test.*`, `*_spec.*`, `fuzz_*` files — absence = untested
- `git log --diff-filter=M --since="2 years ago" -- <path>` — no recent changes = stale, possibly forgotten

---

## Phase 1.3: Reachability & Consumer Mapping

Before the Hunt, build two whole-tree inventories so every later lane reasons against a prior instead of re-deriving reachability per finding:

1. **`reachable_surface`** — per source, the critical functions / sinks **provably reachable under default config**, each tiered `proven` / `conditional` / `unreachable`.
2. **`consumer_graph`** — per sink, the downstream consumers that read / trust / dispatch its output (the basis for the CONSUMER-OR-DEMOTE contract).

The Hunt receives this as a prior: a candidate whose sink is `unreachable` needs an explicit reopen rationale, not a silent promotion. Confirm Gate 1 (taint reach) reads this inventory rather than re-deriving it per finding. On a large target this is itself a heavy lane — cap and schedule it like any other.

> **Load `references/phases/reachability-consumer-mapping.md`** for the inventory schema, the proven/conditional/unreachable tiering rules, and the consumer-graph construction recipe.

---

## Phase L3: Source Audit

> **Non-strict:** The categories below are routing hints, not a closed taxonomy. New attack classes appear faster than this table updates. If you find a vulnerability that doesn't fit any row, it's still a vulnerability — record it freeform and let Phase L7 do the gating.

Run parallel agents, each focused on one attack domain. Every agent traces **source to sink** — user input reaching a dangerous function.

See `references/domain-reference-map.md` for the per-domain reference routing table.

Every module agent MUST conclude its report with a **Blind Spots** block: files it did not read, components absent from the repo but referenced elsewhere (other-repo Rust halves, dynamically-fetched configs, production-only artifacts), runtime states it could not observe (OIDC discovery docs, feature-flag evaluation), and dependencies whose behavior gates its findings' severity. Blind spots are first-class output, not footnotes. Phase L6 chain synthesis consumes this list to flag findings whose severity depends on external evidence.

When this Source Audit (or Phase L4 Taint Analysis) runs **DuckDB-backed** and an agent spots a **promising lane** — a concrete new investigation direction worth a dedicated lane next round (e.g. a custom template engine → SSTI-fuzz, a hand-rolled ORM → SQLi) — it emits a `promising_lanes` row event (feed-forward only, non-mandatory; the next round picks it up via `v_promising_lanes_ranked`). A promising lane is the positive twin of a blind spot: a lead, not a gap. See `references/v2/pipeline-architecture.md` (Promising-Lane Feed-Forward).

---

## Phase L3.5: Technology Stack Discovery (Sink Loading)

> **Non-strict:** Sink catalogs are representative, not exhaustive. The per-language files exist to prevent forgetting the obvious; they do not bound discovery. A "sink" is any function that does something dangerous with attacker-controlled data — listed or not.

Before taint analysis, identify **every language and framework in the stack** — most targets are polyglot:

1. **Enumerate languages**: scan file extensions, shebangs, `package.json`/`composer.json`/`pom.xml`/`go.mod`/`Cargo.toml`/`mix.exs`/`Gemfile`/`requirements.txt`
2. **Identify the stack layers**: e.g., PHP backend + Node.js build tooling + Python microservice + Java auth service
3. **Load matching sink files**: for each language present, load the corresponding `references/sinks/<lang>.md` — load multiple if the target is polyglot
4. **Load the SAST/DAST router**: `references/sinks-catalog.md` for cross-language Semgrep/CodeQL/SonarQube rules
5. **Ruby/Rails targets**: load `references/sinks/ruby.md` (security-sensitive API corpus) and, when authoring or extending detections, the validated **Ruby Rule MegaDB** at `rules/ruby/` (`semgrep/<category>/ruby-<slug>.yaml` + CodeQL `.ql`, each with a co-located test; manifest + taxonomy + validation tooling in the same tree). Authoring feed and commit-mining pipeline: `references/security-fix-oracle.md`

**Example**: a Laravel app with React SSR and a Python ML microservice → load `sinks/php.md` + `sinks/javascript.md` + `sinks/python.md`

Do not skip minor languages in the stack — the weakest link is often the least-reviewed service.

**PHP targets — custom Semgrep pack.** When PHP is in the stack, layer `semgrep-rules/php/php-sinks.yaml` (439 rules) on top of the curated public combo (`p/ci` + `p/phpcs-security-audit` + `r/php.lang.security`, plus Federico Dotta's PHP/Yii pack and `p/trailofbits` for deeper audits). The pack mirrors the full `references/sinks/php.md` taxonomy (RCE, LFI/RFI + stream wrappers, unserialize/Phar, SQLi, XSS, SSRF, XXE, traversal, type juggling, CVE-2024-2961 iconv, variable overwrite, `mail()` abuse, and more); every rule carries a `vuln-research-domain` tag so swarm output routes to the right verifier.

**C/C++ targets — custom Semgrep pack.** Layer `semgrep-rules/c-cpp/c-cpp-sinks.yaml` (555 rules) over `p/c` + `r/c.lang.security`; it mirrors `references/sinks/c-cpp.md` (buffer-write, object lifecycle, integer/type, syscall/`errno`, concurrency/TOCTOU, ambient-state, C++ semantics, Windows-userspace).

Canonical command set for both packs + the mirror rule (pack ↔ sink doc edited together): `semgrep-rules/README.md`. Expect ~86% precision (Fraunhofer 2024) — feed hits through Phase L4.5 SAST triage before promoting anything.

**Authoring custom detections** — when a project wrapper hides a sink from the curated packs (any language), author a precise rule **test-first** rather than grepping: `references/methodology/semgrep-rule-authoring.md` (taint-over-pattern, AST dump, 100%-pass TDD loop). The CodeQL analogue is **data-extension models** for custom source/sink wrappers — without them CodeQL false-cleans at the wrapper — see `references/methodology/tool-ingest-recipes.md` § 1.1. In both cases the rule/model is tool *config*; its hits enter as `candidate` rows through the ingest contract and earn promotion only via the five-gate Confirm.

**Binary / native artifacts in the stack** — when the target ships compiled binaries, firmware, kernels, drivers, packed/obfuscated samples, or source depending on ABI/memory-ordering semantics, load **`references/binary/binary-stack-triggers.md`** for the 13-row trigger map onto the `references/binary/binary-{triage-and-re,bug-classes,exploit-and-specialties}.md` files. Binary findings feed Phase L6 Chaining and pass the Phase L7 gate via the same DAG form as source findings.

**C/C++ *source* in the stack** — load **`references/sinks/c-cpp.md`** for the source-level memory-safety bug-class catalog (buffer-write sinks, object lifecycle, integer/type, syscall/`errno`/`EINTR`, concurrency/TOCTOU, ambient-state, C++ semantics, and the **Windows-userspace** classes `systems.md` omits) plus the threat-model gate. This is distinct from the binary track above: source-level review here, compiled-artifact RE there. Dynamic confirmation of a memory-safety class is the Phase 1.5 `boundary_fuzz_lane` (`references/v2/fuzzing-lane.md` + the harness how-to `references/methodology/fuzz-harness-craft.md`); the crash lands as a `gr_findings(finding_kind='fuzz_crash')` row, never a file.

**C3 — Mandatory regex inventory.** Every regex in the in-scope tree MUST be mapped into the `regexes` table (the 5th `preliminary_enumeration_lane` category — inventory only; bypass analysis and fuzzing happen in later lanes). This is enforced by the `v_coverage.regexes_unmapped` HARD-RED gate: any unmapped regex blocks DEEP completion. See `references/v2/bypass-catalogue.md` (regex bypass classes) and `references/methodology/preliminary-enumeration-lane.md` (enumeration contract).

### Tool-Integration Matrix (CPG / SAST / AST tooling)

For DEEP-tier Swarm Pipeline runs and any audit where a mechanical pre-pass is available, the priority order is: Joern (Code Property Graph — full inter-procedural taint, PDG cuts, call-chain slicing) → CodeQL (relational AST + dataflow, SARIF output, optional call-path/context retrieval) → Semgrep + ast-grep (semantic patterns + structural AST matching) → fallback plain-text grep against `sinks/<lang>.md`. Outputs from the first three layers are packaged as SecuritySlice input packets for LLM consumption; agents treat tool hits as hypotheses to verify, not findings to rubber-stamp. When the optional function-context strategy is selected, function selectors pick target functions, CPG/CodeQL/LSP retrieves callers/callees/call paths and security helpers, and the agent must say `context_insufficient` instead of guessing.

> **Load `references/phases/tool-integration-matrix.md`** for the full priority table with per-tool "when to use" guidance, the CPG-over-AST rationale, and the 11 slice cuts the tooling can emit (from `references/methodology/swarm-pipeline.md` § Slice Types).
>
> **Load `references/methodology/tool-ingest-recipes.md`** to turn a tool's *native output* into DuckDB rows — the exact CodeQL / Semgrep / ast-grep run commands, the SARIF/JSON → `gr_findings` / `sinks` / `input_slices` candidate mapping, cross-tool dedup by `finding_hash`, and the coverage-computed-from-tool-output contract. Every tool hit enters as a `candidate` hypothesis and earns promotion only through the five-gate Confirm.

---

## Phase L4: Taint Analysis

Three strategies (source-forward for small codebases, sink-backward for large ones, hybrid for medium, circulatory tracing as a complement to any). Controllability is classified High / Medium / Low / Needs-verification. Output filter internals must be traced to confirm the escaping context matches the output context — a filter named `is_safe` does not mean the output is safe. For high-stakes findings, restate the trace as a closed DAG (ground-truth source nodes → intermediate inference nodes → verified_sink); if the graph does not close, the finding drops to Observations. Load `references/sinks-catalog.md` for the language router and SAST/DAST integration rules.

> **Load `references/phases/taint-analysis.md`** for: the full strategy table with method detail, the four-tier controllability classification, output-filter internals (Django `|safe`, Twig `|raw`, Rails `html_safe`, React `dangerouslySetInnerHTML`, Jinja2 `|safe`), circulatory tracing domain-crossing examples, and the DAG-structured trace framework with 12 failure patterns. Also load `references/methodology/dag-reasoning.md` for worked DAG examples.

---

## Phase L4.5: Static Analysis False Positive Calibration

SAST tools generate noise. Before triaging any tool output, load **`references/phases/sast-triage.md`** for: per-severity FP-rate priors (treat as field estimates, not measurements — replace with your own per-rule rate after ≥10 samples), the common-FP-pattern checklist (dead-code sinks, framework-sanitized paths, test fixtures, vendor code, constant inputs), and the 5-step calibration workflow that ends in disabling rules above 90% FP in your stack.

---

## Phase L5: Exploitation

**Severity is computed, not typed.** The class tier below is only the **input** `base(class)` — a ceiling, never the verdict. The recorded severity is the composite:

```
final = base(class) × reachability_cap × mechanism_cap × poc_evidence_gate
```

- **`base(class)`** — the class ceiling from the priority table below (an input, not a verdict).
- **`reachability_cap`** — unauth-remote ×1.0 / authed-low caps one band down / admin caps two bands / harness-only → Observation.
- **`mechanism_cap`** — a **hardened-allocator / bounds-checked-container / sanitizer-abort build caps memory-unsafety at DoS**; only a raw-pointer / `memcpy` / forward-linear write retains leak / write-what-where; only a *proven* write-what-where, or a read primitive plus an ASLR defeat, lifts toward RCE. (Example: an `operator[]` OOB in a build with a hardened libc++ aborts → DoS, while the same offset reached through raw-pointer arithmetic can leak.)
- **`poc_evidence_gate`** — vanilla end-to-end PoC ×1.0 / no PoC → cap at LOW / theoretical.

> **Load `references/phases/exploitability-gate.md` §rubric** for the full factor definitions, the per-band cap arithmetic, and the evidence each factor requires before it may exceed its default cap.

**Priority tiers** — `base(class)` ceilings; also the work order (don't burn effort on Medium ceilings while Critical ceilings are open):

| Tier | base(class) ceiling | Examples |
|------|----------|----------|
| **P0** | Critical | RCE (webshell, deser, SSTI, command injection, eval, JNDI) |
| **P1** | High | SQLi, SSRF, auth bypass, arbitrary file read, IDOR w/ sensitive data, XXE |
| **P2** | Medium | Stored XSS, CSRF on critical actions, race conditions, mass assignment, proto pollution, smuggling |
| **P3** | Low | Reflected XSS, info disclosure, missing headers, CORS misconfig, open redirect |

For each finding: identify source → trace transforms → confirm sink reach → craft payload → prove impact.

### PoC Constraints (Mandatory)

The PoC must be a realistic, end-to-end victim↔attacker interaction against the unmodified target in a production-equivalent environment. Zero mocking — no stub servers, no patched binaries, no debug flags, no modified `docker-compose.yml` target services. Every confirmed finding ships two forms: a step-by-step walkthrough (reviewer understands the bug without running anything) and a full bundled `docker compose up && ./poc.sh` directory (third party clones, runs, sees exploit work). Missing either form → finding stays Candidate.

> **Load `references/phases/poc-constraints.md`** for: the full ZERO MOCKING rule text, docker-compose and no-container environment setup, the two-form table with audience and description, and the responsible disclosure principle.

---

## Phase L6: Vulnerability Chaining

Single bugs are starting points. Real impact comes from chains.

See `references/phases/chaining-advanced-techniques.md` for the full chain-pattern catalog.

**Impact amplifiers**: Re-score severity in chain context. A Low open redirect becomes High when it enables OAuth token theft → account takeover.

---

## Phase L7: Exploitability Gate

Four questions gate every finding before reporting: can you control the input? Does it reach the sink through all transforms and sanitizers? Can you prove impact with a working payload? Where is the defense layer — and is it actually active, not just assumed? If any of Q1–Q3 is No, the finding moves to Observations. Questions 1–3 map onto a closed DAG; if the DAG does not close, Q2 is No. When a defense layer blocks exploitation, treat it as a new attack surface and apply the methodology recursively.

> **Load `references/phases/exploitability-gate.md`** for: the full four-question text, the "If any answer to Q1–Q3 is No" rule, the mechanical DAG gate (Q1/Q2/Q3 node types), and the defense-layer recursion pointer to `references/phases/defense-layer-iteration.md`.

---

## Phase L8: Registry Promotion (DuckDB-Native)

Under v2 there is no separate persistence step — `gr_findings.confirmation_status = 'confirmed'` IS the registry. Dedup is enforced by the `finding_hash` UNIQUE constraint over `(target_id, finding_kind, sink_id, source_id)`-derived hash; re-runs over the same `commit_sha` update rather than duplicate. Edge types (`variant-of`, `co-occurs-with`, `enables`) are derived at read time from `gr_findings` overlap queries, not persisted as a separate table. Cross-audit priors come from querying `gr_findings WHERE target_id = ? AND confirmation_status = 'confirmed'` — no `.vuln-registry/` directory is read or written. Promotion to `confirmed` is governed by the five-gate doctrine in `references/v2/confirmation-rigor-doctrine.md`.

---

## Proof Collection (Summary)

**Realism Gate:** a third party must be able to clone the repo, run `docker compose up`, and observe the exploit firing against the **unmodified app**. If this is not possible, the finding is **Candidate**, not Confirmed.

Every confirmed finding requires:
- Working payload (copy-pasteable, not screenshots) + server response proving impact
- Step-by-step numbered reproduction a reviewer can follow without running code first
- Both PoC forms: step-by-step explanatory + full bundled runnable script
- Video is **supplementary only** — a submission based solely on a video attachment is auto-rejected

Low-confidence findings (score <= 3) → **Observations** section. Intended features → also Observations.

> **Load `references/phases/audit-poc-report.md`** for: full proof checklist (confidence score, exploitability likelihood, auth level, intent gate), Submission N/A Criteria, Always-Rejected Findings, Docker lab setup, and Playwright templates.
>
> **Load `references/phases/bug-bounty-triage.md`** for the pre-submission triage funnel (real / proven-unmodified / in-scope / not-N/A / not-duplicate / severity-honest), the canonical bug-bounty submission template, the duplicate/known-issue check, and the gold-standard worked example.

---

## Blind Spots Checklist (Top 8)

Before declaring "done", verify you tested:

- [ ] Unauthenticated access (not just admin)
- [ ] POST body, JSON body, headers, cookies, path segments (not just GET params)
- [ ] Second-order injection (stored safely, used unsafely later)
- [ ] Rate limiting (brute force login, OTP, password reset)
- [ ] Content-type switching (JSON → XML for XXE, form-encoded for CSRF)
- [ ] Race conditions on ALL state-changing operations
- [ ] Stateful traces (message reorder/drop/repeat/splice, authenticated↔unauthenticated transitions, deep protocol states)
- [ ] Deep uncovered functions (reachable call-graph frontier nodes where fuzzing/static passes never reached)

Full blind spots list (RSS/Atom CDATA, archive extraction, runtime version gates, template filter internals, and 15+ more) in `references/phases/chaining-advanced-techniques.md`.

---

## On-Demand: Audit / PoC / Report

> **Trigger**: Load `references/phases/audit-poc-report.md` when the user requests:
> - Formal security audit (OWASP/STRIDE/PASTA framework)
> - Proof-of-concept development methodology
> - Multi-finding audit / pentest report generation
> - Red team simulation with attacker personas
> - CVSS scoring and risk assessment
>
> **Trigger**: Load `references/phases/bug-bounty-triage.md` when preparing a **bug-bounty / coordinated-disclosure submission** — deciding whether a confirmed finding will survive a program triager and assembling it in the canonical single-finding submission format.

This section is not auto-loaded to save tokens during standard research.

---

> **Remember:** The best researchers don't follow checklists —
> they understand systems deeply enough to invent new attack classes. This document
> gives you the vocabulary. The creativity is yours. Question every assumption.
> Test every boundary. The flag is always one weird trick away.
