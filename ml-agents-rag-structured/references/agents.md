# Agent Frameworks, Orchestration & Evolution

Distilled reference for **LangChain**, **LlamaIndex**, **CrewAI**, **AutoGPT**, and **A-Evolve**.

## Framework Selection

| Framework | Best For | Paradigm | Key Strength |
|-----------|----------|----------|--------------|
| **LangChain** | General LLM apps, ReAct/tool-calling agents, quick RAG | Chains + tool-calling agents (LangGraph for cycles) | 500+ integrations, LangSmith tracing |
| **LlamaIndex** | Document Q&A, knowledge bases, data-centric RAG | Indices + QueryEngine/ChatEngine + FunctionAgent | 300+ LlamaHub connectors, built-in RAG eval |
| **CrewAI** | Role-based multi-agent teams & event-driven workflows | Crews (sequential/hierarchical) + Flows | Standalone (no LangChain dep), built-in memory |
| **AutoGPT** | Continuous autonomous agents, visual workflow builder | Node/block graph execution + Forge toolkit | Docker platform, webhook/cron triggers, agbenchmark |
| **A-Evolve** | Optimizing existing agents against benchmarks | Filesystem workspace + solve-observe-evolve loop | Git-gated prompt/skill/memory mutation |

---

## 1. LangChain

**Install:**
```bash
pip install -U langchain langchain-openai langchain-anthropic
# Common extras: langchain-community langchain-chroma langchain-pinecone
```

**Core patterns:**
```python
from langchain_anthropic import ChatAnthropic
from langchain.agents import create_agent

def get_weather(city: str) -> str:
    """Get current weather for a city."""
    return f"Sunny in {city}"

agent = create_agent(
    model=ChatAnthropic(model="claude-sonnet-4-5-20250929"),
    tools=[get_weather],
    system_prompt="Use tools when needed."
)
result = agent.invoke({"messages": [{"role": "user", "content": "Weather in Paris?"}]})
print(result["messages"][-1].content)
```

- **Structured output:** `structured_llm = llm.with_structured_output(PydanticModel)`
- **Streaming:** `llm.stream(prompt)` or `agent_executor.stream({"input": ...})`
- **Text splitting & RAG:** `RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)` -> `Chroma.from_documents(splits, OpenAIEmbeddings())` -> `vectorstore.as_retriever(search_kwargs={"k": 4})` -> `RetrievalQA.from_chain_type(llm=llm, retriever=retriever, return_source_documents=True)`.
- **LangSmith observability:** Set `LANGCHAIN_TRACING_V2=true`, `LANGCHAIN_API_KEY`, `LANGCHAIN_PROJECT`.
- **LangChain vs LangGraph:** Use `create_agent()` for linear tool-calling; switch to **LangGraph** for stateful cyclic graphs, fine-grained node control, or advanced human-in-the-loop.

**Gotchas:**
- Wrap risky tools in `try/except` returning an error string so the agent recovers instead of crashing.
- Pass `allow_dangerous_deserialization=True` only for trusted local `FAISS.load_local(...)` indices.

---

## 2. LlamaIndex

**Install:**
```bash
pip install llama-index
# Or modular: pip install llama-index-core llama-index-llms-openai llama-index-embeddings-openai
```

**Core patterns:**
```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings, StorageContext, load_index_from_storage
from llama_index.llms.anthropic import Anthropic
from llama_index.embeddings.huggingface import HuggingFaceEmbedding

Settings.llm = Anthropic(model="claude-sonnet-4-5-20250929")
Settings.embed_model = HuggingFaceEmbedding(model_name="sentence-transformers/all-mpnet-base-v2")

docs = SimpleDirectoryReader("./data", recursive=True, required_exts=[".pdf", ".md"]).load_data()
index = VectorStoreIndex.from_documents(docs)
index.storage_context.persist(persist_dir="./storage")

# Reload later:
storage_context = StorageContext.from_defaults(persist_dir="./storage")
index = load_index_from_storage(storage_context)

# Query engine & chat engine:
qe = index.as_query_engine(similarity_top_k=3, response_mode="compact", streaming=True)
ce = index.as_chat_engine(chat_mode="condense_plus_context")
```

- **Metadata filtering:** `MetadataFilters(filters=[ExactMatchFilter(key="category", value="tutorial")])` passed to `as_retriever(filters=...)` or `as_query_engine(filters=...)`.
- **RAG Agent:** Wrap a query engine with `QueryEngineTool.from_defaults(query_engine=qe, name="docs", description="...")` and pass to `FunctionAgent.from_tools(tools=[query_tool, ...], llm=llm)`.
- **Evaluation:** `RelevancyEvaluator().evaluate_response(query=..., response=...)` and `FaithfulnessEvaluator().evaluate_response(...)`.

**Gotchas:**
- Always persist `storage_context` to disk (`persist_dir`) to avoid re-embedding on every run.
- `Settings.llm` and `Settings.embed_model` are global; configure them before building indices.

---

## 3. CrewAI

**Install & CLI:**
```bash
pip install crewai 'crewai[tools]'
crewai create crew my_project && cd my_project
crewai install && crewai run
```

**Crews (role-based collaboration):**
```python
from crewai import Agent, Task, Crew, Process, LLM

llm = LLM(model="claude-sonnet-4-5-20250929")  # or "gpt-4o", "ollama/llama3.1"
researcher = Agent(
    role="Senior Research Analyst",
    goal="Discover trends in {topic}",
    backstory="Expert analyst.",
    llm=llm,
    max_iter=15,
    max_rpm=10,
    allow_delegation=True,
)
writer = Agent(role="Writer", goal="Write report", backstory="Technical writer.", llm=llm)

t1 = Task(description="Research {topic}", expected_output="5 bullet points", agent=researcher)
t2 = Task(description="Draft post", expected_output="Markdown post", agent=writer, context=[t1], output_file="report.md")

crew = Crew(agents=[researcher, writer], tasks=[t1, t2], process=Process.sequential, memory=True, verbose=True)
result = crew.kickoff(inputs={"topic": "AI Agents"})
print(result.raw, result.token_usage)
```

- **Hierarchical process:** `process=Process.hierarchical, manager_llm="gpt-4o"` auto-creates a manager agent.
- **YAML project layout:** `@CrewBase` class with `config/agents.yaml` and `config/tasks.yaml`, decorated methods `@agent`, `@task`, `@crew`.
- **Flows (event-driven):** Subclass `Flow[MyState]` (`BaseModel` state) using `@start()`, `@listen(fn)`, `@router(fn)`.
- **Custom tools:** Subclass `crewai.tools.BaseTool` with `name`, `description`, and `_run(self, ...) -> str`.

**Gotchas:**
- Limit agents to 3-5 tools and set `max_iter` / `max_rpm` to prevent infinite reasoning loops or rate-limit errors.
- Explicitly pass `context=[prior_task]` on downstream `Task`s so outputs flow reliably.
- Set `CREWAI_STORAGE_DIR=./my_storage` if default memory storage paths cause permission/state issues.

---

## 4. AutoGPT

Two modes: **AutoGPT Platform** (visual node/block builder, FastAPI + React + Postgres/Redis/RabbitMQ) and **AutoGPT Classic** (Forge CLI + agbenchmark).

**Platform quick start (Docker):**
```bash
git clone https://github.com/Significant-Gravitas/AutoGPT.git
cd AutoGPT/autogpt_platform
cp .env.example .env && docker compose up -d --build
# Frontend: http://localhost:3000 | Backend API: http://localhost:8006/api | WS: ws://localhost:8001/ws
```

- **Execution triggers:**
  - Manual: `POST /api/v1/graphs/{graph_id}/execute` with `{"inputs": {...}}`
  - Webhook: `POST /api/v1/webhooks/{webhook_id}`
  - Scheduled: cron string e.g. `"0 */2 * * *"`
- **Forge (Classic) & Benchmarks:**
  ```bash
  cd classic && ./run setup
  ./run forge create my-agent && ./run forge start my-agent
  ./run benchmark --category coding --agent my-agent   # Uses VCR cassettes (--record / --playback)
  ```
- **Production env vars:** `DATABASE_URL`, `REDIS_URL`, `RABBITMQ_URL`, `ENCRYPTION_KEY` (generate via `poetry run cli gen-encrypt-key`), `SUPABASE_URL`.

**Gotchas:**
- Stuck executions usually live in RabbitMQ (`http://localhost:15672`); run `docker compose restart executor` or run `poetry run prisma migrate deploy` if DB migrations lag.

---

## 5. A-Evolve

Universal evolution layer that optimizes any agent's filesystem workspace (`prompts/system.md`, `skills/*/SKILL.md`, `memory/*.jsonl`, `tools/`) via a **Solve -> Observe -> Evolve -> Gate -> Reload** loop.

**Install & quick start:**
```bash
pip install a-evolve  # or a-evolve[anthropic], a-evolve[all]
```

```python
import agent_evolve as ae

config = ae.EvolveConfig(
    batch_size=10,
    max_cycles=20,
    holdout_ratio=0.2,
    evolve_prompts=True,
    evolve_skills=True,
    evolve_memory=True,
    evolver_model="us.anthropic.claude-opus-4-6-v1",
    egl_threshold=0.05,
    egl_window=3,
)
evolver = ae.Evolver(agent="./my-agent-workspace", benchmark="swe-verified", config=config)
results = evolver.run(cycles=10)
print(results.final_score, results.score_history)
```

- **Pluggable interfaces:**
  - `ae.BaseAgent`: implement `solve(task) -> ae.Trajectory` and `reload_from_fs()` (re-reads evolved files after each cycle).
  - `ae.BenchmarkAdapter`: implement `get_tasks(split="train", limit=None)` and `evaluate(task, trajectory) -> ae.Feedback(success, score, detail)`.
  - `ae.EvolutionEngine`: implement `step(workspace, observations, history, trial) -> ae.StepResult`.
- **Built-in seeds & benchmarks:** Seeds `"swe"`, `"terminal"`, `"mcp"`; benchmarks `"swe-verified"`, `"mcp-atlas"`, `"terminal2"`, `"skill-bench"`, `"arc-agi-3"`.

**Gotchas:**
- Always `git init` and commit the seed workspace before evolving; gating uses git snapshots (`evo-1`, `evo-2`, ... tags) for rollback.
- Run each `evolver.run()` on its own workspace copy to avoid git conflicts.
- Keep `trajectory_only=False` and include specific failure reasons in `Feedback.detail` so the evolver diagnoses errors instead of plateauing early.
