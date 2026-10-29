# go-concurrency

A self-contained Go skill for owned goroutines, channel protocols, bounded
workers, synchronization, cooperative cancellation and runtime diagnosis.
Instructions, references, runnable stdlib-only examples and upstream licensing
travel together; no sibling installation or upstream fetch is required.

## Install

From the repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r go-concurrency ~/.claude/skills/
```

Before copying, preserve any existing local `go-concurrency` installation and its
changes; do not blindly overwrite it. Copy the entire directory, not just SKILL.md.
Installation adds instructions, not a running service or Go dependency.

## Usage prompts

- "Find why this Go pipeline hangs after the consumer stops early."
- "Bound admission and result retention without spawning one goroutine per item."
- "Preserve the first worker error while canceling and joining its siblings."
- "Choose a mutex, typed atomic or sync.Map for this shared-state invariant."
- "Explain this container's GOMAXPROCS and timer behavior after a Go upgrade."

## Reference index

| File | Coverage |
|---|---|
| [SKILL.md](SKILL.md) | Routing, workflow, essential lifetime guards, version gates and evidence |
| [Ownership and channels](references/ownership-and-channels.md) | Goroutines/WaitGroup, closure versions, nil/open/closed channels, select, context propagation/causes/detached cleanup |
| [Bounded work](references/bounded-work.md) | Workers, fan-in/out, pipelines/iterators, first-error and join protocol, semaphore admission, rate limits/token buckets and pub/sub loss policy |
| [Synchronization](references/synchronization.md) | Mutex/RWMutex, memory publication, atomics, Once helpers, Pool, sync.Map and Cond |
| [Runtime and diagnostics](references/runtime-and-diagnostics.md) | Timer/synctest version corrections, container CPU/memory, GC claims, race/liveness tooling and deterministic testing |
| [Executable pipeline](examples/pipeline.go) | Bounded two-stage map/consume protocol with actual errors, cancellation and complete joins |
| [Behavioral checks](examples/examples_test.go) | One Output example and six named regression tests |
| [Real demo](examples/cmd/demo/main.go) | Successful concurrent work and early consumer stop outside a test harness |

## Runnable examples and limits

Minimum **Go 1.25.0**: the module declares `go 1.25.0` and uses WaitGroup.Go and
stable testing/synctest.Test. The supplied integration environment is Go 1.26.10
linux/amd64; no older-toolchain certification is claimed. Core channel/lock/context
APIs predate 1.25; precise newer gates are listed in the runtime reference.

From inside this bundle, including an isolated copied installation:

```sh
cd examples
GOTOOLCHAIN=local go test -count=1 -timeout=30s ./...
GOTOOLCHAIN=local go test -race -count=1 -timeout=60s ./...
GOTOOLCHAIN=local go vet ./...
GOTOOLCHAIN=local go run ./cmd/demo
```

Verified on 2026-10-29 with Go 1.26.10 linux/amd64 in an isolated copy:
race-enabled tests, `go vet`, and both demo scenarios passed.
`GOTOOLCHAIN=local` prevents implicit toolchain downloads; an installed Go 1.25+
compiler is required. There are no third-party modules, network calls, external
services or root module. The race command additionally needs a supported
race-detector target and C toolchain/CGO. An outer process deadline is appropriate
for `go run`; the demo's two-second context is cooperative, not an OS kill switch.

Expected demo stdout, if the finite work completes before its watchdog:

```text
squares: [1 4 9 16]
early stop: joined after one result
```

Failures go to stderr with nonzero exit. The worker pool consumes results in
completion order; the demo sorts the four results only for stable presentation.
It uses two workers plus one serial consumer and unbuffered jobs/results: no
channel backlog or unbounded goroutine spawning. Finite input and retained demo
results still occupy memory; this is not a streaming-input API or a service queue.

The Output example checks mapping and joined serial consumption. Named tests:

- `TestForEachBoundedWorkersAndJoin`: hold two workers at a gate; require exactly
  two active calls, then release and require all five results and zero active work.
- `TestForEachFirstWorkerErrorSurvivesSiblingCancellation`: coordinate the source
  failure before its sibling returns ctx.Err; require original error and cleanup,
  with trailing input not admitted to the work callback.
- `TestForEachEarlyConsumerExitJoinsBlockedSenders`: hold consumption until workers
  are blocked sending, then stop after one result and require joined return.
- `TestForEachCancellationIsNotPreemption`: cancel while arbitrary work ignores
  context; require the function to keep waiting until that work is released.
- `TestForEachEmptyInvalidAndPreCanceled`: empty input, nonpositive workers,
  missing callbacks, and cancellation before any work begins.
- `TestClosedBufferedAndNilChannels`: buffered values survive close, drained
  receives return zero/false, and a nil channel disables a select case.

Tests use channel gates, joins and stable synctest, not sleep polling. Test
timeouts are watchdogs, not speed assertions. Finite schedules do not prove all
interleavings or performance. The sample does not validate container quota
changes, real I/O cancellation, limiter precision, pub/sub durability, arbitrary
panics or uncooperative callbacks that never return. Such callbacks intentionally
prevent return: cancellation cannot preempt them.

## Source map and decisions

Adapted from StructWeave-Algorithms at immutable commit
`e2a796e212d431c906c85957ea3c203ce0e2218f`:

| Pinned source and read coverage | Local coverage |
|---|---|
| [03 — Concurrency patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/03-concurrency-patterns.md), **all lines 1–1149** | Every substantive topic: goroutines/WaitGroup/loop capture; channels/select; Mutex/RWMutex/Once/Cond/atomics; workers, fan-in/out, pipeline, semaphore, rate limit/token bucket, pub/sub; context; race scenarios; synctest, container GOMAXPROCS, experimental GC, sync.Map iteration and iter.Seq |
| [07 — Trap questions](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/07-trap-questions.md), lines 261–290, 317–410, 805–891, 1317–1424, 1825–1834 | Concurrent maps, channel matrix/draining/leaks, loop language version, Add ordering, copied locks, select default |
| [12 — Anti-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/12-anti-patterns.md), lines 25–303, 1272–1310, 1359–1396, 1464–1487 | Leaked sends, bounded admission, no-copy sync values, close ownership, races, deterministic checks, vet/race/profile diagnosis |
| [14 — Standard library](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/14-standard-library-essentials.md), lines 1592–1726, 1949–2158, 2579–2608, 2996–3018, 3068–3075, 3095–3119 | Timers/context including WithoutCancel/AfterFunc; sync/atomic families; corrected stable synctest API; context root and shared-lock corrections |

Consolidation/correction decisions and rationale:

1. **Organize around ownership and invariants, not interview order.** Four
   task-based references merge repeated cheat sheets. Keep the entrypoint routing
   and safety-focused; only the actual pipeline is compiled in examples.
2. **Replace sleep-based completion and bare streaming sends.** The executable
   implementation joins workers before closing results and joins its consumer.
   Every admitted worker can abort a blocked result send. A buffer alone would
   not repair an abandoned stream or cancel arbitrary computation.
3. **Make errors and bounds explicit.** The first registered callback error wins
   over sibling aborts; parent cancellation is returned if no callback fails.
   Unbuffered edges bound channel backlog; callback retention and existing input
   are explicitly outside that queue bound. Early consumer stop is a sentinel
   error, not a hidden success/fallback or an unobserved worker failure.
4. **Correct capture and WaitGroup guidance.** The source's unqualified loop
   capture warning is obsolete for loop-declared variables under Go 1.22+
   language semantics, but existing-variable assignment still shares state.
   WaitGroup.Go is Go 1.25 and its function must not panic. Add must precede a
   zero-count Wait/task launch; used sync primitives must not be copied.
5. **Correct cancellation examples.** Select evaluates send expressions before
   choosing, so `out <- expensiveOperation()` is not a cancellation-aware call.
   Use the incoming request context; detached cleanup needs its own bound and
   owner. AfterFunc stop is not join. Cancellation is neither rollback nor kill.
6. **Correct timer/synctest versions.** Go 1.24's experimental Run is not the
   Go 1.25 stable Test API. Wait is quiescence, not forced time advancement or
   a join for arbitrary blocked tasks. Go 1.23 timer semantics depend on the
   main module and GODEBUG; stopping a ticker never closes its channel.
7. **Keep shared-state contracts honest.** Do not combine the source's separate
   mu/rwmu around one counter. Pool can discard entries and fixed-size copy can
   truncate; map races do not guarantee a recoverable panic. sync.Map.Range is
   old; Go 1.23 adds usable iteration syntax, not snapshot consistency.
8. **Qualify runtime/GC claims.** Container GOMAXPROCS depends on quota, affinity,
   compatibility gates and overrides; it is not an application admission limit.
   SetMemoryLimit is a soft runtime-memory target, not heap percentage/RSS cap.
   Green Tea's Go 1.25 estimate concerned GC overhead, not 10–40% memory savings.
9. **Preserve meaningful patterns without extra frameworks.** Cond predicates,
   semaphore shutdown, limiter burst/lifetime and pub/sub loss/unsubscribe
   policies remain substantive guidance. The sample does not pretend to
   implement or test these separate systems; no immortal refill goroutine,
   unbounded queue or broker abstraction is introduced merely to illustrate them.

Version corrections additionally cite pinned Go 1.25 runtime/WaitGroup/synctest
contracts and the official timer transition in the runtime reference. Original
material is MIT-licensed; the exact notice is in [LICENSE.upstream](LICENSE.upstream).
