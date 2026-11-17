# ds-stats-bayesian

Consolidated skill for frequentist/econometric modeling, Bayesian inference,
experimental design, power analysis, and hypothesis testing. [SKILL.md](SKILL.md)
is a short orchestrator that routes to two independently readable references,
loaded only when the task needs them:

- [references/statistical-modeling.md](references/statistical-modeling.md) —
  model selection, diagnostics, robust SEs, and ARIMA/SARIMAX in `statsmodels`
  (0.15.0), plus the 8-step `pymc` (6.3.2) + `arviz` (1.3.0) Bayesian workflow
  (priors, predictive checks, NUTS diagnostics, PSIS-LOO, and VI caveats).
- [references/hypothesis-power-design.md](references/hypothesis-power-design.md) —
  pre-collection experimental design and DOE (`pydoe` 1.5.0), closed-form and
  simulation-based power/sample-size planning, Pingouin (0.7.0) hypothesis
  testing, assumption-check rules, effect sizes with CIs, and APA reporting.

## Install and use

Copy the complete `ds-stats-bayesian/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ds-stats-bayesian ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ds-stats-bayesian@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ds-stats-bayesian
```

Examples:
- "Fit a Negative Binomial or Zero-Inflated model in statsmodels and check for overdispersion."
- "Build a hierarchical PyMC model with prior/posterior predictive checks and compare models via PSIS-LOO."
- "Calculate required sample size per group for a cluster-randomized trial with 20% attrition and an ICC of 0.05."
- "Run a Welch t-test with signed Cohen's d, 95% CI, assumption checks, and an APA-formatted summary."

## Sources and adaptation

Condensed on 2026-11-16 from five upstream skills in
[K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills)
(MIT, commit `ec59a29a03d5c40f73ab40878df04860bc00e876`, see
[LICENSE.upstream](LICENSE.upstream)):

- `skills/experimental-design/SKILL.md`
- `skills/pymc/SKILL.md`
- `skills/statistical-analysis/SKILL.md`
- `skills/statistical-power/SKILL.md`
- `skills/statsmodels/SKILL.md`

These references are condensed derivatives, not vendored copies. Overlapping
workflows and boilerplate from the upstream skill files were deduplicated into
two domain-grouped guides while preserving core APIs, version pins, decision
matrices, and statistical guardrails.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks (`check_static_smells.py`). Commands and Python APIs target
the consumer's scientific Python environment and were not executed live here.
