# API contracts, traits, and evolution

## Start with ownership, not a trait hierarchy

| Requirement | Signature/design | Contract to document |
|---|---|---|
| Read text or contiguous items | `&str`, `&[T]` | Borrow duration; byte versus character units |
| Retain an input | Owned `String`/`Vec<T>` or `impl Into<String>` | Conversion may allocate; do not clone an already-owned argument |
| Mutate existing storage | `&mut T` | State after an error; do not promise rollback accidentally |
| Return a view | `&T`, `&str`, borrowed iterator | Which input owns the result; avoid unrelated lifetime coupling |
| Sometimes borrow, sometimes construct | `Cow<'a, str>` | `into_owned` can copy borrowed data |
| Possibly absent, possibly failed | `Result<Option<T>, E>` | `Ok(None)` is absence, not a swallowed I/O error |
| Validate a representation | `TryFrom`, `FromStr`, fallible constructor | Accepted grammar, normalization, and retained original data |
| Infallibly convert | `From`/`Into` | No input-dependent failure or hidden lossy conversion |

Returning owned output is appropriate for a new result, not for every getter.
Returning an iterator avoids collecting when callers need only traversal, but its
lifetime and exposed trait bounds become part of the API. `impl Trait` in return
position denotes a single hidden concrete type, not arbitrary runtime alternatives.

## Abstraction and dispatch decision

| Situation | Choose | Consequence |
|---|---|---|
| One known implementation | Concrete type/function | Most legible contract and diagnostics |
| One variable operation | `Fn`, `FnMut`, or `FnOnce` bound | Bound reflects shared invocation, mutation, or consumption |
| Closed alternatives | Enum and exhaustive `match` | Runtime choice without an open implementation set |
| Caller supplies implementation | `T: Trait` / argument `impl Trait` | Static type information and monomorphization |
| Borrowed heterogeneous operations | `&dyn Trait` / `&mut dyn Trait` | Dynamic dispatch without requiring allocation |
| Own heterogeneous operations | `Box<dyn Trait + 'a>` | Ownership, explicit object lifetime, normally heap storage |
| One item type per implementation | Associated type | E.g. `Iterator::Item`; bind it when erasing: `dyn Iterator<Item = u8>` |
| Same type supports multiple input types | Trait type parameter | E.g. several `From<T>` implementations |

`T: Trait` is implicitly `Sized`; use `T: Trait + ?Sized` behind a reference if
both concrete types and trait objects should work. Do not add `Send + Sync +
'static` unless the contract really requires transfer, sharing, or long-lived
storage. Those bounds exclude useful callers.

## SOLID as contract checks

- **SRP:** Keep domain invariants together. Split storage, transport, or formatting
  when they change independently, not because a function exceeds thirty lines.
- **OCP:** Decide whether downstream extension is needed. A private implementation
  behind a module is already encapsulation; it does not require a public trait.
- **LSP:** State guarantees precisely. A remote cache cannot emulate an infallible
  local cache by mapping timeouts to misses. Different size limits are acceptable
  only if the trait promises that limit discovery/error behavior.
- **ISP:** Reuse standard capabilities such as `Read` or `Write`. A report writer
  needs a writer, not a connection pool, logger, and repository supertrait.
- **DIP:** Pass dependencies as arguments or fields and wire them at the program
  boundary. A closure can supply a clock or policy without a new service class.

This real formatter accepts any standard writer, including a borrowed trait
object, and propagates output errors. It does not invent a logging framework.

```rust
use std::io::{self, Write};

fn write_hex<W: Write + ?Sized>(out: &mut W, bytes: &[u8]) -> io::Result<()> {
    for byte in bytes {
        write!(out, "{byte:02x}")?;
    }
    Ok(())
}

let mut bytes = Vec::new();
write_hex(&mut bytes, &[0, 15, 255]).expect("Vec writer");
assert_eq!(bytes, b"000fff");
let erased: &mut dyn Write = &mut bytes;
write_hex(erased, &[]).expect("empty input changes nothing");
assert_eq!(bytes, b"000fff");
let mut short_storage = [0_u8; 1];
let mut short_writer = &mut short_storage[..];
assert_eq!(write_hex(&mut short_writer, &[255]).unwrap_err().kind(),
           io::ErrorKind::WriteZero);
```

The last call may have written a prefix before failing. A `Result` does not imply
atomic output. If a caller needs all-or-nothing behavior, select a real transaction
or document a staging-and-commit protocol appropriate to that destination.

## Dyn compatibility: preserve a usable dynamic surface

Per the [Rust Reference](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility),
a dyn-compatible trait cannot require `Self: Sized`, associated constants, or
generic associated types. Dynamically callable methods cannot have type parameters
or return bare `Self`, `impl Trait`, or an `async fn`'s opaque future. Supported
receivers include references and certain owning/pinned pointer forms.

A generic helper can still live on the trait with `where Self: Sized`; it is then
unavailable through `dyn`. Prefer that or a separate extension trait over erasing
all arguments to `Any` and rebuilding type checking with downcasts. Ordinary
associated types are compatible when their values are fixed in the object type.

## Relevant interview traps, corrected

1. **Does `Box<dyn Trait>` permit arbitrary short-lived borrows?** In an item
   signature, an unconstrained object lifetime normally defaults to `'static`.
   Use `Box<dyn Trait + 'a>` when the object borrows for `'a`. `&'a dyn Trait`
   normally inherits `'a`; a reference to a box does not automatically shorten
   the lifetime bound of the object inside it.
2. **Does `T: 'static` keep a value alive forever?** No. It constrains borrowed
   content; an owned `String` qualifies and drops normally.
3. **Does `Fn(&str) -> &str` need an explicit HRTB to compile?** Not inherently.
   Elision already expresses the input/output relationship for all argument
   lifetimes. A particular closure can have an inference problem; spelling the
   same bound differently does not fix every closure. A function item makes the
   relationship clear, as below.
4. **Can a foreign trait be implemented for `Vec<i32>`?** Not by a downstream
   crate. Use a local newtype for that combination; a type alias is not a local
   type. More complex generic impls must also satisfy coherence/orphan rules.
5. **Is generic dispatch always faster or `dyn` always smaller?** No universal
   guarantee. Monomorphization and indirect calls have different tradeoffs;
   optimizer decisions, code size, and workload matter.

```rust
fn trimmed(s: &str) -> &str { s.trim() }

fn apply<F>(f: F) -> usize
where
    F: Fn(&str) -> &str,
{
    let input = String::from("  borrowed  ");
    f(&input).len()
}

assert_eq!(apply(trimmed), 8);
```

See [lifetime elision and object defaults](https://doc.rust-lang.org/reference/lifetime-elision.html).
Lifetimes constrain validity; repeating `'a` does not require input owners to have
identical lexical scopes. Avoid tying an unused lookup key's lifetime to a result
borrowed solely from a collection.

## Anti-pattern review and public evolution

- Replace string tags for a closed domain with enums and distinguish identifiers
  with newtypes. Parse external strings at the boundary; a newtype's name alone
  does not validate its contents.
- Use private fields and narrow methods for invariants. Public `DerefMut`, `AsMut`,
  unchecked deserialization, or a public tuple field can reopen invalid states.
- Cloning may intentionally produce independence, or merely share `Rc`/`Arc`
  storage. Document which. `Clone` does not imply `Copy`; assignment of a
  non-`Copy` type still moves it. Shared mutable state needs an ownership design,
  not a blanket prohibition on `RefCell` or `Mutex`.
- Return errors for expected failures. `expect` is useful in tests and for a
  demonstrated invariant, not because a configuration error is inconvenient.
  Keep error sources and avoid leaking tokens or sensitive payloads in `Debug`.
- Do not equate iterator style, unsafe code, or a prescribed size threshold with
  performance. Route measurements to rust-performance if installed.
- Document `# Errors`, `# Panics`, examples, units, and state after failure;
  document `# Safety` for unsafe APIs. Support ordinary traits only when their
  semantics are meaningful, not as an automatic derive list.

For published APIs, adding a required trait method, tightening bounds, removing
`Send`/`Sync`, changing exposed lifetimes, or adding variants to an exhaustive enum
can break callers. Choose `#[non_exhaustive]` or sealed traits at design time only
when the intended evolution policy warrants them; adding restrictions later can
itself break callers. Internal/private refactors do not require a public extension
framework. Review the [Cargo SemVer guide](https://doc.rust-lang.org/cargo/reference/semver.html)
and [Rust API Guidelines checklist](https://rust-lang.github.io/api-guidelines/checklist.html).

For published library changes, consider [cargo-semver-checks](https://github.com/obi1kenobi/cargo-semver-checks)
against the intended release baseline and supported feature/target configurations.
Passing structural API checks does not establish behavioral or wire-format
compatibility; retain tests for those contracts.

## Sources

Adapted from StructWeave [08 SOLID](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/08-solid-principles.md),
[12 anti-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/12-anti-patterns-best-practices.md),
and the API-relevant sections of [13 traps](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md).
First-party references above take precedence over simplified upstream examples.
