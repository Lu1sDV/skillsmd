# Search API Reference

## Endpoint

`POST https://api.tavily.com/search`

## All Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `query` | string | required | Search query (max 400 chars) |
| `max_results` | integer | 5 | Number of results (1-20) |
| `search_depth` | string | `"basic"` | `"basic"` (1 credit) or `"advanced"` (2 credits) |
| `topic` | string | `"general"` | `"general"`, `"news"`, or `"finance"` |
| `time_range` | string | null | `"day"`, `"week"`, `"month"`, `"year"` |
| `days` | integer | null | Number of days back (alternative to time_range) |
| `include_answer` | bool/string | false | `true`, `"basic"`, or `"advanced"` for AI answer |
| `include_raw_content` | bool | false | Include full page HTML (expensive — prefer extract) |
| `include_domains` | array | null | Restrict to these domains |
| `exclude_domains` | array | null | Exclude these domains |
| `include_images` | bool | false | Include image results |
| `country` | string | null | Country bias (general topic only), e.g. `"us"`, `"gb"` |
| `chunks_per_source` | integer | 1 | Content chunks per result (1-5, advanced depth only) |

## Response Fields

```json
{
  "query": "original query",
  "answer": "AI-generated answer (if requested)",
  "results": [
    {
      "title": "Page Title",
      "url": "https://...",
      "content": "Relevant snippet",
      "raw_content": "Full content (if requested)",
      "score": 0.95,
      "published_date": "2026-03-10"
    }
  ],
  "images": [],
  "request_id": "uuid"
}
```

## Query Optimization

- **Be specific**: "React Server Components performance benchmarks 2026" > "React performance"
- **Split complex queries**: Break "Compare X and Y for Z" into separate queries for X and Y
- **Use domain filters**: `include_domains: ["github.com"]` for code-specific results
- **Time-bound news**: Always pair `topic: "news"` with `time_range` or `days`

## Search Depth Selection

| Use Case | Depth | Why |
|----------|-------|-----|
| Quick fact lookup | basic | Fast, 1 credit |
| API documentation | basic | Usually well-indexed |
| Niche technical topic | advanced | Deeper crawling needed |
| Competitive analysis | advanced | More thorough results |
| Current news | basic | News is well-indexed |

## Cost-Aware Patterns

```bash
# Budget search: basic depth, minimal results
curl -s "https://api.tavily.com/search" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "your query", "max_results": 3, "search_depth": "basic"}'

# Thorough search: advanced depth, answer included
curl -s "https://api.tavily.com/search" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "your query", "max_results": 10, "search_depth": "advanced", "include_answer": "advanced"}'

# News search with recency filter
curl -s "https://api.tavily.com/search" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "latest AI regulation", "topic": "news", "time_range": "week", "max_results": 5}'

# Domain-scoped search
curl -s "https://api.tavily.com/search" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "authentication best practices", "include_domains": ["owasp.org", "cheatsheetseries.owasp.org"], "max_results": 5}'
```

## Post-Filtering

After receiving results, filter by:
- **Score threshold**: Skip results with `score` below 0.5
- **Domain trust**: Prefer authoritative sources
- **Recency**: Check `published_date` for time-sensitive queries
