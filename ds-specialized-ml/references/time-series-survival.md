# Time Series ML, Zero-Shot Forecasting & Survival Analysis

Guide to temporal machine learning (`aeon`), zero-shot foundation forecasting (`timesfm`), and right-censored / competing-risk survival analysis (`scikit-survival`).

## Tool Selection

| Task | Tool | Core Strength | Key Caveat |
|---|---|---|---|
| **TS classification / regression / clustering** | `aeon` | Scikit-learn-compatible (`Rocket`, `HIVECOTEV2`, `TimeSeriesKMeans`, DTW) | Collection shape is `(n_cases, n_channels, n_timepoints)`; `forecasting`, `anomaly_detection`, `segmentation`, `similarity_search` are experimental in 1.x |
| **Zero-shot time-series forecasting** | `timesfm` | Pretrained 200M (2.5, Apache-2.0) & 330M (3.0, non-commercial) quantile forecasters + XReg | Regular time grid required; never `dropna()` internal gaps; 3.0 weights are non-commercial/non-production |
| **Right-censored & competing-risk survival** | `scikit-survival` | CoxPH, Coxnet, RSF, GBDT, Survival SVM, IPCW metrics, nonparametric CIF | No Fine-Gray regression; `ipcwls` GBDT has known defects; GPL-3.0-or-later upstream |

---

## aeon (`aeon==1.6.0`, Python 3.11–3.14)

```bash
uv pip install "aeon==1.6.0"
uv pip install "aeon[all_extras]==1.6.0"   # optional extras; stumpy for matrix profiles, TensorFlow for DL
```

Note: `prts` range precision/recall/F-score metrics conflict with NumPy 2+ in `aeon` 1.6; use AUC metrics instead.

### Data Format & Preprocessing
- **Collections**: `(n_cases, n_channels, n_timepoints)`. Single series: `(n_channels, n_timepoints)` with `axis=1`.
- **Normalization**: `Normalizer()` (per-series z-norm) removes amplitude/level—skip when amplitude carries signal.
- **Imputation**: `SimpleImputer(strategy="mean")` before fitting.
- **Splitting**: Split chronologically for forecasting/overlapping windows and by subject/group for repeated measurements.

### Core Estimators

| Task | Fast Prototyping | High Accuracy | Interpretable |
|---|---|---|---|
| **Classification** | `MiniRocketClassifier`, `RocketClassifier`, `Arsenal` | `HIVECOTEV2`, `InceptionTimeClassifier` | `ShapeletTransformClassifier`, `Catch22Classifier` |
| **Regression** | `MiniRocketRegressor`, `RocketRegressor` | `InceptionTimeRegressor` | — |
| **Clustering** | `TimeSeriesKMeans(n_clusters=3, distance="dtw", averaging_method="ba")` | `AEFCNClusterer`, `AEResNetClusterer` | — |
| **Small datasets** | `KNeighborsTimeSeriesClassifier(n_neighbors=5, distance="dtw", distance_params={"window": 0.2})` | — | — |

```python
from aeon.classification.convolution_based import RocketClassifier
from aeon.transformations.collection import Normalizer
from aeon.datasets import load_classification
from sklearn.pipeline import Pipeline

X_train, y_train = load_classification("GunPoint", split="train")
X_test, y_test = load_classification("GunPoint", split="test")

pipe = Pipeline([("norm", Normalizer()), ("clf", RocketClassifier(n_kernels=10000))])
pipe.fit(X_train, y_train)
acc = pipe.score(X_test, y_test)
```

### Feature Extraction, Distances & Experimental Modules
- **Feature extractors** (feed into any `sklearn` model): `Rocket()`, `Catch22()`, `TSFresh`.
- **Distances** (`aeon.distances`): Elastic (`dtw`, `ddtw`, `wdtw`, `erp`, `edr`, `lcss`, `twe`, `msm`), Lock-step (`euclidean`, `manhattan`, `minkowski`), Shape-based (`shape_dtw`, `sbd`). Functions: `dtw_distance(x, y, window=0.1)`, `dtw_pairwise_distance(X)`.
- **Forecasting (experimental)**: `NaiveForecaster(strategy="drift", horizon=5).fit(y).predict(y)` returns a single value at `horizon`. `ARIMA(p=1, d=1, q=1).iterative_forecast(y, prediction_horizon=5)` uses explicit `p/d/q` (not `order=`).
- **Anomaly detection / Segmentation / Similarity search (experimental)**:
  - `STOMP(window_size=50).fit_predict(y)` (requires `stumpy`; higher score = more anomalous).
  - `ClaSPSegmenter().fit_predict(y)` returns change-point indices.
  - `MASS(length=20, normalize=True).fit(X_train).predict(query, k=3, X_index=(0, 0))` returns `(indices, distances)` excluding self-match.

---

## TimesFM Zero-Shot Forecasting (`timesfm==3.0.2`, Python 3.10+)

```bash
uv pip install "timesfm[torch]==3.0.2" numpy pandas
# Optional CPU XReg: install jax + scikit-learn (Python 3.12+ for current JAX); avoid [xreg] extra on macOS (requests jax[cuda])
```

### Checkpoint Selection & License Boundary

| Checkpoint | API | Quantile Output | Weight License |
|---|---|---|---|
| **2.5 (200M)** (default) | `timesfm.TimesFM_2p5_200M_torch`, `compile()`, `forecast()` | Mean + 9 deciles `(B, H, 10)`, median at index `5` | **Apache-2.0** |
| **3.0 (~330M)** | `timesfm3.TimesFM3Forecaster`, `predict()` / `predict_batch()` | 9 deciles, median at index `4` | **Non-commercial, non-production only** |

### TimesFM 2.5 Workflow & Gotchas

```python
import numpy as np
import timesfm

model = timesfm.TimesFM_2p5_200M_torch.from_pretrained(
    "google/timesfm-2.5-200m-pytorch",
    revision="1d952420fba87f3c6dee4f240de0f1a0fbc790e3",
    torch_compile=False,
)
model.compile(timesfm.ForecastConfig(
    max_context=512,
    max_horizon=128,
    per_core_batch_size=1,
    normalize_inputs=True,
    use_continuous_quantile_head=True,
    force_flip_invariance=True,
    infer_is_positive=False,      # True ONLY if target is strictly nonnegative by domain
    fix_quantile_crossing=True,
))

histories = [np.sin(np.linspace(0, 20, 200)).astype(np.float32)]
point, q = model.forecast(horizon=24, inputs=list(histories))  # pass fresh list; 2.5 may append dummy series
# q[..., 1], q[..., 9] = q10-q90 (nominal 80% PI); q[..., 2], q[..., 8] = q20-q80 (nominal 60% PI)
```

- **Device**: Loader auto-selects `cuda:0` or CPU (MPS is not enabled); do not call `model.to(...)`.
- **Context & horizon limits**: Compile positive explicit values (`0` does not mean max). Keep patch-rounded `context + horizon <= 16384` and `horizon <= 1024` with continuous quantile head.
- **Regular grid**: Sort and deduplicate timestamps; never `dropna()` internal gaps (distorts spacing). Impute only inside training history, never from held-out future targets.
- **Quantile calibration**: Monotonic quantiles (`fix_quantile_crossing=True`) are **nominal**, not calibrated. Evaluate across rolling origins with per-origin preprocessing and compare against seasonal-naive baselines.
- **XReg covariates (2.5)**: Compile with `return_backcast=True`, align covariates over context + horizon. `"xreg + timesfm"` fits regression on targets then forecasts residuals; `"timesfm + xreg"` forecasts first then fits regression on backcast residuals (needs `> 32` observations).

---

## scikit-survival (`scikit-survival==0.28.0`, Python 3.11+)

```bash
uv pip install "scikit-survival==0.28.0" "scikit-learn>=1.9.0,<1.10" "numpy>=2.0.0" "pandas>=2.2.0" "scipy>=1.13.0" "osqp>=1.0.2" "narwhals>=2.0.1"
```

Note: `0.28.0` adds pandas/Polars support via `narwhals` and removes `criterion` from `GradientBoostingSurvivalAnalysis`. Upstream package is **GPL-3.0-or-later**.

### Outcome Construction & Leakage-Safe Pipeline

```python
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sksurv.linear_model import CoxPHSurvivalAnalysis
from sksurv.util import Surv

# Field 1 MUST be boolean (True=event, False=right-censored); Field 2 is float time
y = Surv.from_dataframe("event", "time", frame)  # or Surv.from_arrays(event=ev, time=t)

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, stratify=y["event"], random_state=42
)

preprocess = ColumnTransformer(
    [
        ("num", make_pipeline(SimpleImputer(strategy="median"), StandardScaler()), numeric),
        ("cat", make_pipeline(SimpleImputer(strategy="most_frequent"),
                              OneHotEncoder(handle_unknown="ignore", drop="first", sparse_output=False)), categorical),
    ],
    sparse_threshold=0.0,
)
model = make_pipeline(preprocess, CoxPHSurvivalAnalysis(alpha=0.1, ties="efron"))
model.fit(X_train, y_train)
```

### Model Selection

| Estimator | Use Case | Key Notes |
|---|---|---|
| `CoxPHSurvivalAnalysis(alpha=0.1, ties="efron")` | Interpretable log-hazard ratios | Ridge penalty `alpha`; assumes proportional hazards |
| `CoxnetSurvivalAnalysis(l1_ratio=..., fit_baseline_model=True)` | High-dimensional LASSO / elastic-net | Set `fit_baseline_model=True` to get survival/hazard functions |
| `IPCRidge` | IPC-weighted ridge AFT | `predict()` returns original-time predictions, **not** Cox risk scores |
| `RandomSurvivalForest` / `ExtraSurvivalTrees` | Nonlinear ensemble | Use **permutation importance**, not impurity importance |
| `GradientBoostingSurvivalAnalysis(loss="coxph")` | Boosted survival | Avoid `loss="ipcwls"` (known log-time validation & gradient-weight defects) |
| `FastSurvivalSVM` / `FastKernelSurvivalSVM` | Ranking / regression | Only `rank_ratio=1` directly outputs higher-is-riskier scores; no survival probabilities |

### Prediction & Metric Contracts

```python
import numpy as np
from sksurv.metrics import (
    brier_score, concordance_index_ipcw, cumulative_dynamic_auc, integrated_brier_score
)

# 1. Rank discrimination (higher = higher risk)
risk = model.predict(X_test)
uno_c = concordance_index_ipcw(y_train, y_test, risk, tau=times[-1])[0]
auc_t, mean_auc = cumulative_dynamic_auc(y_train, y_test, risk, times)

# 2. Probability error (requires (n_test, n_times) survival probabilities)
surv_fns = model.predict_survival_function(X_test)
surv_prob = np.vstack([fn(times) for fn in surv_fns])
_, brier_t = brier_score(y_train, y_test, surv_prob, times)
ibs = integrated_brier_score(y_train, y_test, surv_prob, times)
```

- **Always pass `y_train`** to IPCW metrics so censoring distributions are estimated on training data only.
- **Evaluation time grid `times`**: Strictly increasing, inside test follow-up, and below the end of training support where estimated censoring survival remains positive.
- **Hyperparameter tuning**: `as_concordance_index_ipcw_scorer(model, tau=tau)` is an **estimator wrapper**, not a `scoring=` callable; prefix tuned params with `estimator__` and use nested CV for unbiased estimates.
- **Competing risks**: `cumulative_incidence_competing_risks(status, observed_time)` takes integer `status` (`0`=censored, `1..K`=causes) and returns `(time, cif)` with `cif.shape == (K + 1, n_times)` (`cif[0]`=total, `cif[1..K]`=cause-specific). Never estimate cause-specific probability with `1 - KM` while censoring competing events. (In `0.28.0`, raw total-risk CI is reversed and ignores `conf_level`; compute KM CI separately if needed.)
