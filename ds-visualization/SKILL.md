---
name: ds-visualization
description: >
  Use when creating static scientific or statistical plots with Matplotlib or
  Seaborn, or designing, styling, auditing, and exporting publication-ready
  figures (including Plotly/Kaleido static export). Triggers on 'matplotlib',
  'seaborn', 'seaborn.objects', 'subplot_mosaic', 'TwoSlopeNorm', 'errorbar',
  'publication figure', 'journal figure', 'Okabe-Ito', 'WCAG contrast',
  'pdf.fonttype', 'Kaleido', or 'figure export'.
---

# Data Science & Scientific Visualization

Two capabilities, one reference each. Open only the reference the task needs;
do not preload all.

| Task / Tool | Read |
|---|---|
| Plotting APIs & statistical graphics: Matplotlib (3.11+ OO API, layouts, colormaps/norms, 3D) and Seaborn (0.13.2 function & `objects` APIs, `errorbar`, faceting, stats caveats) | [Plotting libraries reference](references/plotting-libraries.md) |
| Publication figures: integrity guardrails, honest encodings, colorblind/WCAG accessibility, exact physical sizing, font embedding, Plotly/Kaleido export, and post-export audit | [Publication figures reference](references/publication-figures.md) |

## What each covers

- **Plotting libraries** — OO Matplotlib (`Figure`/`Axes`, `layout="constrained"`, `subplot_mosaic`, `GridSpec`), Matplotlib 3.11 API updates (`tick_labels`, `mpl.colormaps`), shared normalization, Seaborn 0.13.2 tidy data workflows, `errorbar` / `native_scale` / `hue` changes, `seaborn.objects`, and repeated-measures / KDE / missing-gap caveats.
- **Publication figures** — Non-negotiable data-integrity rules, 6-step figure design workflow, redundant & colorblind-safe encodings (Okabe-Ito, Paul Tol, WCAG 2.2), millimeter sizing, Type 42 / SVG font settings, RGB TIFF alpha handling, Plotly 7 / Kaleido 1.4.0 static export, and post-export inspection.

## Universal rules

- Use Matplotlib's object-oriented API (`fig, ax = plt.subplots(...)`) with `layout="constrained"` for production code; never call `tight_layout()` after constrained layout.
- Share both `cmap` and `norm`/`vmin`/`vmax` across comparable heatmaps; handle zero/negative/missing values explicitly before `LogNorm`.
- Preserve missing-data gaps rather than bridging across excluded observations silently, and state the uncertainty metric (`sd`, `se`, `ci`), `n`, and independent sampling unit.
- Never rely on color alone; pair color with markers, line styles, hatching, direct labels, or facets.
- Omit `bbox_inches="tight"` when exact physical page dimensions are required, close figures with `plt.close(fig)` in batch loops, and inspect the actual exported file at final size.
