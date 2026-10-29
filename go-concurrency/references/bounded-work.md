# Bounded workers and streaming protocols

## Contents

- [Budget the whole path](#budget-the-whole-path)
- [Executable fan-out, fan-in and pipeline](#executable-fan-out-fan-in-and-pipeline)
- [Semaphore admission](#semaphore-admission)
- [errgroup in existing projects](#errgroup-in-existing-projects)
- [Rate limits and token buckets](#rate-limits-and-token-buckets)
- [Pub/sub and slow consumers](#pubsub-and-slow-consumers)

## Budget the whole path

Workers, queued jobs, payload bytes, retained results, connections and retries
are distinct budgets. A channel of `len(inputs)` is finite for one call but
allocates backlog proportional to input; it is not a fixed admission bound.
An unbuffered queue supplies direct backpressure. A small buffer absorbs bursts,
not sustained overload. Choose wait, reject or drop and document that policy.
Input slices and accumulated outputs still count toward memory even if channels
are unbuffered. Avoid an unbounded list of goroutines waiting on a semaphore.

CPU-bound work often starts near `runtime.GOMAXPROCS(0)` and is measured. I/O
concurrency is constrained by upstream budgets and latency, not `NumCPU()*2`.
Neither setting limits connections or guarantees memory fit. Heavy payloads need
byte limits in addition to item limits.

## Executable fan-out, fan-in and pipeline

[`ForEach`](../examples/pipeline.go) uses one owner/admission loop, exactly
`workers` worker goroutines and one serial consumer goroutine:

1. The calling goroutine sends finite input through an unbuffered `jobs` channel.
2. Workers compete for jobs (**fan-out**), invoke `work(ctx, item)`, then select
   between cancellation and sending to one unbuffered `results` channel (**fan-in**).
3. One consumer applies the final pipeline stage. No output slice is retained
   unless the supplied callback chooses to retain it; order is completion order.
4. The first callback error registered through `sync.Once` is retained **before**
   cancellation. It cannot be overwritten by a sibling returning `ctx.Err()`.
   Simultaneous independent errors have no deterministic chronological ordering;
   the registration winner is the documented first error.
5. Cancellation stops admission. The owner closes `jobs`, joins all workers,
   closes `results` only after all senders stop, then joins the consumer. The
   consumer drains/skips remaining results after cancellation so no sender leaks.
6. Return the recorded callback error, or context cancellation if no callback
   failed, otherwise nil. Parent cancellation is not allowed to erase an already
   recorded operation error. A callback error also takes precedence over parent
   cancellation observed before return; this is an explicit example policy.

The implementation has zero queued channel items and at most one in-flight
work/result per worker plus one consumer-held value. The caller's existing input
slice is not a streaming source or a memory bound. Positive worker count and
non-nil callbacks are validated; nil context is disallowed by Go convention.
Callbacks must return and must not panic (`WaitGroup.Go` contract). There is no
hidden recovery or forced termination. Cancellation can race with an already
started callback or ready send, so do not promise zero work after the instant of
cancel. The function waits for callbacks rather than leaking them to return early.

For early consumer exit, return your own sentinel error from `consume`; the
sentinel is returned to the caller after cleanup, not silently converted to
success. Both early stop and real worker failures use the same join path. The
[demo](../examples/cmd/demo/main.go) demonstrates this; the
[tests](../examples/examples_test.go) coordinate a worker failure with a sibling
waiting for cancellation to show that the first error survives.

For multiple stages, repeat the same contract at each edge: the sender owns
close, every blocking send/receive observes the shared cancellation, and an
owner joins every stage. A generator must stop when downstream leaves early.
A merge forwarder must handle both upstream close and downstream cancellation;
its coordinator closes the merged channel after all forwarders finish. Do not
copy a bare `for v := range input { output <- v }` stage into a cancelable
pipeline: both sides can block forever after an early exit.

If mapping/filtering data locally does not require asynchronous producers, a
plain loop or Go 1.23 `iter.Seq` avoids goroutine lifetime machinery. An iterator
must stop immediately when `yield` returns false; a channel-backed iterator that
returns on `break` still needs to cancel and join its upstream producer. Range
over a function is synchronous iteration, not an implicit worker pool.

## Semaphore admission

A buffered channel is a counting semaphore: send acquires, receive releases.
Validate capacity is positive. Acquire **before** starting the goroutine, with a
cancellation alternative; release with a defer, and join all launched operations.
Never close the semaphore to cancel users; use context.

The following complete function bounds both launched goroutines and active
operations, unlike acquiring inside an unbounded number of goroutines. It is a
recipe (not an additional compiled sample); worker errors belong in the pipeline
above when they need propagation.

```go
package admission

import (
    "context"
    "errors"
    "sync"
)

// Visit calls a non-panicking, returning visitor at most limit times concurrently.
func Visit(ctx context.Context, limit int, values []int, visit func(context.Context, int)) error {
    if limit <= 0 || visit == nil {
        return errors.New("positive limit and non-nil visitor required")
    }
    slots := make(chan struct{}, limit)
    var wg sync.WaitGroup
admission:
    for _, value := range values {
        if err := ctx.Err(); err != nil {
            break
        }
        select {
        case slots <- struct{}{}:
        case <-ctx.Done():
            break admission
        }
        wg.Go(func() {
            defer func() { <-slots }()
            if ctx.Err() == nil {
                visit(ctx, value)
            }
        })
    }
    wg.Wait()
    return ctx.Err()
}
```

This recipe's `visit` has no error result; do not discard failures to fit that
signature. Prefer `ForEach` when real operations return errors. A semaphore
controls concurrency, not starts per second, FIFO fairness or weighted resources.

## errgroup in existing projects

For projects already using [`errgroup`](https://pkg.go.dev/golang.org/x/sync/errgroup),
`WithContext`'s derived context is canceled when `Wait` returns, even on success;
do not reuse it for later work. With `SetLimit`, `Go` blocks at capacity: nested
submissions can deadlock when active workers occupy all slots. Never change the
limit while tasks are active. If admission must stop promptly on cancellation,
use an explicit context-aware admission policy rather than assuming `Go` observes
the context. `Wait` still requires every started function to return; cancellation
does not preempt tasks.

## Rate limits and token buckets

A concurrency limit bounds in-flight calls; a rate limit bounds admission over
time. Often both are needed. A ticker pacing starts alone still permits unlimited
in-flight work if jobs become slower than the tick interval. Use a fixed worker
pool behind rate-limited admission instead of `go process()` on each tick.

For a simple integer requests-per-second pacing rule, validate `rps > 0` and
`interval := time.Second / time.Duration(rps)` is positive before `NewTicker`.
Otherwise invalid input can panic, including rates above timer resolution.
Select between `ticker.C` and `ctx.Done()` while waiting; `defer ticker.Stop()`
and an explicit cancellation exit are required. Stop does not close `ticker.C`.
A ticker may adjust/drop ticks for a slow receiver; this is approximate pacing,
not a durable event count or strict service-level quota.

A token bucket adds bounded burst capacity:

- Validate positive refill interval and positive capacity; initially fill up to
  capacity only if the documented policy permits an initial burst.
- A refill owner selects on ticker and cancellation, attempts a nonblocking token
  send (drop refill when full), stops its ticker and publishes completion on exit.
- `Allow` is a nonblocking token receive; `Wait(ctx)` selects a token or context.
  Do not assume fairness among waiting clients, or that cancellation wins if both
  cases are ready. Do not close the tokens channel: closed receives grant tokens
  forever, and a refill sender could panic.
- The creator owns cancel **and join** of the refill goroutine. An immortal
  refill loop and a stopped ticker with a forever-blocked range are both leaks.
- Fixed-rate ticker refill is a coarse bucket. For precise elapsed-time refill,
  keep bounded token state and monotonic timestamps under one lock; avoid a
  custom algorithm if a project-approved limiter already provides the policy.

No background limiter service is required for the executable worker example.
Rate-limiter correctness requires clock/boundary and burst tests of the chosen
policy; the provided sample does not claim to test or implement a limiter.

## Pub/sub and slow consumers

A local pub/sub channel registry needs subscription lifetime and loss policy,
not just a map protected by `RWMutex`. Options are explicit bounded blocking
with cancellation, reject/drop with observability, or a durable broker when loss
is unacceptable. A nonblocking send with `default` **drops** data for a slow/full
subscriber; it does not guarantee reliable delivery or exactly-once effects.

Subscription removal and close must synchronize with publishing so no snapshot
publisher can send to a closed channel. One simple policy holds the registry
lock during nonblocking sends and removes/closes under the exclusive lock;
never run subscriber callbacks or indefinitely blocking sends under that lock.
Give the caller an unsubscribe operation and guarantee who joins any delivery
goroutine. A closed receive must terminate the subscriber, not spin on zeroes.
Per-subscriber channel capacity bounds message count only, not payload bytes.
