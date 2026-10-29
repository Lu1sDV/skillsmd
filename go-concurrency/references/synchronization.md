# Shared state and synchronization

## Contents

- [Choose the invariant, then the primitive](#choose-the-invariant-then-the-primitive)
- [Mutex and RWMutex](#mutex-and-rwmutex)
- [Atomics and publication](#atomics-and-publication)
- [Once and initialization](#once-and-initialization)
- [Pool and reusable buffers](#pool-and-reusable-buffers)
- [sync.Map](#syncmap)
- [Cond](#cond)

## Choose the invariant, then the primitive

| Requirement | Default |
|---|---|
| Protect related mutable fields or a typed map | One `sync.Mutex` guarding the entire invariant |
| Coordinate values and transfer ownership | Channels with explicit lifecycle |
| Join returning tasks | `sync.WaitGroup`, plus a separate error protocol |
| Independent scalar counter/flag | Typed `sync/atomic` value, if semantics fit |
| Publish initialization once | `sync.Once` / Go 1.21 Once helpers |
| Reuse temporary allocated objects after measurement | `sync.Pool`, never a resource owner |
| Specialized concurrent key access | Consider `sync.Map`; normal map+lock is the starting point |
| Wait for a changing shared predicate | `sync.Cond` and a predicate loop |

A data race is conflicting concurrent accesses, at least one a write, without
synchronization. Synchronize reads too. Do not use different locks for reads and
writes to the same data. A map read concurrent with a write is invalid even if
keys differ; the runtime may terminate with a fatal concurrent-map error, but
this is not guaranteed detection and not a recoverable panic strategy. Slice
append, mutable pointed-to objects and check-then-update operations need the same
ownership analysis.

Memory visibility comes from synchronization: mutex unlock followed by lock,
channel communication/close observations, atomic operations, and joined task
completion under their documented contracts. Sleeping or polling ordinary memory
adds no happens-before edge. Sending a pointer publishes preceding initialization
but does not grant safe concurrent mutation afterward.

## Mutex and RWMutex

Complete basic shared-counter implementation:

```go
package counter

import "sync"

type Counter struct {
    mu sync.Mutex
    value int
}

func (c *Counter) Add(delta int) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value += delta
}

func (c *Counter) Value() int {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.value
}
```

Zero-value Mutex/RWMutex are usable. Use pointer receivers and pointers to
containers with sync primitives. Do not copy after first use, including through
assignment, return-by-value, interface conversion or moving elements in slices.
Copying a pristine zero mutex is not itself forbidden, but a single-owner pointer
convention avoids accidentally copying a used one. `go vet` catches many, not all,
copy paths.

Keep lock scopes cohesive. Protect a multi-field invariant in one critical
section; locking each scalar separately can still violate the relationship.
Avoid callbacks/network I/O under locks, establish lock ordering, and do not
reenter a Mutex from a callback. Locks are not recursive. A failed `TryLock`
establishes no synchronization and is not permission to read protected fields.

RWMutex allows multiple readers or one writer. No read-to-write upgrade, no
write-to-read downgrade, and no recursive read locking: a waiting writer blocks
new readers and can deadlock recursive acquisition. Returning a map/slice pointer
from a read lock does not protect its later use. Snapshot/copy under the lock or
keep ownership explicit. Read-heavy does not by itself prove RWMutex wins;
benchmark contention and critical-section cost before replacing a Mutex.

## Atomics and publication

Go 1.19 typed `atomic.Int64`, `Uint64`, `Bool`, and `Pointer[T]` avoid raw-pointer
alignment mistakes. `Add`, `Load`, `Store`, `Swap` and `CompareAndSwap` are
sequentially consistent atomic operations, not a lock-free application design.
Go 1.23 adds typed integer bitwise `And`/`Or` operations. Use the project's version
floor. Never mix atomic and unsynchronized ordinary accesses to the same value;
raw 64-bit atomics have alignment requirements on some 32-bit platforms.

A CAS loop must retry from the new observed value and cannot safely repeat
external side effects. Two individually atomic fields do not make a consistent
pair. For an immutable configuration snapshot, publish an initialized
`*Config` with `atomic.Pointer[Config]`; treat the whole reachable graph as
immutable after publication. A pointer update does not make its pointee mutable
without locks. Zero `atomic.Pointer[T]` loads nil.

`atomic.Value` starts with `Load() == nil`. All stored values must have the same
concrete type; storing a nil interface panics. CAS comparisons require comparable
values and can panic for dynamically non-comparable values. Do not copy a Value
or typed atomic after first use. Do not use a cached atomic snapshot as a durable
transaction or invent lock-free queues without a demonstrated need.

## Once and initialization

`Once.Do` runs one initialization; concurrent callers wait until it returns.
If the function panics, Once considers it done; later `Do` calls do not retry.
A recursive call to `Do` on the same Once deadlocks. It has no reset operation.
`OnceFunc`, `OnceValue` and `OnceValues` (Go 1.21) package once-only calls and cached
results. Unlike `Once.Do`, these helpers re-panic the same panic value on each
call after an initialization panic. `OnceValues` can cache `(value, error)`, so
an initialization error is cached too; do not use it when transient failures must
be retried. Once safely publishes initialized fields, not subsequent mutations.
Prefer explicit startup/configuration ownership over hidden global singletons.

## Pool and reusable buffers

`sync.Pool` is an opportunistic allocation cache. The runtime may discard entries
at any time; `Get` can behave as if empty, and no particular Put/Get pairing is
guaranteed. It is not a connection pool, cache with retention promises, capacity
limit or cleanup mechanism. `New` may create a value when empty and must not be
changed concurrently with Get. Do not copy a used Pool.

Get grants temporary exclusive use by application convention. Reset before reuse,
never retain/use a buffer after Put, and copy bytes before returning them to a
caller if the buffer goes back into the pool. Validate/size for the actual input:
`copy(buf, data)` silently truncates when a fixed-size pooled buffer is too short.
Cap oversized buffers before retaining them and clear sensitive data if required.
Pooling `*bytes.Buffer` or a pointer to a byte slice can avoid interface boxing
allocations, but pool only after measurement; pooling everything can retain more
memory and complicate lifetime reasoning.

## sync.Map

Prefer a typed map with one lock when invariants span keys or values. `sync.Map`
is specialized for write-once/read-many entries or disjoint-key access; it is not
a universal replacement for maps or a transaction boundary. It is usable at the
zero value and must not be copied after first use.

- `Load`/`Store`/`Delete`, `LoadOrStore`, `LoadAndDelete` (Go 1.15), `Swap`,
  `CompareAndSwap`/`CompareAndDelete` (Go 1.20), and `Clear` (Go 1.23) each have
  documented per-operation semantics. `LoadOrStore(key, expensive())` evaluates
  `expensive()` first in every caller; it does not make initialization once-only.
- Keys must be comparable. CAS/Delete comparison values must be comparable;
  dynamic slice/map/function values can panic even though the API accepts `any`.
  Values retrieved from the map still need their own synchronization if mutable.
- `Range` is not a consistent snapshot or stable order. A false callback return
  stops iteration. Go 1.23 range-over-function syntax can range over the bound
  `m.Range` method because its callback shape matches an iterator; the `Range`
  method itself is old, not a new Go 1.23 API. Neither syntax makes it a snapshot.

## Cond

Use Cond for a shared predicate under one lock, not as a queued message stream.
`Wait` atomically unlocks the locker and suspends, then locks again before return.
Always use `for !predicate { cond.Wait() }`: a woken goroutine must recheck after
competing goroutines can change the state. Update state under the same lock;
`Signal` wakes one waiter and `Broadcast` wakes all. A signal is not a stored token
for future waiters. There is no intrinsic context-aware Wait or FIFO promise.

A bounded queue predicate must include not-empty/not-full and closed/canceled
state, wake all affected waiters on shutdown, and release retained references on
removal. The source's unbounded Cond queue without close is not a production
worker queue. Prefer a bounded channel with context for the demonstrated pipeline;
it already supplies admission and shutdown without bespoke queue machinery.
