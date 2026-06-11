#!/usr/bin/env bash
# Build a minimal CodeQL Ruby oracle DB pair for one CVE WITHOUT cloning the repo.
# Ruby needs no build step, so a file subtree extracts cleanly.
#
# Strategy: fetch ONLY the files touched by the fix commit, at both the vulnerable
# parent (vuln_sha) and the fix (fix_sha), into two source trees, then
# `codeql database create` each. A query should HIT @vuln and MISS @fix.
#
# Usage:
#   tools/build_oracle_db.sh <slug> <github_owner/repo> <vuln_sha> <fix_sha>
# Produces:
#   oracle/dbs/<slug>/vuln/   (CodeQL DB at vuln_sha)
#   oracle/dbs/<slug>/fix/    (CodeQL DB at fix_sha)
set -euo pipefail
cd "$(dirname "$0")/.."   # -> rules/ruby

slug="$1"; repo="$2"; vuln="$3"; fix="$4"
api="https://api.github.com/repos/$repo"
raw="https://raw.githubusercontent.com/$repo"
work="oracle/dbs/$slug"
hdr=(-H "Accept: application/vnd.github+json")
[[ -n "${GITHUB_TOKEN:-}" ]] && hdr+=(-H "Authorization: Bearer $GITHUB_TOKEN")

# Files changed by the fix commit (limit to .rb).
mapfile -t files < <(curl -s "${hdr[@]}" "$api/commits/$fix" \
  | jq -r '.files[].filename' | grep -E '\.rb$' || true)
if [[ ${#files[@]} -eq 0 ]]; then echo "no ruby files touched by $fix"; exit 2; fi
echo "touched ruby files: ${#files[@]}"

fetch_tree() {  # <sha> <destdir>
  local sha="$1" dest="$2"
  for f in "${files[@]}"; do
    mkdir -p "$dest/$(dirname "$f")"
    curl -fsSL "${hdr[@]}" "$raw/$sha/$f" -o "$dest/$f" 2>/dev/null \
      || echo "  (absent @$sha: $f)"   # file may not exist at vuln parent (new file in fix)
  done
}

for variant in vuln fix; do
  sha=$([[ $variant == vuln ]] && echo "$vuln" || echo "$fix")
  src="$work/src-$variant"; db="$work/$variant"
  rm -rf "$src" "$db"; mkdir -p "$src"
  echo "== fetching $variant tree @ $sha =="
  fetch_tree "$sha" "$src"
  echo "== codeql database create ($variant) =="
  codeql database create "$db" --language=ruby --source-root="$src" --overwrite >/dev/null
done
echo "ORACLE DB READY: $work/{vuln,fix}"
