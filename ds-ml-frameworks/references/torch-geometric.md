# PyTorch Geometric (PyG) Reference

Graph Neural Networks on PyTorch (`torch-geometric == 2.8.0.post1`, Python 3.10+, PyTorch 2.9+).

## Installation

```bash
uv pip install torch==2.14.1
uv pip install torch-geometric==2.8.0.post1
python -c "import torch, torch_geometric; print(torch.__version__, torch.version.cuda, torch_geometric.__version__)"
```

- Basic tensor-based layers need no compiled extensions.
- **Neighbor sampling** requires `pyg-lib` or `torch-sparse`; **spatial k-NN operators** (`T.KNNGraph`) require `pyg-lib` in PyG 2.8.
- `torch-cluster` and `torch-spline-conv` are deprecated and ignored.
- Match extension wheels to your exact Python, OS, PyTorch, and CUDA/CPU tuple from `https://data.pyg.org/whl/` (conda packages are no longer provided for Torch > 2.5):
  ```bash
  uv pip install --only-binary=:all: "pyg-lib==0.9.0+pt214" \
    -f https://data.pyg.org/whl/torch-2.14.0+cpu.html
  ```

---

## Core Data Structures & Transforms

### `Data` (Homogeneous Graphs)

```python
from torch_geometric.data import Data

# edge_index must be [2, num_edges] (COO format, torch.long)
# If edges are [[src, dst], ...], transpose first:
edge_index = edge_pairs.t().contiguous()

data = Data(
    x=node_features,         # [num_nodes, num_node_features]
    edge_index=edge_index,   # [2, num_edges]
    edge_attr=edge_features, # [num_edges, num_edge_features]
    y=labels,                # node-level [num_nodes, *] or graph-level [1, *]
    pos=positions,           # [num_nodes, num_dims]
)
data.validate(raise_on_error=True)
```

- **Isolated nodes / no `x`:** Set `data.num_nodes` explicitly from the node table. Inferring from `edge_index.max() + 1` drops isolated nodes and corrupts batching offsets.
- **Undirected graphs:** Include both `[src, dst]` and `[dst, src]` in `edge_index` (or use `T.ToUndirected()`).

### Datasets & Transforms

```python
import torch_geometric.transforms as T
from torch_geometric.datasets import Planetoid, TUDataset, ShapeNet

# Single-graph node classification
cora = Planetoid(root="./data/Cora", name="Cora", split="public")[0]

# Multi-graph classification
tu = TUDataset(root="./data/TU", name="ENZYMES")

# pre_transform runs once & caches; transform runs on every access
dataset = ShapeNet(
    root="./data",
    pre_transform=T.KNNGraph(k=6),
    transform=T.RandomJitter(0.01),
)
```

Common transforms: `T.NormalizeFeatures()`, `T.ToUndirected()` (default reduces duplicate edge attributes by sum — verify semantics before using on directed/weighted/temporal graphs), `T.AddSelfLoops()`, `T.Compose([...])`. For OGB benchmarks, use the official `ogb` evaluator and splits rather than random splits.

---

## Conv Layer Selection & Custom `MessagePassing`

### Layer Decision Table

| Layer | Best For | Notes / Signature Gotchas |
|---|---|---|
| `GCNConv` | Homogeneous, semi-supervised node classification | Accepts scalar `edge_weight`, not multi-dim `edge_attr` |
| `GATConv` / `GATv2Conv` | Varying neighbor importance | Attention-weighted aggregation |
| `SAGEConv` | Large graphs, inductive learning | Sampling-friendly; supports `(-1, -1)` bipartite lazy init |
| `GINConv` | Graph classification, 1-WL expressiveness | Wraps an MLP (may already include activations) |
| `TransformerConv` | Rich edge features (`edge_dim`) | Multi-head attention with edge attributes |
| `EdgeConv` | Point clouds, dynamic k-NN graphs | MLP on `(x_i, x_j - x_i)` |
| `RGCNConv` | Heterogeneous with many relation types | Requires `edge_type` relation IDs |
| `HGTConv` | Heterogeneous graphs | Takes `x_dict`, `edge_index_dict`; `out_channels` must divide by `heads` |

High-level ready-made models are also available: `from torch_geometric.nn import GraphSAGE, GCN, GAT, GIN`.

### Lazy Initialization

```python
from torch_geometric.nn import SAGEConv

conv = SAGEConv((-1, -1), 64)
with torch.no_grad():
    _ = conv(data.x, data.edge_index)  # Must run 1 pass before training/DDP
```

### Custom `MessagePassing` Layer

`propagate()` calls `message()` -> `aggregate()` -> `update()`. Any tensor passed to `propagate()` can be auto-indexed with `_j` (source/neighbor) or `_i` (target/central):

```python
from torch_geometric.nn import MessagePassing

class MyConv(MessagePassing):
    def __init__(self, in_channels: int, out_channels: int):
        super().__init__(aggr="add")  # "add", "mean", or "max"
        self.lin = torch.nn.Linear(in_channels, out_channels)

    def forward(self, x, edge_index):
        x = self.lin(x)
        return self.propagate(edge_index, x=x)

    def message(self, x_j):
        return x_j
```

---

## Task Patterns

### Node Classification (Full-Batch)

```python
import torch.nn.functional as F
from torch_geometric.nn import GCNConv

class GCN(torch.nn.Module):
    def __init__(self, in_ch, hidden_ch, out_ch):
        super().__init__()
        self.conv1 = GCNConv(in_ch, hidden_ch)
        self.conv2 = GCNConv(hidden_ch, out_ch)

    def forward(self, x, edge_index):
        x = self.conv1(x, edge_index).relu()
        x = F.dropout(x, p=0.5, training=self.training)
        return self.conv2(x, edge_index)
```

Compute loss only on `out[data.train_mask]` / `data.y[data.train_mask]`; select checkpoints on `val_mask` and evaluate `test_mask` once.

### Graph Classification (Mini-Batched)

`DataLoader` packs multiple graphs into a block-diagonal union and populates `data.batch`:

```python
from torch_geometric.loader import DataLoader
from torch_geometric.nn import global_mean_pool  # also global_max_pool, global_add_pool

loader = DataLoader(train_dataset, batch_size=32, shuffle=True)
# Inside forward(self, x, edge_index, batch):
# x = global_mean_pool(x, batch)  # -> [num_graphs_in_batch, hidden_ch]
```

### Link Prediction

```python
from torch_geometric.transforms import RandomLinkSplit

transform = RandomLinkSplit(
    num_val=0.1,
    num_test=0.1,
    is_undirected=True,
    add_negative_train_samples=True,
    disjoint_train_ratio=0.2,  # Keeps supervision edges out of message-passing edges
)
train_data, val_data, test_data = transform(data)

z = encoder(train_data.x, train_data.edge_index)
src, dst = train_data.edge_label_index
logits = (z[src] * z[dst]).sum(dim=-1)
loss = F.binary_cross_entropy_with_logits(logits, train_data.edge_label.float())
```

---

## Scaling to Large Graphs (`NeighborLoader`)

Requires `pyg-lib` or `torch-sparse`:

```python
from torch_geometric.loader import NeighborLoader

train_loader = NeighborLoader(
    data,
    num_neighbors=[15, 10],      # Length must equal number of GNN layers
    batch_size=128,
    input_nodes=data.train_mask, # For HeteroData: ("node_type", mask)
    shuffle=True,
)

for batch in train_loader:
    batch = batch.to(device)
    out = model(batch.x, batch.edge_index)
    # Seed nodes are ALWAYS the first batch.batch_size nodes
    loss = F.cross_entropy(out[:batch.batch_size], batch.y[:batch.batch_size])
```

Other samplers: `LinkNeighborLoader` (link prediction), `ClusterLoader` (ClusterGCN), `GraphSAINTSampler`, `ShaDowKHopSampler`.

---

## Heterogeneous Graphs (`HeteroData`)

```python
from torch_geometric.data import HeteroData
from torch_geometric.nn import SAGEConv, HeteroConv, HGTConv, to_hetero

data = HeteroData()
data["user"].x = torch.randn(1000, 64)
data["movie"].x = torch.randn(500, 128)
data["user", "rates", "movie"].edge_index = torch.stack([
    torch.randint(1000, (3000,)), torch.randint(500, (3000,))
])
```

Three modeling approaches:
1. **`to_hetero(model, data.metadata(), aggr="sum")`** — auto-converts a homogeneous GNN (use `(-1, -1)` input channels) to accept `data.x_dict, data.edge_index_dict`.
2. **`HeteroConv({...}, aggr="sum")`** — assign a distinct conv layer per `(src, rel, dst)` edge triplet.
3. **Native `HGTConv(-1, 64, data.metadata(), heads=4)`**.

**Bipartite self-loop rule:** Set `add_self_loops=False` on conv layers where source and target node types differ (e.g., `GATConv((-1, -1), 64, add_self_loops=False)`); use skip connections instead. Apply `T.ToUndirected()` to add reverse edge types for bidirectional flow.

---

## Custom Datasets & Explainability

- **Custom datasets:** Pass a list of `Data` objects directly to `DataLoader`; subclass `InMemoryDataset` (RAM) or `Dataset` (disk-backed); or convert via `from_networkx(G)` / `from_scipy_sparse_matrix(adj)`.
- **Explainability (`torch_geometric.explain`):** Wrap models with `Explainer(model=..., algorithm=GNNExplainer(epochs=200), explanation_type="model", node_mask_type="attributes", edge_mask_type="object", model_config=dict(mode="multiclass_classification", task_level="node", return_type="raw"))`. Also supports `PGExplainer`, `CaptumExplainer`, `AttentionExplainer`.

---

## Common Pitfalls

1. **`edge_index` shape:** Must be `[2, num_edges]`, not `[num_edges, 2]`.
2. **NeighborLoader slicing:** Only `out[:batch.batch_size]` corresponds to the seed nodes.
3. **`num_neighbors` depth:** Match `len(num_neighbors)` to the number of GNN layers.
4. **Missing activations:** `GCNConv` and `SAGEConv` do not apply nonlinearities; add `.relu()`/`F.relu` between layers.
5. **Scientific split validity:** Graph-level random splits leak scaffolds, patients, or time; node masks are transductive unless unseen nodes/edges are held out.
