# Semgrep authoring → OpenGrep compatibility

Baseline: **OpenGrep v1.30.0**, release commit `acf67b45c97c4b63626536605c77064ef536806d`. OpenGrep forked Semgrep **1.100.0**, not the current Semgrep product. Read the bundled Semgrep writing-rules pages for syntax, then apply the version boundaries here. [Release feature overview](opengrep/v1.30.0/OPENGREP.md); [all snapshot sources and provenance](opengrep/INDEX.md).

**Evidence labels:** “Documented” means upstream prose or release source establishes the claim; it is not a runtime result. “Verified” means an observed result on the identified binary below; it applies only to the exercised case. Wiki comparisons with Semgrep 1.139.0 describe those examples, not equivalence with every Semgrep Pro release.

## Compatibility matrix

| Feature | v1.30.0 evidence / boundary | Authoring adaptation | Status |
|---|---|---|---|
| Classic search YAML | Release advertises Semgrep rule compatibility; classic parser retained | Keep ordinary structural patterns and metavariable constraints; regression-test matching/ranges | Verified for the compound KDF rule and generic structural Nginx rule; authoring policy forbids primary regex |
| Classic taint YAML | Parser accepts sources, sinks, sanitizers, propagators and label dependencies | Existing models may transfer unchanged, but test complete label/mutation interactions | Verified for lab 02's JOB → JOB + SHELL transition, boolean sink requirement, exactness and side effects |
| Same-file cross-function taint | `--taint-intrafile` in scan **and test** | Replace Semgrep `--pro-intrafile` with `--taint-intrafile`; test concrete object/callback shapes | Verified: lab 04 produces 2 findings with flag, 0 without; four negatives remain clear; two code-shape limitations below |
| Cross-file taint | Release scan CLI has **no `--taint-interfile` flag**; main-only docs introduce it later | Do not map Semgrep `--pro` / `--pro-interfile` to v1.30.0. A same-file flag does not supply cross-file analysis | Documented; verified rejection of `--taint-interfile` and `--pro-intrafile` |
| Experimental rule syntax | Native parser supports `match:` and `taint:` forms; upstream native tests use `all`/`any` | Not blanket-unsupported, but prefer classic YAML for portability; verify the exact nested operators before migrating | Documented; verified only for minimal `match:` equality |
| Join / cloud mode | Native `parse_mode` accepts search, taint, extract, step and dependency-only rules; other modes error | Do not promise native `mode: join` or `mode: cloud`. Legacy Python join code in the repo is **not** evidence that the shipped native CLI executes it | Documented; verified join probe yielded no usable rule; cloud unverified |
| Dependency / Supply Chain | Parser accepts dependency formulas; native targeting implements `package-lock.json` and contains explicit partial-implementation caveats | Parsing a dependency rule is not proof of correct ecosystem coverage, reachability or lockfile association. Verify those separately; do not advertise Semgrep Supply Chain parity | Documented partial implementation; unverified |
| Secrets | Search/regex rules can describe secret-like strings; native reporting notes absence of secret validators | Separate text detection from live credential validation, historical scans and cloud-backed product workflows; `--gitlab-secrets` is an **output format**, not a validation engine | Documented source boundary; unverified |
| Guarded signatures | Release scan flag and wiki describe opt-in branch-condition filtering | Explicitly pass `--experimental --guarded-taint-signatures --taint-intrafile` when evaluating; per-rule option `guarded_taint_signatures: true` is documented | Documented; unverified |
| Language coverage | Scan help names supported intrafile languages and says others fall back to intraprocedural analysis | A parser accepting a language is not evidence that cross-function analysis is supported | Documented; unverified |
| Autofix | `fix` works in the configuration lab; `fix-regex` depends on retained match metadata | A parsed `fix-regex` can silently produce no edit on synthetic matches; use a focused `fix` when equivalent and safe | Current configuration golden and actual copied-target fix pass; earlier regex-only/focused probes are recorded below |

Primary local evidence: [release README](opengrep/v1.30.0/README.md), [Scan_CLI.ml](opengrep/v1.30.0/src/osemgrep/cli_scan/Scan_CLI.ml), [Test_CLI.ml](opengrep/v1.30.0/src/osemgrep/cli_test/Test_CLI.ml), [Parse_rule.ml](opengrep/v1.30.0/src/parsing/Parse_rule.ml), [Core_runner.ml](opengrep/v1.30.0/src/osemgrep/core_runner/Core_runner.ml), [secret reporting](opengrep/v1.30.0/src/osemgrep/reporting/Matches_report.ml). See the [index](opengrep/INDEX.md) for original URLs and exact revisions.

## Commands: change the executable, not ordinary rules

Install a pinned release binary for your platform from the [upstream releases](https://github.com/opengrep/opengrep/releases/tag/v1.30.0), verify its published digest/signature, then check `opengrep --version`. The release [README](opengrep/v1.30.0/README.md) documents installation; [INSTALL.md](opengrep/v1.30.0/INSTALL.md) is for source builds. Avoid an unpinned `main/install.sh` download when reproducibility matters.

```sh
# A local rule file: no registry rule fetch; disable the version-check request.
opengrep scan --disable-version-check -c rules/example.yaml src/

# Preserve literal IDs when comparing JSON to ruleid fixture annotations.
opengrep scan --disable-version-check --no-rewrite-rule-ids \
  --json -c rules/example.yaml fixtures/example.py

# Annotated fixture tests (ruleid: / ok: directly above expected line).
opengrep test -c rules/example.yaml fixtures/example.py

# For a rule whose expectations depend on same-file cross-function flows:
opengrep scan --disable-version-check --taint-intrafile \
  --dataflow-traces -c rules/example.yaml fixtures/example.py
opengrep test --taint-intrafile -c rules/example.yaml fixtures/example.py
```

`scan` and `test` are different subcommands: do not assume every scan option is accepted by test. v1.30.0 test has `--taint-intrafile`, `--json`, `--strict`, `--matching-diagnosis` and TODO-annotation control; a file target needs `-c`, and multiple files require exactly one config. Multiple targets are not automatically a cross-file test. Scan's legacy `--test` route also forwards the intrafile setting. [Test CLI](opengrep/v1.30.0/src/osemgrep/cli_test/Test_CLI.ml); [Scan CLI](opengrep/v1.30.0/src/osemgrep/cli_scan/Scan_CLI.ml).

## Taint knobs: do not rewrite useful models blindly

The release [taint parser](opengrep/v1.30.0/src/parsing/Parse_rule.ml) implements these classic fields; spell out important defaults so a Semgrep-doc update does not silently change your intent:

| Location | Supported fields / release defaults | Rule-design consequence |
|---|---|---|
| Source | `exact: false`; `by-side-effect: false`; `label`; `requires`; `control: false` | Explicit `exact: true` limits source matching to the selected expression. Labels are identifiers, not metavariables; `requires` uses `and`, `or`, `not` over labels |
| Sink | `exact: true`; `requires`; `at-exit: false` | Focus the dangerous argument when the whole call would include unrelated tainted data; explicitly choose `exact: false` only when needed |
| Sanitizer | `exact: false`; `by-side-effect: false`; `not-conflicting` | Exactness and in-place sanitization are separate choices; a narrowly focused sanitizer avoids sanitizing unrelated subexpressions |
| Propagator | `from`, `to`; `by-side-effect: true`; optional `label`, `requires`, `replace-labels` | Bind the appropriate metavariables and retain explicit collection/library models where needed; `by-side-effect: false` changes propagation behavior |

For an in-place source/sanitizer, use `patterns` with `focus-metavariable: $X` to identify the mutated l-value, rather than tainting/sanitizing the entire call. Add a fixture with a later read of `$X` and a clean neighboring argument to expose overbroad modeling. A supported parser key does not prove every sophisticated combination's dataflow behavior; run annotated fixtures for labels, exactness, mutation and propagation together.

OpenGrep has documented **built-in collection methods**: mutators taint receivers and accessors carry receiver taint to return values. Intrafile mode can therefore change findings even without rule changes. Consult [Methods that taint](opengrep/wiki/Methods-that-taint.md), [higher-order functions](opengrep/wiki/Higher-order-functions-tutorial.md), and [intrafile examples](opengrep/wiki/Intrafile-tainting-tutorial.md) before adding a redundant propagator. Keep a custom propagator for an unmodeled API or when your fixture establishes that the built-in behavior is insufficient. The wiki's list is not a guarantee that every same-named method has library-accurate type semantics.

## Intrafile is not Semgrep Pro or main's interfile engine

The v1.30.0 scan/test CLI lists intrafile support for Apex, C, Clojure, C#, C++, Dart, Elixir, Go, Java, JavaScript, Julia, Kotlin, Lua, Python, Ruby, Rust, Scala, Swift, TypeScript and Visual Basic. **PHP is not in that list**: modern PHP parser support is not proof of cross-function taint support. Unsupported languages fall back to intraprocedural analysis. [Scan flag definition](opengrep/v1.30.0/src/osemgrep/cli_scan/Scan_CLI.ml); [PHP notes](opengrep/wiki/Support-for-Php.md).

For ordinary taint rules, enable same-file analysis with the CLI flag and retain source/sink YAML. If translating a Pro-dependent rule, identify the required flow first: two methods in one file may fit intrafile; imports across files do not. Semgrep-specific CLI flags, licensing/authentication steps or metadata declaring `interfile: true` do not install a missing engine.

The **post-v1.30.0 main snapshot** documents `--taint-interfile`, `--taint-interfile-depth`, `options.taint_interfile`, and an `options.interfile` alias, plus graph tools. It describes OR-combination of global/per-rule enablement, max-combination of depth and implication of intrafile. Those are **main-only documentation**, not released behavior here. Its sample `opengrep scan --taint-interfile <rules> <target>` is upstream prose; when a future binary supports the flag, use explicit `-c RULES` and confirm its help. [Main interfile CLI](opengrep/main-interfile/05-cli-and-tools.md); [architecture](opengrep/main-interfile/README.md). The release's accepted `--interfile-timeout` option alone does **not** prove an interfile engine exists.

### Observed constructor/callback boundaries in the complex example

In the current Python job pipeline, initializing `self.pending = []` and then calling `self.pending.append(command)` in the constructor lost both expected unsafe flows. A boundary probe still detected the source-factory return, normalization helper, and direct higher-order calls, but not reads of the queue field or its method. Initializing `self.pending = [command]` preserved the field taint and both unsafe paths.

With the latter constructor, a `map` lambda calling `shell_exec(checked_command(command), ...)` produced a false positive although `checked_command` calls the defined allowlist. Calling the directly modelled `allowlisted_command` inside that lambda kept the safe path clear. The separate named callback still exercises the wrapper's inferred safe return. No custom source-on-caller, broad sanitizer, or path exclusion hides either limitation.

These are concrete native 1.30.0 observations, not a general promise about constructor side effects or callbacks. The [fixture](../examples/04-intrafile/intrafile.py) comments explain the supported forms. Do not rewrite production code solely to appease the scanner or claim the original unsafe/safe shapes are equivalent in analysis.


## Autofix and generic-capture traps found during verification

During initial compatibility probes, a regex-only configuration rule detected both `false` values but generated **no `fix-regex` edit**, including with the minimal replacement `regex: false`, `replacement: true`. A focused password-expression rule also lost its regex fix. A simple AST-backed `logging.warn(...)` probe applied `fix-regex` correctly. **Do not classify all regex fixes as unsupported or all AST rules as safe.** These are historical probes, not primary-regex templates: the current authoring policy requires structural matching. Current lab 03 focuses its structural `$VERIFY` binding and uses `fix: 'on'`; its golden preserves surrounding configuration.

Release-source explanation: [Xpattern_matcher](opengrep/v1.30.0/src/engine/Xpattern_matcher.ml) creates synthetic rule IDs for text matches; [range conversion](opengrep/v1.30.0/src/engine/Range_with_metavars.ml) restores `fix` but does not restore `fix_regexp`. [Autofix.render_fix](opengrep/v1.30.0/src/fixing/Autofix.ml) reads the retained `fix_regexp` field. Test the complete rule, not a bare syntax probe.

An earlier generic-token probe retained leading whitespace in `API_TOKEN = value`, unlike the no-space assignment; a directly alphanumeric-anchored filter missed that case. Current lab 03 similarly permits horizontal whitespace around `$...UPSTREAM`, forbids internal whitespace/semicolons, and uses a documented 20-line span for multiline patterns. Generic nesting is primarily indentation-based, **not** a complete Nginx brace parser; the sibling/nested negatives exercise the fixture's formatting, not every valid configuration layout.


## Offline operation, targets and limits

- Use local `-c` files/directories for offline authoring. `auto`, registry packs, URLs and remote git configs fetch rules; disable version checks with `--disable-version-check`. **The publication gate is separate:** `opengrep validate` fetches `p/semgrep-rule-lints` in 1.30.0. The earlier refused-proxy probe failed with exit 2; network-enabled validation of the current four examples passed with zero fatal/skippable errors. Run the mandatory gate before committing/publishing or report it blocked—do not silently substitute a local scan. [Policy decision](authoring-policy.md); [scan definitions](opengrep/v1.30.0/src/osemgrep/cli_scan/Scan_CLI.ml).
- Keep `.semgrepignore`: that remains the default filename despite the executable rename. A custom filename is documented through `--experimental --semgrepignore-filename=NAME`; no automatic `.opengrepignore` migration is promised. `--no-git-ignore` disables Git ignore filtering, **not** `.semgrepignore`. The internal `--x-ignore-semgrepignore-files` flag is unstable and not a portable workflow. `--force-exclude` applies include/exclude filtering to explicit file targets. [Release overview](opengrep/v1.30.0/OPENGREP.md); [target flags](opengrep/v1.30.0/src/osemgrep/cli_scan/Scan_CLI.ml).
- Findings can be suppressed by `nosem`, `nosemgrep`, `noopengrep` and an optional `--opengrep-ignore-pattern` prefix. Use `--disable-nosem` only deliberately when inspecting suppressed results. The rule's `paths`, language/extension selection, include/exclude filters and file-size cap can also explain an absent finding. [Scan flags](opengrep/v1.30.0/src/osemgrep/cli_scan/Scan_CLI.ml).
- Inspect scan errors and skipped-target reporting, not only the finding count. `--timeout`, `--timeout-threshold`, `--max-memory`, `--max-target-bytes` and `--max-match-per-file` bound work. Zero timeout/memory disables those limits; nonpositive maximum target bytes disables size filtering. The documented 10,000 match-per-file limit discards that target's matches when exceeded before deduplication: it is not ordinary pagination. Per-rule timeouts require `--allow-rule-timeout-control` and a positive CLI timeout. `taint-fixpoint-timeout` is documented as deprecated/no longer operative; do not add it as a fix for missing flows. [Scan definitions](opengrep/v1.30.0/src/osemgrep/cli_scan/Scan_CLI.ml); [release changes](opengrep/v1.30.0/OPENGREP.md).
- Intrafile implementation documents incomplete mutual-recursion handling (arbitrary cyclic ordering); the wiki demonstrates an inheritance false negative. Treat these as documented limits of those snapshots, not an exhaustive bug list. Add a focused fixture for dynamic calls, recursive wrappers, constructors or inheritance relied on by your rule. [Implementation](opengrep/v1.30.0/docs/INTRA_FUNCTION_IMPLEMENTATION.md); [wiki limitations](opengrep/wiki/Intrafile-tainting-tutorial.md).

## Verification results for the selected binary

Observed on 2026-10-03: Linux x86-64 release asset `opengrep_manylinux_x86`, version output `1.30.0`, SHA-256 `35779bdd72e92129c8df2a77f0c55e8c08356801ea92591ef32108d6b28d564c`, checked against the GitHub digest:

| Probe | Observed result |
|---|---|
| Classic `pattern: $X == $X` | Exit 0, one finding on `x == x`, no errors |
| Experimental `match: $X == $X` | Exit 0, one finding on `x == x`, no errors |
| Scan `--pro-intrafile` / `--taint-interfile` | Each exit 2, unknown option |
| Native `mode: join`, also with `--strict` | Exit 7, generic no-config JSON; no usable rule. No parse-specific diagnostic is claimed |
| `opengrep validate LOCAL.yaml` with HTTP/HTTPS proxy `http://127.0.0.1:9` | Exit 2; attempted Semgrep rule-lint config download and reported connection refusal |
| Current four complex examples under `unshare --user --map-root-user --net` | 4/4 rule tests and the configuration golden passed; real scans produced exactly 17 expected finding locations, excluded all 26 `ok` annotations, and reported zero scan errors |
| Current intrafile example without / with `--taint-intrafile` | 0 / 2 findings; all four negative sites clear |
| Current configuration autofix | `--dryrun` preserved the copied target; actual `--autofix` equalled the golden byte-for-byte |
| Current examples: `opengrep validate examples/`, network enabled | Configuration valid: 4 rules, 0 fatal errors, 0 skippable errors |
| Regex-only and focused `fix-regex` probes | Findings returned without edits; simple AST-backed regex fix worked. See the source explanation above |

Unexercised boundaries include guarded-signature conditions, languages beyond the demonstrated Python/generic code and earlier regex probes, cloud/secrets/SCA workflows, and the post-release interfile engine. Ignore behavior is documented from release source rather than independently exhaustively tested. Synthetic fixture success is not real-codebase confidence calibration or a large-codebase performance benchmark.

These checks establish compatibility for the exercised rule families, not blanket parity with newer Semgrep documentation or commercial/cloud workflows.
