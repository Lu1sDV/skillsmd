#!/usr/bin/env bash
# incomplete_fix_hunt.sh — Strategy #6: Incomplete-Fix / Unpatched-Call-Site Detection
#
# Usage:
#   incomplete_fix_hunt.sh WORKLIST_JSON [LIMIT] [SRC] [JOURNAL]
#
# Args:
#   WORKLIST_JSON  Path to oracle/validation/incomplete-fix-worklist.json
#   LIMIT          Max jobs to process (default: 10)
#   SRC            Git source repo (default: /home/x/Personal_Projects/find-ctfs/gitlab)
#   JOURNAL        Path to append run log (default: oracle/validation/incomplete-fix-hunt.journal.jsonl)
#
# Memory contract:
#   - ONE 8G build or ONE 14G analyze at a time, NEVER concurrent.
#   - Do NOT run while another 16G CodeQL job is active.
#   - Idempotent: skips any sha already in VERDICTS_OUT or JOURNAL.
#   - Continue-on-error: logs failures and moves to the next job.
#
# Outputs:
#   oracle/validation/incomplete-fix-verdicts.jsonl  — verdict.py JSON lines appended per job
#   oracle/validation/sarif/if-<sha8>-{before,after}.sarif  — kept for review
#
# Per-job disk reclaim: DBs (~1.4GB each) deleted after each job; SARIFs kept.

set -euo pipefail

# ── Args ────────────────────────────────────────────────────────────────────────
WORKLIST="${1:?Usage: $0 WORKLIST_JSON [LIMIT] [SRC] [JOURNAL]}"
LIMIT="${2:-10}"
SRC="${3:-/home/x/Personal_Projects/find-ctfs/gitlab}"
JOURNAL="${4:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ -z "$JOURNAL" ]]; then
    JOURNAL="${REPO_ROOT}/oracle/validation/incomplete-fix-hunt.journal.jsonl"
fi

VERDICTS_OUT="${REPO_ROOT}/oracle/validation/incomplete-fix-verdicts.jsonl"
SARIF_DIR="${REPO_ROOT}/oracle/validation/sarif"
DB_BASE="${REPO_ROOT}/oracle/validation/dbs"
TMP_BASE="${REPO_ROOT}/oracle/validation/tmp-worktrees"
MANIFEST="${REPO_ROOT}/oracle/validation/snapshots.jsonl"
VERDICT_PY="${SCRIPT_DIR}/verdict.py"

BUILD_SH="${SCRIPT_DIR}/build_db.sh"
ANALYZE_SH="${SCRIPT_DIR}/analyze.sh"

mkdir -p "${SARIF_DIR}" "${DB_BASE}" "${TMP_BASE}"

# ── Helpers ─────────────────────────────────────────────────────────────────────

log_progress() {
    local sha="$1"; shift
    echo "[$(date -u +%H:%M:%SZ)] sha=${sha:0:8} $*"
}

log_journal() {
    local sha="$1" status="$2" msg="$3"
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"sha\":\"${sha}\",\"status\":\"${status}\",\"msg\":$(echo "$msg" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))')}" \
        >> "${JOURNAL}"
}

sha_in_verdicts() {
    local sha="$1"
    # verdict.py writes via json.dump => `"sha": "<sha>"` (space after colon).
    # Tolerate optional whitespace so idempotency actually matches.
    [[ -f "${VERDICTS_OUT}" ]] && grep -Eq "\"sha\": ?\"${sha}\"" "${VERDICTS_OUT}" 2>/dev/null
}

sha_in_journal() {
    local sha="$1"
    [[ -f "${JOURNAL}" ]] && grep -q "\"sha\":\"${sha}\"" "${JOURNAL}" 2>/dev/null
}

cleanup_worktrees() {
    local wt_before="$1" wt_after="$2"
    git -C "${SRC}" worktree remove --force "${wt_before}" 2>/dev/null || true
    git -C "${SRC}" worktree remove --force "${wt_after}"  2>/dev/null || true
    rm -rf "${wt_before}" "${wt_after}" 2>/dev/null || true
}

cleanup_dbs() {
    local db_before="$1" db_after="$2"
    rm -rf "${db_before}" "${db_after}" 2>/dev/null || true
}

# ── Main loop ───────────────────────────────────────────────────────────────────
echo "=== incomplete_fix_hunt.sh ==="
echo "  WORKLIST : ${WORKLIST}"
echo "  LIMIT    : ${LIMIT}"
echo "  SRC      : ${SRC}"
echo "  JOURNAL  : ${JOURNAL}"
echo "  VERDICTS : ${VERDICTS_OUT}"
echo ""

# Parse worklist with python3 to iterate jobs; jq not required
job_count=0
processed=0
skipped=0
failed=0

# Use python3 to extract each job as a one-liner for easy shell consumption
python3 - "${WORKLIST}" "${LIMIT}" <<'PYEOF' | while IFS='|' read -r SHA PARENT_REF CATEGORY PRIORITY QUERY_PATHS_JSON; do
import json, sys

worklist_path = sys.argv[1]
limit = int(sys.argv[2])

with open(worklist_path) as f:
    jobs = json.load(f)

for job in jobs[:limit]:
    sha          = job["sha"]
    parent_ref   = job.get("parent_ref", sha + "^1")
    category     = job.get("category", "")
    priority     = job.get("priority_score", 0)
    query_paths  = json.dumps([q["path"] for q in job["queries"]])
    print(f"{sha}|{parent_ref}|{category}|{priority}|{query_paths}")
PYEOF

    job_count=$((job_count + 1))
    SHA8="${SHA:0:8}"
    log_progress "${SHA}" "START  cat=${CATEGORY} pri=${PRIORITY}"

    # ── Idempotency check ──────────────────────────────────────────────────────
    # Idempotency keys on the VERDICTS file only — a journal entry merely means we
    # ATTEMPTED the sha (incl. failed/aborted runs + intermediate DB-build records), so
    # checking the journal would wrongly skip jobs that never produced a verdict.
    if sha_in_verdicts "${SHA}"; then
        log_progress "${SHA}" "SKIP   already has verdict"
        skipped=$((skipped + 1))
        continue
    fi

    # ── Paths for this job ─────────────────────────────────────────────────────
    WT_BEFORE="${TMP_BASE}/wt-${SHA8}-before"
    WT_AFTER="${TMP_BASE}/wt-${SHA8}-after"
    DB_BEFORE="${DB_BASE}/if-${SHA8}-before"
    DB_AFTER="${DB_BASE}/if-${SHA8}-after"
    SARIF_BEFORE="${SARIF_DIR}/if-${SHA8}-before.sarif"
    SARIF_AFTER="${SARIF_DIR}/if-${SHA8}-after.sarif"

    # Build a per-job .qls from QUERY_PATHS_JSON
    QLS_FILE="${TMP_BASE}/suite-${SHA8}.qls"
    python3 - "${QUERY_PATHS_JSON}" "${QLS_FILE}" <<'PYEOF2'
import json, sys
paths_json = sys.argv[1]
qls_path   = sys.argv[2]
paths = json.loads(paths_json)
# Emit a plain query-list suite. Each `- query: <abs path>` resolves against the
# query's enclosing qlpack (codeql/qlpack.yml). Do NOT use `- queries: .` — a bare
# relative path is unresolvable when the .qls lives outside the pack (CodeQL: "refers
# to a relative path '.' but is not in a pack, so we don't know what to resolve it against").
with open(qls_path, "w") as f:
    for p in paths:
        f.write(f"- query: {p}\n")
PYEOF2

    # ── Step 1: Materialize worktrees ──────────────────────────────────────────
    log_progress "${SHA}" "STEP1  git worktree add before=${PARENT_REF} after=${SHA}"

    if ! git -C "${SRC}" worktree add --detach "${WT_AFTER}"  "${SHA}" 2>&1; then
        log_progress "${SHA}" "FAIL   worktree add after failed (sha missing?)"
        log_journal  "${SHA}" "fail"  "worktree add after failed for sha=${SHA}"
        failed=$((failed + 1))
        continue
    fi

    if ! git -C "${SRC}" worktree add --detach "${WT_BEFORE}" "${PARENT_REF}" 2>&1; then
        log_progress "${SHA}" "FAIL   worktree add before failed (parent=${PARENT_REF})"
        log_journal  "${SHA}" "fail"  "worktree add before failed for parent=${PARENT_REF}"
        git -C "${SRC}" worktree remove --force "${WT_AFTER}" 2>/dev/null || true
        rm -rf "${WT_AFTER}" 2>/dev/null || true
        failed=$((failed + 1))
        continue
    fi

    # ── Step 2: Build BEFORE DB, then AFTER DB (serial, 8G each) ───────────────
    log_progress "${SHA}" "STEP2a build BEFORE DB"
    if ! "${BUILD_SH}" "${WT_BEFORE}" "${DB_BEFORE}" "if-${SHA8}-before" "8G" "5000" "4" "${JOURNAL}" 2>&1; then
        log_progress "${SHA}" "FAIL   BEFORE DB build failed"
        log_journal  "${SHA}" "fail"  "build_db BEFORE failed"
        cleanup_worktrees "${WT_BEFORE}" "${WT_AFTER}"
        failed=$((failed + 1))
        continue
    fi

    log_progress "${SHA}" "STEP2b build AFTER DB"
    if ! "${BUILD_SH}" "${WT_AFTER}" "${DB_AFTER}" "if-${SHA8}-after" "8G" "5000" "4" "${JOURNAL}" 2>&1; then
        log_progress "${SHA}" "FAIL   AFTER DB build failed"
        log_journal  "${SHA}" "fail"  "build_db AFTER failed"
        cleanup_worktrees "${WT_BEFORE}" "${WT_AFTER}"
        cleanup_dbs "${DB_BEFORE}" "${DB_AFTER}"
        failed=$((failed + 1))
        continue
    fi

    # ── Step 3: Analyze BEFORE, then AFTER (serial, 14G each) ─────────────────
    log_progress "${SHA}" "STEP3a analyze BEFORE"
    if ! "${ANALYZE_SH}" "${DB_BEFORE}" "${QLS_FILE}" "${SARIF_BEFORE}" "14G" "9000" "4" "${JOURNAL}" 2>&1; then
        log_progress "${SHA}" "FAIL   analyze BEFORE failed"
        log_journal  "${SHA}" "fail"  "analyze BEFORE failed"
        cleanup_worktrees "${WT_BEFORE}" "${WT_AFTER}"
        cleanup_dbs "${DB_BEFORE}" "${DB_AFTER}"
        failed=$((failed + 1))
        continue
    fi

    log_progress "${SHA}" "STEP3b analyze AFTER"
    if ! "${ANALYZE_SH}" "${DB_AFTER}" "${QLS_FILE}" "${SARIF_AFTER}" "14G" "9000" "4" "${JOURNAL}" 2>&1; then
        log_progress "${SHA}" "FAIL   analyze AFTER failed"
        log_journal  "${SHA}" "fail"  "analyze AFTER failed"
        cleanup_worktrees "${WT_BEFORE}" "${WT_AFTER}"
        cleanup_dbs "${DB_BEFORE}" "${DB_AFTER}"
        failed=$((failed + 1))
        continue
    fi

    # ── Step 4: verdict.py → append to verdicts.jsonl ─────────────────────────
    log_progress "${SHA}" "STEP4  verdict.py"
    verdict_output="$(python3 "${VERDICT_PY}" \
        --sha "${SHA}" \
        --manifest "${MANIFEST}" \
        --before-sarif "${SARIF_BEFORE}" \
        --after-sarif "${SARIF_AFTER}" \
        --out - 2>&1)" || true

    if [[ -n "${verdict_output}" ]]; then
        echo "${verdict_output}" >> "${VERDICTS_OUT}"
        log_progress "${SHA}" "OK     verdict appended"
        log_journal  "${SHA}" "ok"    "${verdict_output}"
    else
        log_progress "${SHA}" "WARN   verdict.py produced no output"
        log_journal  "${SHA}" "warn"  "verdict.py empty output"
    fi

    # ── Step 5: Reclaim disk — remove DBs and worktrees, keep SARIFs ──────────
    log_progress "${SHA}" "STEP5  cleanup DBs + worktrees"
    cleanup_worktrees "${WT_BEFORE}" "${WT_AFTER}"
    cleanup_dbs "${DB_BEFORE}" "${DB_AFTER}"
    rm -f "${QLS_FILE}" 2>/dev/null || true

    processed=$((processed + 1))
    log_progress "${SHA}" "DONE   processed=${processed} skipped=${skipped} failed=${failed}"

done

echo ""
echo "=== SUMMARY ==="
echo "  Jobs in worklist slice : ${job_count}"
echo "  Processed              : ${processed}"
echo "  Skipped (idempotent)   : ${skipped}"
echo "  Failed                 : ${failed}"
echo "  Verdicts file          : ${VERDICTS_OUT}"
