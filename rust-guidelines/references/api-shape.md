# API shape

## Names and signatures

Use Rust casing: `UpperCamelCase` types/traits/variants, `snake_case` functions and
modules, `SCREAMING_SNAKE_CASE` constants. Keep word order consistent. Prefer
`field()` / `field_mut()` over `get_field()`; homogeneous collection traversal uses
`iter`, `iter_mut`, `into_iter` with corresponding named iterator types.

Use `as_*` for a cheap borrowed view, `to_*` for conversion work without consuming
a non-Copy receiver, and `into_*` for consumption. `to_*` need not allocate;
`into_*` need not be cheap. Put conversions on the more specific type.

Use inherent constructors (`new`, `with_*`) and methods for natural receivers.
Borrow views (`&str`, `&[T]`) when ownership is unnecessary; take ownership when
storing or consuming. Small Copy values can travel by value. Let callers choose
copying and storage; expose useful intermediate results instead of repeating work.
Use only meaningful generic bounds; preserve dyn compatibility when trait objects
are an intended use case.

## Types and ergonomics

Use newtypes for distinct units/identities, enums for alternatives, and a flags
representation for combinable options. Keep genuine optionality as `Option`;
replace ambiguous boolean arguments with domain types. Builders suit complex
configuration; typestate must eliminate a real invalid transition, not merely add
ceremony.

Return values, tuples, or structs normally. Mutable output buffers are appropriate
for deliberate storage reuse or bounded output, not as a universal optimization.
Keep operators unsurprising. Reserve `Deref` for pointer-like behavior; smart-pointer
operations should avoid shadowing the pointee's methods.

## Evolution

Keep representation private, including implementation containers. Avoid unnecessary
bounds on type definitions. Seal traits only when downstream implementations are
intentionally prohibited. Treat public variants, trait implementations, bounds,
and ownership changes as compatibility decisions, not cosmetic refactors.

Basis: API Guidelines [naming](https://rust-lang.github.io/api-guidelines/naming.html),
[predictability](https://rust-lang.github.io/api-guidelines/predictability.html),
[flexibility](https://rust-lang.github.io/api-guidelines/flexibility.html),
[type safety](https://rust-lang.github.io/api-guidelines/type-safety.html), and
[future proofing](https://rust-lang.github.io/api-guidelines/future-proofing.html).
