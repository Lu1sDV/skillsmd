---
name: ds-specialized-ml
description: >
  Use when building time series ML, zero-shot forecasting, or survival analysis
  workflows (aeon, TimesFM, scikit-survival), training single-agent or
  vectorized reinforcement learning policies (Stable Baselines3, PufferLib), or
  solving multi-objective optimization and variational quantum circuits (pymoo,
  PennyLane). Triggers on 'aeon', 'timesfm', 'scikit-survival', 'sksurv',
  'stable-baselines3', 'pufferlib', 'pymoo', 'pennylane', 'NSGA-II', 'NSGA-III',
  'VQE', 'QAOA', 'CoxPH', or 'time series classification'.
---

# Specialized ML: Time Series, Survival, RL, Optimization & Quantum

Three capabilities, one reference each. Open only the reference the task needs;
do not preload all.

| Task / Tool | Read |
|---|---|
| Time series ML (`aeon` classification, regression, clustering, DTW, STOMP), zero-shot forecasting (`timesfm` 2.5/3.0, XReg), and survival analysis (`scikit-survival` CoxPH, RSF, IPCW, competing-risk CIF) | [Time series & survival reference](references/time-series-survival.md) |
| Reinforcement learning: `stable-baselines3` (PPO, SAC, DQN, TD3, `VecNormalize`, callbacks, custom Gymnasium envs) and `pufferlib` (3.0/4.0/5.0 profiles, `PuffeRL`, `PufferEnv`, vectorization) | [Reinforcement learning reference](references/reinforcement-learning.md) |
| Multi/many-objective optimization (`pymoo` NSGA-II/III, MOEA/D, GA/CMA-ES, constraints, MCDM) and quantum circuits (`pennylane` QNodes, Torch/JAX QML, VQE, QAOA) | [Optimization & quantum reference](references/optimization-quantum.md) |

## What each covers

- **Time series & survival** — `aeon` (`1.6.0`) `(n_cases, n_channels, n_timepoints)` pipelines (`RocketClassifier`, `HIVECOTEV2`, `STOMP`, `ClaSPSegmenter`), `timesfm` (`3.0.2`) 2.5 Apache-2.0 vs 3.0 non-commercial checkpoints and regular-grid/XReg contracts, and `scikit-survival` (`0.28.0`) leakage-safe `Surv` pipelines, IPCW metrics, and nonparametric CIF.
- **Reinforcement learning** — `stable-baselines3` (`2.9.0`) on/off-policy algorithm selection, `DummyVecEnv`/`SubprocVecEnv`, `VecNormalize` train-vs-eval freezing, and `pufferlib` version-profile separation (`5.0` native C/CUDA vs `3.0.0` Gymnasium/PettingZoo emulation vs `4.0`).
- **Optimization & quantum** — `pymoo` (`0.6.2`) unified `minimize()` with `g(x) <= 0` constraint checks, Das-Dennis reference-direction budgeting for `NSGA3`, and `pennylane` (`0.45.1`) analytic QNode gradient checks, `qml.set_shots`, `qml.cond`, `.resources` inspection, and chemistry/QAOA sign conventions.

## Universal rules

- Pin environment versions explicitly and separate conflicting stacks (e.g., `pufferlib==3.0.0` requires NumPy `<2` and Gymnasium `<=0.29.1`, whereas `aeon 1.6`, `scikit-survival 0.28`, `pymoo 0.6.2`, and `pennylane 0.45.1` use NumPy `2+`).
- Never fit preprocessing, imputation, normalization (`Normalizer`, `VecNormalize`), or censoring distributions (`y_train` in IPCW) on held-out evaluation data; freeze `training=False, norm_reward=False` on `VecNormalize` during evaluation.
- Preserve temporal and censoring semantics: never `dropna()` internal timestamps in regular-grid forecasting, never use `1 - KM` for competing-risk CIF, and never bootstrap across episode `truncated` vs `terminated` boundaries.
- Verify output contracts before downstream use: check `res.CV` feasibility in `pymoo`, quantile monotonicity/shapes in `timesfm`, and analytic/finite-diff gradients on small `default.qubit` circuits in `pennylane` before scaling up.
- Never load untrusted `.pkl`, `.pt`, or `.bin` checkpoints without verifying source and SHA-256 checksums, and never hardcode W&B/API keys in configs or CLI flags.
