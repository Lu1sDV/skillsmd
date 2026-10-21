# rust-type-diagnostics

Focused diagnosis of advanced Rust type relationships, complementing the
existing Rust skills rather than adding another general language guide.
[SKILL.md](SKILL.md) routes by symptom to four independently readable references:

- [Coercions and patterns](references/coercions-and-patterns.md): expected types,
  generic coercion barriers, function items, reference patterns and receivers.
- [Lifetimes and variance](references/lifetimes-and-variance.md): implied bounds,
  nested lifetime positions and higher-ranked callback requirements.
- [Type erasure](references/type-erasure.md): exact `Any` identity, wrapper layers
  and version-qualified trait upcasting.
- [Drop checking](references/drop-checking.md): destructor borrow obligations,
  safe owner scopes and guaranteed versus observed destruction order.

Everyday ownership and errors remain with `rust-idiomatic`; public API decisions
with `rust-api-design`; unsafe obligations with `rust-unsafe-ffi`. Other skills
are optional handoffs, not installation dependencies.

## Install and use

Copy the complete `rust-type-diagnostics/` directory into your agent's skills
directory. For Claude Code, from this repository checkout, first ensure that no
existing local copy would be overwritten:

```sh
mkdir -p ~/.claude/skills
cp -r rust-type-diagnostics ~/.claude/skills/
```

Example requests:

- “Use rust-type-diagnostics to explain why this generic call rejects `&String`
  even though the concrete function accepts `&str`.”
- “Trace which lifetime position prevents this mutable container conversion.”
- “Explain why this `Any` downcast fails without changing our domain API.”

## Sources and validation

Derived from a complete chapter-by-chapter review of Nouman Azam's *Advanced
Rust*, with original examples and corrections grounded in primary Rust
references. The book is not bundled or required at runtime. See the
[source map and validation record](references/sources.md) for chapter boundaries,
corrections, version assumptions and exercised checks.

From this skill directory:

```sh
rustdoc --test --edition=2024 references/coercions-and-patterns.md
rustdoc --test --edition=2024 references/lifetimes-and-variance.md
rustdoc --test --edition=2024 references/type-erasure.md
rustdoc --test --edition=2024 references/drop-checking.md
```

The 34 Rustdoc checks comprise 22 executable examples and 12 intentional compile
failures. They were validated on Rust 1.99.0, edition 2024; this is not an MSRV
certification. The skill requires respecting each consumer project's compiler,
edition and API contract rather than upgrading them to silence diagnostics.
