# Ownership, channels and cancellation

## Contents

- [Goroutine lifetime](#goroutine-lifetime)
- [Channel semantics](#channel-semantics)
- [Select and shutdown](#select-and-shutdown)
- [Context propagation](#context-propagation)
- [Complete owned example](#complete-owned-example)

## Goroutine lifetime

A `go` statement evaluates its function and arguments in the launching goroutine,
then runs the call independently. The runtime grows goroutine stacks as needed;
initial stack sizes are implementation details, not admission budgets. Cheap
creation does not mean free CPU, memory, connections or scheduler capacity.

Each goroutine needs an owner, an exit trigger and a join. Joining is required
on success and failure. A context's `Done` channel says cancellation was signaled,
not that cleanup completed. `main` returning stops the program without waiting
for other goroutines or their defers.

Traditional WaitGroup pattern (fragment; `work` is the application's operation):

```go
var wg sync.WaitGroup
wg.Add(1) // Before go, not inside it.
go func() {
    defer wg.Done()
    work()
}()
wg.Wait()
```

With Go 1.25, `wg.Go(func() { work() })` combines registration and launching.
The function must not panic; return ordinary failures through an explicit error
protocol. When the group is empty, `Go` must happen before `Wait`. While it is
nonempty, registered tasks may launch more tasks. Reuse starts only after all
previous `Wait` calls have returned. WaitGroup is neither a worker bound nor an
error channel. Do not copy it after use, including via value receivers or slices
of structs. The same no-copy discipline applies to other sync/atomic primitives.

Loop variables declared by `for` get per-iteration identity in Go 1.22+ language
semantics (normally selected by the module's `go` directive). Older modules need
argument capture/shadowing. `for _, x = range items` assigns an existing `x` and
still shares it; pointers inside per-iteration copies may share mutable data too.
A join prevents use-before-completion; it does not repair concurrent mutations.

## Channel semantics

| Operation | Nil channel | Open channel | Closed channel |
|---|---|---|---|
| Send | Blocks indefinitely | Rendezvous, or buffer admission; may block | Panics |
| Receive | Blocks indefinitely | Rendezvous, or buffered value; may block | Drains buffer, then zero value with `ok == false` |
| Close | Panics | Marks no future sends; does not discard buffer | Panics |

Unbuffered send completion means a receiver accepted the value, not that it
processed or committed it. Buffered send completion means admission to the
buffer, not delivery. `len(ch)` is a snapshot, not a check-then-send guarantee.
`range ch` stops only on close after draining; it does not observe context itself.
Channels transfer values: a slice/map/pointer sent through a channel can still
alias mutable storage. Transfer exclusive ownership or synchronize later access.

Prefer directional signatures (`<-chan T`, `chan<- T`). The sender-side owner
closes if receivers need end-of-input. A channel need not be closed just to make
it collectible. With multiple senders, close after joining all of them, never
on the assumption that a delay was long enough. No send may race with close.

## Select and shutdown

Cases on nil channels are disabled. If several cases can proceed, `select`
chooses pseudo-randomly; neither cancellation nor lexical order has priority.
An all-nil select without default blocks forever. `default` makes the select
nonblocking, so repeating it can burn CPU. A pre-check can reduce cancellation
latency but cannot create atomic priority over a concurrently ready send.

Receive loops must inspect `ok`. In a fan-in select, set a closed input to `nil`
to stop repeatedly receiving zero values; exit when all inputs are disabled.
A two-level priority select only favors already-observed readiness, not absolute
priority against arrivals racing the inner select.

Sending with cancellation (fragment):

```go
result, err := work(ctx, input) // Must itself return/cooperate; not preempted.
if err != nil {
    return err
}
select {
case out <- result:
case <-ctx.Done():
    return ctx.Err()
}
```

All select channel operands and send values are evaluated before selection.
`case out <- work():` may run `work` even when cancellation is ready. A one-result
buffer prevents that one send from blocking if its receiver leaves; it does not
cancel computation or observe its failure. Streaming senders require cancellation
and a join, not increasingly large buffers.

## Context propagation

- Accept `ctx context.Context` as the first argument; pass it through to actual
  HTTP requests, database calls and blocking operations. Do not pass nil or hide
  request contexts in long-lived structs. `Background` belongs at true lifetime
  roots; inside HTTP handlers use `r.Context()`, not a new root.
- `WithCancel`, `WithTimeout` and `WithDeadline` derive from the caller; always
  call the returned cancel function to release resources, even on success.
  A shorter parent deadline still wins. `TODO` marks a migration gap, not a
  cancellation strategy for production work.
- Observe `ctx.Err()` or `<-ctx.Done()` at blocking boundaries. Chunk CPU work
  if it must cooperate. Blocking syscalls/libraries need their own supported
  deadlines/unblock protocol; wrapping them in a goroutine does not stop them.
- `WithCancelCause`/`Cause` (Go 1.20) preserve the first cancellation cause;
  `WithDeadlineCause`/`WithTimeoutCause` (Go 1.21) attach deadline causes.
  `ctx.Err()` remains `Canceled` or `DeadlineExceeded`. Store operation errors
  before signaling cancellation if their identity must survive sibling aborts.
- Values are for request-scoped metadata, not optional parameters or dependency
  containers. Use an unexported comparable key type and checked assertions,
  not string keys that collide or unchecked assertions that panic.
- `WithoutCancel` (Go 1.21) retains values but removes deadline/cancellation:
  its `Done` is nil and `Err`/`Cause` are nil. Detached cleanup still needs a
  new timeout and an explicit lifetime owner; do not create immortal background
  work accidentally.
- `AfterFunc` (Go 1.21) starts a callback in its own goroutine upon cancellation.
  Its stop function prevents a callback only if it has not started; it does not
  join one already running. Give callbacks their own completion signal if the
  caller requires cleanup completion. `time.AfterFunc` has analogous ownership
  concerns but is a timer API, not a context-derived callback.

Cancellation does not undo external effects. A timeout after sending a write may
leave its outcome unknown; idempotency/transaction/reconciliation policy belongs
at that operation boundary. Never claim cancellation guarantees rollback.

## Complete owned example

This is a complete `main` using the [executable pipeline](../examples/pipeline.go)
in its example module (Go 1.25+):

```go
package main

import (
    "context"
    "fmt"
    concurrency "example.com/go-concurrency"
)

func main() {
    total := 0
    err := concurrency.ForEach(context.Background(), 2, []int{1, 2, 3},
        func(_ context.Context, n int) (int, error) { return n * n, nil },
        func(n int) error { total += n; return nil })
    fmt.Println(total, err) // 14 <nil>; consume is serial and joined.
}
```

The shared `total` is safe because exactly one consumer writes it and return
joins that consumer before reading. It would not be safe to read it concurrently
while the pipeline was running. See [bounded-work](bounded-work.md) for the exact
admission, error and shutdown protocol, and [regressions](../examples/examples_test.go)
for consumer stop and cancellation that cannot preempt arbitrary work.
