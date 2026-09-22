# Security-Fix Oracle

> **When to use**: Load this reference when building or extending a labeled
> security-fix dataset mined from a project's git history — the authoring feed
> behind the Ruby rule MegaDB. Triggers: "mine commits for security fixes",
> "build a vuln dataset from git history", "label commits by CWE / vuln class",
> "SZZ / who introduced the vulnerability / skill-gap", "CVSS-score the commits",
> "gold (diff-verified) vs weak (message-only) labels".

> **Goal**: Convert a repo's commit history into a quality-tiered, leakage-aware
> Parquet of security fixes — enriched with CVSS 3.1 and SZZ introducer
> attribution — that feeds Semgrep/CodeQL rule authoring and risk prioritization.

This is the **embedded mirror** of the standalone `security-fix-oracle` skill.
The full skill (SKILL.md + per-phase references + runnable harness) lives at the
repo root: [`../../security-fix-oracle/`](../../security-fix-oracle/). Its harness
scripts are the canonical copies in
[`rules/ruby/tools/`](../rules/ruby/tools/), wired to the live GitLab oracle.

---

## The 7-phase pipeline

| # | Phase | Model | Output |
|---|-------|-------|--------|
| 1 | **Mine & triage** — classify security relevance + vuln class from title/body at scale (`mode=message`), then a precise Ruby-diff pass (`mode=diff`) | Haiku | per-commit verdicts (`is_security_fix`, `category`, `cwe`, `rule_idea`) |
| 2 | **Re-gate** — default-deny re-judgement of the chore/CI/merge suspect pool | Haiku | corrected `is_security_fix_regate` |
| 3 | **Fetch fix diffs** — `git diff <sha>^1 <sha>` (merge-safe), resumable, per-tier timeouts | none | `commit-diffs.jsonl` |
| 4 | **Cross-language** — recover JS/Vue/Go/HAML/GraphQL fixes the Ruby pass missed, diff-verify each | Sonnet | `nonruby-security-fix-corpus.json` |
| 5 | **Package** — leakage-free, gold/weak-tiered Parquet + data dictionary | none | `security-commits.parquet` |
| 6 | **CVSS 3.1** — LLM picks the 8-metric vector, Python computes the canonical score | LLM + procedural | `security-commits-cvss.parquet` |
| 7 | **SZZ** — blame fixed lines at `<sha>^1` → introducer + skill-gap lift | none (git blame) | `szz-*` (PII) / parquet `szz_*` cols |

Per-phase detail: [`../../security-fix-oracle/references/`](../../security-fix-oracle/references/)
(`01-mining-triage` … `07-orchestration-harness`).

## The load-bearing gotchas

- **`git show` misses ~39% of fixes** (merge commits, empty combined-diff). Use
  `git diff <sha>^1 <sha>`.
- **`git blame` is unusable on a `blob:none` clone** (>90 s/file). Materialize
  blobs once (`git fetch --refetch` after unsetting `partialclonefilter`) before
  SZZ; survive a giant repack with `http.lowSpeedLimit=0`.
- **Train only on the diff-verified `gold` tier** — message-only `weak` labels
  disagree ~65% of the time; they are eval/weak-supervision only.
- **Model-generated text (`vuln_summary`, `rule_idea`, …) is NOT a feature** — it
  leaks the label. The `diff` is genuine signal.
- **CVSS: trust the vector, recompute the score** (LLM botches the arithmetic
  ~48% of the time). LLMs also hallucinate/abbreviate SHAs — re-anchor by batch order.
- **SZZ output is author PII** — git-ignored, local-only; a team/area
  training-need signal, **not** an individual blame leaderboard.

## How this feeds the rule MegaDB

The oracle's **diff-verified gold fixes** (root cause → tainted-input → sink) and
their **`rule_idea`** fields are the Tier-A authoring feed for new Semgrep/CodeQL
rules. The CVSS + CWE enrichment prioritizes which classes to cover first; the SZZ
category-lift surfaces which vuln classes a team repeatedly reintroduces (where a
detection rule pays off most). See the MegaDB state in
[`rules/ruby/`](../rules/ruby/) and `AUTHORING_GUIDE.md`.
