# Advanced Workflows — Parallel Search

Multi-step search patterns, domain scoping strategies, and integration with other Parallel tools for complex research tasks.

## Workflow: Multi-Round Refinement

When the first search doesn't yield adequate results, refine iteratively:

```
Round 1: Broad search → identify key terms and authoritative domains
Round 2: Domain-scoped search → deeper results from best sources
Round 3: Targeted extract → read full content from top pages
```

### Example: Researching a New Technology

**Round 1 — Discovery:**
```bash
parallel-cli search "WASM component model current status and adoption" \
  -q "WebAssembly" -q "component model" -q "WASI" \
  --json --max-results 10
```
Analyze results to identify: key projects, official domains, common terminology.

**Round 2 — Deep dive:**
```bash
parallel-cli search "WASM component model production deployment" \
  -q "component model" -q "production" -q "deployment" -q "2026" \
  --include-domains bytecodealliance.org --include-domains github.com \
  --json --max-results 10
```

**Round 3 — Extract details:**
```bash
parallel-cli extract \
  --url "https://component-model.bytecodealliance.org/" \
  --url "https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md" \
  --json
```

## Workflow: Cross-Source Verification

Verify facts by searching across multiple authoritative domains:

```bash
# Search official docs
parallel-cli search "Python 3.13 GIL removal status" \
  --include-domains docs.python.org \
  -q "PEP 703" -q "free-threaded" -q "GIL" \
  --json --max-results 5

# Search community discussion
parallel-cli search "Python 3.13 free-threaded production experience" \
  --include-domains discuss.python.org --include-domains github.com \
  -q "free-threaded" -q "production" -q "crash" \
  --json --max-results 5
```

Compare results. When official docs and community experience disagree, present both with clear source attribution.

## Workflow: Temporal Analysis

Track how a topic has evolved over time using date-scoped searches:

```bash
# What's current?
parallel-cli search "AI coding assistants latest developments" \
  --after-date 2026-03-01 \
  -q "coding" -q "assistant" -q "2026" \
  --json --max-results 10

# What was the state 6 months ago?
parallel-cli search "AI coding assistants developments" \
  --after-date 2025-10-01 \
  -q "coding" -q "assistant" -q "2025" \
  --json --max-results 10 -o /tmp/ai-coding-past.json
```

Synthesize a timeline by comparing current vs. past results.

## Workflow: Competitive Landscape

Research competitors or alternatives systematically:

```bash
# Round 1: Discover alternatives
parallel-cli search "Vector database comparison 2026" \
  -q "Pinecone" -q "Weaviate" -q "Qdrant" -q "Milvus" -q "Chroma" \
  --json --max-results 10

# Round 2: Deep dive on each
parallel-cli search "Qdrant vector database production performance" \
  -q "Qdrant" -q "benchmark" -q "production" -q "latency" \
  --json --max-results 5
```

## Workflow: Search → Extract → Synthesize Pipeline

The canonical multi-tool workflow combining Parallel tools:

```
1. parallel-cli search  → discover URLs and excerpts
2. parallel-cli extract → read full content from top URLs
3. Synthesize           → combine into user-facing answer
```

### Full Example

**Step 1: Search**
```bash
parallel-cli search "Rust web framework comparison Axum vs Actix vs Rocket 2026" \
  -q "Axum" -q "Actix" -q "Rocket" -q "benchmark" -q "production" \
  --json --max-results 10 -o /tmp/rust-frameworks-search.json
```

**Step 2: Extract top sources**
```bash
# Parse search results to find top URLs, then extract
parallel-cli extract \
  --url "https://www.shuttle.dev/blog/2024/01/30/rust-web-framework-comparison" \
  --url "https://github.com/tokio-rs/axum" \
  --objective "framework features, performance, and production readiness" \
  --json -o /tmp/rust-frameworks-extract.json
```

**Step 3: Synthesize**
Read `/tmp/rust-frameworks-search.json` and `/tmp/rust-frameworks-extract.json`.
Produce a structured comparison with citations from both sources.

## Domain Scoping Reference

### Common Authoritative Domains by Category

| Category | Domains |
|----------|---------|
| **Python** | `docs.python.org`, `peps.python.org`, `pypi.org`, `discuss.python.org` |
| **JavaScript/Node** | `nodejs.org`, `developer.mozilla.org`, `npmjs.com` |
| **React** | `react.dev`, `github.com/facebook/react` |
| **Rust** | `doc.rust-lang.org`, `crates.io`, `blog.rust-lang.org` |
| **Go** | `go.dev`, `pkg.go.dev`, `github.com/golang/go` |
| **Kubernetes** | `kubernetes.io`, `github.com/kubernetes/kubernetes` |
| **Security/CVEs** | `nvd.nist.gov`, `cve.org`, `cve.mitre.org` |
| **Academic** | `arxiv.org`, `scholar.google.com`, `dl.acm.org` |
| **Regulatory/Government** | `.gov` domains, `ec.europa.eu`, `legislation.gov.uk` |
| **Cloud Providers** | `aws.amazon.com`, `cloud.google.com`, `learn.microsoft.com/azure` |

### When Not to Use Domain Scoping

Skip domain scoping when:
- You're exploring an unfamiliar topic and don't know the authoritative sources yet
- The topic is niche with few sources (domain scoping might exclude the only relevant page)
- You need broad discovery to surface unexpected relevant results
- The search engine's default ranking is already sufficient

## Performance Tuning

### Latency vs. Completeness

| Goal | `--max-results` | `--excerpt-max-chars-total` | Expected Latency |
|------|-----------------|-----------------------------|------------------|
| Quick fact check | 3-5 | 2000 | ~1-2s |
| Standard lookup | 5-10 | 8000 | ~2-4s |
| Thorough research | 10-15 | 20000 | ~4-8s |
| Exhaustive sweep | 15-20 | 50000 | ~8-15s |

Note: Latency is approximate. Network conditions, query complexity, and API load affect actual response times.

### Batch Searching

For large research projects, batch independent searches to run concurrently. Save each to a separate file:

```bash
# Run these in parallel (they're independent)
parallel-cli search "Topic A..." --json -o /tmp/search-A.json &
parallel-cli search "Topic B..." --json -o /tmp/search-B.json &
parallel-cli search "Topic C..." --json -o /tmp/search-C.json &
wait
```

Then synthesize from all three files sequentially.
