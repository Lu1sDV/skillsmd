#!/usr/bin/env python3
"""Prep pass for non-Ruby security-fix analysis (pure git I/O, no model).

From the parquet's security-regate rows whose Ruby diff is empty, keep the ones that
touch a CODE language (the real client/server vuln surface) and fetch their diff
restricted to those code files. Output feeds the Sonnet analysis workflow.

KEEP a commit if it changes >=1 file with a code extension; DROP docs/translations/
images/lockfiles/CI-yaml noise. Diff is restricted to code files and capped.

Outputs:
  oracle/nonruby-analysis-input.json   [{sha, subject, langs, files, diff}]  (Sonnet input)
  appends code diffs to oracle/commit-diffs.jsonl (diff_status='ok-nonruby') to populate parquet
"""
import json, os, subprocess, collections
from concurrent.futures import ThreadPoolExecutor, as_completed

REPO = os.path.expanduser("~/Personal_Projects/find-ctfs/gitlab")
ORACLE = os.path.normpath(os.path.dirname(os.path.abspath(__file__)) + "/../oracle")
PARQUET = f"{ORACLE}/security-commits.parquet"
OUT_INPUT = f"{ORACLE}/nonruby-analysis-input.json"
DIFFS = f"{ORACLE}/commit-diffs.jsonl"
CAP = 18000
WORKERS = 14

CODE_EXT = {".js", ".mjs", ".ts", ".jsx", ".tsx", ".vue", ".coffee",
            ".haml", ".slim", ".go", ".graphql", ".scss", ".less"}
CODE_GLOBS = ["*.js", "*.mjs", "*.ts", "*.jsx", "*.tsx", "*.vue", "*.coffee",
              "*.haml", "*.slim", "*.go", "*.graphql", "*.scss", "*.less"]

def candidates():
    import duckdb
    rows = duckdb.sql(f"""SELECT sha, subject FROM '{PARQUET}'
        WHERE diff_status IN ('empty','timeout') AND is_security_fix_regate""").fetchall()
    return [(r[0], r[1]) for r in rows]

def probe(sha, subject):
    try:
        nm = subprocess.run(["git", "-C", REPO, "diff", "--name-only", f"{sha}^1", sha],
                            capture_output=True, text=True, timeout=40).stdout.split()
    except Exception:
        return None
    code = [f for f in nm if os.path.splitext(f)[1].lower() in CODE_EXT]
    if not code:
        return None  # not a code-language fix -> drop
    langs = sorted({os.path.splitext(f)[1].lower().lstrip(".") for f in code})
    try:
        diff = subprocess.run(["git", "-C", REPO, "diff", f"{sha}^1", sha, "--"] + CODE_GLOBS,
                             capture_output=True, text=True, timeout=60, errors="replace").stdout or ""
    except Exception:
        diff = ""
    return {"sha": sha, "subject": subject, "langs": langs,
            "files": code[:25], "diff": diff[:CAP], "truncated": len(diff) > CAP}

def main():
    cand = candidates()
    print(f"candidate security non-ruby commits: {len(cand)}", flush=True)
    kept = []
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        futs = [ex.submit(probe, s, sub) for s, sub in cand]
        for i, f in enumerate(as_completed(futs), 1):
            r = f.result()
            if r:
                kept.append(r)
            if i % 1000 == 0:
                print(f"  probed {i}/{len(cand)} | kept {len(kept)}", flush=True)
    lang_hist = collections.Counter(l for r in kept for l in r["langs"])
    print(f"KEPT (code-language fixes): {len(kept)}")
    print(f"language histogram: {dict(lang_hist.most_common())}")

    json.dump(kept, open(OUT_INPUT, "w"))
    # populate parquet diff column for these rows
    with open(DIFFS, "a") as out:
        for r in kept:
            out.write(json.dumps({"sha": r["sha"], "tier": "weak",
                "diff": r["diff"] or None, "diff_chars": len(r["diff"]),
                "truncated": r["truncated"], "diff_status": "ok-nonruby"}) + "\n")
    print(f"wrote {OUT_INPUT} ({len(kept)} rows) + appended code diffs to commit-diffs.jsonl")

if __name__ == "__main__":
    main()
