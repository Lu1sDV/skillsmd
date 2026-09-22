#!/usr/bin/env python3
"""Fetch the fix patch (.rb/.rake/.erb hunks) for every SHA in the parquet.

Pure git I/O, no model. Uniform command `git diff <sha>^1 <sha>` correctly
handles BOTH single-parent commits AND GitLab security merges (where a plain
`git show` returns the empty combined-diff).

REALITY of the blob:none partial clone: GOLD commits were diff-analyzed before
so their blobs are cached (fast); WEAK/message commits are mostly uncached, and
an on-demand blob fetch from gitlab.com can take minutes or hang. So:
  - gold  -> long timeout, we want all of them
  - weak  -> short timeout, parallel, SKIP-ON-TIMEOUT (best effort)
Every row records diff_status in {ok, empty, timeout, error} so a null diff is
explained, never silent. Resumable: skips SHAs already in the output JSONL.

Output -> oracle/commit-diffs.jsonl
  {sha, tier, diff, diff_chars, truncated, diff_status}
"""
import json, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor, as_completed

REPO = os.path.expanduser("~/Personal_Projects/find-ctfs/gitlab")
ORACLE = os.path.normpath(os.path.dirname(os.path.abspath(__file__)) + "/../oracle")
OUT = f"{ORACLE}/commit-diffs.jsonl"
GLOBS = ["*.rb", "*.rake", "*.erb"]
CAP = 24000
GOLD_TIMEOUT = 90
WEAK_TIMEOUT = 12
WORKERS = 12

def load_targets():
    gold = {r["sha"] for r in json.load(open(f"{ORACLE}/security-fix-corpus.json"))["commits"]}
    weak = set()
    with open(f"{ORACLE}/message-security-commits.jsonl") as fh:
        for line in fh:
            line = line.strip()
            if line:
                try: weak.add(json.loads(line)["sha"])
                except Exception: pass
    weak -= gold
    return gold, weak

def fetch(sha, tier, timeout):
    try:
        p = subprocess.run(["git", "-C", REPO, "diff", f"{sha}^1", sha, "--"] + GLOBS,
                           capture_output=True, text=True, timeout=timeout, errors="replace")
        d = p.stdout or ""
        trunc = len(d) > CAP
        if trunc: d = d[:CAP]
        status = "ok" if d.strip() else "empty"
        return {"sha": sha, "tier": tier, "diff": d or None,
                "diff_chars": len(d), "truncated": trunc, "diff_status": status}
    except subprocess.TimeoutExpired:
        return {"sha": sha, "tier": tier, "diff": None, "diff_chars": 0,
                "truncated": False, "diff_status": "timeout"}
    except Exception as e:
        return {"sha": sha, "tier": tier, "diff": None, "diff_chars": 0,
                "truncated": False, "diff_status": f"error:{type(e).__name__}"}

def main():
    gold, weak = load_targets()
    # "done" = only rows we won't improve by retrying. timeout/error rows are
    # retried (e.g. after blobs are materialized). Keep last status per sha.
    last = {}
    if os.path.exists(OUT):
        with open(OUT) as fh:
            for line in fh:
                try:
                    o = json.loads(line); last[o["sha"]] = o.get("diff_status")
                except Exception: pass
    done = {s for s, st in last.items() if st in ("ok", "empty")}

    # gold first (sequential-ish via pool, long timeout), then weak best-effort
    jobs = [(s, "gold", GOLD_TIMEOUT) for s in sorted(gold - done)] + \
           [(s, "weak", WEAK_TIMEOUT) for s in sorted(weak - done)]
    print(f"gold {len(gold)} weak {len(weak)} | already done {len(done)} | todo {len(jobs)}", flush=True)

    counts = {"ok": 0, "empty": 0, "timeout": 0}
    n = 0
    with open(OUT, "a", buffering=1) as out, ThreadPoolExecutor(max_workers=WORKERS) as ex:
        futs = {ex.submit(fetch, s, t, to): s for (s, t, to) in jobs}
        for f in as_completed(futs):
            r = f.result()
            out.write(json.dumps(r) + "\n")
            k = r["diff_status"] if r["diff_status"] in counts else "error"
            counts[k] = counts.get(k, 0) + 1
            n += 1
            if n % 500 == 0:
                print(f"  {n}/{len(jobs)} | ok={counts.get('ok',0)} "
                      f"empty={counts.get('empty',0)} timeout={counts.get('timeout',0)}", flush=True)
    print(f"DONE: {n} fetched | {counts}", flush=True)

if __name__ == "__main__":
    main()
