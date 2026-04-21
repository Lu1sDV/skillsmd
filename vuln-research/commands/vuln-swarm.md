---
name: vuln-swarm
description: >
  Multi-phase SAST swarm pipeline for deep vulnerability research. Recency pass with
  patch-seed extraction, holistic map with module decomposition, parallel narrow
  analysis across modules (orthogonal strategies) + sink-hunter, two-check
  verification (re-trace + semantic judge), synthesis with analog cascade and
  weighted scoring, skill-improvement feedback.
argument-hint: "<target-repo-path>"
---

# Vulnerability Research — Swarm Pipeline

Target: `$ARGUMENTS`

> **This command owns the PIPELINE SHAPE and the HANDOFF CONTRACT.**
> **The `vuln-research` skill owns TAXONOMY, SINK CATALOGS, BUG CLASSES, GATES.**
> Do not re-specify what the skill already specifies — invoke it.
>
> Mode: **SAST only**. No running instance. No rule engines. Skill decides everything else.

Load the `vuln-research` skill (`vuln-research/SKILL.md`). Also load `vuln-research/references/swarm-pipeline.md` for methodology sections referenced below (module decomposition, orthogonal strategies, three-stage per-agent pass, analog cascade, weighted scoring, Phase 4 continuous-learning scope).

All artifacts live under `$ARGUMENTS/.vuln-swarm/` (create if missing). Every artifact is **Markdown + JSON sidecar**. Every finding cites `file:line` with a source→sink trace.

---

## ═══ Phase 0 — Recency pass + seed extraction (1 subagent, sequential) ═══

Invoke the skill's **Phase 0 (Latest Commits Security Review)**. Respect its fallbacks (no git / <3 commits / docs-only / subagent failure).

**Additional responsibility:** from the same commit range, extract a set of **PATCH SEEDS** — recently-fixed bugs or tightened controls that downstream agents use as hypothesis templates ("are there unfixed variants of this pattern elsewhere in the tree?"). See the skill's Phase 0 for the PATCH SEED record shape.

**Outputs:**
- `0-recency.md` — human-facing narrative (Phase 0 standard output)
- `0-recency.json` — structured mirror
- `0-seeds.json` — array of PATCH SEEDS `[{affected_file, affected_hunk, fix_summary, bug_class, variant_query}]`

---

## ═══ Phase 1 — Holistic map (1 subagent, sequential, runs BEFORE Phase 2) ═══

Invoke the skill's **Phase 1 (Recon)** + **Phase 2 (Crown Jewels + Attention Deficit)**. Capture **vulnerabilities AND misconfigurations, bad patterns, low-impact smells/bad habits** — everything that should be on the final reviewer's radar, not just exploitable findings.

End the phase by emitting a **module-level decomposition** of 8–15 modules driving Phase 2a fan-out, per `references/swarm-pipeline.md` § Module Decomposition. Each module entry: `{name, paths[], summary, suspected_risks[]}`.

**Outputs:**
- `1-map.md` — ≤ 600 lines, human-facing
- `1-map.json` — structured mirror
- `1-decomposition.json` — `[{name, paths[], summary, suspected_risks[]}]`

---

## ═══ Phase 2 — Parallel narrow analysis (two lanes, fan out) ═══

### Lane 2a — Module agents (one per module in `1-decomposition.json`)

**Input each agent receives:**
- its own module entry + `1-map.md`
- one-line index of sibling modules
- PATCH SEEDS from `0-seeds.json` filtered to its module
- **code slices**: program-analysis-extracted call-chain slices centered on suspected sinks (not raw file blobs)

Compression budget per agent: *module entry + sibling one-line index + filtered seeds + call-chain slices only*.

**Orthogonal-strategy requirement:** across the pool of N module agents, **at least 2 distinct analysis strategies** must be represented (e.g., source-forward, sink-backward, seed-hypothesis-driven, free-form) — not N copies of the same prompt. See `references/swarm-pipeline.md` § Orthogonal Strategies for allocation rules.

**Internal structure per agent (three-stage pass):** Briefing → Class-enrichment → Skeptical arbiter. See `references/swarm-pipeline.md` § Three-Stage Pass for per-stage prompts and exit criteria. Only candidates that survive Briefing → Class-enrichment → Skeptical arbiter are emitted.

**Output per agent:**
- `2a-<module>.md`
- `2a-<module>.json`

### Lane 2b — Sink-hunter (1 agent, parallel with 2a)

Cross-cuts modules, **file-anchored**. Loads the skill's sinks router (`references/sinks-catalog.md`) + per-language sinks files matching the detected stack. Also receives `0-seeds.json` for variant hunting.

**Outputs:**
- `2b-sinks.md`
- `2b-sinks.json`

---

## ═══ Phase 2.5 — Verification loop (fresh-eye subagents, parallel) ═══

Per the skill's **Phase S3 (2-check verification)**. Every finding from Phase 2a/2b is re-evaluated by an agent that was **NOT** its discoverer, via **two distinct checks** made as **separate agent calls with separate prompts**:

1. **RE-TRACE** — independent source→sink walk: does the path exist as claimed?
2. **JUDGE** — semantic-correctness review: given this finding and its claimed root cause, is the diagnosis correct? Is the alleged data flow actually reachable? Is the impact as stated?

Combine:
- **pass BOTH** → `Confirmed`
- **pass one** → `Candidate`
- **fail BOTH** → `False Positive`

**Output:** `2_5-verified.json` — `[{finding_id, re_trace_verdict, judge_verdict, classification, notes}]`

---

## ═══ Phase 3 — Synthesis (1 subagent, sequential) ═══

Reads all prior outputs. Steps:

1. **DEDUP** — same root cause across discoverers → merge (keep best trace)
2. **ANALOG CASCADE** — for each Confirmed finding in module X, search other modules' outputs for structurally analogous patterns that may have been missed; flag analogs for reviewer attention. See `references/swarm-pipeline.md` § Analog Cascade
3. **WEIGHTED SCORING** — each finding accumulates a confidence score from weighted signals (discoverer count, re-trace verdict, judge verdict, taint-trace depth, skill-assigned severity). Only findings above the confirmed threshold proceed to step 4. See `references/swarm-pipeline.md` § Weighted Scoring
4. **CHAINING** — apply skill **Phase 6** (Vulnerability Chaining)
5. **EXPLOITABILITY GATE** — apply skill **Phase 7** (Exploitability Gate)
6. **ALWAYS-REJECTED FILTER + BLIND SPOTS CHECKLIST** — apply the skill's Always-Rejected Findings table and Blind Spots Checklist
7. **SPLIT** — findings that pass the gate AND score above confirmed-threshold → `confirmed.md`; the rest (with reviewer value) → `candidates.md`

**Deliverables:**
- `REPORT.md` — tiered: exec summary → findings catalogue → Bad Habits & Misconfigurations → appendix
- `findings.json` — SARIF-compatible
- `bad-patterns.json` — non-exploitable smells (misconfigurations, bad habits, low-impact observations)
- `confirmed.md`
- `candidates.md`

---

## ═══ Phase 4 — Skill improvement proposal (1 subagent, sequential, LAST) ═══

Continuous-learning pass. Input: every prior phase's outputs + `vuln-research/SKILL.md` + its `references/` tree.

**Scope — ADDITIONS ONLY:**
- sinks, bug classes, frameworks, config flags, runtime gates, blind-spots observed during this audit that are NOT already in the skill or its references
- false-positive patterns that slipped past the skill's always-rejected list
- missing per-language sink entries for stack members that had no matching `sinks/<lang>.md`
- references that should exist but don't
- wording gaps in existing phases where the agent had to improvise

**Out of scope — do NOT propose:**
- new phases, new modes, or pipeline reorderings
- rewrites of philosophy / mode-selection / routing
- ex-novo architectural changes

Every proposal must be **evidence-grounded**: cite the exact audit moment (file:line in the target repo + finding id) where the gap mattered. No speculative additions.

**Output:** `skill-improvements.md` — each proposal carries:
`[title, gap_observed, evidence, suggested_insertion_point (file + section heading), proposed_text (≤ 10 lines), priority (High/Med/Low)]`

See `references/swarm-pipeline.md` § Phase 4 Methodology for full proposal record shape and evidence-grounding rule.

---

## Handoff contract (applies every phase)

- Every artifact: **Markdown + JSON sidecar**
- Every finding: **file:line + source→sink trace**
- Every narrow-agent compressed handoff: **≤ own module entry + sibling one-line index + filtered seeds + call-chain slices** (no raw file dumps, no cross-module blobs)
- Mode: **SAST only** — no running instance, no rule engines. The skill decides everything else.

## Final deliverable set (all under `$ARGUMENTS/.vuln-swarm/`)

```
.vuln-swarm/
├── 0-recency.md
├── 0-recency.json
├── 0-seeds.json
├── 1-map.md
├── 1-map.json
├── 1-decomposition.json
├── 2a-<module>.md             (one pair per module)
├── 2a-<module>.json
├── 2b-sinks.md
├── 2b-sinks.json
├── 2_5-verified.json
├── REPORT.md
├── findings.json
├── bad-patterns.json
├── confirmed.md
├── candidates.md
└── skill-improvements.md
```
