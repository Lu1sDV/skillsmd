# Retrieval Pathway (RT) — Embedding-Retrieval Replaces Fine-Tuning

> **FuzzGPT-derived** — RT is not in the original paper (Deng et al., arXiv:2304.02014).
> It replaces FT's slot: target-specialized generation keyed on the target unit,
> without GPU training. The paper's FS/ZS data (retained in `evaluation.md`) is RT's
> acceptance bar.

---

## Data flow

```
MINE → ANNOTATE → [INDEX] → GENERATE(RT) → EXECUTE → ORACLES
                    │            │
   embed all triples│            │ embed "{unit_label}: {target_unit}",
   persist {id,vec} │            │ top-N → MMR → K=6 (or 1 for Mode B),
   (seconds, no GPU)│            │ assemble template, log retrieved ids
                    │            └─ fallback → random when no neighbours
```

The `[INDEX]` step is new. Everything else — mining, annotation, execution, oracles — is
unchanged from the base pipeline (`pipeline.md`).

---

## Corpus shape (target-agnostic)

The annotated corpus generalizes from `(api, description, code)` to:

```
(target_unit, description, code)
```

`target_unit` is whatever the fuzzing target's unit-of-interest is — an **API** (DL
libraries), a **compiler flag / optimization pass**, a **SQL feature**, an **SMT
theory**, a **syscall**, a **bytecode / opcode**, a protocol message, etc. A
`unit_label` string configures the label used in indexed documents and queries:

| Domain | `unit_label` | Example `target_unit` |
|--------|--------------|----------------------|
| DL / numeric library | `"API"` | `torch.gather` |
| Compiler / interpreter | `"Flag"` | `-O2` |
| DB engine | `"Feature"` | `JSON_TABLE` |
| SMT solver | `"Theory"` | `array-ext` |
| Kernel / runtime | `"Syscall"` | `io_uring` |
| Parser / file format | `"Field"` | `PNG tEXt chunk` |
| Bytecode VM | `"Opcode"` | `INVOKEDYNAMIC` |

---

## Retriever components

| Component | Responsibility | Default / notes |
|-----------|----------------|-----------------|
| **Indexer** | Embed a composite doc per triple: `"{unit_label}: {unit}\n{description}\n{code}"` | Deterministic, idempotent; re-runnable on corpus change |
| **Embedding backend** | `embed(texts) -> vectors` interface | Pluggable. Blessed local (CPU-fine, offline): `jina-embeddings-v2-base-code`, BGE-code. Blessed hosted: `voyage-code-3`, `text-embedding-3-large`. Pick one matching the target's snippet language; the description field carries signal for non-code units |
| **Vector store** | Similarity search over the index | NumPy brute-force cosine — exact, zero-dep, fine ≤ ~50 k triples. Scale upgrade: FAISS HNSW/IVF |
| **Query builder** | Target unit → query text `"{unit_label}: {target_unit}"` | Optional one-line NL gloss (default **off** — YAGNI) |
| **Selector** | top-N (N=30) by cosine → MMR select K=6 (λ=0.5) | **Fallback to random** if max-sim < τ (≈0.2) or corpus tiny. For the 100-progs budget, draw 10 varied K=6 subsets from the top-N pool |
| **Prompt assembler** | Feed selected examples into the chosen template | Templates **unchanged**: FS CoT (Mode A) or ZS completion (Mode B) |
| **Provenance log** | Record retrieved triple ids per generation | Interpretability — FT cannot do this |

---

## Mode A — RAG-FS (default)

Retrieve K=6 on-target triples → existing few-shot CoT template (predict
`Bug description:` then code) → target-unit query block. Identical generation
contract to FS; only example *selection* changes from random to
retrieval-with-random-fallback.

Per the target-agnostic design, the template's `API:` header generalizes to
`{unit_label}:`:

```
{unit_label}: {unit_1}
Bug description: {description_1}
{code_1}

...  (K=6 retrieved examples, MMR-selected or random fallback)  ...

{unit_label}: {target_unit}
Bug description:            ← model completes description, then code
```

**Generation contract (unchanged):** `temperature=0.8`, `top_p=0.95`,
`max_token=256`. Run 10 prompts × 10 generations = 100 programs per target unit.

---

## Mode B — RAG-ZS (optional)

Retrieve the **single most relevant real snippet** for the target unit → existing ZS
completion path (truncate suffix, model completes). The comment generalizes to:

```
# The following code reveals a bug in {target_unit}
<retrieved c_e[:j]>         ← real partial snippet (suffix truncated)
                            ← model completes
```

Lower valid-rate (as in the paper's ZS). Use when you want concrete real-code
ingredients without the full K=6 block.

---

## Hyperparameters

| Param | Value | Notes |
|-------|-------|-------|
| Embedding model | pluggable | Blessed: local `jina-embeddings-v2-base-code` / BGE-code; hosted `voyage-code-3` / `text-embedding-3-large` |
| `K` (examples, Mode A) | **6** | Paper sweet spot — kept |
| top-N pool | **30** | Candidates before MMR |
| MMR `λ` | **0.5** | Relevance vs. diversity balance |
| Fallback threshold `τ` | **≈0.2** | Max cosine below this → random selection |
| Mode B snippets | **1** | Most-relevant real snippet |

**Unchanged generation contract:** `temperature=0.8`, `top_p=0.95`, `max_token=256`,
100 programs/target unit (10 prompts × 10 generations), annotation `temperature=0`.

---

## Honest caveat (from the paper's §7 finding)

The paper found MMR-based similar/diverse example selection ≈ **random** selection on
a single-library corpus. RT makes no claim of a coverage gain in that regime. Two
design choices encode this honestly:

1. **Fallback-to-random guard** — when max cosine < τ or corpus is tiny, RT selects
   examples randomly. RT is **never worse than random FS**.
2. **Upside only at scale** — on a large or multi-source corpus, random K=6 rarely
   lands on-target; retrieval keeps the few-shot block relevant. That is RT's genuine
   analog of FT's per-target specialization.

---

## Reference code (indexer + MMR/fallback selector)

```python
import numpy as np

# --- Indexer ---
def build_index(triples, embed_fn, unit_label="API"):
    """
    triples: list of (target_unit, description, code) dicts
    embed_fn: callable(list[str]) -> np.ndarray shape (n, d)
    Returns: dict with 'vecs' (n,d) float32 and 'ids' list
    """
    docs = [
        f"{unit_label}: {t['target_unit']}\n{t['description']}\n{t['code']}"
        for t in triples
    ]
    vecs = embed_fn(docs).astype(np.float32)
    norms = np.linalg.norm(vecs, axis=1, keepdims=True)
    vecs = vecs / np.where(norms == 0, 1, norms)   # L2-normalise
    return {"vecs": vecs, "ids": [t["id"] for t in triples]}

# --- Selector ---
def select_examples(query_unit, index, triples_by_id, embed_fn,
                    unit_label="API", N=30, K=6, lam=0.5, tau=0.2,
                    rng=None):
    """
    Returns K triples (dicts) via MMR, falling back to random if max-sim < tau.
    rng: np.random.Generator — pass for reproducibility.
    """
    if rng is None:
        rng = np.random.default_rng()
    q = embed_fn([f"{unit_label}: {query_unit}"])[0].astype(np.float32)
    q = q / (np.linalg.norm(q) or 1)
    sims = index["vecs"] @ q                        # cosine (vecs already normed)
    if sims.max() < tau:                            # fallback: corpus too sparse
        chosen = rng.choice(len(index["ids"]), size=min(K, len(index["ids"])),
                            replace=False).tolist()
        return [triples_by_id[index["ids"][i]] for i in chosen]
    top_n_idx = np.argsort(sims)[-N:][::-1]        # top-N candidates
    # MMR
    selected, candidates = [], list(top_n_idx)
    cand_vecs = index["vecs"][candidates]
    while len(selected) < K and candidates:
        if not selected:
            best = 0
        else:
            sel_vecs = index["vecs"][selected]
            rel = sims[candidates]
            div = cand_vecs @ sel_vecs.T
            mmr = lam * rel - (1 - lam) * div.max(axis=1)
            best = int(mmr.argmax())
        chosen_idx = candidates.pop(best)
        cand_vecs = np.delete(cand_vecs, best, axis=0)
        selected.append(chosen_idx)
    return [triples_by_id[index["ids"][i]] for i in selected]
```

Usage: call `build_index` once per corpus update; call `select_examples` at generation
time. For the 100-programs budget, call `select_examples` 10 times (different
`rng` seeds) to get 10 varied K=6 subsets, run 10 generations each.

---

## Validation protocol (FuzzGPT-derived)

Because RT is not in the paper, its acceptance bar is the **retained FS coverage** in
`evaluation.md`. Run on DL libraries as the concrete reproduction example (that is
where FS numbers exist); the protocol generalises to any target domain.

1. **Parity (single-source corpus):** on a sample of target units, run random-FS vs
   RAG-FS; assert `coverage(RAG-FS) ≥ coverage(random-FS) − ε`. Expectation: approximately equal.
2. **Scale win (enlarged / multi-source corpus):** assert
   `coverage(RAG-FS) > coverage(random-FS)`. Expectation: RT wins when random
   sampling goes off-target across a heterogeneous corpus.
3. **Fallback correctness:** for a target unit with no neighbours above τ, verify RT's
   selection distribution matches random (KS test or visual inspection).

---

## Error handling

| Condition | Behaviour |
|-----------|-----------|
| Empty corpus | Error: "corpus is empty — run MINE + ANNOTATE first" |
| Embedding backend unavailable | Error with model name + remediation (check API key / install local model) |
| No neighbours above τ | Silent random fallback (expected path, not an error) |
| Corpus / index drift (new triples added) | Re-run `build_index` — idempotent and cheap |
