# Compression, Merging, and Speculative Decoding

Distilled engineering reference for Knowledge Distillation, Model Pruning, Model Merging (`mergekit`), and Speculative Decoding.

---

## 1. Knowledge Distillation

Compress a large teacher (e.g., 70B) into a smaller student (e.g., 7B) using logit matching, reverse KLD, or synthetic response generation. Aim for a 7–13x teacher-to-student ratio (70B -> 1B is usually too large a gap).

### Loss Functions

```python
import torch.nn.functional as F

# 1. Standard Logit Distillation (Forward KLD + Hard CE)
def distillation_loss(student_logits, teacher_logits, labels, temperature=2.0, alpha=0.7):
    hard_loss = F.cross_entropy(
        student_logits.view(-1, student_logits.size(-1)), labels.view(-1)
    )
    soft_targets = F.softmax(teacher_logits / temperature, dim=-1)
    soft_student = F.log_softmax(student_logits / temperature, dim=-1)
    soft_loss = F.kl_div(soft_student, soft_targets, reduction="batchmean") * (temperature ** 2)
    return alpha * soft_loss + (1 - alpha) * hard_loss

# 2. MiniLLM Reverse KLD (better for open-ended text generation)
def reverse_kl_loss(student_logits, teacher_logits, temperature=1.0):
    p_teacher = F.softmax(teacher_logits / temperature, dim=-1)
    log_p_student = F.log_softmax(student_logits / temperature, dim=-1)
    return -(p_teacher * log_p_student).sum(dim=-1).mean() * (temperature ** 2)
```

- **Forward KLD vs Reverse KLD (MiniLLM):** Forward KLD is mode-seeking (student averages over modes, often producing generic text); Reverse KLD is mode-covering and preserves diverse generative outputs.
- **Hyperparameters:** Temperature `T = 2.0–5.0` for standard KD (`T = 1.0` for MiniLLM); `alpha = 0.5–0.7`.
- **Response Distillation:** Generate synthetic outputs from the teacher (`do_sample=True, temperature=0.7`), mix ~70% teacher-generated + 30% real data, and SFT the student. For multi-teacher KD, average teacher logits before KLD.

---

## 2. Model Pruning

Reduce parameter count and memory by 40–60% with minimal accuracy loss, or achieve 2x hardware speedup with N:M sparsity.

### Method Comparison (50% Sparsity on LLaMA-7B)

| Method | Criterion | Accuracy Loss | Hardware Speedup | Retraining |
|---|---|---|---|---|
| **Magnitude** | `\|W\|` | -2.5% | 1.0x (unstructured) | No |
| **Wanda** | `\|W\| * \|\|X\|\|_2` (weight x input activation norm) | -0.8% | 1.0x (unstructured) | No |
| **SparseGPT** | Second-order Hessian (`W^2 / diag(H)`) + layer reconstruction | -0.4% | 1.0x (unstructured) | No |
| **N:M (2:4)** | Keep top-N weights per M consecutive weights | -1.0% | **2.0x** (NVIDIA Sparse Tensor Cores) | No |
| **Structured** | Prune entire heads/neurons/layers | -3.0% | 2.0x | Optional |

### Key Patterns

- **Calibration data:** Wanda and SparseGPT require ~128–1000 calibration samples (e.g., `wikitext-2-raw-v1`) via forward hooks on `nn.Linear` layers; never prune blindly without calibration.
- **Wanda importance:** `importance = W.abs() * act.unsqueeze(0)`, thresholded at `torch.quantile(importance.flatten(), sparsity)`.
- **2:4 N:M sparsity:** Reshape weights into groups of 4, keep top-2 by `abs()`, scatter binary mask, and deploy on NVIDIA Ampere+ GPUs.
- **High sparsity (>50%):** Use iterative prune-and-finetune (`lr=1e-5`, 1–2 epochs per step) or layer-wise schedules (less pruning on early layers, more on late layers), then verify with `lm_eval` on `arc_easy`, `hellaswag`, and `winogrande`.

---

## 3. Model Merging (`mergekit`)

Combine fine-tuned models of the **exact same architecture** without GPU training. Install: `pip install mergekit`. Run: `mergekit-yaml config.yml ./merged-model --cuda`.

### Method Selection

- **SLERP (2 models):** Smooth spherical interpolation; supports layer-filtered `t` (`self_attn` vs `mlp`).
- **Linear (Model Soup, 3+ models):** Weighted parameter average (`sum(weights) = 1.0`).
- **Task Arithmetic:** `merged = base + sum(w_i * (model_i - base))` for combining distinct skills.
- **TIES-Merging:** Sparsifies task vectors (`density`) and resolves sign conflicts across many models.
- **DARE (`dare_ties`):** Randomly drops delta parameters (`density: 0.5`) and rescales remaining weights; set `int8_mask: true` to save RAM.
- **Passthrough / FrankenMoE:** `merge_method: passthrough` with `slices` (`layer_range`) or `merge_method: moe` with `positive_prompts` per expert.

```yaml
# Example: DARE-TIES with base model
merge_method: dare_ties
base_model: mistralai/Mistral-7B-v0.1
models:
  - model: WizardLM/WizardMath-7B-V1.1
    parameters:
      density: 0.5
      weight: 0.6
  - model: teknium/OpenHermes-2.5-Mistral-7B
    parameters:
      density: 0.5
      weight: 0.4
parameters:
  int8_mask: true
dtype: bfloat16
```

### Unsupervised Coefficient Tuning (AdaMMS)

To select `t` or `weight` without labeled eval data (arXiv:2503.23733):
1. Merge across candidate coefficients (e.g., `[0.3, 0.4, 0.5, 0.6, 0.7]`).
2. Generate responses on ~50–200 unlabeled prompts.
3. Score each candidate by average output similarity to its neighbors (`alpha +/- delta`); pick the most consistent region.

---

## 4. Speculative Decoding

Achieve 1.5–3.6x lossless inference speedup by verifying multiple draft tokens in a single target forward pass.

| Method | Speedup | Draft Model | Extra Training | Best For |
|---|---|---|---|---|
| **Draft Model (Assisted)** | 1.5–2.0x | Yes (5–10x smaller) | None | Existing model pairs (e.g., 70B + 7B) |
| **Medusa** | 2.0–3.6x | No (built-in heads) | Heads only (Medusa-1) or joint (Medusa-2) | Dedicated high-throughput deployments |
| **Lookahead Decoding** | 1.5–2.3x | No | None | Plug-and-play, code/structured generation |

### Production Snippets

```python
# 1. HuggingFace Assisted Generation (transformers >= 4.36)
outputs = target_model.generate(
    **inputs,
    assistant_model=draft_model,
    max_new_tokens=256,
    do_sample=True,
    temperature=0.7,
)

# 2. vLLM Speculative Decoding
from vllm import LLM, SamplingParams
llm = LLM(
    model="meta-llama/Llama-2-70b-hf",
    speculative_model="meta-llama/Llama-2-7b-hf",
    num_speculative_tokens=5,
    use_v2_block_manager=True,
)
```

- **Medusa:** Adds 3–4 linear prediction heads on the final hidden state and verifies candidates in parallel with tree-based attention (`posterior_threshold=0.09`, `posterior_alpha=0.3`).
- **Lookahead Decoding:** Uses parallel Jacobi iteration across two branches (lookahead n-gram generation + verification); tune `window_size` (15 for 7B, 10 for 13B, 7 for 33B+) and `ngram_size=5`.
