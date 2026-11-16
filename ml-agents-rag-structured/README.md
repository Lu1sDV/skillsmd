# ml-agents-rag-structured

Consolidated skill for LLM agent frameworks, RAG vector databases, and
programmatic/constrained structured prompting. [SKILL.md](SKILL.md) is a short
orchestrator that routes to three independently readable references, loaded only
when the task needs them:

- [references/agents.md](references/agents.md) — LangChain, LlamaIndex, CrewAI,
  AutoGPT, and A-Evolve (tool calling, RAG indices, multi-agent crews/flows,
  visual automation, and workspace evolution).
- [references/rag-vectordbs.md](references/rag-vectordbs.md) — Sentence
  Transformers, FAISS, Chroma, Qdrant, and Pinecone (embeddings, index types,
  metadata filtering, hybrid dense+sparse retrieval, and quantization).
- [references/structured-prompting.md](references/structured-prompting.md) —
  DSPy, Instructor, Outlines, and Guidance (declarative optimization, Pydantic
  validation/retries, FSM-constrained decoding, and regex/CFG token healing).

## Install and use

Copy the complete `ml-agents-rag-structured/` directory into your agent's
skills directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-agents-rag-structured ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-agents-rag-structured@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-agents-rag-structured
```

Examples:
- "Build a CrewAI sequential crew with a researcher and writer agent."
- "Set up Qdrant hybrid search with INT8 quantization and payload indexing."
- "Extract a validated Pydantic model from text using Instructor with retries."
- "Optimize a DSPy RAG module with BootstrapFewShot."

## Sources and adaptation

Condensed from 14 upstream skills in
[Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)
(MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`, see
[LICENSE.upstream](LICENSE.upstream)):

- `14-agents/langchain/SKILL.md`
- `14-agents/llamaindex/SKILL.md`
- `14-agents/crewai/SKILL.md`
- `14-agents/autogpt/SKILL.md`
- `14-agents/a-evolve/SKILL.md`
- `15-rag/sentence-transformers/SKILL.md`
- `15-rag/faiss/SKILL.md`
- `15-rag/chroma/SKILL.md`
- `15-rag/qdrant/SKILL.md`
- `15-rag/pinecone/SKILL.md`
- `16-prompt-engineering/dspy/SKILL.md`
- `16-prompt-engineering/instructor/SKILL.md`
- `16-prompt-engineering/outlines/SKILL.md`
- `16-prompt-engineering/guidance/SKILL.md`

These references are distilled, deduplicated engineering guides, not vendored
copies of the full upstream trees.

Validation: YAML frontmatter, local reference links, and the static skill-smell
checks via `check_static_smells.py`.
