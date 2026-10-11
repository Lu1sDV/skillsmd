# Async runtimes, cancellation, and shutdown

## Pick an execution model, not just syntax

Calling `async fn` produces a future. Its body makes progress when polled;
`.await` drives a future and may suspend the current task when it is pending.
It does not spawn a thread, and an always-ready `.await` is not a reliable
fairness or preemption point. Rust supplies the language machinery and `Future`
trait, not an application-wide I/O runtime.

Use the project's existing runtime and compatible I/O libraries. Tokio is the
concrete runtime discussed here; these are not promises about every executor.
Do not create a runtime per request or call a blocking `block_on` inside async
work as a way to wait for another task. Keep runtime ownership at the application
boundary; libraries should normally expose async operations instead.

| Operation | Meaning | Common wrong assumption |
|---|---|---|
| Consecutive `.await`s | Finish one operation before starting the next expression | Calling both async functions automatically overlaps them |
| `tokio::join!` | Poll branches concurrently within the current task; wait for all | Each branch runs on a separate CPU |
| `tokio::try_join!` | Return on the first error, dropping remaining branch futures | Dropping a branch rolls back its effects |
| `tokio::select!` | Choose a matching completed branch and drop losing branch futures | A dropped task handle cancels its spawned task |
| `tokio::spawn` | Schedule an independently driven task | Dropping its handle waits or cancels |
| `spawn_blocking` | Run finite synchronous work on blocking-pool threads | It has the same abort semantics as an async task |

`join!` and `select!` cannot progress their other branches while one branch
blocks the current thread. For Tokio setup, select features actually needed:
`rt` for a current-thread runtime, `rt-multi-thread` for a multi-thread runtime,
`macros` for runtime attribute macros and coordination macros, `sync` for async
channels/locks, and `time`, `net`, `io-util`, `fs`, or `signal` for the APIs used.
Check the resolved Tokio version's feature and MSRV requirements rather than
copying `features = ["full"]` indiscriminately.

Sources: [Tokio spawning](https://tokio.rs/tokio/tutorial/spawning),
[`select!`](https://docs.rs/tokio/latest/tokio/macro.select.html).

## Diagnose `Send` and lifetime failures separately

`tokio::spawn` requires a `Send + 'static` future and `Send + 'static` output.
Check both the initial captures and all state retained across possible
suspension points. A non-`Send` value created *inside* the future and scoped
away before suspension can be valid; capturing it in the future from outside
can already make that future non-`Send` before its first poll.

- Move owned data, not a reference to a local owner that will disappear.
  `async move` does not turn borrowed data into owned data or extend lifetimes.
- Shared references retained by a `Send` future require the referent to be
  `Sync`. A non-`Send` output, including an unconstrained boxed error, also
  prevents spawning; choose error bounds at the actual thread boundary.
- An ordinary `std::sync::MutexGuard` held across suspension prevents a
  `Send` future. Release it in a lexical scope or a synchronous helper before
  awaiting. Making the task local does not solve a blocking-lock wait cycle.
- For genuinely thread-confined resources, use `LocalSet` with `spawn_local`.
  This removes the `Send` requirement, **not** the spawned task's `'static`
  requirement. A current-thread runtime alone does not relax `tokio::spawn`'s
  bounds. Borrowing futures can instead be awaited/composed in the caller's
  task without spawning them.

Sources: [spawn bounds](https://tokio.rs/tokio/tutorial/spawning),
[`spawn_local`](https://docs.rs/tokio/latest/tokio/task/fn.spawn_local.html).

## Blocking boundaries and shared resources

Use async timers instead of `std::thread::sleep` inside runtime tasks. Use async
I/O APIs or move a finite synchronous call to `spawn_blocking`; marking the
wrapper `async fn` does not change the underlying operation. Tokio filesystem
APIs commonly delegate blocking file operations to its blocking pool; async
syntax is not a claim that the OS operation is inherently nonblocking.

For CPU-heavy work submitted through `spawn_blocking`, cap the number of jobs
**before submission** and keep the permit inside the closure until the job
actually finishes. A permit owned only by the awaiting task can be released
on cancellation while the computation continues. Use Rayon for an appropriate
CPU work pool and dedicated threads for persistent blocking loops.

[`spawn_blocking`](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html)
has a large default thread limit and queues excess jobs. Started closures
cannot be aborted; runtime shutdown can wait for them indefinitely. A shutdown
timeout stops waiting, not the underlying work. Pass a cooperative stop signal
and arrange an interruptible/wakeable blocking operation when termination is
required; a flag cannot interrupt arbitrary synchronous I/O.

For shared state:

- A standard mutex is appropriate for a short, low-contention synchronous
  update that does not span `.await`. Long contention blocks runtime workers.
- A Tokio mutex asynchronously waits for acquisition and supports a guard
  across `.await`, for example to serialize a connection operation. Keep that
  interval intentional. It can still deadlock if the awaited operation needs
  the same lock, and unrelated waiters still cannot access the resource.
- Tokio's mutex does not poison after a panic. Neither unwinding nor cancelling
  a task restores a partially modified invariant. If the operation changes
  state before awaiting, specify what observers may see after cancellation.
- An owner task plus bounded commands/replies is often simpler for stateful I/O.
  Cancellation of a requester's reply wait does not automatically cancel a
  command already accepted by the owner. Decide whether to finish it, cancel
  it before commit, or expose an operation identifier for reconciliation.

Sources: [shared-state guidance](https://tokio.rs/tokio/tutorial/shared-state),
[Tokio mutex](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html).

## Choose the channel by delivery semantics

| Tokio primitive | Fits | Required failure policy |
|---|---|---|
| Bounded `mpsc` | Commands or work for one consumer | Positive capacity; await space or handle `try_send` full/closed |
| `oneshot` | One completion or reply | Sender disappearance and abandoned receiver are meaningful outcomes |
| `watch` | Latest configuration/status | Intermediate values can be overwritten; not a work queue |
| `broadcast` | Events for current subscribers | Slow receivers can return `Lagged`; explicitly resync, tolerate loss, or fail |
| `Semaphore` | Active-resource budget | Controls permits, not a message queue or the total number of waiting tasks |

A bounded channel limits buffered **messages**, not bytes, producer-owned values,
spawned task count, downstream buffers, or completed results awaiting collection.
Bound those independently where the workload requires it. Await admission before
spawning a task; periodically reap `JoinSet` completions as well as limiting
running work. Otherwise even a concurrency-limited service can retain unbounded
completed outputs.

[`broadcast`](https://docs.rs/tokio/latest/tokio/sync/broadcast/index.html) is
not reliable per-subscriber backpressure: it evicts retained values and reports
lag. For sync/async bridges, use bounded Tokio `mpsc` with `blocking_send` or
`blocking_recv` only on the synchronous side, outside async execution.

Source: [Tokio mpsc lifecycle and bridging](https://docs.rs/tokio/latest/tokio/sync/mpsc/index.html).

## Audit each cancellation boundary

Treat cancellation as dropping an in-progress future. For each suspension,
write down: owned resources, changed state, external effects already issued,
and whether restarting repeats or loses work. Destructors can release guards,
permits, and buffers; they cannot await a protocol flush or undo a remote commit.

The following distinctions come from Tokio's
[`select!` cancellation contracts](https://docs.rs/tokio/latest/tokio/macro.select.html#cancellation-safety):

| Operation in a repeatedly recreated `select!` branch | On losing the race |
|---|---|
| `mpsc::Receiver::recv`, `watch::Receiver::changed`, `TcpListener::accept` | Documented cancellation-safe operations; no consumed item silently lost |
| `AsyncReadExt::read`, `AsyncWriteExt::write` | Cancellation-safe at that API boundary; still account for returned partial progress when they win |
| `read_exact`, `read_to_end`, `write_all` | Not cancellation-safe; a partial transfer can be lost from the operation's bookkeeping |
| `Mutex::lock`, `RwLock::read/write`, `Semaphore::acquire` | Cancellation loses the waiter's queue position |
| `Sender::send(value)` | Message is not sent if another branch wins, but its owned value is dropped |
| Awaiting `&mut JoinHandle<T>` | Task output is not lost; the task remains running for later observation |

For a cancellable send that must retain the value, keep the value outside the
raced future, await `Sender::reserve`, then move the value into `Permit::send`
only after obtaining capacity. Cancelling reservation still loses its queue
position. Dropping an unused permit returns the capacity. This avoids losing
the unsent value; it does **not** make queue acceptance a durable commit.
See the [sender contract](https://docs.rs/tokio/latest/tokio/sync/mpsc/struct.Sender.html#method.send).

Preserve a partially progressed future outside a loop and poll a pinned mutable
reference when it must survive unrelated branch wins; do not poll it again
once complete. Preserve an absolute deadline or one pinned timer too: recreating
a full-duration sleep on each incoming message can postpone timeout forever.

Additional `select!` traps:

- A closed receive can be immediately ready forever; handle `None`/closed and
  disable or exit the branch. Pattern-mismatch disables it for that invocation;
  all branches disabled without `else` panics.
- A false branch precondition prevents polling, not evaluation of the async
  expression used to construct its future. Keep construction side effects out
  of disabled branches.
- `biased;` uses source order, not fairness. Put shutdown where it cannot be
  starved by a perpetually ready stream, and consider starvation of other work.
- A timeout cannot preempt code that never yields back to the runtime.
  Timing out ownership of a `JoinHandle` drops the handle and detaches the task;
  keep the handle, time out a mutable borrow, then explicitly cancel/observe if
  the policy requires the task to stop.

## Supervision and errors

For a task returning `Result<T, E>`, awaiting its handle yields
`Result<Result<T, E>, JoinError>`. Distinguish success, application failure,
panic, and cancellation. `handle.await??` is appropriate only when both error
layers convert to the chosen error type **and** early return preserves
supervision of every other task. Stopping a loop at its first error can leave
other handles detached or discard errors during teardown.

[`JoinHandle`](https://docs.rs/tokio/latest/tokio/task/struct.JoinHandle.html)
detaches on drop; [`JoinSet`](https://docs.rs/tokio/latest/tokio/task/struct.JoinSet.html)
aborts remaining tasks on drop. Neither drop is a graceful-drain protocol.
After an abort request, await completion to observe cancellation or a result
that won the race. Consume `join_next` results explicitly when every failure
must be accounted for; do not assume a convenience shutdown method reports
all worker errors. Started blocking jobs are the exception to abortability.

## Graceful shutdown sequence

1. **Detect:** choose an explicit shutdown trigger (OS signal, parent request,
   unrecoverable worker failure) and record why shutdown began.
2. **Stop admission:** stop accepting requests and prevent new jobs from being
   submitted. Do not close only one queue while another producer still creates
   unlimited work upstream.
3. **Notify:** use an existing watch/status channel or, when already appropriate
   to the project, `tokio_util::sync::CancellationToken`. The token is from
   `tokio-util`, not `tokio`; notifications request cooperation rather than
   forcibly finishing tasks.
4. **Drain or discard deliberately:** `mpsc::Receiver::close()` rejects new
   ordinary sends while allowing buffered messages to be drained. Previously
   reserved permits can still send; receive until `None`, and arrange for all
   permits to be used or dropped. Dropping the receiver discards unread work.
5. **Finish cleanup:** workers reach a safe boundary, flush/commit required
   work and close resources. Cleanup that needs `.await` belongs in the worker's
   shutdown path, not an ordinary synchronous destructor.
6. **Join:** await all owned tasks and collect application and join errors.
   If using `TaskTracker`, close the tracker and wait for it to become empty;
   tracker closure is not cancellation or a substitute for stopping admission.
7. **Escalate:** after the documented grace deadline, abort permitted async
   work and observe termination. Report unfinished blocking work and partially
   committed operations honestly; abort is not rollback or hard preemption.

Sources: [Tokio graceful shutdown](https://tokio.rs/tokio/topics/shutdown),
[bounded channel close/permits](https://docs.rs/tokio/1.53.2/src/tokio/sync/mpsc/bounded.rs.html#438-447),
[`spawn_blocking`](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html).
