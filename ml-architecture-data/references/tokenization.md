# Tokenization: Hugging Face Tokenizers & SentencePiece

Guide to choosing, training, and integrating fast subword tokenizers.

## Tool Selection

| Feature | Hugging Face `tokenizers` | `sentencepiece` |
|---|---|---|
| **Core strength** | Rust speed (<20s/GB), modular pipeline, offset tracking | Language-independent raw Unicode, CJK, deterministic vocab |
| **Algorithms** | BPE, WordPiece, Unigram | BPE, Unigram (default) |
| **Pre-tokenization** | Explicit (`Whitespace`, `ByteLevel`, `Metaspace`, `Digits`) | None required (treats space as `▁` meta-symbol) |
| **Best for** | Custom LLM/BERT tokenizers, NER/QA span alignment, HF Hub | Multilingual/CJK corpora, T5/ALBERT/XLNet/mBART, subword regularization |

---

## Hugging Face Tokenizers

```bash
pip install tokenizers transformers
```

### Pretrained & Alignment Tracking

```python
from tokenizers import Tokenizer

tokenizer = Tokenizer.from_pretrained("bert-base-uncased")
text = "Hello, world!"
output = tokenizer.encode(text)
print(output.tokens, output.ids)

# Map tokens back to character spans in original text (for NER / QA)
for tok, (start, end) in zip(output.tokens, output.offsets):
    print(f"{tok} -> [{start}, {end}): {text[start:end]!r}")
```

### 4-Stage Pipeline & Training Custom Tokenizers

Pipeline order: **Normalization -> Pre-tokenization -> Model -> Post-processing**.

**1. Byte-level BPE (GPT-2 / Llama style)**:
```python
from tokenizers import Tokenizer
from tokenizers.models import BPE
from tokenizers.trainers import BpeTrainer
from tokenizers.pre_tokenizers import ByteLevel
from tokenizers.processors import TemplateProcessing

tokenizer = Tokenizer(BPE(unk_token="<|endoftext|>"))
tokenizer.pre_tokenizer = ByteLevel()

trainer = BpeTrainer(
    vocab_size=50257,
    special_tokens=["<|endoftext|>"],
    min_frequency=2,
)
tokenizer.train(files=["train.txt", "val.txt"], trainer=trainer)

tokenizer.post_processor = TemplateProcessing(
    single="$A <|endoftext|>",
    special_tokens=[("<|endoftext|>", 50256)],
)
tokenizer.save("my-bpe-tokenizer.json")
```

**2. WordPiece (BERT style)**:
```python
from tokenizers.models import WordPiece
from tokenizers.trainers import WordPieceTrainer
from tokenizers.normalizers import BertNormalizer
from tokenizers.pre_tokenizers import Whitespace

tokenizer = Tokenizer(WordPiece(unk_token="[UNK]"))
tokenizer.normalizer = BertNormalizer(lowercase=True)
tokenizer.pre_tokenizer = Whitespace()

trainer = WordPieceTrainer(
    vocab_size=30522,
    special_tokens=["[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]"],
    continuing_subword_prefix="##",
)
tokenizer.train(["corpus.txt"], trainer)
```

**3. Unigram**:
```python
from tokenizers.models import Unigram
from tokenizers.trainers import UnigramTrainer

tokenizer = Tokenizer(Unigram())
trainer = UnigramTrainer(vocab_size=8000, special_tokens=["<unk>", "<s>", "</s>"], unk_token="<unk>")
tokenizer.train(["data.txt"], trainer)
```

### Training from Large Iterators, Padding & `transformers` Integration

```python
from datasets import load_dataset
from transformers import PreTrainedTokenizerFast

# Stream large datasets without writing temp files
dataset = load_dataset("wikitext", "wikitext-103-raw-v1", split="train")
def batch_iter(batch_size=1000):
    for i in range(0, len(dataset), batch_size):
        yield dataset[i : i + batch_size]["text"]

tokenizer.train_from_iterator(batch_iter(), trainer=trainer, length=len(dataset))

# Configure truncation & padding on raw Tokenizer
tokenizer.enable_truncation(max_length=512)
tokenizer.enable_padding(pad_id=tokenizer.token_to_id("[PAD]"), pad_token="[PAD]", length=512)

# Wrap for Hugging Face transformers
hf_tok = PreTrainedTokenizerFast(
    tokenizer_file="my-bpe-tokenizer.json",
    unk_token="<|endoftext|>",
    pad_token="[PAD]",
)
inputs = hf_tok("Hello world", padding=True, truncation=True, max_length=512, return_tensors="pt")
```

Note: When loading via `AutoTokenizer.from_pretrained(...)`, check `tokenizer.is_fast` and access the Rust object via `tokenizer.backend_tokenizer`.

---

## SentencePiece

```bash
pip install sentencepiece
```

### Training (CLI & Python)

```bash
spm_train --input=data.txt --model_prefix=m --vocab_size=32000 --model_type=unigram
```

```python
import sentencepiece as spm

spm.SentencePieceTrainer.train(
    input="corpus.txt",
    model_prefix="m",
    vocab_size=32000,
    model_type="unigram",       # "unigram" (T5/ALBERT/XLNet) or "bpe" (mBART)
    character_coverage=0.9995,  # Use 1.0 for CJK (Chinese/Japanese/Korean)
    user_defined_symbols=["[SEP]", "[CLS]"],
    unk_piece="<unk>",
    unk_id=2, eos_id=1, pad_id=0,
    num_threads=16,
)
```

For T5-style sentinel tokens, pass `user_defined_symbols=[f"<extra_id_{i}>" for i in range(100)]`.

### Encoding, Decoding & Subword Regularization

SentencePiece treats whitespace as `▁` (U+2581) so detokenization is lossless without language-specific rules.

```python
sp = spm.SentencePieceProcessor(model_file="m.model")

pieces = sp.encode("This is a test", out_type=str)  # ['▁This', '▁is', '▁a', '▁test']
ids = sp.encode("This is a test", out_type=int)
text = sp.decode(ids)                               # "This is a test"

# Subword regularization (data augmentation during training)
sampled = sp.encode("tokenization", out_type=str, enable_sampling=True, alpha=0.1)
```

### Performance & Gotchas

- **Training speed (1GB corpus)**: HF BPE ~15 min, HF Unigram ~40 min; SentencePiece BPE ~10-15 min, Unigram ~30-40 min.
- **Inference throughput**: HF Tokenizers ~200k sentences/sec (~4 GB/min); SentencePiece ~50k sentences/sec (~6MB RAM).
- **CJK coverage**: Always set `character_coverage=1.0` for CJK or rare characters will collapse to `<unk>`.
- **Transformers compatibility**: Use `T5Tokenizer.from_pretrained(...)` for SentencePiece-backed T5 models.
