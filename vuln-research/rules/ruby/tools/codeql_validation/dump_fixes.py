#!/usr/bin/env python3
"""Extract per-fix authoring packets (sha, message, cwe, cvss, ruby diff) from the
parquet for a category, to feed the query-authoring lane. Read-only; no PII columns.

Usage: dump_fixes.py --category ssti [--limit N] [--gold-only] --out <dir|->
Writes one JSON object per fix (to <dir>/<sha>.json, or jsonl to stdout if out=-).
"""
import argparse, json, os, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--parquet", default="oracle/security-commits-cvss.parquet")
    ap.add_argument("--category", required=True)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--gold-only", action="store_true")
    ap.add_argument("--weak-only", action="store_true")
    ap.add_argument("--out", default="-")
    args = ap.parse_args()
    import pyarrow.parquet as pq
    cols = ["sha", "category", "cwe", "cvss_score", "cvss_severity", "quality_tier",
            "language", "diff_status", "is_security_fix_regate", "diff", "subject", "message"]
    t = pq.read_table(args.parquet)
    have = [c for c in cols if c in t.column_names]
    d = t.select(have).to_pydict()
    def col(name, i, default=None):
        return d[name][i] if name in d else default
    out_items = []
    for i in range(t.num_rows):
        if col("is_security_fix_regate", i) is not True: continue
        if (col("cvss_score", i) or 0) <= 0: continue
        if col("diff_status", i) not in ("ok", "ok-nonruby"): continue
        if col("category", i) != args.category: continue
        if args.gold_only and col("quality_tier", i) != "gold": continue
        if args.weak_only and col("quality_tier", i) != "weak": continue
        cwe = col("cwe", i) or []
        if not isinstance(cwe, list): cwe = [cwe]
        out_items.append({
            "sha": col("sha", i), "category": col("category", i),
            "cwe": [str(c) for c in cwe], "cvss_score": col("cvss_score", i),
            "cvss_severity": col("cvss_severity", i), "quality_tier": col("quality_tier", i),
            "language": col("language", i), "diff_status": col("diff_status", i),
            "subject": col("subject", i), "message": col("message", i),
            "diff": col("diff", i) or "",
        })
    if args.limit: out_items = out_items[:args.limit]
    if args.out == "-":
        for it in out_items: print(json.dumps(it))
    else:
        os.makedirs(args.out, exist_ok=True)
        for it in out_items:
            with open(os.path.join(args.out, f"{it['sha']}.json"), "w") as f:
                json.dump(it, f, indent=2)
    print(f"# wrote {len(out_items)} {args.category} fixes", file=sys.stderr)

if __name__ == "__main__":
    main()
