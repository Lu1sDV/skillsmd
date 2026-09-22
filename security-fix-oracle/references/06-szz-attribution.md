# PHASE 7 — SZZ Vulnerability-Introducer Attribution

**Goal**: Given a fix commit F, identify which earlier commit(s) introduced the
vulnerable lines — and surface per-author skill-gap signals normalized for
exposure.

Harnesses: [`../harness/szz.py`](../harness/szz.py) (gold-only, writes aggregate)
and [`../harness/szz_parquet.py`](../harness/szz_parquet.py) (all diffed parquet rows,
writes per-row columns).

---

## GATE: Blobs Must Be Materialized

> **This is the single most important prerequisite.** `git blame` on a
> `blob:none` partial clone reconstructs full file history on every call —
> typically **>90 s/file**, making a corpus run infeasible.

Materialize blobs before running either harness:

```bash
git config --unset remote.origin.partialclonefilter
git fetch --refetch
```

After materialization: **~0.1–0.8 s/file**. Cross-ref: [./02-diff-fetching.md](./02-diff-fetching.md).

---

## The SZZ Idea

```
Fix F  ──diff──►  deleted/modified lines at F^1
                       │
                  git blame F^1 -- <file>
                       │
                       ▼
               Introducer commit I
               (last commit to touch those lines before the fix)
               + author / email / timestamp
```

`git diff F^1 F` is used uniformly — this handles both single-parent commits
and GitLab security merge commits (first parent = `master-before-fix`, diff =
the security change). Same approach as Phase 3 (see [./03-tiered-labeling.md](./03-tiered-labeling.md)).

---

## Tier A — Core Blame

1. Diff `F^1..F` over code globs.
2. Collect all **deleted** old-side lines (the lines the fix removed or
   replaced — these are where the bug lived).
3. `git blame --porcelain F^1 -- <file>` those line numbers → introducer SHA,
   author, email, `author-time`.
4. Skip self-edges (`intro_sha == fix_sha`).

**Code globs**

| Harness | Globs |
|---------|-------|
| `szz.py` | `*.rb *.rake *.erb` |
| `szz_parquet.py` | `*.rb *.rake *.erb *.js *.mjs *.ts *.jsx *.tsx *.vue *.coffee *.haml *.slim *.go *.graphql *.scss *.less` |

`szz_parquet.py` keys globs off the diff content, not the `language` column,
so it correctly attributes non-Ruby fixes in the corpus.

---

## Tier B — Denoise (three parts)

### B1 — Drop blank and comment-only deleted lines

Cosmetic deletions carry no logic; blaming them attributes whitespace commits,
not vulnerability authors. Drop before blaming.

| Pattern matched (drop) | Languages |
|------------------------|-----------|
| `^\s*$` (blank) | all |
| `^\s*#` | Ruby, Python, YAML, Haml |
| `^\s*//` or `^\s*/\*` or `^\s*\*` | JS, TS, Go, Java |
| `^\s*--` | SQL, Lua |

`szz.py` uses `RUBY_COMMENT = re.compile(r"^\s*#")`.
`szz_parquet.py` uses the broader `COMMENT = re.compile(r"^\s*(#|//|/\*|\*|--)")`.

### B2 — Cosmetic introducer flag

After blaming, fetch each introducer commit's subject
(`git show -s --format=%H%x01%s`, batched 200 at a time). Flag commits whose
subject matches:

```
refactor|rubocop|lint|style|format|reformat|rename|move|typo|whitespace|
cleanup|tidy|bump|upgrade|dependency|prettier|eslint|merge branch|merge remote
```

Flagged edges (`introducer_cosmetic=true`) are **excluded** from denoised
counts and from skill-gap lift math. They remain in the raw edge list so the
full data is preserved.

### B3 — Addition-only recovery

A fix that only **adds** lines (e.g., inserting a missing authorization check)
has no deleted lines to blame — Tier A finds nothing. Recovery:

- Parse the hunk event stream for context lines (`" "` prefix) that are
  **immediately adjacent** (±1 position) to an insertion run.
- Blame those context lines at `F^1`.
- Emit as `line_kind=vicinity`, `confidence=low`.

These edges are kept separate and **not** counted in denoised skill-gap
calculations.

---

## Tier C — Exposure Normalization (skill-gap signal)

Raw introduction counts are biased toward prolific committers. Normalize by
**total authored commits** as an exposure proxy.

```python
# exposure: email -> total commits across all refs
git shortlog -sne --all HEAD

intro_per_1k_commits = 1000 * denoised_introductions / total_commits

# category lift = author's share of a category / global share of that category
author_share  = author_categories[cat] / sum(author_categories)
global_share  = global_cat[cat] / total_denoised_edges
lift[cat]     = author_share / global_share
```

**lift > 1.0** means the author introduces bugs in that category at above-
baseline frequency. Example: `lift=3.0` for `auth-session` → introduces auth
bugs at 3× the global rate, controlling for total commit volume.

`szz.py` computes this for gold fixes only and writes it to `szz-introducers.json`.
`szz_parquet.py` does not compute Tier C (no aggregate needed for per-row columns).

---

## Outputs

### `szz.py` — gold fixes only

**`oracle/szz-attribution.jsonl`** — one JSONL row per fix→introducer edge:

| Field | Type | Notes |
|-------|------|-------|
| `fix_sha` | str | |
| `category` | str | from corpus label |
| `cwe` | list[int] | |
| `fix_date` | str | |
| `intro_sha` | str | introducer commit |
| `intro_author` | str | **PII** |
| `intro_email` | str | **PII** |
| `intro_time` | int | unix timestamp |
| `blamed_lines` | int | lines attributed to this intro |
| `line_kind` | str | `code` or `vicinity` |
| `confidence` | str | `high` or `low` |
| `introducer_subject` | str | commit subject |
| `introducer_cosmetic` | bool | cosmetic flag |

**`oracle/szz-introducers.json`** — Tier C per-author aggregate:

| Field | Notes |
|-------|-------|
| `introductions_denoised` | code-only, non-cosmetic |
| `intro_per_1k_commits` | exposure-normalized rate |
| `skill_gap_lift` | `[(category, lift_ratio, count), ...]` top 4 |
| `top_categories` | most_common(6) |
| `top_cwes` | most_common(6) |
| `dominant_category` | single top category |
| `vicinity_only` | addition-only recovery edges |

Also written: aggregate metadata — `fix_status_breakdown`, `code_edges`,
`vicinity_edges`, `cosmetic_introducer_edges`, `distinct_introducers`,
`global_category_distribution`, `top_introducers_denoised` (top 40).

---

### `szz_parquet.py` — all diffed parquet rows

Reads `oracle/security-commits-cvss.parquet`, runs SZZ Tier A+B over every row
where `diff_status in ("ok", "ok-nonruby")` (13,643 rows), and **appends
columns in place**. Idempotent: drops any pre-existing `szz_*` columns before
appending, so re-runs are safe.

**New parquet columns:**

| Column | Type | Notes |
|--------|------|-------|
| `szz_introducers` | VARCHAR | JSON edge list (see schema above, minus `fix_sha`) |
| `szz_primary_introducer` | VARCHAR | author of dominant edge (non-cosmetic high-conf, most blamed lines) |
| `szz_primary_email` | VARCHAR | email of dominant introducer — **PII** |
| `szz_primary_intro_sha` | VARCHAR | SHA of dominant introducing commit |
| `szz_n_introducers` | INT | distinct introducing commits |
| `szz_confidence` | VARCHAR | `high` (≥1 code edge) \| `low` (vicinity only) \| null |
| `szz_status` | VARCHAR | `ok` \| `no-introducer` \| `addition-only-vicinity` \| `addition-only` \| `diff-fail` \| null |

Also writes a **PII sidecar** `oracle/szz-parquet-attribution.jsonl` (git-ignored).

**Primary edge selection** (dominant introducer):

```python
primary = sorted(edges, key=lambda e: (
    e["confidence"] == "high" and not e["introducer_cosmetic"],
    e["blamed_lines"]
), reverse=True)[0]
```

Non-cosmetic high-confidence edges win; ties broken by blamed line count.

---

## Canonical Numbers (GitLab gold run)

| Metric | Value |
|--------|-------|
| Gold fixes processed | 1,018 |
| Code-attributed fixes | 758 |
| Recovered via vicinity | 114 |
| Still unattributable | 143 |
| Code edges (high-conf) | 3,442 |
| Vicinity edges (low-conf) | 375 |
| Cosmetic introducer edges flagged | 524 |
| Distinct introducers | 491 |
| Top global category | auth-session (1,212 edges) |
| Parquet rows covered | 13,643 |

---

## PII Handling

> **WARNING — real author data**

Introducer names and emails are real developer PII from `git blame` output.

| Artifact | Contains PII | Treatment |
|----------|-------------|-----------|
| `oracle/szz-attribution.jsonl` | yes | git-ignored, local only |
| `oracle/szz-introducers.json` | yes | git-ignored, local only |
| `oracle/szz-parquet-attribution.jsonl` | yes | git-ignored, local only |
| `oracle/security-commits-cvss.parquet` (with szz_* cols) | yes | git-ignored, local only |

If you need to publish parquet with SZZ columns: either **git-ignore the
enriched parquet** (current approach) or **redact** — store `intro_sha` and a
hashed email (`sha256(email)[:16]`) instead of raw strings.

**Frame results as a team/area training-need signal, not an individual blame
leaderboard.**

---

## Honest Limits

- **Tiny denominator noise**: lift on 1–2 introductions is statistically
  meaningless. Trust only authors with multiple denoised edges.
- **Vicinity edges are weak by construction**: filter `confidence=low` for
  any clean quantitative analysis; treat as a rough signal only.
- **Exposure is a proxy**: `git shortlog` counts total commits, not
  lines-authored in the security-relevant area. A high-volume author in a
  non-security subsystem may appear under-exposed.
- **Blame attributes the last toucher**: the commit that last modified a line
  may be a trivial reformatter, not the logic author, despite B1/B2 filtering.
  Cosmetic flagging reduces but does not eliminate this.
- **Rebases and vendored code**: a rebase rewrites SHAs; vendored code
  produces spurious introducer attribution. `.mailmap` is respected but cannot
  fix these.
- **Category label is from the raw corpus**: join on `fix_sha` against the
  normalized label table (Phase 3) for the canonical category before computing
  lift.
- **Merges**: `git diff F^1 F` uses the first parent; this matches GitLab's
  security merge pattern but may miss changes introduced via second-parent
  merge commits in unusual topologies.

---

## Next Phase

[./07-orchestration-harness.md](./07-orchestration-harness.md) — end-to-end
pipeline orchestration that runs Phases 1–7 in sequence.
