# universal-skill-finder

A Claude Code skill that searches TWO community skill marketplaces in one pass and installs matches locally:

- [SkillsMP](https://skillsmp.com) — 11,000+ skills (keyword + AI semantic search, API key)
- [skills.sh](https://skills.sh) — via the official [find-skills](https://github.com/vercel-labs/skills) guidelines (`npx skills find`, no auth)

Results are merged into one ranked table with a **Market** column showing where each skill was found: `skillsmp`, `skills.sh`, or `both`.

## Features

- **Dual-market search** — skillsmp keyword/AI search + skills.sh CLI search in one pass
- **Merged results table** — Market column (`skillsmp` / `skills.sh` / `both`) with per-market metrics (★ stars, installs)
- **Cross-market dedup** — same `owner/repo` + normalized skill name in both markets → one `both` row
- **Graceful degradation** — no skillsmp API key? skills.sh-only results with a notice
- **Interactive selection** via `AskUserQuestion` — never auto-selects
- **Rubric comparison** — "Compare to find best" scores candidates across both markets (/12 rubric)
- **Unified install** — raw GitHub URL transform (skillsmp) or `npx skills add <owner/repo@skill>` (skills.sh)

## Installation

### Claude Code Plugin

```
/plugin install universal-skill-finder@Lu1sDV/skillsmd
```

### npx

```bash
npx skills add Lu1sDV/skillsmd universal-skill-finder
```

### Manual

```bash
cp -r universal-skill-finder ~/.claude/skills/
```

## Setup

Only the SkillsMP half needs a key (skills.sh works with none):

1. Get an API key at [skillsmp.com](https://skillsmp.com)
2. Export it as an environment variable:
   ```bash
   echo 'export SKILLSMP_API_KEY="your-key-here"' >> ~/.zshrc
   source ~/.zshrc
   ```

No key? The skill still searches skills.sh and says so.

## Usage

Just ask Claude to find or install a skill:

- *"Find a skill for writing better git commits"*
- *"Search skills for React testing"*
- *"Search skills.sh for Next.js performance"*
- *"Install a skill for Dockerfile best practices"*
