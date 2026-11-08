# search-driven-development

A coding-agent skill for deciding when and how to learn from existing code before building.

It challenges the premise behind a proposed implementation, inspects the current system,
searches by problem structure (including neighboring engineering domains), and reuses at the
smallest complete level — configuration, API, module, internal mechanism, design, platform,
or new code. Candidates are disqualified early, verified at source/test/experiment level, and
compared by total ownership burden. Research stays proportional: clear, bounded changes are
just implemented.

See [SKILL.md](SKILL.md).

## Installation

```bash
npx skills add Lu1sDV/skillsmd search-driven-development
# or manually
cp -r search-driven-development ~/.claude/skills/
```
