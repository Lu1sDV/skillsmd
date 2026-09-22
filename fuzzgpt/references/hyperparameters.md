# Hyperparameters, Models & Modern Mapping (FuzzGPT §4, §5.2)

Two columns: **paper-exact** (the canonical reproduction target — preserve these
verbatim) and **modern equivalent** (what to actually run today, since Codex
`code-davinci-002` was retired by OpenAI in 2023).

## Generation hyperparameters (paper-exact — keep these)

| Param | Value | Notes |
|-------|-------|-------|
| Sampling | **top-p, p = 0.95** | Following TitanFuzz |
| `temperature` | **0.8** | For generation |
| `max_token` | **256** | Per generation; also the dataset snippet length cap |
| Programs per fuzz target | **100** | Default fuzzing budget (per API, in the paper) |
| Annotation temperature | **0** | Greedy, for the buggy-fuzz-target self-training labels (most confident) |
| `K` (few-shot examples) | **6** | Sweet spot; K=0 worst, too-large K hurts |
| Ablation sample | **50 PyTorch APIs**, **5 runs averaged** | RQ3 to control cost |

### Per-variant generation budget (how to reach 100 programs per fuzz target)

- **Few-shot:** construct **10 prompts**, each with **6 random examples**; sample
  **10 generations** per prompt → 100.
- **Zero-shot:** randomly choose **10 different examples**; build **10 prompts**
  (completion or editing) → 100.
- **Retrieval (RT):** call `select_examples` 10 times (varied seeds) to get 10
  K=6 subsets from the top-N pool; run **10 generations** per prompt → 100. See
  `references/retrieval.md §Hyperparameters` for RT-specific params (embedding
  model, N=30, K=6, λ=0.5, τ≈0.2).

## Models used in the paper

| Model | Role | Status today |
|-------|------|--------------|
| **Codex `code-davinci-002`** | Main generator + annotator (proprietary, GPT-3-initialized) | **Retired** — not callable |
| **InCoder** | (baseline TitanFuzz's mutator) | — |
| **ChatGPT** / GPT-4 | No-history instruct variant (§7) | Superseded |

Codex was accessed via API. The paper's open-model fine-tuning study (CodeGen 350M /
2B / 6B) is not reproduced here — FT is replaced by the RT pathway.

## Modern model mapping (to make this runnable in 2024+)

Preserve the *settings* above; swap the *model*. Match the original role:

| Paper role | Modern equivalent |
|------------|-------------------|
| Codex generator/annotator (strongest) | Claude (Opus/Sonnet), GPT-4o / GPT-4-class, DeepSeek-V3 |
| ChatGPT no-history instruct (§7) | Any instruct model (proprietary or open) |

Mapping rules:
- **Keep `temperature=0.8`, `top_p=0.95`, `max_tokens=256`, `K=6`, 100 progs per
  fuzz target** unchanged — they're the reproducible contract, model-independent.
- **Annotation still uses `temperature=0`** (greedy) on whatever generator you pick.
- If using an API model with no logprob/greedy control, set the lowest available
  temperature for annotation and accept minor label drift (labels need not be
  precise anyway — see `pipeline.md`).

## Reproduction environment (paper §5.2)

64-core workstation, 256 GB RAM, Ubuntu 20.04.5 LTS, **4× NVIDIA RTX A6000** GPUs.
Subject versions for the head-to-head: **PyTorch v1.12, TensorFlow v2.10** (same as
TitanFuzz); new-bug hunting was run on the **nightly** builds of both.
