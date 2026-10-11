# Sources and adaptation notes

## Upstream guide basis

This bundle is an original, task-oriented consolidation of the Rust guides in
**StructWeave-Algorithms**, pinned to Rust-content revision
`49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`. The upstream MIT notice is preserved
in [LICENSE.upstream](../LICENSE.upstream).

| Pinned chapter | Material retained and destination |
|---|---|
| [06 — Concurrency](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/06-concurrency.md) | Threads, move captures, channels, shared state, Send/Sync, async, Rayon, producer-consumer, pool lifecycle, alternating-worker predicates, bounded-buffer termination, and parallel-sum boundaries. Distributed across all three references. |
| [17 — Standard Library Essentials](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/17-std-library-essentials.md#synchronization-stdsync) | Synchronization section: Arc, Mutex/poisoning, RwLock, mpsc, atomics, Once/OnceLock. Consolidated in threads-and-state. |
| [12 — Anti-Patterns and Best Practices](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/12-anti-patterns-best-practices.md#blocking-in-async) | Blocking in async, inappropriate sharing/cloning, and failure propagation at concurrency boundaries. Applied to runtime selection and supervision. |
| [13 — Interview Trap Questions](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md#concurrency-traps) | Send/Sync confusion, Arc/Mutex nesting, blocking futures, and guards across await. Reworked as design and diagnostic decisions rather than interview quizzes. |

## Deliberate corrections and consolidation

- Replace unqualified "thread-safe" wrapper tables with conditional trait
  bounds. `Arc` does not make arbitrary data safe; `RefCell<T>` may be `Send`
  without being `Sync`. Transfer safety and lifetime bounds are independent.
- Replace "if it compiles" and "no runtime overhead" conclusions with explicit
  invariant, liveness, failure, and resource obligations.
- Keep standard mutexes in suitable async critical sections. Distinguish them
  from Tokio mutexes, whose guards can span suspension but do not guarantee
  deadlock freedom or restore state after cancellation.
- Preserve the legitimate immutable-snapshot use of `Mutex<Arc<T>>`, rather
  than calling that nesting useless. It has different observer semantics from
  `Arc<Mutex<T>>`.
- Replace an incomplete custom thread pool/parallel-map recipe with lifecycle
  requirements and existing-pool selection. Replace copied per-chunk inputs
  with scoped borrowing; cover empty work, nonzero worker counts, widened
  arithmetic, and explicit completion in runnable examples.
- Prefer standard bounded channels over a hand-written buffer without closure
  semantics. Preserve condition-variable predicates and final wakeup reasoning.
- Remove fixed Rayon speedup/size thresholds and unneeded runtime-market-status
  claims. Runtime choice follows project compatibility; performance follows
  measurement. External-crate guidance is explicit prose, not incomplete Rust
  snippets disguised as doctests.
- Expand the upstream async overview using Tokio's actual contracts: losing
  `select!` branches, lost send payloads, reserved permits, detached handles,
  non-abortable blocking jobs, backpressure, and graceful shutdown.

## First-party references

The following API documentation informed the safety and lifecycle guidance.
`latest` and Rust stable URLs evolve; use the version resolved by the consuming
project. Pinned source URLs record the details consulted for cancellation and
reduction semantics, not a requirement to upgrade dependencies.

### Standard library

- [Thread spawn bounds, joining, and creation failure](https://doc.rust-lang.org/std/thread/fn.spawn.html)
- [Scoped borrowing and panic handling](https://doc.rust-lang.org/std/thread/fn.scope.html)
- [Sync definition and reference bounds](https://doc.rust-lang.org/std/marker/trait.Sync.html)
- [Arc thread safety and weak ownership](https://doc.rust-lang.org/std/sync/struct.Arc.html)
- [Mutex access and advisory poisoning](https://doc.rust-lang.org/std/sync/struct.Mutex.html)
- [RwLock reader/writer policy and poisoning](https://doc.rust-lang.org/std/sync/struct.RwLock.html)
- [Bounded and rendezvous channels](https://doc.rust-lang.org/std/sync/mpsc/fn.sync_channel.html)
- [Condition-variable wait predicates and spurious wakeups](https://doc.rust-lang.org/std/sync/struct.Condvar.html)
- [Atomic memory orderings](https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html)
- [OnceLock initialization and reentrancy](https://doc.rust-lang.org/std/sync/struct.OnceLock.html)

### Tokio

- [Task spawning and Send/static boundaries](https://tokio.rs/tokio/tutorial/spawning)
- [Shared state and synchronous mutexes](https://tokio.rs/tokio/tutorial/shared-state)
- [Async mutex semantics](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html)
- [Local task spawning](https://docs.rs/tokio/latest/tokio/task/fn.spawn_local.html)
- [Select fairness, branch lifecycle, cancellation safety](https://docs.rs/tokio/latest/tokio/macro.select.html)
- [Mpsc backpressure, closure, and sync/async bridging](https://docs.rs/tokio/latest/tokio/sync/mpsc/index.html)
- [Sender payload ownership and permits](https://docs.rs/tokio/latest/tokio/sync/mpsc/struct.Sender.html)
- [Bounded-channel implementation documentation, Tokio 1.53.2](https://docs.rs/tokio/1.53.2/src/tokio/sync/mpsc/bounded.rs.html)
- [Broadcast lag and closure](https://docs.rs/tokio/latest/tokio/sync/broadcast/index.html)
- [JoinHandle detachment and nested results](https://docs.rs/tokio/latest/tokio/task/struct.JoinHandle.html)
- [JoinSet task collection and drop](https://docs.rs/tokio/latest/tokio/task/struct.JoinSet.html)
- [Blocking pool limits and abort/shutdown behavior](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html)
- [Graceful shutdown: detection, notification, completion](https://tokio.rs/tokio/topics/shutdown)

### Rayon

- [Parallel iterator entry points](https://docs.rs/rayon/latest/rayon/iter/index.html)
- [ParallelIterator operations](https://docs.rs/rayon/latest/rayon/iter/trait.ParallelIterator.html)
- [Reduction, numerical ordering, and fallible traversal contracts, Rayon 1.12.0](https://docs.rs/rayon/1.12.0/src/rayon/iter/mod.rs.html)
