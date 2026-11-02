---
name: parallel-search
description: >
  AI-powered web search via Parallel API. Returns ranked results with
  LLM-optimized excerpts. Use for up-to-date research, fact-checking,
  domain-scoped searching, and discovering web content. Triggers: "search
  the web", "web search", "look up", "find online", "current news about",
  "research [topic]", "fact-check", "find on Reddit/GitHub/Stack Overflow".
homepage: https://parallel.ai
---

# Parallel Search

High-accuracy web search built for AI agents. Returns ranked results with
intelligent excerpts optimized for LLM consumption.

## When to Use

Trigger this skill when the user asks for:
- "search the web", "web search", "look up", "find online"
- "current news about...", "latest updates on..."
- "research [topic]", "what's happening with..."
- Fact-checking with citations needed
- Domain-specific searches (e.g., "search GitHub for...", "find on Reddit...")

**Use Search to discover; use [Parallel Extract](../parallel-extract/SKILL.md) to read.**

## Quick Start

```bash
parallel-cli search "your query" --json --max-results 5
```

## Basic Usage

```bash
parallel-cli search "<objective>" [options]
```

| Flag | Description |
|------|-------------|
| `-q, --query "<keyword>"` | Keyword filter (repeatable, 3-8 recommended) |
| `--max-results N` | Number of results (1-20, default: 10) |
| `--json` | Output as JSON |
| `--after-date YYYY-MM-DD` | Filter for recent content |
| `--include-domains domain.com` | Limit to specific domains (repeatable, max 10) |
| `--exclude-domains domain.com` | Exclude domains (repeatable, max 10) |
| `--excerpt-max-chars-total N` | Limit total excerpt size (default: 8000) |
| `-o, --output <path>` | Save output to file |

### Common Examples

**Simple factual lookup:**
```bash
parallel-cli search "When was the United Nations founded?" --json --max-results 5
```

**Current events with keyword filtering:**
```bash
parallel-cli search "Latest developments in quantum computing" \
  -q "quantum" -q "computing" -q "2026" \
  --json --max-results 10
```

**Domain-scoped search:**
```bash
parallel-cli search "React hooks best practices" \
  --include-domains react.dev --include-domains github.com \
  --json --max-results 5
```

**Recent news:**
```bash
parallel-cli search "AI regulation news" \
  --after-date 2026-01-01 \
  --json --max-results 10
```

## Response Format

Returns structured JSON with:

| Field | Description |
|-------|-------------|
| `search_id` | Unique identifier |
| `results[].url` | Source URL |
| `results[].title` | Page title |
| `results[].excerpts[]` | Relevant text excerpts |
| `results[].publish_date` | When available |

## Progressive Disclosure

This skill uses tiered reference files. Load deeper references on-demand:

| When you need... | Load |
|------------------|------|
| Complete CLI reference — all flags, examples, exit codes, JSON schema | `references/cli-reference.md` |
| Prompting strategy — objective writing, keyword queries, quality checklist | `references/best-practices.md` |
| Handling results — presenting to users, citations, context management | `references/output-handling.md` |
| Multi-step patterns — sequential refinement, cross-source verification, search→extract→synthesize pipeline | `references/advanced-workflows.md` |

## Error Handling

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | Unexpected error (network, parse) |
| 2 | Invalid arguments |
| 3 | API error (non-2xx) |

## Prerequisites

1. Get an API key at [parallel.ai](https://parallel.ai)
2. Install the CLI:

```bash
curl -fsSL https://parallel.ai/install.sh | bash
export TAVILY_API_KEY=your-key
```

## References

- [Parallel API Docs](https://docs.parallel.ai)
- [Search API Reference](https://docs.parallel.ai/api-reference/search)
