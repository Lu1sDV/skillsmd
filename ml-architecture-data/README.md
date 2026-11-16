# ml-architecture-data

Consolidated skill for LLM model architectures, subword tokenization, and
large-scale data curation/ETL. [SKILL.md](SKILL.md) is a short orchestrator that
routes to three independently readable references, loaded only when the task
needs them:

- [references/architectures.md](references/architectures.md) — decision matrix,
  configs, and gotchas for LitGPT, TorchTitan (FSDP2, 4D parallelism, Float8),
  nanoGPT, Mamba, and RWKV.
- [references/tokenization.md](references/tokenization.md) — training and
  integrating Hugging Face `tokenizers` (BPE, WordPiece, Unigram, alignment
  offsets) and `sentencepiece` (raw Unicode, CJK coverage, subword
  regularization).
- [references/data-processing.md](references/data-processing.md) — GPU-accelerated
  curation with NeMo Curator (heuristics, exact/fuzzy/semantic dedup, PII,
  multimodal) and distributed streaming ETL with Ray Data.

## Install and use

Copy the complete `ml-architecture-data/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-architecture-data ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-architecture-data@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-architecture-data
```

Examples:
- "Configure TorchTitan with FSDP2 and Float8 to pretrain Llama 3.1 8B on 8x H100s."
- "Train a custom 32k Unigram SentencePiece tokenizer for Japanese + English."
- "Build a NeMo Curator pipeline to deduplicate and PII-redact Common Crawl Parquet files."

## Sources and adaptation

Condensed on 2026-11-16 from nine upstream skills in
[Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)
(MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`, see
[LICENSE.upstream](LICENSE.upstream)):

- `01-model-architecture/litgpt/SKILL.md`
- `01-model-architecture/mamba/SKILL.md`
- `01-model-architecture/nanogpt/SKILL.md`
- `01-model-architecture/rwkv/SKILL.md`
- `01-model-architecture/torchtitan/SKILL.md`
- `02-tokenization/huggingface-tokenizers/SKILL.md`
- `02-tokenization/sentencepiece/SKILL.md`
- `05-data-processing/nemo-curator/SKILL.md`
- `05-data-processing/ray-data/SKILL.md`

These references are condensed derivatives, not vendored copies. Overlapping
workflows and boilerplate from the upstream skill files and their `references/`
were deduplicated into three domain-grouped guides while preserving core CLI
flags, APIs, VRAM tables, and configuration snippets.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks (`check_static_smells.py`). Commands and Python APIs target
the consumer's GPU/cluster environment and were not executed live here.
