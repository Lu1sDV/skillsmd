---
name: rust-concurrency
description: >
  Use when implementing or debugging Rust threads, Send/Sync bounds, Arc and
  synchronization, channels, Tokio async tasks, cancellation, graceful shutdown,
  backpressure, deadlocks, or choosing Rayon for CPU-bound parallel work.
---

# Rust Concurrency

## Quick reference

| Need or symptom | Start with | Read next |
|---|---|---|
| Independent blocking work or a persistent worker | Owned OS thread; explicit join/shutdown | [Threads and shared state](references/threads-and-state.md) |
| Parallel work borrowing caller-owned data | `std::thread::scope`; split disjoint mutable slices | [Threads and shared state](references/threads-and-state.md) |
| Move work to one resource owner | Bounded channel; close, drain, join | [Threads and shared state](references/threads-and-state.md) |
| Share immutable data / a compound mutable invariant | `Arc<T>` / `Arc<Mutex<T>>`, with the required bounds | [Threads and shared state](references/threads-and-state.md) |
| Many concurrent I/O operations | Existing async runtime; bound admission and task count | [Async lifecycle](references/async-lifecycle.md) |
| `future cannot be sent between threads safely` | Inspect captures and state retained across suspension | [Async lifecycle](references/async-lifecycle.md) |
| Timeout, task cancellation, service shutdown | Identify the operation being dropped and its partial effects | [Async lifecycle](references/async-lifecycle.md) |
| Independent CPU-heavy items | Sequential baseline, then Rayon if justified | [Parallel work and diagnostics](references/parallel-work-and-diagnostics.md) |
| Hang despite compiling successfully | Draw the wait-for graph; inspect termination ownership | [Parallel work and diagnostics](references/parallel-work-and-diagnostics.md) |

Load only the relevant reference. Concurrency means overlapping progress;
parallelism means simultaneous execution. Neither guarantees lower latency.

## Establish the contract first

1. Read the package's edition, `rust-version`, selected runtime, dependency
   versions/features, and deployment target. Preserve the project's MSRV.
   Edition 2024 requires Rust 1.85; a new edition is not required for threads
   or async. Examples here use stable APIs compatible with that baseline.
2. Identify the owner of each resource, the invariant spanning its fields,
   and who may mutate it. Prefer ownership transfer or disjoint access over
   introducing shared mutation.
3. Classify work: asynchronous I/O, bounded blocking calls, persistent blocking
   loops, or CPU computation. Do not move every workload onto one executor.
4. Define limits for queued messages, payload sizes, active operations, and
   completed-but-uncollected results. Define what overload does: wait, reject,
   shed explicitly permitted work, or stop admission.
5. Define success and failure: what counts as accepted, completed, acknowledged,
   cancelled, and durably committed? A successful send is not processing success.
6. Define ownership of worker handles and the shutdown order before spawning.
   Every normal/error path must join, abort-and-observe, or deliberately transfer
   supervision; silently dropping handles is not graceful shutdown.

## Choose the smallest coordination mechanism

- **No sharing:** move an owned input and return an owned result. Use scoped
  threads when a join-before-return boundary allows borrowing instead of cloning.
- **Shared immutable input:** `Arc<T>` when independent ownership is needed;
  borrowed references inside a thread scope when it is not.
- **Short compound update:** a mutex around the entire invariant, not one lock
  per field. `RwLock` is a candidate when concurrent readers are useful, not an
  automatic improvement whenever reads outnumber writes.
- **One resource with asynchronous operations:** a task owning the resource plus
  commands and replies can make serialization and shutdown clearer than a lock.
- **Single atomic value:** an atomic read-modify-write can replace a mutex only
  when the invariant really fits that operation. Two atomic operations are not
  a transaction, even with `SeqCst`.
- **CPU data parallelism:** prefer Rayon to building a general-purpose worker
  pool. Keep its blocking computation off an async runtime's worker threads.

## Keep type safety and lifecycle separate

[`Send`](https://doc.rust-lang.org/std/thread/fn.spawn.html) permits moving a
value between threads. [`Sync`](https://doc.rust-lang.org/std/marker/trait.Sync.html)
means `&T: Send`. Neither implies `'static`, a particular lifetime, fairness,
atomic multi-step updates, or freedom from deadlocks.

- `Arc<T>` makes reference counting safe across threads, **not arbitrary `T`**.
  For the usual allocator, it is `Send + Sync` when `T: Send + Sync`.
  `Arc<RefCell<T>>` does not become a cross-thread shared mutable container.
- `Mutex<T>` is `Send + Sync` when `T: Send`; `T` need not be `Sync` because
  the lock serializes access. `RwLock<T>: Sync` needs `T: Send + Sync`.
- `thread::spawn` and `tokio::spawn` impose their own `Send + 'static` bounds
  on the work and output. `move` captures ownership; moving a borrowed
  reference does not extend the referent's lifetime.
- Safe Rust prevents data races when dependencies and unsafe implementations
  are sound. It does not prove the application protocol or progress correct.

## Minimal bounded pipeline

This dependency-free check covers an empty input and a queue smaller than the
workload. The consumer drains while the producer runs; joining the producer
first could deadlock on a full queue. Moving the only sender into the producer
makes its drop the end-of-input signal. `expect` is intentional in this check;
production code must apply its documented failure policy.

```rust
use std::sync::mpsc;
use std::thread;

fn sum_jobs(count: u32) -> u64 {
    let (tx, rx) = mpsc::sync_channel(1);
    let producer = thread::spawn(move || {
        for value in 0..count {
            tx.send(value).expect("consumer must remain alive");
        }
    });

    let total = rx.into_iter().map(u64::from).sum();
    producer.join().expect("producer must not panic");
    total
}

assert_eq!(sum_jobs(0), 0);
assert_eq!(sum_jobs(10), 45);
assert_eq!(sum_jobs(100), 4_950);
```

See [`sync_channel`](https://doc.rust-lang.org/std/sync/mpsc/fn.sync_channel.html)
for bounded blocking and zero-capacity rendezvous semantics.

## Async correctness gates

1. Use async I/O and timers on an executor. A long computation, synchronous
   receive, or blocking sleep inside `async fn` still blocks its worker thread.
2. Use a standard mutex only for short, low-contention sections without
   `.await`. A Tokio mutex may span `.await`, but it does not remove wait cycles
   or make partially updated state cancellation-safe.
3. For each `select!`/timeout, inspect the exact future's cancellation contract.
   Dropping a future does not roll back external effects; dropping a Tokio
   `JoinHandle` detaches its task rather than cancelling it.
4. Bound work **before** spawning or submitting it. A semaphore acquired inside
   millions of spawned tasks limits execution, not the waiting task backlog.
5. Stop admission, notify workers, apply the drain/discard policy, complete
   required cleanup, and observe all worker results. Escalate after an explicit
   deadline; started `spawn_blocking` work cannot be forcibly aborted by Tokio.

The [async reference](references/async-lifecycle.md) details channels, nested
errors, cancellation-safe operations, runtime boundaries, and shutdown.

## Completion criteria

- Ownership, required trait bounds, lock ordering, and task supervision are
  explicit; no unsafe `Send`/`Sync` workaround conceals a design error.
- Each queue and concurrency limit has a reason and an overload policy.
- Tests cover empty work, full queue, disconnected peer, worker failure,
  cancellation at a meaningful suspension point, and shutdown with queued work
  where applicable. Use handshakes, not sleeps, to establish event order.
- Required effects are not silently lost by `select!`, early `?`, detached tasks,
  discarded join errors, or a receiver dropped before draining.
- Report only checks actually executed; the [README](README.md) lists runnable
  documentation checks. Compilation alone does not establish liveness.

## Handoffs

If installed, use **rust-tdd** for red-green-refactor and regression-test design,
**rust-idiomatic** for general ownership/error handling, **rust-api-design** for
public async interfaces, and **rust-performance** for profiling and measured
contention, allocation, and scheduling changes. Manual unsafe concurrency
requires a proof review with **rust-unsafe-ffi**, if installed.

## Sources

Adapted from StructWeave chapters 06 and relevant portions of 12, 13, and 17;
see [source mapping and first-party references](references/sources.md).
