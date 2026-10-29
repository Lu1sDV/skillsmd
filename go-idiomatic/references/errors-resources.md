# Errors and deterministic cleanup

## Error values and scope

Use `(value, error)` for fallible operations; absence can instead be `(value, bool)`
when there is no separate failure. Check errors before using results. Return `nil`
on success, not a typed nil pointer. Use sentinel errors for stable conditions and
custom types for structured details only when callers need them. Error strings
start lowercase and avoid redundant punctuation.

Add operation/context with `fmt.Errorf("read config %q: %w", path, err)` when the
caller should inspect the cause. `%v` formats without exposing the cause as part
of the API. `errors.Is` recognizes sentinels through wrapping/joining; `errors.As`
extracts a type through wrapping (declare `var e *os.PathError`, pass `&e`). Do not
match text or directly assert a wrapped error's concrete type. Decide at the
boundary whether to return or log; logging and returning everywhere duplicates
reports and may leak input secrets. Plain propagation is fine if context is already
adequate; wrapping is not a substitute for a stack trace.

`:=` can silently shadow the error you intend to return. This **fragment** is wrong:

```go
var err error
if needsWrite {
    _, err := f.Write(data) // inner err, not outer err
    if err != nil {
        log.Print(err) // logging does not propagate failure
    }
}
return err // can return nil after the failed write
```

Instead return that inner error immediately, or assign to the outer variable with
`=` when a deferred closure genuinely needs it. A named result shadowed at a naked
return may be rejected by the compiler, but explicit returns of an unaffected outer
error can still be incorrect. `if err := op(); err != nil { return err }` is normal
and correct: the failure itself is returned, not an unrelated variable.

## Ownership and defer

The opener owns cleanup unless the API explicitly transfers ownership. Do not close
a borrowed reader just because an assertion discovers `io.Closer`. Acquire, check,
then defer; do not discard acquisition errors. A nil `*os.File`'s `Close` returns an
error rather than necessarily panicking, so the source's categorical panic claim
is wrong. Registering cleanup before the error check is still unsafe for general
resource types and can hide the real failure.

A defer evaluates its function value, arguments and receiver immediately, then
executes at **function** return in LIFO order. A closure reads captured variables
when executed and may change named results after return expressions assign them.
A deferred nil function panics when invoked. Defer inside a loop accumulates until
that function returns; process each file in a helper so lifetime is one iteration.
Explicit close is also valid but must cover all error paths. Do not rely on GC or
finalizers for prompt cleanup.

This complete bounded file reader preserves both read and close failures. It does
not close a caller's resource because it opens its own. Exact source:
[resources.go](../examples/resources.go).

```go
package idiomatic

import (
    "errors"
    "fmt"
    "io"
    "os"
)

// ReadFileLimit reads at most limit bytes, rejecting rather than truncating excess.
func ReadFileLimit(path string, limit int64) (data []byte, err error) {
    if limit < 0 || limit > 1<<20 {
        return nil, fmt.Errorf("limit %d outside [0,1048576]", limit)
    }
    f, err := os.Open(path)
    if err != nil {
        return nil, fmt.Errorf("open %q: %w", path, err)
    }
    defer func() {
        if closeErr := f.Close(); closeErr != nil {
            err = errors.Join(err, fmt.Errorf("close %q: %w", path, closeErr))
        }
    }()
    data, err = io.ReadAll(io.LimitReader(f, limit+1))
    if err != nil {
        return nil, fmt.Errorf("read %q: %w", path, err)
    }
    if int64(len(data)) > limit {
        return nil, fmt.Errorf("read %q: exceeds limit %d", path, limit)
    }
    return data, nil
}
```

The 1 MiB ceiling is an explicit example policy, not a general file API rule. Read
errors can accompany data; this helper discards partial data on failure by contract.
Close failure may accompany otherwise valid data, so callers must always check err.
Writes require checking short writes and flushing buffered writers before closing;
`Close` is not a durability guarantee. `Sync`, transactional replacement, HTTP body
lifetimes and SQL rows/transaction cleanup require resource-specific policies:
route to **go-stdlib** or **go-system-design** rather than assuming this read recipe
covers them. The real-file checks cover acquisition errors and size limits, not
injected read/close failures or durability guarantees.

## Panic, recover and exit

Return errors for expected malformed input, missing resources and operational
failures. Panic is a documented programmer-contract failure, not normal validation;
`Must...` names should advertise intentional panic semantics. Recover only at a
boundary that can restore/report a valid state, in a deferred function of the same
goroutine; do not convert every panic to successful zero values. Panic normally
unwinds defers in that goroutine; `os.Exit` does not, and `log.Fatal` calls exit.
Keep cleanup in `run() error`, return to `main`, print diagnostics to stderr there,
then exit nonzero. A server's handling of panics in other goroutines is a concurrency
boundary; no universal recovery wrapper is provided here.
