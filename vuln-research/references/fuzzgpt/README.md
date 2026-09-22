# FuzzGPT reference set (preserved verbatim)

The 7 docs in this directory are the **preserved, verbatim** FuzzGPT reference
set — the depth layer behind the `fuzzgpt_history_lane` (Phase 1.4). They are
copied unchanged from the upstream `fuzzgpt` skill so the paper's exact templates,
formulas, hyperparameters, and reproduction tables stay faithful.

**Source / attribution.** FuzzGPT-derived: Deng et al., *Large Language Models
are Edge-Case Fuzzers: Testing Deep Learning Libraries via FuzzGPT*,
[arXiv:2304.02014](https://arxiv.org/abs/2304.02014). The paper's FS (few-shot)
and ZS (zero-shot) variants are reproduced faithfully; **fine-tuning (FT) is
replaced by an embedding-retrieval pathway (RT)** — see `retrieval.md`. Upstream
skill marketplace origin: `Lu1sDV/skillsmd`.

**House-style entry points (read these first):**
- `references/v2/fuzzgpt-history-lane.md` — the v2 doctrine entry (lane identity vs
  `llm_seed_corpus_lane` / `boundary_fuzz_lane`, both modes, the differential
  `N/A`+`unconfirmed` quarantine/promotion flow, recording contracts, gates).
- `references/methodology/fuzzgpt-history-driven-lane.md` — the operational lane
  methodology (mine → annotate → generate → execute → oracle/quarantine).

Then pull the specific depth doc below for the step you are on. **Do not load all
7 at once** — load only the one the active step needs.

## On "API" / "fuzz target" in these docs

Everywhere these references say **"API,"** read **"fuzz target"** in fuzzgpt's
sense: the **unit generation is steered toward** — an API in the paper's DL study,
but equally a compiler flag, SQL feature, SMT theory, syscall, opcode, or protocol
field. The empirical tables in `evaluation.md` keep "API" verbatim because they
report the paper's actual PyTorch/TensorFlow numbers, where the fuzz target happens
to be an API. This is **distinct** from the libFuzzer *harness* sense of "fuzz
target" used in `references/v2/fuzzing-lane.md` / `references/methodology/fuzz-harness-craft.md`.

## Index

| Doc | Load when |
|-----|-----------|
| `pipeline.md` | Building the dataset — `gh` mining, cleaning rules, the 6-shot self-training buggy-fuzz-target labeler (Figure 3). |
| `prompt-templates.md` | Constructing prompts / generating programs — the FS (CoT, default) and ZS (completion/editing) templates + probability formulas. |
| `retrieval.md` | Using the RT (embedding-retrieval) pathway instead of fine-tuning — components, Mode A/B, hyperparameters, and the `build_index`/`select_examples` reference code ported into `engines/fuzzgpt-retrieval/`. |
| `hyperparameters.md` | Setting temps/K/budgets, picking a model — paper-exact values (temp 0.8, top-p 0.95, max_token 256, K=6, 100 progs/fuzz target) + the modern model mapping (Codex retired). |
| `oracles.md` | Detecting bugs from generated programs — crash (always applies) + the differential/metamorphic oracle table (the target-agnostic generalization of CPU/GPU + autodiff). |
| `evaluation.md` | Reproducing the study / validating a re-implementation — RQ1–4, baselines, metrics, the paper's exact result tables, and the RT validation protocol. |
| `orchestration.md` | Running this as a Claude Code multi-agent workflow — per-step subagent tier routing, the two opus-worthy judgment moments, the parallel per-fuzz-target fan-out. |
