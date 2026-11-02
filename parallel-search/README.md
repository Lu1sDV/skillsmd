# parallel-search

AI-powered web search via Parallel API. Returns ranked results with LLM-optimized excerpts for research, fact-checking, and domain-scoped searching.

## Structure

```
parallel-search/
├── SKILL.md                       # Main entry — purpose, quick start, routing to references
├── README.md                      # This file
├── _meta.json                     # Skill metadata (marketplace compatibility)
└── references/
    ├── cli-reference.md           # Full CLI reference — all flags, examples, exit codes, JSON schema
    ├── best-practices.md          # Prompting strategy — objectives, keyword queries, quality checklist
    ├── output-handling.md         # Result handling — presentation, citations, context management
    └── advanced-workflows.md      # Multi-step patterns — refinement, cross-source verification, pipeline
```

## Token Efficiency

The skill uses **two-tier progressive disclosure**:

1. **SKILL.md** (~90 lines) loads automatically — provides purpose, when-to-use, quick start, basic flags, and a routing table to reference files
2. **Reference files** load on-demand based on what the agent needs:
   - Writing a search query → load `best-practices.md`
   - Debugging CLI errors → load `cli-reference.md`
   - Presenting results → load `output-handling.md`
   - Complex multi-step research → load `advanced-workflows.md`

This saves significant context window space compared to loading the full ~400 lines of documentation upfront.

## Related Skills

- [parallel-extract](../parallel-extract/SKILL.md) — Extract clean markdown from URLs found by search
- [parallel-deep-research (external)](https://github.com/Demerzels-lab/elsamultiskillagent/tree/main/public/skills/normallygaussian/parallel-deep-research) — Multi-source deep research for complex topics
- [parallel-enrichment (external)](https://github.com/Demerzels-lab/elsamultiskillagent/tree/main/public/skills/normallygaussian/parallel-enrichment) — Bulk data enrichment for lists of companies/people/products
