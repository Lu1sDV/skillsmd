# Skill Quality Rubric

Evaluation criteria extracted from `superpowers:writing-skills`. Use when scoring candidate skills in "Compare to find best" mode.

## 1. Description Quality (CSO)

Source: Claude Search Optimization section.

**Strong (2):**
- Starts with "Use when..." focusing on triggering conditions
- Specific triggers, symptoms, and situations — not what the skill does
- Third-person voice (injected into system prompt)
- No workflow summary in description (causes Claude to shortcut the skill body)
- ≤1024 chars total, ≤500 chars preferred

**Red flags (0-1):**
- Vague ("helps with projects", "for async testing")
- First/second person ("I can help you...")
- Summarizes the skill's process or workflow in description
- Missing "Use when..." pattern
- Technology-specific triggers when the skill is technology-agnostic

```yaml
# BAD: Summarizes workflow — Claude follows description, skips skill body
description: Use for TDD - write test first, watch it fail, write minimal code, refactor

# GOOD: Just triggering conditions
description: Use when implementing any feature or bugfix, before writing implementation code
```

## 2. Token Efficiency

Source: Token Efficiency (Critical) section.

**Strong (2):**
- Body ≤500 words (getting-started <150, frequently-loaded <200)
- Assumes Claude's baseline knowledge — only adds what Claude doesn't know
- Heavy reference (100+ lines) split to separate files
- Uses cross-references to other skills instead of repeating content
- Compressed examples (minimal, not verbose)
- References `--help` for tool flags instead of documenting them inline

**Red flags (0-1):**
- Verbose explanations of concepts Claude already knows (what PDFs are, how libraries work)
- Everything inlined in one massive SKILL.md
- Multiple examples of the same pattern
- Exceeds word count targets

Verify: `wc -w SKILL.md`

## 3. Structure & Organization

Source: SKILL.md Structure + File Organization sections.

**Strong (2):**
- Valid YAML frontmatter with `name` and `description` fields
- `name` uses only letters, numbers, hyphens (no special chars)
- Expected sections: Overview, When to Use, Quick Reference, Implementation, Common Mistakes
- Separate files for heavy reference (100+ lines) and reusable tools
- Flat namespace — all skills in one searchable level
- Code inline for patterns <50 lines

**Red flags (0-1):**
- Missing or invalid YAML frontmatter
- Monolithic file with 600+ lines of inlined reference
- Nested references (A links to B links to C)
- No Quick Reference or Common Mistakes section
- Generic labels (step1, helper2) instead of semantic names

## 4. Degrees of Freedom

Source: Set appropriate degrees of freedom section.

**Strong (2):**
- Freedom level matched to task fragility:
  - **High freedom** (text instructions): multiple valid approaches, context-dependent decisions
  - **Medium freedom** (pseudocode/parameterized): preferred pattern exists, some variation OK
  - **Low freedom** (exact scripts): fragile operations, consistency critical, specific sequence required
- Analogy: narrow bridge with cliffs = low freedom; open field = high freedom

**Red flags (0-1):**
- Over-constraining creative tasks (code review forced into rigid steps)
- Under-constraining fragile operations (database migration with optional flags)
- No validation gates on fragile workflows
- Ambiguous ordering where sequence matters

## 5. Domain Value

Source: When to Create a Skill + Skill Types sections.

**Strong (2):**
- Non-obvious gotchas and silent-error warnings
- Version-specific traps not in official docs
- Technique wasn't intuitively obvious
- Broadly applicable across projects
- Covers troubleshooting beyond official documentation
- Clear skill type: technique (steps), pattern (mental model), or reference (API docs)

**Red flags (0-1):**
- Only restates what Claude already knows or what official docs cover
- One-off solution dressed as a skill
- Project-specific conventions that belong in CLAUDE.md
- Mechanical constraints that should be automated with regex/validation

## 6. Code & Examples

Source: Code Examples + Anti-Patterns sections.

**Strong (2):**
- One excellent, runnable example in the most relevant language
- Well-commented explaining WHY, not WHAT
- From a real scenario, shows pattern clearly
- Ready to adapt (not a generic fill-in template)
- Right language choice for domain (testing=TS/JS, system=Shell/Python, data=Python)

**Red flags (0-1):**
- Multi-language dilution (same example in 5+ languages)
- Generic fill-in-the-blank templates
- Contrived examples that don't reflect real usage
- Narrative storytelling ("In session 2025-10-03, we found...")
- Code embedded in flowcharts (can't copy-paste)

## Scoring

| Score | Meaning |
|-------|---------|
| 2 | Strong — meets all criteria for this dimension |
| 1 | Acceptable — minor gaps but functional |
| 0 | Red flags — significant issues in this dimension |

**Total: /12.** Present as side-by-side table with per-dimension scores, `wc -w` word count, and 1-sentence key finding per candidate.
