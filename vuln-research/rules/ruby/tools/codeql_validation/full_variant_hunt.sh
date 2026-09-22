#!/usr/bin/env bash
# Full variant hunt: run every EXISTING dataflow query (10 categories) against the
# HEAD DB, one category at a time so a per-query Java-heap OOM stays isolated
# (a whole-suite OOM produces no SARIF; per-category keeps the rest).
# Heap fix vs the earlier rails-misc OOM: --ram=12000 (Xmx ~4.4G) instead of 4000.
set -uo pipefail
cd /home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby

CATS="code-injection command-injection crypto-tls deserialization hardcoded-secrets insecure-randomness open-redirect path-traversal rails-misc xss"
DB=oracle/validation/dbs/HEAD
MEM=14G; RAM=12000; THR=2
JOURNAL=oracle/validation/journal.jsonl
mkdir -p oracle/validation/sarif

SARIFS=()
for cat in $CATS; do
  # build a suite of TOP-LEVEL .ql only (exclude tests/ copies) at the pack root so
  # `- query: <cat>/<file>.ql` resolves relative to the suite dir (codeql/).
  suite="codeql/_hunt-$cat.qls"
  : > "$suite"
  for q in codeql/"$cat"/*.ql; do
    [ -f "$q" ] || continue
    echo "- query: ${q#codeql/}" >> "$suite"
  done
  nq=$(wc -l < "$suite")
  out="oracle/validation/sarif/HEAD-$cat.sarif"
  echo "[$(date -u +%H:%M:%S)] HUNT $cat ($nq queries) -> $out"
  bash tools/codeql_validation/analyze.sh "$DB" "$suite" "$out" "$MEM" "$RAM" "$THR" "$JOURNAL" 2>&1 | tail -2
  [ -f "$out" ] && SARIFS+=("$out") && echo "   OK $cat" || echo "   FAILED $cat (no SARIF — see $out.log)"
  rm -f "$suite"
done

echo "[$(date -u +%H:%M:%S)] PARSING ${#SARIFS[@]} category SARIFs -> variants-existing.jsonl"
if [ "${#SARIFS[@]}" -gt 0 ]; then
  python3 tools/codeql_validation/sarif_to_findings.py "${SARIFS[@]}" \
    --out oracle/validation/variants-existing.jsonl \
    --md oracle/validation/variants-existing.md --exclude-tests
fi
echo "[$(date -u +%H:%M:%S)] FULL VARIANT HUNT DONE (${#SARIFS[@]}/10 categories produced SARIF)"
