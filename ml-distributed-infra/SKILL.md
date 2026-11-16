---
name: ml-distributed-infra
description: >
  Distributed ML training and cloud GPU infrastructure: HuggingFace Accelerate,
  PyTorch FSDP2 (fully_shard), DeepSpeed ZeRO/offload, NVIDIA Megatron-Core
  (3D/4D parallelism, MoE), PyTorch Lightning, Ray Train, plus cloud GPU
  execution on Modal, SkyPilot, and Lambda Labs. Triggers on multi-GPU,
  multi-node, FSDP2, DeepSpeed, ZeRO, Megatron, Accelerate, Lightning,
  Ray Train, Modal, SkyPilot, or Lambda Labs.
---

# Distributed ML & Cloud GPU Infrastructure

Two references, one per layer. Open only the reference the task needs; do not
preload both.

| Task / Tool | Read |
|---|---|
| Parallelism selection (DP/ZeRO/FSDP2/TP/PP/CP/EP), Accelerate, PyTorch FSDP2, DeepSpeed, Megatron-Core, PyTorch Lightning, Ray Train | [Distributed training reference](references/distributed-training.md) |
| Serverless GPUs, multi-cloud YAML orchestration, spot recovery, dedicated GPU clusters: Modal, SkyPilot, Lambda Labs | [Cloud infrastructure reference](references/cloud-infrastructure.md) |

## What each covers

- **Distributed training** — choosing between DDP, ZeRO-1/2/3, FSDP2
  (`fully_shard`), and 3D/4D parallelism (TP/PP/CP/EP); launch commands
  (`torchrun`, `accelerate launch`, `deepspeed`, `ray`), config patterns,
  checkpointing (DCP, `save_state`), and memory/throughput tuning.
- **Cloud infrastructure** — provisioning and scaling GPU workloads on Modal
  (Python-native serverless functions, `Volume`, `Secret`, web endpoints),
  SkyPilot (multi-cloud YAML, `use_spot` + `sky jobs`, `MOUNT_CACHED`, `autostop`),
  and Lambda Labs (SSH, `/lambda/nfs` filesystems, REST/Python API, 1-Click Slurm).

## Universal rules

- **Verify hardware and environment before launching:** check GPU count, VRAM,
  NVLink vs PCIe topology (`nvidia-smi topo -m`), and compiled ops (`ds_report`
  for DeepSpeed, `sky check` for SkyPilot) rather than assuming defaults.
- **Match parallelism to model size and interconnect:** use DDP when a model
  fits on one GPU; use FSDP2/ZeRO-2/3 for 1B–30B+ models; keep Tensor Parallel
  intra-node (`TP <= 8` over NVLink) and use Pipeline Parallel across nodes.
- **Follow framework contracts:** in FSDP2, apply `fully_shard` bottom-up,
  create the optimizer after sharding, call `model(x)` (not `.forward()`), and
  save via DCP; in Accelerate, never manually `.to("cuda")` prepared tensors.
- **Checkpoint to persistent storage:** save to `/lambda/nfs/...`, `modal.Volume`
  (with `volume.commit()`), or `MOUNT_CACHED` cloud buckets—never rely on
  ephemeral local instance disks for long runs or spot instances.
- **Prevent runaway cloud spend:** always configure `autostop` in SkyPilot or
  explicitly terminate Lambda Labs instances (which have no auto-stop); keep
  API keys (`HF_TOKEN`, `LAMBDA_API_KEY`) in secrets/env vars, never in YAML or code.
