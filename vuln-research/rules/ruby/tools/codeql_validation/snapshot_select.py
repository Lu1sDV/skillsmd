#!/usr/bin/env python3
"""Stage 1 — snapshot/manifest selection for the CodeQL validation harness.

Reads the (PII, git-ignored) cvss parquet, applies the locked eligibility + scope
filter, and for every in-scope fix extracts the changed Ruby files and per-hunk
line ranges directly from the parquet `diff` column (which is `git diff <sha>^1
<sha>`). No git access needed for the manifest.

Emits oracle/validation/snapshots.jsonl, one row per fix:
  sha, parent_ref ("<sha>^1"), category, secondary_categories[], cvss_score,
  cvss_severity, quality_tier, language, diff_status,
  expected_detectable (bool: has >=1 ruby-extractable changed file),
  fix_shape (deletion|modification|addition-only|unknown),
  changed_files[] (ruby only),
  changed_line_ranges[] {file, parent_del_start, parent_del_len, fix_add_start, fix_add_len},
  priority_score (joined from szz-class-priority.csv by category)

PII: reads columns only; never copies szz_* author columns into the manifest.
"""
import argparse, csv, json, os, re, sys

SCOPE = ["auth-session", "xss", "rails-misc", "ssti"]
# CodeQL Ruby extractor sees these. (.erb/.haml are template; ruby extractor
# handles .erb; .haml is NOT ruby-extractable -> excluded.)
RUBY_EXT = (".rb", ".rake", ".erb", ".gemspec", ".ru")
RUBY_BASENAMES = {"Rakefile", "Gemfile", "Guardfile", "config.ru"}
HUNK = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")

def is_ruby(path):
    base = path.rsplit("/", 1)[-1]
    return path.endswith(RUBY_EXT) or base in RUBY_BASENAMES

def parse_diff(diff):
    """Return {file: [(pdel_start,pdel_len,fadd_start,fadd_len), ...]} for ruby files."""
    out = {}
    cur = None
    if not diff:
        return out
    for line in diff.splitlines():
        if line.startswith("+++ "):
            p = line[4:].strip()
            if p.startswith("b/"):
                p = p[2:]
            cur = p if (p != "/dev/null" and is_ruby(p)) else None
        elif line.startswith("@@") and cur:
            m = HUNK.match(line)
            if m:
                ps, pl, fs, fl = m.groups()
                out.setdefault(cur, []).append((
                    int(ps), int(pl) if pl is not None else 1,
                    int(fs), int(fl) if fl is not None else 1,
                ))
    return out

def fix_shape(ranges):
    if not ranges:
        return "unknown"
    any_del = any(r[1] > 0 for r in ranges)
    any_add = any(r[3] > 0 for r in ranges)
    if any_del and any_add:
        return "modification"
    if any_add and not any_del:
        return "addition-only"
    if any_del and not any_add:
        return "deletion"
    return "unknown"

def load_priority(path):
    pri = {}
    if os.path.exists(path):
        with open(path) as f:
            for row in csv.DictReader(f):
                try:
                    pri[row["category"]] = float(row["priority_score"])
                except (KeyError, ValueError):
                    pass
    return pri

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--parquet", default="oracle/security-commits-cvss.parquet")
    ap.add_argument("--priority", default="oracle/analysis/szz-class-priority.csv")
    ap.add_argument("--out", default="oracle/validation/snapshots.jsonl")
    ap.add_argument("--categories", default=",".join(SCOPE))
    args = ap.parse_args()

    import pyarrow.parquet as pq
    cats = [c.strip() for c in args.categories.split(",") if c.strip()]
    pri = load_priority(args.priority)

    need = ["sha", "category", "cwe", "cvss_score", "cvss_severity",
            "quality_tier", "language", "diff_status", "is_security_fix_regate", "diff"]
    t = pq.read_table(args.parquet)
    have = [c for c in need if c in t.column_names]
    d = t.select(have).to_pydict()
    n = t.num_rows

    def col(name, i, default=None):
        return d[name][i] if name in d else default

    rows, stats = [], {"total": 0, "detectable": 0, "by_cat": {}, "by_shape": {}}
    for i in range(n):
        if col("is_security_fix_regate", i) is not True:
            continue
        if (col("cvss_score", i) or 0) <= 0:
            continue
        if col("diff_status", i) not in ("ok", "ok-nonruby"):
            continue
        category = col("category", i)
        if category not in cats:
            continue

        diff = col("diff", i) or ""
        per_file = parse_diff(diff)
        ranges = []
        for f, hs in per_file.items():
            for (ps, pl, fs, fl) in hs:
                ranges.append({"file": f, "parent_del_start": ps, "parent_del_len": pl,
                               "fix_add_start": fs, "fix_add_len": fl})
        changed_files = sorted(per_file.keys())
        detectable = len(changed_files) > 0
        cwe = col("cwe", i) or []
        if not isinstance(cwe, list):
            cwe = [cwe]
        shape = fix_shape([(r["parent_del_start"], r["parent_del_len"],
                            r["fix_add_start"], r["fix_add_len"]) for r in ranges])

        rows.append({
            "sha": col("sha", i),
            "parent_ref": (col("sha", i) or "") + "^1",
            "category": category,
            "secondary_categories": [str(c) for c in cwe],
            "cvss_score": col("cvss_score", i),
            "cvss_severity": col("cvss_severity", i),
            "quality_tier": col("quality_tier", i),
            "language": col("language", i),
            "diff_status": col("diff_status", i),
            "expected_detectable": detectable,
            "fix_shape": shape,
            "changed_files": changed_files,
            "changed_line_ranges": ranges,
            "priority_score": pri.get(category),
        })
        stats["total"] += 1
        stats["detectable"] += int(detectable)
        stats["by_cat"][category] = stats["by_cat"].get(category, 0) + 1
        stats["by_shape"][shape] = stats["by_shape"].get(shape, 0) + 1

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w") as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")
    print(json.dumps({"out": args.out, **stats}, indent=2))

if __name__ == "__main__":
    main()
