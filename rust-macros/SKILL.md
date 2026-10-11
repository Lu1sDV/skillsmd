---
name: rust-macros
description: >
  Use when writing or debugging Rust macro_rules! matchers, repetitions, hygiene,
  $crate exports, edition-dependent fragments, or procedural derive, attribute,
  and function-like macros using syn and quote; includes expansion and diagnostic tests.
---

# Rust Macros

## Quick reference

| Task or symptom | Action | Load |
|---|---|---|
| Ordinary reusable logic | Use a function; generics for type abstraction | Optional rust-idiomatic or rust-api-design skill |
| Variable syntax, repeated declarations | Start with `macro_rules!` and an explicit grammar | [Declarative macros](references/declarative.md) |
| `local ambiguity`, invalid fragment follower | Add a delimiter/tag; inspect fragment follow sets | [Declarative macros](references/declarative.md) |
| Works locally, fails downstream | Inspect `$crate`, helper visibility, imports, renamed dependencies | [Declarative macros](references/declarative.md) |
| Derive, item transformation, parsed DSL | Separate proc-macro crate; parse → validate → generate | [Procedural macros](references/procedural.md) |
| Wrong bound or inscrutable derive error | Preserve generics; field-specific bounds and input spans | [Procedural macros](references/procedural.md) |
| Suspected bad expansion | Compile smallest caller, inspect expansion, test semantics | [Testing and traps](references/testing.md) |
| Edition migration changes matching | Check definition crate's edition, `expr_2021`, `pat_param` | [Declarative macros](references/declarative.md) |

## Scope and defaults

Macros are syntax APIs, not a general substitute for functions. Choose one only
when callers need syntax a function cannot accept or genuinely repetitive item
generation. A macro expands before type checking its generated code; expansion
itself does not know inferred types. Generated code can allocate, panic, move
values, or be expensive. No blanket runtime or build-time speed claim follows.

Read the project's edition, `rust-version`, toolchain and dependency versions
before choosing syntax. Examples here target edition 2024 (Rust 1.85 minimum);
this is not permission to raise a consumer's MSRV. Proc-macro dependencies and
optional debugging tools have their own MSRV constraints.

## Workflow

1. **Write the equivalent ordinary Rust.** Identify exactly which syntax must
   vary. Keep runtime logic in normal functions rather than cloning it into
   every expansion.
2. **Specify the public contract.** List accepted forms, empty input, trailing
   comma policy, duplicate handling, evaluation count/order, ownership, and the
   output position: expression, item, type, or pattern.
3. **Choose the least powerful mechanism.** `macro_rules!` for grammar matching
   and repetition; derive to append implementations; attribute to transform an
   item; function-like proc macro for syntax requiring a real parser.
4. **Make parsing unambiguous.** Specific rules precede catch-alls. Delimit
   repeated groups explicitly. Reject unsupported input rather than silently
   ignoring tokens or attributes.
5. **Protect caller context.** Use `$crate` for declarative helpers and qualified
   library paths. Proc macros need explicit path/name handling. Never assume a
   trait, `Vec`, or a helper is imported by the caller.
6. **Preserve semantics.** Evaluate an expression once unless repetition is
   documented; preserve moves, borrows, early returns, `?`, attributes, and
   generics. An expression expansion's final value must not gain a semicolon.
7. **Make failures useful.** For declarative grammar errors use a specific
   fallback `compile_error!` when useful. For proc macros return spanned
   `syn::Error`, not a panic caused by malformed user input.
8. **Test the caller, not just token text.** Include behavior assertions,
   intentional compile failures, downstream imports and edition-sensitive forms.
   Consult [testing](references/testing.md) for the matrix and tools.

## A small, executable syntax contract

This macro is deliberately a non-empty list, permits a trailing comma, evaluates
each argument once from left to right, and uses no heap allocation. Empty input
is not silently assigned an arbitrary element type. The normal array syntax
would suffice in production; this is a grammar/evaluation test, not a reason to
introduce an array wrapper API.

```rust
macro_rules! nonempty_array {
    ($first:expr $(, $rest:expr)* $(,)?) => {
        [$first $(, $rest)*]
    };
}

let mut visits = 0;
let values = nonempty_array!(
    { visits += 1; visits },
    { visits += 1; visits },
);
assert_eq!(values, [1, 2]);
assert_eq!(visits, 2);
assert_eq!(nonempty_array!(7), [7]);
```

The empty invocation intentionally fails because no first expression exists:

```rust,compile_fail
macro_rules! nonempty_array {
    ($first:expr $(, $rest:expr)* $(,)?) => {
        [$first $(, $rest)*]
    };
}
let _ = nonempty_array!();
```

## Pitfalls to check before expanding the design

- **Matching is not overload resolution.** First matching arm wins. If its
  expansion fails type checking, later arms are not tried.
- **Fragments are not textual substitution.** An `expr` preserves expression
  grouping and becomes opaque when forwarded; `tt` preserves token structure.
- **Hygiene is mixed-site for `macro_rules!`.** Locals/labels and item names do
  not all resolve alike. Exporting a macro does not export its private helpers.
- **Repetition has structure.** Match and transcribe variables at compatible
  nesting; zipped repetitions require equal lengths. Avoid recursive token-tree
  munchers when an ordinary repetition expresses the grammar.
- **Edition belongs to the definition.** A 2024 caller does not upgrade a macro
  defined in a 2021 dependency.
- **Derive appends, attribute replaces.** Returning the input from a derive
  duplicates the original type. Failing to return an attribute's original or
  transformed item deletes it.
- **Strings are not identifiers.** `quote!` interpolates a Rust string as a
  literal; use parsed `Ident` or `format_ident!` for generated names.
- **Compile-time execution is not sandboxing.** Procedural dependencies execute
  with compiler access to files/environment; review them like build scripts.
- **Expansion output is lossy.** `cargo expand` is a debugging aid, not a source
  replacement or evidence of hygiene/behavior equivalence.

## Completion criteria

- Accepted syntax and intentional rejections are documented with real callers.
- Repetition boundaries, evaluation count, hygiene, and generics have evidence.
- Public macros work outside the defining module/crate with intended imports;
  helper paths remain valid when the crate is renamed by Cargo.
- Diagnostics point to offending input, not only generated code.
- Required features, supported editions, and MSRV are explicit; optional tools
  are not assumed installed.
- Report executed checks separately from suggested checks; never claim a token
  snapshot proves the generated program works.

## Handoffs and sources

If installed, use **rust-tdd** for red–green–refactor and test-suite design,
**rust-api-design** for generated public contracts, **rust-idiomatic** for normal
traits/const/Cargo semantics, and **rust-performance** for measured expansion,
build-time or runtime costs. These are optional, not installation dependencies.

This skill adapts StructWeave chapters 14 and the macro/compile-time section of
13. Pinned upstream links, first-party references, and correction notes appear
in [README](README.md) and each reference. Read only the reference needed for
the current task.
