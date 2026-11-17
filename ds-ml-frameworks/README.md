# ds-ml-frameworks

Consolidated skill for core Python machine learning and deep learning
frameworks: scikit-learn, PyTorch Lightning, Hugging Face Transformers, and
PyTorch Geometric (PyG). [SKILL.md](SKILL.md) is a short orchestrator that
routes to four independently readable references, loaded only when the task
needs them:

- [references/scikit-learn.md](references/scikit-learn.md) — `Pipeline` and
  `ColumnTransformer` workflows, scaling/splitting decision tables, metrics,
  out-of-core estimators, and leakage/convergence troubleshooting.
- [references/pytorch-lightning.md](references/pytorch-lightning.md) —
  `LightningModule`, `LightningDataModule`, `Trainer`, callbacks, loggers,
  DDP/FSDP/DeepSpeed strategy selection, and distributed metric gotchas.
- [references/transformers.md](references/transformers.md) — Transformers v5
  PyTorch-only setup, Hub auth/caching, `pipeline()` v5 changes,
  `apply_chat_template`, and `Trainer` fine-tuning.
- [references/torch-geometric.md](references/torch-geometric.md) — `Data` and
  `HeteroData`, conv layer selection, custom `MessagePassing`, node/graph/link
  tasks, `NeighborLoader`, and `GNNExplainer`.

## Install and use

Copy the complete `ds-ml-frameworks/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ds-ml-frameworks ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ds-ml-frameworks@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ds-ml-frameworks
```

Examples:
- "Build a scikit-learn `ColumnTransformer` + `Pipeline` with `StratifiedGroupKFold` for mixed tabular data."
- "Convert my PyTorch training loop into a `LightningModule` with `ModelCheckpoint` and `bf16-mixed` FSDP."
- "Load an instruction-tuned LLM with Transformers v5 `apply_chat_template` and fine-tune it with `Trainer`."
- "Implement heterogeneous link prediction in PyG using `HeteroData`, `to_hetero`, and `RandomLinkSplit`."

## Sources and adaptation

Condensed on 2026-11-16 from four upstream skills in
[K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills)
(MIT, commit `ec59a29a03d5c40f73ab40878df04860bc00e876`, see
[LICENSE.upstream](LICENSE.upstream)):

- `skills/scikit-learn/SKILL.md`
- `skills/pytorch-lightning/SKILL.md`
- `skills/transformers/SKILL.md`
- `skills/torch-geometric/SKILL.md`

These references are condensed derivatives, not vendored copies. Upstream
boilerplate, citation blocks, and unbundled sub-reference links were removed
while preserving core APIs, installation constraints, decision tables, code
patterns, and pitfalls.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks (`check_static_smells.py`). Commands and Python APIs target
the consumer's Python/GPU environment and were not executed live here.
