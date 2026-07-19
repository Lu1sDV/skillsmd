# bug-bounty-reporting

Creates concise, evidence-first bug bounty report packages from verified
findings and executable PoCs. It works across HackerOne, Bugcrowd, Intigriti,
and vendor-managed programs while keeping the report, final-run evidence,
cleanup, and frozen snapshot mutually consistent.

## Installation

### Claude Code Plugin

```text
/plugin install bug-bounty-reporting@Lu1sDV/skillsmd
```

Or add the marketplace first:

```text
/plugin marketplace add Lu1sDV/skillsmd
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/bug-bounty-reporting ~/.claude/skills/
```

### npx

```bash
npx skills add Lu1sDV/skillsmd
```

## Usage

```text
Use bug-bounty-reporting to turn this finding, PoC, and evidence bundle into a
submission-ready bug bounty report.
```

```text
Review this frozen Bugcrowd report package and list every claim that lacks
exact final-run evidence.
```

The skill starts with an eligibility/scope gate, combines impact and severity,
requires direct-impact evidence, and finishes with one independent
frozen-snapshot review.

## Included Files

| File | Purpose |
|---|---|
| `SKILL.md` | Authoring workflow, guardrails, freeze protocol, and completion gate |
| `references/report-standard.md` | Report template, evidence matrix, PoC contract, cleanup, and review standard |
| `agents/openai.yaml` | Codex skill interface metadata |

## Validation

```bash
python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  bug-bounty-reporting
```
