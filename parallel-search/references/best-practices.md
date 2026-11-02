# Best Practices — Parallel Search

Prompting strategy for `parallel-cli search` to maximize result quality. An effective search has two components: a clear **objective** (what you want to know and why) and targeted **keyword queries** (terms to match).

## Objective Writing

The objective is a 1-3 sentence natural-language description of your search intent. The search engine uses this to rank and filter results.

### What to Include

- **Task context** — Why you need this information (helps the engine prioritize relevant sources)
- **Freshness constraints** — "Prefer 2026+", "latest docs only", "post-January 2025"
- **Source preferences** — "Official docs preferred", "primary sources only", "news from major outlets"
- **Scope boundaries** — "US market only", "open-source tools", "enterprise-grade solutions"

### Examples

**Good:**
```
Research the current state of WebAssembly outside the browser for server-side workloads.
Focus on WASI preview 2, component model adoption, and production use cases.
Prefer 2025-2026 sources from official projects and technical blogs.
```

**Poor:**
```
Tell me about WebAssembly
```

**Good:**
```
Find the latest CVEs affecting Kubernetes ingress controllers published in 2026.
Prioritize official NVD entries and vendor advisories.
Include severity scores and exploit availability.
```

**Poor:**
```
Kubernetes security issues
```

### Template

```
[What information you need]. [Why you need it / how you'll use it].
[Freshness: prefer YEAR+ / latest only / no constraint].
[Sources: official docs / primary sources / news / academic].
```

## Keyword Queries

Keyword queries (`-q` flag) provide concrete terms for the search engine to match. Use 3-8 queries for best results.

### What Makes a Good Keyword Query

- **Specific terms**: "WebAssembly component model", "WASI preview 2", not "wasm"
- **Version numbers**: "React 19", "Python 3.12", "Kubernetes 1.30"
- **Error strings**: `"cannot find module"`, `"connection refused"` (use quotes for exact phrases)
- **Proper nouns**: "Bytecode Alliance", "CNCF", "Fermyon Spin"
- **Date terms**: "2026", "Jan 2026", "Q1 2026"
- **Common synonyms**: Include alternative phrasings the engine might miss

### Strategy by Search Type

| Search Type | Keyword Pattern | Example |
|-------------|----------------|---------|
| **Current events** | topic + year + "news" | `-q "quantum" -q "2026" -q "announced"` |
| **Technical docs** | tool + version + concept | `-q "React" -q "19" -q "server components"` |
| **Bug investigation** | error string + library + version | `-q "TypeError: undefined" -q "next.js" -q "15.1"` |
| **Competitive analysis** | company names + feature terms | `-q "Stripe" -q "Square" -q "pricing" -q "API"` |
| **Academic/literature** | domain term + methodology + "paper" | `-q "transformer" -q "attention mechanism" -q "survey"` |

### What to Avoid

- **Vague terms**: "stuff", "things", "cool features"
- **Overly broad queries**: A single keyword query of "security" is useless
- **Redundant queries**: `-q "React" -q "react" -q "REACT"` is wasteful (search is case-insensitive by default for single terms — use quotes for exact case matching)
- **Too many queries**: More than 12 degrades precision

## Domain Scoping Strategy

### When to Use Include-Domains

Use `--include-domains` when you know exactly which sources are authoritative:

- **Official docs**: `react.dev`, `docs.python.org`, `kubernetes.io/docs`
- **GitHub**: `github.com/org/repo` for specific project issues/discussions
- **Known quality sources**: `arxiv.org` for papers, `cve.org` for vulnerabilities
- **Forums**: `stackoverflow.com`, `discuss.python.org`

### When to Use Exclude-Domains

Use `--exclude-domains` when you encounter consistent low-quality results from certain domains:

- Content farms and SEO spam
- Paywalled sources you can't access
- Sources in wrong language for your needs
- Domains you've already reviewed exhaustively

### Combining Include and Exclude

```bash
parallel-cli search "Rust async executor benchmarks" \
  --include-domains github.com --include-domains crates.io \
  --exclude-domains medium.com --exclude-domains dev.to \
  -q "tokio" -q "async-std" -q "smol" -q "benchmark" \
  --json --max-results 10
```

## Quality Checklist

Before submitting a search, verify:

- [ ] Objective is specific (not "tell me about X")
- [ ] Objective includes freshness constraint if relevant
- [ ] 3-8 keyword queries provided
- [ ] Keywords include version numbers / dates if applicable
- [ ] Domain scoping used if known authoritative sources exist
- [ ] `--max-results` set appropriately (5 for quick lookup, 10-15 for thorough)
- [ ] `--json` flag included for programmatic consumption
