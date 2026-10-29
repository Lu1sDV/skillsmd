# CPU parallelism and concurrency diagnostics

## Select the execution mechanism

| Workload | Prefer | Why / boundary |
|---|---|---|
| Small or cheap computation | Sequential iterator/function | Avoid scheduling work that does not justify scheduling overhead |
| Independent CPU-heavy collection work | Rayon parallel iterators | Pool-managed decomposition instead of a custom queue and result lock |
| A small fixed set of borrowed computations | Scoped threads | Explicit lifetime and join boundary without cloning input |
| Persistent blocking service or thread-affine synchronous API | Dedicated thread with a stop protocol | Does not occupy the runtime's finite blocking pool indefinitely |
| Finite blocking library call from async code | Bounded `spawn_blocking` submission | Keeps the call off async worker threads; started work is not abortable |
| Many mostly idle network operations | Existing async runtime | Multiplex waiting operations rather than one OS thread per idle connection |

There is no universal element-count threshold for Rayon, nor a promise that
parallel sorting or mapping is faster for a particular input size. Measure
representative work and resource limits. Hand measured tuning to
**rust-performance**, if installed; this reference owns correctness and progress.
See [Rayon iterators](https://docs.rs/rayon/latest/rayon/iter/index.html) and
[Tokio blocking work](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html).

## Rayon semantic checklist

Rayon is an external dependency. Use the version compatible with the project's
MSRV and import its `rayon::prelude::*` traits. The following are API selection
recipes, not standalone Rust programs:

- `par_iter()` borrows input; `par_iter_mut()` partitions mutable access;
  `into_par_iter()` consumes owned items. Do not clone a whole collection just
  to move each chunk into a thread when borrowing or moving items suffices.
- Map each item to its result and collect, rather than sharing one locked
  output vector. For an ordered slice pipeline, collecting a mapped parallel
  iterator into `Vec` preserves its logical order; execution and side effects
  can occur in a different order. Unordered sources do not gain an order.
- Use `find_any` only when any match is acceptable. Use `find_first` when the
  logical first match is part of the contract. `take_any` and `skip_any` do not
  mean the first or last elements of an ordered sequence.
- A parallel `reduce` needs a true identity and an associative operation for
  grouping-independent results. Parallel `fold` creates multiple partial
  accumulators; reduce them explicitly. Floating-point addition is not
  associative, so parallel sums can differ from sequential sums and between
  decompositions. Define tolerance or use a deterministic numerical algorithm
  when reproducibility is required.
- Widen or check integer arithmetic **before** multiplication/addition. Summing
  `0..1_000_000` into `i32` overflows; scheduling cannot repair the accumulator.
  Checked and saturating arithmetic can also change results under regrouping
  for some signed workloads, so define the actual reduction semantics.
- `try_for_each`/fallible reductions try to stop after failure, but concurrent
  side effects may already have occurred. Which error wins among concurrent
  failures can be unspecified. They are not all-or-nothing transactions.
- Avoid worker callbacks that block waiting for other work to run on the same
  saturated pool. Do not call a Rayon computation synchronously inside an
  async task and assume its internal threads make the caller nonblocking.
  Offload the synchronous entry or use a completion bridge supported by the
  chosen pool, with explicit input/output ownership and bounded submission.
- Do not allocate a fresh CPU pool per request or let nested executors each
  consume the full machine without a resource plan. Thread count is a resource
  policy, not a guarantee of available cores or throughput.

Sources: [`ParallelIterator`](https://docs.rs/rayon/latest/rayon/iter/trait.ParallelIterator.html),
[reduction contract](https://docs.rs/rayon/1.12.0/src/rayon/iter/mod.rs.html#953-980),
[fallible side-effect contract](https://docs.rs/rayon/1.12.0/src/rayon/iter/mod.rs.html#446-452).

## Dependency-free boundary check: scoped reduction

This example teaches input partitioning, not a production pool or a speedup
claim. It does not copy input chunks, treats empty work explicitly, uses a
nonzero worker count, and widens the accumulator. At most `workers` threads are
created, and no thread is created for an empty chunk. A real caller must choose
an appropriate worker bound; creating many tiny threads is not a tuning strategy.

```rust
use std::num::NonZeroUsize;
use std::thread;

fn parallel_sum(values: &[u32], workers: NonZeroUsize) -> u128 {
    if values.is_empty() {
        return 0;
    }
    let chunk_size = values.len().div_ceil(workers.get());
    thread::scope(|scope| {
        let handles: Vec<_> = values
            .chunks(chunk_size)
            .map(|chunk| {
                scope.spawn(move || chunk.iter().map(|&value| u128::from(value)).sum::<u128>())
            })
            .collect();
        handles
            .into_iter()
            .map(|handle| handle.join().expect("sum worker must not panic"))
            .sum()
    })
}

for count in [1, 3, 8] {
    let workers = NonZeroUsize::new(count).unwrap();
    assert_eq!(parallel_sum(&[], workers), 0);
    assert_eq!(parallel_sum(&[1, 2, 3, 4, 5], workers), 15);
    assert_eq!(parallel_sum(&[u32::MAX, u32::MAX], workers), 2 * u128::from(u32::MAX));
}
assert!(NonZeroUsize::new(0).is_none());
```

The `expect` treats panic as a failed executable check; an application may
instead join every worker and translate failures to its own error contract.
Scope semantics: [`thread::scope`](https://doc.rust-lang.org/std/thread/fn.scope.html).

## Investigate hangs by identifying waits

Start with the reported symptom, then trace the actual resource dependency.
Do not "fix" a hang by adding sleeps, dropping error results, increasing a
pool arbitrarily, or switching every mutex to an async mutex.

| Observation | Concrete path to inspect | Root-cause correction |
|---|---|---|
| Receiver loop never ends | Live sender clone, owner cycle, or reserved permit | Make producer/permit ownership and closure explicit |
| Shutdown waits for producer | Producer blocked on full queue; coordinator stopped consumer first | Drain concurrently or deliberately reject/discard work |
| Shutdown waits for blocking job | Synchronous call never returns; abort only affected a handle | Give the operation a real interrupt/termination mechanism |
| Worker cannot acquire a lock | Opposite lock order, recursive acquisition, or a join while holding its lock | Change ownership or establish one ordering; release before waiting |
| Async task runs alone | Blocking call or long non-yielding computation | Move work to the correct bounded execution resource |
| Repeated timeout loses a worker's progress | Fresh lock acquisition/future/timer every loop iteration | Preserve necessary future state and use a stable deadline |
| Memory grows despite a semaphore | Tasks spawned before admission, oversized payloads, retained completed results | Bound admission and result retention, not just active operations |
| Results appear missing | Early return, detached handle, cancelled send, dropped receiver, broadcast lag | Trace acceptance through completion and apply delivery semantics |
| Tests pass but state is wrong | Multi-step check/update split across locks or atomics | Protect the invariant as one operation |

Construct a wait-for graph with **threads/tasks, locks, queue capacity, replies,
and join handles** as nodes. A cycle is a candidate deadlock even if it contains
no mutex. A channel-based actor can await a reply from an actor waiting for its
own reply; moving shared state to channels alone does not prove progress.

Collect thread backtraces or existing task diagnostics while the failure is
present. For an async system, distinguish runtime starvation from a task that
is simply pending on I/O. Add narrowly scoped diagnostic instrumentation only
when needed to establish the path, not as an unrelated subsystem.

When the project uses `tracing`, do not hold a `Span::enter` / `entered` guard
across `.await`: yielding can attribute another task's events to that span even
on one thread. Use `#[instrument]` or `future.instrument(span)`, and attach the
intended context to spawned work. For synchronous sections, `span.in_scope` exits
the span before suspension. `#[instrument]` records arguments by default; select
`skip` / `skip_all` and explicit fields for sensitive or expensive-to-format values.
Sources: [async span handling](https://docs.rs/tracing/latest/tracing/span/struct.Span.html#in-asynchronous-code),
[instrumented fields](https://docs.rs/tracing/latest/tracing/attr.instrument.html).

## Regression checks for the discovered contract

Use deterministic channels, barriers, or condition variables to establish the
ordering that exposes a bug. Sleeps establish elapsed time, not that another
worker reached a specific state. Put timeouts around tests as a failure bound,
not as synchronization or proof of a production deadline.

Choose cases relevant to the implementation:

1. Zero jobs; one job; fewer jobs than workers; uneven partitions.
2. Full queue with a deliberately paused consumer; receiver disappearance;
   last sender dropped; shutdown with buffered work and reserved capacity.
3. Application error and worker panic separately; ensure remaining tasks are
   observed and no required work becomes detached on an early return.
4. Cancellation before acceptance, after acceptance, during a transfer, and
   after an external effect but before its acknowledgement.
5. Repeated signals and already-closed channels; no busy loop, accidental
   respawn, duplicate commit, or cancellation-triggered invariant break.

Use existing async test facilities for controlled time; do not mistake a test
that only waits until "eventually 10" for a proof of ordering. Where low-level
interleavings matter and the project uses a model checker such as Loom, model
the primitive with that tool's synchronization types; ordinary stress tests
sample schedules rather than exhaust them. If installed, **rust-tdd** owns the
red-green-refactor workflow and richer concurrent-test recipes.
