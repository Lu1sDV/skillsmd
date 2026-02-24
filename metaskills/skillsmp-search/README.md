# skillsmp-search

A Claude Code skill that searches [SkillsMP](https://skillsmp.com)'s 11,000+ community skill marketplace and installs matches locally.

## Features

- **Keyword search** (fast, ~500ms) — sorted by stars
- **AI semantic search** (smart, ~5s) — natural language queries
- **Interactive selection** via `AskUserQuestion` — never auto-selects
- **One-command install** — fetches SKILL.md from GitHub, saves to global or project scope

## Setup

1. Copy `SKILL.md` to `~/.claude/skills/skillsmp-search/SKILL.md`
2. Place your API key in `~/.claude/skills/skillsmp-search/.skillsmp-key`
3. Get an API key at [skillsmp.com](https://skillsmp.com)

## Usage

Just ask Claude to find or install a skill:

- *"Find a skill for writing better git commits"*
- *"Search skills for React testing"*
- *"Install a skill for Dockerfile best practices"*
