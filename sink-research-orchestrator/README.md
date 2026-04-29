# sink-research-orchestrator

Orchestrate parallel research swarms for unseen sink languages and new technique categories.

## What It Does

When sink subagents encounter an unfamiliar language or technique class, this skill orchestrates a 5-phase research pipeline:

1. **Intent clarification** — confirm scope, categories, citation format
2. **Parallel research swarm** — spawn 8-12 subagents across orthogonal lanes
3. **Result synthesis** — deduplicate, cross-reference, flag contradictions
4. **Structured output** — JSON citations per finding with source URLs
5. **Quality gates** — every finding has code example, citation, and confidence level

## Installation

### Via Plugin Marketplace

```text
/plugin marketplace add Lu1sDV/skillsmd
/plugin install sink-research-orchestrator@Lu1sDV/skillsmd
```

### Via npx

```bash
npx skills add Lu1sDV/skillsmd sink-research-orchestrator
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/sink-research-orchestrator ~/.claude/skills/
```

### Verify

```text
What skills are available?
```

## When It Triggers

The skill loads when Claude detects keywords like:
- "comprehensive", "exhaustive", "most complete"
- "deep dive", "long horizon", "parallel research"
- "unseen language", "new technique category"

## Related

- Part of [vuln-research](../vuln-research/) — loaded as a reference when auditing unseen languages
- Uses the same JSON citation format as vuln-research's per-language sink catalogs
