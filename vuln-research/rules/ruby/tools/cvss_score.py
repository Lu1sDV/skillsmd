#!/usr/bin/env python3
"""CVSS v3.1 + vulnerability-class scoring orchestrator.

Subcommands
  --prep   : filter is_security_fix_regate=true AND language != 'ruby' AND
             diff_status not in (empty, timeout), sort, slice into batches of 30,
             write analysis/cvss-input.json (full) + analysis/cvss-batch-XXX.json
             (per-batch slices).

  --list   : print all batch indices and their slice paths (so the orchestrator
             can dispatch them to parallel fixer subagents in waves of 16).

  --print  BATCH_IDX  : print the per-batch prompt markdown for a single batch
             (handy for the orchestrator or for direct `task` subagent calls).

Resume: per-batch output files (analysis/cvss-XXX.jsonl) are append-mode and
deduped by sha inside the prompt logic. The aggregate step is idempotent.
"""
import argparse, glob, json, os, re, sys, textwrap
from pathlib import Path

ORACLE  = Path(__file__).resolve().parent.parent / "oracle"
ANALYSIS = ORACLE / "analysis"
PARQUET = ORACLE / "security-commits.parquet"
PROMPT_TPL = Path(__file__).resolve().parent / "cvss_prompt.md"

BATCH_SIZE = 30
DIFF_CAP = 6000
BODY_CAP = 1500


def cap(s, n):
    if not s:
        return ""
    s = str(s)
    return s if len(s) <= n else s[:n] + f"\n... [truncated at {n} chars; original {len(s)}]"


def sort_key(r):
    """gold before weak-with-diff before weak-no-diff; then by sha for stability."""
    tier = r["quality_tier"]
    has_diff = bool(r.get("diff")) and r.get("diff_status") in ("ok", "ok-nonruby")
    bucket = {"gold": 0, "weak": 1 if has_diff else 2}.get(tier, 3)
    return (bucket, r["sha"])


def load_filtered():
    import pyarrow.parquet as pq
    t = pq.read_table(PARQUET).to_pandas()
    t = t[t["is_security_fix_regate"] == True].copy()  # noqa: E712
    t = t[t["language"] != "ruby"].copy()               # non-ruby only
    t = t[~t["diff_status"].isin(["empty", "timeout"])].copy()  # must have a diff
    t["__sort"] = t.apply(sort_key, axis=1)
    t = t.sort_values("__sort", kind="stable").drop(columns="__sort").reset_index(drop=True)
    return t


def to_input_row(r):
    return {
        "sha": r["sha"],
        "subject": r.get("subject") or "",
        "body": cap(r.get("body"), BODY_CAP),
        "diff": cap(r.get("diff"), DIFF_CAP),
        "diff_status": r.get("diff_status") or ("ok" if r.get("diff") else "empty"),
        "category_hint": r.get("category") or "",
    }


def prep():
    import pyarrow.parquet as pq
    ANALYSIS.mkdir(parents=True, exist_ok=True)
    df = load_filtered()
    rows = [to_input_row(r) for _, r in df.iterrows()]
    full_path = ANALYSIS / "cvss-input.json"
    full_path.write_text(json.dumps(rows, ensure_ascii=False))
    print(f"wrote {full_path}  ({len(rows)} rows)")

    n_batches = (len(rows) + BATCH_SIZE - 1) // BATCH_SIZE
    for i in range(n_batches):
        slc = rows[i * BATCH_SIZE : (i + 1) * BATCH_SIZE]
        slc_path = ANALYSIS / f"cvss-batch-{i:03d}.json"
        slc_path.write_text(json.dumps(slc, ensure_ascii=False))
    print(f"wrote {n_batches} batch slices in {ANALYSIS}/cvss-batch-XXX.json")

    # Tier breakdown for sanity
    import collections
    by_tier = collections.Counter(
        ("gold" if r["quality_tier"] == "gold"
         else "weak_ok" if r.get("diff_status") == "ok"
         else "weak_no_diff")
        for _, r in df.iterrows()
    )
    print(f"tier mix: {dict(by_tier)}")
    print(f"batches of {BATCH_SIZE} = {n_batches}; 16-parallel -> {((n_batches + 15) // 16)} waves")


def list_batches():
    paths = sorted(ANALYSIS.glob("cvss-batch-*.json"))
    for p in paths:
        idx = int(p.stem.split("-")[-1])
        arr = json.loads(p.read_text())
        first_sha = arr[0]["sha"] if arr else ""
        last_sha = arr[-1]["sha"] if arr else ""
        print(f"batch={idx:03d}  n={len(arr):3d}  sha[0]={first_sha[:10]}  sha[-1]={last_sha[:10]}  out=analysis/cvss-{idx:03d}.jsonl")


def print_batch(batch_idx):
    slc = ANALYSIS / f"cvss-batch-{batch_idx:03d}.json"
    if not slc.exists():
        sys.exit(f"missing {slc} — run --prep first")
    tpl = PROMPT_TPL.read_text()
    out = tpl.replace("{BATCH_IDX}", str(batch_idx)) \
             .replace("{BATCH_SIZE}", str(BATCH_SIZE)) \
             .replace("{BATCH_INPUT}", slc.read_text()) \
             .replace("{OUT_FILE}", str(ANALYSIS / f"cvss-{batch_idx:03d}.jsonl"))
    print(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--prep", action="store_true", help="filter+sort+slice into batches")
    ap.add_argument("--list", action="store_true", help="print batch manifest")
    ap.add_argument("--print", dest="print_idx", type=int, default=None, metavar="BATCH_IDX",
                    help="print filled-in prompt for a single batch (uses cvss_prompt.md template)")
    args = ap.parse_args()
    if args.prep:
        prep()
    elif args.list:
        list_batches()
    elif args.print_idx is not None:
        print_batch(args.print_idx)
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
