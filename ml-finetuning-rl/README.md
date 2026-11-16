# ml-finetuning-rl

Consolidated LLM fine-tuning and post-training RL skill covering parameter-efficient
SFT, preference alignment, verifiable-reward GRPO, and multi-node distributed RLHF.
[SKILL.md](SKILL.md) is a short orchestrator that routes to three independently
readable references, loaded only when the task needs them:

- [references/sft-peft.md](references/sft-peft.md) — PEFT (LoRA, QLoRA, DoRA,
  LoftQ, rsLoRA, IA3), Unsloth, Axolotl, LLaMA-Factory, VRAM sizing, and framework
  selection.
- [references/preference-rl.md](references/preference-rl.md) — TRL (`SFTTrainer`,
  `RewardTrainer`, `DPOTrainer`, `GRPOTrainer`, `PPO`), GRPO reward design and
  diagnostics, and reference-free SimPO.
- [references/distributed-rl.md](references/distributed-rl.md) — OpenRLHF, veRL,
  Slime, Miles, and TorchForge for multi-GPU / multi-node RLHF and RLVR.

## Install and use

Copy the complete `ml-finetuning-rl/` directory into your agent's skills directory.
For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-finetuning-rl ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-finetuning-rl@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-finetuning-rl
```

Examples:
- "Fine-tune Llama-3.1-8B with 4-bit QLoRA using PEFT or Unsloth on a 24GB GPU."
- "Set up a TRL GRPO training run with format and correctness rewards for math."
- "Configure veRL or OpenRLHF for 8-GPU GRPO training with vLLM rollouts."

## Sources and adaptation

Condensed on 2026-11-16 from 12 upstream skills in
[Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)
(MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`; see
[LICENSE.upstream](LICENSE.upstream)):

- `03-fine-tuning/axolotl/SKILL.md` (and `references/` CLI/YAML/dataset guides)
- `03-fine-tuning/llama-factory/SKILL.md` (and `references/getting_started.md`)
- `03-fine-tuning/peft/SKILL.md` (and `references/advanced-usage.md`)
- `03-fine-tuning/unsloth/SKILL.md` (and `references/llms-txt.md`)
- `06-post-training/trl-fine-tuning/SKILL.md`
- `06-post-training/grpo-rl-training/SKILL.md`
- `06-post-training/simpo/SKILL.md`
- `06-post-training/openrlhf/SKILL.md`
- `06-post-training/verl/SKILL.md`
- `06-post-training/miles/SKILL.md`
- `06-post-training/slime/SKILL.md`
- `06-post-training/torchforge/SKILL.md`

These references are condensed derivatives, not vendored copies. Scraper-generated
boilerplate in `axolotl`, `llama-factory`, and `unsloth` was replaced with distilled
CLI, YAML, and Python API patterns from their upstream reference docs.

Validation: static skill-smell check (`check_static_smells.py`) and local markdown
link verification. Training commands and configs target the consumer's GPU
environment and were not executed live here.
