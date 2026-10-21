# Sources, boundaries, and validation

## Source material and adaptation

Topic selection began with Nouman Azam, *Advanced Rust: Exploring Power Features
of Rust for Intermediate and Advanced Developers*, Apress, 2026,
[DOI 10.1007/979-8-8688-2992-5](https://doi.org/10.1007/979-8-8688-2992-5).
The supplied `Advanced_Rust.md` was reviewed across all nine chapters, not just
its contents. That conversion includes split listings and other extraction
artifacts; source prose also contains misleading language claims.

This skill is an original diagnostic synthesis, not a reproduction or corrected
edition of the book. It does not bundle the book, depend on its local path, or
claim that the book's license covers the skill's new prose. Original examples
isolate language rules instead of preserving textbook application scaffolding.

Primary Rust documentation takes precedence for language/library semantics.
Compiler observations establish behavior only on the exercised configuration;
they do not turn implementation details into guarantees.

## Full-book disposition

| Book chapter | Treatment in this skill | Existing owner or reason for exclusion |
|---|---|---|
| 1. Error Handling | No tutorial copied | `rust-idiomatic`: Result/Option, propagation, typed errors and context |
| 2. Debugging | Runtime-debugging workflow excluded | Ordinary tools already have a home; deeper tracing/debugger work is a different activation task |
| 3. Beyond Basic References | Pattern/type reconstruction and intermediate receiver diagnosis | Basic moves, reborrows and split borrows remain `rust-idiomatic`; chaining API design remains `rust-api-design` |
| 4. Coercions | Expected types, coercion sites, generic barriers, function items and branch/collection targets | New mechanistic diagnostic depth, not wrapper/API design advice |
| 5. Combinators | No combinator catalog copied | `rust-idiomatic`; cost claims route to `rust-performance` |
| 6. Relationships in Lifetimes | Implied bounds and position-sensitive variance | Lifetime fundamentals and ordinary HRTB introductions remain `rust-idiomatic` |
| 7. Trait Limitations, Object Safety, and the Orphan Rule | Handoff rather than another trait checklist | `rust-api-design` owns dyn compatibility, trait architecture, newtypes and sealing |
| 8. Downcasting | Exact erased-type, borrowed-content and reference/wrapper diagnosis | Choosing runtime erasure remains an API-design decision |
| 9. Drop Check | Drop-check obligations, safe owner scopes and destruction-order distinctions | Unsafe manual cleanup, pinning and FFI remain `rust-unsafe-ffi` |

The overlap comparison included the Rust suite at `skillsmd`: algorithms,
API design, concurrency, guidelines, idiomatic Rust, macros, performance, TDD,
unsafe/FFI and Wasm, including relevant references. At comparison time,
`rust-fast` was an empty reference directory with no `SKILL.md`; its name was not
treated as evidence of an additional installed capability.

Neighboring skills are optional handoffs, not required files. This bundle can be
installed by itself. Shared vocabulary is unavoidable; duplicated workflows and
broad tutorials are deliberately excluded.

## Corrections that affect this skill

These are not an exhaustive errata list for the book.

| Source issue | Rule used here | Primary authority |
|---|---|---|
| Binding mutability described as a reference type property | Distinguish `mut binding` from `&mut T`, and reference patterns from binding modes | [Patterns](https://doc.rust-lang.org/reference/patterns.html) |
| Deref chains used to assert unrestricted coercion transitivity | General transitive coercion support is incomplete | [Coercion types](https://doc.rust-lang.org/reference/type-coercions.html#coercion-types) |
| Slices described as inherently static; lifetimes treated as codegen specializations | A borrow depends on its actual owner; lifetime parameters are erased, not separate type-monomorphized copies | [Lifetime elision](https://doc.rust-lang.org/reference/lifetime-elision.html), [Rust compiler monomorphization guide](https://rustc-dev-guide.rust-lang.org/backend/monomorph.html) |
| `T: 'a` conflated with a particular value living until `'a` | It constrains borrowed content represented in the type | [Lifetime bounds](https://doc.rust-lang.org/reference/trait-bounds.html#lifetime-bounds) |
| Covariance generalized to arbitrary constructors; callback prose reverses assignments | Track each parameter position; distinguish fixed-lifetime variance from higher-ranked input requirements | [Subtyping and variance](https://doc.rust-lang.org/reference/subtyping.html) |
| `Any` used as discovery of unrelated trait implementations | Downcasting tests the exact concrete type, not arbitrary implemented traits | [Any and TypeId](https://doc.rust-lang.org/std/any/index.html) |
| Replacing a domain trait with `Any` presented as equivalent helper removal | Preserve the domain contract; use a supertrait upcast only when supported | [Rust 1.86](https://blog.rust-lang.org/2025/04/03/Rust-1.86.0/) |
| `#[may_dangle]` example accesses the borrowed field it promises not to access | Do not import the unsafe bypass; use valid ownership/scope changes | [Drop-check escape hatch](https://doc.rust-lang.org/nomicon/dropck.html#an-escape-hatch) |
| Vector destruction order described as guaranteed | `Vec` does not guarantee element destruction order | [Vec guarantees](https://doc.rust-lang.org/std/vec/struct.Vec.html#guarantees) |
| Panic catching presented as universal recovery/cleanup | Only unwinding panics can be caught; catching is neither rollback nor proof of safe state | [catch_unwind](https://doc.rust-lang.org/std/panic/fn.catch_unwind.html) |

## Explicit supplementary material

The following are primary-source additions, not claims about what the book
teaches:

- Rust 2024 match-ergonomics restrictions:
  [Edition Guide](https://doc.rust-lang.org/edition-guide/rust-2024/match-ergonomics.html).
- Rust 2024 temporary-scope changes:
  [Destructors](https://doc.rust-lang.org/reference/destructors.html#temporary-scopes).
- Trait upcasting, stabilized in Rust 1.86:
  [release announcement](https://blog.rust-lang.org/2025/04/03/Rust-1.86.0/).
- Smart-pointer versus payload type identity:
  [std::any](https://doc.rust-lang.org/std/any/index.html#smart-pointers-and-dyn-any).
- Complete coercion sites and method receiver lookup:
  [coercions](https://doc.rust-lang.org/reference/type-coercions.html),
  [method calls](https://doc.rust-lang.org/reference/expressions/method-call-expr.html).

## Reproducing example checks

The bundle requires no Cargo project or downloaded crates. From its directory,
run each topic separately with the intended compiler:

```sh
rustdoc --test --edition=2024 references/coercions-and-patterns.md
rustdoc --test --edition=2024 references/lifetimes-and-variance.md
rustdoc --test --edition=2024 references/type-erasure.md
rustdoc --test --edition=2024 references/drop-checking.md
```

Passing examples execute assertions. Intentional `compile_fail` examples exercise
rejected relationships. When maintaining them, inspect the actual diagnostic to
exclude accidental syntax/import failures; an arbitrary compiler rejection is
not proof of the intended constraint. Do not remove a failure case just because
a new compiler changes its result: establish whether the rule, edition, or
example is responsible, then update both the guidance and its evidence.

These commands are not a project-wide test policy. When applying the skill to
real code, use that project's locked toolchain, target, features and verification
workflow. Neither local example success nor an independent text review is an
MSRV certification or proof that unsafe code is sound.

## Exercised validation

Validated on 2026-10-21 with Fedora Rust/rustdoc **1.99.0**, Linux x86_64,
edition **2024**, without external crates:

| Check | Observed result |
|---|---|
| Rustdoc examples across four topic files | 34 passed: 22 executable examples and 12 intentional compile failures; none ignored |
| Rejection-cause inspection with rustc | All 11 annotated error codes matched; the remaining failure was the intended Rust 2024 reference-pattern restriction |
| Drop-check cause isolation | Revised example rejects with `Drop`; the same case without that implementation compiles and runs |
| Fresh skill-consumer correction | Generic `&String` trait-bound failure reproduced as E0277; the consumer's explicit `&str` reborrow compiled and ran, checking Unicode character count and preserving the original owner |
| Consumer scope/version trials | Kept the existing `as_any` bridge for declared MSRV 1.85; routed a queue-optimization request to concurrency/performance rather than inventing a type diagnostic |
| Standalone packaging | An isolated six-file copy resolved all 10 local Markdown links inside the bundle |
| Skill discovery | The managed skill resolved by name |
| Static skill-smell checks | Five checks completed without findings or parser warnings |
| Semantic skill-smell review | All 21 categories assessed without an identified smell; this is reviewer judgment, not a mechanical guarantee |

Independent semantic review found that the original drop-check rejection also
had a later explicit use, so it did not isolate implicit destructor liveness.
That use was removed; the affected Rustdoc file and with/without-`Drop`
comparison were executed successfully. A separate review found missing
observed-validation metadata; this section supplies it.

The MSRV 1.85 decision was a consumer reasoning trial, not execution on Rust
1.85. No older compiler, other target, unsafe abstraction, or universal model
reliability claim is covered by these checks. The consumer trial demonstrates
one real use of the skill, not a broad diagnostic-accuracy benchmark.
