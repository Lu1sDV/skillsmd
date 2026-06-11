#!/usr/bin/env bash
# Deterministic Semgrep validation gate (PRIMARY).
# 1) `semgrep --validate` on every rule (must parse).
# 2) `semgrep --test` over the co-located annotated test pairs (must pass).
# Optional: `--corpus <dir>` to also record real-code hit counts (SECONDARY signal).
#
# Usage:
#   tools/validate_semgrep.sh                 # validate + test all semgrep/ rules
#   tools/validate_semgrep.sh semgrep/sql-injection   # scope to one category
#   tools/validate_semgrep.sh --corpus corpus semgrep/
set -euo pipefail
cd "$(dirname "$0")/.."   # -> rules/ruby

CORPUS=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --corpus) CORPUS="$2"; shift 2;;
    *) ARGS+=("$1"); shift;;
  esac
done
TARGET="${ARGS[0]:-semgrep}"

echo "== semgrep --validate ($TARGET) =="
# --validate checks rule syntax/schema for every yaml under TARGET
fail=0
while IFS= read -r -d '' rule; do
  if ! semgrep --validate --config "$rule" >/dev/null 2>&1; then
    echo "  INVALID: $rule"; fail=1
  fi
done < <(find "$TARGET" -name '*.yaml' -print0)
[[ $fail -eq 0 ]] && echo "  all rules parse" || { echo "VALIDATE FAILED"; exit 1; }

echo "== semgrep --test ($TARGET) =="
semgrep --test "$TARGET"

if [[ -n "$CORPUS" && -d "$CORPUS" ]]; then
  echo "== corpus scan (secondary): $CORPUS =="
  semgrep --config "$TARGET" "$CORPUS" --json 2>/dev/null \
    | jq -r '.results | group_by(.check_id) | .[] | "\(length)\t\(.[0].check_id)"' \
    | sort -rn || true
fi
echo "SEMGREP GATE PASSED"
