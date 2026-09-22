#!/usr/bin/env bash
# Memory-contained, self-measuring CodeQL Ruby database build.
#
# Wraps `codeql database create` in a transient systemd user scope with a hard
# MemoryMax and MemorySwapMax=0 (this host's zram swap runs near-full; an
# unbounded build OOM-killed the parent Claude Code process on 2026-06-11).
# A runaway build hits its own ceiling and is OOM-killed INSIDE its scope,
# leaving the orchestrator alive.
#
# It measures the build accurately via the scope's cgroup `memory.peak` (read
# from inside the scope before teardown) plus wall time, and appends one JSON
# record to the journal. OOM kills are distinguished from extractor errors via
# the cgroup `memory.events` oom_kill counter.
#
# Usage:
#   build_db.sh SRC_ROOT DB_DIR LABEL [MEM_MAX] [CODEQL_RAM_MB] [THREADS] [JOURNAL]
# Example:
#   build_db.sh ~/.../gitlab oracle/validation/dbs/HEAD head 6G 3500 2 oracle/validation/journal.jsonl
set -uo pipefail

SRC="${1:?source-root required}"
DB_DIR="${2:?db dir required}"
LABEL="${3:?label required}"
MEM_MAX="${4:-6G}"
CODEQL_RAM_MB="${5:-3500}"
THREADS="${6:-2}"
JOURNAL="${7:-/dev/null}"
CODEQL="${CODEQL_BIN:-/usr/local/bin/codeql}"

mkdir -p "$(dirname "$DB_DIR")"
RESULT_FILE="$(mktemp)"
trap 'rm -f "$RESULT_FILE"' EXIT

# Everything heavy runs inside the scope. The inner script reads the scope's own
# cgroup memory.peak + oom counter and writes a RESULT json to $RESULT_FILE.
/usr/bin/systemd-run --user --scope -q \
  -p MemoryMax="$MEM_MAX" -p MemorySwapMax=0 -p MemoryAccounting=yes \
  --unit="cqdb-${LABEL}" \
  -- bash -c '
    set -o pipefail
    SRC="$1"; DB_DIR="$2"; CODEQL="$3"; RAM="$4"; THREADS="$5"; RESULT_FILE="$6"
    cg="/sys/fs/cgroup$(awk -F: "/0::/{print \$3}" /proc/self/cgroup)"
    start=$(date +%s)
    rm -rf "$DB_DIR"
    "$CODEQL" database create "$DB_DIR" \
        --language=ruby --source-root="$SRC" \
        --ram="$RAM" --threads="$THREADS" --overwrite >/dev/null 2>"$DB_DIR.buildlog" || true
    rc=$?
    end=$(date +%s)
    peak=$(cat "$cg/memory.peak" 2>/dev/null || echo 0)
    oom=$(awk "/^oom_kill /{print \$2}" "$cg/memory.events" 2>/dev/null || echo 0)
    dbsz=$(du -sb "$DB_DIR" 2>/dev/null | cut -f1 || echo 0)
    printf "%s\n" "{\"rc\":$rc,\"wall_s\":$((end-start)),\"peak_bytes\":$peak,\"oom_kill\":${oom:-0},\"db_bytes\":${dbsz:-0}}" > "$RESULT_FILE"
  ' _ "$SRC" "$DB_DIR" "$CODEQL" "$CODEQL_RAM_MB" "$THREADS" "$RESULT_FILE"
scope_rc=$?

# Parse the inner result (absent => scope itself was OOM-killed before writing).
if [[ -s "$RESULT_FILE" ]]; then
  INNER=$(cat "$RESULT_FILE")
else
  INNER="{\"rc\":137,\"wall_s\":0,\"peak_bytes\":0,\"oom_kill\":1,\"db_bytes\":0}"
fi
rc=$(echo "$INNER" | sed -n 's/.*"rc":\([0-9-]*\).*/\1/p')
oom=$(echo "$INNER" | sed -n 's/.*"oom_kill":\([0-9]*\).*/\1/p')
db_ok=0; [[ -f "$DB_DIR/codeql-database.yml" ]] && db_ok=1

if [[ "$db_ok" == "1" && "${rc:-1}" == "0" ]]; then
  status="built"
elif [[ "${oom:-0}" -gt 0 || "${rc:-1}" == "137" ]]; then
  status="oom_kill"
else
  status="extractor_error"
fi

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
REC="{\"label\":\"$LABEL\",\"status\":\"$status\",\"src\":\"$SRC\",\"db\":\"$DB_DIR\",\"mem_max\":\"$MEM_MAX\",\"codeql_ram_mb\":$CODEQL_RAM_MB,\"threads\":$THREADS,\"scope_rc\":$scope_rc,\"inner\":$INNER,\"ts\":\"$TS\"}"
echo "$REC" | tee -a "$JOURNAL"
[[ "$status" == "built" ]]
