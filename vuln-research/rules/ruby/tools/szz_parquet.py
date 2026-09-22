#!/usr/bin/env python3
"""SZZ blame-contributor attribution for EVERY diffed row of the cvss parquet.

Unlike tools/szz.py (gold-only, writes the szz-introducers aggregate), this runs
the same SZZ Tier-A+B blame over ALL rows of security-commits-cvss.parquet that
carry a fix diff (Ruby `ok` + non-Ruby `ok-nonruby`, 13,643 rows) and writes the
per-fix attribution back INTO the parquet as new columns.

PER FIX F:
  1. `git diff F^1 F -- <code globs>`  (handles single-parent AND GitLab security
     merges; first parent = master-before). Ruby + frontend/Go code extensions.
  2. [denoise] collect DELETED old-side lines, drop blank / comment-only lines
     (#  //  /* *  --). Remaining = "code" deletions to attribute.
  3. `git blame F^1` those lines -> introducing commit + author/email/time.
  4. [addition-only recovery] if the fix only ADDS lines, blame the context lines
     adjacent to each insertion -> "vicinity" introducers (confidence=low).
  5. resolve each introducer commit's subject + cosmetic flag (refactor/lint/...).

NEW PARQUET COLUMNS (added in place; existing columns preserved):
  szz_introducers        VARCHAR  JSON list of edges, one per introducing commit:
                                  [{intro_sha, intro_author, intro_email,
                                    blamed_lines, line_kind, confidence,
                                    introducer_subject, introducer_cosmetic}, ...]
  szz_primary_introducer VARCHAR  author of the dominant edge (most blamed lines,
                                  preferring non-cosmetic high-confidence)
  szz_primary_email      VARCHAR  email of that author
  szz_primary_intro_sha  VARCHAR  sha of that introducing commit
  szz_n_introducers      INT      distinct introducing commits for this fix
  szz_confidence         VARCHAR  high (>=1 code edge) | low (vicinity only) | null
  szz_status             VARCHAR  ok | no-introducer | addition-only-vicinity |
                                  addition-only | diff-fail | null (no diff)

PII: introducer names/emails are REAL author PII. This script overwrites
security-commits-cvss.parquet in place; per the build decision that parquet is
git-ignored (local-only), like oracle/szz-attribution.jsonl. Do NOT publish it.

Run:  python3 tools/szz_parquet.py
"""
import json, os, re, subprocess, collections
from concurrent.futures import ThreadPoolExecutor, as_completed
import pyarrow as pa
import pyarrow.parquet as pq

REPO = os.path.expanduser("~/Personal_Projects/find-ctfs/gitlab")
ORACLE = os.path.normpath(os.path.dirname(os.path.abspath(__file__)) + "/../oracle")
PARQUET = f"{ORACLE}/security-commits-cvss.parquet"
SIDECAR = f"{ORACLE}/szz-parquet-attribution.jsonl"   # per-fix edges, PII, git-ignored

# Ruby + frontend/Go code extensions — the languages our fixes actually touch.
CODE_GLOBS = ["*.rb", "*.rake", "*.erb",
              "*.js", "*.mjs", "*.ts", "*.jsx", "*.tsx", "*.vue", "*.coffee",
              "*.haml", "*.slim", "*.go", "*.graphql", "*.scss", "*.less"]
BLAME_TIMEOUT = 60
DIFF_TIMEOUT = 45
WORKERS = 12
HUNK = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+\d+(?:,\d+)? @@")
COSMETIC = re.compile(r"\b(refactor|rubocop|lint|style|format|reformat|rename|move|"
                      r"typo|whitespace|cleanup|tidy|bump|upgrade|dependency|prettier|"
                      r"eslint|merge branch|merge remote)", re.I)
# blank / pure-comment lines across our languages: # (rb/haml/yaml), // and /* * (js/go), --
COMMENT = re.compile(r"^\s*(#|//|/\*|\*|--)")


def git(args, timeout):
    return subprocess.run(["git", "-C", REPO] + args, capture_output=True,
                          text=True, timeout=timeout, errors="replace")


def is_code(text):
    """A deleted line worth blaming: not blank, not a pure comment."""
    s = text.strip()
    return bool(s) and not COMMENT.match(text)


def parse_diff(fix):
    """Return (code_dels, vicinity), each {file: [old_lineno, ...]}, or (None, None)."""
    try:
        p = git(["diff", f"{fix}^1", fix, "--"] + CODE_GLOBS, DIFF_TIMEOUT)
    except Exception:
        return None, None
    code_dels, vicinity = {}, {}
    cur, oldno = None, 0
    hunk_events = []  # (kind, oldno_or_None), kind in {ctx, del, add}

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


def process(sha):
    code_dels, vicinity = parse_diff(sha)
    if code_dels is None:
        return {"fix_sha": sha, "status": "diff-fail", "edges": []}
    edges, statuses = {}, set()
    if code_dels:
        intro, st = attribute(sha, code_dels, "code"); statuses |= st
        for k, v in intro.items():
            edges[k] = {**v, "confidence": "high"}
    elif vicinity:
        intro, st = attribute(sha, vicinity, "vicinity"); statuses |= st
        for k, v in intro.items():
            edges[k] = {**v, "confidence": "low"}
    edge_list = [{"intro_sha": k, **v} for k, v in edges.items()]
    if code_dels:
        status = "ok" if edge_list else ("blame-empty" if statuses - {"ok"} else "no-introducer")
    elif vicinity:
        status = "addition-only-vicinity" if edge_list else "addition-only"
    else:
        status = "addition-only"
    return {"fix_sha": sha, "status": status, "edges": edge_list}


def introducer_subjects(shas):
    """sha -> (subject, cosmetic_bool); batched git show."""
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
    tbl = pq.read_table(PARQUET)
    shas = tbl.column("sha").to_pylist()
    diff_status = tbl.column("diff_status").to_pylist()
    todo = [s for s, d in zip(shas, diff_status) if d in ("ok", "ok-nonruby")]
    print(f"SZZ blame over {len(todo)} diffed rows / {len(shas)} total | workers={WORKERS}",
          flush=True)

    results = {}
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        futs = {ex.submit(process, s): s for s in todo}
        for i, f in enumerate(as_completed(futs), 1):
            r = f.result(); results[r["fix_sha"]] = r
            if i % 1000 == 0:
                print(f"  {i}/{len(todo)}", flush=True)

    all_intro = {e["intro_sha"] for r in results.values() for e in r["edges"]}
    print(f"resolving subjects for {len(all_intro)} introducer commits...", flush=True)
    subj = introducer_subjects(all_intro)

    # sidecar (PII) + assemble per-row columns
    col_json, col_primary, col_pemail, col_psha, col_n, col_conf, col_status = (
        [], [], [], [], [], [], [])
    with open(SIDECAR, "w") as out:
        for sha in shas:
            r = results.get(sha)
            if r is None:                       # row had no diff (empty/timeout/null)
                col_json.append(None); col_primary.append(None); col_pemail.append(None)
                col_psha.append(None); col_n.append(None); col_conf.append(None)
                col_status.append(None)
                continue
            edges = []
            for e in r["edges"]:
                s, cosmetic = subj.get(e["intro_sha"], (None, False))
                edges.append({
                    "intro_sha": e["intro_sha"], "intro_author": e["author"],
                    "intro_email": e["email"], "intro_time": e["intro_time"],
                    "blamed_lines": e["blamed_lines"], "line_kind": e.get("kind"),
                    "confidence": e["confidence"], "introducer_subject": s,
                    "introducer_cosmetic": cosmetic,
                })
            out.write(json.dumps({"fix_sha": sha, "status": r["status"],
                                  "edges": edges}) + "\n")
            # dominant edge: non-cosmetic high-conf first, then most blamed lines
            primary = None
            if edges:
                primary = sorted(edges, key=lambda e: (
                    e["confidence"] == "high" and not e["introducer_cosmetic"],
                    e["blamed_lines"]), reverse=True)[0]
            has_code = any(e["confidence"] == "high" for e in edges)
            col_json.append(json.dumps(edges) if edges else None)
            col_primary.append(primary["intro_author"] if primary else None)
            col_pemail.append(primary["intro_email"] if primary else None)
            col_psha.append(primary["intro_sha"] if primary else None)
            col_n.append(len(edges))
            col_conf.append("high" if has_code else ("low" if edges else None))
            col_status.append(r["status"])

    # append columns (drop any pre-existing szz_* so re-runs are idempotent)
    drop = {"szz_introducers", "szz_primary_introducer", "szz_primary_email",
            "szz_primary_intro_sha", "szz_n_introducers", "szz_confidence", "szz_status"}
    keep = [n for n in tbl.column_names if n not in drop]
    tbl = tbl.select(keep)
    tbl = tbl.append_column("szz_introducers", pa.array(col_json, pa.string()))
    tbl = tbl.append_column("szz_primary_introducer", pa.array(col_primary, pa.string()))
    tbl = tbl.append_column("szz_primary_email", pa.array(col_pemail, pa.string()))
    tbl = tbl.append_column("szz_primary_intro_sha", pa.array(col_psha, pa.string()))
    tbl = tbl.append_column("szz_n_introducers", pa.array(col_n, pa.int32()))
    tbl = tbl.append_column("szz_confidence", pa.array(col_conf, pa.string()))
    tbl = tbl.append_column("szz_status", pa.array(col_status, pa.string()))
    pq.write_table(tbl, PARQUET, compression="zstd")

    by_status = collections.Counter(r["status"] for r in results.values())
    attributed = sum(1 for c in col_status if c in ("ok", "addition-only-vicinity"))
    print(f"\nstatus breakdown: {dict(by_status)}")
    print(f"rows with >=1 introducer: {attributed}")
    print(f"distinct introducer commits: {len(all_intro)}")
    print(f"wrote columns to {PARQUET}")
    print(f"wrote PII sidecar {SIDECAR}")


if __name__ == "__main__":
    main()
