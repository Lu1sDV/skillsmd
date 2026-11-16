# Experiment Tracking & Model Lifecycle

Guide to logging metrics, artifacts, hyperparameter sweeps, profiling, and model registries across Weights & Biases, MLflow, TensorBoard, and SwanLab.

## Tool Selection

| Tool | Best for | Hosting | Key strength |
|---|---|---|---|
| **Weights & Biases** | Collaborative DL training, sweeps, rich media | Managed SaaS / self-hosted | Bayesian/Hyperband sweeps, team reports, artifact lineage |
| **MLflow** | End-to-end lifecycle, model registry, serving | Self-hosted / Databricks | Framework-agnostic registry (`@alias`), REST serving |
| **TensorBoard** | Local scalar/histogram/graph debugging & profiling | Local / TensorBoard.dev | Zero-server overhead, PyTorch/TF profiler traces |
| **SwanLab** | Open-source/self-hosted tracking & multimodal media | Cloud / local / self-hosted | Lightweight local dashboard (`mode="local"`), ECharts & media |

---

## Weights & Biases (`wandb`)

### Install and Auth

```bash
pip install wandb
wandb login
# Or non-interactive:
export WANDB_API_KEY="your_api_key"
# Offline / air-gapped runs:
export WANDB_MODE="offline"
# Sync later: wandb sync <run_directory>
```

### Core Tracking Loop

```python
import wandb

run = wandb.init(
    project="image-classification",
    name="resnet50-lr1e-3-bs32",
    tags=["baseline", "resnet50"],
    group="resnet-experiments",
    job_type="train",
    notes="Baseline run",
    config={"learning_rate": 1e-3, "epochs": 10, "batch_size": 32},
)

for epoch in range(run.config.epochs):
    train_loss, val_loss, val_acc = train_and_eval()
    wandb.log({
        "epoch": epoch,
        "train/loss": train_loss,
        "val/loss": val_loss,
        "val/accuracy": val_acc,
    })

wandb.finish()
```

### Media, Histograms, and Tables

```python
wandb.log({"examples": [wandb.Image(img) for img in images]})
wandb.log({"gradients": wandb.Histogram(gradients)})
wandb.log({"conf_mat": wandb.plot.confusion_matrix(
    probs=None, y_true=y_true, preds=preds, class_names=class_names
)})

table = wandb.Table(columns=["id", "prediction", "ground_truth"], data=rows)
wandb.log({"predictions": table})
```

### Hyperparameter Sweeps

Supported `method` values: `"bayes"`, `"grid"`, `"random"`. Add `early_terminate` with `"hyperband"` to prune poor trials early.

```python
sweep_config = {
    "method": "bayes",
    "metric": {"name": "val/accuracy", "goal": "maximize"},
    "parameters": {
        "learning_rate": {"distribution": "log_uniform_values", "min": 1e-5, "max": 1e-1},
        "batch_size": {"values": [16, 32, 64, 128]},
        "dropout": {"distribution": "uniform", "min": 0.1, "max": 0.5},
    },
    "early_terminate": {
        "type": "hyperband",
        "min_iter": 3,
        "s": 2,
        "eta": 3,
        "max_iter": 27,
    },
}

sweep_id = wandb.sweep(sweep_config, project="my-project")

def train():
    run = wandb.init()
    for epoch in range(27):
        val_acc = train_one_epoch(run.config)
        wandb.log({"val/accuracy": val_acc, "epoch": epoch})

wandb.agent(sweep_id, function=train, count=50)
```

### Artifacts and Model Registry

```python
# Log dataset or model artifact
artifact = wandb.Artifact(
    name="resnet50-model",
    type="model",
    metadata={"architecture": "ResNet50", "accuracy": 0.95},
)
artifact.add_file("model.pth")
wandb.log_artifact(artifact, aliases=["best", "production"])

# Link to Model Registry
run.link_artifact(artifact, "model-registry/production-models")

# Consume in another run
downloaded_dir = run.use_artifact("resnet50-model:latest").download()
```

### Framework Integrations

- **HuggingFace Transformers**: `TrainingArguments(output_dir="./results", report_to="wandb", run_name="bert-ft", logging_steps=100)`
- **PyTorch Lightning**: `Trainer(logger=WandbLogger(project="lightning-demo", log_model=True), max_epochs=10)`
- **Keras**: `model.fit(..., callbacks=[WandbCallback()])` (from `wandb.keras`)

---

## MLflow (`mlflow`)

### Install and Tracking Server

```bash
pip install mlflow
# With SQLAlchemy / S3 extras:
pip install "mlflow[extras]"

# Local UI (http://localhost:5000)
mlflow ui

# Production tracking server
mlflow server \
  --backend-store-uri postgresql://user:password@localhost/mlflow \
  --default-artifact-root s3://my-bucket/mlflow \
  --host 0.0.0.0 \
  --port 5000
```

Configure clients via `export MLFLOW_TRACKING_URI=http://localhost:5000` or `mlflow.set_tracking_uri("http://localhost:5000")`.

### Tracking API & Autologging

```python
import mlflow

mlflow.set_experiment("sentiment-analysis")

# Automatic logging (or per-framework: mlflow.sklearn.autolog(), mlflow.pytorch.autolog(),
# mlflow.keras.autolog(), mlflow.xgboost.autolog(), mlflow.transformers.autolog())
mlflow.autolog()

with mlflow.start_run(run_name="resnet50-lr0.001-bs32"):
    mlflow.log_params({"learning_rate": 0.001, "batch_size": 32, "epochs": 50})
    mlflow.set_tags({"dataset": "ImageNet", "gpu": "A100", "git_commit": commit_sha})

    for epoch in range(50):
        mlflow.log_metrics({"train_loss": train_loss, "val_accuracy": val_acc}, step=epoch)

    mlflow.log_artifact("model.pkl")
    mlflow.log_artifacts("plots")
    mlflow.log_dict({"lr": 0.001}, "config.json")
    mlflow.pytorch.log_model(model, "model", registered_model_name="my-classifier")
```

### Model Registry (Aliases & Stages)

MLflow 2.8+ favors **aliases** (`@champion`, `@challenger`) over legacy stages (`Staging`, `Production`, `Archived`).

```python
from mlflow.tracking import MlflowClient
import mlflow.pyfunc

client = MlflowClient()

# Register an existing run's model
mlflow.register_model(f"runs:/{run_id}/model", "my-classifier")

# Modern approach: Aliases
client.set_registered_model_alias(name="my-classifier", alias="champion", version="5")
champion = mlflow.pyfunc.load_model("models:/my-classifier@champion")

# Legacy approach: Stages
client.transition_model_version_stage(
    name="my-classifier", version=3, stage="Production", archive_existing_versions=True
)
prod_model = mlflow.pyfunc.load_model("models:/my-classifier/Production")

# Annotate & tag versions
client.update_model_version(name="my-classifier", version="5", description="ResNet50 95% acc")
client.set_model_version_tag(name="my-classifier", version="5", key="validation_status", value="approved")
```

### Searching Runs & Serving Models

```python
experiment_id = client.get_experiment_by_name("sentiment-analysis").experiment_id
runs = client.search_runs(
    experiment_ids=[experiment_id],
    filter_string="metrics.accuracy > 0.9 AND params.model = 'ResNet50'",
    order_by=["metrics.accuracy DESC"],
    max_results=10,
)
```

```bash
# Local REST serving
mlflow models serve -m "models:/my-classifier@champion" -p 5001

# Test endpoint
curl http://127.0.0.1:5001/invocations -H 'Content-Type: application/json' \
  -d '{"inputs": [[1.0, 2.0, 3.0, 4.0]]}'
```

---

## TensorBoard (`tensorboard`)

### Install and Launch

```bash
pip install tensorboard
tensorboard --logdir=runs
# Open http://localhost:6006
```

### PyTorch `SummaryWriter`

```python
from torch.utils.tensorboard import SummaryWriter
from torchvision.utils import make_grid

with SummaryWriter("runs/resnet50_lr0.001") as writer:
    writer.add_graph(model, dummy_input)

    for epoch in range(50):
        writer.add_scalar("Loss/train", train_loss, epoch)
        writer.add_scalars("Accuracy", {"train": train_acc, "val": val_acc}, epoch)

        if epoch % 5 == 0:
            for name, param in model.named_parameters():
                writer.add_histogram(name, param, epoch)
                if param.grad is not None:
                    writer.add_histogram(f"{name}.grad", param.grad, epoch)

        if epoch % 10 == 0:
            writer.add_image("Batch/inputs", make_grid(images[:16], nrow=4), epoch)

    writer.add_embedding(embeddings, metadata=labels, label_img=label_imgs, global_step=50)
    writer.add_hparams({"lr": 0.001, "bs": 32}, {"hparam/accuracy": final_acc})
    writer.add_pr_curve("PR_curve/class_0", y_true == 0, probs[:, 0], global_step=50)
    writer.add_text("Summary", "| Metric | Value |\n|---|---|\n| Acc | 0.95 |", 50)
```

### TensorFlow / Keras & Performance Profiling

```python
import tensorflow as tf

tb_cb = tf.keras.callbacks.TensorBoard(
    log_dir="logs/fit",
    histogram_freq=1,
    write_graph=True,
    profile_batch="10,20",  # Profile batches 10-20 in the Profile tab
)
model.fit(x_train, y_train, validation_data=(x_val, y_val), epochs=10, callbacks=[tb_cb])
```

PyTorch Profiler integration:

```python
import torch.profiler as profiler

with profiler.profile(
    activities=[profiler.ProfilerActivity.CPU, profiler.ProfilerActivity.CUDA],
    on_trace_ready=profiler.tensorboard_trace_handler("./runs/profiler"),
    record_shapes=True,
    with_stack=True,
) as prof:
    for batch in train_loader:
        train_step(batch)
        prof.step()
```

---

## SwanLab (`swanlab`)

### Install and Modes

```bash
pip install "swanlab>=0.7.11" "pillow>=9.0.0" "soundfile>=0.12.0"
# Add local dashboard support for mode="local" and `swanlab watch`
pip install "swanlab[dashboard]>=0.7.11"

swanlab login
# Self-hosted: swanlab.login(api_key=os.environ["SWANLAB_API_KEY"], host="http://your-server:5092")
```

### Tracking, Media, and Local Mode

```python
import numpy as np
import swanlab

run = swanlab.init(
    project="image-classification",
    experiment_name="resnet18-seed42",
    tags=["baseline", "resnet18"],
    mode="local",        # Omit or use "cloud" for managed/self-hosted upload
    logdir="./swanlog",
    config={"learning_rate": 3e-4, "batch_size": 64, "epochs": 20},
)

for epoch in range(run.config.epochs):
    swanlab.log({"train/loss": train_loss, "val/loss": val_loss}, step=epoch)

# Multimodal media & custom ECharts
swanlab.log({
    "examples/image": swanlab.Image(img_uint8, caption="Sample"),
    "examples/audio": swanlab.Audio(wave_f32, sample_rate=16000),
    "examples/text": swanlab.Text("Notes"),
    "examples/video": swanlab.Video("predictions.gif"),
    "examples/point_cloud": swanlab.Object3D(xyz_f32),
    "examples/molecule": swanlab.Molecule.from_smiles("CCO", caption="Ethanol"),
})
run.finish()
```

```bash
# View local logs or sync them later
swanlab watch -l ./swanlog
swanlab sync ./swanlog
```

### Framework Integrations

- **HuggingFace Transformers**: `TrainingArguments(..., report_to="swanlab", run_name="bert-finetune")`
- **PyTorch Lightning**: `from swanlab.integration.pytorch_lightning import SwanLabLogger`
- **Fastai**: `from swanlab.integration.fastai import SwanLabCallback`

---

## Shared Best Practices & Gotchas

- **Group metric namespaces**: Use `"train/loss"` and `"val/loss"` consistently instead of mixing flat and nested names.
- **Avoid per-batch logging bloat**: Log epoch metrics every epoch and batch metrics every N steps (e.g., `batch_idx % 100 == 0`) to prevent huge event files or network throttling.
- **Always close/finish runs**: Use `with mlflow.start_run():`, `with SummaryWriter(...) as writer:`, or `wandb.finish()` / `run.finish()` so buffered metrics and artifacts flush before exit.
- **Offline-first on unstable clusters**: Use `WANDB_MODE=offline` + `wandb sync`, or SwanLab `mode="local"` + `swanlab sync`, rather than letting network timeouts stall training.
