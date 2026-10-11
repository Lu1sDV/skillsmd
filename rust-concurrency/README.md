# rust-concurrency

A self-contained Rust skill for choosing concurrency mechanisms and making
ownership, progress, delivery, failure, and shutdown contracts explicit.

## Scope

- OS threads, scoped borrowing, move captures, joins, and worker failures.
- Conditional Send/Sync bounds, Arc ownership, mutexes, reader/writer locks,
  condition variables, atomics, and one-time initialization.
- Message passing versus shared state; bounded queues, producer-consumer
  termination, snapshots, and compound invariants.
- Tokio runtime boundaries, task ownership, cancellation-safe operations,
  deadlines, shutdown, overload/backpressure, and blocking-pool limitations.
- Rayon selection and ordering/reduction semantics; diagnostics for deadlocks,
  starvation, detached work, lost messages, and unbounded backlogs.

Measured optimization belongs to the optional **rust-performance** skill;
general Rust ownership and errors to **rust-idiomatic**; test-first development
to standalone **rust-tdd**. None is required to install this bundle.

## Install

From the repository checkout:

```bash
mkdir -p ~/.claude/skills
cp -r rust-concurrency ~/.claude/skills/
```

Copy the entire directory so internal reference links and attribution remain
available. This instruction does not require a plugin marketplace manifest.

## Usage prompts

- "Review this Rust worker queue for backpressure and shutdown deadlocks."
- "Explain this Tokio future-is-not-Send error without adding unsafe impls."
- "Make cancellation of this select loop preserve partially received data."
- "Choose scoped threads, Rayon, or spawn_blocking for this CPU pipeline."
- "Does this Arc/Mutex arrangement update existing readers or replace snapshots?"

## Reference index

| File | Read when |
|---|---|
| [SKILL.md](SKILL.md) | Selecting a mechanism and establishing the end-to-end contract |
| [Threads and shared state](references/threads-and-state.md) | Working with threads, trait bounds, locks, channels, wait predicates, atomics, initialization |
| [Async lifecycle](references/async-lifecycle.md) | Working with runtimes, task supervision, cancellation, backpressure, shutdown |
| [Parallel work and diagnostics](references/parallel-work-and-diagnostics.md) | Choosing Rayon, preserving result semantics, investigating hangs or resource growth |
| [Sources](references/sources.md) | Checking pinned upstream coverage, first-party contracts, and adaptation decisions |

## Runnable documentation checks

From the checkout, run each command separately. These exercise the complete,
dependency-free Rust fences: bounded queue empty/drain behavior, disjoint scoped
mutation, immutable snapshots, a condition-variable predicate, and parallel-sum
empty/uneven/wide-value boundaries. They are verification instructions, not a
claim that the commands have already passed.

```bash
rustdoc --test --edition=2024 rust-concurrency/SKILL.md
rustdoc --test --edition=2024 rust-concurrency/references/threads-and-state.md
rustdoc --test --edition=2024 rust-concurrency/references/parallel-work-and-diagnostics.md
```

After installation, the same checks can run independently of this repository:

```bash
rustdoc --test --edition=2024 ~/.claude/skills/rust-concurrency/SKILL.md
rustdoc --test --edition=2024 ~/.claude/skills/rust-concurrency/references/threads-and-state.md
rustdoc --test --edition=2024 ~/.claude/skills/rust-concurrency/references/parallel-work-and-diagnostics.md
```

Rust 1.85 or later supports the edition used by these commands. Consuming
projects must use their own declared MSRV/edition and compatible dependency
versions. Tokio and Rayon guidance is presented as API/protocol recipes; these
standard-library checks do not validate a consuming application's async runtime
configuration, cancellation policy, or all possible thread schedules.

## Consolidation and attribution

Adapted from StructWeave-Algorithms chapter 06 plus synchronization in 17,
blocking/coordination antipatterns in 12, and concurrency traps in 13, pinned to
`49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`. See the
[pinned source map](references/sources.md) and [upstream MIT notice](LICENSE.upstream).

The material is organized by real tasks rather than chapter/interview order.
Custom pool and buffer sketches are replaced with standard primitives and
explicit lifecycle obligations; source overstatements about Arc, automatic
thread safety, lock selection, and universal Rayon gains are corrected.
Cancellation, reserved capacity, nested task errors, and shutdown are expanded
from first-party Tokio/std documentation. No runtime dependency is installed by
copying this skill, and no incomplete Rust example is hidden behind an ignored
code fence.
