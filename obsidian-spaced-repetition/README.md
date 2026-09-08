# obsidian-spaced-repetition

A Claude Code skill for managing [Obsidian Spaced Repetition](https://github.com/st3v3nmw/obsidian-spaced-repetition) through the [official Obsidian CLI](https://obsidian.md/help/cli).

## Covers

- Vault targeting, plugin discovery, and read-only settings inspection.
- Basic, reversed, multiline, and cloze flashcards; tag- and folder-based decks.
- Guarded exact-text correction through `scripts/replace-once.mjs`.
- Starting card/cram sessions and whole-note review workflows.
- Preserving scheduling comments, note frontmatter, and sibling-card history.
- Diagnosing missing cards, context-dependent commands, and CLI setup failures.

The actual plugin ID is `obsidian-spaced-repetition`. Reviews use the desktop UI; this skill does not invent a headless scheduler or choose recall ratings for the user.

## Install

From this repository:

```bash
mkdir -p ~/.claude/skills
cp -r obsidian-spaced-repetition ~/.claude/skills/
```

Or select the skill with:

```bash
npx skills add Lu1sDV/skillsmd
```

This installs the **agent skill**, not Obsidian or its community plugin. Enable the official CLI in Obsidian's General settings and install/enable Spaced Repetition in the intended vault separately.

## Example requests

- “Use the Obsidian CLI to add five geography cards to my existing deck.”
- “Why are this note's cloze cards missing from Spaced Repetition?”
- “Open this note's flashcards for review without changing their schedules.”
- “Correct this answer while preserving its scheduling metadata.”

See [SKILL.md](SKILL.md) for the workflow. Command IDs and the settings inspection probe were checked against plugin 1.15.4; the skill requires live discovery for other versions.
