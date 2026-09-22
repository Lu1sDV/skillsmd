# security-fix-oracle

A Claude Code skill: a reproducible pipeline + runnable harness for turning a
real project's **git history into a labeled, enriched, leakage-free security-fix
dataset** ("oracle") — for training a vulnerability classifier, feeding a SAST
rule-authoring loop, or prioritizing review by risk.

Built and validated on `gitlab-org/gitlab`: 189k commits → 18,202
security-relevant → 1,018 diff-verified gold + 204 confirmed non-Ruby fixes;
CVSS 3.1 over 18,060 rows; SZZ vulnerability-introducer attribution over 13,643
diffed rows. The methodology is repo-agnostic.

## What you get

A single Parquet (one row per commit) with vuln-class + CWE **labels**, the fix
**diff** and other honest features, **CVSS 3.1** scores, optional **SZZ
introducer** attribution, and quality signals — plus a data dictionary spelling
out the read-before-modeling caveats (train on gold, never use model-generated
text as features, avoid random splits).

## Pipeline

| # | Phase | Model |
|---|-------|-------|
| 1 | Mine & triage commits by security relevance + vuln class | Haiku (scale) |
| 2 | Re-gate — strip chore/CI/merge false positives | Haiku |
| 3 | Fetch fix diffs (`git diff <sha>^1 <sha>`, merge-safe) | none (git I/O) |
| 4 | Recover non-primary-language fixes (JS/Vue/Go/…) | Sonnet (diff judgement) |
| 5 | Package the leakage-free, tiered Parquet | none |
| 6 | CVSS 3.1 enrichment (LLM vector + procedural score) | LLM + procedural |
| 7 | SZZ introducer attribution + skill-gap | none (git blame) |

Full detail per phase in [`references/`](references/). The runnable scripts are
in [`harness/`](harness/) (see [`harness/README.md`](harness/README.md)).

## Install

Plugin marketplace:

```
/plugin marketplace add Lu1sDV/skillsmd
/plugin install security-fix-oracle@Lu1sDV/skillsmd
```

Or local (for testing):

```bash
cp -r security-fix-oracle ~/.claude/skills/
```

Then ask Claude something like *"build a security-fix dataset from this repo's
history"*, *"do SZZ blame attribution to find who introduced these vulns"*, or
*"add CVSS scores to my commit corpus"*, and the skill activates.

## Requirements

- `git` (with **blobs materialized** if you run SZZ — see
  [`references/02-diff-fetching.md`](references/02-diff-fetching.md))
- Python: `pyarrow`, `duckdb`, `pandas`
- A subagent runner for the fan-out phases (Claude Code Workflow tool or
  equivalent)

## The expensive lessons (read these first)

- **`git show` misses ~39% of fixes** — they're merge commits with an empty
  combined-diff. Use `git diff <sha>^1 <sha>`.
- **`git blame` is unusable on a `blob:none` partial clone** (>90 s/file).
  Materialize blobs once with `git fetch --refetch`.
- **Never feed model-generated text back as a feature** — it leaks the label.
  The `diff` is genuine signal; the LLM summaries are not.
- **Train only on the diff-verified `gold` tier** — message-only labels disagree
  ~65% of the time.
- **CVSS: trust the vector, recompute the score** — the LLM picks metrics well
  but botches the arithmetic ~48% of the time.
- **SZZ output is author PII** — git-ignore it; read it as a team training-need
  signal, not a blame leaderboard.

## Relationship to other skills

Feeds [`vuln-research`](../vuln-research/) (the oracle's diff-verified fixes +
`rule_idea`s are the authoring feed for Semgrep/CodeQL rules). For building sink
catalogs for an unseen language, see
[`sink-research-orchestrator`](../sink-research-orchestrator/).
