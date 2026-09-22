# Taint Analysis

> **Load when**: Load when entering Phase L4 (Taint Analysis) — strategy selection, controllability classification, output-filter semantics, circulatory tracing, and DAG-trace requirements for high-stakes findings.

## Strategy Selection

Three strategies (plus circulatory tracing) — choose based on codebase size:

| Strategy | When | Method |
|----------|------|--------|
| **Source-forward** | Small codebase, few entry points | Trace from user input → through transforms → to sinks |
| **Sink-backward** | Large codebase, known dangerous functions | Start at sinks (see `../sinks-catalog.md`) → trace backward to find controllable inputs |
| **Hybrid** | Medium codebase, complex data flow | Combine both: forward from sources AND backward from sinks, meet in the middle |
| **Circulatory tracing** | Any codebase, complement to other strategies | Map the full journey of every input through *all* program domains — not just to known sinks, but through every transformation and domain crossing |

## Controllability Classification

For each sink parameter:

- **High**: Direct user input reaches sink with no sanitization
- **Medium**: Input reaches sink through partial transforms (encoding, type casting)
- **Low**: Input is significantly constrained but still partially controllable
- **Needs verification**: Theoretical path exists, requires dynamic confirmation

## Output Filter Internals

When a template engine or framework marks output as "safe" or "escaped", verify HOW it escapes. Django's `|safe`, Twig's `|raw`, Rails' `html_safe`, React's `dangerouslySetInnerHTML`, and Jinja2's `|safe` all disable auto-escaping — but even auto-escaped output can be vulnerable in non-HTML contexts (JavaScript strings, CSS `url()`, HTML attributes without quotes). A filter labeled `is_safe` in Django means "this filter's output doesn't need further escaping" — it does NOT mean the output IS safe. Trace through the filter chain to confirm the escaping matches the output context.

## Circulatory Tracing Insight

Vulnerabilities hide not in the obvious "security" parts of programs but where inputs cross into unexpected domains. Trace inputs through *every* domain boundary — not just to known sinks:

- HTTP parameter → YAML parser → object instantiation → method dispatch (Rails YAML RCE)
- Uploaded image → image library → font rendering subsystem → memory allocator (browser RCE)
- User string → template engine → compilation → code execution (SSTI)
- Config value → DNS resolver → network request → internal service (SSRF via config)

The domain knowledge needed is "arbitrary" — font internals, serialization formats, protocol edge cases. The LLM already encodes this. **Ask about every code path the input touches**, not just paths that look security-relevant.

## Sink Language Router

Load `../sinks-catalog.md` for the language router and SAST/DAST integration rules. It routes to per-language sink files — load only the language(s) matching the target codebase.

## DAG-Structured Trace (High-Stakes Findings)

Free-prose source→sink narration is the single highest source of hallucinated findings — the DAGVul paper measured 36.4% of correct LLM vulnerability verdicts as supported by *incorrect* reasoning. When a finding will be reported (not just observed), restate its trace as a DAG: ground-truth source nodes with line refs → intermediate inference nodes that cite parent IDs and name the program-analysis primitive (taint, def-use, CFG, constraint, API contract) → a `verified_sink` or `sanitized_sink`. If the graph does not close from an untrusted source to a verified sink, the finding is not exploitable — move it to Observations rather than hedging. Load `../methodology/dag-reasoning.md` for the framework, the 12 failure patterns to screen each intermediate node against, and worked examples.
