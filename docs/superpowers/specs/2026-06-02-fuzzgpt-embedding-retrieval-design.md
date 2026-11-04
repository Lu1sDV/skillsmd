# FuzzGPT — Embedding Retrieval Replaces Fine-Tuning (Design Spec)

- **Date:** 2026-06-02
- **Status:** Draft for review
- **Target skill:** `fuzzgpt/`
- **Author:** brainstorming session (design only — no implementation yet)

## 1. Summary

Replace FuzzGPT's fine-tuning pathway (FT) with an **embedding-retrieval pathway (RT)**.
RT is a corpus-indexing + example-selection layer: it embeds the annotated bug corpus
once, then at generation time retrieves the most relevant historical bug examples for the
**target unit** and feeds them to an existing FuzzGPT generation template. It occupies the
slot FT vacates, giving FT's "target-specialized generator from just the target unit"
behavior **without any GPU training**.

The skill's identity changes from *"faithful 1:1 reproduction of FuzzGPT"* to
**"FuzzGPT-derived: retrieval replaces fine-tuning."**

## 2. Motivation

FT (FuzzGPT §3.2.3) trains one model per target on the annotated corpus
(`batch=32, lr=5e-5, AdamW, 10 epochs`, one model per library) so that, given only the
target unit, the model emits a plausible bug description + bug-triggering code in that
target's idiom. Its operational costs: a GPU training loop, per-target storage, and — most
limiting today — **it cannot be applied to hosted, non-fine-tunable models** (Claude /
GPT-4-class), which are the strongest generators available.

RT reproduces FT's *role* (specialized generation keyed on the target unit) by sourcing the
specialization from **retrieved context** instead of **trained weights**:

- **No training** — runs on any generator, including hosted non-fine-tunable models.
- **Instant corpus refresh** — re-running the index is seconds, vs. re-training FT.
- **Interpretable & deterministic** — every generation logs which past bugs drove it.
- **Scales to large / multi-source corpora** — see §4.

## 3. Locked decisions (from brainstorming)

| # | Decision |
|---|----------|
| D1 | Primary goal = **operational FT-replacement** (match FS/FT coverage, not beat it). |
| D2 | **Full excision** of FT — remove the FT *method* AND the paper's FT *result data*. |
| D3 | Reframe skill identity to "FuzzGPT-derived: retrieval replaces fine-tuning." |
| D4 | Include **Mode B** (retrieval → ZS-completion) as a documented secondary mode. |
| D5 | **Target-agnostic** — the retrieved/queried thing is the generic *target unit*, not "API". |
| D6 | Deliverable = skill **markdown + a compact reference code snippet** (not a packaged module). *(assumption — see §11)* |

## 4. The honest caveat and how the design respects it

FuzzGPT §7 (`evaluation.md`) found that **MMR-based similar/diverse example selection ≈
random selection** for few-shot on a single-library corpus, and warns "don't over-engineer
example selection." This design does **not** claim a coverage gain. Two structural choices
keep us honest:

- **Fallback-to-random guard** (§6, Selector): when the corpus is small or the target unit
  has no sufficiently-similar neighbours (max cosine < τ), RT selects examples **randomly**.
  This encodes the paper's finding as a runtime safety net — RT is **never worse than
  random few-shot**, and only diverges (positively) when the corpus is large/heterogeneous
  enough that random sampling goes off-target.
- **Expectation = parity, with upside only at scale.** On a single moderate corpus
  RT ≈ FS. On a large or multi-source corpus (pooled multi-repo, cross-language), random
  K=6 rarely lands on-target, so retrieval keeps the few-shot block relevant — *that* is
  where RT earns its slot, and it is the genuine analog of FT's per-target specialization.

## 5. Pathway model after the change

The paper's three paradigms (FS / ZS / **FT**) become (FS / ZS / **RT**). RT is not a new
learning paradigm — it is a **selection layer** that feeds an existing template:

```
                          ┌─ Mode A (default): few-shot CoT template  → RAG-FS
Retrieval (RT) selects ───┤
on-target examples        └─ Mode B (optional): zero-shot completion   → RAG-ZS
```

## 6. Architecture

### 6.1 Data flow (one new step replaces FT training)

```
MINE → ANNOTATE → [INDEX] → GENERATE(RT) → EXECUTE → ORACLES
                    │            │
   embed all triples│            │ embed "{unit_label}: {target_unit}",
   persist {id,vec} │            │ top-N → MMR → K=6 (or 1 for Mode B),
   (seconds, no GPU)│            │ assemble template, log retrieved ids
                    │            └─ fallback → random when no neighbours
```

### 6.2 Corpus shape (target-agnostic)

The annotated corpus from `pipeline.md` generalizes from `(api, description, code)` to:

```
(target_unit, description, code)
```

where `target_unit` is the fuzzing target's unit-of-interest — an **API** (DL libraries), a
**compiler flag / optimization pass**, a **SQL feature**, an **SMT theory**, a **syscall**,
a **bytecode/opcode**, a protocol message, etc. A target-configured `unit_label` string
("API" | "Flag" | "Feature" | "Theory" | "Syscall" | …) is used in both the indexed
document and the query.

### 6.3 Retriever components (one responsibility each)

| Component | Responsibility | Default / notes |
|-----------|----------------|-----------------|
| **Indexer** | Embed a composite doc per triple: `"{unit_label}: {unit}\n{description}\n{code}"` | Deterministic, idempotent; re-runnable on corpus change |
| **Embedding backend** | `embed(texts) -> vectors` interface | Pluggable. Blessed: local code-aware (`jina-embeddings-v2-base-code`, BGE-code — CPU-fine, offline) **or** hosted (`voyage-code-3`, `text-embedding-3-large`). Pick one matching the target's snippet language; the description field carries signal for non-code units |
| **Vector store** | similarity search over the index | NumPy brute-force cosine — exact, zero-dep, fine ≤ ~50k triples. Scale upgrade: FAISS HNSW/IVF |
| **Query builder** | target unit → query text `"{unit_label}: {target_unit}"` | Optional one-line NL gloss of the unit (default **off** — YAGNI) |
| **Selector** | top-N (N=30) by cosine → **MMR** select K=6 (λ=0.5) | **Fallback to random** if max-sim < τ (≈0.2) or corpus tiny. For the 100-progs budget, draw 10 varied K=6 subsets from the top-N pool (preserves FS across-prompt diversity) |
| **Prompt assembler** | feed selected examples into the chosen template | Templates **unchanged**: FS CoT (Mode A) or ZS completion (Mode B) |
| **Provenance log** | record retrieved triple ids per generation | Interpretability — FT cannot do this |

### 6.4 Mode A — RAG-FS (default)

Retrieve K=6 on-target triples → existing few-shot **CoT** template (predict
`Bug description:` then code) → target-unit query block. Identical generation contract to
FS; only example *selection* changes from random to retrieval-with-random-fallback. Per D5
the template's literal `API:` header generalizes to `{unit_label}:` (the example bodies are
unchanged real snippets).

### 6.5 Mode B — RAG-ZS (optional)

Retrieve the **single most relevant real snippet** for the target unit → existing ZS
**completion** path (truncate suffix, model completes). Verbatim ingredient reuse; lower
valid-rate (as in the paper's ZS). The ZS comment generalizes to
`# The following code reveals a bug in {target_unit}`.

## 7. Hyperparameters (new table replaces FT's)

| Param | Value | Notes |
|-------|-------|-------|
| Embedding model | pluggable | blessed local + hosted defaults (§6.3) |
| `K` (examples, Mode A) | **6** | kept — paper sweet spot |
| top-N pool | **30** | candidates before MMR |
| MMR `λ` | **0.5** | relevance vs. diversity |
| Fallback threshold `τ` | **≈0.2** | below → random selection |
| Mode B snippets | **1** | most-relevant real snippet |

**Unchanged generation contract:** `temperature=0.8`, `top_p=0.95`, `max_token=256`,
**100 programs/target unit** (10 prompts × 10 generations), **annotation `temperature=0`**.

## 8. Removals — full excision of FT (D2)

| File | Remove |
|------|--------|
| `fuzzgpt/SKILL.md` | FT from the 5-step pipeline, fast-path step 3, three-variants list, model-routing line, "picking a variant" guidance; frontmatter `fine-tune` → `retrieval`; reframe core identity + "Faithful reproduction" line |
| `fuzzgpt/references/prompt-templates.md` | §3.2.3 (FT) incl. loss/inference factorization; FT row in "picking a variant" table |
| `fuzzgpt/references/hyperparameters.md` | FT hyperparameter table, FT per-variant budget line, CodeGen-fine-tune-only model rows |
| `fuzzgpt/references/evaluation.md` | FT rows in Table 1 & Table 2; Table 5 (FT model-size) and Table 6 (FT-CoT) ablations; FT framing in RQ1 |
| `fuzzgpt/README.md` & root `README.md` | FT mentions in variant lists / descriptions |

**Retained FS rows stay** — they become RT's acceptance bar (§9).

## 9. Acceptance / validation protocol (replaces deleted paper baseline)

Because FT's parity numbers are being deleted, RT's bar is the **retained FS** coverage.
Documented in `evaluation.md` as the RT validation protocol (target-agnostic; DL libraries
are the concrete reproduction example since that is where retained FS numbers exist):

1. **Parity (single-source corpus):** on a sample of target units, run random-FS vs RAG-FS;
   assert `coverage(RAG-FS) ≥ coverage(random-FS) − ε`.
2. **Scale win (enlarged / multi-source corpus):** assert `coverage(RAG-FS) > coverage(random-FS)`.
3. **Fallback correctness:** below τ, RT's selection distribution matches random.

## 10. Error handling

- Empty corpus or embedding backend unavailable → error with remediation guidance.
- No sufficiently-similar neighbours → **random fallback** (expected path, not an error).
- Corpus/index drift → INDEX is idempotent and cheap to re-run.

## 11. Out of scope / open questions

- **Approach C** (per-module centroid specialization) — rejected, YAGNI.
- **Packaged Python module** — out of scope per D6; deliverable is markdown + a compact
  reference snippet (indexer + MMR/fallback selector) consistent with the skill's existing
  `gh` one-liners and Figure templates. **Open question:** confirm markdown-only, or do you
  also want a runnable module shipped?

## 12. File change plan

- **New:** `fuzzgpt/references/retrieval.md` — full RT methodology (target-agnostic),
  components (§6.3), Mode A/B, hyperparameters (§7), reference code snippet, validation (§9).
- **Edit:** `SKILL.md`, `prompt-templates.md`, `hyperparameters.md`, `evaluation.md`,
  `fuzzgpt/README.md`, root `README.md` per §8 + add RT routing/links.
