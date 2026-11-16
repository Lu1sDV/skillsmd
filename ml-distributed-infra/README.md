# ml-distributed-infra

Consolidated skill for distributed ML training frameworks and cloud GPU
infrastructure. [SKILL.md](SKILL.md) is a short orchestrator that routes to two
independently readable references, loaded only when the task needs them:

- [references/distributed-training.md](references/distributed-training.md) —
  parallelism selection (DP, ZeRO-1/2/3, FSDP2, TP/PP/CP/EP), HuggingFace
  Accelerate, PyTorch FSDP2 (`fully_shard`), DeepSpeed, Megatron-Core,
  PyTorch Lightning, and Ray Train.
- [references/cloud-infrastructure.md](references/cloud-infrastructure.md) —
  platform selection, Modal serverless GPUs, SkyPilot multi-cloud YAML & spot
  recovery, and Lambda Labs dedicated instances & 1-Click Slurm clusters.

## Install and use

Copy the complete `ml-distributed-infra/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-distributed-infra ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-distributed-infra@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-distributed-infra
```

Examples:
- "Convert this single-GPU PyTorch loop to FSDP2 with DCP checkpointing."
- "Write a SkyPilot YAML to train a 70B model on 4x8 H100 spot instances with S3 checkpointing."
- "Deploy an auto-scaling vLLM/Transformers endpoint on Modal with a persistent Volume."

## Sources and adaptation

Condensed from nine upstream skills in
[Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)
(MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`, see
[LICENSE.upstream](LICENSE.upstream)):

- `08-distributed-training/accelerate/SKILL.md`
- `08-distributed-training/deepspeed/SKILL.md`
- `08-distributed-training/megatron-core/SKILL.md`
- `08-distributed-training/pytorch-fsdp2/SKILL.md`
- `08-distributed-training/pytorch-lightning/SKILL.md`
- `08-distributed-training/ray-train/SKILL.md`
- `09-infrastructure/lambda-labs/SKILL.md`
- `09-infrastructure/modal/SKILL.md`
- `09-infrastructure/skypilot/SKILL.md`

These references are condensed derivatives, not vendored copies. Auto-scraped
documentation dumps (such as the upstream DeepSpeed `SKILL.md`) were distilled
into concise configuration schemas, launch commands, and engineering guardrails.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks (`check_static_smells.py`). Commands and cloud configs apply
to the consumer's environment and were not executed against live GPU clusters
here.
