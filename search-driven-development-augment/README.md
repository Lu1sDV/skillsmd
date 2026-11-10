# search-driven-development-augment

A coding-agent skill for writing the repository index entries that search-driven-development
agents read to decide which repositories to open, skip, or start from.

Each entry follows a fixed five-paragraph format (what it does, core mechanism, problem
structure, what studying it gives you, limits and fit), stays factual and verified against the
source, and is checked with a routing test. [INDEX_BUILD_WORKFLOW.md](INDEX_BUILD_WORKFLOW.md)
covers building a whole index: problem council, discovery, parallel entry writing, merge, and
routing test.

See [SKILL.md](SKILL.md).

## Installation

```bash
npx skills add Lu1sDV/skillsmd search-driven-development-augment
# or manually
cp -r search-driven-development-augment ~/.claude/skills/
```
