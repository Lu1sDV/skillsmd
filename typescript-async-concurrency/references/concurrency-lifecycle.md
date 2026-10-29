# Concurrency Lifecycle

## Worker pools

Accept lazy task functions or items plus a task function. Require a positive integer worker count. Start at most that many workers, and assign each item once. Store by input index when stable output order is required.

Define the failure policy before coding: stop claiming new items after failure, continue and collect all results, or request cancellation of started work. Observe every started task regardless of the caller-facing policy. Handle synchronous throws from task factories as well as rejected promises.

If using an active set, track the exact promise that completes and remove it on either outcome. Do not retain already-settled entries in repeated `Promise.race` calls. Do not remove an arbitrary recent task merely because another task finished.

Check every promise created by a `then`, `catch`, or `finally` chain for rejection handling. A cleanup handler does not automatically make its derived promise safe to ignore.

## Batching and rate limits

Distinguish these contracts:

| Contract | Bound |
| --- | --- |
| Batch processing | Start a group, wait for the entire group, then start the next |
| Concurrency pool | At most k operations active simultaneously |
| Rate limit | At most a specified start/operation budget over time |
| Backpressure | Producer waits or slows when downstream capacity is exhausted |

A slow member can leave a batch underutilized. A pool alone can still exceed a per-second request budget. Use a separate time-based mechanism when that budget is part of the requirement.

## Queues and mutexes

Give callers an observable completion/error result when they need to know whether enqueued work succeeded. Keep processing flags, queue state, and results consistent on failure; release/reset in finally under the correct ownership.

Define drain, stop, and cancellation semantics. Avoid publishing a mutable internal results array. Use efficient FIFO removal for sustained workloads.

Prefer a scoped lock API that releases exactly once; protect against double release and unrelated release. Do not await work inside a lock that requires the same lock to finish. Define fairness only when the implementation guarantees it.

## Retry and backoff

Identify retryable conditions and whether repeating the operation is safe. Separate the number of retries from total attempts. Bound attempts and total time; apply a capped delay and jitter when synchronized retry traffic matters.

Respect server retry guidance when applicable. Propagate cancellation through both the operation and backoff wait. Avoid retrying validation failures or repeating a successful side effect solely because later response handling failed.

Preserve the final error/cause and expose enough context to diagnose attempt exhaustion.

## Debouncing and latest-result behavior

Specify what happens to every caller when a newer call replaces its timer: reject it with a deliberate superseded outcome, join it to the final result, or implement another documented policy. Clearing a timer while abandoning its promise is not a complete debounce implementation.

Specify trailing/leading execution, maximum wait if needed, and behavior while a prior invocation is already running. Preserve receiver/argument semantics. Derive the resolved type with `Awaited<ReturnType<T>>` when expressing a generic async wrapper.

For latest-result UI/state updates, pair cancellation with request identity. An old operation can ignore a signal or finish before cancellation; gate state commits and cleanup against the current request.

## Source sections

- [StructWeave: concurrency patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/06-async-patterns.md#concurrency-patterns)
- [StructWeave: cancellation](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/06-async-patterns.md#cancellation)
- [StructWeave: debounce and mutex examples](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/06-async-patterns.md#common-interview-patterns)
