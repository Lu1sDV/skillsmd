# Vibe-code detection: the sixth sense

Goal: never refurbish code that nobody understood. This guide turns the intuition into
checks you can run and cite.

## Contents
1. The principle
2. Six evidence channels
3. The 5-minute protocol
4. What serious young projects look like
5. Verdicts and what they allow
6. Evidence base

## 1. The principle

AI involvement is not the problem. Serious projects use Claude Code, Copilot and Cursor
every day, behind review, tests and CI. The problem is **unreviewed** generation: *volume
without decisions*. The question for every candidate:

> Did a human who understood this code decide each part of it, and can you see evidence of those decisions?

Decisions leave traces: design notes that admit trade-offs, consistent conventions, tests
that pin specific edge cases, review threads that change code, and changelogs written for
users. Vibe code leaves volume: features, files, summaries and badges, but no visible
reasoning.

Fingerprints work only in one direction. Coding agents often leave no commit trace
(Cursor, Windsurf and Copilot completions), so **clean commits are not proof of human
code**. Agent config files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`) show tooling
adoption, not vibe code; SQLite has an `AGENTS.md`. Judge **process and artifacts**, not
tools.

## 2. Six evidence channels

The script scores channels A–C. Channels D–F need your eyes.

### A. Provenance (who or what wrote it)

| Tell | Strength | Notes |
|---|---|---|
| App-builder fingerprints: `Replit-Commit-Author: Agent`, `gpt-engineer-app[bot]`/`lovable-dev[bot]`, `.bolt/`, `.replit`, "Lovable project" README | Strong | Generated apps. Fine for prototypes, not for refurbishing |
| ≥ 90% of commits AI-marked (`Co-Authored-By: Claude`, `Generated with Claude Code`, `(aider)`, `devin-ai-integration`, `copilot-swe-agent`) **and** weak review | Strong | This mirrors the research threshold for "vibe-coded" (≥ 90% AI-authored) |
| Most merged PRs opened by coding-agent bots and approved only by the owner | Medium | Rubber-stamp review |
| Owner account younger than 90 days | Medium | Common for throwaway and slop accounts |

### B. Process (how it grew)

| Tell | Strength |
|---|---|
| Code dump: first commit of thousands of lines, with fewer than 30 commits in total | Strong |
| No PRs at all; one author pushing directly to the main branch | Medium |
| Bursts of 25 or more commits by one author in one day | Weak–medium |
| Generic messages ("update", "fix", "Add files via upload") or LLM-register subjects ("Implement comprehensive X with robust Y") | Weak |
| Version theater: v1.0 or v2.0 within weeks; changelogs that just list "Enhanced…/Improved…" | Weak–medium |

Counter-signal: a large initial commit from an **organization** is often an internal
project being open-sourced. Check for later organic history.

### C. Artifacts (what's lying around)

| Tell | Strength |
|---|---|
| Agent leftover docs in the root: `IMPLEMENTATION_SUMMARY.md`, `FINAL_REPORT.md`, `FIXES_APPLIED.md`, `SETUP_COMPLETE.md`, `*_STATUS.md` | Strong when there are 2 or more |
| Duplicate variants: `foo.py` next to `foo_fixed.py`/`foo_new.py`/`enhanced_foo.py` (versioned modules like `api_v1`/`api_v2` are fine) | Strong when there are 3 or more |
| Scratch scripts in the root: `test_*.py`, `debug_*.py`, `quick_*.py` outside any test suite | Medium |
| Committed `node_modules/`, virtualenvs, `*.pyc` | Medium |
| Many code files and zero tests; no CI, or CI that is always red | Medium |
| README: emoji on every heading, walls of static badges, "production-ready / enterprise-grade / blazing fast" with no benchmark, 30-bullet feature lists | Weak–medium |
| "Production-ready" or "battle-tested" claims on a repo under 6 months old | Medium |

### D. Code (read the core, see the protocol below)

- **Narrating comments:** `# Step 1:`, `# Now we…`, `# FIXED:`, `# NEW:`, `# Enhanced version`, `# As requested`.
- **Fake success paths:** `except Exception: return {"status": "success"}`; "fallback to
  mock data"; `simulate_*` or `mock_*` functions on production paths; hardcoded
  placeholder results behind confident names.
- **API drift:** calls to functions that don't exist in the pinned dependency version, or
  old and new SDK styles mixed in one codebase.
- **Inconsistent shape:** three logging styles, two HTTP clients, `utils.py` + `helpers.py`
  + `common.py` with overlapping functions. No single mind shaped it.
- **Ceremony:** Manager → Service → Handler → Factory layers wrapping one API call.
- **Emoji in library logs** (`✅ Done!`, `🚀 Starting`), print-debugging in library code.
- **Tests that can't fail:** `assert True`, asserting that a mock returns its mocked value, tests that only print.
- **Demo-oriented security:** client-side-only auth checks, `CORS: *`, unauthenticated
  admin routes, row-level security off, secrets in `.env` committed to the repo.

### E. Claims compared with reality

- Pick 2 headline README features and grep for them. Missing or stubbed means vibe code.
- Benchmarks without a script and environment to reproduce them don't count.
- Look for a section on limitations or non-goals. Honest projects say what they don't do;
  vibe READMEs win every row of their own comparison table.

### F. Attention compared with adoption

- Stars far above forks, dependents and external issues suggest hype or bought stars.
- Star velocity of tens per day on a young repo: verify real adoption (downloads,
  dependents, issues from real users) before trusting it.

## 3. The 5-minute protocol

Run this after the script, for anything not already clearly Tier A, and **always** on the young-field track.

1. **Script verdict.** Read its tells and green signals and note what is borderline.
2. **Tree (30 s).** Open the root. Leftover docs, variants, scratch scripts and committed
   dependencies are visible at a glance.
3. **Core file (2 min).** Find the file that does the main job (follow the README's headline
   feature) and read 100–200 lines. Check channel D. Does the error handling make
   decisions, or does it swallow errors?
4. **Claim check (1 min).** Grep two README features. Check that the README's install
   command uses a package name that exists (`pypi:<name>` in the script).
5. **Review culture (1 min).** Open 2–3 recently merged PRs. Look for human review comments
   that changed code. Open 2–3 issues. Are outsiders reporting real bugs, and do the
   maintainers answer with code-level knowledge or with generated text?

Write down what you saw in one line. That line is the evidence in the report.

## 4. What serious young projects look like

Use these as positive evidence on the young-field track, where AI tooling is often
1–3 years old and still the best available:

- **Organization:** an org account; named maintainers with track records; an affiliation
  (lab, company, foundation); a paper with code that reproduces its results.
- **Process:** PRs with substantive review; CODEOWNERS or branch protection (Scorecard
  Code-Review, Branch-Protection); external contributors getting merged.
- **Engineering:** tests that pin edge cases; CI enforcing tests, types and lint;
  lockfiles; pinned versions; reproducible benchmarks.
- **Release discipline:** versioned releases with human-written changelogs; deprecation
  notes; semver respected.
- **Communication:** a docs site with an API reference; examples that run; known
  limitations; design docs, RFCs or ADRs.
- **Community:** issues from real users with reproductions; maintainers who push back and
  explain trade-offs.

The script cannot see these. Credit them explicitly when you override:
- inline tests (Rust `#[cfg(test)]`, doctests, mdtest);
- code that lives in another repo (astral-sh/ty builds from the ruff repo);
- review on Gerrit or mailing lists;
- docs on a separate site.

## 5. Verdicts and what they allow

| Verdict | Meaning | Allowed reuse |
|---|---|---|
| LIKELY VIBE-CODED | Strong tells with little discipline, or ≥ 90% AI-marked with weak review | None. You may note an idea, but write your own |
| SUSPECT | Mixed evidence | Cap at Tier C until your protocol read clears it; then use the metric tier |
| No strong tells | Nothing alarming mechanically | Still skim the core file before vendoring or copying |

When you clear a SUSPECT verdict, say why in one line, for example: "the tells come from
`examples/`; the core has tests and a review culture."

## 6. Evidence base

- Khosravani & Mockus (2026), *Detecting AI Coding Agents in Open Source* (arXiv
  2606.24429): a census of 180M repositories. Config files show adoption only; most agent
  use is invisible in commits; no single signal is representative.
- *Understanding the (In)Security of Vibe-Coded Applications* (arXiv 2606.23130): treats a
  repo as vibe-coded when ≥ 90% of commits and lines are AI-authored. Of 200 deployed apps,
  91% had at least one vulnerability, broken access control was the leading class, and
  "demo-oriented design" was a root cause.
- Spracklen et al., USENIX Security 2025, *We Have a Package for You!*: about 20% of
  LLM-recommended packages were hallucinated, many repeatably. This is the basis of
  slopsquatting, and why the script checks that the package exists.
- He et al. (2024), *4.5 Million (Suspected) Fake Stars in GitHub*: stars are gameable.
