#!/usr/bin/env bash
# Deterministic CodeQL validation gate.
# 1) `codeql query compile` on every .ql (must compile).
# 2) `codeql test run` over the co-located query tests (must pass).
#
# Cold compile of the ruby dataflow library is ~70s ONCE; warm runs ~2s/test.
# Run tools/warm_codeql.sh first if the cache is cold.
#
# Usage:
#   tools/validate_codeql.sh                  # compile + test all codeql/ queries
#   tools/validate_codeql.sh codeql/sql-injection
set -euo pipefail
cd "$(dirname "$0")/.."          # -> rules/ruby
TARGET="${1:-codeql}"

echo "== codeql pack install =="
( cd codeql && codeql pack install >/dev/null 2>&1 ) || true

echo "== codeql query compile ($TARGET) =="
# Compile only authored queries, not the test fixtures' copies.
mapfile -t qls < <(find "$TARGET" -name '*.ql' -not -path '*/tests/*')
if [[ ${#qls[@]} -gt 0 ]]; then
  codeql query compile --check-only --threads=0 "${qls[@]}"
else
  echo "  (no queries yet)"
fi

echo "== codeql test run ($TARGET) =="
if find "$TARGET" -path '*/tests/*' -name '*.ql' | grep -q .; then
  codeql test run --threads=0 "$TARGET"
else
  echo "  (no query tests yet)"
fi
echo "CODEQL GATE PASSED"
