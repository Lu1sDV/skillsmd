# Publication-Ready Scientific Figures

Workflow, integrity guardrails, accessibility, color management, Plotly/Kaleido static export, and post-export verification for scientific figures.

## Non-Negotiable Integrity Guardrails

- Never alter, hide, invent, or selectively enhance data to improve a figure.
- Preserve raw tables/images, exclusions, missing-value codes, analysis code, normalization, binning, image adjustments, and random seeds.
- Do not infer journal requirements: identify the exact publisher/journal, article type, figure type, and submission phase, and verify its live official guidance before submission.
- Do not claim that a palette, DPI value, format, or automated check certifies accessibility or journal compliance.
- Do not silently connect missing observations, suppress inconvenient points, upsample images as if detail increased, or tune dual axes to exaggerate correlation.
- Keep interactive and static outputs as distinct deliverables; hover tooltips do not replace labels, alt text, keyboard access, data tables, or static fallbacks.

---

## 6-Step Publication Workflow

### 1. Define Evidence & Destination

Record before coding:
- Audience & medium (manuscript, web, slide, poster, supplement) and intended final width (e.g., 89 mm single column, 183 mm double column).
- Target journal, article type, figure type, and submission phase (mark choices pending verification if unknown).
- Variable semantics, units, sample/replicate structure (`n`, independent sampling unit), missing/censored codes, estimator/uncertainty definition, and all transformations.

### 2. Choose an Honest Encoding

Prefer position on a common scale. Verify:
- **Bars/areas**: Include zero baseline (length/area encodes magnitude from zero).
- **Points/lines**: Nonzero limits can be valid; show context and disclose axis breaks.
- **Uncertainty**: Name SD, SE, CI, percentile, or posterior interval; state `n` and sampling unit. Show raw observations when feasible without obscuring structure.
- **Missing data**: Distinguish missing, zero, censored, and excluded; render gaps or explicit model/interpolation styling.
- **Area/volume**: Scale area/volume, never radius/diameter; avoid decorative 3D.
- **Log axes**: Label base/transform and declare how zero/negative values are handled.
- **Binning/smoothing/normalization**: Record bin edges, bandwidth/window, formula/reference, and keep normalization limits consistent across compared panels.
- **Dual axes**: Prefer aligned stacked panels; if unavoidable, justify units explicitly.
- **Images**: Preserve originals, disclose whole-image adjustments, include scale bars, and avoid clipped/erased backgrounds.

### 3. Design Accessibility In

- **Redundant encoding**: Combine color with marker shape, line style, hatching, direct labels, or faceting — never rely on color alone.
- **Semantic palettes**:
  - Qualitative: Okabe-Ito (`#E69F00`, `#56B4E9`, `#009E73`, `#F0E442`, `#0072B2`, `#D55E00`, `#CC79A7`, `#000000`) or Paul Tol palettes.
  - Sequential: `viridis`, `cividis`, `plasma` (avoid `jet`/rainbow).
  - Diverging: `RdBu_r`, `coolwarm` with a meaningful center.
- **Missing / out-of-range values**: Make explicit, e.g.:
  ```python
  cmap = mpl.colormaps["RdBu_r"].with_extremes(bad="#777777")
  ```
- **WCAG 2.2 web contrast targets**: `>= 4.5:1` for normal text, `>= 3:1` for large text, `>= 3:1` for graphical objects required for understanding. Check grayscale separation as a screen, not as a substitute for full color-vision testing.
- **Web delivery**: Provide alt text, longer descriptions for complex figures, and underlying data tables.

### 4. Implement with Scoped Styles & Exact Physical Sizing

Use Matplotlib's OO API with scoped `rc_context` or `.mplstyle` files (quote hex colors in `.mplstyle`, e.g., `"#0072B2"`, so `#` is not parsed as a comment):

```python
import matplotlib as mpl
import matplotlib.pyplot as plt

# 89 mm single-column width converted to inches
with mpl.rc_context({"savefig.bbox": None, "font.size": 8}):
    fig, ax = plt.subplots(figsize=(89 / 25.4, 60 / 25.4), layout="constrained")
    norm = mpl.colors.TwoSlopeNorm(vmin=-2, vcenter=0, vmax=5)
    cmap = mpl.colormaps["RdBu_r"].with_extremes(bad="#777777")
    im = ax.imshow(values, norm=norm, cmap=cmap, interpolation="nearest")
    fig.colorbar(im, ax=ax, label="Change (unit)")
```

- Use `layout="constrained"` for colorbars, `GridSpec`, subfigures, and `subplot_mosaic`; never call `tight_layout()` afterward.
- Omit `bbox_inches="tight"` when exact physical page dimensions matter.
- Use `LogNorm`, `CenteredNorm`, `SymLogNorm`, `BoundaryNorm`, or `TwoSlopeNorm` only when the transform matches scientific meaning.

#### Plotly (7.x) + Kaleido (1.4.0) Static Export Notes

- Use `fig.write_html()` for interactive output and `fig.write_image()` / `plotly.io.write_images()` for static export.
- **Kaleido 1.4.0 requires Chrome/Chromium** installed on the host (it no longer bundles Chrome).
- **Plotly 7 breaking changes**: Removes `engine=`, Orca, Kaleido `<1`, and `plotly.io.kaleido.scope` (use `plotly.io.defaults`). Requires MathJax 3/4 (not 2).
- **Formats**: PNG, JPEG, WebP, SVG, PDF (EPS is Kaleido v0-only).
- **Vector vs WebGL**: Plotly Express may auto-select WebGL above 1,000 rows, which embeds raster content in PDF/SVG. Pass `render_mode="svg"` when vector markers are required.
- **Sizing**: `width`, `height`, and `scale` control pixel dimensions (`scale=3` is not inherently "300 DPI"). Offline exports require local MathJax/topojson/tile assets.

### 5. Export Explicitly, Embed Fonts & Record Provenance

- **Fonts**:
  - PDF/PS: set `pdf.fonttype = 42` / `ps.fonttype = 42` (TrueType) so fonts are embedded and editable.
  - SVG: `svg.fonttype = "none"` keeps text editable/searchable (appearance depends on viewer fonts); `svg.fonttype = "path"` locks glyph geometry as paths (not editable/searchable).
- **Background & Alpha**: Use an explicit opaque background (`facecolor="white"`) unless transparency is required. Matplotlib writes RGBA TIFFs even on white; when a publisher forbids alpha (e.g., RGB TIFF with LZW), flatten/convert to RGB and verify opacity before removing alpha.
- **Provenance**: Avoid implicit overwrites; write atomically and log a manifest alongside exports recording raw data paths, QC filters/transformations, uncertainty method + random seed, and missing-data handling.

### 6. Post-Export Inspection Checklist

Before submission or delivery, inspect the **actual exported file** at final print/display size:
1. File metadata: physical dimensions (MediaBox/CropBox in PDF), effective DPI, color mode (RGB/CMYK/Grayscale), alpha channel presence, ICC profile, compression, and embedded fonts.
2. Contrast & grayscale separation: readable at final scale with no disappearing lines or low-contrast labels.
3. Visual defects: no clipped tick labels, missing glyphs, overlapping legends, unreadable small text, or missing scale bars.
4. Scientific & compliance audit: raw data/code preserved, uncertainty/missingness disclosed, and live target-journal guidelines re-verified immediately before upload.
