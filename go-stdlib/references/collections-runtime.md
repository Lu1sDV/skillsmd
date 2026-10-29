# Collections and runtime APIs

## Contents

- [Collections and iterators](#collections-and-iterators)
- [Synchronization and tests](#synchronization-and-tests)
- [Error inspection](#error-inspection)
- [Logging](#logging)
- [Flags and configuration](#flags-and-configuration)
- [Math, randomness and cryptography](#math-randomness-and-cryptography)
- [SQL handles, rows and transactions](#sql-handles-rows-and-transactions)

## Collections and iterators

| API | Minimum version | Contract |
|---|---|---|
| `slices.Sort`, `SortFunc`, `SortStableFunc` | 1.21 | Mutate input; comparator must define strict weak ordering; use `cmp.Compare`, not subtraction that can overflow |
| `slices.BinarySearch` / `BinarySearchFunc` | 1.21 | Input sorted under the matching order; returns insertion position plus found |
| `slices.Min` / `Max` | 1.21 | Panic on empty input |
| `slices.Compact`, `Delete`, `Insert`, `Replace` | 1.21 | Retain returned slice; Compact removes adjacent duplicates only; backing storage may be shared |
| `slices.Clone`, `maps.Clone` | 1.21 | Shallow copies; nested pointers/slices/maps remain shared |
| `slices.Grow`, `Clip` | 1.21 | Grow ensures room for additional elements; Clip limits capacity, not a guarantee of releasing the backing allocation |
| `slices.Equal`, `Compare`, Func variants | 1.21 | Nil and empty slices compare equal; equality and ordering have different NaN behavior |
| `maps.Copy`, `Equal`, `DeleteFunc` | 1.21 | Copy overwrites destination entries; destination must be writable; ordinary map synchronization rules apply |
| `slices.All`, `Values`, `Backward`, `Collect`, `AppendSeq`, `Sorted` | 1.23 | Iterators use range-over-function; `Sorted` returns a **slice** |
| `maps.All`, `Keys`, `Values`, `Collect`, `Insert` | 1.23 | Map iteration order unspecified; Keys/Values return iterators, not slices |
| `sort.Search(n, predicate)` | Earlier releases | Predicate must be false then true; returns n when never true |
| `container/heap` | Earlier releases | Implement Len/Less/Swap/Push/Pop; use package heap.Push/Pop to maintain order |
| `container/list` | Earlier releases | Doubly linked elements containing `any`; element membership/ownership matters |

`sort` is supported, not deprecated. Its binary-search predicate remains useful
without an actual slice. `heap.Init` is O(n); push/pop are O(log n), peek O(1) when
nonempty. The interface's `Pop` removes the final element after the heap algorithm
has rearranged it; it is not a standalone minimum-extraction method. Clear removed
pointer slots to avoid retaining objects. `heap.Fix` needs the item's current
index, maintained through swaps when callers store handles.

Example function fragment (imports `slices`, Go 1.23+):

```go
func reversedCopy(values []int) []int {
    result := make([]int, 0, len(values))
    for _, value := range slices.Backward(values) {
        result = append(result, value)
    }
    return result
}
```

`Backward` yields **index and value**; one range variable takes the index.
Similarly `for value := range slices.Sorted(seq)` iterates indices of the returned
slice, not its values. Use `for _, value := range slices.Sorted(seq)`. Prefer
`Clone` then `Reverse` for an ordinary copied reversal; the fragment demonstrates
the iterator's two-value contract, not a universal replacement.

Go 1.22 changed relevant shrinking `slices` operations to clear obsolete tail
slots. Do not keep using old slice aliases as if their lengths/data were updated.
`cmp.Compare` defines a usable floating-point ordering including NaN, whereas
`==` still reports NaN unequal to itself. `maps.Equal` does not special-case NaN
keys/values. With interface-valued keys/elements, dynamic uncomparable values can
still panic; a generic `comparable` constraint is not a universal runtime guarantee.

Optional **go-algorithms** owns collections, sets/queues/trees/graphs and algorithm
invariants. **go-api-design** owns generic constraints and iterator API design.

## Synchronization and tests

This is an API selection index, not a second concurrency workflow:

| Primitive | Use / caveat |
|---|---|
| `sync.Mutex` / `RWMutex` | Protect one invariant using the **same** lock; RWMutex is not automatically faster |
| `WaitGroup` / `WaitGroup.Go` (1.25) | Join tasks; traditional positive Add before spawning; Go callbacks must not panic |
| `Once`, `OnceValue`/`OnceValues` (1.21) | One attempt, including failure; not a retry mechanism |
| `sync.Pool` | Disposable scratch objects; may discard values anytime, not a capacity-limited resource pool |
| `sync.Map` | Specialized concurrent map; compound operations and Range do not provide transaction/snapshot semantics |
| `sync.Cond` | Wait in a predicate loop under its lock; Wait releases then reacquires the lock |
| Typed `sync/atomic` values (1.19) | Single atomic operations/publication; do not protect unrelated mutable fields |

Do not copy locks, wait groups, once/pools/maps/conditions or typed atomic values
after first use. An atomic pointer publication does not make the pointed object
immutable. All stores to an `atomic.Value` must use the same concrete type;
plain nil stores panic. **go-concurrency** owns cancellation, blocking, backpressure
and race diagnosis.

Use `testing`, table/subtests, `t.Cleanup`, `t.TempDir`, `httptest`, `testing/fstest`,
fuzz targets, and benchmarks where the consumer contract warrants them. Stable
Go 1.25 concurrency tests use `synctest.Test(t, func(t *testing.T) { ... })` and
`Wait`, not experimental `Run`. **go-tdd** owns these workflows, isolation and CI;
calling a stdlib parser and asserting only that it did not panic is not an
application property.

## Error inspection

`errors.New` creates an error; `fmt.Errorf("open %s: %w", name, err)` adds context
and exposes a cause. Wrapping is an API choice: clients can inspect that cause.
`errors.Is` checks a value/matching contract through the error tree; `errors.As`
finds an assignable type or custom match and needs a correctly typed non-nil
pointer target. Do not compare error messages.

`errors.Join` (Go 1.20) preserves multiple causes and ignores nil inputs, returning
nil when all inputs are nil. `errors.Unwrap` only calls `Unwrap() error`; it does
not flatten the `Unwrap() []error` form used by Join. Use Is/As for traversal.
Return an actual nil `error` on success rather than a typed nil pointer. Routine
input errors are not panics. **go-idiomatic** owns recovery/resource workflows.

## Logging

Use existing logging conventions. `log` is suitable for simple text output;
`log/slog` (1.21) adds levels, structured attributes/groups and handlers. Both
can carry secrets unless fields are selected/redacted deliberately.

Complete initialization fragment (imports `log/slog`, `os`):

```go
logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))
logger = logger.With(slog.String("service", "catalogue"))
logger.Info("ready", slog.Int("workers", 4))
```

Use `LogAttrs` when typed attributes fit the call; avoid calculating expensive
values before a disabled log call without an `Enabled` guard. `InfoContext` passes
context to the handler; it does not automatically copy every context value into
output. Cancellation should not suppress records needed to diagnose cancellation.

Built-in handlers manage concurrency; custom handlers must implement concurrent
`Enabled`/`Handle`/`WithAttrs`/`WithGroup` semantics, preserve derived wrappers,
and clone a `slog.Record` before mutating a shared copy. Embedding a Handler and
overriding only Handle may let With discard the wrapper. Prefer built-in handlers
and `HandlerOptions.ReplaceAttr` for simple transformations. Logger methods do not
return handler errors; explicitly design error/durability behavior for audit sinks.
`log.Fatal` exits without defers, so keep it out of resource-owning helpers.

## Flags and configuration

Use a local `flag.FlagSet` with `ContinueOnError` for reusable command parsing;
set its output to stderr/a supplied diagnostic writer. Global `flag.CommandLine`
and environment mutation complicate tests/concurrency. `flag` parsing stops at
the first non-flag argument or `--`; it does not implement every POSIX/GNU CLI
convention or parse interspersed options automatically. Check parse errors, help
(`flag.ErrHelp`), unused positional arguments and domain ranges after conversion.

Standard String/Int/Bool/Duration flags cover small CLIs. For custom values,
implement `flag.Value.String/Set` with checked parsing. `os.LookupEnv` distinguishes
missing from explicitly empty. Define CLI/env/file/default precedence once and
validate the final typed configuration. **go-system-design** owns configuration
assembly and dependency wiring.

## Math, randomness and cryptography

- `math` covers floating-point abs/min/max, rounding, powers/roots/logs/trig,
  infinities/NaN, and constants. Check domain/finiteness and tolerances; avoid
  converting integers to float64 just to compare them. Built-in `min`/`max` need
  Go 1.21. Floating-point results are not exact decimal accounting.
- `math/rand/v2` (1.22) is for sampling/simulation, **not secrets**. `IntN` and
  generic `N` require a positive upper bound; validate empty choices first.
  Package-level functions are concurrent-safe; a local Rand/Source needs its own
  ownership. `rand.New(rand.NewPCG(seed1, seed2))` supports reproducible local tests.
- Use `crypto/rand` for tokens/keys, then `encoding/hex` or raw URL base64 for
  transport. Go 1.24+ `crypto/rand.Read` fills its buffer and does not return an
  error; an entropy failure terminates the process. Older-version recipes must
  check returned errors. Do not replace entropy failure with math/rand.
- SHA-256/SHA-512 digest data; they are not encryption, authentication without a
  key, or password hashing. MD5 is unsuitable where collision resistance matters.
  Use `crypto/hmac` with a suitable hash for a MAC and `hmac.Equal` for comparison;
  validate decoded tag size/format and obtain keys from real secret management.
  Passwords need a vetted password-hashing scheme, not a fast general-purpose hash.
- Encryption needs a reviewed authenticated construction and nonce/key policy,
  not a home-grown combination of hashes. The upstream crypto section supplies
  digest/MAC/random APIs, not a complete encryption recipe.

## SQL handles, rows and transactions

`database/sql` needs a separate driver; none is bundled here. `sql.Open` creates a
concurrent-safe pool handle and may not connect. Use bounded `PingContext` if startup
requires connectivity, and choose max-open/max-idle/lifetime settings from actual
service and database capacity, not an unexplained constant. Reuse the pool.

| Operation | Required check |
|---|---|
| `QueryRowContext(...).Scan(...)` | Deferred execution errors and `sql.ErrNoRows` appear at Scan |
| `QueryContext` + `rows.Next()` | Check query error first, defer Close, check each Scan and final `rows.Err()` |
| `ExecContext` | Check execution error; RowsAffected/LastInsertId can themselves fail or be unsupported |
| `PrepareContext` | Check preparation, close statement, use correct parameter markers |
| `BeginTx` | Check error, arrange rollback, keep every operation on that Tx |
| `Commit` | Check error; failure is not successful persistence or universal proof no effect occurred |

Bind data values with placeholders; never interpolate them into SQL. Placeholder
syntax is driver-specific, and bind parameters do not quote dynamic identifiers:
select identifiers from an explicit allowed set. QueryRow/Rows scans need nullable
types/pointers when NULL is possible. `sql.RawBytes` borrows memory valid only until
the next Next/Scan/Close; copy when retaining it.

Deferring `tx.Rollback` after successful BeginTx ensures early-error cleanup;
after successful Commit it returns `sql.ErrTxDone`, not literal success. Do not
ignore meaningful rollback failures when they affect the outcome. Transfer examples
also need row-existence, amount/overflow, affected-row, isolation and authorization
invariants; two UPDATE statements alone are not a correct financial transaction.
A commit error may require reconciliation rather than blind replay. Cancellation
behavior depends on driver/database support. SQL/network compatibility needs real
integration checks; no driver/database is exercised by this bundle's examples.

## Primary references

[slices](https://pkg.go.dev/slices), [maps](https://pkg.go.dev/maps),
[cmp](https://pkg.go.dev/cmp), [sort](https://pkg.go.dev/sort),
[container/heap](https://pkg.go.dev/container/heap),
[container/list](https://pkg.go.dev/container/list), [sync](https://pkg.go.dev/sync),
[sync/atomic](https://pkg.go.dev/sync/atomic), [errors](https://pkg.go.dev/errors),
[slog](https://pkg.go.dev/log/slog), [slog handler guide](https://go.dev/s/slog-handler-guide),
[flag](https://pkg.go.dev/flag), [math/rand/v2](https://pkg.go.dev/math/rand/v2),
[crypto/rand](https://pkg.go.dev/crypto/rand), [crypto/hmac](https://pkg.go.dev/crypto/hmac),
[database/sql](https://pkg.go.dev/database/sql).
