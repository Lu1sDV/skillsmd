# 02 — Diff Fetching (Phase 3)

Fetch the fix patch for every SHA in the corpus. Pure git I/O.
Harness: [`../harness/fetch_diffs.py`](../harness/fetch_diffs.py)
Output: `oracle/commit-diffs.jsonl`

---

## The Uniform Diff Command

```bash
git -C <repo> diff <sha>^1 <sha> -- '*.rb' '*.rake' '*.erb'
```

This single command handles **both** single-parent commits and merge commits.

**Why not `git show`?** ~39% of security fixes in large projects land as merge commits. `git show <merge-sha>` returns the **empty combined-diff** — GitLab's security merges fast-forward a branch into the default, so `show` sees no delta. `git diff <sha>^1 <sha>` produces the first-parent diff: *what the merge introduced vs. the branch it landed on* = the fix. This is the single most important gotcha in the entire pipeline.

| Command | Single-parent commit | Merge commit |
|---------|----------------------|--------------|
| `git show <sha>` | correct diff | **empty** (combined-diff) |
| `git diff <sha>^1 <sha>` | correct diff | correct diff (first-parent) |

Always use `git diff <sha>^1 <sha>`.

---

## Blobless Partial Clone Reality

```bash
git clone --filter=blob:none <url> <dir>
```

Trees are fetched immediately; blobs are lazy-fetched on demand.

| Operation | Blobs needed | Blobless clone behavior |
|-----------|--------------|-------------------------|
| `git diff <sha>^1 <sha>` | 2 blobs (old + new of changed files only) | **Fast** — even uncached, on-demand fetch is cheap |
| `git blame <file>` | Full file history — hundreds of blobs per file | **Breaks** — >90 s/file or hangs entirely |

### Materializing blobs for SZZ blame

Diff-fetch works fine on a blobless clone. SZZ blame (`git blame`) does **not** — it reconstructs full file history and triggers hundreds of individual blob fetches.

Fix: convert the clone from `blob:none` to full once, before running blame:

```bash
git config --unset remote.origin.partialclonefilter
git fetch --refetch
```

Disk impact example: 1.5 GB → 4.3 GB. After materialization, blame drops to ~0.1–0.8 s/file.

**Cross-link**: see [./06-szz-attribution.md](./06-szz-attribution.md) — materialize blobs **before** running the SZZ phase, not during.

---

## `curl 28: Operation too slow` Abort

During `git fetch --refetch`, a large server-side repack (e.g. compressing 769,809 objects) can stall the transfer below git's default low-speed floor, aborting with:

```
error: RPC failed; curl 28 Operation timed out after ... ms with ... bytes received
```

Survive it with:

```bash
git -c http.lowSpeedLimit=0 \
    -c http.postBuffer=524288000 \
    -c http.version=HTTP/1.1 \
    -c core.compression=0 \
    fetch --refetch
```

- `http.lowSpeedLimit=0` — disables the low-speed abort entirely
- `http.postBuffer=524288000` — 500 MB POST buffer, avoids chunked-upload fragmentation
- `http.version=HTTP/1.1` — forces HTTP/1.1; HTTP/2 multiplexing can amplify stall symptoms
- `core.compression=0` — skips local recompression during fetch, reducing CPU contention

---

## Per-Tier Timeouts and Best-Effort Policy

```python
GOLD_TIMEOUT = 90   # seconds
WEAK_TIMEOUT = 12   # seconds
WORKERS     = 12    # ThreadPoolExecutor
```

| Tier | Blob state | Timeout | On timeout |
|------|-----------|---------|-----------|
| `gold` | Already diff-analyzed → blobs cached | 90 s | **Skip** (log timeout, retry later) |
| `weak` / `message` | Mostly uncached; on-demand fetch can take minutes or hang | 12 s | **Skip-on-timeout** (best effort) |

Gold commits get a long window because we want all of them and their blobs are warm. Weak/message commits are treated as best-effort: a 12 s cap prevents the pool from stalling on slow remote fetches. Both tiers record `diff_status` — no silent nulls.

---

## `diff_status` Taxonomy

Every output row carries `diff_status`. A null diff is always explained.

| Status | Meaning |
|--------|---------|
| `ok` | Real patch — diff is non-empty after glob filtering |
| `empty` | Fix touched none of the target globs (e.g. frontend-only commit, or merge-of-merges with no code change) |
| `timeout` | `subprocess.TimeoutExpired` — blob fetch stalled past tier limit |
| `error:<Type>` | Any other exception, e.g. `error:CalledProcessError` |

Diff text is capped at **24,000 chars**; rows over the cap have `truncated: true`.

### GitLab build numbers

| Outcome | Count |
|---------|-------|
| Ruby patches fetched (`ok`) | 10,929 |
| Non-Ruby code patches (separate phase) | 3,217 |
| Fixes touching no target file (`empty`) | 4,416 |
| Timeouts | 1 |

---

## Data Integrity: Fabricated SHAs

During the GitLab build, **12 "gold" SHAs in the source corpus were LLM-fabricated**: a real 12-character prefix followed by sequential hex filler. These resolve to nothing (or the wrong commit), producing blank diffs that look identical to legitimate `empty` results.

**Diagnosis signal**: a gold SHA returning an empty diff when the commit message clearly references a security fix. Resolution: look up the real full SHA via the 12-char prefix in the GitLab API or `git log --oneline` and update the corpus entry.

Never assume a blank diff from a gold SHA means "the fix touched no target file" — verify the SHA is real first.

---

## Resumability

The output file is append-mode JSONL. On restart, the harness reads all existing rows and computes:

```python
done = {sha for sha, status in last.items() if status in ("ok", "empty")}
```

- `ok` and `empty` rows are **final** — won't improve on retry, skipped.
- `timeout` and `error:*` rows are **retried** on the next run (e.g. after blobs are materialized).

This means running the harness a second time after `git fetch --refetch` automatically picks up all previously timed-out SHAs without touching the already-fetched results.

---

## How to Run

```bash
# Edit REPO and ORACLE constants at the top of the script first.
python3 harness/fetch_diffs.py
```

Output file: `oracle/commit-diffs.jsonl`

### Output schema

| Field | Type | Notes |
|-------|------|-------|
| `sha` | string | Commit SHA |
| `tier` | `"gold"` \| `"weak"` | Source corpus tier |
| `diff` | string \| null | Unified diff text (null if no patch) |
| `diff_chars` | int | Character count after cap |
| `truncated` | bool | True if diff exceeded 24,000-char cap |
| `diff_status` | string | `ok`, `empty`, `timeout`, `error:<Type>` |

---

## Related Docs

- [./01-mining-triage.md](./01-mining-triage.md) — corpus construction and SHA sourcing
- [./03-tiered-labeling.md](./03-tiered-labeling.md) — labeling the fetched diffs
- [./06-szz-attribution.md](./06-szz-attribution.md) — SZZ blame (requires materialized blobs)
- [./07-orchestration-harness.md](./07-orchestration-harness.md) — end-to-end pipeline wiring
