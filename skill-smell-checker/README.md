# skill-smell-checker

Audits Agent Skill `SKILL.md` files for the 26 skill smells defined in
[*From Anatomy to Smells: An Empirical Study of SKILL.md in Agent Skills*](https://arxiv.org/abs/2607.01456).

It uses the paper's hybrid approach:

- **5 static smells** are checked by a deterministic Python harness.
- **21 semantic smells** are reviewed contextually with evidence and confidence.

## Installation

### Claude Code Plugin (recommended)

```text
/plugin install skill-smell-checker@Lu1sDV/skillsmd
```

Or browse the marketplace:

```text
/plugin marketplace add Lu1sDV/skillsmd
```

Then select **Browse and install plugins** > **Lu1sDV/skillsmd** >
**skill-smell-checker**.

### Manual install

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/skill-smell-checker ~/.claude/skills/
```

### npx

```bash
npx skills add Lu1sDV/skillsmd
```

## Usage

Invoke it naturally:

```text
Use skill-smell-checker to audit .claude/skills/my-skill/SKILL.md
```

```text
Check every SKILL.md in this repository for skill smells
```

```text
Audit this skill, then fix only the confirmed smells
```

The resulting report covers all 26 smell IDs, separates static findings from
semantic judgments, cites file evidence, assigns confidence, and recommends the
smallest remediation.

## Deterministic Checks

| ID | Smell | Rule |
|---|---|---|
| `LSB` | Lengthy Skill Body | Body exceeds 5,000 words |
| `LSN` | Lengthy Skill Name | Name exceeds 64 characters |
| `LSD` | Lengthy Skill Description | Description exceeds 1,024 characters |
| `XID` | XML Included Description | Description contains tag-shaped XML |
| `BP` | Backslash Path | Paths use backslashes |

Run the harness directly:

```bash
python skill-smell-checker/scripts/check_static_smells.py path/to/SKILL.md --pretty
```

Add `--strict` to return exit code 1 when a static smell is found.

## What's Included

| File | Purpose |
|---|---|
| `SKILL.md` | Audit workflow, decision rules, report template, and guardrails |
| `scripts/check_static_smells.py` | Dependency-free deterministic checker |
| `scripts/test_check_static_smells.py` | Black-box regression tests |
| `references/smell-catalog.md` | Complete 26-smell taxonomy and review questions |
| `references/paper.md` | PDF-to-Markdown conversion of arXiv:2607.01456v2 |
| `agents/openai.yaml` | Codex skill interface metadata |

## Verification

From the repository root:

```bash
python skill-smell-checker/scripts/test_check_static_smells.py
python skill-smell-checker/scripts/check_static_smells.py \
  skill-smell-checker/SKILL.md --pretty
```

The semantic checks remain contextual judgments. The paper reports weighted F1
of 0.78 for its LLM-based semantic detector, so reports should preserve evidence,
confidence, and uncertainty rather than treating those 21 checks as ground
truth.
