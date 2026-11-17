# PyTorch Lightning Reference

Structured PyTorch training, multi-GPU/TPU orchestration, callbacks, and logging (`lightning == 2.6.6`, Python 3.10+).

## Installation & Namespace

Use `import lightning as L` with the `lightning` package (do not mix `pytorch_lightning as pl` and `lightning as L` namespaces in one application):

```bash
uv pip install "lightning==2.6.6"
# Optional extras (loggers, strategies)
uv pip install "lightning[extra]==2.6.6" wandb mlflow
```

---

## Core Architecture

### 1. `LightningModule` (6 Logical Sections)

Organize model logic into:
1. `__init__()` / `setup()` — layers and `self.save_hyperparameters()`
2. `training_step(batch, batch_idx)` — returns loss tensor
3. `validation_step(batch, batch_idx)` — validation metrics
4. `test_step(batch, batch_idx)` — held-out test evaluation
5. `predict_step(batch, batch_idx)` — inference
6. `configure_optimizers()` — optimizer(s) and LR scheduler(s)

```python
import lightning as L
import torch
import torch.nn.functional as F

class LitModel(L.LightningModule):
    def __init__(self, in_dim: int, hidden_dim: int = 64, lr: float = 1e-3):
        super().__init__()
        self.save_hyperparameters()
        self.net = torch.nn.Sequential(
            torch.nn.Linear(in_dim, hidden_dim),
            torch.nn.ReLU(),
            torch.nn.Linear(hidden_dim, 1),
        )

    def forward(self, x):
        return self.net(x)

    def training_step(self, batch, batch_idx):
        x, y = batch
        loss = F.mse_loss(self(x), y)
        self.log("train/loss", loss, prog_bar=True)
        return loss

    def validation_step(self, batch, batch_idx):
        x, y = batch
        loss = F.mse_loss(self(x), y)
        self.log("val/loss", loss, prog_bar=True, sync_dist=True)

    def test_step(self, batch, batch_idx):
        x, y = batch
        loss = F.mse_loss(self(x), y)
        self.log("test/loss", loss, sync_dist=True)

    def configure_optimizers(self):
        return torch.optim.AdamW(self.parameters(), lr=self.hparams.lr)
```

### 2. `LightningDataModule`

Encapsulate data preparation and per-rank DataLoaders:
- `prepare_data()` — download/tokenize/cache; runs on local rank 0 per node by default (or global rank 0 with shared storage). Do not assign `self.*` state here.
- `setup(stage=None)` — create splits/datasets per rank (`stage` in `'fit'`, `'validate'`, `'test'`, `'predict'`).
- `train_dataloader()`, `val_dataloader()`, `test_dataloader()`.

### 3. `Trainer` & End-to-End Workflow

```python
import lightning as L
from lightning.pytorch.callbacks import ModelCheckpoint, EarlyStopping, LearningRateMonitor
from lightning.pytorch.loggers import CSVLogger

L.seed_everything(42, workers=True)

callbacks = [
    ModelCheckpoint(monitor="val/loss", mode="min", save_top_k=1, save_last=True),
    EarlyStopping(monitor="val/loss", patience=5, mode="min"),
    LearningRateMonitor(logging_interval="step"),
]

trainer = L.Trainer(
    max_epochs=20,
    accelerator="auto",        # "gpu", "cpu", "tpu", "auto"
    devices="auto",
    precision="bf16-mixed",    # or "16-mixed", "32-true"
    gradient_clip_val=1.0,
    accumulate_grad_batches=1,
    callbacks=callbacks,
    logger=CSVLogger("logs", name="exp"),
    deterministic=True,
)

trainer.fit(model, datamodule=dm)
trainer.test(model, datamodule=dm, ckpt_path="best", weights_only=True)
```

---

## Distributed Strategies & Loggers

### Distributed Strategy Selection

Choose based on measured peak memory and throughput (not a fixed parameter-count threshold):

| Strategy | When to Use | Config |
|---|---|---|
| **DDP** (`strategy="ddp"`) | Each GPU holds full model, optimizer state, and activations | `Trainer(strategy="ddp", accelerator="gpu", devices=4)` |
| **FSDP** (`strategy="fsdp"`) | Sharding parameters/gradients/optimizer state resolves measured VRAM pressure | `Trainer(strategy="fsdp", accelerator="gpu", devices=4)` |
| **DeepSpeed** (`strategy="deepspeed_stage_2"` / `"deepspeed_stage_3"`) | ZeRO/CPU-offload features fit measured workload and CUDA stack | `Trainer(strategy="deepspeed_stage_2", accelerator="gpu", devices=4)` |

### Loggers

- Built-in local: `CSVLogger` (always available), `TensorBoardLogger` (default only when `tensorboard` is installed).
- Cloud/external: `WandbLogger`, `MLFlowLogger`, `CometLogger`.
- **Removed:** `NeptuneLogger` was removed in Lightning 2.6.4 (Neptune service shut down March 5, 2026).

---

## Best Practices & Gotchas

- **Device-agnostic code:** Never call `.cuda()`; use `self.device` or register buffers (`self.register_buffer(...)`).
- **Distributed metric sync:** `self.log(..., sync_dist=True)` is `False` by default. Set `sync_dist=True` for scalar tensors in `validation_step`/`test_step` and ensure all ranks execute the call. For non-additive metrics (e.g., AUROC), use a stateful `torchmetrics.Metric` object instead of averaging per-rank scalars.
- **Resuming vs. loading weights:**
  - Resume full training state (optimizer, epoch, callbacks): `trainer.fit(model, datamodule=dm, ckpt_path=path, weights_only=True)` on a fresh `model` and `Trainer`.
  - Load weights only for inference/fine-tuning: `LitModel.load_from_checkpoint(path, weights_only=True)`.
- **DDP evaluation padding:** Distributed samplers pad batches for even rank division, which can duplicate samples in `test_step`. Run final test evaluation on `devices=1` for exact sample counts or use a non-duplicating evaluator.
- **Debugging:** `Trainer(fast_dev_run=True)` runs 1 train/val/test batch, but disables checkpointing and several callbacks — also run a short 1-epoch fit to verify callbacks and checkpoints.
- **Data leakage:** Split independent subjects/groups/time periods before fitting preprocessing or scaling.
