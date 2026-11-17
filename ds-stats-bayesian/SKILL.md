---
name: ds-stats-bayesian
description: >
  Use when fitting regression, econometric, or time-series models (statsmodels
  OLS, GLM, Logit, Poisson/NB, ARIMA/SARIMAX), building Bayesian hierarchical or
  MCMC models (PyMC, ArviZ, PSIS-LOO), designing experiments (randomization,
  blocking, factorial/DOE, response-surface), calculating statistical power and
  sample sizes, or running hypothesis tests with assumption checks, effect
  sizes, and APA reporting (Pingouin, SciPy). Triggers on 'statsmodels',
  'pymc', 'arviz', 'pingouin', 'OLS', 'GLM', 'ARIMA', 'NUTS', 'PSIS-LOO',
  'power analysis', 'sample size', 'MDE', 'experimental design', 'DOE',
  'pseudoreplication', 'Cohen d', or 'APA report'.
---

# Statistical Modeling, Bayesian Inference & Experimental Design

Two capabilities, one reference each. Open only the reference the task needs;
do not preload all.

| Task / Tool | Read |
|---|---|
| Regression, GLMs, discrete choice, time series (`statsmodels`) and Bayesian modeling, NUTS MCMC, diagnostics, PSIS-LOO (`pymc`, `arviz`) | [Statistical modeling reference](references/statistical-modeling.md) |
| Experimental design & DOE (`pydoe`), a priori / simulation power & MDE, hypothesis testing, assumption checks, effect sizes & APA reporting (`pingouin`, `scipy`) | [Hypothesis, power & design reference](references/hypothesis-power-design.md) |

## What each covers

- **Statistical modeling** — Model selection, intercept/missing-data rules, HC3/HAC/cluster SEs, VIF, ARIMA/SARIMAX, and `statsmodels` 0.15.0 pitfalls; plus the 8-step `pymc` 6.3.2 + `arviz` 1.3.0 Bayesian workflow (priors, prior/posterior predictive checks, R-hat/ESS/BFMI/divergences, `pm.Data` predictions, PSIS-LOO `az.compare`, VI caveats).
- **Hypothesis, power & design** — Fisher's design principles, randomization/blocking, factorial/CCD/screening DOE (`pydoe` 1.5.0), closed-form & Monte Carlo power with attrition/clustering/multiplicity adjustments, Pingouin 0.7.0 test selection, assumption-check rules, effect sizes with CIs, and APA reporting.

## Universal rules

- Define the estimand, independent experimental unit, and sampling structure before touching data; match the analysis model to blocking, clustering, and nesting to avoid pseudoreplication.
- Never compute post-hoc ("observed") power; report sensitivity analyses (MDE at achieved $n$) and effect-size CIs instead.
- Never switch statistical tests automatically at a diagnostic p-value threshold (Shapiro-Wilk / Levene); inspect raw plots and prespecify robust defaults (e.g., Welch `correction=True`, HC3).
- In `statsmodels`, pass `missing="raise"` on array models, keep training/prediction design columns identical (`has_constant="add"`), and omit constants from `OrderedModel` and `ConditionalLogit`.
- In `pymc` + `arviz`, run prior and posterior predictive checks, inspect rank R-hat/ESS/MCSE/divergences/BFMI before trusting estimates, and compute log-likelihoods while training data is loaded in the model.
- Report effect sizes with 95% CIs, exact p-values (or posterior probabilities), assumption checks, missing-data handling, and multiplicity corrections for all planned analyses.
