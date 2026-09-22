#!/usr/bin/env python3
"""SZZ (Sliwerski-Zimmermann-Zeller) — vulnerability-introducer attribution.

Tier A + B + C over the 1,018 diff-verified GOLD security fixes.

PIPELINE per fix F (category/CWE labeled):
  1. diff F^1..F over .rb/.rake/.erb. Uniform `git diff F^1 F` handles single-parent
     AND GitLab security merges (first parent = master-before; diff = the fix).
  2. [Tier B denoise] Collect DELETED old-side lines, DROP blank/comment-only lines
     (cosmetic, not vulnerable logic) -> remaining = "code" deletions to attribute.
  3. `git blame F^1` the code-deletion lines -> introducing commit + author/email/date.
  4. [Tier B addition-only recovery] If a fix only ADDS lines (e.g. a missing auth
     check), deletion-blame finds nothing. Instead blame the CONTEXT lines immediately
     adjacent to each insertion -> "vicinity" introducers, confidence=low, flagged.
  5. [Tier B introducer denoise] Fetch each introducer commit's subject; flag those
     that look cosmetic (refactor/rubocop/lint/style/rename/format/bump/merge) so they
     can be excluded from skill-gap math.
  6. [Tier C exposure normalization] Join each author's TOTAL repo commits (one
     `git shortlog -sne` pass) as exposure; report intro_rate = introductions/exposure
     and category LIFT = author's share of a category / global share -> skill-gap signal
     that isn't just "prolific author".

OUTPUTS (git-ignored; carry real author PII -> local only):
  oracle/szz-attribution.jsonl   one row per (fix -> introducer) edge, with
                                 line_kind(code|vicinity), confidence, introducer_subject,
                                 introducer_cosmetic
  oracle/szz-introducers.json    Tier-C aggregate: per-author exposure-normalized rate,
                                 denoised introductions, category lift / skill-gap

HONEST LIMITS still standing:
  - SZZ is a heuristic; even denoised, blame attributes the LAST toucher, who may not be
    the logic author. Vicinity (addition-only) edges are weak by construction.
  - Exposure = total commits (a proxy); not lines-authored-in-area. Read as team/area
    training signal, not an individual blame leaderboard.
  - `git blame` respects .mailmap; rebases/vendored code still add noise.
"""
import json, os, re, subprocess, collections
from concurrent.futures import ThreadPoolExecutor, as_completed

REPO = os.path.expanduser("~/Personal_Projects/find-ctfs/gitlab")
ORACLE = os.path.normpath(os.path.dirname(os.path.abspath(__file__)) + "/../oracle")
EDGES = f"{ORACLE}/szz-attribution.jsonl"
AGG = f"{ORACLE}/szz-introducers.json"
GLOBS = ["*.rb", "*.rake", "*.erb"]
BLAME_TIMEOUT = 60
WORKERS = 10
HUNK = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+\d+(?:,\d+)? @@")
COSMETIC = re.compile(r"\b(refactor|rubocop|lint|style|format|reformat|rename|move|"
                      r"typo|whitespace|cleanup|tidy|bump|upgrade|dependency|prettier|"
                      r"merge branch|merge remote)", re.I)
RUBY_COMMENT = re.compile(r"^\s*#")

def git(args, timeout):
    return subprocess.run(["git", "-C", REPO] + args, capture_output=True,
                          text=True, timeout=timeout, errors="replace")

def is_code(text):
    """A deleted line worth blaming: not blank, not a pure comment."""
    s = text.strip()
    return bool(s) and not RUBY_COMMENT.match(text)

def parse_diff(fix):
    """Return (code_dels, vicinity) where
       code_dels = {file: [old_lineno, ...]}  # non-trivial deleted lines
       vicinity  = {file: [old_lineno, ...]}  # context lines adjacent to insertions
    """
    try:
        p = git(["diff", f"{fix}^1", fix, "--"] + GLOBS, 45)
    except Exception:
        return None, None
    code_dels, vicinity = {}, {}
    cur, oldno = None, 0
    # per-hunk event list to locate context lines adjacent to '+' runs
    hunk_events = []  # (kind, oldno_or_None)  kind in {'ctx','del','add'}
    def flush_hunk():
        if cur is None:
            return
        for i, (k, ln) in enumerate(hunk_events):
            if k != "ctx":
                continue
            near_add = any(hunk_events[j][0] == "add"
                           for j in (i - 1, i + 1) if 0 <= j < len(hunk_events))
            if near_add and ln is not None:
                vicinity.setdefault(cur, []).append(ln)
    for line in (p.stdout or "").splitlines():
        if line.startswith("diff --git"):
            flush_hunk(); hunk_events = []; cur = None
        elif line.startswith("+++ b/"):
            cur = line[6:]
        elif line.startswith("@@"):
            flush_hunk(); hunk_events = []
            m = HUNK.match(line)
            oldno = int(m.group(1)) if m else 0
        elif cur is not None and line.startswith("-") and not line.startswith("---"):
            if is_code(line[1:]):
                code_dels.setdefault(cur, []).append(oldno)
            hunk_events.append(("del", oldno)); oldno += 1
        elif cur is not None and line.startswith("+") and not line.startswith("+++"):
            hunk_events.append(("add", None))
        elif cur is not None and (line.startswith(" ") or line == ""):
            hunk_events.append(("ctx", oldno)); oldno += 1
    flush_hunk()
    return code_dels, vicinity

def blame_file(fix, path):
    try:
        p = git(["blame", "--porcelain", f"{fix}^1", "--", path], BLAME_TIMEOUT)
    except subprocess.TimeoutExpired:
        return None, "timeout"
    except Exception as e:
        return None, f"error:{type(e).__name__}"
    if p.returncode != 0:
        return None, "blame-fail"
    commits, lines, cur, lineno = {}, {}, None, None
    for ln in (p.stdout or "").splitlines():
        if re.match(r"^[0-9a-f]{40} ", ln):
            parts = ln.split(); cur = parts[0]; lineno = int(parts[2])
            commits.setdefault(cur, {})
        elif ln.startswith("author "):
            commits[cur]["author"] = ln[7:]
        elif ln.startswith("author-mail "):
            commits[cur]["email"] = ln[12:].strip("<>")
        elif ln.startswith("author-time "):
            commits[cur]["time"] = int(ln[12:])
        elif ln.startswith("\t") and cur and lineno is not None:
            lines[lineno] = cur
    return (lines, commits), "ok"

def attribute(fix, want, kind):
    """Blame `want` ({file:[lines]}) at fix^1; return {intro_sha: {...}} + statuses."""
    intro = collections.defaultdict(lambda: {"author": None, "email": None,
                                              "intro_time": None, "blamed_lines": 0})
    statuses = set()
    for path, lns in want.items():
        res, st = blame_file(fix, path); statuses.add(st)
        if res is None:
            continue
        bl, commits = res
        for n in lns:
            isha = bl.get(n)
            if not isha or isha == fix:
                continue
            e = intro[isha]; c = commits.get(isha, {})
            e["author"] = c.get("author"); e["email"] = c.get("email")
            e["intro_time"] = c.get("time"); e["blamed_lines"] += 1
            e["kind"] = kind
    return intro, statuses

def process(rec):
    fix = rec["sha"]
    code_dels, vicinity = parse_diff(fix)
    if code_dels is None:
        return {"fix_sha": fix, "status": "diff-fail", "edges": []}
    edges, statuses = {}, set()
    if code_dels:
        intro, st = attribute(fix, code_dels, "code"); statuses |= st
        for k, v in intro.items():
            edges[k] = {**v, "confidence": "high"}
    elif vicinity:  # addition-only: fall back to vicinity context blame
        intro, st = attribute(fix, vicinity, "vicinity"); statuses |= st
        for k, v in intro.items():
            edges[k] = {**v, "confidence": "low"}
    edge_list = [{"intro_sha": k, **v} for k, v in edges.items()]
    if code_dels:
        status = "ok" if edge_list else ("blame-empty" if statuses - {"ok"} else "no-introducer")
    elif vicinity:
        status = "addition-only-vicinity" if edge_list else "addition-only"
    else:
        status = "addition-only"
    return {"fix_sha": fix, "category": rec.get("category"), "cwe": rec.get("cwe"),
            "fix_date": rec.get("date"), "status": status, "edges": edge_list}

def load_exposure():
    """email -> total authored commits across all refs (Tier-C exposure denominator)."""
    exp = {}
    try:
        p = git(["shortlog", "-sne", "--all", "HEAD"], 180)
        for line in (p.stdout or "").splitlines():
            m = re.match(r"\s*(\d+)\s+(.*?)\s+<([^>]+)>", line)
            if m:
                exp[m.group(3)] = exp.get(m.group(3), 0) + int(m.group(1))
    except Exception as e:
        print(f"WARN exposure: {e}")
    return exp

def introducer_subjects(shas):
    """sha -> (subject, cosmetic_bool); batched cat-file."""
    out = {}
    shas = list(shas)
    for i in range(0, len(shas), 200):
        batch = shas[i:i + 200]
        try:
            p = subprocess.run(["git", "-C", REPO, "show", "-s", "--format=%H%x01%s", *batch],
                               capture_output=True, text=True, timeout=120, errors="replace")
            for line in p.stdout.splitlines():
                if "\x01" in line:
                    h, s = line.split("\x01", 1)
                    out[h] = (s, bool(COSMETIC.search(s)))
        except Exception:
            pass
    return out

def main():
    gold = json.load(open(f"{ORACLE}/security-fix-corpus.json"))["commits"]
    print(f"SZZ B+C over {len(gold)} gold fixes | workers={WORKERS}", flush=True)
    results = []
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        futs = {ex.submit(process, r): r["sha"] for r in gold}
        for i, f in enumerate(as_completed(futs), 1):
            results.append(f.result())
            if i % 200 == 0:
                print(f"  {i}/{len(gold)}", flush=True)

    # introducer subjects + cosmetic flags
    all_intro = {e["intro_sha"] for r in results for e in r["edges"]}
    print(f"resolving subjects for {len(all_intro)} introducer commits...", flush=True)
    subj = introducer_subjects(all_intro)
    exposure = load_exposure()
    print(f"exposure map: {len(exposure)} authors", flush=True)

    # write edges
    with open(EDGES, "w") as out:
        for r in results:
            for e in r["edges"]:
                s, cosmetic = subj.get(e["intro_sha"], (None, False))
                out.write(json.dumps({
                    "fix_sha": r["fix_sha"], "category": r.get("category"),
                    "cwe": r.get("cwe"), "fix_date": r.get("fix_date"),
                    "intro_sha": e["intro_sha"], "intro_author": e["author"],
                    "intro_email": e["email"], "intro_time": e["intro_time"],
                    "blamed_lines": e["blamed_lines"], "line_kind": e.get("kind"),
                    "confidence": e["confidence"], "introducer_subject": s,
                    "introducer_cosmetic": cosmetic,
                }) + "\n")

    # ---- Tier C aggregate: denoised, exposure-normalized, category lift ----
    by_status = collections.Counter(r["status"] for r in results)
    global_cat = collections.Counter()
    author = collections.defaultdict(lambda: {"introductions": 0, "denoised": 0,
        "vicinity": 0, "blamed_lines": 0, "fixes": set(), "email": None,
        "categories": collections.Counter(), "cwes": collections.Counter()})
    for r in results:
        for e in r["edges"]:
            s, cosmetic = subj.get(e["intro_sha"], (None, False))
            a = e["author"] or "(unknown)"
            ag = author[a]; ag["email"] = ag["email"] or e["email"]
            ag["introductions"] += 1
            if e["confidence"] == "low":
                ag["vicinity"] += 1
            if not cosmetic and e["confidence"] == "high":
                ag["denoised"] += 1
                if r.get("category"):
                    ag["categories"][r["category"]] += 1; global_cat[r["category"]] += 1
                for c in (r.get("cwe") or []):
                    ag["cwes"][str(c)] += 1
            ag["blamed_lines"] += e["blamed_lines"]; ag["fixes"].add(r["fix_sha"])
    total_denoised = sum(global_cat.values()) or 1
    global_share = {c: n / total_denoised for c, n in global_cat.items()}

    authors = []
    for a, ag in author.items():
        exp = exposure.get(ag["email"] or "", 0)
        dn = ag["denoised"]; cats = ag["categories"]; tot = sum(cats.values()) or 1
        # category lift: author's within-category share vs global share (skill-gap signal)
        lift = sorted(
            ((c, round((cats[c] / tot) / global_share[c], 2), cats[c])
             for c in cats if global_share.get(c)),
            key=lambda x: -x[1])
        authors.append({
            "author": a, "email": ag["email"],
            "introductions_raw": ag["introductions"],
            "introductions_denoised": dn, "vicinity_only": ag["vicinity"],
            "distinct_fixes": len(ag["fixes"]),
            "total_commits": exp,
            "intro_per_1k_commits": round(1000 * dn / exp, 2) if exp else None,
            "top_categories": cats.most_common(6),
            "dominant_category": cats.most_common(1)[0][0] if cats else None,
            "skill_gap_lift": lift[:4],   # categories this author introduces above baseline
            "top_cwes": ag["cwes"].most_common(6),
        })
    authors.sort(key=lambda x: -x["introductions_denoised"])

    agg = {
        "tier": "A+B+C",
        "gold_fixes": len(gold),
        "fix_status_breakdown": dict(by_status),
        "attributed_fixes_code": sum(1 for r in results if r["status"] == "ok"),
        "attributed_fixes_vicinity": sum(1 for r in results if r["status"] == "addition-only-vicinity"),
        "still_unattributable": by_status.get("addition-only", 0),
        "total_edges": sum(len(r["edges"]) for r in results),
        "code_edges": sum(1 for r in results for e in r["edges"] if e["confidence"] == "high"),
        "vicinity_edges": sum(1 for r in results for e in r["edges"] if e["confidence"] == "low"),
        "cosmetic_introducer_edges": sum(1 for r in results for e in r["edges"]
                                         if subj.get(e["intro_sha"], (None, False))[1]),
        "distinct_introducers": len(author),
        "global_category_distribution": dict(global_cat),
        "top_introducers_denoised": authors[:40],
        "method": "Tier A blame + B (line+commit denoise, addition-only vicinity) + "
                  "C (exposure-normalized rate, category lift). git blame honors .mailmap.",
        "caveats": [
            "Vicinity edges (addition-only fixes) are low-confidence by construction.",
            "Cosmetic introducers flagged & excluded from denoised counts / lift.",
            "Exposure = total authored commits (proxy, not lines-in-area).",
            "Read as team/area training signal, NOT an individual blame leaderboard.",
        ],
    }
    json.dump(agg, open(AGG, "w"), indent=2)
    print(f"\nstatus: {dict(by_status)}")
    print(f"code edges: {agg['code_edges']} | vicinity: {agg['vicinity_edges']} | "
          f"cosmetic flagged: {agg['cosmetic_introducer_edges']}")
    print(f"recovered via vicinity: {agg['attributed_fixes_vicinity']} | "
          f"still unattributable: {agg['still_unattributable']}")
    print(f"distinct introducers: {agg['distinct_introducers']}")
    print(f"wrote {EDGES} and {AGG}")

if __name__ == "__main__":
    main()
