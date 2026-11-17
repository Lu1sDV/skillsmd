# Plotting Libraries: Matplotlib & Seaborn

Guide to creating static scientific and statistical plots with Matplotlib (3.11+) and Seaborn (0.13.2).

## Library & Interface Selection

| Need | Use | Interface |
|---|---|---|
| Fine-grained layout, novel/3D plots, exact physical sizing, publication assembly | **Matplotlib** | Object-oriented (`fig, ax = plt.subplots(...)`) |
| Quick interactive exploration | **Matplotlib** | `pyplot` state machine (`plt.plot(...)`) |
| Tidy DataFrame statistical plots, facets, CI/SD estimation | **Seaborn** | Function interface (axes-level `sns.scatterplot` or figure-level `sns.relplot`) |
| Composable layered grammar-of-graphics plots | **Seaborn** | `seaborn.objects` (`so.Plot(...).add(...)`) — experimental in 0.13.2 |

---

## Matplotlib (3.11+)

```bash
uv add "matplotlib==3.11.2" numpy scipy
# For Jupyter interactive widgets (%matplotlib widget):
uv add "matplotlib==3.11.2" ipympl
```

### Backends & Batch Execution

- Headless/file output needs no GUI: set `MPLBACKEND=Agg` or select `Agg` before importing `pyplot`.
- Interactive windows require a GUI toolkit (`PySide6` for `QtAgg`, or `TkAgg`); `plt.ioff()` does not remove GUI thread requirements.
- In batch loops, save with `fig.savefig(...)` before `show()`, then call `plt.close(fig)` to prevent memory leaks.

### Object-Oriented Hierarchy & Layouts

Hierarchy: **Figure** (canvas) -> **Axes** (plot region) -> **Artist** (lines, text, ticks) / **Axis** (number lines & ticks).

```python
import matplotlib.pyplot as plt
import numpy as np

fig, ax = plt.subplots(figsize=(10, 6), layout="constrained")
x = np.linspace(0, 2 * np.pi, 100)
ax.plot(x, np.sin(x), linewidth=2, label="sin(x)")
ax.set(xlabel="x", ylabel="y", title="Sine Wave")
ax.legend()
ax.grid(True, alpha=0.3)
fig.savefig("plot.png", dpi=300, bbox_inches="tight", facecolor="white")
plt.close(fig)
```

**Multi-panel layouts:**

```python
# 1. Regular grid
fig, axes = plt.subplots(2, 2, figsize=(12, 10), layout="constrained")
axes[0, 0].plot(x, y1)

# 2. Mosaic layout (named panels)
fig, axes = plt.subplot_mosaic(
    [["left", "right_top"], ["left", "right_bottom"]],
    figsize=(10, 8),
    layout="constrained",
)
axes["left"].plot(x, y)

# 3. GridSpec (arbitrary spans)
from matplotlib.gridspec import GridSpec
fig = plt.figure(figsize=(12, 8), layout="constrained")
gs = GridSpec(3, 3, figure=fig)
ax1 = fig.add_subplot(gs[0, :])
ax2 = fig.add_subplot(gs[1:, 0])
ax3 = fig.add_subplot(gs[1:, 1:])
```

### Core Plot Types & 3.11 API Notes

```python
ax.plot(x, y, linewidth=2, linestyle="--", marker="o", color="steelblue")
ax.scatter(x, y, s=sizes, c=colors, alpha=0.6, cmap="viridis")
ax.bar(categories, values, color="steelblue", edgecolor="black")  # or ax.barh
ax.hist(data, bins=30, edgecolor="black", alpha=0.7)

# Heatmaps / matrices
im = ax.imshow(matrix, cmap="viridis", aspect="auto", interpolation="nearest")
fig.colorbar(im, ax=ax, label="Intensity (unit)")

# Contours (label contour lines rather than contourf in 3.11+)
cs = ax.contour(X, Y, Z, levels=10)
ax.clabel(cs, inline=True, fontsize=8)

# Box & violin plots (Matplotlib 3.11 uses tick_labels & orientation)
ax.boxplot([d1, d2, d3], tick_labels=["A", "B", "C"], orientation="vertical")
ax.violinplot([d1, d2, d3], positions=[1, 2, 3])

# 3D plots
ax3d = fig.add_subplot(111, projection="3d")
ax3d.plot_surface(X, Y, Z, cmap="viridis")
```

### Styling, Colormaps & Annotations

```python
plt.style.use("seaborn-v0_8-darkgrid")  # list all: plt.style.available
plt.rcParams.update({"font.size": 12, "axes.labelsize": 14, "axes.titlesize": 16})

ax.annotate(
    "Peak", xy=(x0, y0), xytext=(x0 + 1, y0 + 1),
    arrowprops=dict(arrowstyle="->", color="red"),
)
```

- **Colormaps** (`mpl.colormaps[name]`): sequential (`viridis`, `cividis`, `plasma`), diverging (`coolwarm`, `RdBu_r`), qualitative (`tab10`, `Set3`). Avoid `jet` (not perceptually uniform).
- **Normalization**: For comparable heatmaps, share both `cmap` and `norm`/`vmin`/`vmax`. Use `mpl.colors.TwoSlopeNorm(vmin, vcenter, vmax)` for asymmetric diverging data; `LogNorm` requires strictly positive values (handle zero/negative/missing values explicitly).

### Matplotlib Gotchas & Scientific Checks

1. **Layout engines**: Prefer `layout="constrained"`. Never call `tight_layout()` afterward — it disables constrained layout.
2. **Physical dimensions**: `figsize` is in inches (`pixels = dpi * inches`). `bbox_inches="tight"` crops to artist bounds and alters final physical dimensions; omit it (and set `savefig.bbox=None` in `mpl.rc_context`) when exact dimensions are required.
3. **Uncertainty args**: `ax.errorbar` takes nonnegative error **sizes** (asymmetric shape `(2, N)`, lower errors first); `ax.fill_between` takes lower/upper **endpoints**. Compute SD/SEM/CI upstream and state `n` and sampling unit.
4. **Missing data & distributions**: Preserve gaps rather than interpolating/connecting silently. Boxplot whiskers default to `1.5 * IQR`; Matplotlib 3.11 ignores masked/nonfinite observations in violin plots — count and disclose excluded values.
5. **Vector file size**: Pass `rasterized=True` on dense scatter/mesh artists when exporting PDF/SVG.

---

## Seaborn (0.13.2)

```bash
uv pip install "seaborn==0.13.2"
# With optional scipy/statsmodels for regression/clustering:
uv pip install "seaborn[stats]==0.13.2"
```

```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import seaborn.objects as so
```

### Data Structure

Prefer **long-form (tidy)** DataFrames (one column per variable, one row per observation, retaining `subject`/replicate IDs). Convert wide-form data with `melt`:

```python
df_long = df.reset_index(names="subject").melt(
    id_vars="subject", var_name="condition", value_name="measurement"
)
```

For offline or regulated work, load local files with pandas rather than `sns.load_dataset()` (which fetches unversioned CSVs from `mwaskom/seaborn-data`).

### Plot Selection & Axes-Level vs Figure-Level

| Task | Axes-level (`ax=ax`) | Figure-level (manages figure/facets) |
|---|---|---|
| Relationships | `scatterplot`, `lineplot` | `relplot(kind="scatter" \| "line")` |
| Distributions | `histplot`, `kdeplot`, `ecdfplot`, `rugplot` | `displot(kind="hist" \| "kde" \| "ecdf")` |
| Categorical | `boxplot`, `violinplot`, `stripplot`, `swarmplot`, `barplot`, `pointplot`, `boxenplot` | `catplot(kind=...)` |
| Regression | `regplot` | `lmplot` |
| Matrices / Pairwise | `heatmap` | `clustermap`, `pairplot`, `jointplot` |

- Use **axes-level** functions (`ax=ax`) inside custom Matplotlib multi-panel figures.
- Use **figure-level** functions (`col="group", col_wrap=3`) for automatic faceting; customize via the returned `FacetGrid`/`PairGrid`/`JointGrid` (`g.set_axis_labels(...)`, `g.savefig(...)`).

### 0.12 / 0.13 API Changes & Gotchas

- **Keyword arguments required**: `sns.scatterplot(data=df, x="x", y="y", hue="group", size="val", style="type")`.
- **`errorbar` replaces `ci`**: Use `errorbar="sd"`, `errorbar="se"`, `errorbar=("pi", 95)`, or `errorbar=("ci", 95)` in `lineplot`, `barplot`, and `pointplot`. (`regplot` and `lmplot` still use `ci`.)
- **Categorical scale**: Pass `native_scale=True` to keep numeric or datetime categories on their true scale instead of ordinal positions.
- **Deprecated `palette` without `hue`**: Assign a redundant hue (`hue="day", legend=False`) instead of passing `palette` alone.
- **Renamed parameters**:
  - `violinplot(density_norm=..., common_norm=...)` (not `scale`/`scale_hue`)
  - `boxenplot(width_method=...)` (not `scale`)
  - `barplot(err_kws=...)` (not `errcolor`/`errwidth`)

### `seaborn.objects` (Declarative API)

```python
(
    so.Plot(data=df, x="total_bill", y="tip")
    .add(so.Dot(), color="day")
    .add(so.Line(), so.PolyFit(order=1))
)
```

Note: `seaborn.objects` is still marked experimental/incomplete upstream in 0.13.2; prefer the function interface for conservative production code unless composition materially simplifies the plot.

### Statistical & Missing-Data Caveats

- **Repeated measurements**: Row-wise bootstrap CIs and fixed `seed=` do not correct pseudoreplication. For individual trajectories, use `units="subject", estimator=None, errorbar=None`. For aggregate intervals, bootstrap at the independent sampling unit upstream and plot explicitly.
- **Line gaps**: `lineplot` drops missing rows and bridges across gaps; split contiguous observed segments when gaps are scientifically meaningful.
- **KDE boundary bias**: Gaussian KDEs can bleed past physical bounds (e.g., negative concentrations). `cut=0` and `clip` only trim drawing, not boundary bias; use `ecdfplot` or a histogram when boundaries matter, and check sensitivity to `bw_adjust`.
- **Observation weights**: Weighted `lineplot`/`barplot`/`pointplot` require finite, nonnegative weights with a positive sum in every group (only mean + bootstrap CI or no error bars supported in 0.13.2).
