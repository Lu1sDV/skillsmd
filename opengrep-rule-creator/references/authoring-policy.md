# Authoring policy and decision record

Decisions on the user's proposed publication, anti-pattern, performance, and false-positive rules, recorded 2026-10-03. These govern **newly authored rules**, not the unmodified upstream examples archived for reference. “Accepted” keeps the requirement; “refined” keeps its intent while correcting an engine-specific or technical claim.

## Mandatory publication gates

1. **NEVER publish a rule without at least two distinct true-positive and two distinct true-negative test cases.** More cases are required for additional branches and boundaries. Two spellings of the same example are not adequate coverage. Annotate the reported line with `ruleid:` / `ok:` using `#` for Python/configuration or `//` for JavaScript, etc., and require the target engine's tests to pass. Out-of-scope or known-missed unsafe code may be documented separately, but does **not** count toward the two genuinely safe negatives.
2. **ALWAYS validate syntax before committing or publishing a rule.** For this OpenGrep-first skill, run `opengrep validate RULE.yaml` and inspect its full result: zero fatal/skippable errors, and the intended rule count. Then run `opengrep test --strict -c RULE.yaml FIXTURE` with the same analysis flags as the real scan. If Semgrep compatibility is also promised, additionally run `semgrep --validate --config RULE.yaml` and `semgrep --test --config RULE.yaml FIXTURE` on the declared Semgrep version. Neither engine's success proves the other's compatibility.
3. **NEVER set `metadata.confidence: HIGH` without testing against a representative real codebase and reviewing the results.** Passing tiny synthetic fixtures is necessary but insufficient. Use `LOW` for these educational examples. A real-codebase run is necessary, not automatically sufficient, for HIGH: document reviewed cases, remaining false positives, coverage limits, and why the signal merits that label.
4. **ALWAYS include WHAT, WHY, and HOW in every rule message.** Name the detected condition; explain its concrete consequence without inventing exploitability; state an actionable remediation. The words WHAT/WHY/HOW need not appear literally. A `fix` field does not replace a useful message.
5. **NEVER use `pattern-regex` as the primary matcher in an authored rule.** Start with language-specific structural `pattern` / `patterns` / `pattern-either` clauses and constrain bound values with `metavariable-regex`. For genuinely unsupported text formats, use generic **token patterns** as the explicit fallback, with documented lexical limitations. Generic matching is not a full language AST. Do not switch to whole-file regex to hide a missing parser or broken structural pattern.

### Offline authoring versus the commit gate

The local references, annotated tests, and local-config scans work without network access. Native OpenGrep 1.30.0 `validate` downloads registry lint rules; it is **not an offline command**. Run the mandatory validation gate in a network-enabled environment before committing/publishing. If validation cannot run, report the blocked gate and do not claim publication readiness; a local scan is not a silent substitute. The four current examples passed native `validate` with **4 rules, 0 fatal errors, and 0 skippable errors**. They are not labelled Semgrep-validated.

## Decisions on each requested hard rule

| User proposal | Decision | Applied rule and reason |
|---|---|---|
| Never publish without 2 TP + 2 TN | **Accepted, strengthened** | Require distinct cases and passing tests; known unsafe misses or unsupported inputs are not “true negatives.” |
| Always `semgrep --validate` before committing | **Refined for the requested engine** | OpenGrep validation is mandatory; preserve the exact Semgrep command as an additional gate for dual-engine claims. Using Semgrep alone can reject OpenGrep-specific features or miss OpenGrep behavior. Network requirements remain explicit. |
| Never HIGH confidence without a real-codebase test | **Accepted, strengthened** | Require review/calibration evidence, not merely having launched a scan. Severity and confidence are separate. |
| Every message contains WHAT, WHY, HOW | **Accepted** | Concrete finding, consequence, and remediation; qualify impact and bind every interpolated metavariable on every matching branch. |
| Never primary `pattern-regex` | **Accepted for authored rules** | Structural primary matching; regex constrains captured values. Archived upstream regex examples remain historical documentation, not recommended templates. |

## Anti-pattern decisions

| Anti-pattern | Decision | Why it fails / correct approach |
|---|---|---|
| Publishing untested rules | **Accepted** | False positives and silent misses erode trust. Write at least 2 TP + 2 TN, use language-correct `ruleid:` / `ok:` annotations, run native tests, then inspect a real scan. Use `semgrep --test` additionally when Semgrep compatibility is claimed. |
| HIGH confidence without validation | **Accepted, clarified metric** | Overconfident metadata misleads reviewers. Calibrate from reviewed results on representative code, record the sample and denominator, and keep confidence conservative when evidence is incomplete. |
| Vague messages | **Accepted** | A warning without a concrete fix path is not actionable. Include WHAT was found, WHY it matters, and HOW to remediate. Do not describe all hits as confirmed exploits. |
| Broad patterns with no exclusions | **Refined** | Narrow positive patterns first. Add `pattern-not` for same-range safe variants and `pattern-not-inside` for proven safe enclosing contexts when needed; use grounded sanitizers for taint. Do not mechanically add redundant negatives or suppress functions just because their names sound safe. |
| Primary regex matching | **Accepted policy; blanket speed claim rejected** | Raw text lacks language structure and is brittle across syntax/format changes. Regex is **not universally slower** than AST matching; cost depends on pattern, candidate set, engine and input. Structural primary matching plus constrained metavariables is this skill's precision policy, not a universal benchmark result. |

## Step 5: Rule optimization — decisions and practice

Optimize **after correctness**, preserve the positive/negative oracle, and re-run it after every simplification. Do not add operators merely to make a rule look sophisticated.

| Proposed best practice | Decision | Practical application |
|---|---|---|
| Specific patterns; avoid `$X($Y)` | **Accepted** | Name the actual API/construct and bind only needed roles. An unconstrained callable metavariable matches unrelated code and can enlarge candidate sets. Dynamic-call analysis is a separate, explicitly scoped problem. |
| `pattern-inside` to narrow context | **Accepted, qualified** | Use a necessary syntactic scope to improve precision. It does not guarantee a runtime speedup: the engine controls evaluation and may still search component patterns. Measure instead of assuming the YAML order is an execution plan. |
| Language-specific syntax | **Accepted** | Prefer a supported language parser, type/context syntax when useful, and structural argument matching. Generic token matching is only the explicit unsupported-format fallback. |
| Avoid deep ellipsis nesting | **Refined** | Use bounded, specific patterns; avoid unnecessary nested `...` / deep-expression searches. These can widen work and ambiguity, but `... ... ... is slow` is not a universal cost model. Keep deep matching only when a fixture proves it necessary and measure representative inputs. |
| `focus-metavariable` | **Accepted for location, not as a speed promise** | Narrow the finding/fix span or the relevant taint expression after matching. Focus does not inherently reduce the search space or make an expensive rule cheap. Test the resulting line/range and fix boundaries. |
| Test on large codebases | **Accepted, scoped to evidence** | Before claiming production-scale performance, use a representative large target; record repository revision, engine version, flags, hardware, selected files, wall time, timeouts/errors, and baseline comparison. A tiny fixture cannot establish scalability. |

### Reducing false positives

| Proposed practice | Decision | Practical application |
|---|---|---|
| `pattern-not` for safe patterns | **Accepted with range semantics** | Same-range subtraction only. Add a negative fixture for every meaningful exclusion. A nested safe context may need `pattern-not-inside`, not `pattern-not`. |
| `metavariable-regex` constraints | **Accepted** | Constrain values already captured structurally; anchor deliberately, account for quotes/whitespace, and test boundary spellings. Regex filtering is not a replacement for semantic validation. |
| `pattern-not-inside` for safe contexts | **Accepted with safety evidence** | Exclude only a context with a demonstrated contract. A function named `safe_*` or `test_*` is not proof. For taint, a return sanitizer and in-place validation have different effects. |
| Honest confidence | **Accepted** | Add `metadata.confidence`, use LOW without real-codebase calibration, and explain limits. Do not upgrade confidence because the message is severe, because a rule is complex, or because fixtures pass. |
| Technology metadata | **Accepted** | Include an accurate `metadata.technology` list for the actual language/framework/API; add category/CWE when applicable. Avoid inventing compatibility with unrelated stacks. |
| Fix suggestions and `fix` when possible | **Accepted with semantic gate** | Always give remediation in the message. Add a `fix` only when its behavior is justified; require a `.fixed` golden and dry-run inspection. Do not auto-change password-work-factor metadata, security semantics, or migration state without application context. |

## Calibration terminology

For a reviewed set of findings, report `TP`, `FP`, the reviewed count, and **precision = TP / (TP + FP)** (or false-discovery proportion `FP / (TP + FP)`). A statistical **false-positive rate = FP / (FP + TN)** also requires labelled negative opportunities and a defensible sampling frame; do not call the finding-only proportion that rate. Neither precision nor passing fixtures establishes recall without labelled missed positives. Record unknown/unreviewed cases separately.

## Decision summary

All requested safety gates and anti-pattern topics are included. Deliberate adjustments: target-engine validation instead of mandatory Semgrep-only validation; language-correct annotation comments; no counting unsafe misses as safe negatives; no universal regex/ellipsis speed claim; no promised performance gain from focus/scoping; no unsupported precision claim from a mere scan; no automatic fix when semantics need application knowledge.
