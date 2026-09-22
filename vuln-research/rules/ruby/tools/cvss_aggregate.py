#!/usr/bin/env python3
"""Aggregate per-batch cvss-*.jsonl into parquet columns.

Steps (default mode)
  1. glob oracle/analysis/cvss-*.jsonl, parse JSONL
  2. for each row, re-parse cvss_vector and recompute CVSS 3.1 base score;
     compare to agent's claim. Mismatch → override with computed value, log.
     Malformed vector → set all 4 cvss cols to null, log.
  3. derive cvss_severity from the (corrected) score using the official band table
  4. left-join onto:
       a) oracle/security-commits-cvss.parquet  (new file, regate=true rows + 4 cols)
       b) oracle/security-commits.parquet       (in-place: add 4 cols, null where unscored)
  5. print a report

Steps (--only-cvss mode)
  1-3. same as default
  4. read existing security-commits-cvss.parquet (the "base")
  5. in-place update: replace 4 cvss cols for the jsonl shas
  6. read security-commits.parquet, filter to non-ruby regate=false rows, append
  7. write back to security-commits-cvss.parquet (master parquet untouched)
"""
import argparse, collections, glob, json, math, os, re, sys
from pathlib import Path

import pyarrow as pa
import pyarrow.parquet as pq

ORACLE  = Path(__file__).resolve().parent.parent / "oracle"
ANALYSIS = ORACLE / "analysis"
PARQUET = ORACLE / "security-commits.parquet"
NEW_PARQUET = ORACLE / "security-commits-cvss.parquet"

CWE_RE = re.compile(r"^CWE-\d+$")
SEVERITY_BANDS: list = [("None", 0.0, 0.0), ("Low", 0.1, 3.9), ("Medium", 4.0, 6.9),
                          ("High", 7.0, 8.9), ("Critical", 9.0, 10.0)]

# ---- official CVSS 3.1 metric values (https://www.first.org/cvss/v3.1/specification-document) ----
AV = {"N": 0.85, "A": 0.62, "L": 0.55, "P": 0.20}
AC = {"L": 0.77, "H": 0.44}
PR_U = {"N": 0.85, "L": 0.62, "H": 0.27}  # Scope=Unchanged
PR_C = {"N": 0.85, "L": 0.68, "H": 0.50}  # Scope=Changed
UI = {"N": 0.85, "R": 0.62}
CIA = {"H": 0.56, "L": 0.22, "N": 0.0}


def roundup(x):
    """CVSS 3.1 roundup: drop decimal if < .1 of next tenth, else round up to next tenth.
    If result would be 0.0 but the input was > 0, return 0.1.
    """
    if x <= 0.0:
        return 0.0
    int_input = round(x * 100000)  # avoid float weirdness
    if int_input == 0:
        return 0.1
    # floor to 1 decimal
    floored = math.floor(x * 10) / 10
    if floored < x:
        return round(floored + 0.1, 1)
    return round(floored, 1)


def parse_vector(v):
    """Return dict of metrics or raise ValueError.

    Accepts empty string when accompanied by None severity + 0.0 score (non-vuln marker).
    """
    # Non-vulnerability sentinel: empty vector AND severity=None AND score=0.0
    # is the contract for "no security fix here". Let the caller handle this so we
    # don't get spurious malformed flags on empty-diff / non-vuln commits.
    if isinstance(v, str) and v == "":
        return None  # caller must check for None and treat as non-vuln
    if not isinstance(v, str) or not v.startswith("CVSS:3.1/"):
        raise ValueError(f"not a CVSS:3.1 vector: {v!r}")
    out = {}
    for tok in v[len("CVSS:3.1/"):].split("/"):
        if ":" not in tok:
            raise ValueError(f"bad token {tok!r}")
        k, val = tok.split(":", 1)
        if len(val) != 1:
            raise ValueError(f"bad value for {k}: {val!r}")
        out[k] = val
    needed = {"AV", "AC", "PR", "UI", "S", "C", "I", "A"}
    if set(out) != needed:
        raise ValueError(f"vector missing/extra metrics: {sorted(out)}")
    if out["AV"] not in AV: raise ValueError("AV")
    if out["AC"] not in AC: raise ValueError("AC")
    if out["UI"] not in UI: raise ValueError("UI")
    if out["S"]  not in ("U", "C"): raise ValueError("S")
    for m in ("C", "I", "A"):
        if out[m] not in CIA: raise ValueError(m)
    pr = PR_U if out["S"] == "U" else PR_C
    if out["PR"] not in pr: raise ValueError("PR")
    return out


def compute_score(vdict):
    """CVSS 3.1 base score from parsed metric dict."""
    pr_table = PR_U if vdict["S"] == "U" else PR_C
    av = AV[vdict["AV"]]; ac = AC[vdict["AC"]]; pr = pr_table[vdict["PR"]]
    ui = UI[vdict["UI"]]
    c = CIA[vdict["C"]]; i = CIA[vdict["I"]]; a = CIA[vdict["A"]]
    iss = 1.0 - (1.0 - c) * (1.0 - i) * (1.0 - a)
    if vdict["S"] == "U":
        impact = 6.42 * iss
    else:
        impact = 7.52 * (iss - 0.029) - 3.25 * (iss - 0.02) ** 15
        impact = max(impact, 0.0)  # can be slightly negative for very low ISS
    exploit = 8.22 * av * ac * pr * ui
    if impact <= 0:
        return 0.0
    raw = impact + exploit if vdict["S"] == "U" else 1.08 * (impact + exploit)
    return roundup(min(raw, 10.0))


def severity_for(score):
    for name, lo, hi in SEVERITY_BANDS:
        if lo <= score <= hi:
            return name
    return None  # unreachable


def load_jsonl():
    """{sha -> {cvss_*, vuln_class_cwe, mismatch, malformed}}"""
    out = {}
    for path in sorted(ANALYSIS.glob("cvss-*.jsonl")):
        with open(path) as fh:
            for ln in fh:
                ln = ln.strip()
                if not ln:
                    continue
                try:
                    o = json.loads(ln)
                except Exception as e:
                    print(f"WARN: bad jsonl in {path}: {e}", file=sys.stderr)
                    continue
                sha = o.get("sha")
                if not sha:
                    continue
                out[sha] = o
    return out


def validate_and_clean(o):
    """Return (sha, score, vector, severity, cwe_list, flags). flags = list of str issues."""
    sha = o.get("sha")
    flags = []
    vec_raw = o.get("cvss_vector")
    try:
        vd = parse_vector(vec_raw)
    except Exception as e:
        flags.append(f"vector_invalid:{e}")
        cwe = o.get("vuln_class_cwe") or []
        if isinstance(cwe, list):
            cwe = [c for c in cwe if isinstance(c, str) and CWE_RE.match(c)][:3]
        return sha, None, None, None, cwe, flags
    if vd is None:
        # Non-vulnerability sentinel: empty vector, score=0.0, severity="None", no CWE
        cwe = o.get("vuln_class_cwe") or []
        if not isinstance(cwe, list):
            flags.append("cwe_not_list")
            cwe = []
        cwe = [c for c in cwe if isinstance(c, str) and CWE_RE.match(c)][:3]
        claimed = o.get("cvss_score")
        try:
            claimed_f = float(claimed) if claimed is not None else None
        except (TypeError, ValueError):
            flags.append("score_unparseable")
            claimed_f = None
        if claimed_f is not None and abs(claimed_f) > 0.05:
            flags.append(f"score_mismatch:claimed={claimed_f:.1f} computed=0.0")
        sev_claimed = o.get("cvss_severity")
        if sev_claimed and sev_claimed != "None":
            flags.append(f"severity_mismatch:claimed={sev_claimed} band=None")
        return sha, 0.0, "", "None", cwe, flags
    score = compute_score(vd)
    claimed = o.get("cvss_score")
    try:
        claimed = float(claimed)
    except (TypeError, ValueError):
        flags.append("score_unparseable")
        claimed = None
    if claimed is not None and abs(claimed - score) > 0.05:
        flags.append(f"score_mismatch:claimed={claimed:.1f} computed={score:.1f}")
    sev = severity_for(score)
    sev_claimed = o.get("cvss_severity")
    if sev_claimed and sev_claimed != sev:
        flags.append(f"severity_mismatch:claimed={sev_claimed} band={sev}")
    cwe = o.get("vuln_class_cwe") or []
    if not isinstance(cwe, list):
        flags.append("cwe_not_list")
        cwe = []
    cwe = [c for c in cwe if isinstance(c, str) and CWE_RE.match(c)][:3]
    if not cwe:
        flags.append("cwe_empty")
    return sha, score, "CVSS:3.1/" + "/".join(f"{k}:{vd[k]}" for k in ("AV","AC","PR","UI","S","C","I","A")), sev, cwe, flags


def main():
    rows_raw = load_jsonl()
    print(f"loaded {len(rows_raw)} scored rows from {ANALYSIS}/cvss-*.jsonl")
    if not rows_raw:
        sys.exit("no jsonl found; run scoring first")

    # ---- validate & clean ----
    cleaned = {}  # sha -> {score, vector, severity, cwe, flags}
    mismatch = 0; malformed = 0; sev_mismatch = 0
    for sha, o in rows_raw.items():
        _sha, s, v, sev, cwe, flags = validate_and_clean(o)
        cleaned[sha] = dict(score=s, vector=v, severity=sev, cwe=cwe, flags=flags)
        for f in flags:
            if f.startswith("vector_invalid") or f.startswith("score_unparseable"):
                malformed += 1
            elif f.startswith("score_mismatch"):
                mismatch += 1
            elif f.startswith("severity_mismatch"):
                sev_mismatch += 1
    print(f"validation: {mismatch} score-mismatch (overridden) | {sev_mismatch} severity-mismatch (overridden) | {malformed} malformed (nulled)")

    # ---- read original parquet ----
    t = pq.read_table(PARQUET)
    df = t.to_pandas()
    n_total = len(df)
    print(f"original parquet: {n_total} rows, {len(df.columns)} cols")

    # add 4 cols, default to None
    df["cvss_score"]    = None
    df["cvss_vector"]   = None
    df["cvss_severity"] = None
    df["vuln_class_cwe"]= None

    n_scored = 0
    for i, sha in enumerate(df["sha"]):
        c = cleaned.get(sha)
        if not c or c["score"] is None:
            continue
        df.at[i, "cvss_score"]    = float(c["score"])
        df.at[i, "cvss_vector"]   = c["vector"]
        df.at[i, "cvss_severity"] = c["severity"]
        df.at[i, "vuln_class_cwe"]= c["cwe"] or []
        n_scored += 1
    print(f"enriched {n_scored}/{n_total} rows with cvss+vuln_class")

    # ---- write in-place enriched parquet ----
    # idempotent schema: only add the 4 new cols if not already present
    existing = {f.name for f in t.schema}
    new_col_defs = [
        ("cvss_score", pa.float64()),
        ("cvss_vector", pa.string()),
        ("cvss_severity", pa.string()),
        ("vuln_class_cwe", pa.list_(pa.string())),
    ]
    all_fields = [(f.name, f.type) for f in t.schema]
    for name, ty in new_col_defs:
        if name not in existing:
            all_fields.append((name, ty))
    new_schema = pa.schema(all_fields)
    table2 = pa.Table.from_pandas(df, schema=new_schema, preserve_index=False)
    pq.write_table(table2, PARQUET, compression="zstd")
    print(f"wrote (in-place) {PARQUET}  ({os.path.getsize(PARQUET)/1048576:.2f} MB)")

    # ---- write the regate=true-only sliced parquet ----
    sub = df[df["is_security_fix_regate"] == True].reset_index(drop=True)  # noqa: E712
    table3 = pa.Table.from_pandas(sub, schema=new_schema, preserve_index=False)
    pq.write_table(table3, NEW_PARQUET, compression="zstd")
    print(f"wrote {NEW_PARQUET}  ({os.path.getsize(NEW_PARQUET)/1048576:.2f} MB, {len(sub)} rows)")

    # ---- report ----
    print("\n== severity histogram (scored rows) ==")
    sev_hist = collections.Counter(df.loc[df["cvss_score"].notna(), "cvss_severity"].tolist())
    for s, _, _ in SEVERITY_BANDS:
        print(f"  {sev_hist.get(s,0):5d}  {s}")

    print("\n== cvss_score distribution (scored rows) ==")
    scores = df["cvss_score"].dropna().tolist()
    print(f"  n={len(scores)}  min={min(scores):.1f}  p25={sorted(scores)[len(scores)//4]:.1f}  "
          f"median={sorted(scores)[len(scores)//2]:.1f}  p75={sorted(scores)[3*len(scores)//4]:.1f}  max={max(scores):.1f}")

    print("\n== top-15 vuln_class_cwe (first-element) ==")
    fc = collections.Counter()
    for v in df["vuln_class_cwe"].dropna():
        if v:
            fc[v[0]] += 1
    for c, n in fc.most_common(15):
        print(f"  {n:5d}  {c}")


def main_only_cvss():
    """Modify only security-commits-cvss.parquet.

    - In-place update of 4 cvss cols for any sha in the jsonl.
    - Append non-ruby regate=false rows from the master parquet.
    - Master parquet is NOT touched.
    """
    import pandas as pd

    rows_raw = load_jsonl()
    print(f"loaded {len(rows_raw)} scored rows from {ANALYSIS}/cvss-*.jsonl")
    if not rows_raw:
        sys.exit("no jsonl found; run scoring first")

    # ---- validate & clean (same pipeline as default mode) ----
    cleaned = {}
    mismatch = 0; malformed = 0; sev_mismatch = 0
    for sha, o in rows_raw.items():
        _sha, s, v, sev, cwe, flags = validate_and_clean(o)
        cleaned[sha] = dict(score=s, vector=v, severity=sev, cwe=cwe, flags=flags)
        for f in flags:
            if f.startswith("vector_invalid") or f.startswith("score_unparseable"):
                malformed += 1
            elif f.startswith("score_mismatch"):
                mismatch += 1
            elif f.startswith("severity_mismatch"):
                sev_mismatch += 1
    print(f"validation: {mismatch} score-mismatch (overridden) | {sev_mismatch} severity-mismatch (overridden) | {malformed} malformed (nulled)")

    # ---- read existing _cvss.parquet (the base) ----
    if not NEW_PARQUET.exists():
        sys.exit(f"missing {NEW_PARQUET} — run default aggregation first to seed it")
    base_tbl = pq.read_table(NEW_PARQUET)
    base = base_tbl.to_pandas()
    n_base = len(base)
    print(f"current {NEW_PARQUET.name}: {n_base} rows, {len(base.columns)} cols")

    # ---- in-place update of 4 cols for the jsonl shas ----
    n_updated = 0
    for i, sha in enumerate(base["sha"]):
        c = cleaned.get(sha)
        if not c or c["score"] is None:
            continue
        base.at[i, "cvss_score"]    = float(c["score"])
        base.at[i, "cvss_vector"]   = c["vector"]
        base.at[i, "cvss_severity"] = c["severity"]
        base.at[i, "vuln_class_cwe"]= c["cwe"] or []
        n_updated += 1
    print(f"updated {n_updated} rows in-place with new scores")

    # ---- read master parquet and append non-ruby regate=false rows ----
    master = pq.read_table(PARQUET).to_pandas()
    add_mask = (
        (master["is_security_fix_regate"] == False) &  # noqa: E712
        (master["language"] != "ruby")
    )
    rows_to_add = master[add_mask].copy()
    # align to base columns
    rows_to_add = rows_to_add[list(base.columns)]
    print(f"appending {len(rows_to_add)} non-ruby regate=false rows from {PARQUET.name}")

    final = pd.concat([base, rows_to_add], ignore_index=True)
    # idempotent: dedupe by sha (first occurrence wins, i.e. the base row is kept)
    n_before = len(final)
    final = final.drop_duplicates(subset="sha", keep="first").reset_index(drop=True)
    n_final = len(final)
    n_with_score = int(final["cvss_score"].notna().sum())
    print(f"final {NEW_PARQUET.name}: {n_final} rows ({n_with_score} with cvss_score)"
          + (f" [deduped {n_before - n_final}]" if n_before != n_final else ""))

    # ---- write back to _cvss.parquet only ----
    schema = base_tbl.schema
    table_out = pa.Table.from_pandas(final, schema=schema, preserve_index=False)
    pq.write_table(table_out, NEW_PARQUET, compression="zstd")
    print(f"wrote {NEW_PARQUET}  ({os.path.getsize(NEW_PARQUET)/1048576:.2f} MB, {n_final} rows)")

    # ---- compact report ----
    print("\n== severity histogram (_cvss.parquet, scored rows) ==")
    sev_hist = collections.Counter(final.loc[final["cvss_score"].notna(), "cvss_severity"].tolist())
    for s, _, _ in SEVERITY_BANDS:
        print(f"  {sev_hist.get(s,0):5d}  {s}")

    print("\n== top-10 vuln_class_cwe (first-element, scored rows) ==")
    fc = collections.Counter()
    for v in final["vuln_class_cwe"].dropna():
        try:
            if len(v) > 0:
                fc[v[0]] += 1
        except TypeError:
            pass
    for c, n in fc.most_common(10):
        print(f"  {n:5d}  {c}")


def cli():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only-cvss", action="store_true",
                    help="modify only security-commits-cvss.parquet: in-place update of jsonl shas "
                         "+ append non-ruby regate=false rows from master. Master parquet untouched.")
    args = ap.parse_args()
    if args.only_cvss:
        main_only_cvss()
    else:
        main()


if __name__ == "__main__":
    cli()
