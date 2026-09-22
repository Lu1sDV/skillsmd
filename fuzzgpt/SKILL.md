---
name: fuzzgpt
description: >
  Use when you want to fuzz any software target — library, compiler, interpreter,
  parser, kernel/syscall, DB engine, SMT solver, binary/file format, or network
  protocol — by priming an LLM with that target's HISTORICAL bug-triggering code
  to generate unusual, edge-case inputs (history-driven LLM fuzzing). FuzzGPT-derived:
  retrieval replaces fine-tuning (Deng et al., arXiv:2304.02014): mine bug reports →
  auto-label each snippet's buggy fuzz target → few-shot / zero-shot / retrieval
  generation → crash + differential oracles. Trigger on "FuzzGPT", "fuzz this
  library/compiler/parser/protocol", "generate edge-case test programs",
  "history-driven fuzzing", or when pairing with vuln-research to turn a target's
  bug history into fresh fuzzing inputs. Target-agnostic: the "fuzz target" is
  whatever unit you point generation at — an API in the paper's DL study, but
  equally a compiler flag, SQL feature, syscall, opcode, or protocol field.
---

# FuzzGPT — History-Driven LLM Fuzzing

> **FuzzGPT-derived: retrieval replaces fine-tuning.** The original paper's FS and ZS
> variants are reproduced faithfully. Fine-tuning (FT) is replaced by an
> embedding-retrieval pathway (RT) — see `references/retrieval.md`.

**Core hypothesis (the whole skill rests on this):** historical bug-triggering
programs contain rare, valuable *code ingredients* — special values (`NaN`,
`inf`, `INT_MAX`, empty/oversized inputs), edge-case shapes/sizes/lengths,
0-size dimensions, unconventional use of the target — that ordinary LLM
generation never produces. LLMs trained on GitHub generate *typical* programs;
fuzzing wants *unusual* ones. FuzzGPT closes that gap by priming the LLM with
real past bugs instead of asking it to be "creative."

This is the unusual-input engine. It pairs with `vuln-research` (which decides
*what* to target and triages findings); FuzzGPT decides *how* to generate inputs
that actually hit edge cases.

## The unit you fuzz: the "fuzz target"

FuzzGPT steers generation toward one **fuzz target** at a time — the specific
unit of functionality you want to stress (here, *the unit you point generation
at*, not a libFuzzer harness). In the paper's DL-library study the fuzz target
is an **API** (e.g. `torch.gather`), and the references use API examples
throughout, but the method is unit-agnostic. Map "fuzz target" to your domain:

| Domain | A "fuzz target" is… | Example |
|--------|---------------------|---------|
| DL / numeric library (paper) | a library API | `torch.gather` |
| Compiler / interpreter | a flag, optimization pass, or language construct | `-O2`, loop-unrolling |
| DB engine | a SQL feature / function | window functions, `JSON_TABLE` |
| SMT solver | a theory / operator | bitvectors, `array-ext` |
| Kernel / runtime | a syscall / ioctl | `io_uring`, `ioctl(FS_IOC_…)` |
| Parser / file format | a format field / chunk | PNG `tEXt`, ELF section header |
| Network protocol | a message type / field | TLS extension, HTTP/2 frame |
| Bytecode VM | an opcode | `INVOKEDYNAMIC` |

**Everywhere the references say "API," read "fuzz target."** The empirical tables
in `evaluation.md` keep "API" verbatim — they report the paper's actual
PyTorch/TensorFlow numbers, where the fuzz target happens to be an API.

## When to reach for this vs. plain LLM generation

| Situation | Use |
|-----------|-----|
| Target has a public issue tracker / past bug reports | **FuzzGPT** (mine the history) |
| You need inputs that hit edge cases, not example usage | **FuzzGPT** |
| Target is brand new, zero bug history | Plain seed generation (TitanFuzz-style) or the ChatGPT no-history variant below |
| You're deciding *which* fuzz targets / sinks to fuzz | `vuln-research` first, then FuzzGPT |

## The pipeline (5 steps)

```
1. MINE      gh issues/PRs → bug-triggering code snippets (+ titles)
2. ANNOTATE  self-train LLM to label each snippet's buggy fuzz target (K=6 manual seeds)
3. GENERATE  pick a variant: few-shot | zero-shot | retrieval  → 100 progs/fuzz target
4. EXECUTE   run each program against oracles
5. ORACLES   crash | CPU-GPU differential | autodiff (AD) differential
```

Read the reference for the step you're on — don't load everything:

| Step | Reference | Load when |
|------|-----------|-----------|
| Mining + annotation | `references/pipeline.md` | Building the dataset, writing the crawler, labeling fuzz targets |
| FS + ZS generation variants + exact prompt templates + formulas | `references/prompt-templates.md` | Constructing prompts / generating programs |
| RT (retrieval) pathway — components, Mode A/B, hyperparams, reference code | `references/retrieval.md` | Using embedding-retrieval instead of fine-tuning |
| Hyperparameters + model choices + modern mapping | `references/hyperparameters.md` | Setting temps, K, budgets, picking a model |
| Oracles | `references/oracles.md` | Detecting bugs from generated programs |
| Full evaluation protocol (RQs, baselines, metrics, paper targets) | `references/evaluation.md` | Measuring coverage/bugs, reproducing the study, validating results |
| Model routing + parallel fan-out (which subagent tier runs each step) | `references/orchestration.md` | Running this as a Claude Code multi-agent workflow / swarm |

## Model routing (one line; full table in `references/orchestration.md`)

If you orchestrate this as a multi-agent workflow, **opus bookends, cheap models
fill the middle**: spend **opus** on the two judgment moments — variant/strategy
selection (step 3 setup) and differential-oracle triage (step 5) — and run mining,
annotation, indexing, generation loops, execution, and crash-detection on
**sonnet/haiku**. Steps 3–5 are parallel per fuzz target: fan out one sonnet
executor per fuzz target, funnel only the differential-divergence cases into one
opus triage lane. (Orchestration tier ≠ generation-model choice — those are set
independently.)

## Fast path (what to actually do)

1. **Mine** the target's bug history with `gh` (one-liners in `pipeline.md`). Keep
   snippets that pass a syntax check and are ≤256 tokens; concatenate code blocks
   per issue; keep the issue/PR title.
2. **Annotate** each snippet with its buggy fuzz target via the 6-shot self-training
   prompt (Figure 3 template in `pipeline.md`). Imprecise labels are fine — they only
   steer the model toward a fuzz target, the bug may surface elsewhere.
3. **Generate** with **few-shot (FuzzGPT-FS) as the default** — it had the highest
   fuzz-target + valid-program counts in the paper. Use the CoT template (predict a
   `Bug description:` first, *then* code). Zero-shot when you want to reuse real
   partial programs verbatim; retrieval (RT) when you want target-specialized
   generation without training — index the corpus once, retrieve K=6 on-target
   examples at generation time (see `references/retrieval.md`). Templates + formulas
   in `prompt-templates.md`.
4. **Execute & apply oracles** (`oracles.md`). Crashes are the cheapest signal;
   differential oracles (CPU/GPU, AD) catch silent wrong-computation bugs.
5. **Measure** against the paper's targets if reproducing (`evaluation.md`).

## Three generation variants (one-line each — full templates in `prompt-templates.md`)

- **Few-shot (FS, default):** prepend K=6 `(fuzz target, Bug description, code)`
  examples, then the target query. CoT: model writes the bug description, then the code.
- **Zero-shot (ZS):** no examples. *Completion* (default) = give a real snippet
  with its suffix randomly truncated + comment `# The following code reveals a bug
  in {fuzz_target}`, let the model finish it. *Editing* = give a full snippet +
  comment `# Edit the code to use {fuzz_target}`.
- **Retrieval (RT):** embed the annotated corpus once, retrieve the K=6 most
  relevant triples for the target unit at generation time, feed them into the FS CoT
  template (Mode A) or a single snippet into the ZS completion path (Mode B). No
  GPU training; runs on any generator. Full methodology in `references/retrieval.md`.

## Generalizing the pipeline to a new target

The method is target-agnostic. To retarget: point the crawler at the new target's
issue tracker, set the fuzz target to your domain's unit (see the mapping table
above — compiler flag, SQL feature, SMT theory, syscall, format field, …), and
swap the oracles (crash always applies; replace the CPU/GPU + AD differentials
with a target-appropriate differential or metamorphic oracle — see `oracles.md`).
Everything else — mining, self-training annotation, the 3 variants — carries over
unchanged.

## No-history fallback (ChatGPT instruct variant, paper §7)

If the target has no usable bug history, directly instruct an instruct-following
model: system = `You are a {target} fuzzer.`, then ask it to generate a program
using `{fuzz_target}` *"in a way you have not seen in your training dataset"* /
*"in a very creative way"* / *"in a non-conventional way"*. Lower valid rate but
broad fuzz-target coverage. This is the weakest variant — prefer history when available.
