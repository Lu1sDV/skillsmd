---
name: universal-skill-finder
description: Use when finding, browsing, or installing community skills across marketplaces, or when a needed capability might exist as a marketplace skill. Triggers on "find a skill", "search skills", "install skill", "skillsmp", "skills.sh", or "marketplace".
---

# Universal Skill Finder (SkillsMP + skills.sh)

Search 11,000+ community skills and install them locally.
Also search skills.sh in the same pass — one merged table whose **Market** column shows where each skill was found: `skillsmp`, `skills.sh`, or `both`.

## When to Use

- User asks to find/search/install a skill
- User needs a capability that likely exists as a community skill

**Not for:** Project-specific conventions (CLAUDE.md), already-installed skills.

## Quick Reference

| Step | Action |
|------|--------|
| Search | `GET https://skillsmp.com/api/skills?q=<query>&sortBy=recent` |
| Present | Show top 3-5 results with name, author, description, install count |
| Install | `npx skills add <author>/<repo>` or copy to `~/.claude/skills/` |
| Verify | Ask Claude "What skills are available?" |
| Search skills.sh | `npx -y skills find "<query>"` — no API key, no token |
| Present (both markets) | One merged table with Market column: `skillsmp` / `skills.sh` / `both` |
| Install (skills.sh) | `npx skills add <owner/repo@skill>` |

## API Config

- **Base**: `https://skillsmp.com/api/v1/skills`
- **Key**: `$SKILLSMP_API_KEY` environment variable
- **Auth**: `Authorization: Bearer $SKILLSMP_API_KEY` | **Limit**: 500/day

**skills.sh**: no API config. Use the `npx -y skills` CLI only (official [find-skills](https://github.com/vercel-labs/skills) guidelines). Do NOT call the skills.sh REST API (`https://skills.sh/api/v1/*`) — it requires a Vercel OIDC token and returns `401 authentication_required` for local use.

## Search

**Keyword** (fast, ~500ms) - specific terms, sort by stars:
```bash
curl -s "https://skillsmp.com/api/v1/skills/search?q=QUERY&limit=30&sortBy=stars" \
  -H "Authorization: Bearer $SKILLSMP_API_KEY"
```
Response: `data.skills[]` → `id`, `name`, `author`, `description`, `githubUrl`, `stars`, `updatedAt`

**AI Semantic** (smart, ~5s) - natural language, conceptual queries:
```bash
curl -s "https://skillsmp.com/api/v1/skills/ai-search?q=QUERY" \
  -H "Authorization: Bearer $SKILLSMP_API_KEY"
```
Response: `data.data[]` → `score` (0-1) + `skill` object. **Skip entries with `skill: null`.**

| Query type | Mode |
|------------|------|
| Specific tech ("react testing") | Keyword, `sortBy=stars` |
| Natural language / vague | AI semantic |
| "newest", "latest", "recent skills" | Keyword, `sortBy=recent` |

Fall back to keyword if AI returns few results.

### skills.sh Search (CLI, no auth)

Per the official find-skills guidelines, search skills.sh with the Skills CLI:

```bash
npx -y skills find "QUERY" [--owner <owner>] | sed 's/\x1b\[[0-9;]*m//g'
```

Output is ranked by installs — parse each `owner/repo@slug N installs` line plus its following `└ URL` line. The CLI **always emits ANSI color codes**, even when piped (`NO_COLOR=1` is ignored) — the `sed` strip above makes the output parseable:

```
affaan-m/ecc@react-performance 3.6K installs
└ https://skills.sh/affaan-m/ecc/react-performance
```

First `npx` run downloads the CLI (~30s); subsequent runs are fast. No API key, no token, no signup.

**Quality gates before recommending (find-skills heuristics):**
- Prefer skills with **1K+ installs**; be cautious under 100
- Trust official sources (`vercel-labs`, `anthropics`, `microsoft`) over unknown authors
- Treat source repos with <100 GitHub stars with skepticism

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

### Merged Results (both markets)

When both markets are searched, merge into ONE ranked table with a **Market** column:

```
| # | Skill | Source | Market | ★ (skillsmp) | Installs (skills.sh) | Description |
|---|-------|--------|--------|--------------|----------------------|-------------|
| 1 | name  | owner/repo | both | 42 | 3.6K | ... |
| 2 | name  | @author | skillsmp | 42 | — | ... |
| 3 | name  | owner/repo | skills.sh | — | 3.6K | ... |
```

**Market = `both`** — the same skill was found in both markets. Detection rule:
1. Extract `owner/repo` from the skillsmp result's `githubUrl`
2. Normalize the skillsmp `name` to kebab-case
3. Match against the skills.sh `owner/repo@slug`
4. Match → single row, Market=`both`, show BOTH ★ and installs

No match → separate rows with the originating market. Ordering: keep each market's ranking; a `both` row takes its better (higher) position. `—` marks a metric the market doesn't provide.

If `$SKILLSMP_API_KEY` is missing/401: degrade gracefully — show skills.sh-only table plus a one-line notice ("skillsmp skipped: no API key"). Never hard-fail the whole search.

### Compare to find best

When user selects "Compare to find best":

1. **Gather criteria**: Ask user to expand needs/priorities (optional)
2. **Load evaluation rubric**: Read `external/writing-skills-rubric.md` for the full scoring framework (6 dimensions, 0-2 each, /12 total)
3. **Fetch & evaluate**: Download SKILL.md from top candidates, score per rubric dimensions:
   - Description quality (CSO) | Token efficiency | Structure & organization
   - Degrees of freedom | Domain value | Code & examples
4. **Present comparison**: Side-by-side table with per-dimension scores (total /12), SKILL.md word count (`wc -w`), and 1-sentence key finding per candidate
5. **Final decision**: Use `AskUserQuestion` to let user pick the winner

Consult `external/anthropic-skills-best-practices.md` for edge-case evaluation details only.

For **skills.sh candidates** in step 3, get the SKILL.md content without installing:

```bash
npx -y skills use <owner/repo@skill>
```

Its output contains the full SKILL.md — score that with the same rubric.

## Install

After user picks:
1. **Transform URL**: `github.com/U/R/tree/B/P` → `raw.githubusercontent.com/U/R/B/P/SKILL.md` (replace domain, remove `/tree` from `/tree/BRANCH` leaving `/BRANCH`)
2. **Fetch**: `curl -s "RAW_URL"`
3. **Ask scope** via `AskUserQuestion`: global (`~/.claude/skills/`) or project-local (`.claude/skills/`)
4. **Save** as `{name}/SKILL.md`, verify frontmatter, confirm activation

**skills.sh picks** — install with the Skills CLI instead of the raw-URL transform:

```bash
npx skills add <owner/repo@skill> -g -y   # -g = global; omit for project scope
```

Ask global vs project scope via `AskUserQuestion` first (same as step 3 above); `-y` skips confirmation prompts.

## Mistakes & Errors

| Issue | Fix |
|-------|-----|
| Auto-selecting without asking | Always `AskUserQuestion` for user choice |
| Raw URL 404 | Verify `/tree` removed, domain replaced; try lowercase `skill.md` |
| `skill: null` in AI results | Filter out before presenting |
| 0-star vs high-star conflict | Cross-check both search modes; review content of 0-star skills before installing |
| 401 | Check `$SKILLSMP_API_KEY` is set — run `echo $SKILLSMP_API_KEY` |
| 429 | Daily quota hit, retry tomorrow |
| Curl exit 56 | Transient network error, retry |
| skillsmp 401 AND user has no key | Degrade: skills.sh-only table + one-line notice, keep going |
| skills.sh CLI slow on first run | Normal — `npx` downloads the CLI (~30s); subsequent calls are fast |
| skills.sh search returns nothing | Query needs ≥2 chars; try alternative terms ("deploy" → "deployment", "ci-cd") |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Installing without checking existing skills | Run "What skills are available?" first |
| Using wrong install path | Skills go in `~/.claude/skills/<skill-name>/SKILL.md` |
| Searching too broadly ("testing") | Be specific: "playwright e2e testing" |
| Installing multiple overlapping skills | Check descriptions for overlap before installing |
| Forgetting to verify after install | Always confirm skill loaded with a test prompt |
| Merging same-named skills from different authors | `both` requires `owner/repo` match, not name alone |
| Calling skills.sh REST API directly | REST needs Vercel OIDC (401); use `npx -y skills find` |
