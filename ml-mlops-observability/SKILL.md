---
name: ml-mlops-observability
description: >
  Use when setting up or debugging ML experiment tracking, hyperparameter sweeps,
  model registries, training profiling, or LLM application observability. Covers
  Weights & Biases (wandb), MLflow, TensorBoard, SwanLab, LangSmith, and Arize
  Phoenix (OpenTelemetry/OpenInference tracing, span evaluation, dataset regression).
  Triggers on 'wandb', 'mlflow', 'tensorboard', 'swanlab', 'langsmith', 'phoenix',
  'arize-phoenix', 'experiment tracking', 'model registry', 'sweep', 'LLM tracing'.
---

# ML Ops & Observability

Two focused references, one per domain. Open only the reference the task needs;
do not preload all.

| Task / Tool | Read |
|---|---|
| Experiment tracking, hyperparameter sweeps, artifacts, profiling, model registry (`wandb`, `mlflow`, `tensorboard`, `swanlab`) | [Experiment tracking reference](references/experiment-tracking.md) |
| LLM tracing, OpenTelemetry/OpenInference spans, LLM-as-judge evals, prompt/dataset regression (`langsmith`, `arize-phoenix`) | [LLM observability reference](references/llm-observability.md) |

## What each covers

- **Experiment tracking** — tool selection across W&B, MLflow, TensorBoard, and
  SwanLab; scalar/media/histogram logging, Bayesian/Hyperband sweeps, MLflow
  model registry aliases (`@champion`) and REST serving, PyTorch/TF profiling,
  and local/offline sync workflows.
- **LLM observability** — LangSmith (`@traceable`, `wrap_openai`, `evaluate()`,
  Hub prompts, pytest/CI regression gates) and Arize Phoenix (`phoenix.otel.register`,
  OpenInference instrumentors, `run_evals`, `run_experiment`, self-hosted Postgres).

## Universal rules

- Prefer environment variables (`WANDB_API_KEY`, `MLFLOW_TRACKING_URI`,
  `LANGSMITH_API_KEY`, `PHOENIX_SQL_DATABASE_URL`, `SWANLAB_API_KEY`) over
  hardcoding credentials or tracking endpoints in source files.
- Always close or flush loggers at run end (`wandb.finish()`, `with mlflow.start_run():`,
  `with SummaryWriter(...) as w:`, `run.finish()`, or `force_flush()` for short-lived
  OTel scripts) so buffered metrics and spans are not dropped.
- Log epoch metrics every epoch and batch metrics at intervals (e.g., every 100
  steps) to avoid event-file bloat and network throttling.
- Redact PII, secrets, and oversized payloads before tracing (`process_inputs` in
  LangSmith; selective span attributes in OpenTelemetry).
- Use offline/local modes (`WANDB_MODE=offline`, SwanLab `mode="local"`) on
  air-gapped or unstable clusters, then sync after training completes.
- Verify that tracking servers, endpoints, and database connections are reachable
  before launching long jobs; never assume traces or artifacts landed without
  checking the run ID or server response.
