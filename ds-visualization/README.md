# ds-visualization

Consolidated skill for scientific and statistical plotting with Matplotlib and
Seaborn, plus publication-ready figure design, accessibility, and export
verification. [SKILL.md](SKILL.md) is a short orchestrator that routes to two
independently readable references, loaded only when the task needs them:

- [references/plotting-libraries.md](references/plotting-libraries.md) — OO
  Matplotlib (3.11+ layouts, colormaps/norms, 3D, gotchas) and Seaborn (0.13.2
  function & `objects` APIs, `errorbar`, faceting, statistical & missing-data
  caveats).
- [references/publication-figures.md](references/publication-figures.md) —
  integrity guardrails, honest encodings, colorblind-safe/WCAG palettes, exact
  physical sizing, font embedding, Plotly 7/Kaleido 1.4.0 static export, and
  post-export inspection.

## Install and use

Copy the complete `ds-visualization/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ds-visualization ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ds-visualization@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ds-visualization
```

Examples:
- "Build a 2x2 constrained-layout Matplotlib figure with shared diverging colorbar normalization."
- "Plot longitudinal subject trajectories and group summary intervals in Seaborn 0.13.2 without pseudoreplication."
- "Prepare an 89 mm single-column Nature-style PDF/TIFF figure with Okabe-Ito colors and Type 42 fonts."

## Sources and adaptation

Condensed on 2026-11-16 from three upstream skills in
[K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills)
(MIT, commit `ec59a29a03d5c40f73ab40878df04860bc00e876`, see
[LICENSE.upstream](LICENSE.upstream)):

- `skills/matplotlib/SKILL.md`
- `skills/seaborn/SKILL.md`
- `skills/scientific-visualization/SKILL.md`

These references are condensed derivatives, not vendored copies. Overlapping
workflows and boilerplate from the upstream skill files were deduplicated into
two domain-grouped guides while preserving core APIs, version-specific flags,
statistical caveats, and export checklists.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks (`check_static_smells.py`). Plotting commands and Python APIs
target the consumer's Python environment and were not executed live here.
