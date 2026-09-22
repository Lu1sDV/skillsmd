---
name: security-fix-oracle
description: >
  Use when turning a real project's git history into a labeled, enriched,
  leakage-free security-fix dataset ("oracle") for a vulnerability classifier,
  rule-authoring feed, or risk-prioritization model. Triggers: "mine commits for
  security fixes", "build a vuln dataset / training corpus from git history",
  "label commits by CWE / vuln category", "SZZ", "blame who introduced the
  vulnerability", "vulnerability-introducer attribution", "skill-gap analysis",
  "CVSS scoring of commits", "diff-verified gold vs message-only weak labels",
  "git blame on a blobless / partial clone is slow". Also load when extending the
  vuln-research Ruby rule MegaDB oracle.
---

# Security-Fix Oracle — mining git history into a labeled vuln dataset

A reproducible pipeline + runnable **harness** for converting a project's commit
history into a quality-tiered, leakage-aware dataset of security fixes, enriched
with **CVSS 3.1** scores and **SZZ vulnerability-introducer attribution**. Built
and validated on `gitlab-org/gitlab` (189k commits → 18,202 security-relevant →
1,018 diff-verified gold + 204 non-Ruby confirmed; CVSS over 18,060 rows; SZZ over
13,643 diffed rows). The methodology is repo-agnostic; the harness constants point
at the GitLab build and are meant to be re-pointed.

## What it produces

A single Parquet (one row per commit SHA) with:
- **labels**: `category` (vuln-class taxonomy term), `cwe[]`, `quality_tier` (gold/weak)
- **features**: `subject`, `body`, `diff` (the fix patch), `sink`, `tainted_input`, `language`
- **enrichment**: `cvss_score`/`cvss_vector`/`cvss_severity`, `vuln_class_cwe[]`
- **attribution** (optional sidecar column, PII): `szz_introducers`, `szz_primary_introducer`, …
- **quality signals**: `is_security_fix_regate`, `label_disagreement`, `near_dup_subject_hash`

…plus a **data dictionary** documenting every column and the read-before-modeling
caveats (train on gold, never use model-generated text as features, avoid random
splits because of backports).

## Pipeline (7 phases)

| # | Phase | Harness | Model? | Output |
|---|-------|---------|--------|--------|
| 1 | **Mine & triage** — classify every commit's security relevance + vuln class from title/body at scale, then a precise diff pass | `gitlab_haiku_analysis.wf.js` (`mode=message` 80/batch, `mode=diff` 25/batch) | Haiku (cheap, massive fan-out) | per-batch `*.jsonl` verdicts |
| 2 | **Re-gate false positives** — strip chore/CI/merge/i18n noise the title pass over-flagged | `haiku_regate.wf.js` | Haiku | corrected `is_security_fix_regate` |
| 3 | **Fetch fix diffs** — `git diff <sha>^1 <sha>` (handles merges); resumable, per-tier timeouts | `fetch_diffs.py` | none (pure git I/O) | `commit-diffs.jsonl` |
| 4 | **Cross-language coverage** — find security fixes whose patch is non-Ruby (JS/Vue/Go/…), diff-verify each | `prep_nonruby.py` (I/O) + `nonruby_analyze.wf.js` | Sonnet (diff-level judgement) | confirmed non-Ruby corpus |
| 5 | **Package** — assemble the leakage-free, tiered Parquet + dictionary | `build_parquet.py` | none | `security-commits.parquet` |
| 6 | **CVSS enrichment** — hybrid: LLM picks the 8-metric vector, Python computes the canonical score | `cvss_score.py` + `cvss_prompt.md` + `cvss_aggregate.py` (+ `fix_shas.py`) | LLM vector + procedural score | `security-commits-cvss.parquet` |
| 7 | **SZZ attribution** — blame the fixed lines at `<sha>^1` to find who introduced the bug + skill-gap lift | `szz.py` (gold aggregate) / `szz_parquet.py` (per-row column) | none (git blame) | `szz-*.json(l)`, parquet `szz_*` cols |

Phases 1→5 are the dataset; 6 and 7 are independent enrichments you can run in any
order once the diffs exist. **Read the matching reference doc before running a phase.**

## Routing — load the reference for the phase you're in

| If you are… | Read |
|-------------|------|
| Mining commits / designing the triage taxonomy / re-gating | `references/01-mining-triage.md` |
| Fetching diffs, or `git blame`/fetch is slow on a partial clone | `references/02-diff-fetching.md` |
| Deciding gold vs weak, avoiding target leakage, designing splits, Parquet schema | `references/03-tiered-labeling.md` |
| Covering non-primary languages (frontend/Go/etc.) | `references/04-cross-language.md` |
| Adding CVSS 3.1 scores + CWE classes | `references/05-cvss-enrichment.md` |
| Doing SZZ introducer attribution / skill-gap, handling author PII | `references/06-szz-attribution.md` |
| Orchestrating the agent waves / resuming a crashed run | `references/07-orchestration-harness.md` |

## When to use / not use

**Use** when you have (a) a git repo with enough history that fixes are findable,
and (b) a downstream need for *labeled* security fixes — training a classifier,
feeding a SAST rule-authoring loop, or prioritizing review by risk.

**Don't use** for: a handful of known CVEs (just read them); live vulnerability
management (CVSS here reflects the vuln at fix-time, no temporal threat
adjustment); or repos whose security commits are too few to tier.

## Cross-cutting gotchas (the expensive lessons)

1. **`git blame` is unusable on a `blob:none` partial clone** (>90 s/file — it
   lazy-fetches every historical blob). `git diff <sha>^1 <sha>` needs only 2 blobs
   (fast), but blame reconstructs full file history. Fix: materialize blobs once
   (`git fetch --refetch` after unsetting `remote.origin.partialclonefilter`), then
   blame is ~0.1–0.8 s/file. See `references/02`.
2. **A huge server-side repack can abort the refetch** with `curl 28: Operation too
   slow`. Survive it with `-c http.lowSpeedLimit=0 -c http.postBuffer=524288000 -c
   http.version=HTTP/1.1`.
3. **Use `git diff <sha>^1 <sha>`, never `git show`** — ~39% of security fixes land
   as merge commits where `git show` returns the empty combined-diff. First-parent
   diff = "what the merge changed vs master-before" = the fix.
4. **Never feed model-generated text back as a feature** (`vuln_summary`, `rule_idea`,
   …). It was produced *from* the labeled text and leaks the target. Keep for audit
   only. The `diff` column is genuine signal (a fix legitimately contains the
   vulnerable code) — usable as a feature with that understanding.
5. **Train only on the diff-verified `gold` tier.** Message-only `weak` labels
   disagree with diff-verified labels on ~65% of the overlap; they are weak
   supervision / eval-only.
6. **Avoid random splits** — backports and near-duplicate fixes repeat across the
   set. Use a temporal holdout + a `near_dup_subject_hash` guard.
7. **CVSS: trust the vector, not the LLM's number.** The LLM is good at picking the
   8 metrics, mediocre at the multiplication chain (~48% of its scores needed
   override). Re-compute the score from the vector procedurally.
8. **LLMs hallucinate SHAs** (~1 per 200–300 rows) and **abbreviate them**. Keep
   input order in batches and re-anchor (`fix_shas.py`); verify SHA-prefix
   collisions are zero before any prefix-recovery join.
9. **SZZ output is author PII.** Names/emails of introducers must not be published —
   git-ignore those artifacts (and any parquet that embeds them). Read SZZ as a
   **team/area training-need signal, not an individual blame leaderboard**.
10. **Every phase is idempotent + resumable** by design (skip-SHAs-already-present,
    overwrite-from-latest-state). Aggregate after each agent wave to checkpoint.

## Orchestration model

Phases 1, 2, 4 fan out across many subagents via the **Workflow tool** (`.wf.js`
scripts: schema-validated agents, parallel batches, `model:` pinned per phase).
Phase 6 dispatches **waves of ~16 parallel fixer subagents** from the main loop.
Route the cheapest adequate model per phase: **Haiku** for scale triage, **Sonnet**
for diff-level judgement, **procedural Python** for anything deterministic (diffs,
blame, CVSS math) — no model where none is needed. See `references/07`.

## Harness

`harness/` ships the runnable reference implementations (copied from the GitLab
build's `vuln-research/rules/ruby/tools/`). Constants `REPO` (the clone) and
`ORACLE` (output dir) are hardcoded to that build — **re-point them** for a new
repo. `harness/README.md` is the per-file manifest + edit checklist.

## Relationship to vuln-research

This skill *feeds* the `vuln-research` Ruby rule MegaDB: the oracle's `rule_idea`
and diff-verified fixes are the authoring feed for Semgrep/CodeQL detection rules.
A mirror of this doc lives at `vuln-research/references/security-fix-oracle.md`.
For building **sink catalogs** for an unseen language, hand off to
`sink-research-orchestrator`.
