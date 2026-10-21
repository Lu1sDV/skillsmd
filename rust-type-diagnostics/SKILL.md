---
name: rust-type-diagnostics
description: "Diagnoses advanced Rust type-system failures involving coercion sites, generic coercion barriers, function-item types, reference patterns, implied lifetime bounds, variance, Any downcasts, trait upcasting, and drop checking. Applies when ordinary ownership fixes do not explain an expected/found type mismatch or lifetime constraint. Complements rather than replaces everyday Rust, API design, concurrency, performance, and unsafe/FFI skills."
---

# Rust Type Diagnostics

Explain the rejected relationship before changing the program. Reconstruct actual
and expected types, identify the language rule, and make the smallest safe change
that preserves the intended ownership and API contract.

## Scope and routing

Use this skill for difficult type relationships, not as a general Rust tutorial.
Read only the reference matching the current failure.

| Symptom | Inspect | Reference |
|---|---|---|
| An annotation fixes a mismatch; a generic call rejects a coercible argument | Expected type, coercion site, inferred type parameter and exact trait impl | [Coercions and patterns](references/coercions-and-patterns.md) |
| Two functions have the same signature but different types | Function-item identity versus an expected function-pointer type | [Coercions and patterns](references/coercions-and-patterns.md) |
| A destructured binding has an unexpected reference layer; a method chain fails | Pattern binding mode, edition, intermediate type and next receiver | [Coercions and patterns](references/coercions-and-patterns.md) |
| A nested reference will not shorten; an outlives bound seems missing | Parameter position, variance, well-formedness and implied bounds | [Lifetimes and variance](references/lifetimes-and-variance.md) |
| A callback accepts static input but fails a general borrowed-input bound | Fixed lifetime versus higher-ranked quantification | [Lifetimes and variance](references/lifetimes-and-variance.md) |
| A downcast returns None or an erased value unexpectedly needs 'static | Exact erased type, wrapper/reference layers and the domain trait contract | [Type erasure](references/type-erasure.md) |
| A borrow remains live until destruction despite no later explicit use | Drop implementation, owning value and actual drop scope | [Drop checking](references/drop-checking.md) |

Existing skills retain their subjects. Use them when available; none is an
installation dependency:

- `rust-idiomatic`: everyday moves, borrows, reborrows, partial moves, lifetime
  basics, errors, combinators and ordinary tooling.
- `rust-api-design` / `rust-guidelines`: public API choices, builders, newtypes,
  dyn-compatibility checklists, coherence/orphan remedies and sealing.
- `rust-concurrency`: Send/Sync, task capture, locks, cancellation and shutdown.
- `rust-performance` / `rust-algorithms`: measured cost and algorithm selection.
- `rust-unsafe-ffi`: aliasing/provenance proofs, pinning implementations, manual
  destruction, unsafe traits and foreign unwind boundaries.
- `rust-macros`, `rust-tdd`, `rust-wasm`: their respective generation, test-first,
  and target/runtime workflows.

## Diagnostic workflow

1. **Establish the real context.** Read the failing expression, declaration and
   affected callers. Record the compiler, target, edition, features and declared
   MSRV. Use the supplied compiler output as evidence; if no failure output exists,
   capture the smallest relevant check using the project's toolchain. Do not
   upgrade Rust or change editions merely to make an example compile.
2. **Write the relationship down.** For each relevant expression, record its
   actual type, expected type, inferred generic arguments, available bounds and
   owner. Distinguish binding mutability from reference mutability. For a chain,
   inspect every intermediate return type and the next method's receiver.
3. **Identify the missing rule.** Select the reference above. Separate pattern
   binding, subtyping, coercion, method receiver adjustment and trait-impl lookup;
   they are not interchangeable. Reduce unrelated behavior without deleting the
   bound or later use that causes the real failure.
4. **Choose a contract-preserving fix.** Prefer a justified expected type,
   explicit reborrow, correctly related lifetime, existing trait operation, or
   shorter owner scope. Do not invent a new trait impl or broaden an API just to
   silence a diagnostic. If the correct change depends on whether the caller may
   retain, mutate or own data, ask about that contract—not facts in the repository.
   Track separate failures and their verification for multi-file work.
5. **Prove the relevant boundary.** Check the original caller with the fix and
   exercise its observable behavior. For a language-rule example, retain a minimal
   accepted example and, where informative, a rejection isolating the forbidden
   relationship. A rejection caused by syntax/import errors proves nothing about
   variance or borrowing. Do not pin compiler prose; inspect the diagnostic's cause.
   If the required toolchain or target cannot run, report that limit explicitly.

## Gotchas and guardrails

- Never use lifetime transmute, raw-pointer casts, leaks, blanket 'static bounds,
  clone/boxing, or nightly drop-check escapes as reflexive compiler fixes. A clone
  or ownership change is valid only when independent ownership is the contract.
- A last borrow use is not necessarily the owner's destruction point. Conversely,
  changing reference annotations cannot extend the lifetime of the owner.
- Shared traits do not make unrelated concrete types subtypes. Coercion does not
  automatically happen through arbitrary generic containers or trait bounds.
- Never present a runtime observation as a language/library guarantee. In
  particular, `Vec` element destruction order is not guaranteed.
- Safe examples compiling does not establish soundness of an unsafe abstraction.
  Hand off unsafe obligations rather than weakening them.
- Rust 2024 pattern/drop-scope changes and Rust 1.86 trait upcasting are explicit
  version boundaries in the references. Respect the project's edition and MSRV.
- Treat the source book as topic material, not an oracle. Use corrected, original
  examples; do not paste broken PDF listings or bundle the full book.

## Result format

Keep the answer proportional to the problem:

- **Cause:** expression, actual/expected types, and the violated rule.
- **Fix:** minimal change and the ownership/API behavior it preserves.
- **Check:** executed command/scenario, compiler/edition, result and any limit.

Do not claim completion when the original caller remains unchecked or a required
validation was skipped. The references contain executable Rustdoc examples:
`rustdoc --test --edition=2024 references/<topic>.md` from this skill directory.
Run the relevant file after changing its examples; use the repository's actual
configuration when diagnosing application code.

## Sources and maintenance

[Sources, chapter boundaries and corrections](references/sources.md) records how
*Advanced Rust* informed this skill, which material was deliberately excluded,
and which primary references supersede misleading claims. It also records the
exercised validation; it is not an MSRV or unsafe-soundness certification.
