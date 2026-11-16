# Model Architectures: LitGPT, TorchTitan, nanoGPT, Mamba, RWKV

Guide to choosing, configuring, and running LLM architectures and pretraining/fine-tuning frameworks.

## Architecture & Framework Decision Matrix

| Tool | Primary Strength | Complexity / Scale | When to Choose |
|---|---|---|---|
| **LitGPT** | Clean single-file implementations of 20+ LLMs | 1-64 GPUs; 160M-70B | Production LoRA/QLoRA fine-tuning, readable code, GGUF/bnb export |
| **TorchTitan** | PyTorch-native 4D parallelism (FSDP2, TP, PP, CP) | 8-512+ GPUs; 8B-405B+ | Large-scale pretraining from scratch on H100/Blackwell with Float8 |
| **nanoGPT** | ~300-line pure PyTorch GPT-2 | CPU to 8 GPUs; <1B | Education, fast architecture hacks, GPT-2 (124M) reproduction |
| **Mamba** | Selective SSM; `O(n)` time, no KV cache | 1-8 GPUs; 130M-2.8B | Long sequences (100K+), 5x faster inference, memory-bound streaming |
| **RWKV** | RNN+Transformer hybrid; `O(1)` inference memory | CPU or GPU; 169M-14B | Infinite-context streaming, constant per-token memory, parallel train + RNN infer |

---

## LitGPT (Lightning AI)

20+ pretrained architectures (Llama, Gemma, Phi, Qwen, Mistral, Mixtral, Falcon) with no heavy abstraction layers.

### Install & Quick Inference

```bash
pip install 'litgpt[extra]'
litgpt download list
litgpt download microsoft/phi-2
```

```python
from litgpt import LLM

llm = LLM.load("microsoft/phi-2")
print(llm.generate("What is the capital of France?", max_new_tokens=50, temperature=0.7))

# Streaming
for token in llm.generate("Explain quantum computing", stream=True):
    print(token, end="", flush=True)
```

### LoRA & Full Fine-Tuning

Dataset format (Alpaca JSON): list of `{"instruction": ..., "input": ..., "output": ...}` objects.

```bash
# LoRA fine-tuning (~8-12GB VRAM for Phi-2, ~16GB for 7B)
litgpt finetune_lora microsoft/phi-2 \
  --data JSON \
  --data.json_path data/my_dataset.json \
  --lora_r 16 \
  --lora_alpha 32 \
  --lora_dropout 0.05 \
  --lora_query true --lora_value true --lora_projection true \
  --train.epochs 3 \
  --train.learning_rate 1e-4 \
  --train.micro_batch_size 4 \
  --train.global_batch_size 32 \
  --out_dir out/phi2-lora

# Merge LoRA adapters into base weights for deployment
litgpt merge_lora out/phi2-lora/final --out_dir out/phi2-merged

# Full fine-tuning (40GB+ VRAM for 7B/8B)
litgpt finetune meta-llama/Meta-Llama-3-8B \
  --data JSON --data.json_path data/my_dataset.json \
  --train.max_steps 1000 --train.learning_rate 2e-5 \
  --train.micro_batch_size 1 --train.global_batch_size 16
```

LoRA rank guide: `r=8` (lightweight, 2-4MB), `r=16` (standard), `r=32` (complex tasks), `r=64` (max capacity).

### Pretraining & Export

```bash
# Tokenize pretraining corpus
python scripts/prepare_dataset.py \
  --source_path data/my_corpus.txt \
  --checkpoint_dir checkpoints/tokenizer \
  --destination_path data/pretrain \
  --split train,val

# Multi-GPU FSDP pretraining
litgpt pretrain \
  --config config/pythia-1b.yaml \
  --data.data_dir data/pretrain \
  --devices 8 \
  --train.max_tokens 100_000_000_000

# Quantize (4-bit NF4 double quantization) or convert to GGUF
litgpt convert_lit_checkpoint out/phi2-lora/final --quantize bnb.nf4-dq
python scripts/convert_lit_checkpoint.py \
  --checkpoint_path out/phi2-lora/final \
  --output_path models/phi2.gguf \
  --model_name microsoft/phi-2
```

### LitGPT Gotchas & Hardware

- **OOM during fine-tuning**: Switch from `litgpt finetune` to `litgpt finetune_lora`, lower `--train.micro_batch_size 1`, and increase `--train.gradient_accumulation_iters`.
- **Slow training**: Flash Attention is automatic on Ampere+ GPUs (A100, RTX 30/40).
- **Model not loading**: Verify `ls checkpoints/` matches the `litgpt download list` ID.
- **VRAM baselines**: Inference (Phi-2) 6GB; LoRA (7B) 16GB; Full fine-tune (7B) 40GB+; Pretrain (1B) 24GB.

---

## TorchTitan (PyTorch Native Distributed Pretraining)

Official PyTorch platform for pretraining Llama 3.1, Llama 4, DeepSeek V3 (MoE), and Qwen 3 from 8 to 512+ GPUs using composable 4D parallelism.

### Install & Setup

```bash
pip install torchtitan
# Or from source with PyTorch nightly for latest features:
# git clone https://github.com/pytorch/torchtitan && cd torchtitan && pip install -r requirements.txt

# Download tokenizer assets
python scripts/download_hf_assets.py \
  --repo_id meta-llama/Llama-3.1-8B \
  --assets tokenizer \
  --hf_token="$HF_TOKEN"
```

### TOML Config & Launch

```toml
# llama3_8b_custom.toml
[job]
dump_folder = "./outputs"
description = "Llama 3.1 8B training"

[model]
name = "llama3"
flavor = "8B"
hf_assets_path = "./assets/hf/Llama-3.1-8B"

[optimizer]
name = "AdamW"
lr = 3e-4

[lr_scheduler]
warmup_steps = 200

[training]
local_batch_size = 2
seq_len = 8192
max_norm = 1.0
steps = 1000
dataset = "c4"

[parallelism]
data_parallel_shard_degree = -1  # -1 = FSDP across all GPUs

[activation_checkpoint]
mode = "selective"               # "full" if OOM
selective_ac_option = "op"

[checkpoint]
enable = true
folder = "checkpoint"
interval = 500
```

```bash
# Single-node 8 GPUs
CONFIG_FILE="./llama3_8b_custom.toml" ./run_train.sh
# Or explicitly:
torchrun --nproc_per_node=8 -m torchtitan.train --job.config_file ./llama3_8b_custom.toml
```

### 4D Parallelism & FSDP2

TorchTitan uses **FSDP2** (`fully_shard` with `DTensor` sharding on dim-0):
- `1D mesh + reshard_after_forward=True` = ZeRO-3 (`FULL_SHARD`).
- `1D mesh + reshard_after_forward=False` = ZeRO-2 (`SHARD_GRAD_OP`).
- `2D mesh` (`data_parallel_replicate_degree > 1`) = HSDP (`HYBRID_SHARD`).
- `model.state_dict()` and `optim.state_dict()` return sharded `DTensor` state dicts with zero communication; clip gradients with `nn.utils.clip_grad_norm_()`.

For 70B (256 GPUs): `data_parallel_shard_degree = 32`, `tensor_parallel_degree = 8`.
For 405B (512 GPUs, 64x8): `data_parallel_shard_degree = 8`, `tensor_parallel_degree = 8`, `pipeline_parallel_degree = 8`, `context_parallel_degree = 1`.

**Pipeline parallelism requires a seed checkpoint first** for consistent initialization across PP stages:
```bash
NGPU=1 CONFIG_FILE=./llama3_405b.toml ./run_train.sh \
  --checkpoint.enable --checkpoint.create_seed_checkpoint \
  --parallelism.data_parallel_shard_degree 1 \
  --parallelism.tensor_parallel_degree 1 \
  --parallelism.pipeline_parallel_degree 1
```

### Float8 Training (H100 / Blackwell MXFP8)

Requires `torchao` (`USE_CPP=0 pip install git+https://github.com/pytorch/ao.git`) and `--compile.enable`:

```toml
[model]
converters = ["quantize.linear.float8"]

[quantize.linear.float8]
enable_fsdp_float8_all_gather = true
precompute_float8_dynamic_scale_for_fsdp = true
filter_fqns = ["attention.wk", "attention.wv", "output", "auto_filter_small_kn"]

[compile]
enable = true
components = ["model", "loss"]
```

- Tensorwise dynamic scaling is stable; `recipe_name = "rowwise"` offers higher accuracy (alpha).
- GEMMs with `K, N > 4096` benefit most; `auto_filter_small_kn` skips small layers where quantization overhead exceeds speedup.

### TorchTitan Gotchas

- **High memory with async TP collectives**: `export TORCH_NCCL_AVOID_RECORD_STREAMS=1`.
- **Resharding checkpoints after topology change**: Convert DCP sharded checkpoint to a single file:
  `python -m torch.distributed.checkpoint.format_utils dcp_to_torch checkpoint/step-1000 checkpoint.pt`.

---

## nanoGPT (Educational / Minimalist GPT-2)

Pure PyTorch GPT implementation (~300 lines in `model.py`, ~300 lines in `train.py`).

### Workflows

```bash
pip install torch numpy transformers datasets tiktoken wandb tqdm

# 1. Character-level Shakespeare (CPU: ~5 min, GPU: ~1 min, <1GB VRAM)
python data/shakespeare_char/prepare.py
python train.py config/train_shakespeare_char.py
python sample.py --out_dir=out-shakespeare-char

# 2. Reproduce GPT-2 124M on OpenWebText (8x A100 ~4 days, ~16GB VRAM/GPU)
python data/openwebtext/prepare.py
torchrun --standalone --nproc_per_node=8 train.py config/train_gpt2.py
python sample.py --out_dir=out
```

Key config knobs:
- `init_from = 'gpt2'` (or `'gpt2-medium'`, `'gpt2-large'`, `'gpt2-xl'`) loads OpenAI weights via `transformers` (use lower `learning_rate = 3e-5` when fine-tuning).
- `compile = True` gives ~2x speedup on PyTorch 2.0+; `dtype = 'bfloat16'` halves memory.
- Custom binary datasets save `np.uint16` token arrays to `train.bin` / `val.bin`.

---

## Mamba (Selective State Space Models)

`O(n)` sequence complexity with no KV cache and ~5x faster inference than Transformers for long sequences.

### Install & Prerequisites

Requires Linux, NVIDIA GPU, PyTorch 1.12+, CUDA 11.6+:
```bash
pip install causal-conv1d>=1.4.0
pip install mamba-ssm --no-build-isolation
# Or combined: pip install "mamba-ssm[causal-conv1d]"
```

### Mamba-1 vs Mamba-2

- **Mamba-1** (`from mamba_ssm import Mamba`): `d_state=16`, `d_conv=4`, `expand=2`.
- **Mamba-2** (`from mamba_ssm import Mamba2`): `d_state=128`, multi-head structure (`headdim=64`, `ngroups=1`), RMSNorm, tensor-parallelism support.

```python
import torch
from transformers import AutoTokenizer
from mamba_ssm.models.mixer_seq_simple import MambaLMHeadModel

# Load pretrained Mamba (use MambaLMHeadModel, NOT AutoModel)
tokenizer = AutoTokenizer.from_pretrained("EleutherAI/gpt-neox-20b")
model = MambaLMHeadModel.from_pretrained("state-spaces/mamba-2.8b", device="cuda", dtype=torch.float16)

input_ids = tokenizer("The future of AI is", return_tensors="pt").input_ids.to("cuda")
output_ids = model.generate(input_ids=input_ids, max_length=200, temperature=0.7, top_p=0.9, repetition_penalty=1.2)
print(tokenizer.decode(output_ids[0]))
```

For custom training, instantiate `MambaLMHeadModel(MambaConfig(d_model=1024, n_layer=24, vocab_size=50277, ssm_cfg=dict(layer="Mamba2", d_state=128, headdim=64, ngroups=1)), device="cuda", dtype=torch.float16)` and call `model.gradient_checkpointing_enable()` if OOM.

VRAM (FP16): 130M (2GB), 370M (4GB), 790M (8GB), 1.4B (14GB), 2.8B (28GB).

---

## RWKV (Receptance Weighted Key Value)

RNN+Transformer hybrid: trains in parallel like GPT, infers sequentially like an RNN with `O(1)` memory per token and no KV cache.

### Install & Dual-Mode Inference

```bash
pip install rwkv pytorch-lightning==1.9.5 deepspeed wandb ninja
```

```python
import os
os.environ["RWKV_JIT_ON"] = "1"
os.environ["RWKV_CUDA_ON"] = "1"  # Enable CUDA kernel for speed

from rwkv.model import RWKV
from rwkv.utils import PIPELINE

model = RWKV(model="/abs/path/to/RWKV-4-Pile-1B5.pth", strategy="cuda fp16")  # or "cpu fp32"
pipeline = PIPELINE(model, "20B_tokenizer.json")

# Parallel (GPT) vs Sequential (RNN) yield identical logits:
out, state = model.forward([187, 510, 1563], None)

# Streaming / infinite-context chunking: ALWAYS pass `state` forward!
state = None
for chunk in token_chunks:
    out, state = model.forward(chunk, state)
```

### RWKV Gotchas & Hardware

- **Lost context bug**: Calling `model.forward(tokens, None)` discards prior state; always thread `state` between calls in RNN mode.
- **Training**: Use `pytorch-lightning` with `precision='bf16'` and `strategy='deepspeed_stage_2'` (or `'deepspeed_stage_3'` if OOM).
- **VRAM (FP16)**: 169M (1GB), 430M (2GB), 1.5B (4GB), 3B (8GB), 7B (16GB), 14B (32GB).
