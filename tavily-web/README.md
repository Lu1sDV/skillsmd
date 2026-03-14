# tavily-web

Web search, content extraction, site crawling, and AI-powered research via the Tavily API — using `curl` only, no SDK needed.

## Origin

This skill was created by searching the [SkillsMP marketplace](https://skillsmp.com) for existing Tavily skills, comparing the top community contributions, and merging the best of each into a single unified skill:

- **sickn33/tavily-web** (24K+ stars) — comprehensive API coverage across all five Tavily endpoints (search, extract, crawl, map, research)
- **andrewyng/tavily-best-practices** (5.8K stars) — query optimization patterns, cost-aware usage strategies, and practical pitfalls

The merge combined sickn33's broad endpoint coverage with andrewyng's operational wisdom (cost control, two-step search-then-extract pattern, pitfall documentation). The result is a skill that covers every Tavily method while guiding Claude toward cost-efficient, production-safe usage.

## Design Decisions

**CLI-only (curl, no SDK):** The skill uses raw `curl` commands rather than any Tavily SDK. This eliminates dependency management — no `pip install`, no `npm install`, no version conflicts. Any environment with `curl` and a `TAVILY_API_KEY` can use it immediately.

**Progressive disclosure:** The main `SKILL.md` contains a quick-reference table, key parameters for each endpoint, and a procedure section. Full parameter references, advanced patterns, and edge cases live in `references/` files, loaded only when Claude needs deeper detail for a specific endpoint.

**Five methods, one decision table:** Rather than forcing Claude to read documentation for all five endpoints, a "Choosing the Right Method" table at the top maps needs to methods with cost and latency signals, so Claude picks the right tool before reading any details.

## Structure

```
tavily-web/
├── SKILL.md              # Main skill — quick reference, procedures, pitfalls
└── references/
    ├── search.md          # Full search API parameters, query optimization
    ├── extract.md         # Extract API, two-step patterns, advanced depth
    ├── crawl.md           # Crawl & Map API, cost control, path filtering
    └── research.md        # Research API, polling, model selection, prompting
```

## Installation

### Plugin marketplace

```
/plugin install tavily-web@Lu1sDV/skillsmd
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/tavily-web ~/.claude/skills/
```

## Prerequisites

Set `TAVILY_API_KEY` in your environment. Never paste API keys into chat.

## What It Covers

| Method | Use Case |
|--------|----------|
| `search` | Web search results, news, finance data |
| `extract` | Content from specific URLs (prefer over `include_raw_content`) |
| `crawl` | Site-wide content extraction with depth/breadth control |
| `map` | URL discovery from a site (precursor to targeted extract) |
| `research` | End-to-end AI-powered research with citations |
