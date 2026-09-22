# Harness — runnable reference implementations

These are the scripts that built the `gitlab-org/gitlab` security-fix oracle,
copied here as the reference implementation. They are **parameterized for that
build** — re-point the constants before running on a different repo.

## ⚠️ Edit these constants first

Every Python tool hardcodes two paths at the top of the file:

| Constant | Meaning | Example |
|----------|---------|---------|
| `REPO` | the (blob-materialized) local clone you mine | `~/Personal_Projects/find-ctfs/gitlab` |
| `ORACLE` | the output directory for corpora + parquet | `<repo>/oracle` |

The `.wf.js` workflow scripts take these as runtime `args` (with the same GitLab
defaults baked in) — pass `{repo, outDir, manifest, total, batchSize}` to override.

## Dependencies

- `git` (a clone with **blobs materialized** for SZZ blame — see `../references/02-diff-fetching.md`)
- Python: `pyarrow`, `duckdb`, `pandas` (`pip install pyarrow duckdb pandas`)
- A subagent runner for the `.wf.js` scripts: the Claude Code **Workflow tool**
  (the `agent()/parallel()/phase()` API) or an equivalent that can fan out
  schema-validated subagents. For the CVSS phase, any main-loop that can dispatch
  ~16 parallel `task`/subagent calls per turn.

## File manifest

| File | Phase | Model | Reads | Writes |
|------|-------|-------|-------|--------|
| `gitlab_haiku_analysis.wf.js` | 1 — mine & triage | Haiku | commit manifest (JSONL/JSON) | per-batch `msg-*.jsonl` / `diff-*.jsonl` verdicts |
| `haiku_regate.wf.js` | 2 — re-gate suspects | Haiku | `regate-input.json` (suspect pool) | `regate-*.jsonl` (kept/flipped) |
| `fetch_diffs.py` | 3 — fetch fix diffs | none (git I/O) | gold corpus + message-commits | `commit-diffs.jsonl` |
| `prep_nonruby.py` | 4 — non-Ruby prep | none (git I/O) | parquet `empty`/`timeout` rows | `nonruby-analysis-input.json` (+ appends diffs) |
| `nonruby_analyze.wf.js` | 4 — non-Ruby confirm | Sonnet | `nonruby-analysis-input.json` | `analysis/nonruby-*.jsonl` |
| `build_parquet.py` | 5 — package | none | all corpora + diffs + verdicts | `security-commits.parquet` + dictionary |
| `cvss_score.py` | 6 — CVSS prep/dispatch | none (orchestrator) | parquet | `analysis/cvss-batch-*.json` slices |
| `cvss_prompt.md` | 6 — CVSS LLM contract | (template) | — | the per-batch fixer prompt |
| `fix_shas.py` | 6 — SHA repair | none | `cvss-*.jsonl` + batch slices | re-anchored `cvss-*.jsonl` |
| `cvss_aggregate.py` | 6 — validate + write | none (CVSS math) | `cvss-*.jsonl` | `security-commits-cvss.parquet` |
| `szz.py` | 7 — SZZ (gold aggregate) | none (git blame) | gold corpus | `szz-attribution.jsonl` + `szz-introducers.json` (**PII, git-ignore**) |
| `szz_parquet.py` | 7 — SZZ (per-row column) | none (git blame) | the cvss parquet | adds `szz_*` columns (**PII, git-ignore the parquet**) |

## Run order

```
# Phase 1 — coarse triage of ALL commits (text only), then precise diff pass on candidates
Workflow: gitlab_haiku_analysis.wf.js  {mode:'message', manifest, total}
Workflow: gitlab_haiku_analysis.wf.js  {mode:'diff', manifest, total}   # candidates only

# Phase 2 — strip false positives from the suspect pool
Workflow: haiku_regate.wf.js  {input: regate-input.json, total}

# Phase 3 — fetch the fix patch for every SHA (resumable)
python3 fetch_diffs.py

# Phase 4 — recover non-primary-language fixes
python3 prep_nonruby.py
Workflow: nonruby_analyze.wf.js  {input: nonruby-analysis-input.json, total}

# Phase 5 — assemble the leakage-free tiered parquet + data dictionary
python3 build_parquet.py

# Phase 6 — CVSS 3.1 enrichment (LLM vector + procedural score)
python3 cvss_score.py --prep
#   dispatch waves of ~16 fixer subagents using `cvss_score.py --print <idx>` as each prompt
python3 fix_shas.py --all          # repair hallucinated SHAs before aggregating
python3 cvss_aggregate.py          # validate vectors, recompute scores, write cvss parquet

# Phase 7 — SZZ introducer attribution (requires blob-materialized clone!)
python3 szz.py                     # gold aggregate + per-author skill-gap
python3 szz_parquet.py             # per-row blame columns on the cvss parquet
```

Phases 6 and 7 are independent enrichments — once `commit-diffs.jsonl` /
the parquet exist, run them in any order.

## Idempotency / resume

Every step is safe to re-run. Agents skip SHAs already in their output; Python
aggregators overwrite from the latest on-disk state; `--prep`/slice steps
overwrite their slices. Aggregate after each wave to checkpoint. See
`../references/07-orchestration-harness.md`.

## Provenance

Canonical copies live in `vuln-research/rules/ruby/tools/` of the
[skillsmd](https://github.com/Lu1sDV/skillsmd) repo, where they remain wired to
the live GitLab oracle build. These copies are the portable reference.
