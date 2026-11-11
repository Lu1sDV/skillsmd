# reuse-first-swe-research

An evidence-first skill for researching how to build or change software with maximum verified reuse and minimum unnecessary reinvention.

The research method adapts to context: for new systems, it investigates the solution space and existing complete implementations; for existing systems, it first examines current behavior, internal reusable assets, compatibility obligations, and safe change boundaries. Mixed projects are handled by subsystem.

The skill researches domain-specific decomposition and adaptive research granularity, verifies reusable platforms and source-level implementations, compares full imports, code reuse, logic reuse, and component reuse using the embedded weighted matrix, and produces an actionable minimum-code implementation or migration recommendation.

All evaluation criteria and formulas are contained in [SKILL.md](SKILL.md). No CSV or external scoring worksheet is required.

## Installation

```bash
npx skills add Lu1sDV/skillsmd --skill reuse-first-swe-research
# or manually
cp -r reuse-first-swe-research ~/.claude/skills/
```

See [SKILL.md](SKILL.md) for the full workflow and evidence requirements.
