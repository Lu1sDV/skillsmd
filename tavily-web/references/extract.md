# Extract API Reference

## Endpoint

`POST https://api.tavily.com/extract`

## All Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `urls` | array | required | URLs to extract from (max 20) |
| `extract_depth` | string | `"basic"` | `"basic"` or `"advanced"` (JS-rendered pages) |
| `query` | string | null | Focus extraction on matching content |
| `chunks_per_source` | integer | 1 | Content chunks per URL (1-5) |
| `format` | string | `"markdown"` | `"markdown"` or `"text"` |

## Response Fields

```json
{
  "results": [
    {
      "url": "https://...",
      "raw_content": "Extracted content in requested format",
      "chunks": ["chunk1", "chunk2"]
    }
  ],
  "failed_results": [
    {
      "url": "https://...",
      "error": "reason"
    }
  ],
  "request_id": "uuid"
}
```

## Extraction Strategies

### One-Step (direct extraction)

Best for: simple pages, blog posts, documentation.

```bash
curl -s "https://api.tavily.com/extract" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "urls": ["https://docs.example.com/api"],
    "extract_depth": "basic",
    "format": "markdown"
  }'
```

### Two-Step (search then extract)

Best for: finding then reading specific content. Preferred over `include_raw_content` on search.

```bash
# Step 1: Search to find relevant URLs
curl -s "https://api.tavily.com/search" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "pricing plans SaaS", "max_results": 3}'

# Step 2: Extract full content from top results
curl -s "https://api.tavily.com/extract" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "urls": ["https://top-result-1.com", "https://top-result-2.com"],
    "query": "pricing tiers and features",
    "chunks_per_source": 3,
    "format": "markdown"
  }'
```

### Targeted extraction with query

Use `query` to focus on specific sections of a page:

```bash
curl -s "https://api.tavily.com/extract" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "urls": ["https://example.com/docs"],
    "query": "authentication and rate limits",
    "chunks_per_source": 3,
    "format": "markdown"
  }'
```

## When to Use Advanced Depth

- Page requires JavaScript rendering (SPAs, dynamic content)
- Basic extraction returns empty or incomplete results
- Content is behind client-side routing
