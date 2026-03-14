---
name: tavily-web
description: "Web search, content extraction, site crawling, URL discovery, and AI-powered research using Tavily API via curl. Use when user needs web search results, current events, news, finance data, content from URLs, site-wide extraction, or multi-topic research with citations. Trigger phrases: 'search the web', 'find online', 'extract from URL', 'crawl site', 'research topic', 'latest news about', 'web search', 'tavily'."
compatibility: "Requires TAVILY_API_KEY environment variable. CLI-based (curl only, no SDK install needed)."
metadata:
  author: merged-community
  version: 2.0.0
  tags: [tavily, search, extract, crawl, research, web, news, citations, api]
---

# Tavily Web Search & Research

CLI-based web search, extraction, crawling, and research via `curl`. No SDK installation required.

## Prerequisites

- `TAVILY_API_KEY` set in environment
- Never hardcode or paste API keys into chat

## Choosing the Right Method

| Need | Method | Cost | Latency |
|------|--------|------|---------|
| Web search results | `search` | 1-2 credits | Fast |
| Content from specific URLs | `extract` | 1+ credits | Fast |
| Content from entire site | `crawl` | Variable | Slow |
| URL discovery from a site | `map` | 1 credit | Fast |
| End-to-end research with AI synthesis | `research` | Higher | Minutes |

## Quick Reference

### search — Web Search

```bash
curl -s "https://api.tavily.com/search" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "your search query here",
    "max_results": 5,
    "search_depth": "basic",
    "topic": "general"
  }'
```

**Key parameters:**

| Parameter | Values | Notes |
|-----------|--------|-------|
| `query` | string (max 400 chars) | Keep focused; split complex questions into sub-queries |
| `max_results` | 1-20 (default 5) | Start small, increase if needed |
| `search_depth` | `basic` (1 credit) / `advanced` (2 credits) | Use basic unless you need precision |
| `topic` | `general` / `news` / `finance` | Determines ranking algorithm |
| `time_range` | `day` / `week` / `month` / `year` | Filter by recency |
| `include_answer` | `true` / `"basic"` / `"advanced"` | AI-generated answer from results |
| `include_domains` | `["domain.com"]` | Restrict to specific sites |
| `exclude_domains` | `["domain.com"]` | Exclude specific sites |

See `references/search.md` for full parameter reference and optimization tips.

### extract — URL Content Extraction

```bash
curl -s "https://api.tavily.com/extract" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "urls": ["https://example.com/page"],
    "extract_depth": "basic",
    "query": "focus on pricing info",
    "chunks_per_source": 3,
    "format": "markdown"
  }'
```

**Key parameters:**

| Parameter | Values | Notes |
|-----------|--------|-------|
| `urls` | array (max 20) | Target URLs to extract from |
| `extract_depth` | `basic` / `advanced` | Advanced handles JS-rendered pages |
| `query` | string | Focus extraction on specific content |
| `chunks_per_source` | 1-5 | Control output volume |
| `format` | `markdown` / `text` | Output format |

See `references/extract.md` for full reference.

### crawl — Site-Wide Extraction

```bash
curl -s "https://api.tavily.com/crawl" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://docs.example.com",
    "max_depth": 2,
    "max_breadth": 10,
    "limit": 20,
    "instructions": "Find API documentation pages",
    "extract_depth": "basic"
  }'
```

**Key parameters:**

| Parameter | Values | Notes |
|-----------|--------|-------|
| `url` | string | Starting URL |
| `max_depth` | integer | How many link levels deep |
| `max_breadth` | integer | Max links per page |
| `limit` | integer | Total pages to extract |
| `instructions` | string | Semantic focus for crawler |
| `select_paths` | `["/docs/*"]` | Include only matching paths |
| `exclude_paths` | `["/blog/*"]` | Skip matching paths |

See `references/crawl.md` for full reference.

### map — URL Discovery

```bash
curl -s "https://api.tavily.com/map" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://docs.example.com"
  }'
```

Returns a list of URLs found on the site. Useful as a precursor to targeted `extract` calls (Map-then-Extract pattern).

### research — AI-Powered Research

```bash
# Start research task
curl -s "https://api.tavily.com/research" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "input": "Analyze the competitive landscape for X in the SMB market",
    "model": "auto",
    "citation_format": "numbered"
  }'
# Returns: { "request_id": "..." }

# Poll for completion
curl -s "https://api.tavily.com/research/REQUEST_ID" \
  -H "Authorization: Bearer $TAVILY_API_KEY"
# Poll every 10s until status is "completed" or "failed"
```

**Model selection:** `mini` (focused queries, faster), `pro` (comprehensive, multi-topic), `auto` (let Tavily decide).

See `references/research.md` for prompting best practices and structured output schemas.

## Procedure

1. **Formulate query** — Keep under 400 chars. Split multi-part questions into 2-4 focused sub-queries.
2. **Pick topic** — `general` for most searches, `news` for current events (pair with `time_range`), `finance` for market data.
3. **Pick depth** — Start with `basic` (1 credit). Use `advanced` (2 credits) only when precision matters.
4. **Keep results small** — Default `max_results` to 5. Filter by `score` and domain trust.
5. **Two-step for full text** — Run `search` first, then `extract` on 1-3 top URLs. This is cheaper and safer than `include_raw_content`.
6. **Cite sources** — Always include `results[].url` as citations in your final answer.
7. **For deep research** — Use `research` endpoint with polling. Include `citation_format` for automatic source attribution.

## Pitfalls

| Pitfall | Mitigation |
|---------|------------|
| `include_raw_content` on search explodes output | Use two-step: `search` then `extract` |
| `search_depth` defaults may auto-upgrade to `advanced` | Set `search_depth` explicitly to control cost |
| `exact_match` is very restrictive | Wrap phrase in quotes inside `query` instead |
| `country` boosting only works with `topic: "general"` | Don't set `country` for news/finance topics |
| Crawl can be expensive on large sites | Set `limit`, `max_depth`, `max_breadth` conservatively |
| Research polling — don't poll too fast | Poll every 10 seconds, set a max wait timeout |

## Verification

Check remaining credits:
```bash
curl -s "https://api.tavily.com/usage" \
  -H "Authorization: Bearer $TAVILY_API_KEY"
```

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| 401 Unauthorized | Invalid or missing API key | Verify `TAVILY_API_KEY` is set and valid |
| 429 Too Many Requests | Rate limit exceeded | Wait and retry; check usage quota |
| Empty results | Query too narrow or restrictive | Broaden query, remove domain filters |
| Slow response on search | `advanced` depth or too many results | Reduce `max_results`, use `basic` depth |

Keep `request_id` from responses for debugging.
