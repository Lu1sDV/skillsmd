# ml-mlops-observability

Consolidated MLOps experiment tracking and LLM observability skill.
[SKILL.md](SKILL.md) is a short orchestrator that routes to two independently
readable references, loaded only when the task needs them:

- [references/experiment-tracking.md](references/experiment-tracking.md) —
  Weights & Biases, MLflow, TensorBoard, and SwanLab: scalar/media logging,
  hyperparameter sweeps, PyTorch/TF profiling, artifacts, and model registries.
- [references/llm-observability.md](references/llm-observability.md) —
  LangSmith and Arize Phoenix: OpenTelemetry/OpenInference tracing, span
  evaluation, LLM-as-judge evaluators, and dataset/prompt regression testing.

## Install and use

Copy the complete `ml-mlops-observability/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-mlops-observability ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-mlops-observability@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-mlops-observability
```

Examples:
- "Set up a W&B Bayesian sweep with Hyperband early termination for my PyTorch trainer."
- "Register my model in MLflow with a @champion alias and serve it locally."
- "Instrument my OpenAI and LangChain app with Arize Phoenix OpenTelemetry tracing and run a hallucination eval."

## Sources and adaptation

Condensed from six upstream skills in
[Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)
(MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`, see
[LICENSE.upstream](LICENSE.upstream)):

- `13-mlops/mlflow/SKILL.md` (plus `references/model-registry.md` for MLflow 2.8+ aliases)
- `13-mlops/weights-and-biases/SKILL.md` (plus `references/sweeps.md` for Hyperband early termination)
- `13-mlops/tensorboard/SKILL.md`
- `13-mlops/swanlab/SKILL.md`
- `17-observability/langsmith/SKILL.md` (plus `references/advanced-usage.md` for `RunTree` and distributed headers)
- `17-observability/phoenix/SKILL.md` (plus `references/advanced-usage.md` for OTel propagation and sessions)

Validation: static skill-smell check (`check_static_smells.py`) and local
markdown link verification.
