# Programmatic Prompting & Constrained Structured Outputs

Distilled reference for **DSPy**, **Instructor**, **Outlines**, and **Guidance**.

## Tool Selection

| Tool | Primary Role | Enforcement Mechanism | Best For |
|------|--------------|-----------------------|----------|
| **DSPy** | Declarative LM programming & optimization | Signatures + teleprompt optimizers + assertions | Systematic prompt/few-shot optimization, multi-stage pipelines |
| **Instructor** | Pydantic structured extraction (API LLMs) | Tool/JSON mode + Pydantic validation + auto-retry | OpenAI/Anthropic/Ollama extraction with `ValidationError` retries |
| **Outlines** | Zero-overhead constrained generation (local) | JSON Schema / Regex / CFG -> Finite State Machine (FSM) | Local models (Transformers, llama.cpp, vLLM) needing 100% valid JSON/regex |
| **Guidance** | Pythonic grammar & token-healing workflows | Context-free grammars + regex + token healing | Fine-grained control flow, ReAct loops, regex/grammar constraints |

---

## 1. DSPy (Declarative Programming & Prompt Optimization)

**Install:** `pip install dspy` (or `dspy[openai]`, `dspy[anthropic]`, `dspy[all]`)

**Core primitives:**
- **Signatures:** `dspy.Predict("context, question -> answer")` or subclass `dspy.Signature` with `dspy.InputField(desc=...)` and `dspy.OutputField(desc=...)`.
- **Modules:** `dspy.Predict`, `dspy.ChainOfThought` (adds `.rationale`), `dspy.ReAct(Sig, tools=[...])`, `dspy.ProgramOfThought`, `dspy.TypedPredictor(Sig)` (Pydantic fields), `dspy.Retrieve(k=3)`.
- **Optimizers (`dspy.teleprompt`):** `BootstrapFewShot`, `MIPRO`, `BootstrapFinetune`.

```python
import dspy
from dspy.teleprompt import BootstrapFewShot
from dspy.evaluate import Evaluate

lm = dspy.Claude(model="claude-sonnet-4-5-20250929")
dspy.settings.configure(lm=lm)

class QA(dspy.Signature):
    """Answer questions with short factual answers."""
    question = dspy.InputField()
    answer = dspy.OutputField(desc="1-5 words")

class RAG(dspy.Module):
    def __init__(self, k=3):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=k)
        self.generate = dspy.ChainOfThought(QA)

    def forward(self, question):
        context = self.retrieve(question).passages
        return self.generate(context=context, question=question)

def exact_match(example, pred, trace=None):
    return example.answer.lower() == pred.answer.lower()

trainset = [dspy.Example(question="...", answer="...").with_inputs("question")]
optimizer = BootstrapFewShot(metric=exact_match, max_bootstrapped_demos=3)
optimized_rag = optimizer.compile(RAG(), trainset=trainset)
optimized_rag.save("models/rag_v1.json")

# Evaluate
evaluator = Evaluate(devset=testset, metric=exact_match, num_threads=4)
score = evaluator(optimized_rag)
```

- **Multi-LM context:** `with dspy.settings.context(lm=cheap_lm): ...`
- **Assertions:** `dspy.Assert(cond, "msg", backtrack=backtrack_handler)`

**Gotchas:**
- Always call `.with_inputs("question", ...)` on `dspy.Example`; otherwise DSPy treats input fields as labels during compilation.
- Inspect `dspy.settings.trace` (set `trace=[]` in `configure`) when debugging prompt compilation.

---

## 2. Instructor (Pydantic Extraction + Auto-Retry)

**Install:** `pip install instructor` (or `"instructor[anthropic]"`, `"instructor[openai]"`, `"instructor[all]"`)

**Core API:**
```python
import instructor
from pydantic import BaseModel, Field, field_validator, model_validator
from anthropic import Anthropic
from openai import OpenAI

# Anthropic
client = instructor.from_anthropic(Anthropic())
# OpenAI / Ollama:
# client = instructor.from_openai(OpenAI(base_url="http://localhost:11434/v1", api_key="ollama"), mode=instructor.Mode.JSON)

class Review(BaseModel):
    sentiment: str = Field(description="positive, negative, or neutral")
    score: int = Field(ge=1, le=5)

    @field_validator("sentiment")
    @classmethod
    def check_sentiment(cls, v: str) -> str:
        if v not in {"positive", "negative", "neutral"}:
            raise ValueError("Must be positive, negative, or neutral")
        return v

review = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Review: Great product!"}],
    response_model=Review,
    max_retries=3,
)
```

- **Streaming:**
  - Partial object: `client.messages.create_partial(..., response_model=Story)`
  - Iterable list: `client.messages.create_iterable(..., response_model=Task)`
- **Modes:** `Mode.ANTHROPIC_TOOLS` (Claude), `Mode.TOOLS` (OpenAI), `Mode.JSON` (Ollama / fallback).
- **Dynamic schemas:** `pydantic.create_model("User", name=(str, ...), age=(int, Field(ge=0)))`.

**Gotchas:**
- Put extraction hints in `Field(description=...)` and use `Optional[...] = None` for fields that may be absent in source text so retries don't fail on missing data.
- Catch `pydantic.ValidationError` when `max_retries` is exhausted.

---

## 3. Outlines (FSM Constrained Decoding)

**Install:** `pip install outlines transformers` (or `llama-cpp-python`, `vllm`)

**Backends:**
- `outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct", device="cuda")`
- `outlines.models.llamacpp("./model.gguf", n_ctx=4096, n_gpu_layers=35)`
- `outlines.models.vllm("meta-llama/Llama-3.1-8B-Instruct", tensor_parallel_size=2)`
- `outlines.models.openai("gpt-4o-mini", api_key="...")` (limited compared to local FSM)

**Generators:**
```python
import outlines
from pydantic import BaseModel, Field
from typing import Literal

model = outlines.models.transformers("microsoft/Phi-3-mini-4k-instruct", device="cuda")

# 1. JSON / Pydantic (compiled to CFG -> FSM, 100% valid)
class Entity(BaseModel):
    name: str
    kind: Literal["PERSON", "ORG", "LOC"]
    confidence: float = Field(ge=0.0, le=1.0)

gen_json = outlines.generate.json(model, Entity)
entity = gen_json("Extract entity from: Tim Cook leads Apple.")

# 2. Choice, Regex, Numeric
gen_choice = outlines.generate.choice(model, ["positive", "negative", "neutral"])
gen_regex = outlines.generate.regex(model, r"[0-9]{3}-[0-9]{3}-[0-9]{4}")
gen_int = outlines.generate.integer(model)
gen_float = outlines.generate.float(model)
```

**Gotchas:**
- FSM compilation happens once per schema and is cached—reuse `generator` objects across batch items instead of recreating `outlines.generate.json(...)` inside a loop.
- Outlines guarantees syntactic/schema validity at token-sampling time; unlike Instructor, it does not run Python `@field_validator` retry loops for semantic checks.

---

## 4. Guidance (Grammar, Regex & Token Healing)

**Install:** `pip install guidance` (or `guidance[transformers]`, `guidance[llama_cpp]`)

**Core API:**
```python
from guidance import models, gen, select, system, user, assistant, guidance

lm = models.Anthropic("claude-sonnet-4-5-20250929")
# Other backends: models.OpenAI("gpt-4o-mini"), Transformers("...", device="cuda"), LlamaCpp("...", n_ctx=4096)

with system():
    lm += "Extract structured fields."
with user():
    lm += "Event: Launch on 2025-05-01, contact ops@example.com."
with assistant():
    lm += "Status: " + select(["pending", "approved", "rejected"], name="status")
    lm += "\nDate: " + gen("date", regex=r"\d{4}-\d{2}-\d{2}", max_tokens=10)
    lm += "\nEmail: " + gen("email", regex=r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", max_tokens=50)

print(lm["status"], lm["date"], lm["email"])
```

- **Reusable & stateful functions:** Decorate with `@guidance` (or `@guidance(stateless=False)` for multi-turn/ReAct loops).
- **Token healing:** Enabled by default—Guidance backs up across prompt/generation token boundaries to prevent double-space or split-token artifacts.
- **Stop sequences:** Always set `stop="\n"` or `max_tokens` on unconstrained `gen(...)` calls.

**Gotchas:**
- Overly narrow regexes (e.g., exact-string alternation with tight `max_tokens`) can stall or fail; keep regexes focused on structural format and use `select(...)` for fixed enum choices.
