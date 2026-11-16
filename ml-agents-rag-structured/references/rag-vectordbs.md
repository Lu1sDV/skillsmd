# Embeddings & Vector Databases (RAG Retrieval)

Distilled reference for **Sentence Transformers**, **FAISS**, **Chroma**, **Qdrant**, and **Pinecone**.

## Tool Selection

| Tool | Role | Best For | Metadata Filtering | Scale / Ops |
|------|------|----------|--------------------|-------------|
| **Sentence Transformers** | Local embeddings | Free, fast local dense vectors & fine-tuning | N/A (encoder) | CPU/GPU local |
| **FAISS** | Vector index library | Pure similarity search, billion-scale, GPU k-NN | None natively | In-memory / disk file |
| **Chroma** | Embedded/local vector DB | Prototyping, notebooks, self-hosted RAG | Yes (`where` dict) | Local disk or single server |
| **Qdrant** | Rust vector search engine | Production self-hosted/cloud, hybrid + quantization | Rich (`Filter` + payload index) | Distributed (Raft, sharding) |
| **Pinecone** | Managed SaaS vector DB | Zero-ops serverless production, namespaces | Yes (`filter` dict) | Fully managed auto-scaling |

---

## 1. Sentence Transformers (Embeddings)

**Install:** `pip install sentence-transformers`

**Model selection:**
- `all-MiniLM-L6-v2` (384d, ~120MB, fastest prototyping)
- `all-mpnet-base-v2` (768d, ~420MB, best general production RAG)
- `all-roberta-large-v1` (1024d, ~1.3GB, highest accuracy)
- `paraphrase-multilingual-mpnet-base-v2` (768d, 100+ languages)
- Domain: `nlpaueb/legal-bert-base-uncased`, `allenai/specter` (science), `microsoft/codebert-base`

**Core API:**
```python
from sentence_transformers import SentenceTransformer, util

model = SentenceTransformer("all-mpnet-base-v2")
corpus_emb = model.encode(corpus, batch_size=32, convert_to_tensor=True, normalize_embeddings=True)
query_emb = model.encode(query, convert_to_tensor=True, normalize_embeddings=True)

hits = util.semantic_search(query_emb, corpus_emb, top_k=5)
# Pairwise similarity: util.cos_sim(a, b) or util.dot_score(a, b)
```

- **Fine-tuning:** `InputExample(texts=[s1, s2], label=0.8)` -> `DataLoader` -> `losses.CosineSimilarityLoss(model)` -> `model.fit(...)` -> `model.save("my-model")`.
- **LangChain / LlamaIndex:** `HuggingFaceEmbeddings(model_name="sentence-transformers/all-mpnet-base-v2")` / `HuggingFaceEmbedding(...)`.

**Gotchas:**
- Always match the embedding dimension (`384`, `768`, `1536`) to your vector store collection/index config.
- Normalize embeddings (`normalize_embeddings=True`) when using dot-product / inner-product indices for cosine similarity.

---

## 2. FAISS (High-Speed Vector Index)

**Install:** `pip install faiss-cpu` (or `faiss-gpu`)

**Index selection:**
| Index | Build | Search | Memory | Accuracy | When to Use |
|-------|-------|--------|--------|----------|-------------|
| `IndexFlatL2(d)` / `IndexFlatIP(d)` | Fast | Slow | High | 100% | <10K vectors, exact baseline |
| `IndexIVFFlat(quantizer, d, nlist)` | Medium | Fast | Medium | 95-99% | 10K-1M vectors; requires `.train(vectors)` |
| `IndexHNSWFlat(d, M)` | Slow | Fastest | High | ~99% | Low-latency ANN without training (`M=32`) |
| `IndexPQ(d, m, nbits)` | Medium | Fast | Low (16-32x smaller) | 90-95% | Memory-constrained large datasets |

**Core API:**
```python
import faiss, numpy as np

d = 768
vectors = np.random.random((10000, d)).astype("float32")
quantizer = faiss.IndexFlatL2(d)
index = faiss.IndexIVFFlat(quantizer, d, 100)  # nlist=100
index.train(vectors)
index.add(vectors)
index.nprobe = 10  # Tune speed vs recall

distances, indices = index.search(query.astype("float32"), k=5)
faiss.write_index(index, "large.index")
index = faiss.read_index("large.index")
```

- **GPU:** `res = faiss.StandardGpuResources(); index_gpu = faiss.index_cpu_to_gpu(res, 0, index_cpu)` (or `index_cpu_to_all_gpus(index_cpu)`).

**Gotchas:**
- FAISS requires `float32` contiguous numpy arrays; `float64` raises type errors.
- FAISS stores only vectors and integer IDs—maintain a separate ID-to-document/metadata mapping if not using LangChain/LlamaIndex wrappers.

---

## 3. Chroma (Local / Embedded Vector DB)

**Install:** `pip install chromadb` (JS/TS: `npm install chromadb @chroma-core/default-embed`)

**Core API:**
```python
import chromadb
from chromadb.utils import embedding_functions

client = chromadb.PersistentClient(path="./chroma_db")  # Ephemeral: chromadb.Client()
# Server mode: `chroma run --path ./chroma_db --port 8000` -> chromadb.HttpClient(host="localhost", port=8000)

ef = embedding_functions.OpenAIEmbeddingFunction(api_key="...", model_name="text-embedding-3-small")
col = client.get_or_create_collection(name="my_docs", embedding_function=ef)  # Default: all-MiniLM-L6-v2

col.add(
    documents=["Doc 1", "Doc 2"],
    metadatas=[{"category": "tutorial", "page": 1}, {"category": "api", "page": 5}],
    ids=["id1", "id2"],
)

results = col.query(
    query_texts=["how to start"],
    n_results=5,
    where={"$and": [{"category": "tutorial"}, {"page": {"$gte": 1}}]},  # $gt, $gte, $lt, $lte, $ne, $in, $or
)
# Also: col.get(ids=..., where=...), col.update(...), col.delete(ids=..., where=...)
```

**Gotchas:**
- `chromadb.Client()` is in-memory only; use `PersistentClient(path=...)` or `HttpClient` to avoid losing data on exit.
- IDs must be unique strings; duplicate `add()` calls fail—use `upsert()` or `update()` for existing IDs.

---

## 4. Qdrant (Production Rust Vector Engine)

**Install & run:**
```bash
pip install qdrant-client
docker run -p 6333:6333 -p 6334:6334 -v $(pwd)/qdrant_storage:/qdrant/storage qdrant/qdrant
```

**Core API:**
```python
from qdrant_client import QdrantClient
from qdrant_client.models import (
    Distance, VectorParams, PointStruct, HnswConfigDiff,
    Filter, FieldCondition, MatchValue, Range, PayloadSchemaType,
    ScalarQuantization, ScalarQuantizationConfig, ScalarType,
)

client = QdrantClient(host="localhost", port=6333, prefer_grpc=True)
# Cloud: QdrantClient(url="https://your-cluster.cloud.qdrant.io", api_key="...")

client.create_collection(
    collection_name="docs",
    vectors_config=VectorParams(size=384, distance=Distance.COSINE),  # COSINE, EUCLID, DOT, MANHATTAN
    hnsw_config=HnswConfigDiff(m=16, ef_construct=100, full_scan_threshold=10000),
    quantization_config=ScalarQuantization(
        scalar=ScalarQuantizationConfig(type=ScalarType.INT8, quantile=0.99, always_ram=True)
    ),
    on_disk_payload=True,
)

# Index payload fields used in filters for fast filtered search:
client.create_payload_index(collection_name="docs", field_name="category", field_schema=PayloadSchemaType.KEYWORD)

client.upsert(
    collection_name="docs",
    points=[PointStruct(id=1, vector=vec, payload={"category": "tech", "ts": 1700000000})],
    wait=True,
)

results = client.search(
    collection_name="docs",
    query_vector=query_vec,
    query_filter=Filter(must=[
        FieldCondition(key="category", match=MatchValue(value="tech")),
        FieldCondition(key="ts", range=Range(gte=1699000000)),
    ]),
    search_params={"quantization": {"rescore": True}},
    limit=10,
    with_vectors=False,
)
```

- **Hybrid / Multi-vector:** Pass `vectors_config={"dense": VectorParams(...)}` and `sparse_vectors_config={"text": SparseVectorParams(...)}` with `SparseVector(indices=..., values=...)`.

**Gotchas:**
- Filtered search degrades without payload indices—call `create_payload_index` for every field used in `query_filter`.
- Set `with_vectors=False` on `search()` when you only need IDs/payloads to avoid unnecessary network overhead.

---

## 5. Pinecone (Managed Serverless Vector DB)

**Install:** `pip install pinecone-client`

**Core API:**
```python
from pinecone import Pinecone, ServerlessSpec

pc = Pinecone(api_key="your-api-key")
pc.create_index(
    name="my-index",
    dimension=1536,
    metric="cosine",  # "cosine", "euclidean", "dotproduct"
    spec=ServerlessSpec(cloud="aws", region="us-east-1"),
)
index = pc.Index("my-index")

index.upsert(
    vectors=[{"id": "doc1", "values": vec, "metadata": {"category": "tutorial"}}],
    namespace="tenant-a",
    batch_size=100,
)

results = index.query(
    vector=query_vec,
    top_k=5,
    namespace="tenant-a",
    filter={"category": {"$eq": "tutorial"}},  # $eq, $ne, $gt, $gte, $lt, $lte, $in, $and, $or
    include_metadata=True,
    include_values=False,
)
```

- **Hybrid search:** Include `"sparse_values": {"indices": [...], "values": [...]}` on upsert and pass `sparse_vector={...}` with `alpha=0.5` (`0`=sparse, `1`=dense) on query (requires `metric="dotproduct"`).
- **Management:** `pc.list_indexes()`, `pc.describe_index(name)`, `index.describe_index_stats()`, `index.delete(ids=...|filter=...|delete_all=True, namespace=...)`.

**Gotchas:**
- Hybrid search (`sparse_vector` + `alpha`) requires `metric="dotproduct"` at index creation.
- Use `namespace` for multi-tenant isolation rather than creating separate indices per tenant.
