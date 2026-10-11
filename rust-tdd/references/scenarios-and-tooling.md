# Async, concurrency, CLI, and test tooling

The scenario workflows come from [chapter 18](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/18-test-driven-development.md);
test-command and CI guidance consolidates [chapter 07](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/07-tooling-workflow.md).
Run these workflows in the target Rust project, not in this Markdown collection.

## Cargo: select the test you intend to observe

[Cargo's test reference](https://doc.rust-lang.org/cargo/commands/cargo-test.html)
distinguishes Cargo arguments from harness arguments after `--`.

| Command | Scope / trap |
|---|---|
| `cargo test` | Selected package/workspace-default members; unit, integration, library doctests subject to manifest settings |
| `cargo test --workspace` | All workspace members rather than assuming defaults include them |
| `cargo test reserve` | Substring name filter; check selected test count |
| `cargo test --lib tests::reserves_exact_remaining_inventory -- --exact` | Exact fully qualified unit-test name; substitute the actual discovered name |
| `cargo test --test cli` | Integration target `tests/cli.rs`, not a test-function name |
| `cargo test --doc` | Library documentation tests only |
| `cargo test --all-targets` | Lib/bin/tests/benches/examples; does not include doctests |
| `cargo test -- --list` | List discovered tests and their names |
| `cargo test -- --nocapture` | Show output, including passing tests |
| `cargo test -- --ignored` | Only ignored tests; arrange their required services first |
| `cargo test -- --include-ignored` | Include ignored as well as ordinary tests |
| `cargo test -- --test-threads=1` | Serial harness execution; diagnostic aid, not a synchronization fix |
| `cargo test --release` | Exercise optimized/release-profile behavior |
| `cargo test --no-run` | Compile only; no green behavioral evidence |

`cargo test --tests` is not “only integration tests”: it includes targets enabled
for testing, including library/binary unit tests by default. `--no-fail-fast`
continues across failing test executables; the ordinary harness already runs its
selected tests to completion. Custom harnesses may interpret arguments differently.

Test binaries normally run from their package root. Do not hard-code the shell's
current directory or an assumed workspace root into fixtures. Use package-relative
committed input files or per-test temporary directories. Tests within a harness
can run concurrently; changing global environment/current directory is not a
safe substitute for injecting configuration or using a child process environment.

## Async: assert results and lifecycle, not just completion

Start with one observable contract: a request returns a specific value/error,
a canceled operation leaves state valid, or shutdown drains accepted work.
Create a deterministic failing case before implementing that behavior. Use the
project's runtime, not a second runtime just for tests.

For Tokio, [the test macro documentation](https://docs.rs/tokio/latest/tokio/attr.test.html)
defines these feature requirements:

| Test behavior | Tokio features / setup |
|---|---|
| `#[tokio::test]` | `macros`, `rt`; defaults to a separate current-thread runtime per test |
| Timers and timeout | Add `time` |
| Channels / synchronization | Add `sync` for these APIs |
| `flavor = "multi_thread"` | Add `rt-multi-thread`; use when the contract actually needs this scheduler |
| `start_paused = true` | Add `test-util`; paused-time testing uses a current-thread runtime |

A concrete timeout workflow for a project function returning `Result<Response, E>`:

1. Arrange a controlled responder rather than a live Internet endpoint. Use a
   channel to report that the request reached the intended phase.
2. Run the real operation under `tokio::time::timeout`; assert both layers of
   the result. `Ok(Err(e))` means it completed with an operation error, not success.
3. For a deadline rule, use paused Tokio time and explicit readiness coordination;
   assert the event/value when time crosses the promised boundary. Do not compare
   wall-clock elapsed time or sleep “long enough.”
4. Cover cancellation separately: arrange the pending phase, drop/cancel the
   operation, and assert the promised cleanup/state. Whether partial side effects
   are allowed is a production contract, not decided by the timeout helper.
5. Await owned task handles and inspect `JoinError` as well as the task's own
   result. Signal/abort and join remaining work on error paths too.

[A Tokio timeout](https://docs.rs/tokio/latest/tokio/time/fn.timeout.html) cannot
preempt blocking or non-yielding code. Dropping a timeout around a borrowed or
owned task handle is not equivalent to stopping the spawned task: retain control,
abort if appropriate, and await cleanup. Runtime timeouts do not replace a CI
job-level watchdog. `join!` concurrently polls futures but does not by itself
prove parallel execution or explore every schedule. Hand off production runtime,
backpressure, and shutdown redesign to optional **rust-concurrency**.

## Concurrent logic: assert a shared invariant

For inventory shared by two callers, the contract is “one item can be reserved
once, and stock never becomes negative.” A red regression for split check/update
logic should coordinate the contested phase through a test seam, not hope a
sleep exposes the race. Fix the whole check-and-update critical section.

This dependency-free green example performs the check and update under one lock,
joins both workers, and asserts conservation. It is one concurrent execution,
not proof that every schedule or a different implementation is correct.

```rust
use std::sync::Mutex;
use std::thread;

fn take_one(stock: &Mutex<u32>) -> bool {
    let mut available = stock.lock().expect("stock lock poisoned");
    match available.checked_sub(1) {
        Some(remaining) => {
            *available = remaining;
            true
        }
        None => false,
    }
}

let stock = Mutex::new(1);
let successful = thread::scope(|scope| {
    let first = scope.spawn(|| take_one(&stock));
    let second = scope.spawn(|| take_one(&stock));
    let first = first.join().expect("first worker panicked");
    let second = second.join().expect("second worker panicked");
    u32::from(first) + u32::from(second)
});
assert_eq!(successful, 1);
assert_eq!(*stock.lock().unwrap(), 0);
assert!(!take_one(&stock));
```

Use channels, barriers, or explicit state signals to arrange a meaningful
interleaving; synchronization used only by the test can accidentally remove the
production race, so inspect what it orders. Join every worker and surface its
panic. Bounded stress tests may expose bugs but a passing stress test is not a
proof of race freedom, deadlock freedom, or correct relaxed memory ordering.

For small synchronization algorithms, [Loom](https://docs.rs/loom/latest/loom/)
can explore schedules with model-aware synchronization. The code under test,
not merely an empty `loom::model` closure, must use Loom's corresponding primitives
under a project-defined configuration. Route all relevant nondeterminism through
the model, include assertions, and use small state spaces. If using `cfg(loom)`,
register it with the project's check-cfg lint configuration and run the model
suite separately. Document preemption/exploration bounds; uninstrumented standard
synchronization and external I/O are not magically modeled. Keep ordinary runtime
integration tests as well as model tests.

## CLI: assert the user's boundary

Develop parsing/domain rules in fast unit tests, then exercise the actual built
binary from an integration test. Cargo supplies `CARGO_BIN_EXE_<name>` there;
for a binary named `inventory`, use `env!("CARGO_BIN_EXE_inventory")` with
`std::process::Command`. This is preferable to guessing `target/debug` paths or
recursively invoking `cargo run` inside the test. An existing `assert_cmd` plus
`predicates` setup is also appropriate; follow its installed version's API.

A concrete feature/bug regression matrix:

| Scenario | Setup and observable assertions |
|---|---|
| Help | `--help`; success, expected usage text on stdout, appropriate stderr |
| Unknown flag | Invalid flag; non-success (specific code if promised), useful stderr, no unintended output/file mutation |
| Valid input | Controlled stdin or fixture path; exact meaningful output and success status |
| Invalid file | Per-test malformed/missing file; domain diagnostic, failure status, original data preserved |
| Environment override | Configure the child with `.env(...)`; assert precedence over default/config as specified |
| Working directory | `.current_dir(...)` on the child, isolated temporary directory; verify relative path behavior |

Close piped stdin after writing so a child waiting for EOF can finish. For large
bidirectional streams, arrange concurrent I/O or use existing helpers to avoid
filling pipes while both processes wait. Capture and assert stdout, stderr, and
status separately. `output()` waits without a built-in timeout; use the project's
process-timeout facility and ensure a timed-out child is killed and reaped, plus
a CI watchdog. A failed status alone is not a sufficient oracle if a process
could fail during unrelated setup. Keep temporary directory guards alive until
the child and output assertions finish. Avoid shared fixed ports/files.

## CI: make supported behavior visible

Reuse existing CI rather than introducing another workflow or dependency manager.
From chapter 07, retain formatting/lint/test gates but explicitly choose the
workspace, feature set, platform, and toolchain that the project supports.
Typical commands, when the necessary components and committed lockfile exist:

```sh
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo test --workspace --locked
```

If CI instead uses `cargo test --workspace --all-targets --locked`, add
`cargo test --workspace --doc --locked` for documentation examples. Test
`--no-default-features` and supported feature combinations when their behavior
matters; `--all-features` is not appropriate for mutually exclusive backends and
does not test absence of a default feature. Apply chosen feature flags consistently
to test/lint jobs. Cross-compilation alone does not execute a target's tests.

Check the declared MSRV as well as the project's primary toolchain when MSRV is
promised. Install rustfmt/Clippy using that environment's toolchain mechanism;
do not assume rustup is installed. Cache dependencies/build artifacts by the
relevant toolchain and dependency state, not test results. Keep ignored/service
suites in explicit provisioned jobs with their own deadlines. A green default
job that silently excludes the changed code is not acceptance evidence.

## Coverage: find omissions, then judge the assertion

[cargo-llvm-cov](https://github.com/taiki-e/cargo-llvm-cov) wraps Rust's LLVM
instrumentation. Once the tool and compatible LLVM tools are available:

```sh
cargo llvm-cov --workspace --show-missing-lines
cargo llvm-cov --workspace --html
```

Use a supported installation/version matching the toolchain. On rustup-managed
systems this often includes `llvm-tools-preview`; other distributions can provide
compatible LLVM tools. Do not claim the command exists without checking the
project environment. At the consulted tool revision, branch coverage and doctest
coverage are optional nightly-dependent modes; consult its current documentation
before adding `--branch` or `--doctests` to CI.

Interpret line/region coverage as execution evidence, not assertion quality:

- A single integer division line can execute while zero divisors and `MIN / -1`
  remain untested. High line coverage does not establish a complete input domain.
- Missing lines may reveal error paths, feature-gated code, or an unexecuted
  adapter. Decide which risk deserves a test rather than gaming the denominator.
- Review exclusions, feature/platform scope, generated code, and doctest support
  before comparing reports. A percentage with a different denominator is not
  a meaningful regression by itself.
- Never replace assertions with “it ran,” impose a universal coverage target,
  or pass a failing test job because a report was generated. Coverage does not
  prove unsafe soundness, concurrency correctness, or security.

Tarpaulin is an alternative coverage runner when supported by the project's
platform/engine; grcov can process coverage data in an established pipeline.
Do not copy old branch flags or assume all coverage requires nightly:
[`-C instrument-coverage`](https://doc.rust-lang.org/rustc/instrument-coverage.html)
is the underlying instrumentation mechanism, while optional reporting modes have
their own requirements. Preserve an existing working pipeline rather than adding
three coverage tools. Use optional **test-engineering** for risk allocation and
**rust-performance** for measurement; neither a pyramid ratio nor a coverage
number substitutes for the missing behavioral assertion.
