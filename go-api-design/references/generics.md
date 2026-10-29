# Generic contracts

## Contents

- [Choose the abstraction](#choose-the-abstraction)
- [Constraints and permitted operations](#constraints-and-permitted-operations)
- [Inference and method restrictions](#inference-and-method-restrictions)
- [Collections and ownership](#collections-and-ownership)
- [Standard library and version gates](#standard-library-and-version-gates)

## Choose the abstraction

Use a concrete signature for one known type, an interface for interchangeable
behavior, and generics when one implementation preserves relationships between
input/output types. They combine: `func Stringify[T fmt.Stringer]([]T) []string`
accepts a homogeneous slice while calling each element's implementation. `[]T`
does not implicitly convert to `[]fmt.Stringer`, even if `T` satisfies Stringer.
A callback can express ordering without forcing every element to own a method.

Do not replace `(T, error)` or `(T, bool)` automatically with `Result[T]` or
`Optional[T]`. Named wrappers help only when they carry an actual domain contract;
zero-value validity and panic-on-Unwrap require explicit policy. Errors remain
runtime outcomes; generics do not validate JSON, context values or plugin data.
At dynamic boundaries use comma-ok assertions/type switches, not unchecked casts.

## Constraints and permitted operations

| Form | Meaning / trap |
|---|---|
| `any` | Alias for `interface{}`; no arithmetic, ordering or asserted methods |
| `comparable` | Allows `==`, `!=` and map keys, with dynamic-interface caveats below |
| `int \| int64` | Exactly these types, not defined types with those underlying types |
| `~int \| ~int64` | Also includes defined types with these underlying types |
| Embedded interfaces on separate lines | Intersection of their type sets |
| Union terms with `\|` | Union; non-interface terms must not overlap |
| Type terms plus `String() string` | Both underlying-type and method requirements apply |

A type parameter permits only operations valid for its entire constraint. No
field selection merely because every type term happens to share a struct field;
expose a method or pass a selector callback. Type-set interfaces containing type
terms or `comparable` are constraints only, not ordinary variable/field types.
`~T` needs a concrete underlying-type term, not another type parameter. An empty
intersection admits no useful instantiation. Multi-term unions cannot include
`comparable` or interfaces that specify methods.

Representative complete generic declarations (also in
[api.go](../examples/api.go)):

```go
type Integer interface { ~int | ~int64 }

func Sum[T Integer](values []T) T {
    var total T
    for _, value := range values {
        total += value
    }
    return total
}

func GroupBy[T any, K comparable](values []T, key func(T) K) map[K][]T {
    groups := make(map[K][]T)
    for _, value := range values {
        k := key(value)
        groups[k] = append(groups[k], value)
    }
    return groups
}
```

`Sum([]UserID{1, 2})` works for `type UserID int` because the constraint uses `~`.
This constraint intentionally covers two integer families, not all numbers.
Integer overflow still follows Go arithmetic; constraints do not detect it.
A production all-integer constraint must enumerate all intended signed/unsigned
terms including `uintptr` if appropriate. Do not use a numeric union to imply
that complex numbers are ordered.

### `comparable` is not a no-panic promise

Since Go 1.20, an ordinary comparable interface such as `any` can satisfy a
`comparable` constraint under the constraint-satisfaction exception. Thus
`Equal[any]([]int{1}, []int{1})` can compile and panic at equality; likewise a
`map[any]V` insert with a slice key panics. Structs/arrays with interface members
can hide the same risk. Interface equality panics when equal dynamic types are
not comparable; differing dynamic types compare false. If dynamic values are
part of the API, choose domain keys or an explicit equality function instead of
promising that a constraint makes all runtime contents safe.

Slices, maps and functions are not comparable except comparison to `nil`; a
struct/array is comparable only if all fields/elements are. NaN is comparable but
not equal to itself, so float set/map keys need an explicit NaN policy. Prefer
`slices.Equal`/`maps.Equal` for their supported element/value contracts; deep
reflection equality has different semantics and is not a domain definition.
The named regression in [examples_test.go](../examples/examples_test.go)
intentionally recovers the comparison panic to assert this documented trap;
production APIs should prevent it rather than recover indiscriminately.

## Inference and method restrictions

- Infer from function arguments and constraint relationships where possible:
  `GroupBy(values, func(v Record) string { return v.Name })`. Explicit type
  arguments may supply a prefix; the compiler infers the remainder.
- Result assignment of a *call* does not generally infer missing arguments:
  `NewStack[int]()` needs `int`; `var s *Stack[int] = NewStack()` does not fill it in.
  Since Go 1.21, assigning a generic **function value** to a known function type
  and passing generic functions as arguments can infer type arguments. Distinguish
  function-value inference from result-directed call inference.
- Generic types must be instantiated: `Stack[int]`. Constraints establish which
  instantiations are valid, not inheritance or covariance between them.
- Methods on a generic receiver redeclare its parameters, e.g.
  `func (s *Stack[T]) Pop() (T, bool)`. They cannot introduce their own new type
  parameters. A type-changing map operation is a free function:
  `func Map[T, U any](in []T, f func(T) U) []U`.
- Generic methods do not exist on non-generic receiver types either. A generic
  interface may describe methods using its interface-level parameters, not methods
  with an additional independent `[U any]` list.
- To assert/switch on a type parameter's dynamic value, use `any(value).(T)` or
  `switch any(value).(type)`. This adds a runtime boundary; it is not constraint
  refinement for arithmetic in the generic body.
- If mutation requires `*T` methods, constrain an additional pointer type with
  `interface { *T; RequiredMethod() }` or accept an allocator/callback. A zero
  generic pointer is still nil, and taking an address is not interface satisfaction.

For named-slice preservation, a useful signature is
`func Clone[S ~[]E, E any](s S) S`; a function returning only `[]E` loses the named
slice type. A type alias `type Set[T comparable] = map[T]struct{}` (Go 1.24+) keeps
identity with a map; `type Set[T comparable] map[T]struct{}` defines a distinct type
and can own methods. Neither gives a nil map writable storage.

## Collections and ownership

| Source family | API contract to preserve |
|---|---|
| Swap/pointer/default helpers | Pointer aliasing and nil/default meaning; avoid wrappers around trivial syntax |
| Map/filter/reduce | Whether outputs allocate, nil versus empty policy, callback order/errors; reduce needs an initial value |
| GroupBy/key selection | Key equality, per-group input order, no global map iteration order; output elements are shallow copies |
| Stack/queue | Empty returns zero plus false; clear removed slots so backing arrays do not retain references |
| Set union/intersection/difference | Allocate independent map storage; nested keys/values still obey their own ownership rules |
| Pair/zip/unzip | Define unequal-length behavior; the source zip truncates to shorter input, it does not report mismatch |
| Lazy | Prefer `sync.OnceValue`/`OnceValues`; cached failures are not retries, protect later mutable data separately |
| Cache/GetOrSet | Capacity/eviction and borrowed values; executing callbacks under a lock can block unrelated keys or deadlock on reentry |
| Binary search/heap/LRU | Ordering, NaN and positive capacity policy; synchronization is separate from generic type safety |

The source's pop/dequeue examples retain removed references in backing arrays;
[Stack.Pop](../examples/api.go) clears the slot before reslicing. Queue slicing
alone can retain an oversized backing array; a ring or compaction is a separate
representation choice. LRU `Get` mutates recency, so even reads need ownership or
synchronization. Algorithm implementations belong in the optional **go-algorithms**
skill; these local contracts do not require it.

## Standard library and version gates

Prefer `slices.Contains`, `slices.BinarySearch`, `slices.SortFunc`, `maps.Clone`,
`cmp.Compare` and built-in `min`/`max` over bespoke generic utility catalogues.
`cmp`, `slices`, `maps`, built-in min/max and sync Once helpers require Go 1.21;
`cmp.Or` arrived in 1.22. `maps.Keys`/`Values`, `slices.Collect` and range-over-function
iterators require 1.23; generic aliases require 1.24. Examples declare 1.25.0.

- Binary search requires sorting under the **same** order. A descending sort cannot
  precede the default ascending `slices.BinarySearch` as in the source sequence.
- Compare integers with `cmp.Compare(a, b)`, not `a-b`, which can overflow. `cmp`
  and `slices.Sort` define NaN ordering; raw `<` does not define the same total order.
- `slices.Min`/`Max` panic on empty input; define the boundary or use a bool/error.
- `Compact` removes adjacent duplicates, not all duplicates unless grouped first.
- Keep returned slices from `Delete`/`Insert`/`Compact`; their new length/storage
  is part of the result. In-place operations can mutate aliases.
- `maps.Clone` and `slices.Clone` are shallow; map iteration order is unspecified.
  Collect and sort keys when a stable display is part of the contract.

Correction authorities: [type parameters and type sets](https://go.dev/ref/spec#Type_parameter_declarations),
[constraint satisfaction](https://go.dev/ref/spec#Satisfying_a_type_constraint),
[type inference](https://go.dev/ref/spec#Type_inference),
[Go 1.21 inference](https://go.dev/doc/go1.21#language),
[cmp](https://pkg.go.dev/cmp), [slices](https://pkg.go.dev/slices),
[maps](https://pkg.go.dev/maps). Links are citations, not required downloads.
