# skillsmp-search

A Claude Code skill that searches [SkillsMP](https://skillsmp.com)'s 11,000+ community skill marketplace and installs matches locally.

## Features

- **Keyword search** (fast, ~500ms) — sorted by stars
- **AI semantic search** (smart, ~5s) — natural language queries
- **Interactive selection** via `AskUserQuestion` — never auto-selects
- **One-command install** — fetches SKILL.md from GitHub, saves to global or project scope

## Installation

### Claude Code Plugin

```
/plugin install skillsmp-search@Lu1sDV/skillsmd
```

### npx

```bash
npx skills add Lu1sDV/skillsmd skillsmp-search
```

### Manual

```bash
cp -r skillsmp-search ~/.claude/skills/
```

## Setup

1. Place your API key in `~/.claude/skills/skillsmp-search/.skillsmp-key`
2. Get an API key at [skillsmp.com](https://skillsmp.com)

## Usage

Just ask Claude to find or install a skill:

- *"Find a skill for writing better git commits"*
- *"Search skills for React testing"*
- *"Install a skill for Dockerfile best practices"*
