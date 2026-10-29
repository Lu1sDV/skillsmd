# Runtime versions, diagnosis and evidence

## Contents

- [Version gates](#version-gates)
- [Timers and shutdown](#timers-and-shutdown)
- [Container CPU and memory](#container-cpu-and-memory)
- [Race and liveness diagnosis](#race-and-liveness-diagnosis)
- [Deterministic tests](#deterministic-tests)

## Version gates

The [example module](../examples/go.mod) declares Go 1.25.0. Go 1.26.10 is the
integration host specified for this suite, not evidence of compatibility testing
on older toolchains. Preserve a consuming project's supported version floor.

| Version | Relevant change and boundary |
|---|---|
| Go 1.19 | Typed atomics (`atomic.Int64`, `Bool`, `Pointer[T]`); not whole-object transactions |
| Go 1.20 | `context.WithCancelCause`/`Cause`; sync.Map CAS/CompareAndDelete/Swap |
| Go 1.21 | Context WithoutCancel/AfterFunc/deadline causes; sync.OnceFunc/OnceValue/OnceValues |
| Go 1.22 language semantics | Loop-declared variables become per-iteration; assignment to an existing variable still shares it |
| Go 1.23 | Range over iterator functions; synchronous timer channels under the new semantics; atomic bitwise And/Or; sync.Map.Clear |
| Go 1.24 | Experimental synctest under `GOEXPERIMENT=synctest`, using the old `Run` API |
| Go 1.25 | WaitGroup.Go; stable `synctest.Test(t, f)`/Wait; Linux cgroup-aware and automatically updated GOMAXPROCS defaults with compatibility gates |

Do not paste Go 1.24 experimental `synctest.Run` into a Go 1.25 stable example.
The old experimental compatibility API was scheduled for removal in Go 1.26.
The Go 1.23 iterator syntax can use the existing bound `sync.Map.Range` method;
it did not add that method or snapshot semantics.

## Timers and shutdown

In programs whose main module declares `go 1.23` or later, channel timers use
synchronous channels: after `Timer.Stop`/`Reset` returns, subsequent receives do
not observe stale values from the old configuration. Unreferenced unstopped
timers/tickers can also be collected. `GODEBUG=asynctimerchan=1` restores old
semantics; `=0` forces new behavior. Check effective deployment settings rather
than assuming a new compiler alone changes timer behavior.

On older asynchronous timer semantics, stopping/resetting timers requires the
old exclusive-owner stop/drain protocol to avoid stale events; blindly draining
can itself block when another receiver consumed the event. Do not mix timer
receivers/reset owners, and do not add legacy draining to new synchronous-timer
code without identifying the compatibility need.

- `time.NewTimer` fires once; `time.After` is convenient for one-shot waits.
  It is no longer correct to claim every abandoned `time.After` necessarily
  retains its timer until firing under the new implementation. Repeated creation
  still has cost; reuse only where measurement/semantics justify it.
- `Ticker.Stop` stops future ticks but **does not close** its channel. A goroutine
  ranging ticker.C still needs cancellation to exit. Long-running owners should
  stop timers/tickers explicitly for lifecycle clarity, not rely on GC to join.
- Validate positive ticker intervals before construction. Tickers can drop ticks
  for slow receivers and are not queues or exact rate-accounting ledgers.
- `Timer.Stop` on an AfterFunc timer does not join a callback already started.
  Resetting an expired AfterFunc may start another call concurrently with a
  prior call; coordinate callback ownership separately.
- A ready cancel channel can race with a near-zero timeout: select chooses among
  ready cases. Do not assert that the first written case always wins or use 1ns
  timers as a deterministic scheduling trick.

See the official [Go 1.23 timer transition](https://go.dev/wiki/Go123Timer).

## Container CPU and memory

`GOMAXPROCS` limits CPUs executing Go code simultaneously, not goroutines, total
OS threads, connections or process memory. `runtime.GOMAXPROCS(0)` reads the
setting without changing it; `runtime.NumCPU()` is a startup OS CPU count, not
an effective cgroup throughput budget.

Go 1.25 defaults consider logical CPUs, affinity and, on Linux, cgroup v1/v2 CPU
quota/period. Kubernetes CPU **limits**, not requests, are relevant. Fractional
quota is rounded up; the default normally stays at least two unless CPU count
or affinity is below two, so this is not an exact enforcement of fractional CPU
quota. The OS still enforces cgroup throttling. Defaults update periodically
(up to once per second, less often when idle), not instantly on every change.

Setting positive `GOMAXPROCS` in the environment or calling
`runtime.GOMAXPROCS(n)` with `n > 0` disables automatic updates. Go 1.25
`runtime.SetDefaultGOMAXPROCS()` restores default calculation/updating, ignoring
the environment override but respecting GODEBUG. `containermaxprocs=0` and
`updatemaxprocs=0` disable the respective behavior; they are compatibility
defaults for language versions 1.24 and below. Inspect the module language
version, runtime overrides, affinity and actual cgroup quota before explaining
container latency as an application bug.

Memory is separate: inspect cgroup `memory.max`/`memory.current`/events (or v1
limits), process RSS, queue bytes and native allocations. `GOMEMLIMIT` or
`debug.SetMemoryLimit` (Go 1.19) is a **soft Go-runtime memory target**, not a hard
RSS/container cap; leave headroom for non-Go memory and OS overhead. `GOGC` /
`debug.SetGCPercent` tune a heap-growth target, not a memory size. Setting
`SetMemoryLimit(512<<20)` does not set the heap's growth percentage to 100 or
guarantee a 512 MiB process ceiling.

Green Tea was experimental in Go 1.25 (`GOEXPERIMENT=greenteagc`). The source's
10–40% **memory-use reduction** claim is incorrect: Go 1.25 release notes discuss
possible GC overhead reductions for GC-heavy programs, not a universal memory,
latency or throughput gain. Experiment/default status is release-specific;
measure the actual deployed release rather than treating a 1.25 flag as a
permanent recommendation.

Primary references: [Go 1.25 release notes](https://go.dev/doc/go1.25#runtime),
[pinned runtime contracts](https://github.com/golang/go/blob/go1.25.0/src/runtime/debug.go),
[soft memory target](https://pkg.go.dev/runtime/debug#SetMemoryLimit).

## Race and liveness diagnosis

Run the [README commands](../README.md#runnable-examples-and-limits) in the
example module. The race detector finds exercised races, not all possible races;
a clean run is neither a proof of correctness nor a performance benchmark.
A supported race-detector platform and C toolchain/CGO are prerequisites for
`-race`. `go vet` can find copied locks and Go 1.25 misplaced WaitGroup.Add;
static checks do not establish shutdown behavior.

For hangs, collect goroutine stacks before changing timeouts. Identify the owner
and the blocking operation of each goroutine: send with no receiver, receive
without end-of-input, lock-order cycle, missing Done, ignored cancellation, or
I/O lacking an unblock path. Compare goroutine profiles under repeated bounded
workloads; a raw global goroutine count includes unrelated runtime/application
work and is not a deterministic per-test leak assertion.

Use `go test -blockprofile=block.out -mutexprofile=mutex.out ./...` for contention
and `go tool pprof block.out` / `mutex.out` to inspect; enable appropriate profile
rates for live applications. `go test -trace=trace.out ./...` and
`go tool trace trace.out` expose scheduling/blocking. Memory profiles show sampled
allocation/retention, not automatically which protocol leaked a goroutine.
Protect diagnostic endpoints/profiles: stacks and labels may expose sensitive
information. Remove local profile outputs after use; they are not bundle files.

## Deterministic tests

Stable Go 1.25 `synctest.Test(t, func(t *testing.T) {...})` creates a bubble and
waits for its goroutines to exit. Channels/timers created inside belong to it.
`Wait` waits for other goroutines to become **durably blocked** or finish; it
provides a synchronization point, not a guarantee that a blocked task completed.
Time advances automatically when all bubble goroutines are durably blocked and
there is a future timed event. Calling `Wait` is not an imperative clock jump.

Blocking on bubble-local channels, applicable WaitGroups, Cond.Wait or time.Sleep
can be durably blocking. Real network I/O, syscalls and Mutex/RWMutex acquisition
are not treated as durably blocked. Do not make tests wait for unrelated external
work to make virtual time progress. The inner test must not call T.Run,
T.Parallel or T.Deadline; outer process/test timeouts remain real watchdogs.

The [behavioral tests](../examples/examples_test.go) use local gates, joins and
stable synctest, never arbitrary sleeps:

- Hold both workers at a gate, wait for quiescence, verify the active bound, then
  release and require all five results and no active calls after join.
- Let one worker fail only after a sibling begins waiting for cancellation;
  require the original error rather than the sibling's context cancellation.
- Stop consumption after one result with pending input and require joined return.
- Cancel while a worker deliberately ignores context at a gate: require that the
  owner remains blocked until the worker is released, then returns cancellation.
- Check empty/invalid/pre-canceled input and buffered-close/nil-channel boundaries.

Finite deterministic schedules do not prove all interleavings. These tests cover
the demonstrated worker implementation, not a custom semaphore, limiter, pub/sub
broker, container reconfiguration or production I/O integration. The complete
[bounded demo](../examples/cmd/demo/main.go) also executes without a test harness.

API sources: [pinned WaitGroup contract](https://github.com/golang/go/blob/go1.25.0/src/sync/waitgroup.go)
and [pinned synctest contract](https://github.com/golang/go/blob/go1.25.0/src/testing/synctest/synctest.go).
