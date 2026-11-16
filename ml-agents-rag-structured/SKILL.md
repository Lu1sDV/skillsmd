---
name: ml-agents-rag-structured
description: >
  Use when building LLM agent workflows, RAG retrieval pipelines, vector
  databases, or programmatic/constrained structured outputs. Covers LangChain,
  LlamaIndex, CrewAI, AutoGPT, A-Evolve; Sentence Transformers, FAISS, Chroma,
  Qdrant, Pinecone; and DSPy, Instructor, Outlines, Guidance. Triggers on
  'LangChain', 'LlamaIndex', 'CrewAI', 'AutoGPT', 'A-Evolve', 'RAG', 'FAISS',
  'Chroma', 'Qdrant', 'Pinecone', 'sentence-transformers', 'DSPy', 'Instructor',
  'Outlines', 'Guidance', 'vector database', or 'structured output'.
---

# ML Agents, RAG & Structured Prompting

Three focused references, one per layer of an LLM application stack. Open only
the reference the task needs; do not preload all.

| Task / Tool | Read |
|---|---|
| Agent frameworks, tool calling, multi-agent orchestration, agent evolution: LangChain, LlamaIndex, CrewAI, AutoGPT, A-Evolve | [Agents & orchestration](references/agents.md) |
| Embeddings, vector indices, hybrid/filtered retrieval: Sentence Transformers, FAISS, Chroma, Qdrant, Pinecone | [RAG & vector DBs](references/rag-vectordbs.md) |
| Programmatic prompt optimization & Pydantic/grammar-constrained outputs: DSPy, Instructor, Outlines, Guidance | [Structured prompting](references/structured-prompting.md) |

## What each covers

- **Agents & orchestration** — Single-agent ReAct/tool-calling (LangChain),
  data-centric RAG indices and query engines (LlamaIndex), role-based Crews and
  event-driven Flows (CrewAI), visual node-graph automation (AutoGPT), and
  git-gated workspace evolution (A-Evolve).
- **RAG & vector DBs** — Local dense embeddings and fine-tuning (Sentence
  Transformers), billion-scale similarity indices (FAISS), embedded/local DB
  (Chroma), production Rust hybrid search with payload indexing and quantization
  (Qdrant), and managed serverless vector storage (Pinecone).
- **Structured prompting** — Signature-based declarative pipelines and
  teleprompt optimization (DSPy), Pydantic validation with auto-retries
  (Instructor), FSM-constrained local decoding (Outlines), and regex/CFG
  generation with token healing (Guidance).

## Universal rules

- Pin framework and provider package versions in project dependencies; APIs
  between major releases (e.g., LangChain, LlamaIndex, DSPy) evolve rapidly.
- Check available VRAM/RAM and match embedding dimensions (`384`, `768`,
  `1536`) before loading local models or creating vector indices.
- Keep API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `PINECONE_API_KEY`,
  `QDRANT_API_KEY`) in environment variables rather than source code.
- Bound autonomous agent loops (`max_iter`, `max_rpm`, `max_retries`) and
  persist vector indices/storage to disk so runs are reproducible and safe.
- Verify retrieval results, schema validation (`ValidationError`), and benchmark
  metrics directly against held-out data instead of assuming correctness.
- Use forward slashes (`/`) for all file paths.
