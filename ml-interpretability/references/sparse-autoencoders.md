# Sparse Autoencoders with SAELens

Reference for loading, training, analyzing, and steering with Sparse Autoencoders (SAEs) using **SAELens** (`sae-lens>=6.0.0`, `transformer-lens>=2.0.0`, Python 3.10+).

Install: `pip install sae-lens`.

## Core Concept

SAEs decompose polysemantic model activations (`d_model`) into a wider, sparse dictionary of monosemantic features (`d_sae >> d_model`):

- **Objective**: `MSE(original, reconstructed) + l1_coefficient * L1(features)` (or TopK / JumpReLU sparsity).
- **Architectures**: `standard` (ReLU + L1), `gated`, `jumprelu`, `topk` (fixed `k` active features).

---

## 1. Loading & Running Pre-trained SAEs

```python
from transformer_lens import HookedTransformer
from sae_lens import SAE

model = HookedTransformer.from_pretrained("gpt2-small", device="cuda")
sae, cfg_dict, sparsity = SAE.from_pretrained(
    release="gpt2-small-res-jb",       # or HF repo "username/repo-name"
    sae_id="blocks.8.hook_resid_pre",
    device="cuda",
)
# Or from local disk:
# sae = SAE.load_from_disk("/path/to/sae", device="cuda")

tokens = model.to_tokens("The capital of France is Paris")
_, cache = model.run_with_cache(tokens)
activations = cache["resid_pre", 8]      # [batch, pos, d_in]

features = sae.encode(activations)       # [batch, pos, d_sae]
reconstructed = sae.decode(features)     # [batch, pos, d_in]
```

Key `SAE` attributes: `W_enc` `[d_in, d_sae]`, `W_dec` `[d_sae, d_in]`, `b_enc` `[d_sae]`, `b_dec` `[d_in]`, `cfg` (`d_in`, `d_sae`, `hook_name`, `architecture`).

Common pre-trained releases: `gpt2-small-res-jb` (GPT-2 Small residual streams), `gemma-2b-res` (Gemma 2B), or search HuggingFace for tag `saelens`. Browse labeled features on [neuronpedia.org](https://neuronpedia.org) (e.g. `neuronpedia.org/gpt2-small/8-res-jb/1234`).

---

## 2. Training a Custom SAE

```python
from sae_lens import LanguageModelSAERunnerConfig, SAETrainingRunner

cfg = LanguageModelSAERunnerConfig(
    # Model & hook
    model_name="gpt2-small",
    hook_name="blocks.8.hook_resid_pre",
    hook_layer=8,
    d_in=768,

    # Architecture
    architecture="standard",  # "standard", "gated", "jumprelu", "topk"
    d_sae=768 * 8,            # 4x-16x d_model
    activation_fn="relu",     # or "topk" with activation_fn_kwargs={"k": 50}

    # Optimization & sparsity
    lr=4e-4,
    l1_coefficient=8e-5,
    l1_warm_up_steps=1000,
    use_ghost_grads=True,

    # Data & batching
    dataset_path="monology/pile-uncopyrighted",
    streaming=True,
    context_size=128,
    train_batch_size_tokens=4096,
    store_batch_size_prompts=16,
    n_batches_in_buffer=64,
    training_tokens=100_000_000,

    # Logging & checkpoints
    log_to_wandb=True,
    wandb_project="sae-training",
    checkpoint_path="checkpoints",
    n_checkpoints=5,
)

trainer = SAETrainingRunner(cfg)
sae = trainer.run()
```

### Target Evaluation Metrics

| Metric | Target | Meaning |
|---|---|---|
| `L0` | 50–200 | Average active features per token |
| `CE Loss Score` | 80–95% | Cross-entropy loss recovered vs. unpatched model |
| `Dead Features` | <5% | Features that never activate over evaluation window |
| `Explained Variance` | >90% | Reconstruction fidelity |

---

## 3. Feature Attribution, Steering & Ablation

### Direct Logit Attribution per Feature

```python
tokens = model.to_tokens("The capital of France is")
_, cache = model.run_with_cache(tokens)
features = sae.encode(cache["resid_pre", 8])[0, -1]  # [d_sae]

paris_id = model.to_single_token(" Paris")
# feature_activation * decoder_direction . unembedding_col
contribs = features * (sae.W_dec @ model.W_U[:, paris_id])
top_features = contribs.topk(10)
```

### Feature Steering & Ablation via Hooks

```python
feature_dir = sae.W_dec[feature_idx]  # [d_model]

def steering_hook(activation, hook):
    activation += strength * feature_dir  # positive to steer, negative/zero-clamp to ablate
    return activation

output = model.generate(
    tokens,
    max_new_tokens=50,
    fwd_hooks=[(sae.cfg.hook_name, steering_hook)],
)
```

For integrated multi-SAE forward passes and caching, SAELens also provides `HookedSAETransformer` and `ActivationsStore`.

---

## 4. Common Issues & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| High dead feature ratio (>5%) | L1 penalty too strong at start | Set `l1_warm_up_steps=1000` (500–2000) and `use_ghost_grads=True` |
| Poor reconstruction / low CE recovery | Over-regularized or under-parameterized | Lower `l1_coefficient` (e.g. `5e-5`) or increase `d_sae` (`16 * d_in`) |
| Polysemantic / uninterpretable features | Sparsity too low | Increase `l1_coefficient` (`1e-4`) or switch to `architecture="topk"`, `activation_fn="topk"`, `activation_fn_kwargs={"k": 50}` |
| CUDA OOM during training | Activation buffer too large | Reduce `train_batch_size_tokens` (`2048`), `store_batch_size_prompts` (`4`), and `n_batches_in_buffer` (`8`) |
