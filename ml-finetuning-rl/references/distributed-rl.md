# Distributed RL Reference (OpenRLHF, veRL, Miles, Slime, TorchForge)

Distilled guide to multi-GPU and multi-node RLHF/RLVR frameworks for 7B-671B+ models.

---

## 1. Framework Selection

| Framework | Orchestration | Training Backend | Rollout Engine | Best For |
|---|---|---|---|---|
| **OpenRLHF** | Ray | DeepSpeed ZeRO-3 | vLLM | Mature Ray+vLLM Hybrid Engine RLHF (PPO/GRPO/RLOO/REINFORCE++/DPO) |
| **veRL** | Ray (HybridFlow) | FSDP, FSDP2, Megatron-LM | vLLM, SGLang, HF | Flexible backend swapping up to 671B, multi-turn tools, VLM RL |
| **Slime** | Ray | Megatron-LM | SGLang + router | Megatron-native RL, custom async data buffers, GLM/Qwen3/DeepSeek |
| **Miles** | Ray (slime fork) | Megatron-LM | SGLang + EAGLE | Enterprise 1TB+ MoE, unified FP8 / INT4 QAT, Rollout Routing Replay (R3) |
| **TorchForge** | Monarch (no Ray) | TorchTitan (FSDP) | vLLM | PyTorch-native algorithm research (GRPO/DAPO/SAPO in ~100 lines) |

---

## 2. OpenRLHF

Install (NVIDIA PyTorch container recommended):
```bash
pip install openrlhf[vllm]
```

### Ray + vLLM Hybrid Engine (PPO & GRPO)
```bash
ray start --head --node-ip-address 0.0.0.0 --num-gpus 8

ray job submit --address="http://127.0.0.1:8265" \
  -- python3 -m openrlhf.cli.train_ppo_ray \
  --ref_num_nodes 1 --ref_num_gpus_per_node 8 \
  --reward_num_nodes 1 --reward_num_gpus_per_node 8 \
  --actor_num_nodes 1 --actor_num_gpus_per_node 8 \
  --vllm_num_engines 4 --vllm_tensor_parallel_size 2 \
  --colocate_all_models --vllm_gpu_memory_utilization 0.5 \
  --vllm_enable_sleep --deepspeed_enable_sleep \
  --pretrain OpenRLHF/Llama-3-8b-sft-mixture \
  --reward_pretrain OpenRLHF/Llama-3-8b-rm-700k \
  --save_path ./output/llama3-8b-grpo \
  --advantage_estimator group_norm \
  --use_kl_loss --kl_estimator k3 --no_advantage_std_norm \
  --zero_stage 3 --bf16 --gradient_checkpointing --packing_samples \
  --actor_learning_rate 5e-7 --init_kl_coef 0.01
```
- For **PPO**, omit `--advantage_estimator group_norm` and add `--critic_num_nodes 1 --critic_num_gpus_per_node 8 --critic_learning_rate 9e-6`.
- For standalone **RM** or **DPO**: `deepspeed --module openrlhf.cli.train_rm` / `openrlhf.cli.train_dpo`.
- Gotchas:
  - GPU OOM with `--colocate_all_models`: remove colocation and assign separate GPUs per role.
  - DeepSpeed GPU index out of range under Ray: `export RAY_EXPERIMENTAL_NOSET_CUDA_VISIBLE_DEVICES=1`.

---

## 3. veRL (Volcano Engine RL / HybridFlow)

Install: `pip install verl[vllm]` (or `verl[sglang]`, or Docker `verlai/verl:vllm011.latest`). Avoid `vllm 0.7.x`; use `vllm>=0.8.5,<=0.12.0`.

### Quick Start (GRPO on Parquet Data)
Parquet rows expect `prompt` (chat list) and `reward_model: {"ground_truth": "..."}`:
```bash
python3 -m verl.trainer.main_ppo \
  algorithm.adv_estimator=grpo \
  data.train_files=~/data/gsm8k/train.parquet \
  actor_rollout_ref.model.path=Qwen/Qwen2.5-7B-Instruct \
  actor_rollout_ref.rollout.name=vllm \
  actor_rollout_ref.rollout.n=8 \
  actor_rollout_ref.actor.use_kl_loss=True \
  actor_rollout_ref.actor.kl_loss_coef=0.001 \
  trainer.n_gpus_per_node=8
```
- `algorithm.adv_estimator` options: `grpo`, `gae` (PPO w/ critic), `reinforce_plus_plus`, `rloo`, `remax`, `opo`.
- Large models (>70B): switch to Megatron backend (`actor_rollout_ref.actor.strategy=megatron`, `tensor_model_parallel_size=8`, `pipeline_model_parallel_size=2`) with `pip install mbridge`.
- Slow weight sync or rollout OOM: use `actor_rollout_ref.actor.strategy=fsdp2`, `offload_policy=true`, `enable_gradient_checkpointing=true`, and `trainer.async_weight_update=true`.

---

## 4. Slime (Megatron-LM + SGLang)

Install via Docker `slimerl/slime:latest` or source (`pip install -e .`).

### GRPO Launch
```bash
source scripts/models/qwen3-4B.sh
python train.py \
  --actor-num-nodes 1 --actor-num-gpus-per-node 8 --rollout-num-gpus 8 \
  --advantage-estimator grpo --use-kl-loss --kl-loss-coef 0.001 \
  --prompt-data /path/to/train.jsonl --input-key prompt --label-key label \
  --apply-chat-template \
  --rollout-batch-size 32 --n-samples-per-prompt 8 --global-batch-size 256 \
  --num-rollout 3000 ${MODEL_ARGS[@]}
```
- **Constraint**: `rollout_batch_size * n_samples_per_prompt = global_batch_size * num_steps_per_rollout`.
- **Async mode**: `python train_async.py --async-buffer-size 4 --update-weights-interval 2 ...`
- **Multi-turn agentic**: pass `--custom-generate-function-path custom_generate.py --max-turns 5`.
- Passes three arg groups: Megatron (`--tensor-model-parallel-size`), SGLang (`--sglang-mem-fraction-static`), and slime (`--colocate`).

---

## 5. Miles (Enterprise Slime Fork for MoE / FP8 / Speculative RL)

Docker: `radixark/miles:latest`. Inherits all `slime` CLI flags and `Sample` dataclass, adding:

- **MoE + FP8 stability**:
  ```bash
  export NVTE_FP8_BLOCK_SCALING_FP32_SCALES=1
  export CUDA_DEVICE_MAX_CONNECTIONS=1
  python train.py --advantage-estimator grpo \
    --tensor-model-parallel-size 8 --expert-model-parallel-size 4 \
    --hf-checkpoint /path/to/deepseek-v3 --prompt-data /path/to/data.jsonl
  ```
- **Rollout Routing Replay (R3)**: Records SGLang MoE routing in `sample.rollout_routed_experts` and replays it in Megatron for bit-wise train-inference alignment.
- **Train-inference mismatch**: Enable Truncated Importance Sampling via `--use-tis --tis-threshold 0.9`.
- **Speculative RL (EAGLE + Online MTP)**:
  ```bash
  --sglang-speculative-algorithm EAGLE --sglang-speculative-num-steps 3 \
  --sglang-speculative-eagle-topk 1 --sglang-speculative-num-draft-tokens 4 \
  --sglang-speculative-draft-model-path /path/to/draft \
  --mtp-num-layers 1 --enable-mtp-training --mtp-loss-scaling-factor 0.2
  ```
- **INT4 QAT**: Reduces 671B VRAM from ~1.3 TB (BF16) to ~420 GB.

---

## 6. TorchForge (PyTorch-Native + Monarch)

Install: `./scripts/install.sh` (or `./scripts/install_rocm.sh`). Experimental; APIs may evolve.

```bash
python -m apps.sft.main --config apps/sft/llama3_8b.yaml    # 2+ GPUs
python -m apps.grpo.main --config apps/grpo/qwen3_1_7b.yaml  # 3+ GPUs (trainer, ref_model, generator)
```

Key abstractions:
- **Monarch services**: `Trainer` (TorchTitan FSDP/TP/PP), `Generator` (vLLM), `Reference Model`, `Reward Actors`.
- **Built-in losses**: GRPO, DAPO, CISPO, GSPO, SAPO, or subclass `nn.Module` with `forward(logprobs, ref_logprobs, advantages, padding_mask)`.
