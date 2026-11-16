# Quantization, Attention Kernels & Training Optimization

Consolidated reference for **AWQ**, **GPTQ**, **GGUF**, **bitsandbytes**, **HQQ**, **FlashAttention**, and **PyTorch training/kernel recipes**.

---

## 1. Quantization Method & Bit-Width Selection

| Method | Precision | Calibration | Speedup vs FP16 | Accuracy Loss | Best For | Serving Support |
|---|---|---|---|---|---|---|
| **AWQ** | 4-bit | Minimal (128–1K tokens) | ~2.5–3x | <5% (<1% on 70B) | Production GPU serving, instruction/chat models | vLLM, TensorRT-LLM, Transformers |
| **GPTQ** | 3–4-bit | Required (e.g. C4/WikiText) | ~2–4x | ~1–2% (4-bit) | Wide ecosystem, ExLlamaV2, consumer GPUs | vLLM, TensorRT-LLM, Transformers |
| **GGUF** | 2–8-bit (K-quants) | Optional (`imatrix`) | 4–10x on CPU | Varies by Q-level | CPU, Apple Silicon (Metal), hybrid offload | llama.cpp, Ollama, LM Studio |
| **bitsandbytes** | 8-bit / NF4 / FP4 | None (on-the-fly) | ~1.5x (memory focus) | <0.5% (8-bit), 1–2% (NF4) | QLoRA fine-tuning, zero-setup Transformers | Transformers, PEFT |
| **HQQ** | 1–8-bit | None (calibration-free) | Backend-dependent | Low at 4-bit | Fast quantization, mixed-precision, 2–3-bit R&D | vLLM, Transformers, PEFT |
| **FP8** | 8-bit float | Minimal / dynamic | ~2x on Hopper | <0.5% | H100/H800 production serving | vLLM, TensorRT-LLM, SGLang, FA-3 |

### Memory Estimation Formulas

```text
FP16 weight memory (GB) = Parameters * 2 / 1e9      # 7B -> ~14 GB
INT8 weight memory (GB) = Parameters * 1 / 1e9      # 7B -> ~7 GB
INT4 weight memory (GB) = Parameters * 0.5 / 1e9    # 7B -> ~3.5 GB
AdamW optimizer (FP32)  = Parameters * 8 bytes      # 7B -> ~56 GB
8-bit AdamW optimizer   = Parameters * 2 bytes      # 7B -> ~14 GB (75% savings)
```

---

## 2. AWQ (Activation-aware Weight Quantization)

Protects ~1% of salient weights identified from activation magnitudes without mixed-precision overhead.

> **Deprecation note**: `autoawq` is officially deprecated. For new projects, prefer `vllm-project/llm-compressor` (NVIDIA/vLLM) or `mlx-lm` (Apple Silicon). Existing AWQ checkpoints remain supported in vLLM and Transformers.

### Install & Quantize (`autoawq`)

```bash
pip install autoawq            # Triton kernels
pip install autoawq[kernels]   # Optimized CUDA kernels + FlashAttention
```

```python
from awq import AutoAWQForCausalLM
from transformers import AutoTokenizer

model_path = "mistralai/Mistral-7B-Instruct-v0.2"
model = AutoAWQForCausalLM.from_pretrained(model_path)
tokenizer = AutoTokenizer.from_pretrained(model_path)

quant_config = {
    "zero_point": True,
    "q_group_size": 128,   # Recommended default
    "w_bit": 4,
    "version": "GEMM",     # "GEMM" for batch>1, "GEMV" for batch_size=1
}
model.quantize(
    tokenizer,
    quant_config=quant_config,
    calib_data="wikitext",
    max_calib_samples=256,
    max_calib_seq_len=512,
)
model.save_quantized("mistral-7b-awq")
tokenizer.save_pretrained("mistral-7b-awq")
```

### Kernel Backends & Gotchas

| Backend | Hardware / Use Case | Notes |
|---|---|---|
| `GEMM` | Batch inference (default) | Best general throughput |
| `GEMV` | `batch_size=1` decode | ~20% faster single-stream; poor for long context |
| `marlin` | Ampere+ (CC >= 8.0: A100, H100, RTX 40xx) | ~2x faster; configure via `AwqConfig(bits=4, version="marlin")` |
| `exllama` | NVIDIA + AMD ROCm | Faster prefill, AMD GPU support |

- **Gotcha**: `AwqConfig(do_fuse=True, fuse_max_seq_len=512)` fuses attention/MLP for speed, but **cannot** be combined with `flash_attention_2`.
- **OOM during quantization**: Lower `max_calib_samples=64`.

---

## 3. GPTQ (Group-Wise Post-Training Quantization)

Uses approximate second-order (Hessian) information to quantize weights in groups.

### Install & Quantize (`auto-gptq`)

```bash
pip install auto-gptq transformers accelerate
pip install auto-gptq[triton]              # Linux Triton kernels
pip install auto-gptq --no-build-isolation # Build CUDA extensions
```

```python
from transformers import AutoTokenizer
from auto_gptq import AutoGPTQForCausalLM, BaseQuantizeConfig
from datasets import load_dataset

model_name = "meta-llama/Llama-2-7b-chat-hf"
tokenizer = AutoTokenizer.from_pretrained(model_name)

quantize_config = BaseQuantizeConfig(
    bits=4,
    group_size=128,     # 32 (higher accuracy), 128 (default), 256 (faster)
    desc_act=False,     # Must be False for Marlin and fastest CUDA kernels
    damp_percent=0.01,
)

model = AutoGPTQForCausalLM.from_pretrained(model_name, quantize_config=quantize_config)
dataset = load_dataset("c4", split="train", streaming=True)
calib_data = [tokenizer(ex["text"])["input_ids"][:512] for ex in dataset.take(128)]

model.quantize(calib_data)   # Pass use_marlin=True for Marlin format (CC >= 8.0)
model.save_quantized("llama-2-7b-gptq")
tokenizer.save_pretrained("llama-2-7b-gptq")
```

### Backends & PEFT Integration

- **ExLlamaV2** (default): `AutoGPTQForCausalLM.from_quantized(name, device="cuda:0", use_exllama=True, exllama_config={"version": 2})` — 1.5–2x faster than Triton.
- **Marlin** (CC >= 8.0): Requires `desc_act=False`, `group_size=128`; load with `use_marlin=True`.
- **Transformers auto-detection**: `AutoModelForCausalLM.from_pretrained("TheBloke/Llama-2-13B-Chat-GPTQ", device_map="auto")`.
- **QLoRA on GPTQ**: Wrap loaded model with `prepare_model_for_kbit_training(model)` and `get_peft_model(model, lora_config)`.

---

## 4. GGUF (llama.cpp Quantization Format)

Pure C/C++ format for CPU, Apple Silicon (Metal), and hybrid CPU+GPU inference.

### Convert & Quantize

```bash
# 1. Convert HuggingFace checkpoint to FP16 GGUF
python convert_hf_to_gguf.py ./llama-3.1-8b --outfile llama-3.1-8b-f16.gguf --outtype f16

# 2. (Recommended for Q4 and below) Compute importance matrix
./llama-imatrix -m llama-3.1-8b-f16.gguf -f calibration.txt --chunk 512 -o model.imatrix -ngl 35

# 3. Quantize
./llama-quantize --imatrix model.imatrix llama-3.1-8b-f16.gguf llama-3.1-8b-q4_k_m.gguf Q4_K_M
```

### K-Quant Selection Guide

| Type | Avg Bits | 7B Size | Quality | Recommendation |
|---|---|---|---|---|
| `Q2_K` | 2.5 | ~2.8 GB | Low | Extreme memory constraints only; requires `imatrix` |
| `Q3_K_M` | 3.3 | ~3.3 GB | Medium | Fitting 70B+ on limited VRAM/RAM |
| `Q4_K_S` | 4.0 | ~3.8 GB | Med-High | Speed-focused 4-bit |
| **`Q4_K_M`** | 4.5 | ~4.1 GB | High | **Default recommendation** (best size/quality balance) |
| `Q5_K_M` | 5.5 | ~4.8 GB | Very High | Quality-focused |
| `Q6_K` | 6.0 | ~5.5 GB | Excellent | Near-FP16 |
| `Q8_0` | 8.0 | ~7.2 GB | Best | Minimal degradation |

---

## 5. bitsandbytes (Zero-Calibration Quantization & QLoRA)

Requires NVIDIA CC >= 7.0 (Turing+), CUDA 11.1+ (12.0+ recommended), PyTorch 2.0+.

### 8-bit & 4-bit NF4 Configs

```python
import torch
from transformers import AutoModelForCausalLM, BitsAndBytesConfig

# 8-bit (<0.5% accuracy loss, 50% weight memory reduction)
bnb_8bit = BitsAndBytesConfig(
    load_in_8bit=True,
    llm_int8_threshold=6.0,
    llm_int8_has_fp16_weight=False,
)

# 4-bit NF4 with double quantization (75% weight memory reduction)
bnb_4bit = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype=torch.bfloat16,  # or torch.float16 on pre-Ampere
    bnb_4bit_quant_type="nf4",              # NormalFloat4 > FP4
    bnb_4bit_use_double_quant=True,         # Quantizes quantization constants
)

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-13b-hf",
    quantization_config=bnb_4bit,
    device_map="auto",
)
```

### QLoRA & 8-bit Optimizers

```python
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from transformers import Trainer, TrainingArguments

model = prepare_model_for_kbit_training(model)
lora_config = LoraConfig(
    r=16, lora_alpha=32, lora_dropout=0.05, bias="none",
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    task_type="CAUSAL_LM",
)
model = get_peft_model(model, lora_config)

# In TrainingArguments, use 8-bit paged AdamW to cut optimizer state memory by 75%:
training_args = TrainingArguments(
    output_dir="./qlora-out",
    optim="paged_adamw_8bit",
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    learning_rate=2e-4,
    bf16=True,
)
```

- **OOM / slow loading**: Add `max_memory={0: "20GB", "cpu": "30GB"}` and `offload_folder="offload", offload_state_dict=True`.

---

## 6. HQQ (Half-Quadratic Quantization)

Fast, calibration-free quantization supporting 1–8 bit weights and mixed precision.

```bash
pip install hqq
pip install hqq[torchao]   # or hqq[marlin], hqq[bitblas]
```

```python
from transformers import AutoModelForCausalLM, HqqConfig
from hqq.core.quantize import HQQLinear

# Mixed precision: higher precision for attention, aggressive for MLP
config = HqqConfig(
    nbits=4,
    group_size=64,
    dynamic_config={
        "attn": {"nbits": 4, "group_size": 64},
        "mlp": {"nbits": 2, "group_size": 32},
    },
)
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-3.1-8B",
    quantization_config=config,
    device_map="auto",
)

# Set fast inference backend
HQQLinear.set_backend("marlin")  # Options: pytorch, pytorch_compile, aten, torchao_int4, gemlite, bitblas, marlin
```

- **Low-memory quantization**: Use `AutoHQQHFModel.from_pretrained(..., device_map="sequential")` to quantize layer-by-layer without full-model VRAM.
- **vLLM**: `LLM(model="mobiuslabsgmbh/Llama-3.1-8B-HQQ-4bit", quantization="hqq", dtype="float16")`.

---

## 7. FlashAttention & PyTorch SDPA

IO-aware exact attention giving 2–4x speedup and 10–20x attention memory reduction on sequences >512 tokens.

- **Hardware**: NVIDIA Turing+ (CC >= 7.5: T4, A100, H100) or AMD MI200+. **Not supported on V100 (Volta) or CPU.**
- **Dtype**: `float16` or `bfloat16` only (`float32` is not supported by FlashAttention kernels).

### Option A: PyTorch Native SDPA (PyTorch >= 2.2)

```python
import torch
import torch.nn.functional as F

# Shape: [batch, heads, seq_len, head_dim]
with torch.backends.cuda.sdp_kernel(
    enable_flash=True, enable_math=False, enable_mem_efficient=False
):
    out = F.scaled_dot_product_attention(q, k, v, is_causal=True)
```

### Option B: `flash-attn` Library & HuggingFace Transformers

```bash
pip install flash-attn --no-build-isolation
```

```python
from flash_attn import flash_attn_func

# Note shape difference vs SDPA: [batch, seq_len, num_heads, head_dim]
out = flash_attn_func(q, k, v, dropout_p=0.0, causal=True, window_size=(-1, -1))

# H100 FP8 (FlashAttention-3)
out_fp8 = flash_attn_func(
    q.to(torch.float8_e4m3fn),
    k.to(torch.float8_e4m3fn),
    v.to(torch.float8_e4m3fn),
)
```

```python
# HuggingFace Transformers (>=4.36)
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    attn_implementation="flash_attention_2",
    torch_dtype=torch.bfloat16,
    device_map="auto",
)
```

---

## 8. PyTorch Training & Kernel Optimization Recipes

- **Chinchilla scaling**: Compute-optimal pretraining is ~20 tokens per parameter (`FLOPs ≈ 6 * N * D`); avoid >4 data epochs.
- **2025 Default LLM Recipe**:
  - **Precision**: `bf16` on Ampere+ (`torch.amp.autocast("cuda", dtype=torch.bfloat16)`); `torch.set_float32_matmul_precision("high")`.
  - **Allocator**: Set `os.environ["PYTORCH_ALLOC_CONF"] = "expandable_segments:True"` before importing `torch`.
  - **Compilation**: `torch.compile(model, dynamic=False)` (Tensor Core alignment: batch size and hidden dims multiples of 8 for bf16, 64 for A100).
  - **Optimizers**: Hybrid Muon (`lr=0.04, wd=0.2` on 2D weight matrices) + AdamW (`β1=0.9, β2=0.95, eps=1e-10`, `wd=0.0` on embeddings/lm_head/scalars); `clip_grad_norm_(params, 1.0)` (optional for Muon).
  - **LR schedule**: Cosine decay or WSD (Warmup-Stable-Decay); 1–5% warmup, 30–50% warmdown.
  - **Memory & stalls**: `model.zero_grad(set_to_none=True)`; `gc.collect(); gc.freeze(); gc.disable()` after step 0 to avoid ~500ms GC stalls; meta-device init (`with torch.device("meta"): ...`) then `model.to_empty(device="cuda")` for large models.
  - **MFU target**: `achieved_flops / gpu_peak_flops` (>40% good, >50% excellent; peak bf16 TFLOPS: H100 SXM = 989.5, A100 = 312, RTX 4090 = 165).
