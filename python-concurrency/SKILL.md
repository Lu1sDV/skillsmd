---
name: python-concurrency
description: >
  Use when choosing or debugging Python threads, process pools, asyncio tasks,
  TaskGroup cancellation, timeouts, bounded queues, worker shutdown, deadlocks,
  GIL assumptions, free-threaded CPython, or Python 3.14 multiple interpreters.
---

# Python Concurrency

## Route the work

| Situation | Default and reference |
|---|---|
| Blocking calls, CPU work, shared state, executor hangs | Start sequential; use bounded threads for blocking I/O and consider processes for substantial GIL-bound CPU work. [Execution and coordination](references/execution-and-coordination.md) |
| Async-compatible I/O, task failure, deadlines or growing backlog | Use the existing loop, structured task ownership and bounded admission. [Async lifecycle](references/asyncio-lifecycle.md) |
| Runtime upgrade, free threading or Python 3.14 interpreters | Check the actual build, start method and dependency compatibility. [Runtime versions](references/runtime-versions.md) |

Load the relevant reference before changing its mechanism. Examples use Python
3.11+ except explicitly gated APIs; preserve the consuming project's version floor.

## Workflow

1. **Classify and measure.** Identify blocking I/O, async-compatible I/O,
   pure-Python CPU work and native code that releases the GIL. Include startup,
   serialization, queueing and shutdown costs before adding concurrency.
2. **Assign ownership.** Name the resource owner and compound invariant. Prefer
   returned values or messages to shared mutation; synchronize the whole invariant.
3. **Bound admission and define success.** Limit queued items, payload bytes,
   outstanding submissions, active workers and retained results. Distinguish
   accepted, processed, acknowledged and committed. Specify wait/reject/drop and
   drain/discard behavior; ask the owner if material loss or durability policy is
   unresolved.
4. **Design every exit.** Name who stops producers, signals end-of-input,
   observes failures, waits for workers and closes resources on normal return,
   failure and cancellation. A producer blocked on a full queue must be able to
   observe a dead consumer.
5. **Exercise the protocol.** Coordinate tests with events, queues or barriers,
   not sleeps. For multi-file runtime cutovers, track affected producers,
   consumers and shutdown paths as pending, migrated, verified or blocked.

## Critical gotchas

- **The GIL is not a transaction.** Protect check-then-update and multi-field
  invariants. In one event-loop thread, interleaving occurs at suspension points;
  use loop-local primitives for tasks, not for OS-thread/process synchronization.
- **Async syntax does not make blocking work nonblocking.** Use async-compatible
  APIs or owned offloading. Await in a host's existing loop; do not nest loops.
- **Cancellation is not rollback or thread termination.** Release resources in
  `finally`, normally re-raise `CancelledError`, and await task cleanup. A timeout
  can leave an effect's outcome unknown; cancelling a `to_thread()` awaiter leaves
  a running callable needing its own deadline or cooperative stop protocol.
- **Observe every outcome.** `TaskGroup` owns related children through cleanup;
  bare `create_task()` needs supervision. `Thread.join()` alone does not propagate
  exceptions. Successful enqueue or `task_done()` is not durable completion.
- **Isolation is not a sandbox.** Never accept untrusted pickle. Multiple
  interpreters share a process and cannot safely contain hostile code.

## Completion and evidence

Exercise empty input, bounded capacity/backpressure, promised ordering, worker
failure, cancellation at a known suspension point and cleanup. Do not claim
completion while a worker outcome or shutdown path is unobserved; report blocked
checks explicitly. Deadlines are watchdogs, not scheduling evidence.

Report executed checks separately from static reasoning and optional runtime
recipes. Deterministic examples do not prove all schedules or performance; see
the [README](README.md#runnable-examples-and-limits) for commands and runtime limits.

## Optional handoffs and attribution

If installed, use **python-tdd** for regression-test design, **python-idiomatic**
for ordinary language/error handling, **python-api-design** for public async
interfaces, and **python-system-design** for durable queues and service-level
transaction ownership. None is required to install this bundle.

Adapted from StructWeave chapter 07 and concurrency portions of 13/14; see the
[pinned source map and corrections](README.md#source-map-and-decisions) and
[upstream MIT notice](LICENSE.upstream).
