# Behavior, traversal, and collaboration

## Task selection

| Need | Pattern and smallest Go shape | Cost / when NOT needed |
|---|---|---|
| Try handlers in order or wrap a request | **Chain of Responsibility**: ordered functions or HTTP middleware | Define first-match versus all-checks and stopping/error rules. A direct function is enough for one step. |
| Queue, record, undo or repeat an operation | **Command**: function now; typed data record when history/serialization is required | Execution/undo failures, history and idempotency. Do not add undo to irreversible effects. |
| Traverse lazily without exposing storage | **Iterator**: `iter.Seq` / `iter.Seq2` | Stop/error/resource contracts. Range a slice directly when laziness is unnecessary; a channel adds lifecycle work. |
| Coordinate a workflow across collaborators | **Mediator**: explicit coordinating function/service | Concentrates sequencing and partial-failure policy. Do not introduce a global event bus for a few direct calls. |
| Restore a prior valid local state | **Memento**: snapshot with sufficient owned state | Copy cost, retention, schema and restoration validation. A shallow struct copy is not automatically an independent snapshot. |
| Notify zero-to-many listeners | **Observer**: callback subscriptions with cancellation | Delivery ordering, failures, reentrancy and lifetime. A callback suffices for one known listener. |
| Legal actions depend on current status | **State**: enum and transition function first | Illegal transitions and atomic effects. State classes are worthwhile only for substantial state-specific behavior. |
| Choose among algorithms with one contract | **Strategy**: pass a function; interface if multiple operations/state matter | Define mutation, ownership and errors consistently. Keep a small stable switch instead of manufacturing strategies. |
| Fix orchestration but vary selected steps | **Template Method**: function with explicit hooks | Hook order/invariants. Embedding is not virtual dispatch; avoid base-type frameworks. |
| Add operations over a stable family of node types | **Visitor**: type switch, `go/ast.Inspect`, or `Accept` methods | New node kinds require handling across operations. A method suffices for one operation; do not return `any` only to assert it back. |
| Reject unhealthy calls / retry safe failures / cap concurrency | **Circuit breaker / retry / bulkhead**: independent policy around calls | Each has a different failure model. None replaces timeouts, admission bounds, or idempotency. |

Contents: [control flow](#chain-strategy-and-template-control-flow), [commands and snapshots](#command-and-memento-record-only-committed-edits), [iterators](#iterator-stop-errors-and-lifetime), [observers and mediators](#observer-and-mediator-delivery-is-a-contract), [state](#state-reject-illegal-transitions-without-mutation), [visitor](#visitor-choose-the-varying-axis), [resilience](#resilience-patterns-are-policy-not-automatic-safety).

Go 1.23 introduced range-over-function and `iter`; the bundle's runnable examples
require Go 1.25. Most function/interface patterns predate those APIs. The
[executable Take implementation](../examples/patterns.go) is the bundle counterpart
to the stop-propagation example below; do not infer other snippets have been
executed merely because the file contains runnable examples.

## Chain, strategy, and template control flow

These solve different decisions:

- A **strategy** chooses one algorithm, e.g. a comparator passed to
  `slices.SortFunc` or a `func([]byte) ([]byte, error)` compressor. Sorting may
  mutate input; compression may allocate output. Keep those contracts explicit.
- A **template** fixes the sequence, e.g. read → validate → transform → write,
  and accepts the specific varying steps. Return stage-specific wrapped errors;
  do not write if validation/transformation fails. Stream or bound inputs where
  materializing the whole dataset is not acceptable.
- A **chain** passes to the next handler or stops. A validation pipeline may
  instead run every check and `errors.Join` the failures. Do not use zero/empty
  output as the unhandled signal when it could be a valid result; use an explicit
  `handled bool` plus `error` where appropriate.

Complete package declarations for HTTP ordering, without replacing the writer:

```go
package behavior

import "net/http"

type Middleware func(http.Handler) http.Handler

// Chain(h, a, b) executes a -> b -> h on entry, then unwinds b -> a.
func Chain(h http.Handler, layers ...Middleware) http.Handler {
    for i := len(layers) - 1; i >= 0; i-- {
        h = layers[i](h)
    }
    return h
}
```

Precondition: handler and middleware functions are non-nil. A rejecting
middleware writes its response and **returns**, without invoking `next`. A layer
outside authentication sees denied requests too. Caching outside authorization
can leak protected data. Logging must redact secrets; recovery cannot undo an
already committed response. Optional writer capabilities and first-final-status
accounting are covered in [HTTP decorators](composition-patterns.md#http-decorators-preserve-capabilities).
The source's third-party rate limiter is not a standard-library primitive; this
bundle does not hide it behind fake stdlib APIs.

Go embedding does not provide overridable template hooks: a promoted
`(*BaseReport).Generate` calling `r.FormatTitle()` invokes the base receiver's
method, not a shadowing outer type's method. Pass the hooks explicitly.

Complete package declarations; the same template accepts an HTML-escaping or
plain-text strategy without inheritance:

```go
package behavior

import "strings"

func Report(title string, sections []string, format func(string) string) string {
    var out strings.Builder
    out.WriteString(format(title))
    out.WriteByte('\n')
    for _, section := range sections {
        out.WriteString(format(section))
        out.WriteByte('\n')
    }
    return out.String()
}
```

Precondition: non-nil formatter. `html.EscapeString` safely escapes text, not a
complete HTML document/layout; use `html/template` for contextual HTML output.
When title and section policies actually differ, pass distinct hooks. Do not
claim embedding changes dispatch. For a compression strategy, check both `Write`
and `Close` as in [the real gzip facade](composition-patterns.md#facade-error-and-resource-ownership).
Concatenating compressed values from a map is not a file archive: preserve names,
boundaries and deterministic ordering with `archive/tar` or `archive/zip`.
Payment strategies need currency/rounding and real provider success semantics,
not `float64` amounts and generated transaction IDs after a print statement.

## Command and memento: record only committed edits

Use `func(context.Context) error` for immediate or in-memory queued work; use a
validated data record for durable commands. A durable queue also needs a versioned
schema, ownership, completion and idempotency semantics. Serializing a closure
is not a durable command protocol. Bounded queues and worker shutdown belong to
`go-concurrency` when available; blocking result sends must not deadlock a close
that waits for workers while nobody drains results.

A **memento** records enough state to restore the invariant: text and cursor if
both matter, not only the last command name. Strings are immutable values; slices,
maps and pointers need copies of the mutable reachable data on save **and**
restore. A shallow copy is sufficient only when its elements are themselves
immutable/value-owned. Bound snapshot count/bytes and clear removed references;
undo history can retain secrets and whole old documents.

Complete package declarations for local UTF-8 text edits. Positions are **byte
offsets at rune boundaries**, not rune indexes or user-perceived grapheme indexes.
The zero-value editor is ready to use. This example is single-owner and keeps
history in memory without a retention cap; choose an application-specific cap
before using it for large/unbounded editing sessions.

```go
package behavior

import (
    "errors"
    "unicode/utf8"
)

type Edit struct {
    Start, End int // Replace [Start, End); equal offsets insert, empty Text deletes.
    Text       string
}

func (edit Edit) Apply(old string) (string, error) {
    if edit.Start < 0 || edit.End < edit.Start || edit.End > len(old) {
        return "", errors.New("edit range out of bounds")
    }
    boundary := func(pos int) bool {
        return pos == len(old) || utf8.RuneStart(old[pos])
    }
    if !boundary(edit.Start) || !boundary(edit.End) || !utf8.ValidString(edit.Text) {
        return "", errors.New("edit must preserve UTF-8 rune boundaries")
    }
    return old[:edit.Start] + edit.Text + old[edit.End:], nil
}

type Editor struct {
    text       string
    past, next []string
}

func (e *Editor) Text() string { return e.text }

func (e *Editor) Do(edit Edit) error {
    updated, err := edit.Apply(e.text)
    if err != nil {
        return err
    }
    e.past = append(e.past, e.text)
    e.text = updated
    clear(e.next)
    e.next = nil // A successful new edit invalidates redo.
    return nil
}

func (e *Editor) Undo() bool {
    if len(e.past) == 0 {
        return false
    }
    last := len(e.past) - 1
    e.next = append(e.next, e.text)
    e.text = e.past[last]
    e.past[last] = ""
    e.past = e.past[:last]
    return true
}

func (e *Editor) Redo() bool {
    if len(e.next) == 0 {
        return false
    }
    last := len(e.next) - 1
    e.past = append(e.past, e.text)
    e.text = e.next[last]
    e.next[last] = ""
    e.next = e.next[:last]
    return true
}
```

`Edit.Apply` requires valid UTF-8 `old`; `Editor` maintains that invariant by
keeping its field private and accepting only validated replacements. Rejecting an
edit leaves text and both history stacks unchanged. Snapshot restore cannot fail
here because saved states are valid private strings. A more general
`Execute() error` / `Undo() error` manager must move stack entries **only after**
the operation succeeds, and specify what partial failure means. Do not reuse a
mutable command instance across histories if executing it overwrites undo data.

Undo is not automatically an inverse of a remote payment, notification or file
write. Use an explicit compensating action and represent compensation failures;
a local memento does not roll back external effects. Persisted snapshots need
schema/version and invariant validation before replacement. For file saves,
check encode/write/close errors and use a staged temporary file plus rename when
atomic replacement is required; truncating the only save before encoding can
lose the previous state. Gob is not an untrusted-input security boundary.

## Iterator: stop, errors, and lifetime

An `iter.Seq[T]` receives `yield func(T) bool`. When `yield` returns false,
**return without another yield or upstream pull**. A consumer's `break` must
propagate through every recursive traversal and adapter. A sequence need not be
concurrent, restartable or safe during collection mutation: document those
properties instead of assuming them.

Complete package declarations, equivalent to the bundle's executable `Take`:

```go
package behavior

import "iter"

func Take[T any](source iter.Seq[T], n int) iter.Seq[T] {
    return func(yield func(T) bool) {
        if n <= 0 {
            return // Do not even start a resource-owning source.
        }
        remaining := n
        for value := range source {
            remaining--
            if !yield(value) || remaining == 0 {
                return // Stop now, not after pulling value n+1.
            }
        }
    }
}
```

Keep `remaining` inside the sequence invocation so a restartable source gives a
restartable adapter; capturing and decrementing the original `n` would change
subsequent traversals. Filtering may consume many upstream values before finding
one accepted value; that is different from accidentally pulling beyond a `Take`
limit. Mapping/filtering fragments (package and `iter` import omitted):

```go
func Map[T, U any](source iter.Seq[T], transform func(T) U) iter.Seq[U] {
    return func(yield func(U) bool) {
        for value := range source {
            if !yield(transform(value)) {
                return
            }
        }
    }
}
func Filter[T any](source iter.Seq[T], accept func(T) bool) iter.Seq[T] {
    return func(yield func(T) bool) {
        for value := range source {
            if accept(value) && !yield(value) {
                return
            }
        }
    }
}
```

Preconditions: non-nil source/callbacks. If transformation can fail, change the
contract to carry an error; do not silently skip failures. `iter.Seq2[T, error]`
is a convention, not built-in error semantics: define a non-nil error as one
terminal item with no valid value, then stop. Consumers check `err` before using
the value and propagate it, not just log and continue.

Complete package declarations for a fallible one-shot iterator over a borrowed
reader; the reader is not closed by this function:

```go
package behavior

import (
    "bufio"
    "io"
    "iter"
)

func Lines(r io.Reader) iter.Seq2[string, error] {
    return func(yield func(string, error) bool) {
        scanner := bufio.NewScanner(r)
        for scanner.Scan() {
            if !yield(scanner.Text(), nil) {
                return
            }
        }
        if err := scanner.Err(); err != nil {
            yield("", err)
            return
        }
    }
}
```

`Scanner` has a token-size limit; configure a documented larger bound or use a
reader-based parser for larger records, rather than dropping `scanner.Err()`.
Breaking early intentionally does not validate the unread remainder. Although a
new scanner is created per invocation, the borrowed reader's position has moved,
and scanner read-ahead means another invocation is not a reliable continuation
at exactly the last yielded line. Treat this sequence as single-use. If an
iterator opens a file internally, open it inside the invocation, defer close,
and decide how close errors surface; holding an owned resource before iteration
can leak it when the sequence is never consumed. `iter.Pull` needs a deferred
`stop()` when the caller may stop before exhaustion.

For **pagination**, validate page size, pass `ctx` through actual network
requests, close each response body, validate HTTP/application errors, and stop
fetching immediately after downstream false. Preserve a terminal fetch error in
`Seq2`, including cancellation. Use the API's continuation token/has-more contract;
`len(page) == pageSize` is not universally reliable. Define empty-but-more pages
and repeated-token behavior so a broken server cannot cause an unbounded loop.
Do not capture a single mutable paging cursor outside the sequence if promising
restartability.

For **tree traversal**, in-order/pre-order recursion returns a bool through every
stack frame; ignoring a left subtree's false continues illegally. Breadth-first
iteration uses a queue and also returns immediately on false. Cycles/depth and
mutable-node ownership need policy, as in [composite](composition-patterns.md#composite-trees-not-arbitrary-graphs).
An integer Fibonacci iterator must check overflow or impose a representable
bound; `a, b = b, a+b` can wrap and keep satisfying `a <= max` forever. Do not use a
channel/goroutine just to iterate synchronously; an abandoned consumer otherwise
needs cancellation and joining.

## Observer and mediator: delivery is a contract

A **mediator** coordinates collaborators (e.g. save an order, then request
inventory work). An **observer** broadcasts a change. An event bus can implement
both, but introduces event routing, subscription lifetime, delivery failures and
partial success; it does not make operations atomic or durably delivered.
Prefer typed events or direct coordination to unchecked `any` assertions keyed
by strings. Chat-room mediation also needs membership/authorization checks for
private messages, not just a recipient pointer.

Copy the callback list **while holding the lock**, then unlock before calling
user code. Merely copying a slice header does not snapshot its mutable backing
array. Invoking callbacks under a read lock deadlocks if a callback subscribes or
unsubscribes (needs a write lock); slow callbacks also block unrelated mutations.
The same rule applies to chat recipients and arbitrary loader/hooks.

Complete package declarations; zero value ready, synchronous delivery, unordered
listeners, collect errors after attempting every listener. The bundle's
[executable Subject counterpart](../examples/patterns.go) exercises this contract:

```go
package behavior

import (
    "errors"
    "sync"
)

type Subject[T any] struct {
    mu        sync.Mutex
    nextID    int
    listeners map[int]func(T) error
}

// Subscribe requires a non-nil listener and returns an idempotent cancellation.
func (s *Subject[T]) Subscribe(listener func(T) error) func() {
    s.mu.Lock()
    if s.listeners == nil {
        s.listeners = make(map[int]func(T) error)
    }
    id := s.nextID
    s.nextID++
    s.listeners[id] = listener
    s.mu.Unlock()
    return func() {
        s.mu.Lock()
        delete(s.listeners, id)
        s.mu.Unlock()
    }
}

func (s *Subject[T]) Notify(event T) error {
    s.mu.Lock()
    callbacks := make([]func(T) error, 0, len(s.listeners))
    for _, listener := range s.listeners {
        callbacks = append(callbacks, listener)
    }
    s.mu.Unlock()

    var failures []error
    for _, callback := range callbacks {
        if err := callback(event); err != nil {
            failures = append(failures, err)
        }
    }
    return errors.Join(failures...)
}
```

Cancellation prevents inclusion in **future snapshots**, not a callback already
selected for the current delivery. A callback can therefore cancel itself without
deadlock, yet may receive an already in-flight notification. Reentrant `Notify`
is allowed but can recurse; concurrent `Notify` calls may invoke the same callback
concurrently, so callbacks need their own synchronization or owner serialization.
Callback panics propagate; no silent recovery/pretend delivery. `T` is copied as a
Go value, not deep-copied; maps/slices/pointers in events must be immutable or
otherwise ownership-safe. Never copy `Subject` after first use.

For **channel observers**, the producer/subscription owner controls sends and
closure; expose a receive-only channel and idempotent unsubscribe, not a channel
that any observer may close. Coordinate removal, in-flight sends and close so
there is no send-on-closed-channel or double close. The source's nonblocking send
under a registry read lock can coordinate with close under its write lock, but
only with a checked/idempotent close and sole close ownership. Snapshotting
channels then closing them independently is unsafe. Closing a channel does not
remove it from the registry.

A buffer is finite, not a guarantee of nonblocking delivery; `default` drops
events when full. Choose block-with-cancellation, drop/coalesce, disconnect or
persist, and make that policy visible. Channels do not create goroutines or
asynchrony by themselves. An unbounded `go handler(event)` loop has no admission,
error collection or shutdown guarantee. Bounded dispatch, cancellation and joins
belong in `go-concurrency`; keep the delivery contract here even when that skill
is unavailable. An in-memory observer is not durable pub/sub.

## State: reject illegal transitions without mutation

A strategy is chosen by the caller; state governs what an object is currently
allowed to do. Start with an enum and explicit transition table/switch. Do not
publish an arbitrary `SetState` that bypasses transition validation.

Complete package declarations for the source order workflow, without pretending
to charge a card or ship a package. See the bundle's
[executable transition counterpart](../examples/patterns.go) for the same rules:

```go
package behavior

import "fmt"

type Status uint8

const (
    Pending Status = iota
    Paid
    Shipped
    Delivered
    Cancelled
)

type Action string

func Transition(current Status, action Action) (Status, error) {
    switch {
    case current == Pending && action == "pay":
        return Paid, nil
    case current == Paid && action == "ship":
        return Shipped, nil
    case current == Shipped && action == "deliver":
        return Delivered, nil
    case (current == Pending || current == Paid) && action == "cancel":
        return Cancelled, nil
    default:
        return current, fmt.Errorf("action %q not allowed in state %d", action, current)
    }
}
```

The caller computes `next, err`, returns on error, and commits `next` only on
success. Unknown enum values and terminal-state actions reject without changing
state. Transitioning paid → cancelled here describes the local rule, not proof
that a refund succeeded. Real effects need an explicit order, idempotency and
reconciliation/transaction policy. Concurrent actors need serialization or
compare-and-set/version checks so they cannot both act on stale state. Separate
state objects help only when there is enough behavior to justify them; they must
preserve these same invariants.

## Visitor: choose the varying axis

An `Accept(visitor)` interface lets new operations (area, drawing, evaluating,
printing) vary while a node family stays stable. Adding a node kind then requires
updating every visitor. A type switch is often the smaller Go choice for a closed
family; return an error for an unsupported kind/operator instead of an accidental
zero result. Use typed results such as `(float64, error)` for evaluation rather
than `any` plus unchecked assertions. Validate expression shapes and division
policy (including zero) when the AST can come from external input.

The standard library already provides AST visitors. Complete package declarations
for one operation over a non-nil standard-library AST and its descendants:

```go
package behavior

import "go/ast"

func CountCalls(root ast.Node) int {
    count := 0
    ast.Inspect(root, func(node ast.Node) bool {
        if _, ok := node.(*ast.CallExpr); ok {
            count++
        }
        return true
    })
    return count
}
```

`ast.Inspect` calls the function with nil on traversal unwind; this assertion is
safe for nil. Returning false skips that node's descendants, **not the entire
walk**; it differs from `iter.Seq` stopping. Stateful visitors should reset their
accumulators per operation if reuse is expected. For custom recursion, decide
who walks children (visitor or nodes) so descendants are neither skipped nor
visited twice; propagate errors/stopping through the whole traversal.

## Resilience patterns are policy, not automatic safety

| Pattern | Use when | Key decision / cost / when NOT needed |
|---|---|---|
| Circuit breaker | Calls to an unhealthy dependency worsen an outage | Closed → open after classified failures; open rejects; bounded half-open probes decide recovery. Adds rejection state and tuning; unnecessary for deterministic local work. |
| Retry with constant/exponential backoff | A classified transient failure may succeed later and repetition is safe | Bound attempts and total deadline, cap/saturate delay arithmetic, add appropriate jitter. Do not retry validation/auth failures or duplicate non-idempotent effects blindly. |
| Bulkhead | One dependency/work class must not consume all concurrent capacity | Separate finite budgets, bounded admission/wait, clear overload error. Adds capacity partitioning; a circuit breaker does not bound healthy-but-slow calls. |

These are separate strategies/decorators, not one magical reliability wrapper.
A breaker needs atomic admission and completion accounting, **including the
first probe** transitioning open → half-open. Reserve its slot before executing;
the source leaves that first probe uncounted and can admit an extra one. Tag
admissions by generation/epoch so an old in-flight result cannot incorrectly
close or reopen a newer circuit generation. Define whether user cancellation,
HTTP status, timeout and transport/application failures count; `http.Get`
returning a response with status 500 is not a nil-success dependency outcome.
Execute the actual call outside the breaker lock and give it a deadline.

A retry function validates `maxAttempts >= 1` instead of wrapping a nil last
error after zero attempts. Check context before the **first** and each subsequent
attempt, pass it to the real operation (e.g. `http.NewRequestWithContext`), and
make backoff waits cancelable. Context cancellation does not preempt a callback
that ignores it. Avoid `math.Pow` converted to `time.Duration` where overflow can
produce a negative/uncapped delay. Close each response body before another
attempt, classify statuses explicitly, and preserve the terminal cause. Changing
a compressor/sort strategy is not a reason to add retries.

For a bulkhead, do not acquire a permit around spawning work and release it
before that work ends; permits represent actual in-flight calls. Define whether
rejection is immediate or waits with context, ensure every admitted path releases
once, and separate admission shutdown from cancellation of running calls. Bounded
queues and waiting callers consume capacity too. Pattern order matters: retries
can consume several breaker attempts/permits; holding a permit during backoff
reduces useful concurrency. Decide which unit each policy counts.

Implementation of cancellation, timers, permit ownership, worker termination and
race-safe lifecycle belongs in the `go-concurrency` skill; deployment budgets,
timeout/retry multiplication and outage policy belong in `go-system-design`.
Those optional hand-offs do not replace the local decisions above or require a
sibling installation to understand them. No untested mini-breaker framework is
included here.

## Sources and correction decisions

Adapted from [StructWeave behavioral patterns, pinned chapter 11](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/11-design-patterns-behavioral.md).
All ten named behavioral patterns, pagination/tree/function variants, and the
source circuit-breaker/retry discussion are retained. Bulkhead decisions make
the concurrency boundary explicit. Consolidation replaces linked validator,
editor, payment and event-bus frameworks with ordinary functions and narrow data.
Deliberate corrections: stop without a surplus iterator pull, carry iteration
errors, no callback under a registry lock, snapshot contents not slice headers,
explicit unsubscribe/closure ownership, history only after success, UTF-8/bounds
validation, no arbitrary state setter, no virtual-hook claim for embedding,
no fake transaction/archive/provider results, and no missing half-open probe
reservation or indiscriminate uncancellable retries.

Authoritative API contracts: [iter](https://pkg.go.dev/iter),
[bufio.Scanner](https://pkg.go.dev/bufio#Scanner),
[go/ast.Inspect](https://pkg.go.dev/go/ast#Inspect),
[errors.Join](https://pkg.go.dev/errors#Join),
[context](https://pkg.go.dev/context).
