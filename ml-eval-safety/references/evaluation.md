# LLM & Code Evaluation Reference

Covers three evaluation harnesses: **lm-evaluation-harness** (general LLM benchmarks), **BigCode Evaluation Harness** (code generation & `pass@k`), and **NeMo Evaluator SDK** (containerized multi-backend evaluation on Docker, Slurm, and cloud).

## Choosing a Harness

| Need | Harness | Entrypoint |
|---|---|---|
| Standard academic LLM benchmarks (MMLU, GSM8K, HellaSwag, ARC, TruthfulQA) | `lm-evaluation-harness` | `lm_eval` |
| Code generation with unit-test execution (`pass@k`), MultiPL-E (18 languages) | `bigcode-evaluation-harness` | `accelerate launch main.py` |
| Containerized multi-harness runs, OpenAI-compatible APIs, Slurm HPC, VLMs, safety | `nemo-evaluator-launcher` | `nemo-evaluator-launcher` |

---

## 1. lm-evaluation-harness (`lm_eval`)

Standard harness for 60+ academic benchmarks (used by the Hugging Face Open LLM Leaderboard).

### Install and List Tasks

```bash
pip install lm-eval
# Optional backends / code eval:
pip install vllm human-eval

lm_eval --tasks list
```

### Core CLI Patterns

**Hugging Face backend (local GPU):**
```bash
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf,dtype=bfloat16 \
  --tasks mmlu,gsm8k,hellaswag,truthfulqa,arc_challenge \
  --num_fewshot 5 \
  --device cuda:0 \
  --batch_size auto \
  --output_path results/eval.json \
  --log_samples
```

**vLLM backend (5-10x faster than HF):**
```bash
lm_eval --model vllm \
  --model_args pretrained=meta-llama/Llama-2-7b-hf,tensor_parallel_size=2,dtype=auto,gpu_memory_utilization=0.8 \
  --tasks mmlu \
  --num_fewshot 5 \
  --batch_size auto \
  --output_path results/vllm-mmlu.json
```

**Quantized or local checkpoint:**
```bash
# 4-bit / 8-bit quantization
lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf,load_in_4bit=True \
  --tasks mmlu --device cuda:0

# Local checkpoint with explicit tokenizer
lm_eval --model hf \
  --model_args pretrained=/path/to/ckpt,tokenizer=/path/to/tokenizer \
  --tasks gsm8k,hellaswag --num_fewshot 0 --batch_size 16
```

**Chat / Instruct models:**
Add `--apply_chat_template` (and optionally `--fewshot_as_multiturn`) when evaluating instruction-tuned/chat models on generative tasks so prompts match the model's expected chat format.

**API models (OpenAI / Anthropic / local OpenAI-compatible):**
- Model types: `openai-completions`, `openai-chat-completions`, `anthropic-completions`, `anthropic-chat`, `local-completions`.
- Note: Chat endpoints without `logprobs` only support `generate_until` tasks (e.g., GSM8K, IFEval), not loglikelihood/multiple-choice tasks.

**Distributed data-parallel HF evaluation:**
```bash
accelerate launch --multi_gpu --num_processes 8 \
  -m lm_eval --model hf \
  --model_args pretrained=meta-llama/Llama-2-7b-hf,dtype=bfloat16 \
  --tasks mmlu,gsm8k,hellaswag \
  --batch_size 16
```

### Key Flags & Gotchas

- `--num_fewshot`: Most papers report 5-shot for MMLU; use `0` only for fast training-progress checks. Always record `num_fewshot` alongside scores.
- `--allow_code_execution`: Required for `humaneval` / `mbpp` (plus `pip install human-eval`).
- **OOM**: Use `--batch_size auto` or `--batch_size 1`, `load_in_8bit=True`, or `device_map=auto,offload_folder=offload`.
- **Score mismatch**: Verify exact task name (`mmlu` vs `mmlu_stem` or `mmlu_direct`), `num_fewshot`, `dtype`, and tokenizer match.

---

## 2. BigCode Evaluation Harness

Functional correctness (`pass@k`) benchmarking for code generation models across 15+ tasks (HumanEval, HumanEval+, MBPP, MBPP+, MultiPL-E 18 languages, APPS, DS-1000, HumanEvalPack, Mercury).

### Install

```bash
git clone https://github.com/bigcode-project/bigcode-evaluation-harness.git
cd bigcode-evaluation-harness
pip install -e .
accelerate config

# List tasks
python -c "from bigcode_eval.tasks import ALL_TASKS; print(ALL_TASKS)"
```

### Standard `pass@k` Evaluation

```bash
accelerate launch main.py \
  --model bigcode/starcoder2-7b \
  --tasks humaneval \
  --max_length_generation 512 \
  --temperature 0.8 \
  --do_sample True \
  --n_samples 200 \
  --batch_size 50 \
  --allow_code_execution \
  --save_generations \
  --metric_output_path results/starcoder2-humaneval.json
```

### Instruction-Tuned Code Models

```bash
accelerate launch main.py \
  --model codellama/CodeLlama-7b-Instruct-hf \
  --tasks instruct-humaneval \
  --instruction_tokens "<s>[INST],</s>,[/INST]" \
  --max_length_generation 512 \
  --allow_code_execution

# HumanEvalPack synthesis
accelerate launch main.py \
  --model codellama/CodeLlama-7b-Instruct-hf \
  --tasks humanevalsynthesize-python,humanevalsynthesize-js \
  --prompt instruct \
  --max_length_generation 512 \
  --allow_code_execution
```

### Safe Two-Stage Execution (Recommended for MultiPL-E / Untrusted Code)

Generate completions on the host GPU without executing code, then evaluate inside Docker:

```bash
# Stage 1: Generate only (host)
accelerate launch main.py \
  --model bigcode/starcoder2-7b \
  --tasks multiple-py,multiple-js,multiple-java,multiple-cpp \
  --max_length_generation 650 \
  --temperature 0.8 \
  --n_samples 50 \
  --batch_size 50 \
  --generation_only \
  --save_generations \
  --save_generations_path generations_multi.json

# Stage 2: Execute tests in Docker
docker pull ghcr.io/bigcode-project/evaluation-harness-multiple
docker run -v $(pwd)/generations_multi.json:/app/generations.json:ro \
  -it ghcr.io/bigcode-project/evaluation-harness-multiple python3 main.py \
  --model bigcode/starcoder2-7b \
  --tasks multiple-py,multiple-js,multiple-java,multiple-cpp \
  --load_generations_path /app/generations.json \
  --allow_code_execution \
  --n_samples 50
```

### Key Arguments & Gotchas

| Flag | Default | Notes |
|---|---|---|
| `--n_samples` | `1` | Use `200` for unbiased `pass@1`/`pass@10`/`pass@100` |
| `--temperature` | `0.2` | `0.2` for low-variance `pass@1`; `0.8` for `pass@10`/`pass@100` |
| `--max_length_generation` | `512` | Prompt + generation tokens; raise to `650+` for longer tasks |
| `--load_in_4bit` / `--load_in_8bit` | `False` | Quantization for OOM; also `--max_memory_per_gpu "20GiB"` |
| `--precision` | `fp32` | Set `bf16` or `fp16` for modern GPUs |
| `--allow_code_execution` | `False` | Required to run generated code against unit tests |

---

## 3. NeMo Evaluator SDK (`nemo-evaluator-launcher`)

Container-first evaluation orchestrator covering 100+ benchmarks across 18+ harnesses (`lm-evaluation-harness`, `simple-evals`, `bigcode-evaluation-harness`, `safety-harness`, `garak`, `vlmevalkit`, `bfcl`, `mtbench`, `livecodebench`, `helm`, `nemo-skills`) on Local Docker, Slurm HPC, or Lepton Cloud.

### Install and Prerequisites

```bash
pip install nemo-evaluator-launcher
export NGC_API_KEY=nvapi-your-key-here
docker login nvcr.io -u '$oauthtoken' -p $NGC_API_KEY
nemo-evaluator-launcher ls tasks
```

Requires Python 3.10-3.13, Docker (for local execution), `NGC_API_KEY` (for NGC containers / NVIDIA Build), and `HF_TOKEN` for gated datasets (e.g., `gpqa_diamond`).

### YAML Configuration & CLI

```yaml
# config.yaml
defaults:
  - execution: local        # local | slurm | lepton
  - deployment: none        # none (external API) | vllm
  - _self_

execution:
  output_dir: ./results

target:
  api_endpoint:
    model_id: meta/llama-3.1-8b-instruct
    url: https://integrate.api.nvidia.com/v1/chat/completions
    api_key_name: NGC_API_KEY   # "" for local vLLM/TRT-LLM without auth

evaluation:
  nemo_evaluator_config:
    config:
      params:
        temperature: 0.0
        parallelism: 4
  tasks:
    - name: ifeval
    - name: gsm8k_cot_instruct
    - name: gpqa_diamond
      env_vars:
        HF_TOKEN: HF_TOKEN
```

**Run, monitor, and export:**
```bash
nemo-evaluator-launcher run --config-dir . --config-name config

# Quick smoke test (10 samples) and overrides
nemo-evaluator-launcher run --config-dir . --config-name config \
  -o target.api_endpoint.model_id=my-model \
  -o target.api_endpoint.url=http://localhost:8000/v1/chat/completions \
  -o +evaluation.nemo_evaluator_config.config.params.limit_samples=10

nemo-evaluator-launcher status <invocation_id>
nemo-evaluator-launcher info <invocation_id>
nemo-evaluator-launcher ls runs
nemo-evaluator-launcher export <invocation_id> --dest mlflow   # or wandb / local --format json
nemo-evaluator-launcher kill <invocation_id>
```

### Slurm HPC Deployment

```yaml
defaults:
  - execution: slurm
  - deployment: vllm
  - _self_

execution:
  hostname: cluster.example.com
  account: my_slurm_account
  partition: gpu
  output_dir: /shared/results
  walltime: "04:00:00"
  nodes: 1
  gpus_per_node: 8

deployment:
  checkpoint_path: /shared/models/llama-3.1-8b
  tensor_parallel_size: 2
  data_parallel_size: 4
  max_model_len: 4096

target:
  api_endpoint:
    model_id: llama-3.1-8b
```

### Safety & VLM Tasks

- **Safety**: `aegis`, `wildguard`, `garak`.
- **Vision-Language (`type: vlm`)**: `ocrbench`, `chartqa`, `mmmu`.

### Python API

```python
from nemo_evaluator.core.evaluate import evaluate
from nemo_evaluator.api.api_dataclasses import (
    EvaluationConfig, EvaluationTarget, ApiEndpoint, EndpointType, ConfigParams
)

eval_config = EvaluationConfig(
    type="mmlu_pro",
    output_dir="./results",
    params=ConfigParams(limit_samples=10, temperature=0.0, max_new_tokens=1024, parallelism=4),
)
target_config = EvaluationTarget(
    api_endpoint=ApiEndpoint(
        model_id="meta/llama-3.1-8b-instruct",
        url="https://integrate.api.nvidia.com/v1/chat/completions",
        type=EndpointType.CHAT,
        api_key="nvapi-your-key-here",
    )
)
result = evaluate(eval_cfg=eval_config, target_cfg=target_config)
```

---

## Reproducibility & Hardware Checklist

- **Pin evaluation settings**: Record `num_fewshot`, `temperature` (`0.0` for deterministic evals), `dtype`, `max_new_tokens`/`max_length_generation`, chat template usage, and exact task names.
- **Approximate VRAM (HF/vLLM)**: 7B ~16 GB (bf16) / 8 GB (8-bit) / 6 GB (4-bit); 13B ~28 GB (bf16) / 14 GB (8-bit); 34B+ requires multi-GPU tensor parallelism or 4-bit quantization.
