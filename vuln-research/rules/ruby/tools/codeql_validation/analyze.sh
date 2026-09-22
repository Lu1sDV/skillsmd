#!/usr/bin/env bash
# Memory-contained `codeql database analyze` for variant hunting / validation.
# Runs a query (or query dir/suite) against an existing DB and writes SARIF.
#
# Usage: analyze.sh DB_DIR QUERIES OUT_SARIF [MEM_MAX] [RAM_MB] [THREADS] [JOURNAL]
#   QUERIES = a .ql file, a directory of .ql, or a .qls suite.
set -uo pipefail
DB="${1:?db dir}"; Q="${2:?queries}"; OUT="${3:?out sarif}"
MEM_MAX="${4:-8G}"; RAM_MB="${5:-4500}"; THREADS="${6:-3}"; JOURNAL="${7:-/dev/null}"
CODEQL="${CODEQL_BIN:-/usr/local/bin/codeql}"
mkdir -p "$(dirname "$OUT")"
LABEL="analyze-$(basename "$DB")-$(basename "$Q" | tr '/.' '__')"
RESULT_FILE="$(mktemp)"; trap 'rm -f "$RESULT_FILE"' EXIT

/usr/bin/systemd-run --user --scope -q \
  -p MemoryMax="$MEM_MAX" -p MemorySwapMax=0 -p MemoryAccounting=yes --unit="$LABEL" \
  -- bash -c '
    set -o pipefail
    DB="$1"; Q="$2"; OUT="$3"; CODEQL="$4"; RAM="$5"; THREADS="$6"; RESULT_FILE="$7"
    cg="/sys/fs/cgroup$(awk -F: "/0::/{print \$3}" /proc/self/cgroup)"
    start=$(date +%s)
    "$CODEQL" database analyze "$DB" "$Q" \
        --format=sarif-latest --output="$OUT" \
        --ram="$RAM" --threads="$THREADS" --rerun >"$OUT.log" 2>&1
    rc=$?
    end=$(date +%s)
    peak=$(cat "$cg/memory.peak" 2>/dev/null || echo 0)
    oom=$(awk "/^oom_kill /{print \$2}" "$cg/memory.events" 2>/dev/null || echo 0)
    printf "{\"rc\":%s,\"wall_s\":%s,\"peak_bytes\":%s,\"oom_kill\":%s}\n" "$rc" "$((end-start))" "$peak" "${oom:-0}" > "$RESULT_FILE"
  ' _ "$DB" "$Q" "$OUT" "$CODEQL" "$RAM_MB" "$THREADS" "$RESULT_FILE"
scope_rc=$?
INNER=$([ -s "$RESULT_FILE" ] && cat "$RESULT_FILE" || echo "{\"rc\":137,\"wall_s\":0,\"peak_bytes\":0,\"oom_kill\":1}")
rc=$(echo "$INNER" | sed -n 's/.*"rc":\([0-9-]*\).*/\1/p')
status=$([ -f "$OUT" ] && [ "${rc:-1}" = "0" ] && echo "analyzed" || echo "analyze_error")
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "{\"label\":\"$LABEL\",\"status\":\"$status\",\"db\":\"$DB\",\"queries\":\"$Q\",\"sarif\":\"$OUT\",\"scope_rc\":$scope_rc,\"inner\":$INNER,\"ts\":\"$TS\"}" | tee -a "$JOURNAL"
[ "$status" = "analyzed" ]
