---
name: skillsmp-search
description: Use when the user wants to find, browse, or install community skills, or needs a capability that might exist as a marketplace skill. Triggers on "find a skill", "search skills", "install skill", "skillsmp", or "marketplace".
---

# SkillsMP Search & Installer

Search 11,000+ community skills and install them locally.

## When to Use

- User asks to find/search/install a skill
- User needs a capability that likely exists as a community skill

**Not for:** Project-specific conventions (CLAUDE.md), already-installed skills.

## API Config

- **Base**: `https://skillsmp.com/api/v1/skills`
- **Key**: `cat ~/.claude/skills/skillsmp-search/.skillsmp-key`
- **Auth**: `Authorization: Bearer <key>` | **Limit**: 500/day

## Search

**Keyword** (fast, ~500ms) - specific terms, sort by stars:
```bash
curl -s "https://skillsmp.com/api/v1/skills/search?q=QUERY&limit=30&sortBy=stars" \
  -H "Authorization: Bearer $(cat ~/.claude/skills/skillsmp-search/.skillsmp-key)"
```
Response: `data.skills[]` → `id`, `name`, `author`, `description`, `githubUrl`, `stars`, `updatedAt`

**AI Semantic** (smart, ~5s) - natural language, conceptual queries:
```bash
curl -s "https://skillsmp.com/api/v1/skills/ai-search?q=QUERY" \
  -H "Authorization: Bearer $(cat ~/.claude/skills/skillsmp-search/.skillsmp-key)"
```
Response: `data.data[]` → `score` (0-1) + `skill` object. **Skip entries with `skill: null`.**

| Query type | Mode |
|------------|------|
| Specific tech ("react testing") | Keyword, `sortBy=stars` |
| Natural language / vague | AI semantic |

Fall back to keyword if AI returns few results.

## Present & Choose

Show **ALL** found skills in the ranked table — never truncate or omit results. Then **use `AskUserQuestion` to let user pick** - never auto-select.

Always include a **"Compare to find best"** option in addition to numbered skill choices:

```
| # | Skill | Author | Stars | Description |
|---|-------|--------|-------|-------------|
| 1 | name  | @author | 42   | ...         |
```

Include relevance score for AI results.

AskUserQuestion options: numbered skills + **"Compare to find best"**

### Compare to find best

When user selects "Compare to find best":

1. **Gather criteria**: Ask user to expand needs/priorities (optional - they may just confirm)
2. **Load standards**: Read `external/anthropic-skills-best-practices.md` for the quality checklist
3. **Fetch & evaluate**: Download SKILL.md from top candidates, score each against:
   - Description quality & trigger specificity
   - Conciseness & token efficiency
   - Progressive disclosure structure
   - Workflow clarity & feedback loops
   - Code quality (if applicable)
4. **Present comparison**: Show strengths/weaknesses table for each candidate
5. **Final decision**: Use `AskUserQuestion` to let user pick the winner

## Install

After user picks:
1. **Transform URL**: `github.com/U/R/tree/B/P` → `raw.githubusercontent.com/U/R/B/P/SKILL.md` (replace domain, remove `/tree` from `/tree/BRANCH` leaving `/BRANCH`)
2. **Fetch**: `curl -s "RAW_URL"`
3. **Ask scope** via `AskUserQuestion`: global (`~/.claude/skills/`) or project-local (`.claude/skills/`)
4. **Save** as `{name}/SKILL.md`, verify frontmatter, confirm activation

## Mistakes & Errors

| Issue | Fix |
|-------|-----|
| Auto-selecting without asking | Always `AskUserQuestion` for user choice |
| Raw URL 404 | Verify `/tree` removed, domain replaced; try lowercase `skill.md` |
| `skill: null` in AI results | Filter out before presenting |
| 0-star vs high-star conflict | Cross-check both search modes; review content of 0-star skills before installing |
| 401 | Check `.skillsmp-key` file |
| 429 | Daily quota hit, retry tomorrow |
| Curl exit 56 | Transient network error, retry |
