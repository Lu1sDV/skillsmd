# Hooks, Caching, and Causal Patching

Reference for inspecting and intervening on model internals with **TransformerLens**, **nnsight**, and **pyvene**.

## Choosing a Tool

| Need | Best Tool | Why |
|---|---|---|
| Consistent hook API across GPT/LLaMA/Pythia/Mistral, logit lens, circuit analysis | **TransformerLens** | Standardized `HookedTransformer` names (`resid_post`, `pattern`), `ActivationCache` |
| Massive models (70B–405B) via NDIF remote execution, or any custom `nn.Module` | **nnsight** | Native HuggingFace module paths, `remote=True`, deferred proxy graph |
| Declarative/shareable interventions, ROME causal tracing, DAS / IIT training | **pyvene** | Config-driven `IntervenableModel`, trainable `RotatedSpaceIntervention`, HF Hub sharing |

---

## 1. TransformerLens

Install: `pip install transformer-lens` (requires `torch>=2.0.0`).

### Loading Models

```python
import os
import torch
from transformer_lens import HookedTransformer

model = HookedTransformer.from_pretrained("gpt2-small")

# With explicit device/dtype or gated models (LLaMA, Mistral)
os.environ["HF_TOKEN"] = "your_token"
model = HookedTransformer.from_pretrained(
    "meta-llama/Llama-2-7b-hf",
    device="cuda",
    dtype=torch.float16,
)
```

Key `from_pretrained()` parameters:
- `fold_ln` (bool, default `True`): folds LayerNorm weights into subsequent linear layers.
- `center_writing_weights` / `center_unembed` (bool, default `True`): centers residual-writing and unembedding weights.
- `n_devices` (int, default `1`): split across multiple GPUs.

Weight matrices exposed on `model`: `W_E` `[d_vocab, d_model]`, `W_U` `[d_model, d_vocab]`, `W_pos` `[n_ctx, d_model]`, `W_Q/K/V` `[n_layers, n_heads, d_model, d_head]`, `W_O` `[n_layers, n_heads, d_head, d_model]`, `W_in` `[n_layers, d_model, d_mlp]`, `W_out` `[n_layers, d_mlp, d_model]`.

### Activation Caching & Keys

```python
tokens = model.to_tokens("The Eiffel Tower is in")
logits, cache = model.run_with_cache(
    tokens,
    names_filter=lambda name: "resid_post" in name or "pattern" in name,
    device="cpu",  # offload cache to CPU for large models
)

residual = cache["resid_post", 5]   # [batch, pos, d_model]
attn_pat = cache["pattern", 3]      # [batch, head, q_pos, k_pos]
```

Common `ActivationCache` keys:
- `resid_pre, layer` / `resid_mid, layer` / `resid_post, layer`: `[batch, pos, d_model]`
- `attn_out, layer` / `mlp_out, layer`: `[batch, pos, d_model]`
- `pattern, layer`: `[batch, head, q_pos, k_pos]` (post-softmax)
- `q, layer` / `k, layer` / `v, layer` / `z, layer`: `[batch, pos, head, d_head]`

### Activation Patching (Causal Tracing)

```python
clean_tokens = model.to_tokens("The Eiffel Tower is in the city of")
corrupted_tokens = model.to_tokens("The Colosseum is in the city of")
_, clean_cache = model.run_with_cache(clean_tokens)

paris_id = model.to_single_token(" Paris")
rome_id = model.to_single_token(" Rome")
metric = lambda logits: logits[0, -1, paris_id] - logits[0, -1, rome_id]

results = torch.zeros(model.cfg.n_layers, clean_tokens.shape[1])
for layer in range(model.cfg.n_layers):
    for pos in range(clean_tokens.shape[1]):
        def patch_hook(activation, hook, pos=pos):
            activation[0, pos] = clean_cache[hook.name][0, pos]
            return activation

        patched_logits = model.run_with_hooks(
            corrupted_tokens,
            fwd_hooks=[(f"blocks.{layer}.hook_resid_post", patch_hook)],
        )
        results[layer, pos] = metric(patched_logits)
```

### Direct Logit Attribution & Induction Heads

```python
# Head contribution to IO - S logit diff at final position
head_out = cache["z", layer][0, :, head, :]          # [pos, d_head]
contrib = head_out[-1] @ model.W_O[layer, head] @ model.W_U
head_score = contrib[john_token] - contrib[mary_token]

# Induction head detection on repeated sequence [A][B][A]
repeated = torch.tensor([[1000, 2000, 1000]])
_, cache = model.run_with_cache(repeated)
for layer in range(model.cfg.n_layers):
    # Attention from pos 2 ([A]) back to pos 1 ([B])
    scores = cache["pattern", layer][0, :, 2, 1]
```

### TransformerLens Gotchas

- **Persisting hooks**: call `model.reset_hooks()` after debugging or failed runs, otherwise old hooks stay attached.
- **Tokenization assumptions**: `"Neel"` tokenizes into `['Ne', 'el']`. Always verify with `model.to_str_tokens(text)` and `model.to_single_token(tok)`.
- **LayerNorm in weight projections**: apply `model.blocks[layer].ln2(residual)` before `@ model.W_in[layer]` unless `fold_ln=True` already absorbed it for that site.

---

## 2. nnsight

Install: `pip install nnsight` (or `pip install "nnsight[vllm]"`). For remote NDIF execution, obtain an API key at `login.ndif.us` and set `NDIF_API_KEY` or `nnsight.CONFIG.API_KEY`.

### Tracing Context & Proxy Objects

`model.trace(...)` builds a deferred computation graph; module accesses return `Proxy` objects. Call `.save()` on any tensor needed outside the context.

```python
import torch
from nnsight import LanguageModel

model = LanguageModel("openai-community/gpt2", device_map="auto")

with model.trace("The Eiffel Tower is in") as tracer:
    hidden = model.transformer.h[5].output[0].save()
    attn = model.transformer.h[5].attn.attn_dropout.input[0][0].save()
    model.transformer.h[8].output[0][:] = 0  # zero out layer 8 in-place
    logits = model.output.save()

print(hidden.shape, logits.shape)
```

### Activation Patching & Cross-Prompt Sharing

Use `tracer.invoke(...)` to share activations across prompts in a single trace:

```python
with model.trace() as tracer:
    with tracer.invoke("The Eiffel Tower is in"):
        clean_h8 = model.transformer.h[8].output[0].save()

    with tracer.invoke("The Colosseum is in"):
        model.transformer.h[8].output[0][:] = clean_h8
        patched_logits = model.output.save()
```

### Remote Execution (NDIF) & Generation Interventions

Toggle `remote=True` to run the same code on 70B/405B models hosted on NDIF:

```python
model = LanguageModel("meta-llama/Llama-3.1-70B")

with model.trace("The meaning of life is", remote=True, timeout=300) as tracer:
    layer_40 = model.model.layers[40].output[0].save()
    logits = model.output.save()
```

### Gradient-Based Analysis (Local Only)

```python
with model.trace("The quick brown fox") as tracer:
    hidden = model.transformer.h[5].output[0].save()
    hidden.retain_grad()
    loss = -model.output[0, -1, target_token]
    loss.backward()

grad = hidden.grad
```

### nnsight Gotchas

- **Architecture-specific module paths**: GPT-2 uses `model.transformer.h[i]`, whereas LLaMA uses `model.model.layers[i]`. Inspect `print(model._model)` before writing hooks.
- **Forgetting `.save()`**: unsaved proxies are unavailable after the `with model.trace(...)` block exits.
- **Gradients unavailable remotely/vLLM**: gradient analysis (`retain_grad()`, `backward()`) only works with local standard PyTorch execution.

---

## 3. pyvene

Install: `pip install pyvene`.

### IntervenableModel & Configs

```python
import pyvene as pv
from transformers import AutoModelForCausalLM, AutoTokenizer

model = AutoModelForCausalLM.from_pretrained("gpt2")
tokenizer = AutoTokenizer.from_pretrained("gpt2")

config = pv.IntervenableConfig(
    representations=[
        pv.RepresentationConfig(
            layer=8,
            component="block_output",
            intervention_type=pv.VanillaIntervention,
        )
    ]
)
intervenable = pv.IntervenableModel(config, model)
```

**Intervention types**:
- `VanillaIntervention` (swap activations), `AdditionIntervention` / `SubtractionIntervention` (steering/ablation), `ZeroIntervention` (knockout), `CollectIntervention` (read activations), `RotatedSpaceIntervention` / `LowRankRotatedSpaceIntervention` (trainable DAS), `LoRAIntervention` (`pyvene>=0.1.8`).

**Valid component names**:
`block_input`, `block_output`, `mlp_input`, `mlp_output`, `mlp_activation`, `attention_input`, `attention_output`, `attention_value_output`, `query_output`, `key_output`, `value_output`, `head_attention_value_output`.

### ROME-Style Causal Tracing

```python
clean_toks = tokenizer("The Space Needle is in downtown", return_tensors="pt")
corrupt_toks = tokenizer("The ##### ###### ## ## ########", return_tensors="pt")

config = pv.IntervenableConfig(
    representations=[
        pv.RepresentationConfig(
            layer=layer,
            component="block_output",
            intervention_type=pv.VanillaIntervention,
            unit="pos",
            max_number_of_units=1,
        )
    ]
)
intervenable = pv.IntervenableModel(config, model)
_, patched = intervenable(
    base=corrupt_toks,
    sources=[clean_toks],
    unit_locations={"sources->base": ([[[pos]]], [[[pos]]])},
    output_original_output=True,
)
```

### Interchange Intervention Training (IIT / DAS)

```python
config = pv.IntervenableConfig(
    representations=[
        pv.RepresentationConfig(
            layer=6,
            component="block_output",
            intervention_type=pv.LowRankRotatedSpaceIntervention,
            low_rank_dimension=1,  # 1D causal subspace
        )
    ]
)
intervenable = pv.IntervenableModel(config, model)
optimizer = torch.optim.Adam(intervenable.get_trainable_parameters(), lr=1e-4)
```

### Steering, Saving, and Sharing

```python
# Generate with an active intervention (e.g. Honest LLaMA)
intervenable = pv.IntervenableModel.load("zhengxuanzenwu/intervenable_honest_llama2_chat_7B", model=model)
outputs = intervenable.generate(inputs, max_new_tokens=100, do_sample=False)

# Save/load locally or on HuggingFace Hub
intervenable.save("./my_intervention")
intervenable.save_intervention("username/my-intervention")
```

### pyvene Gotchas

- **Exact component names**: passing `"mlp"` raises an error; use `"mlp_output"` or `"mlp_activation"`.
- **Shape mismatches on `unit_locations`**: when `unit="pos"`, specify `max_number_of_units=1` and match nested list indexing `([[[pos]]], [[[pos]]])` for `sources->base`.
- **Memory**: enable `model.gradient_checkpointing_enable()` or restrict `IntervenableConfig` to a single layer when training DAS/IIT on large models.
