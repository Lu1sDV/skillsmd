# Language semantics

## Contents

- [Declarations and types](#declarations-and-types)
- [Control flow and capture](#control-flow-and-capture)
- [Functions, methods and embedding](#functions-methods-and-embedding)
- [Nil, assertions and equality](#nil-assertions-and-equality)

## Declarations and types

Inside functions, `:=` declares at least one new non-blank name in the current
block; existing names in that same block are reassigned. In a nested block they
are new names. At package scope use `var`, `const`, `type` and function declarations.
A declaration without an initializer gets its type's zero value: numeric zero,
false, empty string, nil pointer/slice/map/channel/function/interface; structs and
arrays recursively get zero-valued elements. `make` initializes slices/maps/channels;
`new(T)` returns `*T` pointing to a zero value, not an initialized map.

`int`/`uint` widths are architecture-dependent; use explicitly sized integers at
binary/storage boundaries. `byte = uint8`, `rune = int32`, and `any = interface{}`
are aliases. `type ID int64` defines a distinct type; `type ID = int64` does not.
Conversions between defined numeric types are explicit and do not validate range.
Untyped constants are representable with arbitrary precision until context gives
them a type; an unrepresentable constant conversion is a compile-time error.

Arrays include length in their type and copy elements on assignment. Structs copy
all fields, but copied slice/map/pointer fields still share referenced storage.
Pointers are values too: assigning `p` copies its address, dereferencing nil panics,
and ordinary Go provides no pointer arithmetic. Taking an address does not itself
prove a heap allocation; escape analysis determines placement.

## Control flow and capture

Use `if init; condition` for narrow lifetimes and early error returns. `for` covers
three-clause, condition-only, infinite and `range` loops; use index iteration when
mutating slice elements (`for i := range xs { xs[i]++ }`). Range values are copies,
not references to source elements. Arrays used as range expressions can be copied;
use a slice or pointer-to-array when that distinction matters.

An expression switch checks cases in order and does not implicitly fall through.
`fallthrough` executes the next case without checking its expression; it is forbidden
in type switches. `break` exits the innermost loop/switch/select, `continue` advances
the loop; labels target an enclosing loop (or breakable switch/select). Channels,
blocking `select`, producer ownership and function iterators belong to concurrency
and algorithms; never substitute sleep for completion.

### The version-sensitive loop rule

For packages using **Go 1.22 language semantics or later**, variables **declared**
by `for i := ...` or `for _, v := range ...` are distinct per iteration. In a
three-clause loop each next iteration starts with a new variable initialized from
the previous one before the post statement. The package language version normally
comes from the module's `go` directive (version-specific build constraints can also
affect a file); merely upgrading the installed compiler is not the migration.

Assignment forms `for i = ...` and `for _, v = range ...` reuse existing variables
at every version. Closures capture variables, not snapshots. The complete runnable
[Capture example](../examples/semantics.go) distinguishes declaration `[1 2 3]`
from assignment `[3 3 3]` without goroutine scheduling or data races. For older
language versions, declare a fresh body-local variable or pass the value as an
argument. Fresh variables do not make shared pointed-to data race-free.

Integer range starts at zero and ends before the positive bound (Go 1.22+);
range over iterator functions needs Go 1.23+. Do not backport syntax silently.

## Functions, methods and embedding

Functions support multiple results, variadic final parameters (`xs...` expands a
slice), closures and named results. A variadic slice can alias its caller's slice.
Name results for genuine documentation or deferred cleanup, not long naked-return
control flow. Validate empty input before `xs[0]` and zero divisors before integer
division. Function values can be nil and can only be compared to nil.

A value receiver receives a shallow copy. Use pointer receivers to change the
receiver's fields, preserve identity, or avoid copying non-copyable state; do not
choose pointers from an arbitrary byte-size threshold. A value receiver can still
mutate elements of a slice field. Use consistent receivers when identity matters.
An addressable `v` permits automatic `(&v).Method()` syntax, but this does not add
pointer methods to `T`'s method set or make map elements addressable. `T` has value
receiver methods; `*T` has both value and pointer receiver methods (for ordinary
non-interface defined types). A nil pointer receiver is callable only if the method
handles nil; invoking a promoted method or dereferencing fields may still panic.

Embedding promotes accessible fields/methods; it is composition, not subclassing
or virtual dispatch. **An exported member promoted through an unexported embedded
type can be accessible from another package** if unambiguous. The embedded field's
own unexported name is inaccessible there. Selectors and composite-literal keys
have different rules: promoted fields cannot be keys of an outer struct literal.
Method-set contracts and deliberate composition route to **go-api-design**.

## Nil, assertions and equality

A nil interface has neither dynamic type nor value. An interface containing a nil
`*T` has a dynamic type and is non-nil; return plain `nil` on success from an `error`
function. Avoid universal reflection-based nil detection as a substitute for a clear
contract. If reflection is actually needed, call `IsNil` only on supported kinds.

`v, ok := x.(T)` safely reports a failed assertion, including a nil interface.
`x.(T)` panics on failure; concrete assertions require the exact dynamic type,
interface assertions require that it implements the target interface. In a type
switch a single concrete case narrows the variable; a multi-type, nil or default
case retains the original interface type. Prefer a typed boundary over repeated
assertions; generic design is not automatically the best replacement.

Numbers, booleans, strings, pointers and channels are comparable; arrays/structs
are comparable when their elements/fields are. Slices/maps/functions compare only
to nil. Compare contents using `slices.Equal`, `maps.Equal`, or domain-specific
logic; nested slices need nested comparison. `reflect.DeepEqual` has its own nil,
NaN and identity semantics and is not a universal equality policy.

Interface equality first compares dynamic types. Equal dynamic types whose values
are not comparable can panic (`any([]int{1}) == any([]int{1})`); differing dynamic
types compare false. Even a comparable struct can contain interface fields that
trigger this panic. A generic `comparable` API may admit interface types under
Go 1.20+ rules; its dynamic contents still matter. NaN is unequal to itself: use
`math.IsNaN`; pointers compare identity rather than pointed-to content.
