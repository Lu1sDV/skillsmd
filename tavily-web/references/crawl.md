# Crawl & Map API Reference

## Crawl Endpoint

`POST https://api.tavily.com/crawl`

### All Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | string | required | Starting URL |
| `max_depth` | integer | 2 | Link depth to follow |
| `max_breadth` | integer | 10 | Max links per page |
| `limit` | integer | 20 | Total pages to extract |
| `instructions` | string | null | Semantic focus for crawler |
| `extract_depth` | string | `"basic"` | `"basic"` or `"advanced"` |
| `chunks_per_source` | integer | 1 | Content chunks per page (1-5) |
| `select_paths` | array | null | Only crawl matching URL paths |
| `exclude_paths` | array | null | Skip matching URL paths |

### Response Fields

```json
{
  "base_url": "https://docs.example.com",
  "results": [
    {
      "url": "https://docs.example.com/page",
      "raw_content": "Extracted content",
      "chunks": ["chunk1"]
    }
  ],
  "failed_results": [],
  "request_id": "uuid",
  "total_pages": 15
}
```

## Map Endpoint

`POST https://api.tavily.com/map`

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | string | required | Site URL to discover links from |

### Response

```json
{
  "urls": [
    "https://docs.example.com/",
    "https://docs.example.com/getting-started",
    "https://docs.example.com/api-reference"
  ],
  "request_id": "uuid"
}
```

## Patterns

### Documentation ingestion

```bash
curl -s "https://api.tavily.com/crawl" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://docs.example.com",
    "max_depth": 3,
    "limit": 50,
    "instructions": "Extract API reference and code examples",
    "select_paths": ["/api/*", "/guides/*"],
    "exclude_paths": ["/blog/*", "/changelog/*"],
    "format": "markdown"
  }'
```

### Map-then-Extract (selective crawling)

Discover URLs first, then extract only relevant pages. More cost-efficient than blind crawling.

```bash
# Step 1: Discover all URLs
curl -s "https://api.tavily.com/map" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://docs.example.com"}'

# Step 2: Extract only relevant URLs from the map results
curl -s "https://api.tavily.com/extract" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "urls": ["https://docs.example.com/api-reference", "https://docs.example.com/authentication"],
    "format": "markdown",
    "chunks_per_source": 3
  }'
```

### Cost Control

- Set `limit` conservatively — start with 10-20 pages
- Use `select_paths` / `exclude_paths` to avoid irrelevant sections
- Use `instructions` to focus the crawler semantically
- Prefer Map-then-Extract for large sites
