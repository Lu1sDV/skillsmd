---
name: rust-api-design
description: >
  Use when designing or reviewing Rust public APIs, trait boundaries, builders,
  newtypes, typestate transitions, enum versus dyn dispatch, or applying SOLID
  and creational, structural, or behavioral design patterns without class hierarchies.
  Triggers include dyn compatibility, dependency injection, API evolution,
  adapters, decorators, factories, visitors, and ownership-aware interfaces.
---

# Rust API Design

Choose functions, concrete types, enums, and composition before introducing an
abstraction. A pattern earns its place by enforcing an invariant or isolating an
actual variation point, not by completing a pattern checklist.

## Quick reference: route by decision

| Decision | Default | Read |
|---|---|---|
| Function, trait, generic, or trait object? | Concrete function until variability is real | [API contracts](references/api-contracts.md) |
| Ownership, errors, lifetimes, public compatibility | Express caller obligations in the signature | [API contracts](references/api-contracts.md) |
| Constructor, builder, factory, abstract factory | Associated constructor with required arguments | [Creation](references/creational.md) |
| Singleton or prototype | Pass configuration; use `Clone` deliberately | [Creation](references/creational.md) |
| Adapter, decorator, facade, composite | Newtype, std trait, module, or enum | [Composition](references/structural.md) |
| Proxy, flyweight, bridge | Explicit methods, scoped sharing, independent axes | [Composition](references/structural.md) |
| Strategy, observer, state, command | Function/closure, callback, enum, owned command | [Behavior](references/behavioral.md) |
| Iterator, chain, visitor, typestate, RAII | Std iterator, control flow, traversal, ownership | [Behavior](references/behavioral.md) |

Load only the reference needed for the current task. The references cover all
assigned pattern families; their tables are selection guides, not mandates.

## Workflow

1. **Read the call sites.** Identify who constructs, owns, mutates, and destroys
   the value. Find the actual invalid inputs, extension points, and error paths.
   Record the project's MSRV, edition, supported targets, and dependency policy.
2. **Write the contract before the wrapper.** Specify valid inputs, units,
   output ownership, missing versus failed lookup, mutation on error, ordering,
   partial success, and any blocking behavior. Do not turn infrastructure failure
   into `None` or return success after merely printing an operation.
3. **Choose the smallest representation.** Use an enum for a closed domain; a
   trait for external implementations or a meaningful test boundary; a closure
   for one injected operation. Keep invariant-bearing fields private.
4. **Choose dispatch and ownership independently.** Generics preserve concrete
   types; `&dyn Trait` erases type without owning it; `Box<dyn Trait>` owns an
   erased value. Runtime selection does not automatically require a trait object.
5. **Implement one real caller end to end.** Reuse `Read`, `Write`, `Iterator`,
   `From`/`TryFrom`, and existing crate capabilities. Avoid a custom DI container,
   abstract factory, or service registry when arguments suffice.
6. **Exercise the contract.** Add a successful caller and a boundary/error case.
   For typestate, add a compile-fail case for the forbidden operation; also test
   runtime validation. For interchangeable implementations, share behavioral
   contract tests rather than testing only method signatures.
7. **Review compatibility and documentation.** Update affected callers, examples,
   errors, and release notes. Describe changed lifetimes, trait bounds, auto
   traits, public enum variants, and partial-failure semantics explicitly.

## SOLID, translated rather than transplanted

| Principle | Useful Rust question | Avoid |
|---|---|---|
| Single responsibility | Do these operations protect the same invariant or change together? | A struct per function; arbitrary method/line-count limits |
| Open/closed | Who must add new implementations without editing this crate? | Replacing a naturally closed enum with a plugin registry |
| Liskov substitution | Does every implementation honor errors, ordering, units, and side effects? | Assuming trait checking proves behavioral correctness |
| Interface segregation | What capability does this caller actually require? | One giant repository trait, or dozens of meaningless one-method traits |
| Dependency inversion | Can the caller pass the resource or policy it needs? | Hidden global connections or a DI framework for ordinary arguments |

An orchestration function may coordinate validation, persistence, and notification.
Splitting functions does not make those operations atomic: specify what happens
if persistence succeeds and notification fails before rearranging abstractions.

## A small invariant-bearing API

This type distinguishes a valid nonempty byte interval from two unrelated
integers. Construction validates once; borrowed access adds no allocation. The
remaining slice bound is checked at the call boundary.

```rust
mod ranges {
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub struct ByteRange {
        start: usize,
        end: usize,
    }

    impl ByteRange {
        pub fn new(start: usize, end: usize) -> Option<Self> {
            (start < end).then_some(Self { start, end })
        }

        pub fn get<'a>(self, bytes: &'a [u8]) -> Option<&'a [u8]> {
            bytes.get(self.start..self.end)
        }
    }
}

use ranges::ByteRange;
assert!(ByteRange::new(2, 2).is_none());
assert!(ByteRange::new(3, 1).is_none());
let range = ByteRange::new(1, 3).expect("nonempty range");
assert_eq!(range.get(b"rust"), Some(&b"us"[..]));
assert_eq!(range.get(b"r"), None);
```

Do not copy this byte API onto `str`: text slicing must also respect UTF-8
boundaries. Choose a richer error enum when callers need to distinguish failures.

## Review traps

- **“Accept borrowed, return owned” is not a law.** Return a borrow for a view;
  take ownership when storing a value; use `Cow` only for genuinely mixed cases.
- **Neither `clone` nor `unwrap` is universally wrong.** Clone for an independent
  value or explicit shared handle; `expect` can document a proven invariant.
  User input, I/O, and expected operational failures need a recoverable policy.
- **Typestate is not validation.** `HasUrl` proves a method was called, not that
  its string is a valid URL or that a remote peer accepted credentials.
- **`Deref` is not inheritance or authorization.** Exposing the inner API may
  bypass a wrapper's invariant; use explicit forwarding for controlled access.
- **`dyn` is not synonymous with allocation.** Borrowed trait objects need no box.
  Generic versus erased dispatch costs depend on the workload and optimizer.
- **`'static` does not mean immortal.** Owned values can satisfy it and still be
  dropped immediately. Do not add it merely to silence a borrowing error.
- **RAII does not make a fallible commit succeed.** Provide explicit fallible
  finalization; use `Drop` for nonpanicking fallback cleanup, not a hidden commit.
- **An ignored `Result` is a policy decision.** Specify the accepted loss and
  observability; do not discard errors just to keep a facade convenient.

## Completion criteria

- The API has an actual caller and a documented ownership/error contract.
- Each trait or generic parameter has a concrete reason; no speculative layers.
- Validation cannot be bypassed through public fields, conversions, or wrappers.
- Pattern examples do real work and check at least one invariant or boundary.
- All implementations preserve the promised behavior, including failure cases.
- The project's edition/MSRV and public compatibility requirements remain valid.
- Verification results distinguish executed checks from proposed checks.

## Handoffs and sources

If installed, use **rust-idiomatic** for borrow-checker mechanics and error
implementation, **rust-tdd** for red-green-refactor and contract-test design,
**rust-concurrency** for channels, cancellation, locks, and async traits,
**rust-unsafe-ffi** for unsafe boundary proofs, and **rust-performance** for
measured dispatch, allocation, interning, and layout costs.

The runnable examples are dependency-free and target edition 2024 (Rust 1.85+);
select the consumer project's actual edition/MSRV rather than upgrading it by
habit. Source attribution and adaptation decisions are in [README](README.md).
