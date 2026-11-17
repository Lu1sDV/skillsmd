# Model Explainability (SHAP) & Graph Analysis (NetworkX)

Actionable reference for auditing predictive models with `shap 0.52.0` and
building/analyzing networks with `networkx 3.7`.

---

## 1. Model Explainability with SHAP (`shap 0.52.0`)

### Environment & Operating Rules

```bash
uv venv --python 3.12 && source .venv/bin/activate
uv pip install "shap[plots]==0.52.0"  # SHAP 0.52.0 requires Python >=3.12
```

1. **Explain a fixed, evaluated model** on held-out or labeled analysis rows; choose background rows only from an appropriate training or reference population.
2. **State the exact explained output** (regression value, raw margin, probability, log loss, logit). Never infer units from plot color or sign.
3. **Prefer `shap.Explanation` via `explainer(X)`.** Use `.shap_values(X)` only when specialized options require it (e.g., deep ranked outputs, Kernel SHAP `nsamples`).
4. **Verify additivity** (`base_values + values.sum(axis=1)`) against the exact model output before interpreting or plotting.
5. **Non-causal scope:** SHAP describes model behavior under a masking/background choice; it never establishes causality, fairness, recourse, or scientific mechanism.
6. **Security:** Do not deserialize untrusted `pickle`, `joblib`, model, or explainer files.

### Explainer & Masker Selection Matrix

| Model / Data | Explainer | Key Constraints & Masker Behavior |
|---|---|---|
| Tree ensemble (XGBoost, LightGBM, CatBoost, sklearn) | `TreeExplainer` / `algorithm="tree"` | `model_output="probability"` or `"log_loss"` requires `feature_perturbation="interventional"` + background data; `feature_perturbation="auto"` switches to interventional when `data` is supplied |
| Linear model | `LinearExplainer` | Masker choice (`Independent` vs. `Partition` / correlated) controls interventional vs. correlation-aware behavior |
| Small feature space | `ExactExplainer` | Exact Shapley values; cost scales exponentially with unconstrained feature count |
| General tabular callable | `PermutationExplainer` / `algorithm="permutation"` | Budget `max_evals >= 2 * n_features + 1` (one full forward/reverse pass); set `seed` |
| Hierarchical groups, text, image | `PartitionExplainer` | Uses `shap.maskers.Text(tokenizer)` or `shap.maskers.Image(...)`; partition tree defines the cooperative game |
| Differentiable neural net | `DeepExplainer` / `GradientExplainer` | Framework-specific support, output shape, and background choice require runtime validation |
| Legacy fallback | `KernelExplainer` | Weighted linear regression; much slower than model-specific explainers |

### Modern `Explanation` Pattern & Multi-Output Slicing

```python
import numpy as np
import shap

# Explicit masker retains all 200 rows (bare DataFrame is capped at 100 by default)
background = shap.sample(X_train, 200, random_state=7)
masker = shap.maskers.Independent(background, max_samples=len(background))

explainer = shap.TreeExplainer(
    model,
    data=masker,
    feature_perturbation="interventional",
    model_output="probability",
)
all_outputs = explainer(X_test)  # shape: (samples, features, outputs) for multi-output

# Resolve target class via model.classes_ before indexing; never use pre-0.45 values[class_idx]
target_idx = list(model.classes_).index(positive_label)
pos_exp = all_outputs[..., target_idx]

# Mandatory additivity check
reconstructed = np.asarray(pos_exp.base_values) + pos_exp.values.sum(axis=1)
expected = model.predict_proba(X_test)[:, target_idx]
np.testing.assert_allclose(reconstructed, expected, rtol=1e-5, atol=1e-6)
```

- **0.52.0 gotchas:**
  - Pass `approximate=True` to `explainer(X, approximate=True)`, **not** to the constructor.
  - `shap.Explainer(model.predict_proba, masker, algorithm="permutation", output_names=...)` may drop `output_names` in `0.52.0` selector dispatch; re-assign `all_outputs.output_names` explicitly and slice with integer index rather than `exp[..., "name"]`.
  - Never average signed attributions across classes.

### Visualization Selection Matrix

| Question | Plot Call |
|---|---|
| Largest average attribution magnitude | `shap.plots.bar(exp, max_display=15)` |
| Global direction, magnitude, and feature values | `shap.plots.beeswarm(exp, max_display=15)` |
| Single prediction breakdown from baseline | `shap.plots.waterfall(exp[i], max_display=15)` |
| Feature attribution vs. feature value (dependence) | `shap.plots.scatter(exp[:, "feature_name"])` |
| Sample-level clustering of explanations | `shap.plots.heatmap(exp)` |
| Descriptive cohort comparison | `shap.plots.bar(exp.cohorts(labels).abs.mean(0))` |
| Token or image-region attributions | `shap.plots.text(exp)` / `shap.plots.image(exp)` |

### Troubleshooting Order

1. Print Python, `shap`, model-library, and `numpy` versions.
2. Confirm `X_test` has the exact transformed columns, order, `dtype` (e.g., `float32` for sklearn forests), and missing-value encoding used at fit time.
3. Inspect `values.shape`, `base_values.shape`, `data.shape`, `feature_names`, and `output_names`.
4. Verify selected output index and units (`raw` vs. `probability` vs. `log_loss`).
5. Recompute `model.predict` / `predict_proba` on the same rows in the same order and test a smaller batch/background.

---

## 2. Graph & Network Analysis with NetworkX (`networkx 3.7`)

### Environment & Removed Legacy APIs

```bash
uv pip install "networkx==3.7"  # Requires Python >=3.12 (excluding 3.14.1)
```

- **Removed pre-3.0/3.4 APIs:** `nx.info`, `nx.write_gpickle`, `nx.read_shp`, and `nx.random_tree` (use `nx.random_labeled_tree(n, seed=...)`) do not exist in 3.7.
- **Graph classes:** `nx.Graph` (undirected), `nx.DiGraph` (directed), `nx.MultiGraph` / `nx.MultiDiGraph` (parallel edges). All four allow self-loops; repeated `G.add_edge(u, v, weight=...)` **overwrites** attributes rather than summing parallel observations.

### Core Graph Construction, Algorithms & Scientific Contracts

```python
import networkx as nx
from networkx.algorithms import community

G = nx.Graph()
G.add_weighted_edges_from([(1, 2, 1.0), (2, 5, 1.0), (1, 5, 5.0)], weight="distance")

# Shortest paths & betweenness treat weights as distances/costs (strictly positive for betweenness)
path = nx.shortest_path(G, source=1, target=5, weight="distance")
bc = nx.betweenness_centrality(G, weight="distance")
pr = nx.pagerank(G, weight=None)  # unweighted topology

# Community detection (optimizes modularity; not a statistical significance test)
comms = community.greedy_modularity_communities(G, weight=None)
```

- **Distance vs. similarity weights:** Shortest-path and weighted-betweenness algorithms treat larger edge weights as **higher cost** (less favorable). Convert similarity, correlation, or interaction strength to a positive distance before running path/betweenness algorithms.
- **Connectivity:** `nx.is_connected(G)` and `nx.connected_components(G)` apply only to nonempty undirected graphs; use `nx.is_strongly_connected` / `nx.strongly_connected_components` / `nx.weakly_connected_components` for `DiGraph`.
- **Node/edge deletion:** Removing a node (`G.remove_node(u)`) automatically removes all incident edges; nodes can be any hashable object except `None`.
- **Scientific caveats:** Centrality is conditional on observed topology and weight model. Test seed/resolution sensitivity and compare against domain-justified null ensembles rather than assuming a generated preferential-attachment model proves a power law.

### Generators, I/O & Matrix Round-Trips

```python
import numpy as np
import pandas as pd

# Synthetic networks (always set seed)
er = nx.erdos_renyi_graph(n=100, p=0.1, seed=42)
ba = nx.barabasi_albert_graph(n=100, m=3, seed=42)
ws = nx.watts_strogatz_graph(n=100, k=6, p=0.1, seed=42)
tree = nx.random_labeled_tree(100, seed=42)

# JSON node-link format: NetworkX 3.6+ uses edges="edges" (older files may use "links")
data = nx.node_link_data(G, edges="edges")
G2 = nx.node_link_graph(data, edges="edges")

# DataFrame edge list (keep a separate node table so isolates survive import)
G_df = nx.from_pandas_edgelist(df, "source", "target", edge_attr="weight")

# Dense NumPy round-trip preserving node order, direction, and zero weights
nodes = list(G)
A = nx.to_numpy_array(G, nodelist=nodes, nonedge=np.nan)
H = nx.from_numpy_array(A, nodelist=nodes, create_using=type(G), nonedge=np.nan)

# SciPy sparse round-trip (sums parallel-edge weights; relabel indices back to nodes)
S = nx.to_scipy_sparse_array(G, nodelist=nodes)
H_sp = nx.relabel_nodes(nx.from_scipy_sparse_array(S, create_using=type(G)), dict(enumerate(nodes)))
```

- **GraphML:** `nx.read_graphml` / `nx.write_graphml` support scalar attributes and read node IDs as strings by default.
- **Performance & backends:** For large sparse graphs, use SciPy sparse arrays, approximate centrality (`k=` sample parameter), or dispatchable backends via `backend=` / `nx.config.backend_priority` (verify backend support for graph type, weights, and seeds).

### Visualization Quick Pattern

```python
import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(10, 7))
pos = nx.spring_layout(G, seed=42)  # alternatives: kamada_kawai_layout, circular_layout, spectral_layout
node_sizes = [300 + 2000 * bc[n] for n in G.nodes()]
nx.draw(G, pos=pos, ax=ax, node_size=node_sizes, with_labels=True, edge_color="gray")
ax.set_axis_off()
fig.savefig("network.pdf", bbox_inches="tight")
```
