---
name: skill-smell-checker
description: >
  Audits Agent Skill SKILL.md files for the 26 skill smells defined in
  arXiv:2607.01456, separating five static checks from 21 semantic checks.
  It applies when reviewing, linting, authoring, or refactoring SKILL.md files;
  when a skill quality audit is requested; or when terms such as skill smell,
  SSD, static skill check, context bloat, missing guardrails, or vague skill
  description appear.
---

# Skill Smell Checker

Audit all 26 smells from Hong, Imani, and Ahmed's *From Anatomy to Smells*.
Treat the five static results as script-derived facts and the other 21 as
evidence-backed semantic judgments.

## Workflow

1. Locate the target `SKILL.md`. For a repository-wide audit, discover files
   with `rg --files -g '**/SKILL.md'`.
2. Run the deterministic harness:

   ```bash
   python SKILL_DIR/scripts/check_static_smells.py path/to/SKILL.md --pretty
   ```

   Replace `SKILL_DIR` with this skill's directory. Do not manually override
   its five results. Use `--strict` only when a nonzero exit status should fail
   CI.
3. Read [references/smell-catalog.md](references/smell-catalog.md) completely.
4. Review every semantic smell against the full target skill and any bundled
   `scripts/`, `references/`, or `assets/` needed to judge delegation,
   validation, templates, or utility-script availability.
5. For each semantic smell, record `present`, `absent`, or `uncertain`, cite
   concrete file evidence, and give confidence. Never infer a clean result
   from a missing section title alone.
6. Produce the report using the template below. Rank fixes by security,
   execution correctness, discoverability, then context efficiency.
7. If remediation was requested, make the smallest behavior-preserving edits,
   rerun the static harness, and repeat the semantic review for changed smells.

Track multi-file audits as `pending`, `checked`, or `blocked`; do not silently
drop files or smells.

## Decision Rules

- If the harness reports a smell, mark it `present`.
- If the harness cannot parse frontmatter, report its warning and do not claim
  `LSN`, `LSD`, or `XID` are absent.
- If a semantic decision depends on the skill's intended users, required output,
  or acceptable autonomy and the repository does not answer it, ask one focused
  human question. Mark the smell `uncertain` until answered.
- If a smell is condition-dependent, explain why the condition does or does not
  apply; do not treat "not applicable" as missing evidence.
- Do not invent thresholds for semantic smells. The paper specifies numeric
  thresholds only for `LSB`, `LSN`, and `LSD`.
- Do not skip validation because the file looks simple or because another smell
  appears more important. A complete audit covers 5 static and 21 semantic
  smells.

## Report Template

```markdown
# Skill Smell Audit: <path>

## Summary
- Static: <present>/5 present
- Semantic: <present>/21 present, <uncertain> uncertain
- Highest-priority issue: <id and reason>

## Findings
| ID | Smell | Mode | Verdict | Confidence | Evidence | Minimal remediation |
|---|---|---|---|---|---|---|
| LSB | Lengthy Skill Body | static | absent | high | 812 / 5,000 words | — |
| RL | Rationalization Loophole | semantic | present | high | No instruction prevents skipping required validation | Add one explicit completion guard |

## Harness Warnings
<warnings or "None">

## Scope
<files and bundled resources inspected>
```

## Gotchas

- The paper defines **26** smells: **5 static and 21 semantic**.
- The paper reports weighted F1 `0.78` for its semantic LLM detector. Treat
  semantic output as review evidence, not ground truth.
- `BP` detects path-shaped backslashes, not every backslash in code or prose.
- `XID` detects tag-shaped XML in the frontmatter description. Comparisons such
  as `x < y` are not tags.
- The paper's supplementary repository was unavailable during this skill's
  construction. The harness implements the published Table III definitions and
  documents its parser assumptions in `--help`.

## Verification

Run:

```bash
python SKILL_DIR/scripts/test_check_static_smells.py
python SKILL_DIR/scripts/check_static_smells.py SKILL_DIR/SKILL.md --pretty
```

Do not declare an audit complete unless the harness ran successfully and the
report accounts for all 26 smell IDs.

For the converted paper text, read
[references/paper.md](references/paper.md) only when the user asks for the
research basis, methodology, limitations, or exact surrounding discussion.
