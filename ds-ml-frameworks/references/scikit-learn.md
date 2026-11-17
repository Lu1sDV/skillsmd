# Scikit-learn Reference

Classical machine learning in Python (`scikit-learn >= 1.9.1`, Python 3.11+).

## Installation

Install **`scikit-learn`** (not the deprecated `sklearn` PyPI package); import as `sklearn`:

```bash
uv pip install "scikit-learn==1.9.1"
# Optional plotting/table extras
uv pip install "scikit-learn[plots]==1.9.1" matplotlib pandas numpy
```

---

## Core Workflows

### Classification & Preprocessing

Always fit scalers/imputers on training data only (`fit_transform` on train, `transform` on test) — or better, wrap them in a `Pipeline`.

```python
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, stratify=y, random_state=42
)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train_scaled, y_train)
y_pred = model.predict(X_test_scaled)
print(classification_report(y_test, y_pred))
```

### Mixed-Type Production Pipeline (`ColumnTransformer` + `Pipeline`)

Wrap all preprocessing inside `Pipeline` so each cross-validation fold refits transformers independently and avoids test leakage.

```python
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.impute import SimpleImputer
from sklearn.ensemble import GradientBoostingClassifier

numeric_features = ["age", "income"]
categorical_features = ["gender", "occupation"]

numeric_transformer = Pipeline([
    ("imputer", SimpleImputer(strategy="median")),
    ("scaler", StandardScaler()),
])

categorical_transformer = Pipeline([
    ("imputer", SimpleImputer(strategy="most_frequent")),
    ("onehot", OneHotEncoder(handle_unknown="ignore")),
])

preprocessor = ColumnTransformer([
    ("num", numeric_transformer, numeric_features),
    ("cat", categorical_transformer, categorical_features),
])

model = Pipeline([
    ("preprocessor", preprocessor),
    ("classifier", GradientBoostingClassifier(random_state=42)),
])

model.fit(X_train, y_train)
y_pred = model.predict(X_test)
```

---

## Decision & Selection Rules

### Feature Scaling

| Needs Scaling (distance/regularization/gradient sensitive) | No Scaling Required |
|---|---|
| SVM, KNN, Neural Networks (`MLPClassifier`/`Regressor`) | Tree-based models (Decision Trees, Random Forest, Gradient Boosting) |
| PCA, Ridge/Lasso/ElasticNet, Logistic Regression | `GaussianNB`; `MultinomialNB` (requires nonnegative counts/proportions) |
| K-Means, DBSCAN, Agglomerative Clustering | — |

### Data Splitting by Independent Unit

- **Independent rows (classification):** `train_test_split(..., stratify=y, random_state=42)` or `StratifiedKFold`.
- **Repeated subjects, sites, specimens, or related molecules:** `GroupKFold` or `StratifiedGroupKFold` (class stratification alone leaks groups). Apply the same grouping rule to both inner hyperparameter tuning and outer evaluation.
- **Temporal / future prediction:** Chronological split; exclude features unavailable at prediction time.

### Metric Selection

- **Balanced classes:** Accuracy, F1-score.
- **Imbalanced classes:** Per-class Precision/Recall, Average Precision (`average_precision_score`), Balanced Accuracy (`balanced_accuracy_score`); report class prevalence and decision threshold.
- **Cost-sensitive tasks:** Custom scorer via `sklearn.metrics.make_scorer`.
- **Clustering:** Inertia/elbow and silhouette analysis assess internal geometry only (not proof of scientific clusters); handle degenerate single-cluster outputs and DBSCAN `-1` noise labels explicitly.

### Large Datasets (Out-of-Core / Memory Errors)

```python
from sklearn.linear_model import SGDClassifier
from sklearn.cluster import MiniBatchKMeans

clf = SGDClassifier()
kmeans = MiniBatchKMeans(n_clusters=8, batch_size=100)
```

---

## Common Pitfalls & Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| `ConvergenceWarning` | Solver hit iteration limit or unscaled features | Scale features with `StandardScaler` inside `Pipeline` or increase `max_iter` (e.g., `LogisticRegression(max_iter=1000)`). |
| Data leakage | Calling `fit_transform` before `train_test_split` or CV | Put all imputation, scaling, encoding, and feature selection inside `Pipeline`. |
| Group leakage | Random/stratified split across repeated patients/batches | Use `GroupKFold` / `StratifiedGroupKFold` for both CV tuning and outer evaluation. |
| High-cardinality feature importance bias | Impurity-based `feature_importances_` favors high-cardinality features | Use `permutation_importance` on held-out validation data instead. |
| Overfitting / poor test score | High variance, distribution shift, or tuning on test set | Add regularization (`Ridge(alpha=1.0)`), use `cross_val_score`, and reserve test set for final evaluation only. |
