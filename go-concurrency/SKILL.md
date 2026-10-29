---
name: go-concurrency
description: >
  Use when designing or debugging Go goroutines, channels, select, bounded worker
  pools, pipelines, fan-in/fan-out, semaphores, rate limits, context cancellation,
  sync locks/atomics, goroutine leaks, data races, or container GOMAXPROCS limits.
---

# Go Concurrency

## Route the work

| Task or symptom | Start here |
|---|---|
| Blocked send, closed/nil channel, cancellation or missing result | [Ownership and channels](references/ownership-and-channels.md) |
| Growing backlog, worker pool, pipeline, semaphore, rate limiter or pub/sub | [Bounded work](references/bounded-work.md) |
| Shared map/counter, lock copying, initialization or reusable buffers | [Synchronization](references/synchronization.md) |
| Race, deadlock, timer/synctest upgrade, container CPU/memory limits | [Runtime and diagnostics](references/runtime-and-diagnostics.md) |

Read the relevant reference before changing its mechanism. Sources and optional
siblings are not dependencies.

## Workflow

1. **Start sequential.** Identify blocking I/O versus CPU work and the invariant
   requiring concurrency. CPU count alone cannot size I/O workers.
2. **Name owners.** Who starts/stops/joins each goroutine, closes each channel and
   mutates each object? Returning from `main` terminates goroutines without joining.
3. **Bound the path.** Limit active operations, waiting jobs, payload bytes, retained
   results and external resources. Semaphores acquired inside per-input goroutines
   do not bound goroutines waiting for admission.
4. **Define outcomes.** Specify ordering, first-error policy, backpressure versus
   drop/reject, partial side effects, normal versus aborted completion.
5. **Design exits.** Completion, worker error, parent cancellation, timeout and early
   consumer exit must stop admission and join producers. Every potentially blocked
   send/receive needs an owner-driven exit.
6. **Exercise the protocol.** Use channels or Go 1.25
   `synctest.Test(t, func(t *testing.T) {...})`, not sleep polling. Join before
   inspecting results; `synctest.Wait` alone is not completion.

## High-risk guardrails

- Cancellation is a signal, not preemption, rollback, or proof that a goroutine
  has returned. Pass context to actual operations, release resources, then join.
- Send expressions in `select` are evaluated before a case is chosen. Writing
  `case out <- expensiveWork():` does not make expensive work cancelable.
- A closed buffered channel drains queued values before returning zero/false.
  Disable a finished receive case with `nil`; otherwise it remains always ready.
- `select` does not prioritize cancellation or the first written case. A `default`
  is immediate fallback, not a fair scheduler or harmless idle loop.
- Close only after proving there can be no more sends. With multiple senders,
  a coordinator closes after joining them. Receivers cancel; they do not close
  a producer-owned data channel to interrupt sending.
- A buffer of one can accommodate one abandoned result; it cannot stop arbitrary
  work, fix an indefinite stream, or replace ownership/error observation.
- `WaitGroup.Go` (Go 1.25) callbacks **must not panic**. Traditional positive
  `Add` from zero happens before `Wait` and before launching the counted task.
  No copied WaitGroups, mutexes, Once, Pool, Map or atomics after first use.
- Synchronize all accesses with the same protocol; locking one writer but leaving
  readers unlocked is still a race. Atomics do not make multi-field invariants
  transactional. A concurrent-map fatal error is not guaranteed race detection.

## Version gates

Runnable samples declare **Go 1.25.0** and use `WaitGroup.Go` and stable
`testing/synctest.Test`. Go 1.24's experimental `synctest.Run` is not that API.
Loop variables declared by the loop have per-iteration semantics with language
version Go 1.22+; assignment to a previously declared variable still reuses it.
Go 1.23 timer behavior and Go 1.25 container defaults depend on module/runtime
settings; see [runtime gates](references/runtime-and-diagnostics.md#version-gates).

## Completion and evidence

Use the [bounded runnable example and exact commands](README.md#runnable-examples-and-limits).
Cover empty/invalid input, bounded active work, first error, parent cancellation,
early consumer exit and joined cleanup. A race-clean finite test does not prove
all schedules, latency or performance. Report executed checks separately from
static reasoning, plus unexecuted target/runtime checks and prerequisites.

Optional installed handoffs: **go-tdd** for deeper test design, **go-stdlib** for
network/I/O deadlines, **go-system-design** for durable delivery and service limits.

Adapted from pinned StructWeave chapters 03, 07, 12 and 14; see the
[source map and correction decisions](README.md#source-map-and-decisions) and
[upstream MIT notice](LICENSE.upstream).
