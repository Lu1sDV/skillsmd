# Model Routing & Orchestration (operational — NOT from the paper)

Everything here is guidance for running FuzzGPT as a **Claude Code multi-agent
workflow**. None of it comes from Deng et al. — the paper is silent on agent
orchestration. The reproducible contract (temps, K, budgets, variants, oracles)
lives in the other references and is model-independent; do not let routing
choices here perturb those values.

## Two different "models" — keep them separate

| Concern | What it is | Decided in |
|---------|-----------|-----------|
| **Generation model** | The LLM that actually writes fuzz programs / labels fuzz targets (paper's Codex/CodeGen; modern Claude/Qwen) | `hyperparameters.md` — an inference-cost & diversity choice |
| **Orchestration model** | Which Claude *subagent tier* (opus/sonnet/haiku) drives each pipeline step | This file — a cognitive-load routing choice |

Conflating them is the common mistake. A sonnet subagent can perfectly well
*drive* a generation loop that calls a strong generation model; the subagent tier
is about the judgment the **step** needs, not the quality of programs produced.

## Route by cognitive load, not by task type

Three questions decide the tier for any step:

1. **Is the output hard to verify?** Instantly checkable → cheap. Correctness needs deep reasoning even to *evaluate* → opus.
2. **Does an error compound?** Strategy/triage decisions poison the whole budget downstream → opus. Mechanical edits don't → cheap.
3. **Is the input ambiguous/adversarial?** Resolving conflicting numeric signals → opus. Following a fixed spec → cheap.

## Per-step routing (against the 5-stage pipeline)

| Step | Subagent | Why |
|------|----------|-----|
| **1. MINE** — `gh` crawl, syntax filter, ≤256-tok cap, concat code blocks | **haiku / sonnet** | Mechanical shell + filtering. Verifiable by "did snippets land?". No compounding. |
| **2. ANNOTATE** — 6-shot self-training buggy-fuzz-target labels | **sonnet** | Paper says imprecise labels are fine — they only *steer*. Low error cost. Subagent just drives the generation model. |
| **3. GENERATE — strategy setup** — pick FS/ZS/RT, build CoT template, set K/temp/budget | **opus** | Wrong variant wastes the whole budget (100 progs × N fuzz targets). Ambiguous (depends on history quality, corpus size, embedding backend availability) and compounds. |
| **3. GENERATE — inner loop** — run the chosen prompts, collect programs | **sonnet** | Once strategy is fixed, this is a mechanical fan-out. |
| **4. EXECUTE** — run each program against oracles | **haiku / sonnet** | Pure execution + capture. Verifiable by exit codes/output. |
| **5. ORACLES — crash detection** | **haiku** | A crash is self-evident; no judgment. |
| **5. ORACLES — differential triage** — CPU/GPU & autodiff divergence | **opus** | "Real wrong-computation bug vs. acceptable numerical tolerance?" is hard-to-verify judgment. False positives flood the report; false negatives lose the silent bugs the differentials exist to catch. |

## The two opus-worthy moments

Everything else is a sonnet/haiku assembly line. Opus earns its cost in exactly two places:

1. **Variant + strategy selection (step 3 setup).** The decision gates the entire generation budget and is genuinely ambiguous. Get it right once, cheaply execute it many times.
2. **Differential-oracle triage (step 5).** Crash = mechanical. Float/gradient divergence = judgment. This is the quality gate of the whole campaign.

**Mnemonic: opus bookends, cheap models fill the middle.** Opus decides the
strategy at the top and judges the ambiguous oracle output at the bottom; mining →
annotate → execute → crash-detect is a cheap pipeline in between.

## Parallel fan-out pattern (when orchestrating as a swarm)

Steps 3–4–5 are **embarrassingly parallel per fuzz target**. The cost-correct
topology:

```
                    ┌─ sonnet executor: target_1  (generate 100 → run → crash-detect) ─┐
opus strategist ──▶ ├─ sonnet executor: target_2  ─────────────────────────────────────┤ ──▶ opus triage
(step 3 setup,      ├─ sonnet executor: target_3                                        │     (only the
 once)              └─ … one per fuzz target …                                          ┘      divergence cases)
```

- **One opus call up front** to fix the variant/strategy — not one per fuzz target.
- **N sonnet executors**, one per fuzz target, each running its own generation + execution + crash-detection loop. Crashes are reported directly (cheap, self-evident).
- **Funnel only the differential-divergence cases** (CPU/GPU or AD mismatches that aren't crashes) into a **single opus triage lane**. You do not want 50 opus agents running fuzz loops; you want 50 sonnet loops feeding one opus judge.

Anti-pattern: spawning opus per fuzz target. It multiplies cost on the mechanical middle
of the pipeline while adding no judgment where none is needed.

## Interaction with the generation-model choice

Orthogonal, but worth stating: a cheap *orchestration* tier does not imply a cheap
*generation* model. You might run sonnet executors that each call a strong
generation model (Claude Opus-class or a large Qwen2.5-Coder) for program
synthesis. Pick the generation model for diversity/validity per `hyperparameters.md`;
pick the subagent tier for the step's judgment load per this file. They are set
independently.
