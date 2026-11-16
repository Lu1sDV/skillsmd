---
name: ml-emerging-techniques
description: >
  Use when scaling or compressing LLMs with emerging training and inference
  techniques: Mixture of Experts (MoE) training and expert parallelism (Mixtral,
  DeepSeekMoE, Switch, DeepSpeed), long-context extension (RoPE, YaRN, ALiBi,
  position interpolation, FlashAttention), knowledge distillation (soft targets,
  reverse KLD / MiniLLM, response distillation), model pruning (Wanda, SparseGPT,
  N:M 2:4 sparsity), model merging with mergekit (linear, SLERP, Task Arithmetic,
  TIES, DARE, AdaMMS coefficient tuning), and speculative decoding (draft models,
  Medusa heads, Lookahead decoding, vLLM).
---

# ML Emerging Techniques

Six specialized LLM scaling, compression, and acceleration workflows consolidated
into two focused references. Open only the reference the task needs; do not
preload both.

| Task / Tool | Read |
|---|---|
| MoE training & inference (Mixtral, DeepSeek-V3, Switch, DeepSpeed EP, load balancing) or long-context extension (RoPE, YaRN, ALiBi, position interpolation) | [Architecture scaling reference](references/architecture-scaling.md) |
| Knowledge distillation (MiniLLM, logit/response KD), pruning (Wanda, SparseGPT, N:M), model merging (`mergekit`, SLERP, TIES, DARE), or speculative decoding (draft, Medusa, Lookahead) | [Compression and merging reference](references/compression-and-merging.md) |

## What each covers

- **Architecture scaling** — sparse MoE architectures, top-k / shared-expert /
  auxiliary-loss-free routing, DeepSpeed expert parallelism and capacity factors,
  plus RoPE math, YaRN NTK-by-parts, ALiBi slopes, HuggingFace `rope_scaling`,
  and long-context fine-tuning memory optimization.
- **Compression and merging** — teacher-student distillation (forward vs reverse
  KLD), one-shot and N:M pruning with calibration data, `mergekit` YAML recipes
  and unsupervised coefficient tuning (AdaMMS), and lossless inference speedup
  via draft-model speculative decoding, Medusa, and Lookahead decoding.

## Universal rules

- Check VRAM, interconnect, and architecture compatibility before launching:
  MoE capacity scales with total experts even when active compute is sparse, and
  `mergekit` only merges models with matching architectures.
- Never apply position interpolation or RoPE scaling to an existing model for
  large context jumps without fine-tuning on genuinely long sequences; evaluate
  perplexity across the full target context window.
- Never prune with Wanda or SparseGPT without representative calibration data,
  and always benchmark compressed, distilled, or merged models (e.g., `lm_eval`)
  against the baseline before deployment.
- MoE training requires 3–6x lower learning rates than dense models and explicit
  load-balancing (auxiliary loss + router z-loss or bias-based balancing) to
  prevent expert collapse.
- Use forward slashes in all file and repository paths.
