# rust-api-design

A standalone Claude Code skill for ownership-aware Rust API design. It consolidates
SOLID, creational/structural/behavioral patterns, API anti-patterns, and relevant
trait/lifetime traps into decisions you can apply to actual callers.

## Install from a checkout

Run from the root of this repository:

```sh
mkdir -p ~/.claude/skills
cp -r rust-api-design ~/.claude/skills/
```

The entire directory is the bundle: keep `SKILL.md`, `references/`, and the source
license together. No other skill is required, and there are no external example
dependencies. Optional named handoffs work when those skills are installed.

## Example prompts

- “Review this Rust public API for unnecessary traits and ownership friction.”
- “Choose an enum, generic parameter, or borrowed trait object for these backends.”
- “Design a builder that validates option combinations without a typestate explosion.”
- “Adapt this foreign API while preserving partial failure and error semantics.”
- “Model this workflow with runtime state or typestate and preserve ownership on errors.”
- “Check this observer/undo/visitor design for reentrancy and invalid transitions.”

## Reference index

| File | Scope and concrete examples |
|---|---|
| [SKILL.md](SKILL.md) | Routing, workflow, SOLID decision questions, validated byte-range API |
| [API contracts](references/api-contracts.md) | Ownership, trait boundaries, dyn compatibility, evolution, corrected HRTB trap; fallible std writer and borrowed callback examples |
| [Creation](references/creational.md) | Constructor, builder, factory, abstract factory, singleton, prototype; cross-field builder validation and independent/shared clone example |
| [Composition](references/structural.md) | Adapter, decorator, facade, composite, proxy, flyweight, bridge; borrowed hex formatting and budgeted writer |
| [Behavior](references/behavioral.md) | Strategy, observer, state, command, iterator, chain, visitor, typestate, RAII, newtype; parser chain, validated publication, negative typestate check, UTF-8-safe insert/undo |

This skill focuses on design contracts, not compiler tutorials, concurrent runtime
implementation, unsafe proofs, or benchmark tuning. Those tasks can hand off to
rust-idiomatic, rust-concurrency, rust-unsafe-ffi, rust-tdd, rust-algorithms, or
rust-performance when installed.

## Runnable documentation checks

The standalone Rust examples use only the standard library and target edition
2024 (Rust 1.85+). These are commands to run, not a claim that checks have passed.
From the repository root:

```sh
rustdoc --test --edition=2024 rust-api-design/SKILL.md
rustdoc --test --edition=2024 rust-api-design/references/api-contracts.md
rustdoc --test --edition=2024 rust-api-design/references/creational.md
rustdoc --test --edition=2024 rust-api-design/references/structural.md
rustdoc --test --edition=2024 rust-api-design/references/behavioral.md
```

The `rust,compile_fail` example intentionally rejects a draft-only value using a
published-only operation. All other Rust fences are independent runnable checks;
assertions cover invalid ranges, partial writes, invalid builder combinations,
clone identity, UTF-8 boundaries, and failed state transitions.

Select the consuming project's own edition and MSRV rather than applying this
example baseline to an existing crate. `OnceLock` requires Rust 1.70; `LazyLock`
requires 1.80. The examples do not use let chains; that syntax requires Rust 1.88+
and edition 2024. Review newer std APIs individually against the project's MSRV.

## Consolidation and corrections

- SOLID becomes a set of contract questions, not five mandatory layers. Functions,
  enums, composition, and standard traits precede custom abstraction or DI.
- All five source creational families, seven structural families, and seven
  behavioral families remain covered, plus typestate, RAII, and newtypes. Tables
  route to substantive guidance instead of duplicating an OO class catalog.
- Replaced placeholder transports, fake compression/codecs, and dummy authentication
  with real dependency-free operations. No third-party framework is required.
- Corrected the claim that an elided `Fn(&str) -> &str` bound inherently fails:
  it already expresses the higher-ranked input/output relationship. Also qualified
  dyn-compatibility exclusions with `where Self: Sized` and associated-type rules.
- Removed blanket “return owned,” “never clone,” “never unwrap,” “dyn is slower,”
  and arbitrary method-count/performance-threshold rules. Each decision names
  its ownership, failure, or measurement contract.
- Typestate validates transitions but does not validate arbitrary strings or
  authenticate a remote system. RAII cleanup has explicit abort/leak limitations;
  fallible finalization remains observable.
- Observer guidance distinguishes broadcast from competing-consumer work queues;
  iterator guidance replaces the source's nonprogressing example with an explicit
  traversal invariant. Command guidance checks UTF-8 boundaries and states undo's
  no-intervening-mutation precondition.
- Detailed borrow checking, async correctness, unsafe implementation, testing
  workflow, and measured optimization are routed to the relevant optional skills
  rather than copied across bundles.

## Sources and attribution

Original synthesis adapted from StructWeave-Algorithms at pinned Rust-content
revision `49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`:

- [08 SOLID principles](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/08-solid-principles.md)
- [09 Creational patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/09-design-patterns-creational.md)
- [10 Structural patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/10-design-patterns-structural.md)
- [11 Behavioral patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/11-design-patterns-behavioral.md)
- [12 Anti-patterns and best practices](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/12-anti-patterns-best-practices.md)
- [13 Interview traps: API-relevant selections](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md)

Upstream material is MIT-licensed; see [LICENSE.upstream](LICENSE.upstream).
First-party references are linked alongside the relevant contracts, especially the
[Rust API Guidelines](https://rust-lang.github.io/api-guidelines/checklist.html),
[Rust Reference](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility),
and [Cargo SemVer guide](https://doc.rust-lang.org/cargo/reference/semver.html).
