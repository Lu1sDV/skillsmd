---
name: ml-finetuning-rl
description: >
  Use when fine-tuning or post-training LLMs: SFT, LoRA/QLoRA/DoRA/PEFT, Unsloth,
  Axolotl, LLaMA-Factory, TRL (SFTTrainer, DPOTrainer, RewardTrainer, GRPOTrainer,
  PPO), SimPO, or distributed RLHF/RLVR with OpenRLHF, veRL, Slime, Miles, or
  TorchForge. Triggers on 'LoRA', 'QLoRA', 'PEFT', 'Unsloth', 'Axolotl',
  'LLaMA-Factory', 'TRL', 'DPO', 'SimPO', 'GRPO', 'PPO', 'RLHF', 'OpenRLHF',
  'veRL', 'Slime', 'Miles', 'TorchForge'.
---

# ML Fine-Tuning & Post-Training RL

Three capabilities, one reference each. Open only the reference the task needs;
do not preload all.

| Task / Tool | Read |
|---|---|
| SFT & adapters: PEFT (LoRA, QLoRA, DoRA, LoftQ, IA3), Unsloth, Axolotl, LLaMA-Factory, VRAM sizing | [SFT & PEFT reference](references/sft-peft.md) |
| Preference & single-node RL: TRL (`SFTTrainer`, `DPOTrainer`, `RewardTrainer`, `GRPOTrainer`, `PPO`), verifiable GRPO rewards, SimPO | [Preference & RL reference](references/preference-rl.md) |
| Distributed RLHF / RLVR (7B-671B+): OpenRLHF, veRL, Slime, Miles (MoE/FP8/R3), TorchForge | [Distributed RL reference](references/distributed-rl.md) |

## What each covers

- **SFT & PEFT** — Framework selection, 8B/70B VRAM budgets, PEFT `LoraConfig` /
  `BitsAndBytesConfig` / DoRA / rsLoRA / LoftQ / multi-adapter serving, Unsloth
  `FastLanguageModel`, Axolotl YAML/FSDP2/CLI, and LLaMA-Factory WebUI/CLI export.
- **Preference & single-node RL** — Method selection (SFT vs DPO vs SimPO vs
  GRPO vs PPO), TRL trainers and CLI, verifiable reward design and diagnostics
  for GRPO (`reward_std`, KL), and reference-free SimPO configs.
- **Distributed RL** — Ray/vLLM Hybrid Engine (OpenRLHF), HybridFlow FSDP2/Megatron
  (veRL), Megatron+SGLang async and multi-turn (Slime), MoE FP8/INT4/R3/EAGLE
  speculative RL (Miles), and PyTorch-native Monarch/TorchTitan (TorchForge).

## Universal rules

- Check available GPU VRAM, CUDA/NCCL compatibility, and dataset schema before
  launching training; never guess batch sizes or parallelism degrees without
  checking hardware.
- Pin or verify compatible library versions (for example, avoid `vllm 0.7.x` with
  veRL; match `bitsandbytes`/`transformers`/`trl` versions for Unsloth).
- Test custom GRPO reward functions and dataset formatting on a small sample
  before full runs; monitor `reward`, `reward_std`, and `kl` rather than raw
  loss alone (GRPO loss normally rises as KL grows).
- When merging LoRA adapters (`merge_and_unload`, `axolotl merge-lora`, or
  `llamafactory-cli export`), merge against an **unquantized** base model and
  preserve any resized tokenizer embeddings.
- Confirm before overwriting existing checkpoints or deleting cached models/runs.
