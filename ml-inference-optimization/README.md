# ml-inference-optimization

Consolidated LLM quantization, attention/training kernel optimization, and
inference serving skill. [SKILL.md](SKILL.md) is a short orchestrator that
routes to two independently readable references, loaded only when the task
needs them:

- [references/quantization-kernels.md](references/quantization-kernels.md) —
  AWQ, GPTQ, GGUF, bitsandbytes, HQQ, FlashAttention / SDPA, and PyTorch
  training/kernel optimization recipes.
- [references/inference-serving.md](references/inference-serving.md) — vLLM,
  SGLang, TensorRT-LLM, and llama.cpp serving, batching, KV/prefix caching,
  and quantization flags.

## Install and use

Copy the complete `ml-inference-optimization/` directory into your agent's
skills directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-inference-optimization ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-inference-optimization@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-inference-optimization
```

Examples:
- "Quantize Llama-3-8B to 4-bit AWQ or GPTQ and serve it with vLLM."
- "Set up SGLang with RadixAttention and JSON schema constrained decoding."
- "Convert a HuggingFace model to Q4_K_M GGUF with imatrix and run llama-server on Apple Silicon."

## Sources and adaptation

Condensed on 2026-11-16 from 11 upstream skills in
[Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)
(MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`; see
[LICENSE.upstream](LICENSE.upstream)):

- `10-optimization/awq/SKILL.md`
- `10-optimization/bitsandbytes/SKILL.md`
- `10-optimization/flash-attention/SKILL.md`
- `10-optimization/gguf/SKILL.md`
- `10-optimization/gptq/SKILL.md`
- `10-optimization/hqq/SKILL.md`
- `10-optimization/ml-training-recipes/SKILL.md`
- `12-inference-serving/llama-cpp/SKILL.md`
- `12-inference-serving/sglang/SKILL.md`
- `12-inference-serving/tensorrt-llm/SKILL.md`
- `12-inference-serving/vllm/SKILL.md`

These references are condensed derivatives, not vendored copies. Overlapping
quantization comparisons and OpenAI-compatible serving boilerplate were
deduplicated into unified decision matrices and engine-specific flag
summaries.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks (`check_static_smells.py`). Runtime GPU/CUDA commands apply
to the consumer's environment and were not executed here.
