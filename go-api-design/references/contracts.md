# Consumer contracts and SOLID tradeoffs

## Contents

- [Define behavior before interfaces](#define-behavior-before-interfaces)
- [Method sets, embedding and nil](#method-sets-embedding-and-nil)
- [SOLID as review questions](#solid-as-review-questions)
- [Composition and failure boundaries](#composition-and-failure-boundaries)

## Define behavior before interfaces

A Go interface expresses a method set, not units, durability, concurrency safety,
error policy or resource ownership. Write those in documentation and behavioral
checks. Accept an existing stdlib interface when its actual contract fits. Define
new interfaces near their consumer, using the minimum coherent capability the
consumer needs; do not count methods or manufacture a mock boundary for every type.
A function argument can be a sufficient boundary for one operation.

An API review should answer:

| Concern | Required decision |
|---|---|
| Inputs | Units, encoding, validation, maximum sizes, nil/empty and zero values |
| Results | Missing versus unavailable, ordering, stable identity, owned versus borrowed data |
| Failure | Errors and wrapping, partial success, whether state changes before failure |
| Lifetime | Who creates/closes resources, callback lifetime, cancellation and blocking |
| Concurrency | Which calls may overlap, synchronization, whether returned data aliases state |
| Evolution | Adding interface methods breaks implementers; widening accepted inputs can still change behavior |

Prefer concrete return types when consumers benefit from the named API/zero value.
Returning an interface is appropriate for runtime-selected implementations or a
purposefully hidden representation. An exported constructor returning an unexported
concrete type is legal: callers can infer its type, store the result and call
exported methods. They cannot spell that concrete type in their own signatures;
that limitation may hurt public composition, but it is not “unusable.” No blanket
ban on either form is justified.

Representative complete consumer function (also in [api.go](../examples/api.go)):

```go
func WriteMessage(w io.Writer, message string) error {
    _, err := io.WriteString(w, message)
    return err
}
```

This declaration requires `import "io"` in its containing file. It does not close
`w`; the caller owns it. A conforming `Writer` must return a non-nil error on a
short write. The executable exporter checks `(n, err)` too and reports
`io.ErrShortWrite` for a faulty writer. `Reader.Read` may return both `n > 0` and
an error; consume bytes before handling the error. Method compatibility cannot
prove these behaviors. Do not automatically close a reader merely because an
optional assertion reveals `io.Closer`: ownership must grant permission to close.

## Method sets, embedding and nil

For a defined non-pointer type `T`, the method set contains methods with receiver
`T`. `*T` contains both `T` and `*T` receiver methods. Calling `value.M()` on an
addressable variable can implicitly take its address; assigning that value to an
interface does **not** expand its method set. Map elements are not addressable.
Use a compile-time assertion when documenting an intended implementation:
`var _ io.Writer = (*MyWriter)(nil)` (a declaration fragment, not a nil runtime writer).
Method signatures must match exactly; Go has no covariant return types.

Value receivers copy the struct, but slices/maps/pointers inside still alias.
Use pointers for identity/mutation or synchronization-bearing types; never copy
used mutexes, Once, Pool, or other non-copyable sync values. A nil `*T` receiver
can execute a pointer method if the method handles nil. A promoted value method
invoked through a nil pointer can panic before its body; nil tolerance is not an
automatic property of interface dispatch.

Embedding promotes fields/methods; it is not inheritance, subtyping or virtual
method override. Calls made inside the embedded value still target its own methods.
A method declared on the outer type shadows a promoted name only at outer selection.
Ambiguous promotions are not resolved by arbitrary priority. Embedding `T` promotes
its value methods to outer values and pointer methods to outer pointers; embedding
`*T` can promote both to each, but leaves nil-embedded-pointer hazards.

The source's trap Q41 is incorrect: an **exported** member of an unexported embedded
type can be promoted and accessible from another package (`outer.Val`). The
unexported embedded field itself cannot be named by that external consumer or
initialized by name in a composite literal. Avoid accidental API exposure through
embedding; a named private field plus forwarding methods is more deliberate.

An interface is nil only when it has no dynamic type or value:

```go
// Complete declaration; no imports required.
type Failure struct{}
func (*Failure) Error() string { return "failed" }

func Success() error {
    return nil // Not: var failure *Failure; return failure
}
```

`var failure *Failure; var err error = failure` makes `err != nil`, even though
`failure == nil`. Return literal nil on success; state explicitly whether typed
nil dependencies are forbidden. `w == nil` detects a nil interface, not every nil
concrete implementation. Prefer producer correctness or a known concrete check
over reflecting through every caller. A legitimately nil-tolerant receiver may
be meaningful, so reflection-based universal rejection can change the contract.

At dynamic boundaries use `value, ok := x.(Concrete)` or an interface assertion for
an optional capability. Asserting a typed nil to its concrete pointer succeeds
and returns nil; asserting a nil interface fails. Type switches have no
`fallthrough`; a multi-type case keeps the original interface type for its bound
variable, unlike a single concrete-type case. For wrapped errors use
`errors.Is`/`As`; a direct assertion only sees the outer error. Temporary-looking
errors alone do not justify retries of non-idempotent effects.

## SOLID as review questions

| Principle | Useful Go decision | Avoid turning it into |
|---|---|---|
| SRP | Cohesive package/type/function; separate reasons that actually change independently | One package per helper, method/line-count limits or a layer for every verb |
| OCP | Function parameters, middleware and interfaces at real extension points | A registry for a small closed enum, or refusal to edit ordinary code |
| LSP | All implementations satisfy documented pre/postconditions, invariants and allowed state histories | “It compiles, therefore interchangeable” |
| ISP | Consumer accepts only the capability it needs; compose small interfaces when needed | Interface fragmentation or a universal five-method maximum |
| DIP | Pass owned dependencies explicitly; keep domain policy independent of transport/storage detail when useful | A DI container, repository-per-table, or prohibition on direct `*sql.DB` use |

A useful interface may have one external implementation; a concrete dependency may
also be the right boundary. Manual constructor injection at the composition root
is usually enough. Do not reverse imports by making a driver depend on an entire
application service package if shared domain values or a smaller consumer contract
can avoid that coupling. Implicit implementation often needs no import of the
interface's package unless parameter/result types require it.

Substitutability applies to behavior: an implementation must not require extra
size/encoding assumptions or silently weaken durability guarantees. But a `Save`
method returning `error` does not by itself promise unlimited size or eternal
retrieval; document those guarantees. Chunking is not automatically a correct
substitute for an atomic Save: partial writes and representation can change.
A network cache must distinguish miss from backend failure if consumers need that
distinction; `(value, found)` may deliberately describe only a best-effort cache,
but should not accidentally turn outages into missing domain data. Prefer
`(value, found, error)` where the distinction is necessary.

## Composition and failure boundaries

Follow the source's useful orchestration idea without its pretend external APIs:
validate, execute a real dependency, propagate failure, then commit the next state.
Separating methods does not make a sequence of persistence, inventory and email
atomic. Decide transaction ownership, idempotency and partial-success reporting.
For reliable post-commit notifications use an appropriate durable mechanism such
as an outbox, not an unowned fire-and-forget goroutine borrowing a mutable order.
Do not silently discard notification failure unless the documented product policy
makes it best effort and supplies an accountable owner.

Explicit initialization keeps errors visible. Check the error before deferring a
close. If step two fails after step one opens a resource, release step one's
resource before returning. `sql.Open` constructs a pool and may not connect;
`PingContext` establishes readiness if required. `*sql.DB` already is a concurrent
connection pool; wrapping multiple DB pools in another “connection pool” is not a
shortcut to bounded database connections.

Use one real consumer test per interchangeable contract plus focused boundaries:
writer failure/short write, successful bytes before EOF, alias isolation, typed
nil and method-set intent. Tests with real stdlib buffers exercise actual local
behavior; they do not establish SQL driver, payment SDK, network or cross-process
compatibility. [Examples](../examples/examples_test.go) are stdlib-only and local.

Correction authorities: [method sets](https://go.dev/ref/spec#Method_sets),
[selectors and promotion](https://go.dev/ref/spec#Selectors),
[interface values](https://go.dev/doc/faq#nil_error),
[io contracts](https://pkg.go.dev/io), [database/sql](https://pkg.go.dev/database/sql).
These links are citations; all required guidance is above.
