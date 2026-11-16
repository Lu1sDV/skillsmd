---
name: ml-interpretability
description: >
  Mechanistic interpretability for neural networks: activation caching, hook
  points, causal tracing, activation patching, interchange interventions (DAS/IIT),
  and sparse autoencoders (SAEs). Covers TransformerLens, nnsight (including
  NDIF remote execution), pyvene, and SAELens. Triggers on 'TransformerLens',
  'HookedTransformer', 'nnsight', 'NDIF', 'pyvene', 'SAELens', 'activation
  patching', 'causal tracing', 'circuit analysis', 'sparse autoencoder',
  'feature steering', or 'mechanistic interpretability'.
---

# ML Interpretability

Two reference modules. Open only the reference the task needs; do not preload all.

| Task / Tool | Read |
|---|---|
| Activation caching, hooks, logit attribution, causal tracing, patching, or DAS/IIT (`TransformerLens`, `nnsight`, `pyvene`) | [Hooks and patching reference](references/hooks-and-patching.md) |
| Loading/training sparse autoencoders, feature attribution, steering, or Neuronpedia lookup (`SAELens`) | [Sparse autoencoders reference](references/sparse-autoencoders.md) |

## What each covers

- **Hooks and patching** — tool selection matrix plus practical APIs for `HookedTransformer` (`run_with_cache`, `run_with_hooks`, direct logit attribution, induction heads), `nnsight` (`LanguageModel`, `trace` context, `.save()`, `tracer.invoke()`, `remote=True` on NDIF, local gradients), and `pyvene` (`IntervenableModel`, `IntervenableConfig`, ROME causal tracing, `RotatedSpaceIntervention` / DAS, HF Hub sharing).
- **Sparse autoencoders** — `SAELens` workflows for loading pre-trained SAEs (`SAE.from_pretrained`), training custom SAEs (`LanguageModelSAERunnerConfig`, `SAETrainingRunner`, TopK/Gated/JumpReLU/Standard), target metrics (`L0`, CE loss recovered, dead feature ratio), feature logit attribution, steering/ablation hooks, and troubleshooting.

## Universal rules

- **Verify tokenization before computing metrics**: multi-character words often split into multiple tokens; inspect with `model.to_str_tokens(...)` and validate single-token targets with `model.to_single_token(...)` before slicing logits.
- **Prevent hook and state leaks**: call `model.reset_hooks()` in TransformerLens after debugging or failed runs; in `nnsight`, explicitly call `.save()` on every proxy tensor needed outside the `with model.trace(...)` block.
- **Budget VRAM before activation sweeps**: filter cached hooks with `names_filter` and pass `device="cpu"` in `run_with_cache`, or save only target layers in `nnsight`, before running full `(layer, pos)` patching grids.
- **Account for LayerNorm and architecture paths**: apply LayerNorm before projecting residual states unless `fold_ln=True` covers that site; inspect `model._model` in `nnsight` (e.g. `transformer.h` vs. `model.layers`) and exact `pyvene` component names before writing interventions.
- **Check remote and gradient constraints**: `nnsight` `remote=True` requires `NDIF_API_KEY` (`CONFIG.API_KEY`) and does not support `.backward()` / `retain_grad()` (nor does vLLM).
- **Use forward slashes in all paths** (e.g. `references/hooks-and-patching.md`).
