---
name: ml-inference-optimization
description: >
  Use when quantizing LLMs (AWQ, GPTQ, GGUF, bitsandbytes, HQQ, FP8),
  optimizing attention kernels or PyTorch training recipes (FlashAttention,
  SDPA, torch.compile, Muon/AdamW, MFU), or deploying high-throughput inference
  servers (vLLM, SGLang, TensorRT-LLM, llama.cpp). Triggers on 'AWQ', 'GPTQ',
  'GGUF', 'bitsandbytes', 'HQQ', 'FlashAttention', 'vLLM', 'SGLang',
  'TensorRT-LLM', 'llama.cpp', 'PagedAttention', 'RadixAttention', 'quantize',
  'serve LLM'.
---

# ML Inference & Optimization

Two reference guides covering quantization/kernels and inference serving. Open
only the reference the task needs; do not preload all.

| Task / Tool | Read |
|---|---|
| Quantization (AWQ, GPTQ, GGUF, bitsandbytes, HQQ), FlashAttention / SDPA, PyTorch training & kernel recipes | [Quantization & kernels](references/quantization-kernels.md) |
| Production or local serving (vLLM, SGLang, TensorRT-LLM, llama.cpp), continuous batching, prefix caching, OpenAI endpoints | [Inference serving](references/inference-serving.md) |

## What each covers

- **Quantization & kernels** — bit-width and method selection, VRAM estimation
  formulas, calibration vs calibration-free workflows, kernel backend
  compatibility (Marlin, ExLlamaV2, TorchAO, FlashAttention-2/3), and
  battle-tested PyTorch mixed-precision/optimizer recipes.
- **Inference serving** — engine selection matrix, OpenAI-compatible server
  launch flags, PagedAttention and RadixAttention prefix caching, FP8/INT4
  serving, GGUF CPU/Metal offload, and Prometheus/latency troubleshooting.

## Universal rules

- Check GPU compute capability and VRAM budget before choosing a format or
  backend: Marlin and `bf16` require Ampere+ (CC >= 8.0), FlashAttention
  requires Turing+ (CC >= 7.5, no V100 or CPU), and FP8 requires Hopper (H100).
- Match quantization to workload: use `Q4_K_M` GGUF (with `imatrix` at Q4 and
  below) for CPU/Apple Silicon, `AWQ`/`GPTQ`/`FP8` for GPU serving, and
  `bitsandbytes` NF4 or `HQQ` when zero-calibration or QLoRA is needed.
- Note deprecations and incompatibilities: `autoawq` is deprecated for new
  projects (prefer `llm-compressor` or `mlx-lm`), AWQ fused modules cannot
  combine with `flash_attention_2`, and GPTQ `desc_act=True` disables Marlin.
- Always verify generation quality (perplexity or sanity-check prompts) and
  actual `nvidia-smi` / `torch.cuda.memory_allocated()` after quantizing or
  changing serving flags; never assume a config fits or preserves accuracy.
- Ensure `--tensor-parallel-size` is a power of 2 in vLLM and use forward
  slashes in all file paths.
