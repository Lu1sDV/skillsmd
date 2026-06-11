# Ruby Rule Authoring Guide (proven conventions)

Every convention here was **empirically verified** against the installed toolchain
(Semgrep 1.163.0, CodeQL 2.25.2 + `codeql/ruby-all@5.2.2`). Follow exactly — these
are the things that silently break the validation gate if you guess.

## Semgrep — the bulk engine (fast, deterministic gate)

**File layout (co-location is mandatory for `semgrep --test`):**
```
semgrep/<category>/ruby-<slug>.yaml     # the rule
semgrep/<category>/ruby-<slug>.rb       # SAME basename — the annotated test
```
`semgrep --test` pairs a rule with its test by **identical basename in the same
directory**. A `tests/` subdir does NOT auto-pair — do not use one.

**Test annotations** (in the `.rb`): put `# ruleid: <rule-id>` on the line
immediately ABOVE a line that SHOULD match, and `# ok: <rule-id>` above a line that
must NOT match. Ship at least one of each (a true positive AND a true negative —
the negative is what proves the rule isn't trivially over-broad).

> **GOTCHA (verified):** the strings `ruleid:` and `ok:` are parsed as annotations
> ANYWHERE they appear in a comment — including a prose header. Never write those
> tokens in explanatory comments or the test fails with "rule id mismatch". Describe
> the fixture without using the literal words.

**Rule schema (all fields required):**
```yaml
rules:
  - id: ruby-<category>-<slug>          # kebab, globally unique, matches filename stem
    languages: [ruby]
    severity: ERROR                     # ERROR | WARNING | INFO
    message: >
      Original wording. State the sink, the attacker-controlled input, the impact,
      and the safe alternative. Never copy a licensed pack's wording verbatim.
    metadata:
      vr-id: RB-SG-0001                 # assigned from backlog.json
      category: command-injection       # MUST be a taxonomy.yml key
      cwe: ["CWE-78"]
      owasp: "A03:2021"
      confidence: HIGH                   # HIGH | MEDIUM | LOW
      tier: B                            # A = diff-derived (oracle), B = catalog-derived
      source-citation: "GHSA-xxxx-…; inspired-by semgrep ruby.lang.security.x; gh-commit <sha>"
      license: derived-original
      references: ["https://…"]
      validated: { parses: true, tested: true }   # script sets the truth; author asserts intent
    patterns:
      - pattern: system("...#{...}...")
```

**Pattern tips that actually work in Ruby mode:**
- `"...#{...}..."` matches any interpolated string literal — the canonical injection tell.
- Use `$X.where("...#{...}...")` (metavar receiver) to catch ActiveRecord interpolation.
- Prefer `pattern-either` over one mega-pattern; add `pattern-not` for the safe form
  (e.g. parameterized `where("x = ?", v)`) so the `# ok:` case stays green.
- Validate locally: `semgrep --test semgrep/<category>` (must say "all tests passed").

## CodeQL — the precision engine (lower volume, ~2s warm / 70s cold compile)

**File layout:**
```
codeql/<category>/<Name>.ql
codeql/<category>/tests/<Name>/<Name>.ql        # copy or .qlref of the query
codeql/<category>/tests/<Name>/<Name>.expected  # accepted result rows
codeql/<category>/tests/<Name>/<fixture>.rb      # source the test DB is built from
```
`qlpack.yml` already declares `extractor: ruby` (REQUIRED — without it test
extraction fails). Run `codeql pack install` once; the compile cache is pre-warmed.

**Correct imports (verified — common mistakes noted):**
```ql
import codeql.ruby.AST
import codeql.ruby.DataFlow
import codeql.ruby.TaintTracking          // NOT codeql.ruby.taint.TaintTracking (does not resolve)
```

**Reuse a built-in flow when one exists** (preferred — highest precision):
```ql
import codeql.ruby.security.CommandInjectionQuery
import CommandInjectionFlow::PathGraph
from CommandInjectionFlow::PathNode source, CommandInjectionFlow::PathNode sink
where CommandInjectionFlow::flowPath(source, sink)
select sink.getNode(), source, sink, "message", source.getNode(), "detail"
```

**Custom taint config** (when no built-in fits) — modern module API:
```ql
private module Cfg implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node n) { /* … */ }
  predicate isSink(DataFlow::Node n)   { /* … */ }
  predicate isBarrier(DataFlow::Node n){ /* optional sanitizers */ }
}
module MyFlow = TaintTracking::Global<Cfg>;
import MyFlow::PathGraph
```

**Query metadata header (required):**
```ql
/**
 * @name Ruby <category> via <sink>
 * @description Original-wording flow + impact.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id rb/<category>-<slug>
 * @tags security external/cwe/cwe-078
 * @vr-id RB-QL-0001
 * @source-citation GHSA-xxxx; gh-commit <sha>
 * @license derived-original
 */
```
Validate locally: `codeql test run codeql/<category>` (build `.expected` by running
once, inspecting `.actual`, and accepting it if correct).

## Tier A vs Tier B
- **Tier A** (diff-derived, ~150–250): the pattern came from a real CVE fix commit.
  Also validate against the oracle DB pair — HIT @ `vuln_sha`, MISS @ `fix_sha`.
- **Tier B** (catalog-derived, ~750–850): original re-expression of a known sink
  pattern; validated by the synthetic test pair + (secondary) corpus scan.

## The non-negotiable
A rule is "done" ONLY when its test pair is green under the script gate
(`tools/validate_semgrep.sh` / `tools/validate_codeql.sh`). No green test → not counted.
