---
name: ml-architecture-data
description: >
  Use when choosing, configuring, or running LLM model architectures (LitGPT,
  TorchTitan, nanoGPT, Mamba, RWKV), training or integrating subword tokenizers
  (Hugging Face Tokenizers, SentencePiece), or building large-scale data curation
  and streaming ETL pipelines (NeMo Curator, Ray Data). Triggers on 'litgpt',
  'torchtitan', 'nanogpt', 'mamba', 'rwkv', 'tokenizers', 'sentencepiece',
  'nemo-curator', 'ray-data', 'FSDP2', 'MinHash deduplication', or 'BPE/Unigram'.
---

# ML Architecture, Tokenization & Data Processing

Three capabilities, one reference each. Open only the reference the task needs;
do not preload all.

| Task / Tool | Read |
|---|---|
| Model architectures & pretraining/fine-tuning: LitGPT, TorchTitan (4D parallelism, FSDP2, Float8), nanoGPT, Mamba, RWKV | [Architectures reference](references/architectures.md) |
| Subword tokenization: Hugging Face `tokenizers` (BPE, WordPiece, Unigram, offsets) and `sentencepiece` (raw Unicode, CJK, subword regularization) | [Tokenization reference](references/tokenization.md) |
| Data curation & ETL: NeMo Curator (GPU dedup, heuristic/classifier filtering, PII, multimodal) and Ray Data (streaming `map_batches`, Ray Train sharding) | [Data processing reference](references/data-processing.md) |

## What each covers

- **Architectures** — Decision matrix and workflows for LitGPT (20+ models, LoRA/QLoRA, GGUF), TorchTitan (PyTorch-native FSDP2, TP/PP/CP, H100 Float8), nanoGPT (~300-line educational GPT-2), Mamba (`O(n)` selective SSM without KV cache), and RWKV (`O(1)` inference memory RNN+Transformer hybrid).
- **Tokenization** — Training custom BPE/WordPiece/Unigram vocabularies, 4-stage normalization/pre-tokenization/post-processing pipelines, span alignment tracking, `PreTrainedTokenizerFast` wrapping, and SentencePiece CJK/multilingual setup.
- **Data processing** — Ordered LLM curation pipelines (heuristics -> language ID -> exact/fuzzy/semantic dedup -> PII redaction -> GPU classifiers) with NeMo Curator, plus distributed streaming transforms, GPU batch inference, and Ray Train sharding with Ray Data.

## Universal rules

- Check GPU count, CUDA version, and VRAM budgets before launching pretraining or fine-tuning; use LoRA, gradient accumulation, or activation checkpointing when VRAM-constrained.
- Pin model/tokenizer configs and special token IDs (`unk`, `pad`, `eos`, `bos`) explicitly; verify encoded/decoded round-trips before tokenizing large corpora.
- For distributed TorchTitan runs with pipeline parallelism, always generate a seed checkpoint (`--checkpoint.create_seed_checkpoint`) before multi-node launch.
- Order NeMo Curator pipelines from cheapest to most expensive (heuristics and language ID before MinHash/semantic dedup and GPU classifiers).
- Stream large datasets (`iter_batches`, `train_from_iterator`, `write_parquet`) instead of materializing full corpora in driver memory (`.take_all()`, `.to_pandas()`).
- Verify outputs (checkpoint files, loss curves, dedup counts, tokenized shapes) rather than assuming success.
