# Sources and adaptation notes

## Upstream basis

Original synthesis adapted from StructWeave-Algorithms by nirajkvinit, pinned to
Rust-content revision `49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`:

- [18 — Test-Driven Development](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/18-test-driven-development.md): primary methodology; red-green-refactor, QA partitions/boundaries, proptest, doubles, fixtures, coverage, testability, feature/bug/legacy workflows, async/concurrency/CLI cases, and exceptions to test-first development.
- [07 — Tooling and Development Workflow](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/07-tooling-workflow.md): Cargo test selection and formatting/lint/test CI gates. General editor, workspace, dependency, and debugging setup belongs to optional rust-idiomatic.

Both chapter contents were consulted, not just their topic lists. Upstream's MIT
notice is preserved in [LICENSE.upstream](../LICENSE.upstream). This is a
standalone TDD workflow skill, not a renamed all-purpose testing/tooling bundle.

## First-party technical references

- [Cargo test](https://doc.rust-lang.org/cargo/commands/cargo-test.html): target selection, filters, harness arguments, documentation tests, package working directories, CLI executable environment variables.
- [The Rust Book: automated tests](https://doc.rust-lang.org/book/ch11-00-testing.html): native test organization and assertions.
- [Proptest API](https://docs.rs/proptest/latest/proptest/) and [introduction](https://proptest-rs.github.io/proptest/intro.html): generated cases, properties, and shrinking.
- [Proptest runner configuration](https://docs.rs/proptest/latest/proptest/test_runner/struct.Config.html): failure persistence, rejection limits, shrink limits, case counts, and seed replay.
- [Mockall guide](https://docs.rs/mockall/latest/mockall/): call counts, ordered expectations, return closures, checkpoints, and async-trait constraints.
- [rstest guide](https://docs.rs/rstest/latest/rstest/): case rows, Cartesian value combinations, and fixtures.
- [Tokio test attribute](https://docs.rs/tokio/latest/tokio/attr.test.html): runtime choices, required features, paused time.
- [Tokio timeout](https://docs.rs/tokio/latest/tokio/time/fn.timeout.html): nested return values, cancellation, non-yielding work, and timer requirements.
- [Loom](https://docs.rs/loom/latest/loom/): model-aware primitives, configuration, state-space bounds, and unmodeled operations.
- [cargo-llvm-cov](https://github.com/taiki-e/cargo-llvm-cov): supported reporting modes and toolchain requirements.
- [rustc coverage instrumentation](https://doc.rust-lang.org/rustc/instrument-coverage.html): instrumentation, compatible LLVM tools, and interpretation of coverage statistics.

Library `latest` links are navigation aids, not dependency pins. Consult the
project's locked version and selected toolchain before using a macro option or
coverage mode; optional tool examples do not alter this repository's dependencies.

## Deliberate corrections and consolidation

- Removed unsupported empirical TDD defect-reduction statistics and prescriptive
  test-pyramid percentages, universal speed budgets, and absolute coverage targets.
  Keep the mechanism and risk-based decision, not an unjustified numeric promise.
- Replaced partial email validation and missing implementations with a complete
  checked reservation example. It asserts failure atomicity, exact exhaustion,
  zero, sequential calls, and maximum count; it does not claim to validate email.
- Separate red observations from predicted failures. A future implementation,
  a zero-test filter, or a setup failure cannot be reported as verified TDD.
- Treat new validation/error rules as new behavior, not a refactor. Retain legacy
  characterization as compatibility evidence, not approval of an accidental bug.
- Replaced generator-only properties and self-comparing sort examples with an
  independent conservation oracle. Random generation is not exhaustive proof;
  shrinking is constrained by strategy and limits rather than guaranteed globally minimal.
- Corrected Mockall response sequencing: repeated `.returning` setters do not
  produce a playlist; use separate count-constrained ordered expectations when
  ordering is contractual. Conditional unit-test mocks are not exported to a
  library's integration-test consumers.
- Corrected Cargo target scope: `--all-targets` omits doctests, `--tests` does not
  mean integration-only, and workspace defaults are not necessarily every member.
- Specified Tokio's `time`, `sync`, `test-util`, and multi-thread runtime features
  where relevant. A timeout is not a preemptive watchdog or automatic task cleanup.
- Replaced an empty Loom model with actionable model wiring requirements and an
  asserted ordinary threaded example. Passing a real-thread run is not exhaustive
  scheduling evidence; uninstrumented synchronization remains outside the model.
- Coverage modes have tool/version constraints. Removed unconditional branch
  flags and blanket nightly claims. Coverage tools cannot establish assertion
  quality, correct overflow semantics, or a proof of concurrency correctness.
- Preserve functional-core/imperative-shell guidance without requiring a trait
  for every dependency. Keep real adapter checks alongside test doubles.
