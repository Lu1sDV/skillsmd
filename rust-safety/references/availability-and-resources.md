# Availability, resources, and interrupted state

## Contents

- [Find the harmed consumer](#find-the-harmed-consumer)
- [Recursive values have several lifecycles](#recursive-values-have-several-lifecycles)
- [Bound memory, work, and expansion](#bound-memory-work-and-expansion)
- [Panics and recovery are not rollback](#panics-and-recovery-are-not-rollback)
- [Concurrency and cancellation](#concurrency-and-cancellation)
- [Verification scenarios](#verification-scenarios)

## Find the harmed consumer

A reachable panic is not automatically a process-wide denial of service. Establish
input control, repetition/concurrency, the executing task/thread/process, shared
capacity, panic strategy, and recovery. A rejected request, dead request task,
starved worker, and terminated service have different consequences. A panic in
an unsafe abstraction also needs a separate memory-invariant review.

| Surface | Trace | Do not accept as proof |
|---|---|---|
| `unwrap`, indexing, `assert!`, `RefCell::borrow_mut` | Can an allowed input or callback reach the failure, and what contains it? | The API name alone |
| Recursive values | Every constructor and consuming traversal, including cleanup | A parser-only depth check |
| Allocation or expensive work | Declared versus actual sizes, output expansion, aggregate retained state | Small request bytes or `try_reserve` alone |
| Locks, permits, queues | Acquisition, ownership, release, cancellation, shared waiters | `Send + Sync` or a bounded queue alone |
| Hashing/comparison | Key control, hasher, comparator laws, cardinality | Memory safety implies bounded execution |

[`catch_unwind`](https://doc.rust-lang.org/std/panic/fn.catch_unwind.html) catches
unwinding panics, not process aborts. A stack overflow is not recovered by that
API; ordinary supported-runtime executions can abort the entire process. Do not
promise a universal signal number or stack threshold across targets/builds.

## Recursive values have several lifecycles

Inventory recursive ownership (`Box`, `Vec`, `Rc`/`Arc`, nested map/enum values),
then follow **construction → parse → transform/compose → format/serialize → drop**.
Inspect implicit derived `Debug`, `Clone`, comparisons, and destructor glue too.
An attacker may build depth through repeated operations rather than one document.
Rejecting a partially constructed value can itself invoke recursive cleanup.

For each traversal, establish an enforced bound or a suitable iterative design.
If an earlier bound is relied on, prove that every construction path preserves it
and that it is adequate for this traversal and supported stack/build. Increasing
thread stack size only moves the threshold; stack growth is not a CPU/memory quota.

The `serde_json` **`unbounded_depth` feature only exposes an opt-out method**;
calling `disable_recursion_limit()` disables the guard for that deserializer.
Inspect the pinned crate version, enabled features, target type, and entry method.
Do not publish a universal safe depth or assume typed and dynamic decoding paths
share every budget. A `serde_stacker` deserializer does not protect later `Debug`,
`Display`, or `Drop`; a serializer adapter covers only serialization through it.
[serde_json method contract](https://docs.rs/serde_json/latest/serde_json/struct.Deserializer.html#method.disable_recursion_limit),
[David Tolnay's serde_stacker documentation](https://docs.rs/serde_stacker/latest/serde_stacker/).

### A complete iterative-destruction example

This scalar-payload chain illustrates removing recursive ownership before each
node is dropped. It is not a generic container: arbitrary payload destructors,
callbacks, and fallible teardown require their own panic/invariant analysis.

```rust
use std::cell::Cell;

struct Node<'a> {
    next: Option<Box<Node<'a>>>,
    drops: &'a Cell<usize>,
}

impl Drop for Node<'_> {
    fn drop(&mut self) {
        self.drops.set(self.drops.get() + 1);
        while let Some(mut node) = self.next.take() {
            self.next = node.next.take();
            // node now owns no successor, so its destructor cannot recurse.
        }
    }
}

let drops = Cell::new(0);
let mut chain = None;
for _ in 0..10_000 {
    chain = Some(Box::new(Node { next: chain, drops: &drops }));
}
drop(chain);
assert_eq!(drops.get(), 10_000);
```

Compare with the iterative value cleanup in the maintainer's
[serde_stacker examples](https://docs.rs/serde_stacker/latest/serde_stacker/).
No small example proves a deployed parser's maximum safe depth.

## Bound memory, work, and expansion

- Treat size hints, declared lengths, peer-supplied iteration counts, and record
  counts as inputs, not allocation authority. Validate the domain, convert with
  `try_from`, and use checked byte/count arithmetic **before** allocation or work.
  `usize::try_from(n)` proves representability, not a protocol quota or buffer bound.
- Bound encoded bytes, decoded bytes, records, nesting, expansion, CPU work,
  concurrent operations, and retained output where relevant. Test all decoder
  entry paths and intermediate forms. A compressed-input cap does not cap output.
- `try_reserve` offers a fallible allocation attempt; it is not a size policy and
  does not guarantee later allocations, allocator behavior, or OS memory pressure
  are recoverable. A zero-sized element type can have huge counts without backing
  allocation: byte limits alone do not bound iteration or destruction work.
  [Vec capacity/try_reserve](https://doc.rust-lang.org/std/vec/struct.Vec.html#method.try_reserve),
  [allocation-error contract](https://doc.rust-lang.org/std/alloc/fn.handle_alloc_error.html).
- For streams, distinguish real EOF from reaching a limit, reject oversized
  records rather than silently accepting a prefix, and apply transport deadlines.
  The [bounded-read example](input-and-os-boundaries.md#bounded-input-is-not-truncated-success)
  enforces byte limits, not deadlines or generic OOM recovery.
- Keep the default randomized `HashMap` hasher for attacker-selected keys unless
  the replacement's security and quota assumptions are established. A fixed
  hasher chosen to permit const initialization is not equivalent protection.
  HashDoS resistance still does not bound total keys/bytes.
  [HashMap security and const construction](https://doc.rust-lang.org/std/collections/struct.HashMap.html),
  [Nicholas Nethercote on hashing tradeoffs](https://nnethercote.github.io/perf-book/hashing.html).
- Check application numeric invariants, not merely overflow. Floating-point NaN
  can defeat ordered comparisons; std sorts require a total order and may panic
  when it is violated. Decide whether non-finite values are valid domain input;
  `total_cmp` supplies an order, not domain validation. Do not label an invalid
  safe `Ord` implementation itself UB.
  [slice sorting contract](https://doc.rust-lang.org/std/primitive.slice.html#method.sort),
  [Ord safety boundary](https://doc.rust-lang.org/std/cmp/trait.Ord.html).

## Panics and recovery are not rollback

Use `Result` for expected malformed input and resource limits. If panic recovery
is an explicit boundary, check `panic=unwind`, where recovery occurs, and the state
that remains usable afterwards. `AssertUnwindSafe` asserts a property; it does
not restore state. Do not resume a half-updated security-sensitive operation as
success. Destruction of a caught panic payload can itself panic; see the
[FFI unwind policy](c-boundaries.md#rust-2024-syntax-and-unwinding).

`Mutex` poisoning is advisory, not a reliable safety barrier. A panic can poison
shared state and repeated `lock().unwrap()` calls can amplify the failure; blindly
recovering with `into_inner()` is not invariant repair either. Unsafe code cannot
rely on poisoning to prevent invalid access.
[Mutex poisoning caveats](https://doc.rust-lang.org/std/sync/struct.Mutex.html#poisoning).

## Concurrency and cancellation

These are audit checks, not a second concurrency implementation guide. Optional
**rust-concurrency** supplies deeper implementation patterns.

### Locks and atomic protocols

Record each guard's actual destruction scope and every callback/transitive callee
that can reacquire a lock. In edition 2024, an `if let` scrutinee temporary drops
before `else`; older editions retain it longer. A `match` scrutinee temporary
remains alive through the statement, so changing to `match` can retain the guard.
Prefer an explicit short scope before callbacks or conflicting acquisition.
[Edition Guide](https://doc.rust-lang.org/edition-guide/rust-2024/temporary-if-let-scope.html),
[Mutex recursive-acquisition contract](https://doc.rust-lang.org/std/sync/struct.Mutex.html#method.lock).

Two atomic operations are not one atomic transaction, even with `SeqCst`.
A load/check/store admission path can admit two callers into the last slot.
Use a suitable read-modify-write/CAS or one lock around the invariant. Atomic
integer arithmetic wraps; an unmatched decrement can invalidate a quota. Follow
success, error, cancellation, and destruction so every reservation is released
once. Stronger memory ordering alone does not repair a multi-field protocol.
[Mara Bos, atomics](https://mara.nl/atomics/atomics.html),
[fetch_update contract (Rust 1.85)](https://doc.rust-lang.org/1.85.0/std/sync/atomic/struct.AtomicUsize.html#method.fetch_update).

This complete example reserves a numeric slot; it intentionally makes no promise
about publishing associated data. The successful caller owns the reservation and
must release it when the real operation completes. A `fetch_update` closure may
run repeatedly, so keep external side effects out of it.

```rust
use std::sync::atomic::{AtomicUsize, Ordering};

fn reserve(used: &AtomicUsize, limit: usize) -> bool {
    used.fetch_update(Ordering::Relaxed, Ordering::Relaxed, |current| {
        if current < limit { Some(current + 1) } else { None }
    }).is_ok()
}

let used = AtomicUsize::new(0);
assert!(!reserve(&used, 0));
assert!(reserve(&used, 2));
assert!(reserve(&used, 2));
assert!(!reserve(&used, 2));
assert_eq!(used.load(Ordering::Relaxed), 2);
// Here both illustrative operations have completed; release each reservation.
used.fetch_sub(1, Ordering::Relaxed);
used.fetch_sub(1, Ordering::Relaxed);
assert_eq!(used.load(Ordering::Relaxed), 0);
assert!(!reserve(&AtomicUsize::new(usize::MAX), usize::MAX));
```

### Async progress and partial effects

- Bound admission **before** spawning unlimited waiting tasks. Count bytes and
  retained results as well as channel slots/permits. Inspect fairness: Tokio's
  queued `acquire_many` can block smaller requests behind it; validate requested
  permit amounts against the application's capacity policy.
  [Tokio Semaphore](https://docs.rs/tokio/latest/tokio/sync/struct.Semaphore.html).
- A timeout is not preemption of synchronous work. Long computation or blocking
  calls can starve the executor; move appropriate work off it and bound admission.
  `spawn_blocking` work that has started generally cannot be aborted by its handle;
  a detached task is not a cancellation/cleanup strategy.
  [Alice Ryhl on blocking](https://ryhl.io/blog/async-what-is-blocking/),
  [spawn_blocking contract](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html).
- Review each `.await` boundary: what bytes/state/ownership have already changed?
  Tokio `read_exact` and `write_all` are not cancellation-safe when restarted;
  short `read`/`write` operations have different contracts. Preserve progress,
  discard the whole affected transaction, or define a recoverable protocol.
  Cancellation safety of one awaited method is not transactional rollback.
- With `select!`, inspect branch side effects, losing futures, disabled branches,
  all-disabled behavior, and `biased;` polling order. A perpetually ready branch
  ahead of shutdown can starve shutdown. Check the pinned runtime's method docs,
  not a universal cancellation-safe list.
  [Tokio select lifecycle and cancellation](https://docs.rs/tokio/latest/tokio/macro.select.html).

## Verification scenarios

For the actual consuming application, select checks that can falsify its claim:

- At-limit and just-over-limit inputs, large declared lengths with small payloads,
  malformed/partial input, decompression expansion, and every decoding entrypoint.
- Parse, composed-value formatting/serialization, and successful/error-path drop
  under the relevant stack/build; use a subprocess if abort is possible.
- Forced contention, callback reentrancy, cancellation immediately after a side
  effect, and shutdown with admitted/in-flight work; observe resource release and
  process liveness, not just a client's exit code.
- Profiles with the deployed overflow, debug-assertion, and panic settings. Never
  weaken an invariant because the debug test happened to pass.

Report unexecuted targets/runtime cases explicitly. The examples above prove only
their stated local contracts, not the absence of denial of service in a service.
