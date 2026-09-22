#!/usr/bin/env bash
# Dataflow variant hunt over the existing 32 queries, ONE query per analyze with the
# proven big-heap recipe: --off-heap-ram=512 forces ~15G of the --ram budget into the JVM
# heap (CodeQL otherwise spends surplus RAM off-heap, leaving only ~2.7G heap → OOM on
# whole-program taint over the 7.9M-LOC HEAD DB). Verified: ReflectedXss completes this way.
# Serial (host fits one 15G-heap query at a time); continue-on-failure; lighter cats first.
set -uo pipefail
cd /home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby
DB=oracle/validation/dbs/HEAD
MEM=16G; RAM=14800; OFFHEAP=512; THR=4   # ~14.3G heap; leaves host margin over a multi-hour run
JOURNAL=oracle/validation/journal.jsonl
# lighter/cheaper taint configs first so early results land even if interrupted
CATS="path-traversal open-redirect insecure-randomness hardcoded-secrets crypto-tls deserialization code-injection command-injection rails-misc xss"
mkdir -p oracle/validation/sarif oracle/validation/logs
SARIFS=()
for cat in $CATS; do
  for q in codeql/"$cat"/*.ql; do
    [ -f "$q" ] || continue
    name=$(basename "$q" .ql)
    out="oracle/validation/sarif/HEAD-df-$cat-$name.sarif"
    LABEL="df-$cat-$name"
    echo "[$(date -u +%H:%M:%S)] HUNT $cat/$name"
    systemd-run --user --scope -q -p MemoryMax=$MEM -p MemorySwapMax=0 -p MemoryAccounting=yes --unit="$LABEL" -- \
      codeql database analyze "$DB" "$q" --format=sarif-latest --output="$out" \
      --ram=$RAM --off-heap-ram=$OFFHEAP --threads=$THR --rerun > "$out.log" 2>&1
    rc=$?
    if [ -f "$out" ]; then SARIFS+=("$out"); echo "   OK rc=$rc"; else echo "   FAIL rc=$rc (heap/other — see $out.log)"; fi
    echo "{\"q\":\"$cat/$name\",\"rc\":$rc,\"sarif\":$([ -f "$out" ] && echo true || echo false),\"ts\":\"$(date -u +%FT%TZ)\"}" >> "$JOURNAL"
  done
done
echo "[$(date -u +%H:%M:%S)] PARSING ${#SARIFS[@]} SARIFs -> variants-existing.jsonl"
if [ "${#SARIFS[@]}" -gt 0 ]; then
  python3 tools/codeql_validation/sarif_to_findings.py "${SARIFS[@]}" \
    --out oracle/validation/variants-existing.jsonl \
    --md oracle/validation/variants-existing.md --exclude-tests
fi
echo "[$(date -u +%H:%M:%S)] DATAFLOW HUNT DONE (${#SARIFS[@]} queries produced SARIF)"
