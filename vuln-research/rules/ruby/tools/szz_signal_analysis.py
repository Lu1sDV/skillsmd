#!/usr/bin/env python3
"""
szz_signal_analysis.py — turn SZZ introducer edges into a prioritization scorecard.

Goal (scoped via deep-interview 2026-06-11): feed two defensive decisions —
  (1) rule-authoring prioritization  — which vuln CLASSES to write Semgrep/CodeQL
      rules for first; and
  (2) risk / hotspot triage          — which introducing COMMITS are vuln-dense.
Class / commit level only — NOT an individual-blame leaderboard (no author names
in any output).

Scope (the eligible fix set): a fix is counted iff its parquet row is
  is_security_fix_regate == True  AND  cvss_score > 0  AND  diff present
and we keep only edges with line_kind == "code" and introducer_cosmetic == False
(drop vicinity + cosmetic SZZ noise). Weak-tier counts are directional.

Composite class priority (documented, reproducible):
  For each class, three signals — F = #fixes (reintroduction frequency),
  D = median dwell days (intro -> fix), S = median CVSS of its fixes.
  Each is rank-normalized across classes to (0,1] (highest -> 1.0, average-rank
  ties), then priority = norm(F) * norm(D) * norm(S) * 100. Multiplicative, so a
  class must score on ALL three to rank high (a frequent-but-trivial-and-quickly-
  fixed class won't dominate). An additive variant is in the comments.

Inputs:
  --sidecar : SZZ edge JSONL (default the full per-row run; falls back to the
              gold-only sidecar so a preview can run before the full job lands).
  --parquet : the CVSS-enriched parquet (eligibility + cvss + category source).
Outputs (under --out-dir, default oracle/analysis/, which is git-ignored):
  szz-class-priority.csv   szz-hotspot-commits.csv   szz-scorecard.md
"""
import argparse
import csv
import json
import os
from collections import defaultdict
from datetime import datetime, timezone
from statistics import median

HERE = os.path.dirname(os.path.abspath(__file__))
ORACLE = os.path.normpath(os.path.join(HERE, "..", "oracle"))
FULL_SIDECAR = os.path.join(ORACLE, "szz-parquet-attribution.jsonl")
GOLD_SIDECAR = os.path.join(ORACLE, "szz-attribution.jsonl")
PARQUET = os.path.join(ORACLE, "security-commits-cvss.parquet")
DEFAULT_OUT = os.path.join(ORACLE, "analysis")


def load_eligible(parquet_path):
    """sha -> meta for rows that pass the eligibility gate (security + cvss + diff)."""
    import pyarrow.parquet as pq
    t = pq.read_table(
        parquet_path,
        columns=["sha", "date", "is_security_fix_regate", "cvss_score",
                 "cvss_severity", "diff_status", "category", "language",
                 "quality_tier"],
    ).to_pandas()
    elig = {}
    for _, r in t.iterrows():
        if r["is_security_fix_regate"] is not True:
            continue
        score = r["cvss_score"] or 0
        if score <= 0:
            continue
        if r["diff_status"] not in ("ok", "ok-nonruby"):
            continue
        elig[r["sha"]] = {
            "category": (r["category"] or "other"),
            "fix_date": r["date"],            # parquet date = authoritative fix date
            "cvss_score": float(score),
            "cvss_severity": r["cvss_severity"] or "None",
            "language": r["language"] or "(null)",
            "quality_tier": r["quality_tier"] or "weak",
        }
    return elig


def parse_fix_epoch(fix_date):
    """fix_date is 'YYYY-MM-DD' (commit date). Return epoch seconds or None."""
    if not fix_date:
        return None
    try:
        return datetime.strptime(fix_date[:10], "%Y-%m-%d").replace(
            tzinfo=timezone.utc).timestamp()
    except ValueError:
        return None


def _iter_raw_edges(sidecar_path):
    """Yield (fix_sha, edge_dict) for both schemas:
       flat (gold)  : one edge per line, fix_sha inline.
       nested (full): {fix_sha, status, edges:[...]} per line."""
    with open(sidecar_path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            rec = json.loads(line)
            if "edges" in rec:
                for e in rec["edges"]:
                    yield rec["fix_sha"], e
            else:
                yield rec["fix_sha"], rec


def load_edges(sidecar_path, eligible):
    """Code, non-cosmetic edges whose fix is in the eligible set. Attaches cvss
    and the authoritative fix_date/category from the parquet meta."""
    edges = []
    dropped_ineligible = dropped_noncode = 0
    for fix_sha, e in _iter_raw_edges(sidecar_path):
        if e.get("line_kind") != "code" or e.get("introducer_cosmetic"):
            dropped_noncode += 1
            continue
        meta = eligible.get(fix_sha)
        if meta is None:
            dropped_ineligible += 1
            continue
        e["fix_sha"] = fix_sha
        e["fix_date"] = meta["fix_date"]    # parquet date (full sidecar omits it)
        e["_cvss"] = meta["cvss_score"]
        e["_severity"] = meta["cvss_severity"]
        e["_category"] = meta["category"]   # parquet category = authoritative
        e["_language"] = meta["language"]
        edges.append(e)
    return edges, dropped_noncode, dropped_ineligible


def rank_normalize(values):
    """Average-rank normalize to (0,1]; highest value -> 1.0. Returns dict id->norm."""
    n = len(values)
    if n == 0:
        return {}
    order = sorted(values.items(), key=lambda kv: kv[1])
    ranks, i = {}, 0
    while i < n:
        j = i
        while j + 1 < n and order[j + 1][1] == order[i][1]:
            j += 1
        avg_rank = (i + j) / 2 + 1               # 1-based average rank
        for k in range(i, j + 1):
            ranks[order[k][0]] = avg_rank / n
        i = j + 1
    return ranks


def class_scorecard(edges):
    by_cat = defaultdict(lambda: {"fixes": set(), "edges": 0, "intro_shas": set(),
                                  "dwell": [], "cvss": {}, "neg_dwell": 0})
    for e in edges:
        c = e["_category"]
        d = by_cat[c]
        d["fixes"].add(e["fix_sha"])
        d["edges"] += 1
        d["intro_shas"].add(e["intro_sha"])
        d["cvss"][e["fix_sha"]] = e["_cvss"]      # one cvss per fix
        fix_ep = parse_fix_epoch(e.get("fix_date"))
        itime = e.get("intro_time")
        if fix_ep and itime:
            dd = (fix_ep - itime) / 86400.0
            if dd >= 0:
                d["dwell"].append(dd)
            else:
                d["neg_dwell"] += 1

    rows = {}
    for c, d in by_cat.items():
        rows[c] = {
            "category": c,
            "n_fixes": len(d["fixes"]),
            "n_edges": d["edges"],
            "distinct_introducing_commits": len(d["intro_shas"]),
            "median_dwell_days": round(median(d["dwell"]), 1) if d["dwell"] else 0.0,
            "median_cvss": round(median(d["cvss"].values()), 1) if d["cvss"] else 0.0,
            "max_cvss": round(max(d["cvss"].values()), 1) if d["cvss"] else 0.0,
            "negative_dwell_anomalies": d["neg_dwell"],
        }
    # composite: rank-normalized multiplicative over (freq, dwell, cvss)
    nf = rank_normalize({c: r["n_fixes"] for c, r in rows.items()})
    nd = rank_normalize({c: r["median_dwell_days"] for c, r in rows.items()})
    ns = rank_normalize({c: r["median_cvss"] for c, r in rows.items()})
    for c, r in rows.items():
        r["priority_score"] = round(nf[c] * nd[c] * ns[c] * 100, 1)
        # additive alt (uncomment to compare): (nf[c]+nd[c]+ns[c])/3*100
    return sorted(rows.values(), key=lambda r: r["priority_score"], reverse=True)


def hotspot_commits(edges):
    by_intro = defaultdict(lambda: {"fixes": set(), "cats": set(), "lines": 0,
                                    "subject": "", "cvss": []})
    for e in edges:
        h = by_intro[e["intro_sha"]]
        h["fixes"].add(e["fix_sha"])
        h["cats"].add(e["_category"])
        h["lines"] += e.get("blamed_lines", 0)
        h["subject"] = h["subject"] or (e.get("introducer_subject") or "")
        h["cvss"].append(e["_cvss"])
    rows = []
    for sha, h in by_intro.items():
        rows.append({
            "intro_sha": sha[:12],
            "n_fixes_caused": len(h["fixes"]),
            "categories": ";".join(sorted(h["cats"])),
            "total_blamed_lines": h["lines"],
            "max_cvss": round(max(h["cvss"]), 1) if h["cvss"] else 0.0,
            "introducer_subject": h["subject"][:80],
        })
    return sorted(rows, key=lambda r: (r["n_fixes_caused"], r["max_cvss"],
                                       r["total_blamed_lines"]), reverse=True)


def write_csv(path, rows, fields):
    with open(path, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=fields)
        w.writeheader()
        for r in rows:
            w.writerow({k: r[k] for k in fields})


def md_table(rows, cols, headers, limit=None):
    rows = rows[:limit] if limit else rows
    out = ["| " + " | ".join(headers) + " |",
           "|" + "|".join("---" for _ in headers) + "|"]
    for r in rows:
        out.append("| " + " | ".join(str(r[c]) for c in cols) + " |")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sidecar", default=None,
                    help="SZZ edge JSONL (default: full run, fallback gold)")
    ap.add_argument("--parquet", default=PARQUET)
    ap.add_argument("--out-dir", default=DEFAULT_OUT)
    ap.add_argument("--top-hotspots", type=int, default=40)
    args = ap.parse_args()

    sidecar = args.sidecar
    preview = False
    if sidecar is None:
        if os.path.exists(FULL_SIDECAR):
            sidecar = FULL_SIDECAR
        else:
            sidecar = GOLD_SIDECAR
            preview = True
    os.makedirs(args.out_dir, exist_ok=True)

    eligible = load_eligible(args.parquet)
    edges, drop_nc, drop_inelig = load_edges(sidecar, eligible)
    classes = class_scorecard(edges)
    hotspots = hotspot_commits(edges)

    n_fixes = len({e["fix_sha"] for e in edges})
    write_csv(os.path.join(args.out_dir, "szz-class-priority.csv"), classes,
              ["category", "priority_score", "n_fixes", "n_edges",
               "distinct_introducing_commits", "median_dwell_days",
               "median_cvss", "max_cvss", "negative_dwell_anomalies"])
    write_csv(os.path.join(args.out_dir, "szz-hotspot-commits.csv"), hotspots,
              ["intro_sha", "n_fixes_caused", "categories", "total_blamed_lines",
               "max_cvss", "introducer_subject"])

    src = "GOLD-ONLY PREVIEW (full per-row SZZ run not yet present)" if preview \
        else os.path.basename(sidecar)
    lines = [
        "# SZZ Signal Scorecard — vuln-class & hotspot prioritization",
        "",
        f"- **Source edges:** `{src}`",
        f"- **Eligible fixes** (security + CVSS>0 + diff): {len(eligible)}",
        f"- **Attributed in this run** (code, non-cosmetic edges): {n_fixes} fixes / "
        f"{len(edges)} edges  ({drop_nc} non-code/cosmetic, {drop_inelig} ineligible dropped)",
        "- **Framing:** class & commit level only — not an individual-blame leaderboard.",
        "",
        "## 1. Vuln classes by composite priority",
        "Priority = rank-norm(#fixes) × rank-norm(median dwell days) × "
        "rank-norm(median CVSS) × 100 — a class must rank on frequency, longevity, "
        "AND severity to score high.",
        "",
        md_table(classes,
                 ["category", "priority_score", "n_fixes", "median_dwell_days",
                  "median_cvss", "max_cvss", "distinct_introducing_commits"],
                 ["class", "priority", "#fixes", "med dwell (d)", "med CVSS",
                  "max CVSS", "distinct intro commits"]),
        "",
        f"## 2. Vuln-dense introducing commits (top {args.top_hotspots})",
        "One commit that later required multiple security fixes = a hotspot worth "
        "a targeted rule or review pass.",
        "",
        md_table(hotspots,
                 ["intro_sha", "n_fixes_caused", "max_cvss", "total_blamed_lines",
                  "categories", "introducer_subject"],
                 ["intro commit", "#fixes caused", "max CVSS", "blamed lines",
                  "classes", "subject"],
                 limit=args.top_hotspots),
        "",
    ]
    md_path = os.path.join(args.out_dir, "szz-scorecard.md")
    with open(md_path, "w") as fh:
        fh.write("\n".join(lines))

    print(f"[{'PREVIEW' if preview else 'FULL'}] {n_fixes} fixes / {len(edges)} edges "
          f"-> {md_path}")
    print(f"  classes: {len(classes)}  hotspots: {len(hotspots)}")
    for r in classes[:8]:
        print(f"    {r['category']:18} pri={r['priority_score']:5}  "
              f"fixes={r['n_fixes']:4} dwell={r['median_dwell_days']:7}d "
              f"cvss={r['median_cvss']}")


if __name__ == "__main__":
    main()
