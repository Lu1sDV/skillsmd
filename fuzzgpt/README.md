# fuzzgpt

A **FuzzGPT-derived**, target-agnostic skill for history-driven LLM fuzzing (Deng
et al., *Large Language Models are Edge-Case Fuzzers: Testing Deep Learning
Libraries via FuzzGPT*, [arXiv:2304.02014](https://arxiv.org/abs/2304.02014)).
**Retrieval replaces fine-tuning** — the paper's FS and ZS variants are reproduced
faithfully; FT is replaced by an embedding-retrieval pathway (RT).

It primes an LLM with a target's own **historical bug-triggering code** to generate
unusual, edge-case inputs — the kind ordinary LLM generation never produces. Built
to pair with the `vuln-research` skill: vuln-research picks *what* to hunt, FuzzGPT
generates inputs that actually hit edge cases.

## What it covers

- **Mining + annotation** — `gh`-based bug-history crawling, cleaning rules, and the
  6-shot self-training buggy-fuzz-target labeler (`references/pipeline.md`).
- **Three generation variants** with exact prompt templates and probability
  formulas — few-shot (default, CoT), zero-shot (completion/editing), retrieval/RT
  (`references/prompt-templates.md`, `references/retrieval.md`).
- **Hyperparameters** preserved verbatim (temp=0.8, top-p=0.95, max_token=256, K=6,
  100 progs per fuzz target) **plus a modern model mapping** since Codex
  `code-davinci-002` is retired (`references/hyperparameters.md`).
- **Oracles** — crash, CPU/GPU differential, autodiff differential, plus
  generalization to compilers/DBs/SMT (`references/oracles.md`).
- **Full evaluation protocol** — RQ1–4, baselines, metrics, and the paper's exact
  result tables as reproduction targets (`references/evaluation.md`).
- **Model routing & orchestration** (operational, not from the paper) — which
  Claude subagent tier runs each pipeline step, the two opus-worthy judgment
  moments, and the parallel per-fuzz-target fan-out pattern (`references/orchestration.md`).

## Install

```bash
cp -r fuzzgpt ~/.claude/skills/
```

Or via the marketplace:

```
/plugin marketplace add Lu1sDV/skillsmd
/plugin install fuzzgpt@Lu1sDV/skillsmd
```

## Usage

Triggers on "FuzzGPT", "fuzz this library/compiler/parser/protocol", "generate
edge-case test programs", "history-driven fuzzing", or when used alongside
`vuln-research` to turn a target's issue history into fresh fuzzing inputs. The
**fuzz target** — the unit you steer generation toward — is an API in the paper's
DL study, but equally a syscall, SQL feature, opcode, or format field.
