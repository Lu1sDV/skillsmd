# huggingface

Compact Hugging Face Hub skill: the `hf` CLI and a benchmark-driven best-model
finder. [SKILL.md](SKILL.md) is a short orchestrator that routes to two
independently readable references, loaded only when the task needs them:

- [references/hf-cli.md](references/hf-cli.md) — every `hf` command group with
  common flags, output formats, and `hf-mount`.
- [references/model-finder.md](references/model-finder.md) — leaderboard
  queries, device-memory parameter budgets, filtering, and the comparison-table
  output contract.

## Install and use

Copy the complete `huggingface/` directory into your agent's skills directory.
For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r huggingface ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install huggingface@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd huggingface
```

Examples:
- "Download the Q4 GGUF of org/model with hf."
- "What's the best model for coding that runs on my 16GB MacBook?"

## Sources and adaptation

Condensed on 2026-11-14 from two upstream skills in
[huggingface/skills](https://github.com/huggingface/skills) (Apache-2.0, see
[LICENSE.upstream](LICENSE.upstream)):

- [hf-cli/SKILL.md](https://github.com/huggingface/skills/blob/main/skills/hf-cli/SKILL.md)
  — generated with `huggingface_hub v2.4.0`. Exhaustive per-command flag lists
  were reduced to common flags; `hf <command> --help` remains the source of truth.
- [huggingface-best/SKILL.md](https://github.com/huggingface/skills/blob/main/skills/huggingface-best/SKILL.md)
  — the six-step workflow, device-budget formulas, and output contract are kept.

These references are condensed derivatives, not vendored copies. Corrections to
the upstream text: its error-handling section cites a "curated fallback table"
that does not exist in the source and MCP-only tools (`hub_repo_search`,
`hub_repo_details`); the fallback here is a popularity search via
`hf models list --sort trending_score` (or the REST equivalent), explicitly
labeled as popularity-ranked. The Q4 capacity wording is unified to
memory (GB) × 2 parameters.

Validation: YAML frontmatter (CI contract), local reference links, and the five
static skill-smell checks. The `hf` commands and Hub API calls apply to the
consumer's environment and were not executed against the live Hub here.
