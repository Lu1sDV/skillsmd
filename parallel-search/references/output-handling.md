# Output Handling — Parallel Search

Guidance for processing, presenting, and managing search results from `parallel-cli search`.

## Response Format

The `--json` output returns a structured object:

```json
{
  "search_id": "srch_abc123",
  "results": [
    {
      "url": "https://example.com/article",
      "title": "Article Title",
      "excerpts": [
        "Relevant text excerpt about the search topic...",
        "Another excerpt with supporting details..."
      ],
      "publish_date": "2026-04-15"
    }
  ]
}
```

### Field Guarantees

- `search_id` — Always present, unique per search
- `url` — Always present, non-empty string
- `title` — Always present, non-empty string
- `excerpts` — Always present as array, may be empty if no relevant content found
- `publish_date` — Present when the page includes publication metadata, `null` otherwise

## Presenting Results to the User

### Priority Order

When synthesizing a response for the user, prioritize results in this order:

1. **Official/primary sources** — `.gov`, `.edu`, official project websites, vendor advisories
2. **High-authority secondary sources** — major publications, established tech blogs, academic papers
3. **Community sources** — Stack Overflow, Reddit, forums (cite with caveats about authority)
4. **Low-authority sources** — personal blogs, medium articles (use as supplementary only)

### Citation Format

Always cite sources. For each fact or claim, include:

```
[Source Title](URL) — published YYYY-MM-DD (if available)
```

Example:
```
According to the [React 19 Release Notes](https://react.dev/blog/2024/12/05/react-19),
server components are now stable. (published 2024-12-05)
```

### Handling Conflicting Results

When search results disagree:

1. **Acknowledge the conflict explicitly**: "Sources disagree on whether X is true..."
2. **Present both positions** with citations for each
3. **Note authority levels**: "Source A (official docs) says X, while Source B (community blog) says Y"
4. **Recommend**: "Given the authority of the source, I recommend X"

### Exhaustive Lists

When the user needs complete enumeration (feature lists, command flags, API parameters):

- Extract every item from within excerpts
- Do not summarize or group items unless the user explicitly requests it
- Preserve ordering from the source
- Preface with "Here is the complete list from [source]:"

## Context Window Management

Search results can be large. Use these strategies to stay within context limits.

### Save to File Pattern

For searches returning many results or for long conversations:

```bash
# Save results to disk
parallel-cli search "comprehensive analysis of..." \
  --json -o /tmp/search-topic.json --max-results 15
```

Then reference the file path instead of pasting raw JSON into context.

### Spawning Sub-Agents for Synthesis

For large result sets, delegate synthesis to a sub-agent:

```bash
# Step 1: Search and save
parallel-cli search "quantum computing milestones 2024-2026" \
  --json -o /tmp/quantum-search.json --max-results 15

# Step 2: Spawn a sub-agent to read and summarize
```

Use the appropriate agent spawning mechanism for your platform to invoke a sub-agent that reads the saved JSON and produces a user-facing summary.

### Excerpt Tuning

Control excerpt length to manage context consumption:

| Scenario | Setting | Rationale |
|----------|---------|-----------|
| Quick fact check | `--excerpt-max-chars-total 2000` | Minimal context needed |
| Standard research | `--excerpt-max-chars-total 8000` (default) | Good balance |
| Deep analysis | `--excerpt-max-chars-total 20000` | Need maximum context per result |
| Many sources required | `--excerpt-max-chars-total 8000` + higher `--max-results` | More sources, narrower excerpts |
| Few authoritative sources | Lower `--max-results` (3-5) + higher excerpt limit | Fewer sources, deeper excerpts |

## Post-Search Workflow

A complete search-to-answer workflow:

1. **Search** with a clear objective + keyword queries
2. **Inspect** result titles, URLs, and dates. Discard obviously irrelevant results.
3. **Prioritize** remaining results by authority, recency, and relevance.
4. **Optionally extract** the top 1-3 URLs for full content (using `parallel-cli extract` from the `parallel-extract` skill)
5. **Synthesize** the answer from excerpts, citing sources
6. **Report** to user with citations

### When to Re-Search

Re-run the search when:
- Fewer than 3 relevant results returned → broaden objective or remove some keyword filters
- Results all from low-authority sources → add `--include-domains` for known good sources
- Results too old → add `--after-date` or include year in keyword queries
- Need different angle → change the objective (different phrasing, different scope)
