# Architecture Scaling: MoE Training and Long-Context Extension

Distilled engineering reference for sparse Mixture of Experts (MoE) training/serving and transformer context window extension.

---

## 1. Mixture of Experts (MoE)

MoE replaces dense FFN layers with multiple expert FFNs and a learned router/gate, activating only `top_k` experts per token (e.g., Mixtral 8x7B: 47B total params, 13B active; DeepSeek-V3: 671B total, 37B active).

### Core Architectures & Routing

| Architecture | Routing | Key Design |
|---|---|---|
| **Switch Transformer** | Top-1 (hard routing) | Simplest sparse routing; auxiliary load-balancing loss |
| **Mixtral 8x7B** | Top-2 (normalized softmax) | 8 experts, 2 active per token; weighted sum of selected expert outputs |
| **DeepSeekMoE (V3)** | Shared + fine-grained routed | Always-on shared experts + top-k routed experts; Multi-Head Latent Attention (MLA) compresses KV cache into a low-rank latent vector; auxiliary-loss-free load balancing via learnable router bias |
| **Expert Choice** | Experts pick top-k tokens | Guarantees uniform load per expert without token dropping |
| **PR-MoE** | Pyramid residual | Varying expert counts across layers (`--num-experts "[128, 64, 32, 16]" --mlp-type residual`) |

### Load Balancing & Stability

Without balancing, routers collapse onto a few experts.

```python
# Standard auxiliary load-balancing loss + router z-loss
expert_counts = torch.bincount(expert_indices.flatten(), minlength=num_experts)
expert_fraction = expert_counts.float() / expert_indices.numel()
gate_probs = torch.softmax(gate_logits, dim=-1).mean(dim=0)

aux_loss = num_experts * (expert_fraction * gate_probs).sum()
z_loss = torch.logsumexp(gate_logits, dim=-1).pow(2).mean()

total_loss = lm_loss + 0.01 * aux_loss + 0.001 * z_loss
```

- **Aux-loss-free balancing (DeepSeek-V3):** Adjusts per-expert bias terms in `F.linear(x, weight, bias)` dynamically instead of adding an auxiliary loss term.
- **Tuning:** If `max_expert_usage / min_expert_usage > 2.0`, raise `moe_loss_coeff` toward `0.1`. If `grad_norm > 10.0`, raise `router_z_loss_coeff` toward `0.01`.

### Capacity Factor & Hyperparameters

```python
expert_capacity = int((seq_len * batch_size / num_experts) * capacity_factor)
```

- **Training capacity factor:** `1.25` (25% buffer; excess tokens dropped unless `--disable-moe-token-dropping`).
- **Evaluation capacity factor:** `2.0` (100% buffer to avoid dropping tokens at eval).
- **Learning rate:** 3–6x lower than an equivalent dense model (e.g., `1e-4` vs `6e-4`), with a 1.5–2x longer cosine decay schedule. Use separate param groups if needed (`non_moe_params` vs `moe_params`).
- **Expert count:** 8–16 for 1B–7B models, 8–64 for 7B–30B, 64–256 for 30B+; avoid 128+ experts on small datasets (overfitting risk).

### DeepSpeed MoE Configuration & CLI

```json
{
  "train_batch_size": 256,
  "gradient_accumulation_steps": 1,
  "fp16": { "enabled": true, "loss_scale": 0, "initial_scale_power": 16 },
  "moe": {
    "enabled": true,
    "num_experts": 128,
    "expert_parallel_size": 8,
    "moe_loss_coeff": 0.01,
    "train_capacity_factor": 1.25,
    "eval_capacity_factor": 2.0,
    "min_capacity": 4,
    "drop_tokens": true,
    "use_residual": false
  },
  "zero_optimization": { "stage": 1 }
}
```

```bash
deepspeed --num_gpus 8 pretrain_moe.py \
  --num-layers 32 --hidden-size 4096 --num-attention-heads 32 \
  --seq-length 2048 --micro-batch-size 2 --global-batch-size 256 \
  --lr 0.0001 --min-lr 0.00001 --lr-decay-style cosine --clip-grad 1.0 \
  --num-experts 8 --moe-expert-parallel-size 4 \
  --moe-loss-coeff 0.01 --moe-train-capacity-factor 1.25 --moe-eval-capacity-factor 2.0 \
  --fp16 --deepspeed --deepspeed_config ds_config_moe.json
```

### MoE Inference Optimization

- **Sparse activation / offloading:** Only load and execute the `top_k` selected experts per token when memory-constrained.
- **Serving:** Use vLLM with expert parallelism and fused MoE kernels; pair with quantized weights (FP8/AWQ/GPTQ) when total expert parameters exceed single-node VRAM.

---

## 2. Long-Context Extension

Extend transformer context windows (32k–128k+ tokens) via positional encoding design or post-pretraining scaling.

### Method Comparison

| Method | Max Context | Fine-tuning Needed | Memory / Speed | Best For |
|---|---|---|---|---|
| **RoPE** | 8k–32k | Pre-training | Moderate | Standard modern LLMs |
| **Position Interpolation (Linear)** | 32k+ | Minimal (~1k steps) | Moderate | Quick extension of RoPE models |
| **Dynamic NTK / RoPE** | 32k+ | Minimal / zero-shot | Moderate | Variable-length inputs |
| **YaRN** | 32k–128k+ | Minimal (~400–1k steps, 10x less data) | Moderate | Extending existing RoPE LLMs to 64k–128k |
| **ALiBi** | Extrapolates well | Full pre-training | -11% memory, +11% speed | Training new models from scratch |

### RoPE & Scaling Formulations

- **RoPE:** Rotates `q, k` pairs by position `m` and frequency `theta_j = base^(-2j/d)` (`base=10000` or higher, e.g., `500000` in newer models).
- **Linear Position Interpolation:** Scales position indices `i -> i / s` so extended positions stay within the pre-trained `[0, L]` range.
- **YaRN (NTK-by-parts + attention temperature):**
  - Splits dimensions into low frequencies (interpolated), high frequencies (extrapolated), and a linear ramp between `beta_slow=1` and `beta_fast=32`.
  - Applies attention temperature scaling: `mscale = 0.1 * ln(scale) + 1.0` (multiplies `cos` and `sin`).
- **ALiBi:** Adds static linear distance bias `-m * |i - j|` directly to attention logits before softmax, where each head has a geometric slope `m`.

### HuggingFace `rope_scaling` Configuration

```python
from transformers import AutoConfig, AutoModelForCausalLM

config = AutoConfig.from_pretrained("mistralai/Mistral-7B-v0.1")

# 1. YaRN (recommended for 8x-16x extension)
config.rope_scaling = {
    "type": "yarn",
    "factor": 8.0,
    "original_max_position_embeddings": 8192,
    "attention_factor": 1.0,
}

# 2. Linear Position Interpolation
config.rope_scaling = {"type": "linear", "factor": 16.0}

# 3. Dynamic NTK scaling
config.rope_scaling = {"type": "dynamic", "factor": 8.0}
```

### Fine-Tuning & Memory Optimization

- **Incremental scaling:** Prefer `8k -> 16k -> 32k -> 64k` over jumping directly to 128k+; rough step budget is `~100 * scaling_factor` steps (400–1000 steps with `lr=2e-5`, `per_device_train_batch_size=1`, `gradient_accumulation_steps=16`).
- **Training data:** Must contain genuine long documents (e.g., PG-19 books, arXiv papers, concatenated repository files) at mixed lengths up to the target window. Short documents do not teach long-range attention.
- **Memory & kernels:**
  ```python
  model = AutoModelForCausalLM.from_pretrained(
      model_id,
      attn_implementation="flash_attention_2",
      torch_dtype=torch.bfloat16,
  )
  model.gradient_checkpointing_enable()
  ```
- **Serving long context (vLLM):** Set `max_model_len=32768` (or target) and `gpu_memory_utilization=0.9` with PagedAttention; use `truncation=False` in tokenizer calls when feeding full documents.
