# Creational decisions

## Selection table

| Family | Smallest Rust form | Use when | Stop condition / trap |
|---|---|---|---|
| Constructor | Associated `new`, `TryFrom`, named constructors | Few required arguments or a validated conversion | No builder solely to rename two arguments |
| Builder | Options struct with fluent setters and fallible `build` | Many independent options/defaults or cross-field constraints | Required arguments can still go in `new`; keep defaults consistent |
| Typestate builder | Distinct state types or state-bearing generic | Operation order must be statically restricted | A state marker does not validate the supplied value |
| Factory method | Function/associated constructor; trait only for variable creation policy | Centralize selection or resource acquisition | Do not hide I/O errors behind an infallible `new` |
| Abstract factory | Family trait with associated product types | Multiple related products must vary together | A single product does not need a family abstraction |
| Singleton | `static` plus `OnceLock`/`LazyLock` | Truly process-wide identity and lifetime | Inject configuration for per-test/per-request variation |
| Prototype | Explicit `Clone` of an existing value | Copy a meaningful template or snapshot | Clone may share handles, not duplicate their resources |

## Builders validate combinations; defaults are one source of truth

For reusable borrowed builders, `build(&self)` may need to clone stored values.
For one-shot construction, consuming setters and `build(self)` can move them.
Choose based on caller behavior, not fluent syntax alone. Keep the product's
invariant-bearing fields private and validate all construction paths.

This batching policy has two independently configurable limits and a cross-field
invariant. It describes batching limits, not a memory allocation or I/O operation.
`new` delegates to `Default` so the two entry points cannot disagree.

```rust
mod batching {
    #[derive(Debug, PartialEq, Eq)]
    pub struct Limits {
        max_item_bytes: usize,
        max_batch_bytes: usize,
    }

    #[derive(Debug, PartialEq, Eq)]
    pub enum BuildError { ZeroLimit, ItemExceedsBatch }

    pub struct LimitsBuilder {
        max_item_bytes: usize,
        max_batch_bytes: usize,
    }

    impl Default for LimitsBuilder {
        fn default() -> Self {
            Self { max_item_bytes: 1024, max_batch_bytes: 8192 }
        }
    }

    impl LimitsBuilder {
        pub fn new() -> Self { Self::default() }
        pub fn item_bytes(mut self, bytes: usize) -> Self {
            self.max_item_bytes = bytes;
            self
        }
        pub fn batch_bytes(mut self, bytes: usize) -> Self {
            self.max_batch_bytes = bytes;
            self
        }
        pub fn build(self) -> Result<Limits, BuildError> {
            if self.max_item_bytes == 0 || self.max_batch_bytes == 0 {
                return Err(BuildError::ZeroLimit);
            }
            if self.max_item_bytes > self.max_batch_bytes {
                return Err(BuildError::ItemExceedsBatch);
            }
            Ok(Limits {
                max_item_bytes: self.max_item_bytes,
                max_batch_bytes: self.max_batch_bytes,
            })
        }
    }
}

use batching::{BuildError, LimitsBuilder};
assert_eq!(LimitsBuilder::new().build(), LimitsBuilder::default().build());
assert!(LimitsBuilder::new().item_bytes(8).batch_bytes(8).build().is_ok());
assert_eq!(LimitsBuilder::new().item_bytes(9).batch_bytes(8).build(),
           Err(BuildError::ItemExceedsBatch));
assert_eq!(LimitsBuilder::new().item_bytes(0).build(), Err(BuildError::ZeroLimit));
```

A typestate builder would not remove these runtime checks: byte limits arrive as
runtime values. Use typestate when method availability matters, such as finalizing
only after a validated signing key has been supplied, and store the validated key
rather than a `HasKey` marker beside an unchecked string. See [behavioral state](behavioral.md).

## Factory methods: select representation separately from ownership

Consider an input source that can be a file or standard input. A factory can return
`io::Result<Box<dyn Read>>` for owned runtime-selected readers; this is an actual
reason for type erasure. A closed `Input` enum with delegating `Read` is another
option. If the caller already owns a reader, accepting `R: Read` is simpler than
making the library acquire it. If there is only one concrete reader, return it.

Returning `impl Read` does not let different branches return unrelated concrete
reader types: the hidden return type must still be one concrete type. Nor is a
Rust trait object a stable plugin ABI; cross-library binary interfaces require a
separate ABI/ownership contract.

Keep fallible acquisition fallible. For example, opening a file returns an I/O
error rather than panicking in a logger factory. Decide whether opening truncates,
appends, or creates; a pattern name does not choose the correct filesystem policy.

## Abstract factories: express product relationships

An export backend may need both an encoder and a manifest writer. An abstract
factory is useful only when these products form a family selected together.
Use associated types (`Encoder`, `Manifest`) when the backend is selected
statically. If an encoder consumes a backend-specific header, connect that header
type through an associated type equality instead of accepting an unrelated
`Box<dyn Header>` and downcasting at runtime.

A concrete example is a binary format family whose encoder produces `F::Header`
and whose manifest writer accepts `&F::Header`. This rejects mixing one format's
header with another's manifest at compile time. It does **not** prove both objects
came from the same factory *instance*: two databases can have the same Rust type.
Connection/transaction pairing often needs a borrow tied to the connection or a
checked runtime identity as well.

For runtime-selected families, a closed backend enum can dispatch the entire
operation so mismatched products are never exposed. Use erased product traits
only if open extension is a real requirement and their common contract is valid.
Avoid manually reimplementing an existing database/serialization library's factory
and transaction APIs.

## Singleton: initialization policy is observable behavior

Prefer an application-owned configuration passed by reference. For an unavoidable
process-wide resource, choose explicitly:

- `OnceLock<T>` (stable since 1.70): explicit `set` or lazy `get_or_init`.
  A failed `set` returns the rejected value; `get` returns `None` without blocking
  while uninitialized or initializing. A panicking initializer leaves it unset.
- `LazyLock<T>` (stable since 1.80): a fixed initializer runs on first access;
  initialization panic poisons the value. Check the project's MSRV first.
- `OnceLock<Result<T, E>>`: deliberately stores failure as well as success. That
  is cached failure, not automatic retry. Do not silently choose this policy for
  transient network errors.

Avoid recursive initialization: `OnceLock::get_or_init` reentrancy is erroneous
and can deadlock. A `const` is a value definition, not a process-wide singleton
allocation. Static values do not receive normal scope-exit destruction; design
explicit shutdown for resources requiring successful flush/close. Do not make
unit tests mutate the same process-wide singleton and depend on execution order.

## Prototype: independent copies versus shared identity

A template containing a `String` and a reference-counted style illustrates two
legitimate clone semantics. The text becomes independent; the immutable style is
shared. The assertions document the difference instead of declaring all clones
expensive or all prototypes deep copies.

```rust
use std::rc::Rc;

#[derive(Clone)]
struct Document {
    text: String,
    style: Rc<str>,
}

let template = Document { text: String::from("draft"), style: Rc::from("plain") };
let mut copy = template.clone();
copy.text.push_str(" revised");
assert_eq!(template.text, "draft");
assert_eq!(copy.text, "draft revised");
assert!(Rc::ptr_eq(&template.style, &copy.style));
```

Do not assume `Clone` can be used directly as a supertrait for a cloneable `dyn`
interface: `Clone` requires `Sized`. A closed enum can derive `Clone`; a genuinely
open object hierarchy can expose an explicit `clone_box` contract if needed.
First decide whether callers want copied state or shared ownership—those are not
interchangeable. Regenerate identity only in a deliberately named operation such
as `duplicate_as_new`, not secretly in a purported snapshot.

## Sources

Adapted from StructWeave [09 creational patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/09-design-patterns-creational.md)
and [12 API practices](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/12-anti-patterns-best-practices.md).
Authoritative semantics: [OnceLock](https://doc.rust-lang.org/std/sync/struct.OnceLock.html),
[LazyLock](https://doc.rust-lang.org/std/sync/struct.LazyLock.html),
[Clone](https://doc.rust-lang.org/std/clone/trait.Clone.html), and
[Rust API Guidelines](https://rust-lang.github.io/api-guidelines/checklist.html).
