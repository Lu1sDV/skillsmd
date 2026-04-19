# debate

Runs a bounded, structured multi-agent debate on a contested technical decision and returns a single recommended answer (or an honest "no clear winner" when positions are genuinely tied). Uses Claude Code's native subagent primitives — no external team-manager dependency.

## Credits

The **debate frame** — the phase structure, pinned debaters, steelman swap, judge synthesis, and decision-document template — is from [wcygan/debate](https://github.com/wcygan/debate). All credit for the original framework goes to wcygan.

This repository's copy adds:

- YAML frontmatter on the decision document (topic, date, positions, out_of_scope, recommendation, tied_on_axis, confidence, rounds, preset)
- Length presets (`quick` / `standard` / `deep`) and an explicit `rounds=<N>` override for arbitrary multi-round rebuttals
- An `out_of_scope` field in Phase 0 framing that propagates to debaters and the judge
- Reworded pragmatist role prompt to remove the neutral-observer contradiction

## When to use

Use when a technical decision has 2–4 nameable positions and you want a recommendation, not open-ended exploration. Triggers include:

- `"X vs Y"`, `"A or B"`, `"pick one"`
- contested trade-off, adversarial review
- decide-between requests

Skip when analysis is open-ended (use `superpowers:brainstorming` instead) or the question has no real contest.

## Installation

### Claude Code Plugin (recommended)

```
/plugin install debate@Lu1sDV/skillsmd
```

Or browse the marketplace:

```
/plugin marketplace add Lu1sDV/skillsmd
```

Then select **Browse and install plugins** → **Lu1sDV/skillsmd** → **debate**.

### Manual install

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/debate ~/.claude/skills/
```

### npx

```bash
npx skills add Lu1sDV/skillsmd debate
```

### Verify

In Claude Code:

```
What skills are available?
```

## Usage

Once installed, invoke naturally:

```
Debate: monorepo vs polyrepo for our 6-person team
```

```
Pick one: Postgres vs MySQL vs SQLite for this workload
```

```
We need to decide between REST and gRPC — run a debate
```

The skill will:

1. Propose 2–4 positions + team composition, wait for your confirmation
2. Spawn 3 debaters + 1 neutral judge as background subagents
3. Run opening → rebuttal → steelman swap rounds
4. Produce a 6-section decision document with confidence rating, irreducible trade-offs, and dissenting view

## What's included

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill — workflow phases, subagent mechanics, anti-patterns |
| `references/role-prompts.md` | Prompt templates for each debater role and phase |
| `references/decision-doc-template.md` | 6-section output template with rules and example |
| `references/failure-catalog.md` | Detection and handling of known failure modes |
