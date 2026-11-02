# CLI Reference — Parallel Search

Complete command-line interface reference for `parallel-cli search`.

## Command

```bash
parallel-cli search "<objective>" [options]
```

## All Flags

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `-q, --query "<keyword>"` | repeatable | none | Add keyword filter (repeat as `-q "term1" -q "term2"`, recommended 3-8 total) |
| `--max-results N` | int | 10 | Number of results to return (1-20) |
| `--json` | flag | off | Output as structured JSON instead of human-readable text |
| `--after-date YYYY-MM-DD` | string | none | Only return content published after this date |
| `--include-domains domain.com` | repeatable | none | Limit search to specific domains (repeatable, max 10) |
| `--exclude-domains domain.com` | repeatable | none | Exclude specific domains from results (repeatable, max 10) |
| `--excerpt-max-chars-total N` | int | 8000 | Maximum total characters across all excerpts |
| `-o, --output <path>` | string | none | Save JSON output to file instead of stdout |

## Basic Examples

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

**Domain-scoped technical search:**
```bash
parallel-cli search "React hooks best practices" \
  --include-domains react.dev --include-domains github.com \
  --json --max-results 5
```

**Recent news only:**
```bash
parallel-cli search "AI regulation news" \
  --after-date 2026-01-01 \
  --json --max-results 10
```

**Exclude low-quality domains:**
```bash
parallel-cli search "Rust async runtime comparison" \
  --exclude-domains medium.com --exclude-domains dev.to \
  --json --max-results 10
```

**Save to file for context management:**
```bash
parallel-cli search "Kubernetes security best practices" \
  -q "kubernetes" -q "security" -q "CIS" \
  --json -o /tmp/k8s-search.json
```

## Exit Codes

| Exit Code | Meaning | Action |
|-----------|---------|--------|
| 0 | Success | Proceed with results |
| 1 | Unexpected error (network, parse) | Retry once; if persistent, report to user |
| 2 | Invalid arguments | Check flags and syntax; correct and retry |
| 3 | API error (non-2xx) | Check API key; check API status at status.parallel.ai |

## JSON Output Schema

```json
{
  "search_id": "srch_abc123",
  "results": [
    {
      "url": "https://example.com/article",
      "title": "Article Title",
      "excerpts": ["Relevant text excerpt 1", "Relevant text excerpt 2"],
      "publish_date": "2026-04-15"
    }
  ]
}
```

### JSON Path Reference

| Path | Type | Description |
|------|------|-------------|
| `$.search_id` | string | Unique identifier for this search |
| `$.results` | array | Array of result objects (max-results determines count) |
| `$.results[].url` | string | Source URL (always present) |
| `$.results[].title` | string | Page title (always present) |
| `$.results[].excerpts` | array of strings | LLM-optimized relevant text excerpts |
| `$.results[].publish_date` | string or null | ISO date when available, null otherwise |

## Flag Constraints

- `--max-results`: Range 1-20. Values outside this range will return exit code 2.
- `--include-domains` and `--exclude-domains`: Maximum 10 each. Domain format: `example.com` (no protocol, no path).
- `--query` / `-q`: Recommended 3-8 keyword queries. The CLI accepts any number but quality degrades past ~12.
- `--after-date`: Strict YYYY-MM-DD format. Future dates return empty results.
- `--excerpt-max-chars-total`: Range 500-50000. Lower = less context but faster token processing.

## Prerequisites

1. Get an API key at [parallel.ai](https://parallel.ai)
2. Install the CLI:

```bash
curl -fsSL https://parallel.ai/install.sh | bash
```

3. Set the API key:

```bash
export TAVILY_API_KEY=your-key
```

## References

- [Parallel API Docs](https://docs.parallel.ai)
- [Search API Reference](https://docs.parallel.ai/api-reference/search)
