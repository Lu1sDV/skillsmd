# LLM Observability & Evaluation

Guide to OpenTelemetry/SDK tracing, span & dataset evaluation, prompt management, and production monitoring using LangSmith and Arize Phoenix.

## Tool Selection

| Tool | Best for | Hosting | Key strength |
|---|---|---|---|
| **LangSmith** | LangChain/LangGraph apps, managed evals, prompt hub | Managed SaaS / Enterprise | `@traceable`, `wrap_openai`, `evaluate()` CI gates, Hub prompts |
| **Arize Phoenix** | Open-source OTel tracing, vendor-neutral LLM-as-judge | Self-hosted / local / Docker | OpenInference OTel auto-instrumentation, `run_evals`, SQLite/Postgres |

---

## LangSmith (`langsmith`)

### Install and Environment

```bash
pip install "langsmith>=0.2.0"

export LANGSMITH_API_KEY="your-api-key"
export LANGSMITH_TRACING=true
export LANGSMITH_PROJECT="my-project"
# Optional: sample 10% of production traces
export LANGSMITH_TRACING_SAMPLING_RATE=0.1
```

### Tracing (`@traceable`, `wrap_openai`, Context & Distributed)

```python
from langsmith import traceable, tracing_context, trace, RunTree, get_current_run_tree
from langsmith.wrappers import wrap_openai
from openai import OpenAI

# 1. Auto-trace all OpenAI SDK calls
oai_client = wrap_openai(OpenAI())

# 2. Hierarchical traces with @traceable
@traceable(run_type="retriever")
def retrieve_context(query: str) -> list:
    return vector_store.search(query)

@traceable(
    run_type="chain",
    process_inputs=lambda x: {k: v for k, v in x.items() if k != "secret"},
)
def answer_query(query: str, secret: str = "") -> str:
    docs = retrieve_context(query)
    resp = oai_client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": f"{docs}\n\n{query}"}],
    )
    return resp.choices[0].message.content

# 3. Dynamic tags/metadata via tracing_context
with tracing_context(project_name="prod-v2", tags=["prod"], metadata={"release": "2.0"}):
    answer_query("What is RAG?")

# 4. Manual span
with trace(name="custom_tool", run_type="tool", inputs={"q": "test"}) as run:
    out = do_work()
    run.end(outputs={"result": out})
```

**Distributed tracing across services:**

```python
# Caller service
run_tree = get_current_run_tree()
headers = {"langsmith-trace": run_tree.trace_id, "langsmith-parent": run_tree.id}

# Receiving service
child = RunTree(
    name="remote_step",
    run_type="tool",
    trace_id=headers["langsmith-trace"],
    parent_run_id=headers["langsmith-parent"],
)
```

LangChain / LangGraph operations trace automatically whenever `LANGSMITH_TRACING=true`.

### Datasets, Evaluation, and CI Regression

```python
from langsmith import Client, evaluate, test
from langsmith.evaluation import LangChainStringEvaluator

client = Client()

dataset = client.create_dataset("qa-test-set", description="QA evaluation")
client.create_examples(
    inputs=[{"question": "What is Python?"}, {"question": "What is ML?"}],
    outputs=[{"answer": "A programming language"}, {"answer": "Machine learning"}],
    dataset_id=dataset.id,
)

def target_fn(inputs: dict) -> dict:
    return {"answer": answer_query(inputs["question"])}

def correctness(run, example):
    pred = run.outputs["answer"].lower()
    ref = example.outputs["answer"].lower()
    return {"key": "correctness", "score": 1.0 if ref in pred else 0.0}

results = evaluate(
    target_fn,
    data="qa-test-set",
    evaluators=[correctness, LangChainStringEvaluator("qa")],
    experiment_prefix="v1",
)
assert results.aggregate_metrics["correctness"] >= 0.9

# Pytest integration
@test
def test_qa_smoke():
    assert "programming" in answer_query("What is Python?").lower()
```

### Client Queries, Feedback, and Hub Prompts

```python
from langsmith import Client, AsyncClient

client = Client()
runs = list(client.list_runs(project_name="my-project", filter='eq(status, "success")', limit=100))
client.create_feedback(run_id=runs[0].id, key="user_rating", score=0.8, comment="Helpful")

prompt = client.pull_prompt("my-org/qa-prompt")
```

### LangSmith Troubleshooting

- **Traces missing**: Verify `LANGSMITH_TRACING=true` and `LANGSMITH_API_KEY`, then test connectivity with `Client().list_projects()`.
- **Added latency**: Ensure background batching is enabled (`Client(auto_batch_tracing=True)`, the default) and set `LANGSMITH_TRACING_SAMPLING_RATE` in high-volume production.
- **Large/sensitive payloads**: Strip heavy fields or secrets via `@traceable(process_inputs=...)`.

---

## Arize Phoenix (`arize-phoenix`)

### Install and Server Deployment

```bash
pip install "arize-phoenix>=12.0.0"
# Modular packages:
pip install arize-phoenix-otel arize-phoenix-evals arize-phoenix-client
```

```python
# Notebook / local dev
import phoenix as px
session = px.launch_app()   # http://localhost:6006
# Clean up in notebooks: session.close(); px.close_app()
```

```bash
# Production CLI or Docker with PostgreSQL
export PHOENIX_SQL_DATABASE_URL="postgresql://user:pass@host:5432/phoenix"
export PHOENIX_ENABLE_AUTH=true
export PHOENIX_SECRET="your-secret-key-min-32-chars"
export PHOENIX_ADMIN_SECRET="admin-bootstrap-token"
phoenix serve --host 0.0.0.0 --port 6006

# Docker
docker run -p 6006:6006 arizephoenix/phoenix:latest
```

Key environment variables: `PHOENIX_PORT` (`6006`), `PHOENIX_HOST` (`127.0.0.1`), `PHOENIX_GRPC_PORT` (`4317`), `PHOENIX_SQL_DATABASE_URL`, `PHOENIX_WORKING_DIR`.

### OpenTelemetry & OpenInference Tracing

```python
from phoenix.otel import register
from openinference.instrumentation.openai import OpenAIInstrumentor
from openinference.instrumentation.langchain import LangChainInstrumentor
from openinference.instrumentation.llama_index import LlamaIndexInstrumentor
from openinference.instrumentation.anthropic import AnthropicInstrumentor
from opentelemetry import trace
from opentelemetry.propagate import inject, extract

tracer_provider = register(
    project_name="my-llm-app",
    endpoint="http://localhost:6006/v1/traces",
)

# Instrument any supported SDK
OpenAIInstrumentor().instrument(tracer_provider=tracer_provider)
# LangChainInstrumentor().instrument(tracer_provider=tracer_provider)
# LlamaIndexInstrumentor().instrument(tracer_provider=tracer_provider)
# AnthropicInstrumentor().instrument(tracer_provider=tracer_provider)

# Custom spans & session tracking
tracer = trace.get_tracer(__name__)
with tracer.start_as_current_span("conversation_turn") as span:
    span.set_attribute("session.id", session_id)
    span.set_attribute("input.value", user_message)
    response = generate(user_message)
    span.set_attribute("output.value", response)
```

**Distributed OTel propagation:**

```python
# Service A
headers = {}
inject(headers)
requests.post("http://service-b/process", json=payload, headers=headers)

# Service B
ctx = extract(request.headers)
with tracer.start_as_current_span("service_b_process", context=ctx):
    ...
```

### Span Evaluation & Dataset Experiments

```python
from phoenix import Client
from phoenix.evals import (
    OpenAIModel,
    HallucinationEvaluator,
    RelevanceEvaluator,
    ToxicityEvaluator,
    llm_classify,
    run_evals,
)
from phoenix.experiments import run_experiment

client = Client(endpoint="http://localhost:6006")
eval_model = OpenAIModel(model="gpt-4o")

# 1. Evaluate collected spans
spans_df = client.get_spans_dataframe(
    project_name="my-llm-app",
    filter_condition="span_kind == 'LLM'",
    limit=1000,
)
eval_results = run_evals(
    dataframe=spans_df,
    evaluators=[HallucinationEvaluator(eval_model), RelevanceEvaluator(eval_model)],
    provide_explanation=True,
)
client.log_evaluations(eval_results)

# 2. Custom LLM-as-judge classification
result = llm_classify(
    model=eval_model,
    template="Question: {input}\nResponse: {output}\nAnswer 'helpful' or 'not_helpful'.",
    input=question,
    output=answer,
    rails=["helpful", "not_helpful"],
)

# 3. Versioned dataset & experiment regression
client.create_dataset(name="qa-test-set", description="QA evaluation dataset")
client.add_examples_to_dataset(
    dataset_name="qa-test-set",
    examples=[{"input": {"question": "What is Python?"}, "output": {"answer": "A programming language"}}],
)

def accuracy_eval(input_data, output, expected):
    hit = expected["answer"].lower() in output["answer"].lower()
    return {"score": 1.0 if hit else 0.0, "label": "correct" if hit else "incorrect"}

exp_results = run_experiment(
    dataset_name="qa-test-set",
    task=lambda inp: {"answer": answer_query(inp["question"])},
    evaluators=[accuracy_eval],
    experiment_name="baseline-v1",
)
```

### Client Queries & Human Annotations

```python
span = client.get_span(span_id="abc123")
trace_data = client.get_trace(trace_id="xyz789")
client.log_annotation(
    span_id="abc123",
    name="user_rating",
    annotator_kind="HUMAN",
    score=0.8,
    label="helpful",
)
```

### Phoenix Troubleshooting

- **Traces not appearing**: Confirm `endpoint="http://localhost:6006/v1/traces"` in `register(...)` and flush short-lived scripts with `trace.get_tracer_provider().force_flush()`.
- **Database errors**: Test `psql "$PHOENIX_SQL_DATABASE_URL" -c "SELECT 1"` and run `phoenix serve --log-level debug`.
- **Notebook memory growth**: Call `session.close()` and `px.close_app()` when finished.
