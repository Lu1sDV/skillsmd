# Statistical & Bayesian Modeling: statsmodels & PyMC

Guide to frequentist/econometric modeling (`statsmodels`) and probabilistic Bayesian modeling (`pymc` + `arviz`).

## Tool Selection

| Need | Library | Key Strengths |
|---|---|---|
| Frequentist regression, GLMs, discrete choice, econometrics, ARIMA/SARIMAX | `statsmodels` (0.15.0) | Closed-form/MLE inference, `.summary()`, HC/HAC/cluster SEs, marginal effects, state-space forecasting |
| Hierarchical models, custom generative likelihoods, full posterior uncertainty, PSIS-LOO | `pymc` (6.3.2) + `arviz` (1.3.0) | NUTS MCMC, named `dims` + xarray `DataTree`, prior/posterior predictive checks, partial pooling |

---

## statsmodels (0.15.0)

```bash
uv pip install statsmodels==0.15.0 numpy==2.5.3 scipy==1.18.1 pandas==3.0.6 matplotlib==3.11.2 scikit-learn==1.9.1
```

- **Imports**: Use `import statsmodels.api as sm` and `import statsmodels.formula.api as smf` for standard models; use direct module imports for newer/specialized classes (e.g., `HurdleCountModel`).
- **0.15 API updates**: Pass `result_object=True` and access named fields for ADF/KPSS and transitioning tests; prefer `rng=` over deprecated `seed` or `random_state`.

### Model Selection by Outcome & Structure

| Outcome / Structure | Models | Key Notes |
|---|---|---|
| Continuous linear | `OLS`, `WLS`, `GLS`, `GLSAR`, `QuantReg`, `MixedLM` | Use `MixedLM` for clustered/repeated units; `QuantReg` for conditional quantiles |
| Generalized linear | `GLM(..., family=sm.families.<Family>(link=...))` | Families: `Gaussian`, `Binomial`, `Poisson`, `NegativeBinomial`, `Gamma`, `InverseGaussian` |
| Binary / Ordinal / Multinomial | `Logit`, `Probit`, `MNLogit`, `ConditionalLogit`, `OrderedModel` | `OrderedModel` and `ConditionalLogit` **must not** receive a constant |
| Count & excess zeros | `Poisson`, `NegativeBinomial`, `ZeroInflatedPoisson`, `ZeroInflatedNegativeBinomialP`, `HurdleCountModel` | Check dispersion before choosing NB over Poisson; audit zero mechanism before ZIP/Hurdle |
| Time series | `ARIMA`, `SARIMAX`, `VAR`, `VARMAX`, `ExponentialSmoothing`, `DynamicFactor` | `ARIMA` models integration via `d`—do not difference manually and again inside `ARIMA` |

### Data Preparation & Design Rules

1. **Intercept handling**: Array-based `OLS`/`GLM`/`Logit` require an explicit `sm.add_constant(X)`; formula models (`smf.ols("y ~ x", data)`) include one by default. When predicting on a new array lacking an intercept (including a single new row), pass `sm.add_constant(X_new, has_constant="add")` so design columns match training.
2. **Missing values**: Array models default to `missing="none"`, which does not check NaNs and can yield all-NaN estimates. Pass `missing="raise"` during construction; if dropping rows, record retained row IDs and compare models on identical observations. Fit imputation and scaling on training data only.
3. **Validation splits**: Match sampling design—grouped splits for repeated units, chronological splits for time series.

### Core Workflows

**1. Linear Regression & Diagnostics**
```python
import statsmodels.api as sm
from statsmodels.stats.outliers_influence import variance_inflation_factor

X = sm.add_constant(X_train)
res = sm.OLS(y_train, X, missing="raise").fit()
print(res.summary())

# Robust SEs for heteroskedasticity (HC3), autocorrelation (HAC), or clusters
robust = res.get_robustcov_results(cov_type="HC3")
# Cluster-robust: res.get_robustcov_results(cov_type="cluster", groups=cluster_ids)

# Multicollinearity (VIF)
vifs = [variance_inflation_factor(X.values, i) for i in range(X.shape[1])]
```
- Check residual vs. fitted, Q-Q plot, heteroskedasticity (Breusch-Pagan), autocorrelation (Ljung-Box / Durbin-Watson), and influence (Cook's distance, leverage).

**2. Binary & Count Models**
- **Binary**: Fit `sm.Logit(y, X).fit()`; check convergence warnings; compute odds ratios (`np.exp(res.params)`) and marginal effects (`res.get_margeff().summary()`); evaluate out-of-sample AUC/calibration.
- **Counts**: Fit `Poisson` -> test overdispersion -> if overdispersed, fit `NegativeBinomial` -> if excess zeros remain, compare `ZIP`/`ZINB`/`HurdleCountModel` via AIC on identical rows; interpret `np.exp(beta)` as rate ratios.

**3. Time Series (ARIMA / SARIMAX)**
1. Plot series; test stationarity with ADF/KPSS (`result_object=True`). Do not treat failure to reject a unit root as proof of non-stationarity.
2. Select deterministic terms and differencing `d` from domain context, plots, and tests; inspect ACF/PACF for candidate `(p, q)`.
3. Fit `ARIMA`/`SARIMAX`, check residual Ljung-Box diagnostics, and generate forecasts with future exogenous inputs and model-based prediction intervals.

### statsmodels Gotchas

- **Model comparison**: AIC/BIC are valid only for comparable likelihoods on the exact same response and rows. Regular nested-model LR tests require interior parameters and valid likelihood assumptions (invalid on boundary/non-nested comparisons).
- **Uncertainty targets**: A GLM interval for the conditional mean omits future outcome noise; state-space forecasts include model-based forecast error.

---

## PyMC (6.3.2) & ArviZ (1.3.0)

```bash
uv pip install "pymc==6.3.2" "pytensor==3.3.2" "arviz==1.3.0" matplotlib pandas h5netcdf h5py
```

- **ArviZ 1.x API**: `import arviz as az` re-exports base/stats/plots. PyMC returns an xarray `DataTree` (despite legacy `return_inferencedata` naming).
  - `az.summary(idata, round_to="none", ci_prob=0.95)` returns numeric columns (default formats for display; ArviZ 1.x defaults to 89% intervals).
  - `az.hdi(idata, prob=0.95)` uses `prob=` with bounds along `ci_bound`.
  - Plotting: use `az.plot_ppc_dist`, `az.plot_dist` (`az.plot_posterior` was removed in 1.x), and `az.plot_trace_dist`; save their returned `PlotCollection`, not a separate `pyplot` figure.
- **Backend note**: If PyTensor C compilation fails (e.g., macOS linker errors), `PYTENSOR_FLAGS="cxx="` disables C compilation for the process.

### Distribution & Prior Conventions

| Outcome / Parameter | Recommended Distribution | Notes |
|---|---|---|
| Continuous outcome | `pm.Normal` or `pm.StudentT` | Calibrate scale to outcome units; Student-t for heavy tails |
| Count outcome | `pm.Poisson` or `pm.NegativeBinomial` | Audit zero-generating mechanism before adding hurdle/zero-inflation |
| Binary outcome | `pm.Bernoulli(..., logit_p=...)` | Keep priors plausible on probability scale, especially under separation |
| Positive scales | `pm.HalfNormal`, `pm.Exponential`, `pm.Gamma` | Domain-specific scales; broad priors are not automatically noninformative |
| Covariance matrices | `pm.LKJCholeskyCov` | Ordinary `dims` labels do not align PyTensor math |

### 8-Step Bayesian Workflow

1. **Define estimand & predictive unit** (new measurement, unseen group, or future time block). Fit scaling on training data only; reject constant columns.
2. **Build generative model** with named `dims` and `coords`, scientifically calibrated priors, and `pm.Data` containers for mutable inputs. Check likelihood support, finite initial log-probability, design rank, and symmetries.
3. **Prior predictive check**: `pm.sample_prior_predictive()` before fitting; verify domain plausibility.
4. **Sample**: Fit multiple independent chains with explicit `random_seed`. Use `nuts_sampler="pymc"` for reproducible backend selection (auto-selection may pick installed `nutpie`); pass sampler options via `nuts={...}` (replaces deprecated `nuts_sampler_kwargs`).
5. **Diagnose MCMC**: Inspect rank R-hat (`< 1.01`), pooled bulk/tail ESS (`>= 400` screening floor, not a universal precision target), estimand-specific MCSE, divergences, energy BFMI (`< 0.3` warning), and `reached_max_treedepth`. Fix model geometry (e.g., centered vs. non-centered parameterization—neither is universally superior) and initialization before increasing draws.
6. **Posterior predictive check**: `pm.sample_posterior_predictive()`; inspect residual structure, tails, zeros, group effects, and time dependence.
7. **Sensitivity & recovery**: Check prior sensitivity and synthetic parameter recovery. Correlated parameters, separated logistic data, or mixture label switching can pass standard MCMC diagnostics while remaining unidentifiable.
8. **Out-of-sample prediction**: Update `pm.Data` with `pm.set_data(...)` and call `pm.sample_posterior_predictive(..., predictions=True)` to store in `predictions` (separate from in-sample `posterior_predictive`). For unseen groups in hierarchical models, draw group effects from every hyperposterior draw rather than using only population means.

### Model Comparison, LOO & Variational Inference

```python
# Compute pointwise log-likelihood while training data is still in the model
with model:
    pm.compute_log_likelihood(idata, model=model)  # idata_kwargs={"log_likelihood": True} is deprecated in 6.3.2

cmp = az.compare({"m1": idata_1, "m2": idata_2})  # Ranks PSIS-LOO ELPD; no ic= argument in ArviZ 1.x
```
- **PSIS-LOO**: Check each LOO result's `good_k` (Pareto-k) diagnostic; refit influential holdouts or use structured CV when needed. WAIC is not a remedy for failed PSIS diagnostics.
- **Validity**: Comparisons require identical outcomes, ordering, scale, likelihood measure, and predictive unit. Stacking weights are predictive combination weights, **not posterior model probabilities**.
- **Model averaging**: Sample a predictive mixture with shape `(sample, *prediction_dims)` preserving within- and between-model variation; pointwise averages of paired posterior draws are not mixture draws.
- **Variational Inference (`pm.fit`)**: Approximations can miss modes and underestimate uncertainty; finite ELBO and high ESS on approximation draws do not prove posterior accuracy. Validate against MCMC on a representative subset.
