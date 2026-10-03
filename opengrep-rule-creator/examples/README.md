# Four complex, commented examples

**Exactly four rules: one complete detection per directory.** Each combines interacting concepts rather than collecting independent one-feature rules. Read the comments in the YAML **and** its fixture: they explain range evaluation, dataflow transitions, boundary cases, and limitations that a list of operators would miss.

All four commented rules and full fixtures are also embedded directly in [SKILL.md](../SKILL.md). This directory supplies scanner-ready companion assets and the autofix golden; it is not a required disclosure step before learning the examples.

These are LOW-confidence educational models, **not real-codebase-calibrated production detections**. Never execute the `.py` fixtures or deploy the configuration fixture. Their external APIs are explicitly documented contracts, not hidden implementations.

## Choose an example

| Example | One detection / concepts that work together | Observed positives / `ok` cases |
|---|---|---:|
| [01 — Password KDF policy](01-structural/structural.yaml), [fixture](01-structural/structural.py) | Two structural API branches; branch-local regex versus AST metavariable filtering; common function scope; numeric comparison; constant propagation; focused multiline reporting; deliberately no unsafe one-token autofix | 3 / 8 |
| [02 — Second-order command injection](02-taint/taint.yaml), [fixture](02-taint/taint.py) | Persisted job provenance → dependent label transition → receiver mutation → delayed extraction → boolean label-gated sink; exactness; focused arguments; return versus in-place sanitization; re-tainting and nested evaluation order | 9 / 9 |
| [03 — Nginx upstream verification](03-config/config.yaml), [fixture](03-config/config.generic), [fixed output](03-config/config.fixed.generic) | Generic structural location blocks; order-sensitive alternatives; named ellipsis capturing URL punctuation; bounded matching; comment handling; metavariable-regex constraints; focused fail-closed fix; sibling/nested block boundaries | 3 / 5 |
| [04 — Object state and callbacks](04-intrafile/intrafile.yaml), [fixture](04-intrafile/intrafile.py) | Scoped source factory → constructor field → collection accessor → method/helper → built-in `map` or custom higher-order callback → focused sink; safe callbacks, field separation, argument separation; intrafile mode comparison | 2 / 4 |

Each rule has at least **two distinct true positives and two genuine safe negatives**. `ok` totals additionally include explicitly labelled scope boundaries; an unsafe path outside a rule's intended target is **not** counted as safe. For example: example 01 has compliant counts at/above the policy threshold; example 02 has clean and allowlisted commands; example 03 has enabled verification and a commented-out directive; example 04 has allowlisted callbacks and clean sibling-field/argument paths.

## 01 — Follow shared constraints across different APIs

`hashlib.pbkdf2_hmac(...)` supplies an algorithm string and positional count; `PBKDF2HMAC(...)` supplies a constructor expression and keyword count. The OR branches normalize these different AST shapes into `$ROUNDS`. The outer AND applies generation-entrypoint scope and the application's `0 < rounds < 600000` policy, then focuses the reported argument.

Near misses change algorithm, count, constant-versus-runtime value, or generation-versus-verification context. An unknown runtime count is unverified, not safe. The 600000 threshold is an explicit **application policy**, not a universal performance recommendation. There is no `fix`: replacing a count at one call can disagree with the stored count returned alongside a hash, breaking verification. The message instead describes migration-aware remediation.

## 02 — Follow label state, not function-name resemblance

```text
load_untrusted_job / read_untrusted_job_into
    → JOB
render_shell_command, requires JOB
    → JOB + SHELL
batch.add(command), explicit from/to side effect
    → labelled batch receiver
batch.pop()
    → run_shell(first argument), requires JOB and SHELL
```

The renderer adds `SHELL` only to a value that already carries `JOB`; clean rendering does not create the same signal. The propagator transfers labels onto a receiver whose mutation would otherwise be invisible to return-value propagation. A focused sink prevents tainted audit metadata from becoming executable command data.

The fixture compares using and discarding a sanitized return, an in-place allowlist followed by another write, source mutation before/after rendering, and sanitizer evaluation before/after a nested sink. A raw job sent directly to `run_shell` bypasses this **second-order** detector's intended transition; that is documented as an unsafe coverage boundary, not taught as a safe coding pattern.

## 03 — Generic structure without a primary regex search

Both candidate branches match a complete `location { ... }` token structure: upstream-before-verification and verification-before-upstream. `$...UPSTREAM` retains `https://`, host punctuation, ports, and variables that a one-word metavariable would lose. The regex constrains only that bound URL; it does not discover candidates by searching the whole file.

A single `fix: 'on'` replaces the focused value, preserving the rest of the location and trailing comments. It fails closed but may break connectivity without an appropriate trusted CA; inspect the dry run and deploy through normal configuration validation. Generic matching does **not** evaluate Nginx inheritance, includes, defaults, or variable expansion. The 20-line ellipsis span is a stated matching limit, not an assertion about valid Nginx block sizes.

## 04 — Follow a real multi-hop program

Unlike example 02's external model APIs, the factory, constructor, methods, allowlist helper, and callback dispatcher here have real bodies. Only the HTTP reader and shell boundary remain external. No extra source pattern on `load_command()` callers and no custom propagator manufacture the cross-function result.

The two unsafe paths reach different sink sites: a `map` lambda and a named function passed through `apply_command`. Safe paths retain the same source and object machinery but change the callback's validation, the selected field, or the dangerous argument. Run once without `--taint-intrafile` and once with it: **0 versus 2 findings** on the verified version.

Two native 1.30.0 limits were reproduced while building this example and are documented rather than silently generalized away:

- `self.pending = []; self.pending.append(command)` in the constructor lost the unsafe flow; the single-expression `self.pending = [command]` form works.
- Hiding `allowlisted_command` behind `checked_command` inside the inline lambda produced a false positive. The lambda uses the directly modelled sanitizer; the separate named callback still exercises the wrapper's inferred safe return.

These are limitations of the observed code shapes, not a recommendation to rewrite production code merely to satisfy the scanner. See [compatibility](../references/compatibility.md).

## Run from the skill root

Required pre-commit/publication syntax gate (**network-enabled**, because 1.30.0 fetches registry lint rules):

```sh
opengrep --version
opengrep validate examples/
```

Local annotated tests (**no registry configuration required**):

```sh
opengrep test --strict -c examples/01-structural/structural.yaml examples/01-structural/structural.py
opengrep test --strict -c examples/02-taint/taint.yaml examples/02-taint/taint.py
opengrep test --strict -c examples/03-config/config.yaml examples/03-config/config.generic
opengrep test --strict --taint-intrafile -c examples/04-intrafile/intrafile.yaml examples/04-intrafile/intrafile.py
```

Actual scans, including the flag comparison and fix preview:

```sh
opengrep scan --disable-version-check --strict --no-rewrite-rule-ids -c examples/01-structural/structural.yaml examples/01-structural/structural.py
opengrep scan --disable-version-check --strict --no-rewrite-rule-ids --dataflow-traces -c examples/02-taint/taint.yaml examples/02-taint/taint.py
opengrep scan --disable-version-check --strict --no-rewrite-rule-ids --autofix --dryrun -c examples/03-config/config.yaml examples/03-config/config.generic
opengrep scan --disable-version-check --strict --no-rewrite-rule-ids -c examples/04-intrafile/intrafile.yaml examples/04-intrafile/intrafile.py
opengrep scan --disable-version-check --strict --no-rewrite-rule-ids --taint-intrafile --dataflow-traces -c examples/04-intrafile/intrafile.yaml examples/04-intrafile/intrafile.py
```

Use explicit original fixtures, not the whole directory, to avoid scanning `.fixed` output as another target. Native `test` checks the configuration golden. A fix preview does not authorize edits to application files.

## Verification and release policy

Verified on native **OpenGrep 1.30.0**, Linux x86-64, 2026-10-03:

- Syntax validation: **4 rules**, **0 fatal errors**, **0 skippable errors**.
- All four annotated rule tests and the configuration golden passed.
- Network-isolated real scans: exactly **17 expected finding locations**, all **26 `ok` annotations** excluded, zero scan errors; rendered messages have no unresolved metavariables.
- Intrafile mode comparison: **0 without / 2 with**; all four negative sites remain clear.
- Copied configuration target: dry run preserved bytes; actual autofix equalled the golden byte-for-byte.
- Every rule uses structural primary matching, LOW confidence, technology metadata, and a WHAT/WHY/HOW message.

No real-codebase confidence calibration or large-codebase benchmark is claimed. The [authoring policy and decision record](../references/authoring-policy.md) preserves every requested rule and explains the deliberate refinements: native OpenGrep validation, optional additional Semgrep validation for dual-engine claims, honest calibration, and measured rather than blanket performance claims.
