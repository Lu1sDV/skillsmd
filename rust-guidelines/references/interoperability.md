# Interoperability

Implement applicable standard traits, not every possible derive. Consider `Debug`,
`Clone`, `Copy`, equality, ordering, hashing, `Display`, and `Default`; preserve
consistent equality/order/hash semantics. A useful no-argument `new()` should agree
with `Default`. Provide numeric formatting traits for numeric domain types.

Implement `From` / `TryFrom` rather than hand-writing their `Into` / `TryInto`
counterparts; use `AsRef` / `AsMut` for appropriate borrowed conversions.
Collection APIs should integrate with `IntoIterator`, `FromIterator`, and `Extend`
where their semantics fit. For bounded containers, do not force an infallible
trait to hide capacity failure or discard entries; expose a fallible operation.

Prefer standard I/O traits. A generic `R: Read` or `W: Write` parameter taken by
value can also accept a mutable reference; it does not necessarily take ownership
of the underlying resource.

Library errors should expose meaningful typed information and implement `Debug`,
`Display`, and the appropriate `Error` trait, preserving useful `source()` chains.
Do not infer runtime allocation from an error derive such as `thiserror`: check
its implementation, selected features, and MSRV for the target environment.

Preserve `Send` / `Sync` where semantically valid; never add unsafe implementations
just to satisfy a bound. Assert promised traits in compile-time tests.

Consider optional `serde` support for transferable data. Keep feature names direct
(`serde`, `std`), additive, and meaningful. Integrations remain subject to the
project's dependency, validation, and resource contracts; no automatic additions.

Basis: API Guidelines [interoperability](https://rust-lang.github.io/api-guidelines/interoperability.html)
and [feature naming](https://rust-lang.github.io/api-guidelines/naming.html#c-feature).
Capacity and derive guidance are adaptation decisions, not mandatory dependencies.
