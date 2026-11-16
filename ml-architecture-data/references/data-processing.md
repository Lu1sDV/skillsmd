# Data Processing: NeMo Curator & Ray Data

Guide to GPU-accelerated LLM data curation and distributed streaming ETL pipelines.

## Tool Selection

| Tool | Best For | Execution Engine | Typical Scale |
|---|---|---|---|
| **NeMo Curator** | LLM corpus cleaning: heuristic/classifier filtering, exact/fuzzy/semantic dedup, PII redaction, multimodal curation | Dask + RAPIDS cuDF (GPU) | 100GB - 10TB+ web scrapes (Common Crawl) |
| **Ray Data** | General distributed ML ETL, vectorized `map_batches`, GPU batch inference, streaming shards into Ray Train / PyTorch | Ray Actors (CPU/GPU streaming) | 100GB+ across 1 to 100s of nodes |

---

## NeMo Curator (NVIDIA)

GPU-accelerated curation (16x faster fuzzy dedup than CPU, ~89% lower cost on 8TB RedPajama v2).

### Install

```bash
uv pip install "nemo-curator[text_cuda12]"  # Text (CUDA 12)
uv pip install "nemo-curator[all_cuda12]"   # Text + Image + Video + Audio
uv pip install "nemo-curator[cpu]"          # CPU-only fallback
```

### Multi-GPU Cluster Setup

```python
from nemo_curator import get_client
from dask_cuda import LocalCUDACluster

cluster = LocalCUDACluster(n_workers=8)
client = get_client(cluster=cluster)
# ... run curation pipeline ...
client.close()
cluster.close()
```

### Recommended Curation Order (Cheap -> Expensive)

Order stages by compute cost so expensive GPU classifiers and deduplication run on fewer, cleaner documents:

1. **Heuristic filters (30+ built-in)** & **Language ID**:
```python
from nemo_curator.datasets import DocumentDataset
from nemo_curator.filters import (
    WordCountFilter, RepeatedLinesFilter, SymbolToWordRatioFilter,
    UrlRatioFilter, LanguageIdentificationFilter,
)

dataset = DocumentDataset.read_parquet("common_crawl/*.parquet")
dataset = dataset.filter(WordCountFilter(min_words=100, max_words=50000))
dataset = dataset.filter(RepeatedLinesFilter(max_repeated_line_fraction=0.2))
dataset = dataset.filter(SymbolToWordRatioFilter(max_symbol_to_word_ratio=0.3))
dataset = dataset.filter(UrlRatioFilter(max_url_ratio=0.3))
dataset = dataset.filter(LanguageIdentificationFilter(target_languages=["en"]))
```

2. **Deduplication (Exact -> Fuzzy -> Semantic)**:
```python
from nemo_curator.modules import ExactDuplicates, FuzzyDuplicates, SemanticDuplicates

# Exact (fastest, 100% recall on identical text)
dataset = ExactDuplicates(id_field="id", text_field="text", hash_method="md5")(dataset)

# Fuzzy (MinHash + LSH; best speed/quality tradeoff for web scrapes)
dataset = FuzzyDuplicates(
    id_field="id", text_field="text",
    num_hashes=260, num_buckets=20, hash_method="md5", jaccard_threshold=0.8,
)(dataset)

# Semantic (embedding cosine similarity; slower, use on high-value subsets)
dataset = SemanticDuplicates(
    id_field="id", text_field="text",
    embedding_model="sentence-transformers/all-MiniLM-L6-v2",
    embedding_batch_size=256, threshold=0.85, device="cuda",
)(dataset)
```

3. **PII Redaction & GPU Quality/NSFW Classifiers**:
```python
from nemo_curator.modules import Modify
from nemo_curator.modifiers import PIIRedactor
from nemo_curator.classifiers import QualityClassifier, NSFWClassifier

pii = PIIRedactor(
    supported_entities=["EMAIL_ADDRESS", "PHONE_NUMBER", "PERSON", "LOCATION"],
    anonymize_action="replace",  # or "redact"
)
dataset = Modify(pii)(dataset)

quality_clf = QualityClassifier(model_path="nvidia/quality-classifier-deberta", batch_size=256, device="cuda")
nsfw_clf = NSFWClassifier(threshold=0.9, device="cuda")
dataset = dataset.filter(lambda doc: quality_clf(doc["text"]) > 0.5)
dataset = dataset.filter(lambda doc: nsfw_clf(doc["text"]) < 0.9)

dataset.to_parquet("curated_common_crawl/")
```

### Multimodal Curation

- **Image** (`nemo_curator.image`): `AestheticFilter(threshold=5.0)`, `NSFWFilter(threshold=0.9)`, `CLIPEmbedder(model="openai/clip-vit-base-patch32")`.
- **Video** (`nemo_curator.video`): `SceneDetector(threshold=27.0)`, `ClipExtractor(min_duration=2.0, max_duration=10.0)`, `InternVideo2Embedder()`.
- **Audio** (`nemo_curator.audio`): `ASRInference(model="nvidia/stt_en_fastconformer_hybrid_large_pc")`, `WERFilter(max_wer=0.3)`, `DurationFilter(min_duration=1.0, max_duration=30.0)`.

---

## Ray Data

Distributed, streaming-first data processing for ML ETL, batch inference, and Ray Train feeding.

### Install & I/O

```bash
pip install -U 'ray[data]'
```

```python
import ray

ds = ray.data.read_parquet("s3://bucket/data/*.parquet")  # Recommended format
# Also: read_csv, read_json, read_images, from_items, range, from_pandas
ds.write_parquet("s3://bucket/output/")
```

### Vectorized Transforms & GPU Batch Inference

Prefer `map_batches` (10-100x faster than row-by-row `map`). Use a class callable with `num_gpus=1` so the model loads once per GPU actor:

```python
class BatchInference:
    def __init__(self):
        self.model = load_model()  # Loaded once per worker

    def __call__(self, batch):
        return {"prediction": self.model(batch["input"])}

ds = (
    ray.data.read_parquet("s3://raw/")
    .filter(lambda row: row["score"] > 0.5)
    .map_batches(clean_fn, batch_size=1000)
    .map_batches(BatchInference, batch_size=32, num_gpus=1)
)
ds.write_parquet("s3://processed/")
```

Other core ops: `ds.flat_map(fn)` (one-to-many), `ds.groupby("category").count()`, `ds.repartition(100)` (match cluster cores), `ds.iter_batches(batch_size=1000)` (streams data larger than RAM).

### Integration with Ray Train, PyTorch & TensorFlow

```python
from ray.train import ScalingConfig
from ray.train.torch import TorchTrainer

train_ds = ray.data.read_parquet("s3://data/train/")
val_ds = ray.data.read_parquet("s3://data/val/")

def train_func(config):
    train_shard = ray.train.get_dataset_shard("train")
    for epoch in range(config["epochs"]):
        for batch in train_shard.iter_batches(batch_size=32):
            pass

trainer = TorchTrainer(
    train_func,
    train_loop_config={"epochs": 10},
    datasets={"train": train_ds, "val": val_ds},
    scaling_config=ScalingConfig(num_workers=4, use_gpu=True),
)
trainer.fit()
```

Standalone PyTorch / TensorFlow:
- PyTorch: `ds.to_torch(label_column="label", batch_size=32, drop_last=True)` or `ds.iter_torch_batches(batch_size=32)`.
- TensorFlow: `ds.to_tf(feature_columns=["image"], label_column="label", batch_size=32)`.

### Performance & Gotchas

- **Tuning**: Increase `batch_size` in `map_batches` (e.g., `1000` or `10000` for CPU vectorized ops) and `repartition(num_workers)` to avoid under-utilized cores.
- **Avoid OOM**: Never call `.take_all()` or `.to_pandas()` on datasets larger than driver RAM; stream with `iter_batches()` or `write_parquet()`.
