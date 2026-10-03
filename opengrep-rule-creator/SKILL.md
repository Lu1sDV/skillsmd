---
name: opengrep-rule-creator
description: >
  Use when creating, testing, or debugging custom OpenGrep YAML rules, porting
  Semgrep rules to OpenGrep, or modelling sources, sinks, sanitizers, and taint
  propagators. Includes offline rule-writing documentation and commented
  experiments for structural matching, taint, generic text, and intrafile analysis.
---

# OpenGrep Rule Creator

Create a precise detection, prove both its matches and exclusions, then run it on real code. Adapted from Trail of Bits' test-first rule-creator workflow; [attribution and license](ATTRIBUTION.md).

Use **OpenGrep**, not an installed `semgrep` binary as a substitute. This package's baseline is **OpenGrep 1.30.0**. The inline OpenGrep essentials below state the relevant limits; supplementary references provide deeper evidence.

## Quick reference

Run from the directory containing the rule and its fixture. Replace `my-rule` and the extension with the actual names.

| Purpose | Command |
|---|---|
| Record engine | `opengrep --version` |
| Required pre-commit syntax gate (network needed in 1.30.0) | `opengrep validate my-rule.yaml` |
| Additional gate when Semgrep compatibility is promised | `semgrep --validate --config my-rule.yaml` |
| Test local rule | `opengrep test --strict -c my-rule.yaml my-rule.py` |
| Test same-file cross-function flow | `opengrep test --strict --taint-intrafile -c my-rule.yaml my-rule.py` |
| Inspect parsed syntax | `opengrep scan --dump-ast --lang python my-rule.py` |
| Run and inspect findings | `opengrep scan --disable-version-check --strict --no-rewrite-rule-ids -c my-rule.yaml my-rule.py` |
| Explain taint findings | `opengrep scan --disable-version-check --taint-intrafile --dataflow-traces -c my-rule.yaml my-rule.py` |
| Machine-readable output | Add `--json` or `--sarif` to `scan` |
| Preview a fix without writing | Add `--autofix --dryrun` to `scan` |

Use local `-c` paths. `--config auto`, registry packs, remote configurations, playgrounds, and hosted services are **not** the offline authoring workflow. OpenGrep 1.30.0 validation fetches registry lint rules: run the mandatory pre-commit/publication gate with network access, or report it blocked and do not publish. A local scan is not a silent substitute. Scan success alone does not prove a finding exists: inspect results, scanned files, and errors. `scan --error` deliberately exits nonzero on findings.

## OpenGrep essentials

The four complete examples below are part of this skill, not deferred reading. Use native **OpenGrep 1.30.0** as the verified baseline; do not substitute an installed Semgrep binary.

- Classic structural and taint YAML is shared, but matching/dataflow behavior must be tested on the actual engine.
- `--taint-intrafile` enables same-file cross-function analysis in both `scan` and `test`. The verified 1.30.0 binary rejects `--taint-interfile` and Semgrep's `--pro-intrafile`; newer main-branch interfile docs are not released-version guarantees.
- Local tests/scans work offline. Native `validate` fetches registry lint rules, so the mandatory publication gate needs network access.
- `.semgrepignore` remains the default filename; `--no-git-ignore` does not disable it. Inspect scanned targets and errors, not just exit status.
- Use `--no-rewrite-rule-ids` when comparing scan output with literal fixture IDs.
- Native 1.30.0 can lose `fix-regex` metadata on synthetic/focused matches. Test actual edits; use a focused ordinary `fix` only when equivalent and semantically safe.
- Parser acceptance, Semgrep Pro badges, or a copied rule do not prove engine support. Guarded signatures, join/cloud/SCA/secrets workflows and newer interfile features need separate evidence.

## Supplementary offline documentation

**No mandatory reference-file loading.** This corpus contains the working rules, full fixtures, publication gates, workflow, and core compatibility caveats. Consult bundled documentation only for a syntax detail or capability not covered here:

- [Semgrep documentation index](references/semgrep/INDEX.md): all 28 writing-rules pages, including syntax, taint, generic patterns, fixes and experiments.
- [OpenGrep reference index](references/opengrep/INDEX.md): wiki and version-pinned source evidence.
- [Detailed compatibility evidence](references/compatibility.md): observed behavior and released-versus-main distinctions.
- [Policy decision record](references/authoring-policy.md): rationale for every requested authoring rule, including refined performance/calibration claims.
- [Runnable asset commands and golden output](examples/README.md): companion files for the inline examples.

These archives retain upstream branding and unsupported/cloud material for completeness, not as OpenGrep feature promises.

## Mandatory authoring and publication rules

- **NEVER publish without at least 2 distinct true-positive and 2 distinct true-negative cases per rule**, all passing with `opengrep test --strict`. Known-missed unsafe cases and out-of-scope inputs do not count as safe negatives.
- **ALWAYS validate syntax before committing or publishing** with `opengrep validate RULE.yaml`; require zero fatal/skippable errors and the intended rule count. Also run `semgrep --validate --config RULE.yaml` and Semgrep tests if dual compatibility is claimed.
- **NEVER set `metadata.confidence: HIGH` without representative real-codebase testing and reviewed calibration evidence.** Synthetic-only teaching examples stay LOW.
- **ALWAYS include WHAT was found, WHY it matters, and HOW to fix it in every message.** Keep remediation concrete and impact evidence-based.
- **NEVER use `pattern-regex` as the primary matcher.** Use language-aware structural patterns; constrain bound values with `metavariable-regex`. Generic token patterns are the explicit fallback for unsupported text formats, not a full AST.
- Include accurate **technology metadata**. Exclude only proven safe variants/contexts; do not suppress inconvenient findings to make tests pass.
- Provide a tested `fix` when semantics permit, never merely to satisfy a checklist. A useful message must still describe remediation when no automatic fix is safe.

The [decision record](references/authoring-policy.md) covers every requested gate, anti-pattern, performance practice, and false-positive practice—including the reasons for adapting Semgrep-only validation and rejecting blanket speed claims.


## Workflow

### 1. Define the detection boundary

- Find an existing project rule before creating another. Read the actual dangerous and safe code.
- State the language, threat model, expected finding location, and examples that must **not** match.
- Choose **search** for syntax; **taint** when the question is whether a modelled source reaches a modelled sink. Generic matching is for genuinely unstructured text or unsupported syntax, not a replacement for a supported language parser.
- Decide whether the flow is within one function, between functions in one file, or across files. Enable `--taint-intrafile` for the second; do not quietly approximate the third with local matching. Check the version-specific guide.
- A source/sink model is an approximation. Do not describe every finding as an exploitable vulnerability or every unreported path as safe.

### 2. Write fixtures before YAML

Keep **one rule per YAML**, with matching fixture basenames. The four bundled complex examples each combine interacting concepts in one rule rather than grouping small independent rules.

```text
my-rule/
├── my-rule.yaml
├── my-rule.py
└── my-rule.fixed.py    # only when testing an autofix
```

Put an annotation immediately before the **reported line**, using the source language's line-comment syntax. A focused match may report an argument rather than the enclosing call.

Use `# ruleid: my-rule` / `# ok: my-rule` in Python or configuration fixtures and `// ruleid: my-rule` / `// ok: my-rule` in JavaScript. See the four complete examples below; do not treat a one-positive/one-negative sketch as a publication-ready test suite.

Start with at least two distinct genuine positives and two genuine safe negatives, then add realistic variations, unrelated calls, boundaries, and each matching branch. For taint, include source aliases, intermediate assignments, and sanitizer placement; for intrafile analysis, include actual helper/object/callback boundaries. Name sanitizers only when their real contract is safe **for this sink**. A validator returning a boolean does not automatically sanitize its input. Label coverage-limit examples separately from truly safe negatives. Fixtures are scanner inputs; **do not execute vulnerable sample programs**.

No deferred `todoruleid` / `todook` expectations. If an engine limitation prevents the requested behavior, show the failing case and explain the limitation instead of relabelling it as safe.

### 3. Inspect syntax and build the smallest rule

Inspect the AST of a representative fixture when using language-specific structural patterns; generic text has no language AST to inspect. Start with the positive structural match, then add only constraints required by the fixtures. Do not replace a missing structural model with primary `pattern-regex`.

- Use classic `pattern` / `patterns` / `pattern-either` syntax for the baseline. Do not copy experimental `match` syntax without a version-specific probe.
- Use `ERROR`, `WARNING`, or `INFO` for portable severity.
- Bind every metavariable used in the message on every matching alternative.
- Add short comments for non-obvious range, scope, propagation, or taint semantics. Do not merely restate the YAML key.
- Include `metadata.technology` and conservative `metadata.confidence`; add category/CWE when applicable. Every message must describe WHAT, WHY, and HOW. Neither metadata nor severity is a substitute for real-codebase calibration.

### 4. Test, diagnose, repeat

Run `opengrep test` with the same analysis mode as the intended scan. Require all positive and negative expectations to pass, no parse/configuration errors, and no missing fixtures.

| Symptom | Investigate before changing the rule |
|---|---|
| Missing match | File selection/language, parser errors, AST shape, metavariable binding, analysis scope |
| Extra match | Constant propagation, an overly broad source, missing scope, negative pattern range |
| Wrong reported line | `focus-metavariable` and the intersection of positive ranges |
| Taint stops | Missing source/sink model, sanitizer scope, mutation/propagator modelling, unsupported call boundary |
| Test passes but scan differs | Engine version, intrafile flag, rule-ID rewriting, ignore rules, selected targets |

Do not “fix” a failed test by weakening the intended behavior. Taint traces explain reported flows; absence of a trace does not explain all missed flows. Test source and sink patterns individually when necessary.

### 5. Rule optimization: correctness first

- Prefer concrete APIs/constructs over unconstrained `$X($Y)`. Remove redundant patterns only after tests pass.
- Use `pattern-inside` for a meaningful scope and language-specific syntax for structure. Scope improves precision but is not a guaranteed execution-time shortcut.
- Avoid unnecessary nested ellipses and deep-expression searches; keep them when a real fixture needs them, then measure their cost. Do not assert that every regex or deep ellipsis is slow.
- Use `focus-metavariable` for precise reporting, sink selection, or fix boundaries—not as a claimed search-space optimization.
- Exclude known-safe variants with the right range semantics: `pattern-not` for same-range alternatives, `pattern-not-inside` for enclosing contexts, grounded sanitizers for dataflow. Constrain bound values with `metavariable-regex`; don't add redundant negatives.
- Before claiming performance at scale, scan a representative large codebase and record version, flags, revision, file counts, wall time, errors/timeouts, and baseline. Fixtures are not a scalability benchmark.

Re-test after each simplification. See [all optimization and false-positive decisions](references/authoring-policy.md#step-5-rule-optimization--decisions-and-practice).

### 6. Prove the real scan and finish

Run against representative project code, not only fixtures. Inspect the actual message, location, taint path when available, and JSON/SARIF errors. Check that the intended files were scanned; `.gitignore`, `.semgrepignore`, extension and size filters can hide targets.

For a fix, test the exact `.fixed` output and preview with `--autofix --dryrun`; apply only with authorization and a recoverable working tree. A pattern match is not proof that a transformation preserves behavior.

Before committing/publishing, run the mandatory syntax-validation gate and all annotated tests; report blocked gates rather than waiving them. Deliver the YAML, fixtures, exact engine/version/flags, observed results, calibration status, and known scope limits. Untested or unsupported requirements remain explicit—not “complete” because the YAML parsed. The shipped examples are LOW-confidence teaching material, not real-codebase-calibrated production detections.

## Non-obvious semantics to keep in mind

- `patterns` intersects positive match ranges; it is not an imperative sequence. Negative patterns and metavariable filters have their own evaluation stages.
- `pattern-not` removes a same-range match; `pattern-not-inside` excludes a match contained in a larger region. They are not interchangeable.
- `focus-metavariable` narrows the reported range; it does not search for the metavariable's spelling.
- A repeated named metavariable enforces compatible bindings within the relevant conjunction. `$_` does not bind a reusable value.
- `metavariable-regex` is left-anchored; include `.*` for intentional substring matching. String captures may include quotes.
- `metavariable-pattern` examines the captured subtree/text, not an unrelated surrounding function.
- Constant propagation can make a literal pattern match a variable assigned that literal. Include this case in fixtures.
- Taint `exact`, `by-side-effect`, `from`/`to`, `label`/`requires`, and `focus-metavariable` change the model, not just output formatting. Use the inline taint examples to understand the interaction, and prove each assumption; consult the local reference for additional syntax.
- Sanitization is context-specific. An HTML escape is not a shell sanitizer; successful parsing is not validation of the parsed value.

## Four complete commented examples

Read these examples here; no reference-file handoff is needed. Each YAML contains one coherent rule, at least two genuine positive and two genuine safe negative cases, LOW confidence, technology metadata, and an actionable WHAT/WHY/HOW message. Extra `ok` cases explicitly document scope boundaries rather than declaring unsafe code safe. Files under `examples/` are executable scanner assets mirroring this corpus, not a prerequisite for understanding it.

Verified on native OpenGrep 1.30.0: four rule tests and the Nginx autofix golden passed; actual network-isolated scans produced 17 expected findings and excluded 26 annotated `ok` cases with zero errors. Network-enabled syntax validation reported four rules and zero fatal/skippable errors. Synthetic success is not real-codebase calibration or a scalability benchmark.

### 1. Multi-API password KDF policy

Two different API shapes share scope, numeric constraints, constant propagation, and focused reporting. No automatic fix: changing the count alone can break stored hash metadata.

**Rule:**

```yaml
rules:
  - id: lab-python-weak-password-kdf
    languages: [python]
    severity: WARNING
    message: >-
      PBKDF2-HMAC-SHA256 password generation in $FUNC uses $ROUNDS iterations,
      below this application's 600000-iteration policy; insufficient work makes
      offline password guessing cheaper. Increase the work factor for NEW hashes,
      store the chosen count with each hash, and migrate old hashes after successful
      verification; do not change legacy verification parameters in place.
    metadata:
      confidence: LOW  # Synthetic fixtures only; no real-codebase FP calibration.
      technology: [python, hashlib, cryptography]
      category: security
      cwe: 'CWE-916: Use of Password Hash With Insufficient Computational Effort'

    # One detection, not two mini-rules: API-specific branches first bind $ROUNDS;
    # the outer conjunction then shares scope, numeric policy, and reporting.
    patterns:
      - pattern-either:
          - patterns:
              # All positional roles are explicit. A loose $FUNC(...) would match
              # unrelated crypto APIs; ellipsis only admits optional trailing args.
              - pattern: hashlib.pbkdf2_hmac($HASH, $PASSWORD, $SALT, $ROUNDS, ...)
              - metavariable-regex:
                  metavariable: $HASH
                  # String metavariables include quotes. Anchor both ends so
                  # "sha256-custom" cannot accidentally satisfy the policy.
                  regex: "^['\"]sha256['\"]$"
          - patterns:
              # Keyword order is structural, not textual: reordered kwargs match.
              - pattern: PBKDF2HMAC(..., algorithm=$HASH, iterations=$ROUNDS, ...)
              - metavariable-pattern:
                  metavariable: $HASH
                  # Here $HASH is a constructor expression, not a quoted string.
                  # Parse its subtree instead of applying the other branch's regex.
                  pattern: hashes.SHA256()

      - pattern-inside: |
          def $FUNC(...):
            ...
      - metavariable-regex:
          metavariable: $FUNC
          # Deliberate application boundary: generation entrypoints only.
          # verify_password must reproduce a legacy stored count before migration.
          regex: '^(?:create|derive|hash)_password(?:_.*)?$'

      - metavariable-comparison:
          metavariable: $ROUNDS
          # Numeric, not lexicographic. Constant propagation resolves local aliases.
          # Zero/negative counts are invalid-argument bugs, not weak derived keys;
          # unknown runtime counts cannot be certified safe by this rule.
          comparison: $ROUNDS > 0 and $ROUNDS < 600000

      # Focus runs on surviving matches: report the iteration argument, not the
      # whole constructor or enclosing function. Multiline fixtures annotate it.
      - focus-metavariable: $ROUNDS

    # No autofix: replacing only the argument can leave stored iteration metadata
    # inconsistent with the derived hash (see create_password_record in the fixture).
    # Remediation is explicit in the message; a migration needs application context.
```

**Full annotated fixture (static scanner input; never execute):**

```python
# STATIC SCANNER INPUT: never execute this file.
# Application policy: newly generated PBKDF2-HMAC-SHA256 password hashes use
# >=600,000 iterations. This is a lab policy, not a universal performance setting.
import hashlib
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


def hash_password(password, salt):
    # Positive A: hashlib branch binds algorithm text and the fourth argument.
    # ruleid: lab-python-weak-password-kdf
    return hashlib.pbkdf2_hmac("sha256", password, salt, 100_000, dklen=32)


def create_password_record(password, salt):
    rounds = 200_000
    # Positive B: constant propagation resolves rounds; focus reports this usage.
    # A one-token autofix would disagree with the count returned as hash metadata.
    # ruleid: lab-python-weak-password-kdf
    derived = hashlib.pbkdf2_hmac('sha256', password, salt, rounds)
    return derived, rounds


def derive_password_key(password, salt):
    # Positive C: cryptography branch filters an AST constructor, not its spelling.
    # The annotation is above iterations because focus reports that value's line.
    return PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        salt=salt,
        # ruleid: lab-python-weak-password-kdf
        iterations=599_999,
        length=32,
    ).derive(password)


def hash_password_boundaries(password, salt, runtime_rounds):
    # Boundary equality is compliant; > threshold is compliant too.
    # ok: lab-python-weak-password-kdf
    hashlib.pbkdf2_hmac("sha256", password, salt, 600_000)
    # ok: lab-python-weak-password-kdf
    hashlib.pbkdf2_hmac("sha256", password, salt, 900_000)
    # Invalid counts raise instead of creating a weak derived key: another rule's job.
    # ok: lab-python-weak-password-kdf
    hashlib.pbkdf2_hmac("sha256", password, salt, 0)
    # SHA512 needs its own cost policy; this does not declare 100 iterations safe.
    # ok: lab-python-weak-password-kdf
    hashlib.pbkdf2_hmac("sha512", password, salt, 100)
    # Unknown runtime values are outside this static numeric check, not known safe.
    # ok: lab-python-weak-password-kdf
    hashlib.pbkdf2_hmac("sha256", password, salt, runtime_rounds)
    # Same numeric boundary for the second API and different keyword ordering.
    # ok: lab-python-weak-password-kdf
    PBKDF2HMAC(iterations=600_000, length=32, algorithm=hashes.SHA256(), salt=salt)
    # Constructor filtering prevents a spelling-only match on any hash object.
    # ok: lab-python-weak-password-kdf
    PBKDF2HMAC(iterations=100, length=32, algorithm=hashes.SHA512(), salt=salt)


def verify_password(password, salt, stored_digest):
    # Verification must reproduce a stored legacy hash before a separate rehash.
    # This rule scopes to generation entrypoints; changing this count would lock
    # users out. Naming alone is not proof: audit entrypoints before using the fix.
    # ok: lab-python-weak-password-kdf
    return hashlib.pbkdf2_hmac("sha256", password, salt, 100_000) == stored_digest
```

Run from the skill directory:

```sh
opengrep test --strict -c examples/01-structural/structural.yaml examples/01-structural/structural.py
```

### 2. Second-order command injection

Follow JOB provenance through a dependent SHELL label, receiver mutation, delayed extraction, and a boolean label-gated sink. Compare returned versus in-place sanitization and nested evaluation order.

**Rule:**

```yaml
# ONE RULE: second-order shell injection through an untrusted persisted job.
#
# Flow: load/read-into -> JOB -> render_shell_command -> JOB + SHELL
#       -> batch.add(command) -> tainted batch receiver -> batch.pop()
#       -> run_shell($COMMAND) requires JOB and SHELL.
#
# All API names are educational models; see taint.py for their safety contracts.
# This rule is intentionally narrower than a general shell-injection rule: raw
# JOB data executed without the rendering stage is OUTSIDE ITS TARGET, not safe.
# Labels represent provenance + a transformation, not two independent inputs.
# Local semantics references:
#   ../../references/semgrep/writing-rules/data-flow/taint-mode/advanced.md
#     (taint labels, side effects, custom propagators)
#   ../../references/semgrep/writing-rules/data-flow/taint-mode/overview.md
#     (exact sources/sanitizers/sinks)
# These upstream snapshots explain syntax; they do not promise engine parity.
# Paired fixtures exercise the combined behavior on the selected OpenGrep engine.

rules:
  - id: lab-python-shell-taint
    languages: [python]
    mode: taint
    severity: WARNING
    message: >-
      A shell command rendered from an untrusted persisted job reaches run_shell's
      execution argument. Unchecked interpolation can execute attacker-controlled
      operating-system commands when a worker processes the job. Reconstruct an
      allowlisted command and use its returned buffer, or validate the entire
      command with a fail-closed allowlist before staging or executing it.
    metadata:
      confidence: LOW
      technology: [python, job-queues, shell]
      # LOW is intentional: synthetic educational cases, not calibrated on real
      # applications. Neither the severity nor example annotations imply accuracy
      # measurements for an actual queue/command library.

    pattern-sources:
      # Step 1: a client-controlled record persisted earlier enters the worker.
      # exact:true labels this call's RESULT, not every descendant expression.
      # load_untrusted_job(run_shell(clean)) must not backdate JOB into that sink.
      - pattern: load_untrusted_job(...)
        exact: true
        label: JOB

      # Alternative entry into the SAME pipeline: an existing mutable job is
      # overwritten. Focus must select the l-value, not the whole read-into call.
      # by-side-effect:true makes later reads of $JOB carry JOB; without it only
      # this occurrence is tainted and later rendering can miss the provenance.
      # The true mode also taints the focused occurrence; it is not 'only'.
      - patterns:
          - pattern: read_untrusted_job_into($JOB)
          - focus-metavariable: $JOB
        exact: true
        by-side-effect: true
        label: JOB

      # Step 2: unsafe interpolation makes the persisted job executable text.
      # This is a DEPENDENT source: SHELL is added only when the matched renderer
      # expression already carries JOB. A renderer invoked on a clean literal is
      # not an unconditional SHELL source. Ordinary argument-to-return propagation
      # preserves JOB; requires adds SHELL rather than replacing the old label.
      # Do not focus $JOB here: that would label the input instead of the output.
      # exact:true keeps SHELL off nested arguments evaluated BEFORE rendering;
      # render_shell_command(run_shell(job)) is a raw-source bypass, not this flow.
      - pattern: render_shell_command(...)
        exact: true
        requires: JOB
        label: SHELL

    pattern-propagators:
      # Step 3: workers stage commands before another statement executes them.
      # add() returns no useful command, so ordinary return propagation cannot
      # model this write. Explicit from/to copies ALL labels from $COMMAND to
      # $BATCH; it does not synthesize the dependent SHELL label on a raw JOB.
      # $BATCH must be an l-value for receiver mutation to affect later reads.
      # by-side-effect:true is the default, written explicitly to expose why a
      # later pop() obtains receiver taint through ordinary call propagation.
      # This conservative container model does not track individual members or
      # clear receiver taint when a member is popped; use separate clean batches.
      - pattern: $BATCH.add($COMMAND)
        from: $COMMAND
        to: $BATCH
        by-side-effect: true

    pattern-sinks:
      # Step 4: only the first argument executes; audit= is inert log data under
      # this API contract. Focus narrows BOTH reporting and label evaluation to
      # the dangerous expression. Otherwise a clean command with tainted audit
      # metadata could satisfy a whole-call sink and create a false positive.
      # exact:true does not broaden the sink to all descendant subexpressions.
      # Boolean requires is evaluated against the focused value's labels:
      # BOTH provenance and the rendering stage must reach the command argument.
      # It does not require that the labels come from two distinct sources, and
      # it is not a safety guarantee for values bearing only JOB.
      - patterns:
          - pattern: run_shell($COMMAND, ...)
          - focus-metavariable: $COMMAND
        exact: true
        requires: JOB and SHELL

    pattern-sanitizers:
      # Return-only sanitizer: construct a NEW command from a fixed allowlist.
      # All labels are removed from the result, not the caller's original buffer.
      # Discarding this return does NOT sanitize command or a staged receiver.
      # Exact matching is essential: allowlisted_command(run_shell(tainted))
      # must still report the inner execution, which happens before the sanitizer.
      # This is not 'shell quoting is always safe'; the full safety contract is
      # allowlisted reconstruction, not merely escaping arbitrary attacker text.
      - pattern: allowlisted_command(...)
        exact: true

      # In-place validation: normal return guarantees the ENTIRE mutable command
      # passes a fixed allowlist; failure raises and cannot continue to the sink.
      # focus + by-side-effect cleans later reads of THIS l-value. A predicate
      # returning False or checking only a substring cannot satisfy this contract.
      # This fact is program-point-local, not permanent: assigning a newly rendered
      # untrusted command later reintroduces JOB + SHELL, as the fixture shows.
      - patterns:
          - pattern: assert_allowlisted_command($COMMAND)
          - focus-metavariable: $COMMAND
        exact: true
        by-side-effect: true
```

**Full annotated fixture (static scanner input; never execute):**

```python
# STATIC SCANNER INPUT: never execute this file; the APIs below are undefined models.
# One detection, not a survey of separate rules:
# persisted client job -> JOB -> render_shell_command -> JOB + SHELL
# -> batch.add(command) mutates receiver -> batch.pop() -> run_shell(command).
#
# Educational API contracts (not claims about a real Python library):
# - load_untrusted_job(key, ...) returns a deserialized, client-controlled job.
# - read_untrusted_job_into(job) overwrites a mutable job object from that store.
# - render_shell_command(job) interpolates the job into a mutable CommandBuffer
#   without shell escaping; it preserves input taint and adds the SHELL stage.
# - set.add/pop model worker staging; run_shell executes ONLY its first argument.
#   audit= is logged as data, never interpreted as code or as a command.
# - allowlisted_command(command) returns a NEW buffer reconstructed from fixed
#   allowed commands; it neither mutates command nor merely quotes attacker text.
# - assert_allowlisted_command(command) checks the ENTIRE buffer against that same
#   fixed allowlist, raises on failure, and returns normally only for safe buffers.
#   It is not a boolean predicate, substring check, or shell-quoting function.
#
# All annotations concern THIS second-order pipeline. In particular, a raw JOB
# sent directly to a shell is OUTSIDE THIS RULE'S TARGET, not safe in general.
# Distinct functions keep intraprocedural taint states independent. There are no
# runnable helpers or scanner mocks; comments explain the expected scanner paths.


def persisted_job_through_worker_batch():
    job = load_untrusted_job("pending/client-42")  # JOB only: source return.
    command = render_shell_command(job)  # JOB flows through; requires JOB adds SHELL.
    pending = set()
    pending.add(command)  # Propagator copies BOTH labels onto this l-value receiver.
    # pop() obtains taint from the receiver under ordinary opaque-call propagation.
    # The staging mutation, not the return of add(), connects producer to consumer.
    # ruleid: lab-python-shell-taint
    run_shell(pending.pop(), audit="worker-7")


def a_missing_stage_is_not_the_target():
    clean_job = {"operation": "status"}
    clean_command = render_shell_command(clean_job)  # No JOB, so no extra SHELL label.
    # ok: lab-python-shell-taint
    run_shell(clean_command)
    job = load_untrusted_job("pending/client-42")
    # Only JOB reaches this sink: no dependent rendering transition occurred.
    # Deliberate coverage boundary, NOT a statement that executing raw input is safe.
    # ok: lab-python-shell-taint
    run_shell(job)


def side_effect_source_changes_a_later_render():
    job = MutableJob({"operation": "status"})
    pending = set()
    pending.add(render_shell_command(job))  # Neither JOB nor SHELL yet.
    # ok: lab-python-shell-taint
    run_shell(pending.pop())
    read_untrusted_job_into(job)  # Focused source mutates JOB taint on later reads.
    pending.add(render_shell_command(job))  # The SAME renderer now gains SHELL.
    # ruleid: lab-python-shell-taint
    run_shell(pending.pop())


def using_the_return_sanitizer_changes_the_batch_input():
    command = render_shell_command(load_untrusted_job("pending/client-42"))
    safe_command = allowlisted_command(command)  # A new clean buffer, not an assertion.
    pending = set()
    pending.add(safe_command)  # No labels copied: the unsafe original stays separate.
    # ok: lab-python-shell-taint
    run_shell(pending.pop(), audit=command)
    # The same original still has JOB + SHELL. Sanitizing a copy didn't change it.
    # ruleid: lab-python-shell-taint
    run_shell(command)


def discarding_the_return_does_not_sanitize_the_original():
    command = render_shell_command(load_untrusted_job("pending/client-42"))
    allowlisted_command(command)  # Return discarded; caller-local command stays tainted.
    pending = set()
    pending.add(command)  # Both labels survive through the mutating propagator.
    # ruleid: lab-python-shell-taint
    run_shell(pending.pop())


def an_in_place_check_cleans_later_reads_but_not_future_writes():
    command = render_shell_command(load_untrusted_job("pending/client-42"))
    # ruleid: lab-python-shell-taint
    run_shell(command)  # An earlier execution cannot be undone by a later check.
    assert_allowlisted_command(command)  # Normal return establishes the buffer is safe.
    pending = set()
    pending.add(command)  # Focus + by-side-effect removed labels from later reads.
    # ok: lab-python-shell-taint
    run_shell(pending.pop())
    command = render_shell_command(load_untrusted_job("pending/client-99"))
    pending.add(command)  # New untrusted content reintroduces BOTH labels to the batch.
    # ruleid: lab-python-shell-taint
    run_shell(pending.pop())


def audit_data_is_not_the_focused_execution_argument():
    audit_data = render_shell_command(load_untrusted_job("pending/client-42"))
    # Both labels exist, but ONLY on audit=. Focusing $COMMAND avoids a false alarm.
    # ok: lab-python-shell-taint
    run_shell("status", audit=audit_data)
    # Moving the identical value into the dangerous argument changes the outcome.
    # ruleid: lab-python-shell-taint
    run_shell(audit_data, audit="worker-7")


def nested_sanitization_happens_before_or_after_execution():
    # Inner load -> render -> sanitizer return -> shell: the sink receives clean data.
    # ok: lab-python-shell-taint
    run_shell(allowlisted_command(render_shell_command(load_untrusted_job("pending/42"))))
    # Here load -> render -> shell happens FIRST. The outer sanitizer cannot undo it.
    # exact:true sanitization applies only to its own result, not descendant sinks.
    # ruleid: lab-python-shell-taint
    allowlisted_command(run_shell(render_shell_command(load_untrusted_job("pending/42"))))


def exact_sources_do_not_backdate_label_transitions():
    # The outer loader only taints its own result, AFTER its argument is evaluated.
    # Its enclosing source match does not make a nested clean renderer/sink untrusted.
    # ok: lab-python-shell-taint
    load_untrusted_job(run_shell(render_shell_command({"operation": "status"})))
    job = load_untrusted_job("pending/client-42")
    # The dependent SHELL source is also exact: it labels its result, not nested
    # arguments. This inner shell receives JOB only, before the transition exists.
    # As above, this raw execution bypass is outside the target, not a safe idiom.
    # ok: lab-python-shell-taint
    render_shell_command(run_shell(job))
    # Changing the nesting puts the dependent transition BEFORE the shell executes.
    # ruleid: lab-python-shell-taint
    run_shell(render_shell_command(job))
```

Run from the skill directory:

```sh
opengrep test --strict -c examples/02-taint/taint.yaml examples/02-taint/taint.py
```

### 3. Contextual Nginx upstream verification

Combine ordered structural token patterns, location context, named ellipsis captures, regex constraints on bound values, comment handling, and a focused fail-closed fix. Generic nesting is indentation-based, not a complete Nginx parser.

**Rule:**

```yaml
rules:
  - id: lab-nginx-unverified-upstream
    languages: [generic]  # Nginx has no dedicated parser in this example's engine.
    severity: WARNING
    message: >-
      An explicit HTTPS proxy location disables upstream certificate verification;
      a network attacker could impersonate the upstream. Set proxy_ssl_verify on
      and configure proxy_ssl_trusted_certificate for the upstream CA; review
      inherited settings and includes separately before deploying the change.
    metadata:
      confidence: LOW  # Lexical configuration model; no real deployment calibration.
      technology: [nginx]
      category: security
      cwe: 'CWE-295: Improper Certificate Validation'
    options:
      # Commented-out directives must not behave as live configuration.
      generic_comment_style: shell
      # A bounded educational window, NOT an Nginx block-size limit. Longer
      # locations may be missed; measure before increasing the matching span.
      generic_ellipsis_max_span: 20

    # Start with STRUCTURAL generic token patterns. Regex only constrains a bound
    # URL; there is no whole-file pattern-regex search and no invented Nginx AST.
    # Spacegrep's multiline nesting follows INDENTATION; braces alone are not an
    # Nginx parser. The sibling/nested fixtures prove only their stated layout.
    patterns:
      - pattern-either:
          # Generic matching is ordered: unlike Python keyword arguments, swapping
          # these two directives needs another branch. Both branches bind the same
          # $VERIFY and $...UPSTREAM for the shared filters and focused fix below.
          - pattern: |
              location $...LOCATION {
                ...
                proxy_pass $...UPSTREAM;
                ...
                proxy_ssl_verify $VERIFY;
                ...
              }
          - pattern: |
              location $...LOCATION {
                ...
                proxy_ssl_verify $VERIFY;
                ...
                proxy_pass $...UPSTREAM;
                ...
              }

      - metavariable-regex:
          metavariable: $...UPSTREAM
          # A single-word metavariable would lose : / . $ and port punctuation.
          # Ellipsis captures may retain surrounding whitespace. Forbid internal
          # whitespace/semicolons so a capture cannot consume another directive.
          regex: '^[ \t]*https://[^\s;]+[ \t]*$'
      - metavariable-regex:
          metavariable: $VERIFY
          regex: '^off$'

      # Focus selects the boolean after the full location has matched. Replacing
      # the entire location would discard sibling directives and their comments.
      - focus-metavariable: $VERIFY
    fix: 'on'

    # This is fail-closed configuration, not an automatically deployable patch:
    # without a valid trusted CA, connections can fail. The fixture tests bytes,
    # not TLS connectivity. No fix-regex: native 1.30.0 can lose that metadata on
    # generic/synthetic matches; focused fix has an explicit golden-file check.
    # Explicit pairs only: absence/defaults, includes, Nginx inheritance and runtime
    # variable expansion require configuration-aware analysis outside this rule.
```

**Full annotated fixture (static scanner input; never execute):**

```nginx
# STATIC SCANNER INPUT: Nginx-style configuration; do not deploy this fixture.
# The generic matcher uses indentation and tokens, not Nginx inheritance or includes.

server {
    location /api/ {
        proxy_pass https://backend.internal:8443;
        proxy_ssl_trusted_certificate /etc/nginx/upstream-ca.pem;
        # Positive A: HTTPS upstream precedes disabled verification.
        # ruleid: lab-nginx-unverified-upstream
        proxy_ssl_verify off;
    }

    location = /upload {
        proxy_ssl_trusted_certificate /etc/nginx/upstream-ca.pem;
        # Positive B: directive order reverses; the other structural branch applies.
        # ruleid: lab-nginx-unverified-upstream
        proxy_ssl_verify off; # preserve this trailing explanation in the fix
        proxy_pass https://uploads.internal;
    }

    location /dynamic/ {
        proxy_pass https://$upstream;
        # Positive C: punctuation and a variable require $...UPSTREAM, not $UPSTREAM.
        # ruleid: lab-nginx-unverified-upstream
        proxy_ssl_verify off;
    }

    location /verified/ {
        proxy_pass https://backend.internal;
        # True negative: certificate verification is enabled.
        # ok: lab-nginx-unverified-upstream
        proxy_ssl_verify on;
    }

    location /plaintext/ {
        proxy_pass http://backend.internal;
        # Out of scope: no upstream TLS, so this flag has no certificate to verify.
        # Plaintext transport might violate another policy; it is not declared safe.
        # ok: lab-nginx-unverified-upstream
        proxy_ssl_verify off;
    }

    location /comment/ {
        proxy_pass https://backend.internal;
        # A disabled directive in a comment is not active configuration.
        # ok: lab-nginx-unverified-upstream
        # proxy_ssl_verify off;
        proxy_ssl_verify on;
    }

    location /upstream-only/ {
        proxy_pass https://backend.internal;
    }
    location /flag-only/ {
        # The preceding sibling's upstream MUST NOT combine with this directive.
        # Inherited upstream/default settings are outside this explicit-pair rule.
        # ok: lab-nginx-unverified-upstream
        proxy_ssl_verify off;
    }

    location /nested/ {
        proxy_pass http://frontend.internal;
        location /nested/child/ {
            # Parent HTTP setting and another sibling's HTTPS must not leak here.
            # ok: lab-nginx-unverified-upstream
            proxy_ssl_verify off;
        }
    }
}
```

Run from the skill directory:

```sh
opengrep test --strict -c examples/03-config/config.yaml examples/03-config/config.generic
```

### 4. Intrafile object state and callbacks

Follow a source factory through constructor state, collection access, helper methods, built-in map and custom callbacks. OpenGrep 1.30.0 reports zero findings without --taint-intrafile and two with it. The fixture documents the constructor-mutation and inline sanitizer-wrapper limitations.

**Rule:**

```yaml
# ONE rule for a complete job-command pipeline, not separate teaching rules.
# This is deliberately OpenGrep-specific at execution time: use
#   opengrep scan -c intrafile.yaml intrafile.py --taint-intrafile
# Omit --taint-intrafile for the zero-finding comparison. Use the native-version
# verification commands in ../README.md; support depends on the exact code shape.
# There is no interfile:true, proprietary flag, or per-rule forced intrafile
# setting: the same YAML must support a genuine flag-off/flag-on experiment.
rules:
  - id: lab-python-intrafile-command
    languages: [python]
    mode: taint
    severity: WARNING
    message: >-
      An untrusted request command crossed same-file job state and a callback
      into shell execution without allowlisting. Whitespace normalization does
      not prevent command injection, so an attacker could execute shell syntax.
      Map user choices to fixed trusted commands with allowlisted_command, or
      replace shell execution with an argument-vector API that does not invoke
      a shell; do not interpolate user input into shell command strings.
    metadata:
      # Synthetic fixtures establish teaching intent, not real-world precision.
      # Upgrade confidence only after calibration on representative codebases.
      confidence: LOW
      technology: [python, opengrep]
      category: security
      cwe: "CWE-78: Improper Neutralization of Special Elements used in an OS Command"

    pattern-sources:
      - patterns:
          # Structural scope AND exact API call: only this application's request
          # adapter reads executable job input. Other HTTP reads are not silently
          # declared sources, and load_command() CALLS are not directly matched.
          # Its actual body must create a source and return it for the native
          # signature extractor to connect the otherwise source-free caller.
          - pattern-inside: |
              def load_command():
                  ...
          - pattern: read_request_field("command")
        # Only the call result is tainted, not its literal field-name argument
        # or arbitrary children of a larger expression. Scope does not mean
        # "everything in the loader is tainted"; it intersects the call match.
        exact: true

    pattern-sinks:
      - patterns:
          # shell_exec is an EDUCATIONAL API with a precise contract: command
          # is executed by a shell, audit is inert text. Do not copy its name to
          # a production rule without identifying the real API and its options.
          - pattern: shell_exec($COMMAND, audit=$AUDIT)
          # First identify the call and bind both arguments, then retain ONLY
          # the command expression's range for taint checking and reporting.
          # A source flowing into $AUDIT alone is a negative, even when the
          # command and audit arrived through the same constructor and HOF.
          - focus-metavariable: $COMMAND
        exact: true

    pattern-sanitizers:
      # The fixture DEFINES this helper: two user choices return fixed command
      # literals; anything else raises. This grounded allowlist contract, not
      # a naming heuristic or blanket exclusion, justifies sanitizing its return.
      - pattern: allowlisted_command(...)
        # Sanitize the returned selection, not the input variable in place and
        # not nested evaluation. An unsafe sink inside an argument would still
        # run before the sanitizer returns and must remain detectable.
        exact: true

    # Dataflow, not YAML order, connects these matches. With --taint-intrafile,
    # native summaries must preserve source -> factory return -> constructor
    # parameter -> self.pending initializer -> self.pending.pop -> method/helper
    # return -> callback argument -> focused sink. Python collection models
    # supply ThisTaintsReturn for pop; map binds its element to the
    # lambda, and apply_command's real body binds a named callback's arguments.
    # No propagator substitutes for these bodies, and no broad safe-functions
    # option suppresses a missing hop. normalize_command/strip is NOT sanitized.
    # checked_command is intentionally NOT matched: its safe return must be
    # inferred through its allowlist call in the named callback. The inline lambda
    # uses the directly modelled allowlist: 1.30.0 lost that wrapper's precision
    # there. Split empty-field initialization + append also missed the unsafe
    # flow; the fixture documents its single-expression constructor alternative.
    #
    # The fixture's two positive sites contrast built-in map with a custom HOF.
    # Four negative sites cover safe named/inline callbacks, a clean sibling
    # field, and source taint only in the non-executable sibling argument.
    # Collection mutation modelling does NOT promise index-sensitive queues;
    # one element avoids implying such precision. Native intrafile support also
    # does not imply imported-callee, reflective-dispatch, inheritance, or
    # mutually recursive signature support. Check the annotated fixture on the
    # pinned engine before treating these expectations as compatibility facts.
```

**Full annotated fixture (static scanner input; never execute):**

```python
# STATIC SCANNER INPUT: never execute this file.
# read_request_field() and shell_exec() are deliberately undefined educational
# boundary APIs: the first returns an untrusted HTTP field; the second executes
# its FIRST argument as a shell command. Its audit keyword is stored as data,
# never interpreted by a shell. These are contracts, not real library names.
# All factories, constructors, methods, helpers, and callbacks below have real
# bodies. In particular, load_command() is NOT a source merely by name, and
# neither normalize_command() nor the callback dispatcher is a sanitizer.
#
# Verified native OpenGrep 1.30.0 behavior for this fixture's exact code shapes:
#   scan -c intrafile.yaml intrafile.py                   -> no findings
#   scan -c intrafile.yaml intrafile.py --taint-intrafile -> two ruleid sites
# Without the flag, load_command() has no tainted arguments from which opaque
# call propagation could invent a tainted return. With it, same-file summaries
# must connect returns, constructor fields, collection access, methods,
# and callback parameters. This is intrafile, NOT imported/interfile analysis.


def load_command():
    # The rule scopes its source to this boundary adapter, and exactly to the
    # return value of this request read, not the string literal "command".
    value = read_request_field("command")
    return value


def normalize_command(value):
    # Whitespace normalization changes the bytes, not their trustworthiness.
    # The helper summary must preserve taint through this receiver-method call.
    return value.strip()


def allowlisted_command(value):
    # Genuine safety contract: user input selects one of two fixed commands.
    # Nothing supplied by the caller is interpolated into a shell string.
    # Rejection raises instead of returning the original dangerous value.
    action = value.strip()
    if action == "health":
        return "printf ready"
    if action == "uptime":
        return "uptime"
    raise ValueError("unsupported job action")


def checked_command(value):
    # This wrapper is NOT matched as a sanitizer by the rule. Intrafile analysis
    # must understand that its return passes through the actual allowlist API.
    return allowlisted_command(normalize_command(value))


class CommandJob:
    def __init__(self, command, audit):
        # Initialize the field with its tainted element in one expression.
        # Native 1.30.0 missed the equivalent split form self.pending=[] followed
        # by self.pending.append(command) in this constructor. That engine limit
        # is documented, not hidden by a custom propagator or a source-on-caller.
        self.pending = [command]
        # Field sensitivity matters: a tainted pending field does not justify
        # tainting audit or fallback, and a tainted audit is not a shell command.
        self.audit = audit
        self.fallback = "printf ready"

    def next_command(self):
        # pop() is the opposite boundary: ThisTaintsReturn retrieves taint from
        # the queue receiver. Then a separate helper preserves it on the return.
        # No manual propagator hides either the constructor or method body.
        return normalize_command(self.pending.pop())

    def fallback_command(self):
        # Same object, same normalization helper, different (clean) field.
        return normalize_command(self.fallback)

    def audit_text(self):
        return self.audit


def apply_command(command, audit, callback):
    # A real custom higher-order function, not an undefined opaque API: the
    # first actual argument becomes callback's first parameter; audit is second.
    # The caller supplies the callback itself, so the function signature must
    # retain that binding rather than treating callback as an unrelated name.
    return callback(command, audit)


def execute_unchecked(command, audit):
    # UNSAFE PATH B ends here. Its callsite supplies job.next_command(), reached
    # through load_command -> __init__ -> pending field -> next_command/pop ->
    # normalize_command -> apply_command -> this named callback's first arg.
    # ruleid: lab-python-intrafile-command
    shell_exec(command, audit=audit)


def execute_checked(command, audit):
    # SAFE HELPER/CALLBACK path: taint does reach this parameter, but the nested
    # checked_command -> allowlisted_command return is a fixed trusted command.
    # The original command is not sanitized in place; only the new return is.
    selected = checked_command(command)
    # ok: lab-python-intrafile-command
    shell_exec(selected, audit=audit)


def unsafe_map_entrypoint():
    # UNSAFE PATH A: factory return -> constructor queue field -> method/helper
    # return -> Python map's first callback parameter -> focused command sink.
    # list() forces Python's lazy map to run; the callback is not dead code.
    job = CommandJob(load_command(), "job-map")
    list(map(
        # strip() above did not remove taint, so this callback needs a finding.
        # ruleid: lab-python-intrafile-command
        lambda command: shell_exec(command, audit=job.audit_text()),
        [job.next_command()],
    ))


def unsafe_named_callback_entrypoint():
    # Same constructor/method state machinery; unlike PATH A, a named function
    # is passed as a value to a custom HOF, which invokes it in its own body.
    # The finding belongs at execute_unchecked's sink, not on this dispatch.
    job = CommandJob(load_command(), "job-named")
    apply_command(job.next_command(), job.audit_text(), execute_unchecked)


def safe_named_callback_entrypoint():
    # One meaningful change from the unsafe named path: the callback performs
    # allowlisting before executing. No source or dispatcher exclusion is used.
    job = CommandJob(load_command(), "job-checked")
    apply_command(job.next_command(), job.audit_text(), execute_checked)


def safe_map_callback_entrypoint():
    # The directly modelled sanitizer runs INSIDE the lambda after map binds its
    # element. 1.30.0 produced a false positive when this call was instead hidden
    # behind checked_command here; the named-callback path proves that wrapper's
    # safe return separately. Do not assume those analysis shapes are equivalent.
    job = CommandJob(load_command(), "job-safe-map")
    list(map(
        # ok: lab-python-intrafile-command
        lambda command: shell_exec(allowlisted_command(command), audit=job.audit_text()),
        [job.next_command()],
    ))


def safe_sibling_field_entrypoint():
    # One-condition negative for PATH A: job still contains an untrusted queue,
    # but the callback receives fallback_command() instead of next_command().
    # Do not repair a receiver/field false positive by excluding this function.
    job = CommandJob(load_command(), "job-fallback")
    list(map(
        # ok: lab-python-intrafile-command
        lambda command: shell_exec(command, audit=job.audit_text()),
        [job.fallback_command()],
    ))


def safe_audit_argument_entrypoint():
    # The source is present and travels through the constructor into audit,
    # while pending contains a fixed command. The dispatcher sends that source
    # to the callback's SECOND parameter. Focusing only the sink's first argument
    # is essential: matching the whole call would conflate audit with execution.
    job = CommandJob("printf ready", load_command())
    apply_command(
        job.next_command(),
        job.audit_text(),
        # ok: lab-python-intrafile-command
        lambda command, audit: shell_exec(command, audit=audit),
    )


# Deliberate analysis limits: only concrete same-file classes/functions are
# exercised, with no inheritance, reflective dispatch, imported callbacks, or
# mutually recursive call graph. Collection models are conservative: this
# one-element queue does NOT prove per-index or per-element precision for a
# mixture of clean and dirty commands. Likewise, a clean fallback field must
# remain separate from a dirty pending field; these ok sites check that contract.
# Annotations encode the intended result and require a native-version scan;
# they do not claim that every supported language or future version agrees.
```

Run from the skill directory:

```sh
opengrep test --strict --taint-intrafile -c examples/04-intrafile/intrafile.yaml examples/04-intrafile/intrafile.py
```
