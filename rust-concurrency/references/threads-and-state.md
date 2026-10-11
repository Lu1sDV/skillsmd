# Threads, shared state, and message passing

## Thread ownership and completion

[`thread::spawn`](https://doc.rust-lang.org/std/thread/fn.spawn.html) requires
both the closure and its result to be `Send + 'static`. The two bounds answer
different questions: may this value move to another thread, and can it be kept
without invalidating a borrowed referent? An owned `String` can satisfy
`'static` and still be dropped immediately after the thread finishes.

Use `move` to transfer captures, not to manufacture a lifetime. A captured
`&str` still refers to someone else's storage. Prefer
[`thread::scope`](https://doc.rust-lang.org/std/thread/fn.scope.html) when the
caller must wait anyway: scoped threads may borrow non-`'static` data, and
unjoined scoped threads are joined before the scope returns. An unhandled
scoped-thread panic makes the scope panic; join explicitly to handle it.

This check mutates disjoint regions without an `Arc`, a lock, or a data copy:

```rust
use std::thread;

let mut values = [1_u32, 2, 3, 4, 5];
thread::scope(|scope| {
    let (left, right) = values.split_at_mut(2);
    scope.spawn(move || {
        for value in left {
            *value *= 2;
        }
    });
    scope.spawn(move || {
        for value in right {
            *value *= 3;
        }
    });
});
assert_eq!(values, [2, 4, 9, 12, 15]);
```

Dropping an ordinary thread's `JoinHandle` detaches it, rather than joining or
cancelling it. Retain handles for owned workers. An unwinding worker panic is
returned by `join`; an application `Result` returned by the closure is a second,
inner result. `panic = "abort"` is not a recoverable worker failure. If OS
thread creation failure must be handled, `thread::Builder::spawn` returns an
I/O result where `thread::spawn` panics.

## Read trait bounds, not wrapper names

For the usual standard-library allocator:

| Type | `Send` condition | `Sync` condition |
|---|---|---|
| `Rc<T>` | Never | Never |
| `Cell<T>` / `RefCell<T>` | `T: Send` | Never |
| `&T` | `T: Sync` | `T: Sync` |
| `&mut T` | `T: Send` | `T: Sync` |
| `Arc<T>` | `T: Send + Sync` | `T: Send + Sync` |
| `Mutex<T>` | `T: Send` | `T: Send` |
| `RwLock<T>` | `T: Send` | `T: Send + Sync` |

`RefCell<T>` can therefore be **moved** to one thread when `T: Send`, but cannot
be concurrently shared by reference. A mutex does not repair `Rc<T>`: other
`Rc` clones could exist outside that lock. Do not add unsafe trait impls to
silence a compiler diagnostic. These semantics are documented by
[`Sync`](https://doc.rust-lang.org/std/marker/trait.Sync.html),
[`Mutex`](https://doc.rust-lang.org/std/sync/struct.Mutex.html), and
[`Arc`](https://doc.rust-lang.org/std/sync/struct.Arc.html#thread-safety).

`Arc::clone` clones a handle, not the payload. Strong reference cycles still
leak; use `Weak` for non-owning back-references and handle a failed `upgrade`.
Use an `Arc` only if independent shared ownership is needed; a scoped borrow
can share a mutex without reference counting.

## Protect the whole invariant

Choose `Arc<Mutex<T>>` when all owners must observe updates to the same `T`.
Keep related checks and writes within **one** guard: lock-check-unlock followed
by lock-update is a check-then-act race even though both accesses are data-race
free. Make invariant-preserving operations methods instead of exporting guards
when doing so prevents callers from accidentally composing broken operations.

`Mutex<Arc<T>>` is not useless or interchangeable with `Arc<Mutex<T>>`: it can
protect replacement of an immutable snapshot pointer. Readers clone the inner
`Arc` while holding the lock, then release the lock and read that snapshot.
Existing readers retain the old snapshot after replacement. Mutating through
`Arc::make_mut` similarly uses copy-on-write rather than updating all readers.

```rust
use std::sync::{Arc, Mutex};

let current = Mutex::new(Arc::new(vec!["v1"]));
let old_snapshot = {
    let guard = current.lock().expect("snapshot lock must not be poisoned");
    Arc::clone(&guard)
};
{
    let mut guard = current.lock().expect("snapshot lock must not be poisoned");
    *guard = Arc::new(vec!["v2"]);
}
let new_snapshot = Arc::clone(&current.lock().unwrap());
assert_eq!(old_snapshot.as_slice(), &["v1"]);
assert_eq!(new_snapshot.as_slice(), &["v2"]);
```

The assertions are a local semantic check; production poison handling must
follow the invariant's failure policy.

## Lock discipline and poison policy

- Minimize the critical section, but do not split one required atomic update
  into separately locked pieces. Compute independent inputs before locking.
- Establish one lock ordering for every path. Avoid invoking callbacks, doing
  I/O, joining workers, or making a potentially blocking channel send while
  holding a lock those operations might need.
- Name a guard or use an explicit scope. `let _ = mutex.lock()` does not retain
  a guard for the following statements; guard destructors, not borrow last-use,
  release locks. Avoid confusing temporary-expression drop scopes.
- Do not recursively acquire a standard mutex. `try_lock` distinguishes
  `WouldBlock` from `Poisoned`; retrying while retaining another lock can still
  livelock or deadlock. Channels can also form cyclic waits.
- A standard mutex's poison flag is advisory evidence of a panic, not a repair
  and not a soundness guarantee. `PoisonError::into_inner` gives access to
  potentially inconsistent state. Recover only with a documented validation or
  repair procedure; clear poison only after restoring the invariant. Otherwise
  propagate the failure or stop the affected subsystem.
- [`RwLock`](https://doc.rust-lang.org/std/sync/struct.RwLock.html) allows readers
  together or one writer. Its OS-dependent policy does not guarantee writer
  priority or fairness. Do not acquire a write lock while retaining a read
  guard; drop it and re-check under the write lock. Reentrant reads can also
  deadlock in the presence of a waiting writer. Only write-side panics poison
  the standard `RwLock`.

See [`Mutex` poisoning](https://doc.rust-lang.org/std/sync/struct.Mutex.html#poisoning)
for why even an unpoisoned mutex is not proof of a valid application invariant.

## Channels are a protocol, not just a queue

| Need | Standard-library choice | Operational consequence |
|---|---|---|
| Multiple senders, one receiver, bounded work | `mpsc::sync_channel(n)` | `send` blocks when full |
| Direct handoff | `sync_channel(0)` | Sender and receiver rendezvous |
| Queue with independently proven volume bound | `mpsc::channel()` | No built-in backpressure |
| Wait for work | `recv()` / receiver iteration | Completion requires every sender to disappear and the buffer to drain |
| Poll or timed wait | `try_recv()` / `recv_timeout()` | Distinguish empty/timeout from disconnection |

The standard receiver is single-consumer, not cloneable for an MPMC worker
pool. A receiver inside `Arc<Mutex<_>>` serializes dequeuing; if that design is
used, release the receiver guard **before** executing a job. Prefer an existing
pool or channel implementation when multiple independent consumers are needed.

A shutdown protocol must account for every cloned sender. Retaining a sender
in the coordinator while waiting for receiver iteration to end hangs the
receiver. For bounded queues, join producers **after** allowing the consumer
to drain; otherwise a producer may wait forever for capacity. Dropping the
receiver rejects further sends and discards unread work, so it is not a drain.
Handle `SendError<T>` as failure with ownership of the unsent item, not success.

Do not assume producer interleaving is a stable application order. Attach
sequence identifiers when ordering across independent producers is required.
A channel send acknowledges queue acceptance; use an explicit reply if callers
need confirmation that processing or a durable commit completed.

Source: [`sync_channel`](https://doc.rust-lang.org/std/sync/mpsc/fn.sync_channel.html).

## Condition variables and termination predicates

Use a [`Condvar`](https://doc.rust-lang.org/std/sync/struct.Condvar.html) for
waiting on a mutex-protected predicate that a channel cannot express simply.
`wait` atomically unlocks and parks, then reacquires the mutex. Always loop over
the predicate (or use `wait_while`) because wakeups may be spurious. A
notification is not stored application state; update the predicate while
holding the associated mutex before notifying. Use the same mutex for a given
condition variable.

This check gates a reader on completion without sleeps. If the producer wins
the scheduling race, the reader sees the predicate and never needs a wakeup:

```rust
use std::sync::{Condvar, Mutex};
use std::thread;

let state = Mutex::new(None::<u32>);
let ready = Condvar::new();
thread::scope(|scope| {
    scope.spawn(|| {
        let mut guard = state.lock().unwrap();
        *guard = Some(42);
        ready.notify_one();
    });
    let guard = ready
        .wait_while(state.lock().unwrap(), |value| value.is_none())
        .unwrap();
    assert_eq!(*guard, Some(42));
});
```

For alternating workers, the wait predicate must include **both** whose turn
it is and whether processing has finished. Wake the other waiter after the
last transition so it can observe termination. For a custom bounded buffer,
include a closed state, wake blocked producers and consumers on close, and
specify whether consumers drain remaining items. Reject zero capacity unless
a genuine rendezvous protocol is implemented; merely waiting on
`len == capacity` at capacity zero never makes progress. Prefer `sync_channel`
to implementing that buffer yourself.

## Atomics and one-time initialization

[`Ordering`](https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html) is part
of a synchronization proof, not an optimization dial:

- `Relaxed` provides atomicity for that operation, not publication of other
  memory. It can fit a standalone statistics counter with no dependent state.
- A release store and an acquire load that observes it can establish
  publication of earlier writes. They do not waive Rust's aliasing rules or
  make raw-pointer lifetime management safe.
- `SeqCst` adds a shared order for sequentially consistent atomic operations;
  it still does not combine a load and a store into one atomic increment. Use
  `fetch_add` or a correct compare-exchange loop when that is the operation.
- Do not spin-poll a flag when a channel or condition variable can park the
  waiter. An atomic cancellation flag cannot wake a blocked receive by itself.

Use `Once` for a one-time action and
[`OnceLock<T>`](https://doc.rust-lang.org/std/sync/struct.OnceLock.html) for a
synchronously initialized value (available since Rust 1.70). `get()` does not
block and can return `None` during initialization. A panicking initializer
leaves `OnceLock` uninitialized rather than poisoned. Reentrant initialization
is erroneous and can deadlock. Do not hide network waits or long blocking
initialization in an executor worker's synchronous `get_or_init` call.
