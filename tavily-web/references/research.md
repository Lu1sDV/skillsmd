# Research API Reference

## Start Research

`POST https://api.tavily.com/research`

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `input` | string | required | Research prompt/question |
| `model` | string | `"auto"` | `"mini"` (fast), `"pro"` (comprehensive), `"auto"` |
| `citation_format` | string | null | `"numbered"`, `"inline"`, or null |
| `output_schema` | object | null | JSON schema for structured output |
| `stream` | boolean | false | Stream results as they come |
| `max_results` | integer | null | Limit number of sources |

### Response

```json
{
  "request_id": "uuid",
  "status": "running"
}
```

## Poll for Results

`GET https://api.tavily.com/research/{request_id}`

### Response (completed)

```json
{
  "request_id": "uuid",
  "status": "completed",
  "content": "The full research report with citations...",
  "sources": [
    {"url": "https://...", "title": "..."}
  ]
}
```

Status values: `"running"`, `"completed"`, `"failed"`

## Full Workflow

```bash
# 1. Start research
RESPONSE=$(curl -s "https://api.tavily.com/research" \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "input": "Compare serverless database options for startups in 2026",
    "model": "pro",
    "citation_format": "numbered"
  }')

REQUEST_ID=$(echo "$RESPONSE" | jq -r '.request_id')

# 2. Poll until complete (every 10s, max 3 min)
for i in $(seq 1 18); do
  RESULT=$(curl -s "https://api.tavily.com/research/$REQUEST_ID" \
    -H "Authorization: Bearer $TAVILY_API_KEY")
  STATUS=$(echo "$RESULT" | jq -r '.status')
  if [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed" ]; then
    echo "$RESULT" | jq '.'
    break
  fi
  sleep 10
done
```

## Model Selection

| Model | Best For | Speed | Depth |
|-------|----------|-------|-------|
| `mini` | Single focused question, fact lookups | Fast | Shallow |
| `pro` | Multi-topic analysis, comparisons, market research | Slow | Deep |
| `auto` | When unsure — Tavily picks based on query complexity | Varies | Varies |

## Prompting Best Practices

**Be specific about output format:**
```
"Analyze X. Provide: 1) Executive summary, 2) Key findings with data, 3) Comparison table, 4) Recommendations. Use numbered citations."
```

**Scope the research:**
```
"Focus on enterprise adoption of Y in North America during 2025-2026. Exclude consumer/prosumer segments."
```

**Request structured output:**
```json
{
  "input": "Top 5 CDN providers by performance",
  "model": "pro",
  "output_schema": {
    "type": "object",
    "properties": {
      "providers": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "name": {"type": "string"},
            "strengths": {"type": "array", "items": {"type": "string"}},
            "weaknesses": {"type": "array", "items": {"type": "string"}},
            "pricing_tier": {"type": "string"}
          }
        }
      },
      "recommendation": {"type": "string"}
    }
  }
}
```
