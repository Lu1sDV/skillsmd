# Ruby Rule MegaDB

A publishable library of original-wording Ruby security detection rules — Semgrep
`.yaml` + CodeQL `.ql` — each carrying a citation and a green test pair. Part of the
`vuln-research` skill; indexed by `manifest.json` and linked from
`references/sinks/ruby.md`.

See `ARCHITECTURE.md` for the build design and `AUTHORING_GUIDE.md` for the
**verified** Semgrep/CodeQL conventions (read it before authoring — it documents the
exact toolchain gotchas).

## Layout

```
semgrep/<category>/ruby-<slug>.yaml   + ruby-<slug>.rb   (co-located test)
codeql/<category>/<Name>.ql           + tests/<Name>/     (query test)
codeql/qlpack.yml                     depends on codeql/ruby-all, extractor: ruby
oracle/cve-commits.json               CVE/GHSA -> {repo, vuln_sha, fix_sha, category}
taxonomy.yml                          canonical categories (rule.category MUST be a key)
backlog.json                          de-duped rule specs that drive authoring [generated]
manifest.json                         index over authored rules               [generated]
corpus/  dbs/  oracle/dbs/            large validation inputs (git-ignored)
tools/                                validation + manifest + oracle scripts
```

## Validate (the gate — a rule counts only when its test is green)

```bash
tools/validate_semgrep.sh                 # validate + test all Semgrep rules
tools/validate_semgrep.sh semgrep/sql-injection
tools/validate_semgrep.sh --corpus corpus semgrep/   # + real-code hit counts

tools/validate_codeql.sh                  # compile + test all CodeQL queries
ruby tools/gen_manifest.rb                # write manifest.json
ruby tools/gen_manifest.rb --check        # CI: fail if any rule lacks metadata/test
```

## Requirements

Semgrep ≥ 1.16, CodeQL ≥ 2.25 with `codeql/ruby-all` + `codeql/ruby-queries` packs
installed (`codeql pack download codeql/ruby-all codeql/ruby-queries`), Ruby ≥ 3 and
`jq` for the manifest/corpus tooling.

## Provenance

- **Tier A** — derived from real CVE fix commits; validated against an oracle DB pair
  (HIT @ vulnerable commit, MISS @ fix commit).
- **Tier B** — original re-expressions of known sink patterns; validated by synthetic
  test pairs and a secondary corpus scan.

All wording is original (`license: derived-original`); rules cite their inspiration
(GHSA, commit SHA, or the public pattern they re-express) but copy no licensed text.
