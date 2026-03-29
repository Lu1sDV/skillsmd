# cook

Composable agent orchestration — review loops, repeat passes, parallel races, vs comparisons, and task-list progression (ralph). Works as pure agent orchestration or with the optional CLI.

Upstream: [rjcorwin/cook](https://github.com/rjcorwin/cook)

## Installation

### Claude Code Plugin (recommended)

```
/plugin install cook@Lu1sDV/skillsmd
```

Or browse the marketplace:

```
/plugin marketplace add Lu1sDV/skillsmd
```

Then select **Browse and install plugins** → **Lu1sDV/skillsmd** → **cook**.

### Manual install

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/cook ~/.claude/skills/
```

### npx

```bash
npx skills add Lu1sDV/skillsmd
```

### Verify

In Claude Code:

```
What skills are available?
```

## Usage

Once installed, invoke naturally:

```
Cook "Implement dark mode" with a review loop
Cook "Auth with JWT" vs "Auth with sessions", pick best security
Let it cook — race 3 approaches to the search feature
```

Or use the operator syntax directly:

```
cook "Implement dark mode" review
cook "Implement dark mode" v3 pick "cleanest"
cook "Next task in PLAN.md" ralph 5 "DONE if all tasks complete, else NEXT"
```

## Optional: CLI

For standalone terminal/CI usage:

```bash
npm install -g @let-it-cook/cli
cook init    # creates COOK.md and .cook/config.json
```

Requires Node.js 20+ and [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Codex](https://github.com/openai/codex), or [OpenCode](https://github.com/opencode-ai/opencode).

## What's included

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill — operator reference, execution patterns, quick reference |
| `references/spec.md` | Full operator grammar, nesting rules, config schema, CLI flags |
