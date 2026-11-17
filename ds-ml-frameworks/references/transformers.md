# Hugging Face Transformers Reference

Hub model loading, pipelines, chat templates, text generation, and `Trainer` fine-tuning (`transformers == 5.18.0`, Python 3.10+, PyTorch 2.5+).

## Installation & Environment

Transformers v5 is **PyTorch-only** (TensorFlow and JAX backends were removed).

```bash
uv venv --python 3.11 .venv-transformers
uv pip install --python .venv-transformers/bin/python \
  "transformers[torch]==5.18.0" "torch==2.14.1" \
  "huggingface-hub==1.33.0" "datasets==5.0.1" \
  "accelerate==1.15.0" "peft==0.21.2"
```

- **Dependency pin note:** `datasets==5.0.1` requires `huggingface-hub < 2` (even though Hub 2.x exists); keep them in the same compatible range.
- **Optional extras:** `Pillow` (images), `torchvision` + `timm` (vision backbones), `librosa` (requires Python >=3.12) + `soundfile` + FFmpeg (audio), `pytesseract` + Tesseract (OCR), `bitsandbytes` (quantization).

### Authentication & Caching

```bash
hf auth login                      # Recommended; writes to $HF_HOME/token
export HF_TOKEN="..."              # CI/server only; never commit or put in shell profiles
export HF_HOME="/path/to/cache"    # Override cache location (or HF_HUB_CACHE)
export HF_HUB_OFFLINE=1            # Offline mode (only after snapshots are cached)
export HF_HUB_DISABLE_IMPLICIT_TOKEN=1  # Prevent sending stored token on every request
```

- **Gated & custom-code models:** Accept the license on the Hub, then pass `trust_remote_code=True` only after reviewing the remote code; pin immutable commits via `revision="<commit_sha>"` (and `code_revision` if code lives in a separate repo).

---

## Core Workflows

### 1. Pipeline API (Quick Inference)

```python
from transformers import pipeline

# Causal LM generation (prefer max_new_tokens over max_length)
generator = pipeline("text-generation", model="Qwen/Qwen2.5-1.5B")
result = generator("The future of AI is", max_new_tokens=50)

# Classification
classifier = pipeline(
    "text-classification",
    model="distilbert/distilbert-base-uncased-finetuned-sst-2-english",
)
result = classifier("This movie was excellent!")

# Chat / instruction-tuned QA
qa = pipeline("text-generation", model="Qwen/Qwen2.5-0.5B-Instruct")
result = qa(
    [{"role": "user", "content": "Context: AI means artificial intelligence. What does AI mean?"}],
    max_new_tokens=32,
    do_sample=False,
)
```

**Removed in Transformers v5:** `question-answering`, `summarization`, `translation*`, `text2text-generation`, `image-to-text`, and `visual-question-answering` pipelines were removed. Load direct task model classes when exact extractive or seq2seq semantics are required.

### 2. Direct Model & Tokenizer Loading + Chat Templates

```python
from transformers import AutoModelForCausalLM, AutoTokenizer

model_id = "Qwen/Qwen2.5-1.5B-Instruct"
tokenizer = AutoTokenizer.from_pretrained(model_id)
model = AutoModelForCausalLM.from_pretrained(model_id, device_map="auto")

# Always use apply_chat_template for chat/instruct checkpoints
messages = [{"role": "user", "content": "Summarize attention in two sentences."}]
inputs = tokenizer.apply_chat_template(
    messages,
    tokenize=True,
    add_generation_prompt=True,
    return_tensors="pt",
    return_dict=True,
).to(model.device)

outputs = model.generate(**inputs, max_new_tokens=100)
print(tokenizer.decode(outputs[0], skip_special_tokens=True))
```

- If calling `apply_chat_template(..., tokenize=False)` and tokenizing afterward, pass `add_special_tokens=False` to `tokenizer(...)` to avoid duplicated BOS/EOS tokens.
- Preserve the exact chat template during fine-tuning data preparation.

### 3. Fine-Tuning with `Trainer`

```python
from transformers import Trainer, TrainingArguments

training_args = TrainingArguments(
    output_dir="./results",
    num_train_epochs=3,
    per_device_train_batch_size=8,
    bf16=True,
    logging_steps=50,
    save_strategy="epoch",
    report_to="none",
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset,
    processing_class=tokenizer,   # v5 uses processing_class (replaces tokenizer=)
)
trainer.train()
```

---

## Pitfalls & Scientific Validation

- **Reproducibility & provenance:** Record exact package versions, Hub `revision` hashes for both model and dataset, label ordering, truncation rates, excluded records, seeds, and decoding parameters (`temperature`, `top_p`, `do_sample`).
- **Dependent observations:** Split by patient, subject, document family, or time before fitting preprocessing or tuning hyperparameters.
- **Calibration & factuality:** Softmax probabilities are not calibrated uncertainties, and deterministic decoding (`do_sample=False`) does not guarantee factual accuracy.
- **Downstream adapters:** Verify output tensor shapes and class ordering when integrating external explainability/adapter tools (e.g., SHAP).
