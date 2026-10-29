# Interoperability

Implement applicable standard traits, not every possible derive. Consider `Debug`,
`Clone`, `Copy`, equality, ordering, hashing, `Display`, and `Default`; preserve
consistent equality/order/hash semantics. A useful no-argument `new()` should agree
with `Default`. Provide numeric formatting traits for numeric domain types.

Implement `From` / `TryFrom` rather than hand-writing their `Into` / `TryInto`
counterparts; use `AsRef` / `AsMut` for appropriate borrowed conversions.
`Borrow<Q>` additionally requires matching equality, ordering, and hashing for
owned and borrowed forms. A case-insensitive key must not implement `Borrow<str>`
when those semantics differ from `str`; use `AsRef<str>` for a view instead.
See the [`Borrow` contract](https://doc.rust-lang.org/std/borrow/trait.Borrow.html).

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

When Serde is already used, treat field names, enum tags, defaults, and unknown
fields as wire contracts. Do not let derived `Deserialize` bypass domain
validation: decode a raw representation and reuse `TryFrom`, for example through
`#[serde(try_from = "Raw")]`. Test legacy payloads and emitted representations,
not only current round trips. Test missing input and explicit `null` separately:
`default` fills missing input; `skip_serializing_if` only changes output.
Choose unknown-field rejection deliberately; `deny_unknown_fields` cannot be
combined with `flatten`. Untagged enums select the first variant that successfully
deserializes, so overlapping shapes or reordered variants can change meaning.
Sources: [container attributes](https://serde.rs/container-attrs.html),
[field attributes](https://serde.rs/field-attrs.html),
[enum representations](https://serde.rs/enum-representations.html).

Basis: API Guidelines [interoperability](https://rust-lang.github.io/api-guidelines/interoperability.html)
and [feature naming](https://rust-lang.github.io/api-guidelines/naming.html#c-feature).
Capacity and derive guidance are adaptation decisions, not mandatory dependencies.
