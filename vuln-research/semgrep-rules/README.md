# semgrep-rules/

Custom Semgrep packs maintained alongside the `vuln-research` skill. **One merged pack per
technology** — the file name is `<technology>-sinks.yaml`, matching its human catalog
`references/sinks/<technology>.md`.

| Pack | Rules | Mirror doc | Validated |
|---|---|---|---|
| `php/php-sinks.yaml` | 439 | `references/sinks/php.md` | `semgrep --validate` clean |
| `c-cpp/c-cpp-sinks.yaml` | 555 | `references/sinks/c-cpp.md` | `semgrep --validate` clean |

## Mirror rule (load-bearing)

Pack and doc are **one artifact in two forms** and are edited together:

- `references/sinks/<tech>.md` — human catalog: taxonomy, sink classes, DuckDB normalization,
  severity heuristics, version gotchas, PoC notes. Loaded by the agent at Phase L3.5.
- `semgrep-rules/<tech>/<tech>-sinks.yaml` — executable detectors: rule ids, patterns,
  severity, `vuln-research-domain` metadata. Run at Phase 0 (callsite enumeration),
  Phase L4.5 (FP calibration) and ingested into the run DB.

When the doc gains a sink class, the pack gains a rule (and vice versa). Neither replaces
the other: ~50-60% of the doc's identifiers have no expressible static pattern, and the
rules encode taint shapes a name list cannot.

## Canonical command set

```bash
# Triage-grade PHP scan (lowest noise)
semgrep --config=p/ci --config=p/phpcs-security-audit --config=r/php.lang.security \
        --config=semgrep-rules/php/php-sinks.yaml --sarif --output semgrep-ci.sarif .

# Deeper manual audit
semgrep --config=p/security-audit --config=p/phpcs-security-audit --config=r/php.lang.security \
        --config=semgrep-rules/php/php-sinks.yaml --config=p/trailofbits \
        --sarif --output semgrep-audit.sarif .

# C/C++ scan — custom pack on top of the curated C/C++ baseline
semgrep --config=p/c --config=r/c.lang.security --config=semgrep-rules/c-cpp/c-cpp-sinks.yaml \
        --sarif --output semgrep-c-cpp.sarif .

# Validate the packs themselves (CI gate)
semgrep --validate --config semgrep-rules/php/php-sinks.yaml
semgrep --validate --config semgrep-rules/c-cpp/c-cpp-sinks.yaml

# Scan sample (intentionally vulnerable; checks that rules still fire)
semgrep --config semgrep-rules/php/php-sinks.yaml --no-git-ignore \
        semgrep-rules/php/tests/php-sinks.php
```

## Merge provenance

The packs were merged from the previous split files
(`php-security-mega-pack.yaml`, `php-gap-sinks.yaml`, `php-additional-sinks.yaml`,
`c-cpp-security-mega-pack.yaml`, `c-cpp-gap-sinks.yaml`) with duplicate rule ids collapsed
(richer definition wins) and upstream rules repaired so the file validates as a whole.
`cat semgrep-rules/<tech>/<tech>-sinks.yaml` header carries the exact repair/drop ledger,
including which repaired rules are parse-valid but not yet fire-verified.

**Rule-authorship protocol** (target-specific additions, location choice, metadata contract):
`references/methodology/semgrep-rule-authoring.md`. Upstream C/C++ pack provenance:
`references/methodology/0xdea-semgrep-rules.md`.
