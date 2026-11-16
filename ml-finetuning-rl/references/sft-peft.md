# SFT & PEFT Reference (PEFT, Unsloth, Axolotl, LLaMA-Factory)

Distilled guide to supervised fine-tuning (SFT) and parameter-efficient fine-tuning (LoRA, QLoRA, DoRA, LoftQ, rsLoRA, IA3) across Hugging Face PEFT, Unsloth, Axolotl, and LLaMA-Factory.

---

## 1. Framework Selection

| Framework | Interface | Best For | Key Strength |
|---|---|---|---|
| **PEFT** (`peft`) | Python (`transformers` / `trl`) | Custom training loops, multi-adapter serving | Official HF library, 25+ adapter methods |
| **Unsloth** (`unsloth`) | Python (`FastLanguageModel`) | Single-GPU speed & VRAM limits | 2-5x faster, 50-80% less VRAM, QAT schemes |
| **Axolotl** (`axolotl`) | YAML + CLI (`axolotl train`) | Reproducible SFT/DPO/GRPO/FSDP2 runs | 100+ models, sequence/context parallelism, `save_compressed` |
| **LLaMA-Factory** (`llamafactory-cli`) | WebUI (Gradio) + YAML/CLI | No-code/low-code tuning, quick PTQ export | Built-in WebUI, 2/3/4/5/6/8-bit QLoRA, GPTQ/AWQ export |

---

## 2. VRAM Sizing (Llama 3.1 8B & 70B Reference)

| Setup | 8B VRAM | 70B VRAM | Notes |
|---|---|---|---|
| Full fine-tuning (BF16) | 60+ GB | Multi-node | Updates 100% of weights |
| LoRA (`r=16`, BF16) | ~18 GB | ~160+ GB | ~0.17% trainable params (~14M on 8B) |
| QLoRA (`r=16`, 4-bit NF4) | ~6 GB | ~40-48 GB (24 GB w/ `r=64` + grad ckpt) | Nested double quant + `bfloat16` compute |
| IA3 | ~16 GB | — | ~0.01% trainable params (~800K on 8B) |

---

## 3. Hugging Face PEFT (`peft` + `bitsandbytes`)

Install:
```bash
pip install peft transformers accelerate bitsandbytes datasets
```

### Standard LoRA & QLoRA
```python
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
from peft import LoraConfig, TaskType, get_peft_model, prepare_model_for_kbit_training

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype="bfloat16",
    bnb_4bit_use_double_quant=True,
)
model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-3.1-8B",
    quantization_config=bnb_config,   # omit for standard BF16 LoRA
    device_map="auto",
)
model = prepare_model_for_kbit_training(model)  # enables gradient checkpointing for k-bit

lora_config = LoraConfig(
    task_type=TaskType.CAUSAL_LM,
    r=16,                            # 8-16 general, 32-64 complex/70B
    lora_alpha=32,                   # rule of thumb: 2 * r
    lora_dropout=0.05,
    target_modules="all-linear",     # or ["q_proj","k_proj","v_proj","o_proj","gate_proj","up_proj","down_proj"]
    bias="none",
)
model = get_peft_model(model, lora_config)
model.print_trainable_parameters()
```

### Advanced PEFT Variants
- **DoRA** (`use_dora=True` in `LoraConfig`): Decomposes magnitude and direction; ~10% more VRAM, stronger on instruction following.
- **rsLoRA** (`use_rslora=True` in `LoraConfig`): Rank-stabilized scaling; recommended when `r > 32`.
- **LoftQ** (`init_lora_weights="loftq"`, `loftq_config=LoftQConfig(loftq_bits=4, loftq_iter=5)`): Initializes LoRA weights to offset 4-bit quantization error (+1-2% accuracy, faster convergence).
- **AdaLoRA** (`AdaLoraConfig(init_r=64, target_r=16, tinit=200, tfinal=1000, deltaT=10)`): Prunes rank per layer dynamically.
- **IA3** (`IA3Config(target_modules=[...], feedforward_modules=["down_proj"])`): ~0.01% params, fastest few-shot adaptation.

### Merging & Multi-Adapter Serving
```python
from peft import AutoPeftModelForCausalLM

# Load & merge into base weights (no inference overhead)
model = AutoPeftModelForCausalLM.from_pretrained("./lora-adapter", device_map="auto")
merged = model.merge_and_unload()
merged.save_pretrained("./merged-model")

# Multi-adapter runtime switching
model.load_adapter("./adapter-task2", adapter_name="task2")
model.set_adapter("task2")
with model.disable_adapter():
    base_out = model.generate(**inputs)
```

---

## 4. Unsloth (`FastLanguageModel`)

Install:
```bash
pip install unsloth unsloth_zoo bitsandbytes transformers trl
```

Core pattern (drop-in with `trl.SFTTrainer` or `trl.GRPOTrainer`):
```python
from unsloth import FastLanguageModel

model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/Qwen3-4B-Instruct-2507",
    max_seq_length=2048,
    load_in_4bit=True,               # or load_in_16bit=True
)
model = FastLanguageModel.get_peft_model(
    model,
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
    use_gradient_checkpointing="unsloth",
    # Optional QAT: qat_scheme="int4"  # supports fp8-int4, fp8-fp8, int8-int4, int4
)

# Before inference:
FastLanguageModel.for_inference(model)
```
Note: To force a specific 4-bit repo without remapping, pass `use_exact_model_name=True`.

---

## 5. Axolotl (YAML + CLI)

Install & fetch starter configs:
```bash
pip install axolotl
axolotl fetch examples
axolotl fetch deepspeed_configs
```

### Core CLI Commands
```bash
axolotl train config.yml
axolotl train config.yml --deepspeed deepspeed_configs/zero1.json
axolotl train config.yaml --launcher torchrun -- --nnodes $N --nproc_per_node $G
axolotl train examples/llama-3/lora-1b-ray.yml --use-ray
axolotl merge-lora config.yml --lora-model-dir="./lora-out"
axolotl inference config.yml --lora-model-dir="./lora-out"  # or --gradio
axolotl quantize qat.yml
```

### Key YAML Patterns
```yaml
# LoRA / QLoRA
adapter: lora
lora_r: 16
lora_alpha: 32
lora_dropout: 0.05
lora_target_linear: true

# FSDP2 (multi-GPU)
fsdp_version: 2
fsdp_config:
  offload_params: true
  state_dict_type: FULL_STATE_DICT
  auto_wrap_policy: TRANSFORMER_BASED_WRAP
  transformer_layer_cls_to_wrap: LlamaDecoderLayer
  reshard_after_forward: true

# Sequence / Context Parallelism (must divide total GPUs)
context_parallel_size: 4  # Note: reduces global batch size by factor of 4

# Disk-efficient checkpoints (~40% smaller, vLLM/llmcompressor compatible)
save_compressed: true
```

Dataset tips:
- Formats: pre-tokenized (`input_ids`, `attention_mask`, `labels` JSONL), template-free, conversation (`messages` list), or instruct (`instruction`/`response`).
- For streaming pre-training, `max_steps` is required (`1 step = sequence_len * micro_batch_size * gradient_accumulation_steps * num_gpus` tokens).
- Always use `axolotl merge-lora` rather than custom scripts if Axolotl expanded embeddings for extra tokens.

---

## 6. LLaMA-Factory (`llamafactory-cli`)

Verify install: `llamafactory-cli version` (if env conflicts occur during source install: `pip install --no-deps -e .`).

Core CLI & WebUI workflow:
```bash
llamafactory-cli webui                    # Gradio UI (Train, Eval/Predict, Chat, Export)
llamafactory-cli train train_config.yaml  # Headless YAML training
llamafactory-cli export merge_config.yaml # Merge LoRA + optional GPTQ/AWQ quantization
```
Gotchas:
- Custom datasets must be registered in `data/data_info.json` with matching format keys.
- When merging LoRA (`llamafactory-cli export`), point `model_name_or_path` to an **unquantized** base model and omit `quantization_bit`; apply `export_quantization_bit` + `export_quantization_dataset` only for post-merge PTQ export.

---

## 7. Common Issues & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| CUDA OOM | Batch/seq too large | Set `per_device_train_batch_size=1`, increase `gradient_accumulation_steps`, enable `gradient_checkpointing`, or switch to 4-bit QLoRA |
| Adapter not updating | Wrong mode or frozen weights | Check `model.active_adapters`, `model.print_trainable_parameters()`, ensure `model.train()` |
| Quality degradation | Rank too low or few targets | Increase `r=32, lora_alpha=64`, set `target_modules="all-linear"`, lower LR to `1e-4` |
| Vocab mismatch on merge | Added special/chat tokens | Use `axolotl merge-lora` or save resized tokenizer alongside merged model |
