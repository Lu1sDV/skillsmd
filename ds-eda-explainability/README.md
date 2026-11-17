# ds-eda-explainability

Consolidated skill for bounded exploratory data analysis, nonlinear
dimensionality reduction (UMAP), model explainability (SHAP), and graph/network
analysis (NetworkX). [SKILL.md](SKILL.md) is a short orchestrator that routes to
two independently readable references, loaded only when the task needs them:

- [references/eda-and-dim-reduction.md](references/eda-and-dim-reduction.md) —
  bounded local EDA safety contracts, scientific format inspection, leakage/outlier
  audits, and `umap-learn 0.5.12` (tuning, HDBSCAN clustering, supervised/semi-supervised,
  `Pipeline` gotchas, densMAP, ParametricUMAP, AlignedUMAP).
- [references/explainability-and-graphs.md](references/explainability-and-graphs.md) —
  `shap 0.52.0` (`Explanation` API, explainer/masker matrix, interventional tree
  probabilities, multi-output slicing, additivity checks, plot selection) and
  `networkx 3.7` (graph types, distance-weight semantics, centrality, community
  detection, generators, and GraphML/JSON/NumPy/SciPy I/O).

## Install and use

Copy the complete `ds-eda-explainability/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ds-eda-explainability ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ds-eda-explainability@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ds-eda-explainability
```

Examples:
- "Audit this CSV dataset for missingness, subject-split leakage, and outlier sensitivity without modifying raw data."
- "Configure UMAP + HDBSCAN for clustering high-dimensional embeddings and validate stability across seeds."
- "Compute probability-space SHAP explanations for a scikit-learn RandomForestClassifier and verify additivity."
- "Build a weighted NetworkX graph from a pandas edge list, compute betweenness centrality, and export to GraphML."

## Sources and adaptation

Condensed on 2026-11-16 from four upstream skills in
[K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills)
(MIT, commit `ec59a29a03d5c40f73ab40878df04860bc00e876`, see
[LICENSE.upstream](LICENSE.upstream)):

- `skills/exploratory-data-analysis/SKILL.md`
- `skills/umap-learn/SKILL.md`
- `skills/shap/SKILL.md`
- `skills/networkx/SKILL.md`

These references are condensed derivatives, not vendored copies. Overlapping
workflows and upstream boilerplate were distilled into two domain-grouped guides
while preserving core APIs, version pins, decision matrices, and scientific/safety
guardrails.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks (`check_static_smells.py`). Python APIs target the consumer's
environment and were not executed live here.
