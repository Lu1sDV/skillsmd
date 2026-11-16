# Distributed Training Frameworks

Practical guide to selecting and configuring distributed training frameworks across single-node multi-GPU and multi-node clusters.

## Parallelism & framework selection

| Model / Workload | Recommended Strategy | Best Framework |
|---|---|---|
| Fits on 1 GPU, want faster throughput | DDP (`DistributedDataParallel`) | PyTorch Lightning or Accelerate |
| 1B–30B params, single/multi-node PyTorch | FSDP2 (`fully_shard`) or ZeRO-2/3 | PyTorch FSDP2, Accelerate, or DeepSpeed |
| Memory-constrained (CPU/NVMe offload) | ZeRO-3 + Offload (ZeRO-Infinity) | DeepSpeed |
| >10B–400B+ LLMs, H100/A100 clusters | 3D/4D parallelism (TP + PP + DP + CP/EP) | Megatron-Core |
| Multi-node orchestration, fault tolerance, HPO | Elastic workers + Ray Tune | Ray Train |
| Clean research loop with callbacks/logging | `LightningModule` + `Trainer` | PyTorch Lightning |

**Parallelism rules of thumb:**
- **Data Parallel (DP / DDP):** Replicates model; splits batch. Fastest when model + optimizer fit in 1 GPU.
- **ZeRO-1 / ZeRO-2 / ZeRO-3 (and FSDP):** Shards optimizer states (stage 1), + gradients (stage 2), + parameters (stage 3 / `FULL_SHARD`).
- **Tensor Parallel (TP):** Splits layers intra-node over NVLink (`TP <= 8`). Avoid crossing InfiniBand nodes with TP.
- **Pipeline Parallel (PP):** Splits layers across nodes for >70B models; pair with interleaved schedules (`--num-layers-per-virtual-pipeline-stage`) to reduce pipeline bubbles.
- **Context Parallel (CP):** Splits sequence dimension for >8K token contexts.
- **Expert Parallel (EP):** Distributes MoE experts across GPUs.

---

## HuggingFace Accelerate

Unified wrapper around DDP, DeepSpeed, FSDP, and Megatron with minimal code changes.

```bash
pip install accelerate
accelerate config              # Interactive config generator
accelerate launch train.py     # Single/multi-GPU based on config
```

### Core 4-line integration

```python
from accelerate import Accelerator
from accelerate.utils import set_seed

set_seed(42)
accelerator = Accelerator(mixed_precision="bf16", gradient_accumulation_steps=4)

model, optimizer, dataloader = accelerator.prepare(model, optimizer, dataloader)

for batch in dataloader:
    with accelerator.accumulate(model):
        optimizer.zero_grad()
        loss = model(batch).mean()
        accelerator.backward(loss)
        optimizer.step()
```

### Launch commands & plugins

```bash
# Multi-GPU (single node)
accelerate launch --multi_gpu --num_processes 8 train.py

# Multi-node
accelerate launch --multi_gpu --num_processes 16 \
  --num_machines 2 --machine_rank 0 \
  --main_process_ip $MASTER_ADDR --main_process_port 29500 train.py

# With DeepSpeed config
accelerate launch --config_file ds_config.json train.py
```

**FSDP plugin in Python:**
```python
from accelerate import Accelerator, FullyShardedDataParallelPlugin

fsdp_plugin = FullyShardedDataParallelPlugin(
    sharding_strategy="FULL_SHARD",
    auto_wrap_policy="TRANSFORMER_AUTO_WRAP",
    cpu_offload=False,
)
accelerator = Accelerator(mixed_precision="bf16", fsdp_plugin=fsdp_plugin)
```

**Checkpointing & gotchas:**
- Never call `.to("cuda")` manually on `model` or `batch` after `accelerator.prepare()`.
- Save state only on main process: `if accelerator.is_main_process: accelerator.save_state("ckpt/")`; load on all ranks: `accelerator.load_state("ckpt/")`.
- Effective batch size = `per_device_batch * num_processes * gradient_accumulation_steps`.

---

## PyTorch FSDP2 (`fully_shard`)

Native PyTorch DTensor-based per-parameter sharding (`torch.distributed.fsdp.fully_shard`). Prefer over FSDP1 for inspectable DTensor state dicts and composable `DeviceMesh` parallelism.

### Required contract

1. Launch with `torchrun` and set device via `LOCAL_RANK`.
2. Apply `fully_shard()` **bottom-up** (transformer blocks first, then root `model`).
3. Call `model(inputs)`, **not** `model.forward(inputs)`, so FSDP2 pre/post-forward hooks execute.
4. Construct the optimizer **after** `fully_shard()` so it holds `DTensor` parameters.
5. Checkpoint with Distributed Checkpoint (`torch.distributed.checkpoint`, DCP) or `get_model_state_dict` / `set_model_state_dict`, not naive `torch.save(model.state_dict())`.

### Minimal pattern (with meta-device init & mixed precision)

```python
import os
import torch
import torch.distributed as dist
from torch.distributed.fsdp import fully_shard, MixedPrecisionPolicy, CPUOffloadPolicy
import torch.distributed.checkpoint as dcp

dist.init_process_group(backend="nccl")
local_rank = int(os.environ["LOCAL_RANK"])
torch.cuda.set_device(local_rank)

# Initialize large model on meta device, shard bottom-up, then materialize
with torch.device("meta"):
    model = MyTransformer()

mp_policy = MixedPrecisionPolicy(param_dtype=torch.bfloat16, reduce_dtype=torch.float32)
for module in model.modules():
    if isinstance(module, TransformerBlock):
        fully_shard(module, mp_policy=mp_policy)
fully_shard(model, mp_policy=mp_policy)  # root reshard_after_forward defaults to False

model.to_empty(device="cuda")
model.reset_parameters()

# Create optimizer AFTER sharding
optimizer = torch.optim.AdamW(model.parameters(), lr=3e-4)

# Gradient accumulation: use set_requires_gradient_sync(False) instead of FSDP1 no_sync()
model.set_requires_gradient_sync(False)
loss = model(inputs)
loss.backward()
model.set_requires_gradient_sync(True)
optimizer.step()
optimizer.zero_grad()
```

```bash
torchrun --nproc_per_node=8 train_fsdp2.py
```

**Troubleshooting:**
- **Hooks skipped / unsharded OOM:** Calling `model.forward(x)` bypasses hooks; always use `model(x)`.
- **Memory spike after forward:** Set `reshard_after_forward=True` explicitly if needed.
- **CPU offload:** Pass `offload_policy=CPUOffloadPolicy()` to `fully_shard` (adds PCIe transfer overhead).

---

## DeepSpeed

Memory-efficient data parallelism (ZeRO-1/2/3), CPU/NVMe offloading (ZeRO-Offload / ZeRO-Infinity), and 3D parallelism.

```bash
pip install deepspeed
ds_report   # Verify compiled ops (e.g., async_io, gds for NVMe offload)
```

### Python integration & launch

```python
import deepspeed

model_engine, optimizer, _, _ = deepspeed.initialize(
    args=cmd_args,
    model=model,
    model_parameters=model.parameters(),
)

for batch in dataloader:
    loss = model_engine(batch)
    model_engine.backward(loss)
    model_engine.step()
```

```bash
deepspeed --num_gpus=8 train.py --deepspeed --deepspeed_config ds_config.json
# Multi-node with hostfile:
deepspeed --hostfile=hostfile train.py --deepspeed --deepspeed_config ds_config.json
```

### ZeRO-3 + CPU/NVMe offload config (`ds_config.json`)

```json
{
  "train_micro_batch_size_per_gpu": 2,
  "gradient_accumulation_steps": 8,
  "bf16": {"enabled": true},
  "zero_optimization": {
    "stage": 3,
    "offload_optimizer": {"device": "cpu", "pin_memory": true},
    "offload_param": {"device": "nvme", "nvme_path": "/local_nvme", "pin_memory": true},
    "overlap_comm": true,
    "contiguous_gradients": true,
    "allgather_bucket_size": 5e8,
    "reduce_bucket_size": 5e8,
    "stage3_gather_16bit_weights_on_model_save": true
  }
}
```

**Notes:**
- `stage: 1` partitions optimizer states; `stage: 2` adds gradients; `stage: 3` adds parameters.
- `offload_param` requires `stage: 3`. NVMe offload requires `libaio-dev` (`async_io` op `[OKAY]` in `ds_report`).
- Set `"stage3_gather_16bit_weights_on_model_save": true` if you need a consolidated checkpoint on save.

---

## Megatron-Core

NVIDIA framework for training 2B–462B+ parameter LLMs with up to ~47% MFU on H100 GPUs.

```bash
# Recommended NVIDIA NGC container
docker run --gpus all -it --rm nvcr.io/nvidia/pytorch:25.04-py3
# Or pip
pip install megatron-core
```

### Parallelism sizing reference

| Model Size | GPUs | TP | PP | DP | CP |
|---|---|---|---|---|---|
| 7B | 8 | 1 | 1 | 8 | 1 |
| 13B | 8 | 2 | 1 | 4 | 1 |
| 70B | 64 | 4 | 4 | 4 | 1 |
| 405B | 128 | 8 | 8 | 2 | 2 |

### 3D/4D launch pattern (`pretrain_gpt.py`)

```bash
torchrun --nproc_per_node=8 --nnodes=8 pretrain_gpt.py \
  --tensor-model-parallel-size 4 \
  --pipeline-model-parallel-size 4 \
  --context-parallel-size 1 \
  --sequence-parallel \
  --num-layers 80 --hidden-size 8192 --num-attention-heads 64 \
  --seq-length 4096 --max-position-embeddings 4096 \
  --micro-batch-size 1 --global-batch-size 1024 \
  --lr 3e-4 --lr-decay-style cosine --lr-warmup-iters 2000 \
  --clip-grad 1.0 --bf16 \
  --use-mcore-models --transformer-impl transformer_engine \
  --data-path /path/to/data --vocab-file /path/to/vocab.json --merge-file /path/to/merges.txt
```

**Key flags & tuning:**
- **FP8 on H100+:** Add `--fp8-hybrid` (with `--transformer-impl transformer_engine`) for 1.5–2x speedup over BF16.
- **MoE:** Add `--expert-model-parallel-size 4 --num-experts 8 --moe-router-topk 2 --moe-router-load-balancing-type aux_loss --moe-aux-loss-coeff 0.01`. Total GPUs = `TP * PP * EP * DP`.
- **OOM fixes:** Enable activation recomputation (`--recompute-granularity full --recompute-method block --recompute-num-layers 1`) or `--cpu-optimizer`.
- **Low MFU (<30%):** Increase `--micro-batch-size`, enable `--use-flash-attn` and `--sequence-parallel`, keep `TP <= 8` (intra-node NVLink), and use `--num-layers-per-virtual-pipeline-stage 2` to cut pipeline bubbles.

---

## PyTorch Lightning

High-level `LightningModule` + `Trainer` abstraction with built-in DDP, FSDP, and DeepSpeed strategies.

```bash
pip install lightning
```

```python
import lightning as L
import torch
from lightning.pytorch.callbacks import ModelCheckpoint, EarlyStopping, LearningRateMonitor

class LitModel(L.LightningModule):
    def __init__(self, model):
        super().__init__()
        self.model = model

    def training_step(self, batch, batch_idx):
        x, y = batch
        loss = torch.nn.functional.cross_entropy(self.model(x), y)
        self.log("train_loss", loss)
        return loss

    def validation_step(self, batch, batch_idx):
        x, y = batch
        val_loss = torch.nn.functional.cross_entropy(self.model(x), y)
        self.log("val_loss", val_loss)

    def configure_optimizers(self):
        opt = torch.optim.AdamW(self.parameters(), lr=1e-3)
        sched = torch.optim.lr_scheduler.CosineAnnealingLR(opt, T_max=100)
        return {"optimizer": opt, "lr_scheduler": {"scheduler": sched, "interval": "epoch"}}

trainer = L.Trainer(
    max_epochs=100,
    accelerator="gpu",
    devices=8,
    num_nodes=1,
    strategy="ddp",            # Or "fsdp", "deepspeed_stage_2", "deepspeed_stage_3"
    precision="bf16-mixed",
    accumulate_grad_batches=4,
    callbacks=[
        ModelCheckpoint(monitor="val_loss", mode="min", save_top_k=3),
        EarlyStopping(monitor="val_loss", patience=5, mode="min"),
        LearningRateMonitor(logging_interval="epoch"),
    ],
)
trainer.fit(LitModel(my_net), train_loader, val_loader)
```

---

## Ray Train

Cluster-scale distributed orchestration with fault-tolerant checkpointing, elastic scaling, and Ray Tune HPO.

```bash
pip install -U "ray[train]"
```

### Cluster startup

```bash
# Head node
ray start --head --port=6379 --dashboard-host=0.0.0.0
# Worker nodes
ray start --address=<HEAD_IP>:6379
ray status   # Verify total nodes and GPUs
```

### `TorchTrainer` with checkpoint recovery

```python
import ray
from ray import train
from ray.train import Checkpoint, ScalingConfig
from ray.train.torch import TorchTrainer
import torch

def train_func(config):
    model = MyModel()
    optimizer = torch.optim.AdamW(model.parameters(), lr=config["lr"])

    checkpoint = train.get_checkpoint()
    start_epoch = 0
    if checkpoint:
        with checkpoint.as_directory() as ckpt_dir:
            state = torch.load(f"{ckpt_dir}/model.pt")
            model.load_state_dict(state["model"])
            optimizer.load_state_dict(state["optimizer"])
            start_epoch = state["epoch"] + 1

    model = train.torch.prepare_model(model)
    dataloader = train.torch.prepare_data_loader(get_dataloader(config["batch_size"]))

    for epoch in range(start_epoch, 20):
        loss = run_epoch(model, optimizer, dataloader)
        ckpt_dir = train.get_context().get_trial_dir()
        torch.save({"model": model.state_dict(), "optimizer": optimizer.state_dict(), "epoch": epoch}, f"{ckpt_dir}/model.pt")
        train.report({"loss": loss, "epoch": epoch}, checkpoint=Checkpoint.from_directory(ckpt_dir))

ray.init(address="auto")
trainer = TorchTrainer(
    train_func,
    train_loop_config={"lr": 3e-4, "batch_size": 32},
    scaling_config=ScalingConfig(
        num_workers=16,
        use_gpu=True,
        resources_per_worker={"GPU": 1, "CPU": 4},
        placement_strategy="SPREAD",
    ),
)
result = trainer.fit()
```

**HuggingFace & Ray Tune:**
- Use `ray.train.huggingface.TransformersTrainer` to scale HF `Trainer` across multi-node Ray clusters.
- Wrap `TorchTrainer` inside `tune.Tuner(..., tune_config=tune.TuneConfig(num_samples=20, scheduler=ASHAScheduler(metric="loss", mode="min")))` for distributed hyperparameter sweeps with early stopping.
