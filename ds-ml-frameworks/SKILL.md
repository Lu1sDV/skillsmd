---
name: ds-ml-frameworks
description: >
  Use when building classical ML pipelines (scikit-learn), organizing PyTorch
  training with multi-GPU/DDP/FSDP/DeepSpeed (PyTorch Lightning), loading or
  fine-tuning Hugging Face Hub models (Transformers), or building Graph Neural
  Networks (PyTorch Geometric / PyG). Triggers on 'scikit-learn', 'sklearn',
  'ColumnTransformer', 'pytorch-lightning', 'LightningModule', 'Trainer',
  'transformers', 'AutoModel', 'apply_chat_template', 'torch-geometric', 'PyG',
  'NeighborLoader', or 'HeteroData'.
---

# ML & Deep Learning Frameworks

Four frameworks, one reference each. Open only the reference the task needs;
do not preload all.

| Task / Framework | Read |
|---|---|
| Classical ML, preprocessing, CV, pipelines, clustering, metrics (`scikit-learn`) | [Scikit-learn reference](references/scikit-learn.md) |
| Structured PyTorch training, `LightningModule`, `Trainer`, DDP/FSDP/DeepSpeed, callbacks (`lightning`) | [PyTorch Lightning reference](references/pytorch-lightning.md) |
| Hub models, `pipeline()`, chat templates, text generation, `Trainer` fine-tuning (`transformers` v5) | [Transformers reference](references/transformers.md) |
| Graph Neural Networks, `Data`/`HeteroData`, `MessagePassing`, `NeighborLoader` (`torch_geometric`) | [PyTorch Geometric reference](references/torch-geometric.md) |

## What each covers

- **Scikit-learn** — `Pipeline` + `ColumnTransformer` mixed-type workflows, scaling/splitting rules (`GroupKFold`, `StratifiedGroupKFold`, chronological), metric selection, out-of-core `SGDClassifier`/`MiniBatchKMeans`, and leakage/convergence troubleshooting.
- **PyTorch Lightning** — `import lightning as L` 6-section `LightningModule`, `LightningDataModule`, `Trainer` (precision, callbacks, CSV/W&B/MLflow logging), DDP/FSDP/DeepSpeed selection, `sync_dist=True` rules, and checkpoint resume vs. load.
- **Transformers** — PyTorch-only v5 stack, Hub auth/caching (`hf auth login`, `HF_HOME`, `revision` pinning), `pipeline()` v5 removals, `tokenizer.apply_chat_template`, and `Trainer(..., processing_class=tokenizer)` fine-tuning.
- **PyTorch Geometric** — `[2, num_edges]` COO `Data` validation, conv layer selection (`GCNConv`, `GATConv`, `SAGEConv`, `GINConv`, `HGTConv`), custom `MessagePassing`, node/graph/link tasks, `NeighborLoader` slicing, `HeteroData` / `to_hetero()`, and `GNNExplainer`.

## Universal rules

- Prevent data leakage: split independent units (patients, subjects, scaffolds, groups, or time periods) *before* fitting scalers, encoders, or tokenizers, and wrap preprocessing inside `Pipeline` or per-split transforms.
- Pin and record package versions, random seeds (`random_state=42`, `L.seed_everything(42, workers=True)`), and immutable Hub `revision` hashes for reproducible runs.
- In distributed PyTorch/Lightning training, avoid `.cuda()` (use `self.device`), pass `sync_dist=True` for cross-rank scalar logging, and run final test evaluation on one device if padded DDP batches would duplicate samples.
- For PyG graphs, verify `edge_index` is `[2, num_edges]` (`.t().contiguous()`), set `data.num_nodes` explicitly if features are absent, slice `NeighborLoader` outputs to `[:batch.batch_size]`, and disable `add_self_loops` on bipartite heterogeneous convs.
- Verify outputs (CV scores, validation loss, `data.validate()`, decoded chat-template round-trips) rather than assuming a clean forward pass implies generalization.
