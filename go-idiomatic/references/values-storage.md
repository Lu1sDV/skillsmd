# Values and backing storage

## Contents

- [Slices and maps](#slices-and-maps)
- [Text boundaries](#text-boundaries)
- [Numeric boundaries](#numeric-boundaries)

## Slices and maps

A slice describes a backing array, length and capacity. Assignment/slicing copies
that descriptor, not the array. `append` must return a new descriptor: always keep
the returned slice. Within capacity it writes into existing storage, including
storage visible through other aliases; beyond capacity it allocates a new array.
The exact growth factor is not a contract. `copy` handles overlapping ranges.

`view := xs[a:b:b]` limits capacity to length, forcing a nonempty append to allocate,
but `view[0] = x` still changes `xs[a]`. `slices.Clip` similarly limits capacity;
neither is an ownership copy nor guarantees release of the backing array. To retain
a small independent portion, validate bounds, allocate and copy (or clone an
appropriate nonempty slice). Copies of nested slices are shallow: allocate each
row separately for a matrix, and deep-copy only when the contract requires it.

Complete implementation, also in [semantics.go](../examples/semantics.go):

```go
package idiomatic

import "fmt"

// Prefix returns independent storage; n counts bytes, not Unicode characters.
func Prefix(data []byte, n int) ([]byte, error) {
    if n < 0 || n > len(data) {
        return nil, fmt.Errorf("prefix length %d outside [0,%d]", n, len(data))
    }
    out := make([]byte, n)
    copy(out, data[:n])
    return out, nil
}
```

Returning a zero-length non-nil allocation here intentionally distinguishes empty
success from nil failure. Nil slices allow `len`, `cap`, `range`, `append` and
`copy`; indexing still requires a valid index. Non-nil empty slices have length zero
too. JSON commonly emits nil as `null` and empty as `[]` (tags/custom marshaling can
change this): choose your wire contract explicitly.

Map assignment shares the map; clone only when independent keys/values are needed
(and remember a clone is shallow). A nil map supports lookup/comma-ok, `len`, range,
`delete` and `clear`; writing an entry panics. Use comma-ok when zero is a valid
stored value. Map values are not addressable: update a struct via get-modify-set,
or intentionally store pointers. Iteration order is unspecified, not a stable
random permutation; sort keys for reproducible output. Mutation during iteration
has specified but nondeterministic visibility for additions; do not rely on it
for ordered processing. Synchronization of concurrent access routes to
**go-concurrency**; runtime race diagnostics are not guaranteed for every misuse.

`clear` deletes entries, not an API guarantee of reduced retained capacity. Deleted
referenced values can become collectible; replacing the map makes old storage
eligible only when no aliases retain it. There is no portable map shrink control;
`sync.Pool` is not a cache-compaction tool. Preallocate slices when the size is known
and trustworthy, but validate externally supplied sizes before `make`; allocation
failure is not ordinary input validation. Collection implementations and retention
on stack/queue removal route to **go-algorithms**.

Do not copy a used `sync.Mutex`, `RWMutex`, `WaitGroup`, `Once`, `Map`, `Pool`, or
atomic wrapper, including inside copied structs. Use pointer receivers and preserve
identity throughout callers; a pointer receiver alone does not stop assignment or
range copying. A nonzero `strings.Builder` must not be copied either. Detailed
synchronization invariants belong to **go-concurrency**.

## Text boundaries

A string is immutable bytes and can contain invalid UTF-8 or NUL. `len(s)` counts
bytes; `s[i]` returns a byte; slices use byte offsets. `range s` yields byte start
indices and decoded runes. Invalid encoding yields `utf8.RuneError`, consuming one
byte per invalid encoding; a valid encoded U+FFFD is not itself invalid.
`utf8.ValidString` distinguishes them. A `rune` is an alias for `int32`, not a type
that automatically validates Unicode scalar values.

Correct examples: `len("café") == 5`, `len("cafe") == 4`; `"hello"[0] == 104`;
range over `"Go!"` has indices 0, 1, 2. Range over `"A世"` has indices 0, 1 and
values `'A'`, `'世'`. `"世"[:1]` is invalid UTF-8, but `"Hello, world"[7:8]` is
valid ASCII `"w"`. The source's claimed contrary outputs are transcription defects.

`[]rune(s)` enables code-point indexing but replaces invalid sequences and allocates;
runes are not user-perceived grapheme clusters (combining marks/emoji sequences).
For a UTF-8 contract validate before conversion. The executable `RunePrefix` rejects
invalid UTF-8, negative lengths and requests past the rune count. It finds a byte
boundary by ranging rather than allocating a rune slice; grapheme slicing is a
separate Unicode requirement, not something this helper promises.

`[]byte(s)` and `string(b)` provide ordinary safe conversion semantics: subsequent
mutation of `b` cannot mutate the string. Do not use unsafe aliases to defeat that
contract. String substrings may retain large source storage; `strings.Clone` is
available for intentional independent retention. Use `strings.Join` for joining
parts or `strings.Builder` for incremental construction, not a chain of growing
concatenations. Simple fixed concatenation is fine. Detailed search/case/trim,
parsing/encoding and normalization choices route to **go-stdlib**.

## Numeric boundaries

Integer division truncates toward zero; remainder follows the dividend's sign.
Runtime integer division by zero panics. The minimum signed integer divided by -1
is the defined overflow exception, not a panic. Integer overflow does not signal
failure: unsigned arithmetic is modulo its width and signed arithmetic is defined
by the representation. A typed constant that exceeds its range fails compilation.
Narrowing conversions discard high bits; signed-to-unsigned conversion can turn -1
into a large value. Check bounds **before** computing/converting, not afterward.

Complete implementation in [semantics.go](../examples/semantics.go):

```go
package idiomatic

import (
    "errors"
    "math"
)

var ErrOverflow = errors.New("integer overflow")

func AddInt64(a, b int64) (int64, error) {
    if (b > 0 && a > math.MaxInt64-b) || (b < 0 && a < math.MinInt64-b) {
        return 0, ErrOverflow
    }
    return a + b, nil
}
```

`int(f)` truncates fractional parts, but converting out-of-range floating values is
not portable validation. Check NaN/infinity/range first. Parse external values with
`strconv.ParseInt`/`ParseUint` and the intended bit size, retaining errors; `Atoi`
uses platform `int`. `string(65)` gives `"A"`, not decimal `"65"`; use `strconv.Itoa`
or `FormatInt` for numeric text.

Untyped constant `0.1 + 0.2` rounds once when assigned to float64 and equals the
float64 constant `0.3`. Adding float64 **variables** rounds at runtime and can differ.
Constant `5.0/0` is a compile-time error too; runtime floating division by a zero
variable can produce infinities/NaN. Use domain-chosen absolute/relative tolerances
only when approximate equality is meaningful; reject nonfinite inputs where
required. Money may need integer minor units or specified decimal arithmetic, not
an arbitrary epsilon. Math/crypto APIs route to **go-stdlib**.
