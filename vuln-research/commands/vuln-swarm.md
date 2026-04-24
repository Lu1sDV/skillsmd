---
name: vuln-swarm
description: >
  Multi-phase SAST swarm pipeline for deep vulnerability research. Recency pass with
  patch-seed extraction, holistic map with module decomposition, parallel narrow
  analysis across modules (orthogonal strategies) + sink-hunter, two-check
  verification (re-trace + semantic judge), synthesis with analog cascade and
  weighted scoring, skill-improvement feedback.
argument-hint: "<target-repo-path> [--effort=low|medium|deep] [--freeform=detached|grounded]"
---

# Vulnerability Research — Swarm Pipeline

Target: `$ARGUMENTS`

> **This command owns the PIPELINE SHAPE and the HANDOFF CONTRACT.**
> **The `vuln-research` skill owns TAXONOMY, SINK CATALOGS, BUG CLASSES, GATES.**
> Do not re-specify what the skill already specifies — invoke it.
>
> Mode: **SAST only**. No running instance. No rule engines. Skill decides everything else.

## Flags

- `--effort=low|medium|deep` (default: `medium`) — selects the effort tier. See `references/swarm-pipeline.md` § Effort Tiers for the authoritative tier-gating table. Summary:
  - **LOW**: Phase 0 → 1–2 freeform agents → single re-check → Phase 3-lite. No module fan-out, no sink-hunter, no analog cascade.
  - **MEDIUM**: full pipeline as specified below (baseline).
  - **DEEP**: MEDIUM + static-first lane + every applicable slice-type per promoted module + 3-check verification + cross-slice reconciliation. Module promotion uses `promotion_score` (crown-jewel +2, attention-deficit +2, PATCH SEED +1) with floor = top-2 attention-deficit.

- `--freeform=detached|grounded` (default: `detached`) — freeform-agent posture. See `references/freeform-detached.md` for the full contract.
  - **detached** (default): freeform agent runs without loading skill taxonomy; emits findings as raw observations, which still pass through Phase 2.5 verification and Phase 7 exploitability gate.
  - **grounded**: freeform agent is briefed with the skill's bug-class taxonomy and sink catalogs before analysis.

Load the `vuln-research` skill (`vuln-research/SKILL.md`). Also load `vuln-research/references/swarm-pipeline.md` for methodology sections referenced below (effort tiers, module decomposition, orthogonal strategies, slice types, context profiling, three-stage per-agent pass, static-first lane, cross-slice reconciliation, analog cascade, weighted scoring, Phase 4 continuous-learning scope).

All artifacts live under `$ARGUMENTS/.vuln-swarm/` (create if missing). Every artifact is **Markdown + JSON sidecar**. Every finding cites `file:line` with a source→sink trace.

---

## ═══ Tier gating ═══

| Phase | LOW | MEDIUM | DEEP |
|-------|-----|--------|------|
| 0 — Recency + seeds | ✓ | ✓ | ✓ |
| 1 — Holistic map + decomposition | ✓ (map only, no decomposition) | ✓ | ✓ (+ `promotion_score` annotation) |
| 1.5 — Static-first lane | — | — | ✓ (promoted modules only) |
| 2a — Module fan-out | — | ✓ | ✓ (every applicable slice type per promoted module) |
| 2b — Sink-hunter | — | ✓ | ✓ |
| 2.5 — Verification | single re-check | 2-check (re-trace + judge) | 3-check (+ DAG-independent) |
| 2c — Cross-slice reconciliation | — | — | ✓ (per promoted module) |
| 3 — Synthesis (dedup, analog cascade, scoring, chain, gate) | lite (no analog cascade) | ✓ | ✓ (consumes cross-slice output) |
| 4 — Skill-improvement proposal | — | ✓ | ✓ |

**LOW short-circuit:** after Phase 0, run 1–2 freeform agents (detached by default, see `--freeform`), single re-check verification per finding, then jump straight to Phase 3-lite (dedup + scoring + skill's Phase 6/7 chain + gate). No module fan-out, no sink-hunter, no analog cascade.

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

**LOW:** skip decomposition — only `1-map.md`/`1-map.json` are produced.

**DEEP:** each module entry additionally carries `promotion_score` (crown-jewel +2, attention-deficit +2, PATCH SEED +1) and a boolean `promoted` flag. Floor rule: minimum two modules promoted (top-2 by attention-deficit) even if no crown jewels.

**Outputs:**
- `1-map.md` — ≤ 600 lines, human-facing
- `1-map.json` — structured mirror
- `1-decomposition.json` — `[{name, paths[], summary, suspected_risks[], promotion_score?, promoted?}]` *(MEDIUM + DEEP)*

---

## ═══ Phase 1.5 — Static-first lane (DEEP only, sequential) ═══

Per `references/swarm-pipeline.md` § Static-First Lane. For every promoted module, run the highest-priority available CPG/SAST tool (Joern → CodeQL → Semgrep+ast-grep → fallback grep of skill's `sinks/<lang>.md`). Emit pre-built SecuritySlice packets (see `references/dag-reasoning.md` § SecuritySlice Input Packet) for consumption by Phase 2a agents.

**Outputs:**
- `2-static/<module>.sarif` (or tool-native) — raw mechanical hits
- `2-static/<module>.slices.json` — `[{slice_id, slice_type, entrypoint, source_nodes[], sink_node, path[], control_guards[], sanitizers_seen[], confidence_prior}]`

Skipped in LOW and MEDIUM.

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

**MEDIUM + DEEP: Stage 0 context profiling.** Before Stage 1, run `references/swarm-pipeline.md` § Context Profiling — compute relevance score per candidate file/slice and drop below-threshold noise. Output `0-context-<module>.json`.

**DEEP — slice-type fan-out:** each promoted module spawns one agent per applicable slice type (taint, sink-backward, source-forward, control-dependence, pdg, plus module-character-specific slices per the applicability matrix in `references/swarm-pipeline.md` § Slice Types). Each agent emits `2a-<module>-<slice_type>.{md,json}`. Findings carry `discoverer_slice_type`.

**Output per agent:**
- `2a-<module>.md` *(MEDIUM)* / `2a-<module>-<slice_type>.md` *(DEEP)*
- `2a-<module>.json` / `2a-<module>-<slice_type>.json`

### Lane 2b — Sink-hunter (1 agent, parallel with 2a)

Cross-cuts modules, **file-anchored**. Loads the skill's sinks router (`references/sinks-catalog.md`) + per-language sinks files matching the detected stack. Also receives `0-seeds.json` for variant hunting.

**Outputs:**
- `2b-sinks.md`
- `2b-sinks.json`

---

## ═══ Phase 2c — Cross-slice reconciliation (DEEP only, 1 agent per promoted module, parallel) ═══

Per `references/swarm-pipeline.md` § Cross-Slice Reconciliation. Within each promoted module, merge findings across slice-type runs by `{sink_node, root_source_class}`. Emit one reconciled finding per group with `slice_types_agreeing[]` and `cross_slice_agreement` boolean. Drop static-lane-only hits with no LLM-pass confirmation into `2-static-rejected/<module>.json` for Phase 4.

**Outputs:**
- `2c-reconciled-<module>.json` — feeds Phase 2.5 (3-check verification)
- `2-static-rejected/<module>.json` — dropped static-only noise (Phase 4 learning input)

Skipped in LOW and MEDIUM.

---

## ═══ Phase 2.5 — Verification loop (fresh-eye subagents, parallel) ═══

Per the skill's **Phase S3 (2-check verification)**. Every finding from Phase 2a/2b (or 2c in DEEP) is re-evaluated by an agent that was **NOT** its discoverer, via distinct checks made as **separate agent calls with separate prompts**:

1. **RE-TRACE** — independent source→sink walk: does the path exist as claimed?
2. **JUDGE** — semantic-correctness review: given this finding and its claimed root cause, is the diagnosis correct? Is the alleged data flow actually reachable? Is the impact as stated?
3. **DAG-INDEPENDENT** *(DEEP only)* — reconstruct the reasoning DAG from scratch per `references/dag-reasoning.md`; does the mechanical graph confirm reachability independent of prose arguments?

**LOW:** single re-check only (one RE-TRACE agent). Finding is `Confirmed` if it passes, `Candidate` otherwise.

Combine (MEDIUM):
- **pass BOTH** → `Confirmed`
- **pass one** → `Candidate`
- **fail BOTH** → `False Positive`

Combine (DEEP):
- **pass ALL THREE** → `Confirmed`
- **pass 2 of 3** → `Candidate`
- **pass ≤ 1** → `False Positive`

**Output:** `2_5-verified.json` — `[{finding_id, re_trace_verdict, judge_verdict, dag_independent_verdict?, classification, notes}]`

---

## ═══ Phase 3 — Synthesis (1 subagent, sequential) ═══

Reads all prior outputs. Steps:

1. **DEDUP** — same root cause across discoverers → merge (keep best trace)
2. **ANALOG CASCADE** *(MEDIUM + DEEP only; skipped in LOW)* — for each Confirmed finding in module X, search other modules' outputs for structurally analogous patterns that may have been missed; flag analogs for reviewer attention. See `references/swarm-pipeline.md` § Analog Cascade. DEEP additionally consumes `2c-reconciled-<module>.json` as a sibling-search surface.
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
├── 0-recency.md                                  (all tiers)
├── 0-recency.json                                (all tiers)
├── 0-seeds.json                                  (all tiers)
├── 1-map.md                                      (all tiers)
├── 1-map.json                                    (all tiers)
├── 1-decomposition.json                          (MEDIUM + DEEP)
├── 2-static/<module>.sarif                       (DEEP only)
├── 2-static/<module>.slices.json                 (DEEP only)
├── 0-context-<module>.json                       (MEDIUM + DEEP)
├── 2a-<module>.md / .json                        (MEDIUM)
├── 2a-<module>-<slice_type>.md / .json           (DEEP, one pair per slice type per promoted module)
├── 2b-sinks.md / .json                           (MEDIUM + DEEP)
├── 2c-reconciled-<module>.json                   (DEEP only)
├── 2-static-rejected/<module>.json               (DEEP only)
├── 2_5-verified.json                             (all tiers; LOW = single re-check)
├── REPORT.md                                     (all tiers)
├── findings.json                                 (all tiers)
├── bad-patterns.json                             (MEDIUM + DEEP)
├── confirmed.md                                  (all tiers)
├── candidates.md                                 (all tiers)
└── skill-improvements.md                         (MEDIUM + DEEP)
```
