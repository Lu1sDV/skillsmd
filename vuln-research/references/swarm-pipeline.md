# Swarm Pipeline Methodology Reference

> **On-demand** — load when running the `/vuln-swarm` command or any hypothesis-driven multi-agent audit that needs module-level decomposition, orthogonal strategies, 2-check verification, analog cascade, weighted scoring, or a continuous-learning feedback pass.

---

## Overview

The Swarm Pipeline is a deeper, more structured counterpart to Agent Sweep mode. Where Agent Sweep iterates file-by-file with discovery → verification → dedup, the Swarm Pipeline:

- **Seeds hypotheses from recent patches** (PATCH SEEDS from Phase 0) rather than starting blind
- **Decomposes the target into modules** before fan-out, so parallel agents attack structural partitions rather than arbitrary files
- **Diversifies strategy across the agent pool** — orthogonal approaches prevent N copies of the same blind spot
- **Runs a three-stage pass inside each agent** — briefing, class-enrichment, skeptical arbiter — so each candidate survives internal adversarial review before emission
- **Verifies every finding with two distinct checks** (re-trace + semantic judge) executed as separate agent calls
- **Cascades analogs** in synthesis — every confirmed finding triggers a search for structurally similar bugs across sibling modules
- **Scores findings with weighted signals** rather than a single verification verdict
- **Closes the loop with a continuous-learning phase** — the pipeline proposes evidence-grounded additions to the skill itself

Use this reference alongside `agent-sweep.md`. Agent Sweep is the "spray everything" mode; the Swarm Pipeline is the "structured deep audit with continuous learning" mode. They share Phases 6/7 (Chaining + Exploitability Gate) as downstream filters.

**Orchestration lives in `commands/vuln-swarm.md`; taxonomy (sinks, bug classes, gates, always-rejected list) lives in `SKILL.md` and the domain-reference tree. This file owns methodology.**

---

## § Effort Tiers

The pipeline runs at one of three effort levels, selected via `/vuln-swarm --effort=low|medium|deep` (default: `medium`). Tiers differ on **which phases run** and **how deeply each runs**, not on the taxonomy applied — the skill's sinks, gates, and always-rejected list govern every tier.

| Phase | LOW | MEDIUM | DEEP |
|-------|-----|--------|------|
| P0 recency + seeds | ✅ | ✅ | ✅ |
| P1 holistic map + module decomposition | ❌ skipped | ✅ | ✅ |
| P2a module agents (Stage 0 context + 3-stage pass, ≥ 2 orthogonal strategies) | ❌ skipped | ✅ | ✅ expanded (every applicable slice-type × promoted modules) |
| P2b sink-hunter | ❌ skipped | ✅ | ✅ seeded by Static-First Lane (Semgrep/CodeQL/Joern) |
| P2.5 verification | Single re-check only | 2-check (re-trace + judge) | 3-check (re-trace + judge + DAG-independent) |
| P3 synthesis | Trimmed — dedup + skill §P6 chain + skill §P7 gate only (no analog cascade, no weighted scoring) | Full — dedup + analog cascade + weighted scoring + chain + gate + split | Full + Cross-Slice Reconciliation |
| P4 skill-improvement | ❌ skipped | ✅ | ✅ |

**LOW design intent.** Fast-path audit for time-boxed scans, small repos, or "smell tests". Runs P0 (recency + seeds) followed by 1–2 freeform detached agents over the whole tree, then a single re-check per finding, then a trimmed Phase 3 (dedup → chain → gate → always-rejected filter). No module decomposition, no orthogonal-strategy discipline, no analog cascade, no continuous-learning. Still applies skill §Phase 7 gate: findings that pass Q1–3 in prose go to `candidates.md`; findings that *also* pass a DAG-mechanical gate (`references/dag-reasoning.md`) go to `confirmed.md`. LOW's confirmed-tier bar is deliberately raised because the rest of the pipeline is lighter.

**MEDIUM design intent.** The current pipeline, unchanged. Default tier. Every module gets ≥ 2 slice-types per applicability matrix, 3-stage pass inside each agent, 2-check verification, full synthesis with analog cascade and weighted scoring.

**DEEP design intent.** Exhaustive audit for flagship targets. Runs MEDIUM plus four additions: (1) Static-First Lane seeding Phase 2b; (2) every promoted module fans out to one agent per applicable slice-type rather than ≥ 2; (3) 3-check verification adds a DAG-independent replication agent; (4) Cross-Slice Reconciliation pairs findings by `file:line` across slice-types to catch PDG-level guard errors.

**DEEP module promotion rule.** To bound cost, DEEP applies its full matrix only to **promoted modules**; non-promoted modules degrade to MEDIUM behavior per-module. Compute `promotion_score` for each module from `1-map.json`:

- Crown-jewel hit (PII / auth / payment / admin / trust-transition surface per skill §Phase 2) → **+2**
- Attention-deficit signal (no security commits + no fuzz + low test coverage + public-facing per skill §Phase 2 Attention Deficit Mapping) → **+2**
- PATCH SEED match filters to this module → **+1**

Modules with `promotion_score ≥ 2` are promoted. **Floor rule:** if fewer than 2 modules promote (e.g. a pure CLI tool with no crown jewels), the top-2 modules by raw attention-deficit score are promoted anyway — DEEP never degrades uniformly to MEDIUM. Record `promotion_score` and promotion decision in `1-decomposition.json` alongside each module entry.

---

## § Module Decomposition

Phase 1 ends by emitting a **module-level decomposition** of the target — a structured partition of the codebase into 8–15 modules that drives Phase 2a fan-out. Fewer than 8 modules under-parallelizes; more than 15 fragments context and dilutes per-agent signal.

### Module entry shape

Each module in `1-decomposition.json` has:

```json
{
  "name": "string (kebab-case, unique across the decomposition)",
  "paths": ["glob/**", "path/to/dir/", "path/to/file.ext"],
  "summary": "2–4 sentences describing what the module does, its trust boundary, and its entry points",
  "suspected_risks": [
    "bug_class or attack pattern the module is structurally prone to",
    "..."
  ]
}
```

### How to draw module boundaries

Prefer boundaries that align with **trust transitions and data-flow seams**, not filesystem layout:

| Good boundary | Why |
|---------------|-----|
| HTTP edge (routers, request parsers, response serializers) | Every external taint source enters here |
| Auth/session surface (login, token issuance, access control middleware) | Privilege decisions concentrate |
| Persistence (ORM, raw SQL layer, cache, file storage) | Most injection sinks live here |
| Template / rendering layer | XSS, SSTI, output-context bugs |
| External integrations (HTTP clients, webhook senders, third-party SDK wrappers) | SSRF, deserialization, supply-chain surface |
| Background jobs / workers | Authorization often different from HTTP; second-order injection |
| CLI / admin tooling | Often less-audited privileged paths |
| Configuration + bootstrap | Insecure defaults, exposed secrets, debug flags |
| Test / fixtures | Reveal invariants production doesn't enforce (include only when suspected risks exist) |

### Sizing heuristic

- **Small repo (<20k LOC):** 8–10 modules, directory-granular
- **Medium repo (20k–200k LOC):** 10–13 modules, feature/domain granular
- **Large repo (>200k LOC):** 13–15 modules, with the understanding that some "modules" may themselves be further decomposed inside Phase 2a if an agent's context budget demands it

### suspected_risks field

Not a wish list — a **prior**, grounded in what Phase 1 actually observed. Each entry should be traceable to an observation: a suspicious import, a stack component matching a known-bad pattern, a commit touching security-adjacent code, a gap in tests, a PATCH SEED hit. Empty `suspected_risks` is legitimate if Phase 1 found no specific priors; free-form strategy in Phase 2a will cover those modules.

---

## § Orthogonal Strategies

Across the pool of N module agents spawned in Phase 2a, **at least 2 distinct analysis strategies must be represented**. This is a hard requirement, not a suggestion: a pool of N clones of the same prompt converges on the same blind spots N times, wasting parallelism.

### Strategy catalog

| Strategy | Starting point | Best for |
|----------|---------------|----------|
| **source-forward** | Request entry points, user-input parsers, external-data readers | Taint discovery in modules with clear edges |
| **sink-backward** | Dangerous functions (loaded from per-language `sinks/*.md`) | Large modules where sources are diffuse; finds sinks first, then reaches for controllability |
| **seed-hypothesis-driven** | A filtered PATCH SEED from `0-seeds.json` — "this exact bug was fixed here; is an unfixed variant present in this module?" | Modules with hits in the seed filter; highest-precision strategy |
| **free-form** | No starting anchor — agent reads the module holistically and follows its own nose | Modules where priors are weak; captures novel patterns the other strategies would miss |
| **trust-boundary** | Known trust transitions (user → admin, unauth → auth, tenant A → tenant B) | Auth, multi-tenant, and privilege-separation modules |
| **state-machine** | State transitions, workflow steps, approval chains | Business-logic-heavy modules where the bug is "what if this state transition fires twice?" |

### Allocation rules

1. **Minimum diversity:** ≥ 2 distinct strategies across the pool, measured by strategy label, not by prompt wording variation.
2. **Seed coverage:** every PATCH SEED that filters to any module MUST be consumed by at least one seed-hypothesis-driven agent. Unconsumed seeds are a gap.
3. **Strategy-module fit:** match strategy to module character (use the "Best for" column). Do not assign source-forward to a module with no obvious sources.
4. **Free-form reserve:** always include at least one free-form agent across the pool, even if every module has strong priors. It catches the bug class nobody predicted.
5. **Duplicate ok when motivated:** two agents on the same module with *different* strategies is valid and often valuable (source-forward + sink-backward meet in the middle). Two agents on the same module with the *same* strategy is waste.

### Anti-patterns

- N agents all running "source-forward" because it's the default — this is the failure mode the requirement exists to prevent.
- "Strategy" implemented as a one-word injection into an otherwise identical prompt — strategies must actually change where the agent starts and what it prioritizes, not just relabel the output.
- Assigning seed-hypothesis-driven to modules with no matching seed — collapses to free-form under the hood; be explicit about the downgrade.

---

## § Slice Types

**Strategy vs. slice type — two different axes.** Strategy = where the agent starts (source, sink, seed, free-form, trust-boundary, state-machine). Slice type = what graph cut the agent reasons over. A single strategy can reason over multiple slice types; a single slice type can be entered from multiple strategies. MEDIUM requires ≥ 2 orthogonal **strategies** across the agent pool AND ≥ 2 applicable **slice types** per module. DEEP applies every applicable slice type to every promoted module.

### Catalog

| Slice type | Definition | CWE family | Preferred construction |
|------------|-----------|------------|------------------------|
| `taint-slice` | Source → ... → sink, value-preserving and taint-propagating. | Injection, XSS, SSRF, SSTI, path traversal, CRLF | CodeQL `DataFlow::Configuration` / Joern `reachableByFlows` / grep + manual DAG |
| `sink-backward-slice` | Start at a dangerous sink, walk def-use backward to find controllable inputs. | RCE, deserialization, crypto misuse, memory corruption | Joern `cpg.call.name(<SINK>).argument.reachableBy(<source>)` / grep sink → walk callers |
| `source-forward-slice` | Start at an untrusted input, walk forward without targeting a specific sink (discovery, not verification). | Attack-surface mapping, unknown-unknowns | Joern forward walk / manual |
| `control-dependence-slice` | Dominators / post-dominators / guard ancestry for a given node. | Authz bypass, missing guards, feature-flag gating | Joern `controlledBy` / manual if/while/try ancestor trace |
| `pdg-slice` | Data dependencies + control dependencies combined. | Memory safety, TOCTOU, business-logic, auth bypass where guard variable ≠ checked variable | Joern PDG / CodeQL DataFlow + ControlFlow composition / manual |
| `changed-code-impact-slice` | Code reachable from or reaching a recent commit hunk; targets of PATCH SEEDS. | Recency audits, variant hunting | `git log -p` + call-graph walk / Joern with diff overlay |
| `auth-check-slice` | Entrypoint → sensitive operation, extract authn/authz checks on every path. | BOLA, IDOR, privilege escalation, tenant breach | Manual route walk + guard grep / custom Joern query |
| `bounds-check-slice` | Size/index value flow plus check-variable *identity* (is the checked variable the one actually used?). | CWE-787 OOB Write, CWE-125 OOB Read, integer mishandling | Joern with constraint primitive / manual `len`-vs-`sizeof(dest)` audit |
| `allocator-free-slice` | `malloc`/`free` (or equivalent) pairs per pointer, ownership and lifetime. | CWE-416 UAF, CWE-415 double-free, memory leaks | Joern ownership query / Clang static analyzer / manual |
| `lock-unlock-slice` | Lock acquisition/release pairs plus shared-state accesses. | Race conditions, TOCTOU, concurrent privilege escalation | Joern call-graph with lock APIs / manual thread audit |
| `crypto-use-slice` | Key source → algorithm/mode → nonce/IV → MAC/signature verification. | Nonce reuse, weak RNG, missing verify, ECB, hardcoded keys | Crypto API grep + manual audit |

### Applicability matrix

Not every slice type fires on every module. Phase 2a agent allocation consults this matrix before spawning:

| Module character | Slice types that apply |
|------------------|------------------------|
| Every module | `taint-slice`, `source-forward-slice`, `control-dependence-slice` |
| HTTP edge / routing | + `auth-check-slice` |
| Auth / session / access control | + `auth-check-slice`, + `control-dependence-slice` (deeper) |
| Persistence / ORM / template | + `sink-backward-slice`, + `taint-slice` (deeper) |
| C / C++ / Rust `unsafe` / Go `cgo` | + `bounds-check-slice`, + `allocator-free-slice`, + `lock-unlock-slice` |
| Crypto / signing / key management | + `crypto-use-slice` |
| Any module touched by recent commits | + `changed-code-impact-slice` |
| Business logic / state machines / workflows | + `pdg-slice` |

### Tier interaction

| Tier | Slice-type allocation per module |
|------|-----------------------------------|
| **LOW** | N/A — no P2a agents; freeform agents operate slice-free over whole tree |
| **MEDIUM** | ≥ 2 applicable slice types per module (chosen for strategy-fit and module character) |
| **DEEP** (promoted modules) | Every applicable slice type per the matrix above; one agent per (module × slice-type) cell |
| **DEEP** (non-promoted) | Same as MEDIUM (≥ 2 applicable) |

### Slice-type tagging on findings

Every finding JSON MUST carry a `discoverer_slice_type` field (value = one of the catalog entries, or `freeform` when discovered by a detached freeform agent with no slice-type anchor). This field feeds Cross-Slice Reconciliation (DEEP) and the `strategy_diversity` signal in Weighted Scoring.

---

## § Context Profiling (Stage 0)

**Goal:** prevent context dilution before the three-stage pass runs. Raw module bytes appended to a prompt degrade LLM performance on large modules (CPRVul, 2026) — selecting context beats appending context.

**When it runs:** mandatory in MEDIUM and DEEP, for every Phase 2a agent, before Stage 1 (Briefing). LOW skips Stage 0 (no module agents exist in LOW).

**Prompt injection:**

> Before briefing, enumerate candidate context for this module:
> - Callers and callees of every function defined in the module
> - Globals and types referenced by the module
> - Imports / depended-on modules
> - Control-flow guards (authn, authz, role checks, feature flags) present on module entrypoints
> - Tests covering the module (presence and coverage)
> - Config flags and runtime gates that affect the module's behavior
> - Sinks, sources, and sanitizers already identified by Phase 0 / Phase 1 / sink-hunter as relevant to this module
>
> For each candidate context item, compute a relevance score:
>
> `relevance = touches_untrusted_input × reaches_sensitive_sink × (1 - test_coverage_fraction)`
>
> Keep only the top-K items (K = 20 default, override via `--context-k=<N>`). Emit the selected set to `0-context-${MODULE}.json` with fields `{item_type, location, relevance_score, rationale}`.
>
> Subsequent stages reason **only** over the selected context plus the module's own source. Do NOT re-fetch raw bytes from discarded context items.

**Exit criterion:** `0-context-${MODULE}.json` exists with at least 5 items and a justification for why each was kept. If the module is trivially small (< 200 LOC), Stage 0 may emit "context-profiling-skipped: module-small" and pass the full module through to Stage 1.

**Failure mode:** agents that skip Stage 0 and grab the whole module wholesale under-perform on modules > 1k LOC. Prompt must be enforced; synthesis agent checks that `0-context-${MODULE}.json` exists before accepting a `2a-${MODULE}.{md,json}` pair.

---

## § Three-Stage Pass

Every Phase 2a agent runs a **three-stage internal pass** before emitting candidates. Stages execute sequentially inside the same agent; only candidates surviving all three reach `2a-<module>.{md,json}`.

### Stage 1 — Briefing

**Goal:** ground the agent in its slice of the world before it hunts.

**Prompt injection:**

> You are auditing module `${MODULE.name}`. Before searching for bugs, produce a briefing:
> 1. Restate the module's purpose, entry points, and trust boundary in your own words.
> 2. List the module's external surface (HTTP routes, message topics, CLI commands, library API) and its internal callers.
> 3. Identify the top 3–5 *assumed invariants* — things the code appears to trust (e.g., "this string is never attacker-controlled", "this path is always absolute", "this role check already ran upstream").
> 4. For each PATCH SEED filtered to this module, state whether an analogous unfixed site is structurally plausible.
>
> Do not emit candidate findings yet. Emit only the briefing.

**Exit criterion:** a briefing that names concrete entry points and concrete assumed invariants. Vague briefings ("handles HTTP things") fail; regenerate once before proceeding.

### Stage 2 — Class-enrichment

**Goal:** expand hypothesis space by loading the right bug-class lens.

**Prompt injection:**

> Given the briefing you just produced, load the bug-class references from the skill's Domain Reference Map that match this module's character. Use the per-language `sinks/*.md` files matching the detected language(s). For each candidate bug class you load:
> 1. State the specific sink pattern or invariant violation you are looking for in this module.
> 2. Trace source-to-sink for each candidate site you find. Include the transform chain — sanitizers, encoders, type coercions, framework-level escapes.
> 3. For each site, assess controllability (High/Medium/Low/Needs-verification) and note defense layers.
>
> Emit candidates in draft form. Do not self-filter yet — include weak candidates.

**Exit criterion:** a draft list of candidates with traces, each naming a specific bug class and sink. Candidates without traces are invalid drafts; the stage must produce traces before handing off.

### Stage 3 — Skeptical arbiter

**Goal:** drop candidates that would embarrass the agent in Phase 2.5.

**Prompt injection:**

> You are now a skeptical reviewer of your own drafts. For each draft candidate:
> 1. Reproduce the source-to-sink trace independently. If you cannot reach the sink from a user-controllable source without assuming unverified behavior, drop the candidate.
> 2. Check whether the suspected bug class matches the skill's **Always-Rejected Findings** table. If it does, drop it unless it appears in a working chain with proven impact.
> 3. Check whether the suspected trace passes the skill's **Phase 7 Exploitability Gate** questions 1–3 (controllability, reach, proof-of-impact). If any answer is No, drop to candidate-not-confirmed or drop entirely.
> 4. For surviving candidates, write the final finding record: file:line, source→sink trace, bug class, controllability, defense layers observed, suggested payload direction, discoverer strategy label.
>
> Emit ONLY candidates that survived all three stages. For each dropped candidate, log (in the Markdown output, not the JSON) a one-line "dropped: reason" entry so the synthesis phase can see what was rejected and why.

**Exit criterion:** a filtered candidate set where every entry has a trace, a bug class, a controllability rating, and an explicit strategy label. The dropped-list exists in the Markdown output.

### Why three stages, not one big prompt

- **Briefing first** pins assumptions down on paper — subsequent stages can challenge them explicitly instead of rediscovering them under time pressure.
- **Class-enrichment before arbiter** ensures the agent has looked at the right bug classes before it starts rejecting things. Skeptical-first collapses the search space; you only want skepticism *after* generation.
- **Arbiter last** prevents the common failure mode where the agent emits weak candidates because "more findings feels better". Self-filtration here is cheaper than Phase 2.5 filtration.

---

## § Analog Cascade

Phase 3 synthesis applies an **analog cascade** to every Confirmed finding. The idea: a confirmed bug in module X is prior evidence that structurally analogous bugs exist in modules Y, Z that Phase 2a missed.

**Tier gating:** does **not** fire in LOW (no Phase 2a module fan-out exists to cascade across). Fires in MEDIUM and DEEP. In DEEP, cascade consumes the cross-slice reconciliation output as an additional sibling-search surface.

### Procedure

For each Confirmed finding `F` emerging from Phase 2.5:

1. **Extract the structural signature of `F`:**
   - bug class (e.g., "unsanitized user input reaching `exec()` via `${VAR}` interpolation")
   - sink name + arity + language
   - source type (HTTP param / cookie / header / file content / DB row / config value)
   - transform chain (what sanitizers or escapers were missing or bypassed)
   - trust-boundary crossed (unauth→auth, tenant→tenant, user→admin, outside→inside)

2. **Search sibling module outputs** (`2a-<other>.{md,json}` plus `2b-sinks.json`) for sites matching the signature with *any* partial hit:
   - same sink, different source → potential analog
   - same source shape, different sink of the same class → potential analog
   - same trust-boundary bypass pattern → potential analog even across bug classes

3. **For each analog candidate:**
   - If the match is already a Confirmed or Candidate finding → link as related; boost its weighted-scoring `discoverer_count`.
   - If the match is new (not previously emitted) → emit as an **analog-flagged** candidate with:
     - pointer to the source finding `F`
     - structural similarity summary
     - explicit `analog_of: F.id` field in the JSON
   - Analog-flagged candidates enter Phase 2.5-style verification retroactively — the synthesis phase spawns one re-trace + one judge agent per analog before promoting it.

4. **Scope limit:** cascade depth 1. Do not cascade analogs-of-analogs — the noise/signal ratio collapses past depth 1, and genuine depth-2 analogs tend to share a root cause and will be caught by dedup.

### Why it works

- Developers who misuse an API in one place tend to misuse it in structurally similar ways elsewhere. A confirmed finding is the highest-quality hypothesis available in synthesis — cheaper than a fresh free-form pass, higher-precision than a patch seed.
- Phase 2a's module-anchored fan-out creates blind spots between modules: if bug `F` depends on patterns that cross two modules, neither module-agent owns the whole picture. Cascade closes that gap.
- It is deliberately **additive, not generative** — it only flags sites that already appear in some agent's output. It does not invent new candidates; it promotes and links existing ones.

### What cascade does NOT do

- Does not chain findings — chaining is Phase 6 (skill's existing workflow). Analog cascade is *sibling*-search, not *composition*-search.
- Does not revise severity of `F` itself — it feeds `discoverer_count` into weighted scoring, which may indirectly raise the score of `F`'s analogs but not `F`.
- Does not downgrade findings — an analog that fails verification stays in `candidates.md` as reviewer-noted.

---

## § Weighted Scoring

Every finding surviving Phase 2.5 accumulates a **weighted confidence score**. This replaces the single-verdict classification ("Confirmed / Candidate / False Positive") with a richer signal for the synthesis split.

### Signals

| Signal | Source | Weight | Rationale |
|--------|--------|--------|-----------|
| `discoverer_count` | Phase 2a + 2b + analog cascade | 0.15 | Multiple independent agents reaching the same site is strong prior evidence. Clipped at 3 (beyond 3, signal saturates). |
| `re_trace_verdict` | Phase 2.5 re-trace agent (pass / partial / fail) | 0.25 | Independent source→sink walk. Highest-weight verification signal. |
| `judge_verdict` | Phase 2.5 semantic-judge agent (correct / plausible / incorrect) | 0.20 | Second-opinion on diagnosis and impact. |
| `taint_trace_depth` | Depth of transform chain in the finding's trace | 0.10 | Shorter traces (1–2 hops) are typically higher-confidence than 5+ hops. Inverse-log scaling. |
| `skill_severity` | Mapped from finding's bug class via SKILL.md Phase 5 priority tiers (P0–P3) | 0.15 | Skill-level priors — P0 sinks tend to be real when the trace exists. |
| `strategy_diversity` | Was the finding discovered by ≥ 2 orthogonal strategies? | 0.10 | Cross-strategy agreement is a strong signal. Binary 0/1 * 0.10. |
| `seed_match` | Finding matches a PATCH SEED variant_query | 0.05 | Seed-hypothesis precision boost. |
| `dag_independent_verdict` *(DEEP only)* | Third verification agent: independent DAG reconstruction confirms mechanical reachability | 0.10 | Only active in DEEP's 3-check verification. |
| `cross_slice_agreement` *(DEEP only)* | Finding emerges from ≥ 2 distinct slice types (e.g., taint + sink-backward) | 0.05 | Independent graph cuts reaching the same site is the strongest DEEP-specific prior. |

**Total possible score:** 1.00. In DEEP, the two new signals (0.15 combined) are accommodated by rebalancing: `re_trace_verdict` 0.25→0.20, `judge_verdict` 0.20→0.15, `taint_trace_depth` 0.10→0.05. All other MEDIUM weights are unchanged. DEEP sum: 0.15 + 0.20 + 0.15 + 0.05 + 0.15 + 0.10 + 0.05 + 0.10 + 0.05 = 1.00. Weights are a starting distribution; the synthesis agent may adjust them with explicit justification recorded in `REPORT.md` if target characteristics warrant (e.g., memory-corruption findings might uprate `taint_trace_depth` because shallow traces dominate in that bug class).

### Thresholds

| Score | Classification | Destination |
|-------|----------------|-------------|
| `>= 0.75` AND passes Phase 7 gate | **Confirmed** | `confirmed.md` + `findings.json` |
| `0.50 – 0.75` OR fails Phase 7 for reasons other than controllability | **Candidate** | `candidates.md` |
| `< 0.50` OR marked False Positive in Phase 2.5 | **Rejected** | Not reported; logged in appendix for Phase 4 learning |

### Score calculation

For each finding:

```
score = sum(
  signal_normalized(s) * signal_weight(s)
  for s in signals
)
```

Where `signal_normalized(s)` maps each raw signal to [0, 1]:
- `discoverer_count`: `min(count, 3) / 3`
- `re_trace_verdict`: pass=1.0, partial=0.5, fail=0.0
- `judge_verdict`: correct=1.0, plausible=0.5, incorrect=0.0
- `taint_trace_depth`: `1.0 / (1 + log2(depth))` clipped to [0.2, 1.0]
- `skill_severity`: P0=1.0, P1=0.75, P2=0.5, P3=0.25
- `strategy_diversity`: 1.0 if discovered by ≥ 2 distinct strategies else 0.0
- `seed_match`: 1.0 if matches, else 0.0

Record the full signal vector alongside the score in `findings.json` so reviewers can inspect why a finding landed where it did.

### Failure modes to guard against

- **Runaway discoverer_count inflation from analog cascade:** cascade can push one underlying bug into many "discoveries" via sibling links. Clip `discoverer_count` at 3 and require at least one entry to be an original Phase 2a/2b emission (not analog-sourced).
- **Judge-aligned-with-re_trace bias:** if both verification agents share a blind spot, their agreement is spurious. Mitigation: prompt them separately with different framings (one "re-walk the path", one "challenge the diagnosis"), never share a context window.
- **Score-gaming by agents:** agents aware of the scoring signals may inflate `taint_trace_depth` reporting or over-claim strategy labels. Mitigation: signals are computed by the synthesis agent from finding metadata, not self-reported.

---

## § Static-First Lane (DEEP only)

DEEP runs a deterministic **static-first lane** before any LLM agent touches a promoted module. Rationale: CPRVul evidence shows naive context append degrades LLM performance; front-loading a mechanical pass produces cheap, high-precision seeds and narrows LLM scope to residual cases.

### Tooling priority

Per the Tool-Integration Matrix (see `vuln-research/SKILL.md` § Phase 3.5), pick in order of availability:

| Priority | Tool | Output |
|----------|------|--------|
| 1 | Joern (CPG) | Call-chain slices, PDG cuts, taint paths for promoted module(s) |
| 2 | CodeQL | Path queries from standard-library sources to sinks; SARIF sidecar |
| 3 | Semgrep + ast-grep (combined) | Semantic pattern hits + structural matches per language pack |
| 4 | Fallback: skill's `sinks/<lang>.md` grep catalog | Plain-text sink enumeration |

### Inputs

- Promoted modules (`promotion_score ≥ threshold` per § Effort Tiers) plus floor set
- Stack-detected language list from Phase 1
- PATCH SEEDS from `0-seeds.json`

### Outputs

- `2-static/<module>.sarif` (or tool-native equivalent) — raw mechanical hits
- `2-static/<module>.slices.json` — one entry per candidate slice: `{slice_id, slice_type, entrypoint, source_nodes[], sink_node, path[], control_guards[], sanitizers_seen[], confidence_prior}`

### Handoff to Phase 2a

Each promoted module-agent receives the static-first output for **its module only**, packaged as pre-built slices in the SecuritySlice input-packet format (see `references/dag-reasoning.md` § SecuritySlice Input Packet). Module-agents treat static hits as *hypotheses to verify*, not as findings to rubber-stamp — the three-stage pass still applies.

### Why static-first is gated to DEEP

- LOW has no module fan-out; a single freeform pass does not benefit from per-module slice prep.
- MEDIUM already delivers acceptable precision at its cost profile; adding a static pre-pass inflates setup cost without matching the verification depth DEEP pairs it with.
- DEEP's 3-check verification and cross-slice reconciliation are what make static-first's extra noise tolerable — the downstream filters catch the false positives the static lane produces.

---

## § Cross-Slice Reconciliation (DEEP only)

After every promoted module has run every applicable slice type, DEEP spawns a **reconciliation agent** per module to reconcile findings *across slice types within the module* before Phase 2.5.

### Purpose

A real bug often surfaces through multiple slice types (e.g., a command-injection shows up under `taint`, `sink-backward`, and `control-dependence` cuts). Naive merging by `file:line` under-counts this; structural reconciliation preserves the `cross_slice_agreement` signal feeding Weighted Scoring.

### Procedure

1. **Collect** all findings for the module across slice-type runs into a single working set.
2. **Group** by `{sink_node, root_source_class}`; within a group, tally distinct `discoverer_slice_type` values.
3. **Emit one reconciled finding per group** with:
   - merged trace (pick the shortest/highest-confidence path, record the others as `alternate_paths[]`)
   - `slice_types_agreeing[]` array
   - `cross_slice_agreement = len(slice_types_agreeing) >= 2`
4. **Drop** groups consisting entirely of static-lane hits that no slice-type LLM pass picked up — these likely represent tool false positives that the skill's bug-class filters already reject. Log them in `2-static-rejected/<module>.json` for Phase 4 learning.

### Output

- `2c-reconciled-<module>.json` — reconciled findings feeding Phase 2.5 verification (3-check in DEEP)

### Interaction with Phase 2.5 and analog cascade

- Phase 2.5 verifies the **reconciled** finding, not each slice-type emission separately. This keeps verification cost linear in reconciled count, not slice-type count.
- Analog cascade (§ Analog Cascade) treats the reconciled finding as the sibling-search anchor; `slice_types_agreeing[]` is propagated into analog candidates' metadata so reviewers can see which slice-type cut caught the analog.

---

## § Phase 4 Methodology

Phase 4 is a **continuous-learning pass**: after the audit completes, a final agent proposes evidence-grounded improvements to the `vuln-research` skill itself.

### Scope — ADDITIONS ONLY

Phase 4 proposes additions to:

- **Sinks** — per-language entries missing from `references/sinks/*.md` for stack members the audit encountered
- **Bug classes** — variants or subclasses the skill doesn't currently enumerate
- **Frameworks / runtimes** — stack components not covered in Phase 1 Recon's stack fingerprint
- **Config flags / runtime gates** — `disable_functions`, CSP directives, sandbox flags, etc. that mattered in this audit but aren't in the skill
- **Blind spots** — sites the agent discovered mid-audit that the Blind Spots Checklist doesn't mention
- **False-positive patterns** — patterns that slipped past the skill's Always-Rejected Findings table, causing wasted triage
- **Missing references** — cross-references the agent expected to exist but found absent
- **Wording gaps** — phases where the agent had to improvise because the existing language was ambiguous

### Out of scope — DO NOT propose

- New phases, new modes, or pipeline reorderings
- Rewrites of Philosophy, Mode Sel  ection, or Domain Reference Map structure
- Ex-novo architectural changes
- Opinions unsupported by an audit moment
- Deletions — Phase 4 is additive; deletion proposals go to a human reviewer through the normal skill-maintenance path, not through the pipeline

### Evidence-grounding rule

**Every proposal must cite the exact audit moment that motivated it.** No speculative additions. No "it would be nice if the skill had…" without a specific gap that cost time during this audit.

A citation must include:
- target-repo `file:line` where the gap mattered
- the finding id (if the gap relates to a specific finding) or the phase + module + moment (if it relates to methodology)
- a one-sentence description of what the agent had to improvise or what signal was missed

Proposals without citations are invalid and must be discarded before `skill-improvements.md` is written.

### Proposal record shape

Every entry in `skill-improvements.md` carries:

```
[
  title,                          # short imperative phrase, e.g., "Add phpggc-chain sink variant to sinks/php.md"
  gap_observed,                   # what was missing and how it manifested — one paragraph max
  evidence,                       # file:line in target repo + finding id + audit-moment description
  suggested_insertion_point,      # skill file + section heading, e.g., "SKILL.md § Phase 4: Taint Analysis"
                                  # or "references/sinks/php.md § Deserialization — phpggc chains"
  proposed_text,                  # the literal text to add, ≤ 10 lines
  priority                        # High / Medium / Low based on how often similar gaps likely recur
]
```

Markdown structure in the output file: one level-2 heading per proposal, with the seven fields as a definition list or labeled paragraphs.

### Priority rubric

| Priority | Criteria |
|----------|----------|
| **High** | Gap caused the agent to miss a finding or misclassify a real bug as False Positive. Affects any audit of a comparable stack. |
| **Medium** | Gap caused the agent to spend extra cycles improvising, but didn't change the outcome. Likely to recur in similar audits. |
| **Low** | Gap was minor (wording, cross-reference, small sink entry). Nice-to-have. |

### What Phase 4 is NOT

- **Not a PR to the skill.** It's a proposal document. Human review gates every addition. The pipeline does not self-modify the skill.
- **Not a postmortem of the audit.** It's scoped specifically to *skill-level* gaps, not to pipeline bugs, target-specific weirdness, or reviewer workflow concerns.
- **Not a summary of the audit.** `REPORT.md` is the summary. `skill-improvements.md` only contains proposals.

### Grounding check

Before emitting `skill-improvements.md`, the agent must verify:

- Every proposal has an evidence citation with a concrete `file:line` in the target repo or a concrete phase-moment reference.
- No proposal falls into the out-of-scope list (new phases, rewrites, deletions).
- No proposal duplicates existing skill content — the agent must have read the suggested-insertion-point section and confirmed the proposed text is genuinely new.
- Proposals are deduplicated — if two audit moments motivated the same addition, merge into one proposal with both citations.

Proposals failing the grounding check are dropped, not watered down.

---

## Integration with Existing Skill

The Swarm Pipeline consumes the skill's taxonomy; it does not replace it.

| Pipeline step | Skill integration |
|---------------|-------------------|
| Phase 0 recency | Invokes SKILL.md § Phase 0 as-is, adds PATCH SEED extraction on top |
| Phase 1 map | Invokes SKILL.md § Phase 1 (Recon) + § Phase 2 (Crown Jewels + Attention Deficit) |
| Phase 2a class-enrichment stage | Loads per-language `sinks/*.md` via SKILL.md § Phase 3.5 (Technology Stack Discovery) |
| Phase 2a skeptical arbiter | Applies SKILL.md § Always-Rejected Findings + § Phase 7 questions 1–3 |
| Phase 2b sink-hunter | Loads `sinks-catalog.md` router + matching per-language sinks files |
| Phase 3 chaining | Invokes SKILL.md § Phase 6 (Vulnerability Chaining) |
| Phase 3 gate | Invokes SKILL.md § Phase 7 (Exploitability Gate) |
| Phase 3 blind-spots check | Invokes SKILL.md § Blind Spots Checklist |
| Phase 4 | Reads SKILL.md + all `references/` to identify gaps |

The pipeline owns structural orchestration; the skill owns every security claim.

---

## Relationship to Agent Sweep (`agent-sweep.md`)

| Dimension | Agent Sweep | Swarm Pipeline |
|-----------|-------------|----------------|
| Starting anchor | Single file | Module (group of files) + patch seeds |
| Strategy diversity | Implicit (sampling variance) | Explicit (≥ 2 orthogonal strategies required) |
| Per-agent internal pass | Single-shot discovery | Three-stage (briefing → enrichment → arbiter) |
| Verification | One fresh agent, one classification | Two separate agents (re-trace + judge), weighted combination |
| Synthesis | Dedup + cluster + feed forward | Dedup + analog cascade + weighted scoring + chain + gate + split |
| Learning loop | None | Phase 4 continuous-learning proposal |
| Best for | Maximum-coverage sweeps, unknown-unknowns | Structured deep audits, continuous skill improvement |
| Cost | High compute, medium precision | Higher compute, higher precision, reusable skill feedback |

Running both in sequence — Agent Sweep first for raw discovery, then Swarm Pipeline on the surviving modules — is a valid Hybrid-plus strategy for critical targets. The Swarm Pipeline's Phase 4 output improves the skill for future Agent Sweep runs, closing the learning loop across modes.

---

> **Remember:** The pipeline is a scaffold, not a substitute for thinking. Orthogonal strategies exist because blind spots cluster. Three-stage passes exist because single-shot agents over-commit. Analog cascade exists because bugs travel in packs. Weighted scoring exists because single verdicts lie. Phase 4 exists because the skill should get better every time it's used. Use the scaffold; don't mistake it for the job.
