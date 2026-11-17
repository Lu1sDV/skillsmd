# ds-specialized-ml

Consolidated skill for specialized machine learning domains: time series &
survival analysis, reinforcement learning, and multi-objective optimization &
quantum circuits. [SKILL.md](SKILL.md) is a short orchestrator that routes to
three independently readable references, loaded only when the task needs them:

- [references/time-series-survival.md](references/time-series-survival.md) —
  time series ML with `aeon` (classification, regression, clustering, DTW,
  STOMP), zero-shot forecasting with `timesfm` (2.5 Apache-2.0 vs 3.0
  non-commercial, XReg), and right-censored/competing-risk survival analysis
  with `scikit-survival`.
- [references/reinforcement-learning.md](references/reinforcement-learning.md)
  — single-agent RL with `stable-baselines3` (PPO, SAC, DQN, TD3,
  `VecNormalize`, callbacks, custom envs) and high-throughput vectorization /
  `PuffeRL` with `pufferlib` (3.0.0, 4.0, and native 5.0 profiles).
- [references/optimization-quantum.md](references/optimization-quantum.md) —
  single/multi/many-objective optimization with `pymoo` (NSGA-II/III, MOEA/D,
  constraints, MCDM) and differentiable quantum circuits / QML / VQE / QAOA with
  `pennylane`.

## Install and use

Copy the complete `ds-specialized-ml/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ds-specialized-ml ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ds-specialized-ml@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ds-specialized-ml
```

Examples:
- "Build a leakage-safe `scikit-survival` CoxPH pipeline and evaluate Uno's C-index and IBS."
- "Run zero-shot quantile forecasting with `timesfm` 2.5 on a regular-grid CSV."
- "Train a `stable-baselines3` PPO agent with `VecNormalize` and evaluate with frozen stats."
- "Solve a constrained 5-objective problem with `pymoo` NSGA-III and Das-Dennis directions."

## Sources and adaptation

Condensed on 2026-11-16 from seven upstream skills in
[K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills)
(MIT, commit `ec59a29a03d5c40f73ab40878df04860bc00e876`, see
[LICENSE.upstream](LICENSE.upstream)):

- `skills/aeon/SKILL.md`
- `skills/timesfm-forecasting/SKILL.md`
- `skills/scikit-survival/SKILL.md`
- `skills/stable-baselines3/SKILL.md`
- `skills/pufferlib/SKILL.md`
- `skills/pymoo/SKILL.md`
- `skills/pennylane/SKILL.md`

These references are condensed derivatives, not vendored copies. Overlapping
workflows and upstream boilerplate were deduplicated into three domain-grouped
guides while preserving core APIs, version pins, decision matrices, and
gotchas.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks (`check_static_smells.py`). Commands and Python APIs target
the consumer's Python/GPU environment and were not executed live here.
