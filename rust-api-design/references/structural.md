# Structural decisions: composition with contracts

## Selection table

| Pattern | Rust form | Concrete reason | Important boundary |
|---|---|---|---|
| Adapter | Newtype implementing the expected trait | Convert a legacy/foreign interface to your caller's capability | Translate units, errors, and ownership, not only method names |
| Decorator | Wrapper implementing the inner trait | Buffer, limit, count, or transform an existing operation | Preserve the trait's partial-progress and error rules |
| Facade | Module or struct with a small public surface | Coordinate a subsystem and hide implementation detail | Do not hide partial failure or imply atomicity |
| Composite | Recursive enum, or owned trait objects for open nodes | Treat leaves and groups uniformly | Empty groups, invalid leaf operations, depth, overflow |
| Proxy | Explicit methods controlling access/loading/caching | Enforce access or defer work | `Deref` can expose a path around the policy |
| Flyweight | Shared immutable data via `Rc`/`Arc`, interning | Repeated values genuinely dominate storage | Scope retention and distinguish identity from value equality |
| Bridge | Domain abstraction composed with a backend capability | Two dimensions vary independently | Avoid every domain/backend pair becoming a new type |

## Adapters: local ownership, coherent implementations

A foreign trait/foreign concrete type combination generally cannot receive your
implementation. Wrap the concrete value in a local newtype; a type alias does not
change type identity. If the trait is yours, implementing it directly on a foreign
type can already be legal—do not add a wrapper without a reason.

For example, adapting a legacy timestamp API from milliseconds to `Duration`
requires explicit units and range checks. An adapter must not silently turn an
invalid timestamp into zero. For formatting, a borrowed newtype can implement
`Display` without owning or copying the underlying collection:

```rust
use std::fmt;

struct Hex<'a>(&'a [u8]);
impl fmt::Display for Hex<'_> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        for byte in self.0 { write!(f, "{byte:02x}")?; }
        Ok(())
    }
}

assert_eq!(format!("{}", Hex(&[0, 255])), "00ff");
assert_eq!(format!("{}", Hex(&[])), "");
```

## Decorators: keep partial-write semantics

Prefer standard decorators (`BufReader`, `BufWriter`, `Read::take`) when they
already implement the requested behavior. A custom decorator should forward
required operations and preserve errors. `write` may accept only part of a buffer;
count the returned amount, not the requested length. `write_all` may fail after
partial progress. `flush` must reach the destination.

This wrapper adds a strict byte budget. It borrows a caller-provided fixed-size
writer in the example, so it neither allocates a buffer nor builds a fake writer.

```rust
use std::io::{self, Write};

struct BudgetWriter<W> {
    inner: W,
    remaining: usize,
}
impl<W: Write> Write for BudgetWriter<W> {
    fn write(&mut self, bytes: &[u8]) -> io::Result<usize> {
        if bytes.is_empty() { return Ok(0); }
        if self.remaining == 0 {
            return Err(io::Error::new(io::ErrorKind::PermissionDenied,
                                      "byte budget exhausted"));
        }
        let allowed = bytes.len().min(self.remaining);
        let written = self.inner.write(&bytes[..allowed])?;
        self.remaining -= written;
        Ok(written)
    }
    fn flush(&mut self) -> io::Result<()> { self.inner.flush() }
}

let mut storage = [0_u8; 8];
{
    let mut writer = BudgetWriter { inner: &mut storage[..], remaining: 3 };
    assert_eq!(writer.write(b"abcdef").expect("first write"), 3);
    assert_eq!(writer.write(&[]).expect("empty writes are allowed"), 0);
    assert_eq!(writer.write_all(b"x").unwrap_err().kind(),
               io::ErrorKind::PermissionDenied);
    writer.flush().expect("slice flush");
}
assert_eq!(&storage[..3], b"abc");
assert_eq!(&storage[3..], &[0; 5]);
```

The wrapper is a budget, not an atomic record writer. If an operation must reject
an oversized record before emitting any bytes, provide a separate record-level
method that checks its total size first. Never implement an incompatible promise
under a standard trait name. Wrapping order also matters: buffering outside a
budget can defer the error until flush. Always check explicit finalization errors.

## Facade: simplicity without false success

A report facade can validate a query, fetch rows, and encode output behind one
operation. Its returned error must still identify the failed stage and preserve
needed source information. If output has begun, say so; do not advertise rollback
because the implementation is split into small services.

For persistence plus notification, define whether a notification failure means
“not persisted,” “persisted but notification failed,” or a durable queued follow-up.
Choose a real transaction/outbox only when the actual delivery contract needs it.
A `save(); send();` sequence cannot promise atomicity across two systems. Avoid
adding retry logic under a facade unless repeatability/idempotency is established.

## Composite: closed trees need no object hierarchy

Use an enum such as `Node::File { bytes }` and `Node::Directory { children }` for
closed node kinds. A total-size fold should define the empty directory's total
(zero) and use checked addition if totals can exceed the chosen integer type.
Do not let `add_child` on a file silently do nothing: expose it only on a directory
representation or return a meaningful error (and preserve the rejected child if
needed).

`Vec<Node>` already provides recursive indirection for children; a `Box<Node>` is
needed for direct recursive fields, not automatically on every edge. For externally
extensible node kinds, `Vec<Box<dyn Node>>` may be appropriate, with explicit
ownership and visitor contracts. Untrusted depth needs a limit or an iterative
walk; recursion is not free protection against stack exhaustion. Parent links
usually need indices or `Weak`, not strong reference cycles.

## Proxy: do not provide a policy bypass

A protection proxy must keep the protected object private and expose only checked
operations. Returning `&Inner`, implementing `Deref<Target = Inner>`, or offering
an unrestricted `into_inner` can bypass that policy. Ordinary `Deref` coercion is
intended for cheap, unsurprising pointer-like access, not hidden I/O or repeated
authorization checks; see [Deref's API contract](https://doc.rust-lang.org/std/ops/trait.Deref.html).

A lazy proxy needs an initialization/failure policy; see [creation](creational.md).
A caching proxy additionally needs a key definition, invalidation/freshness rules,
and a statement about whether errors are cached. Include authorization context in
the cache partition if values differ by caller. Avoid holding a global cache lock
through network I/O. Releasing the lock can allow duplicate loads; choose whether
that is acceptable before introducing single-flight coordination. Hand off such
coordination to rust-concurrency if installed.

## Flyweight: sharing is not eviction

Split shared immutable style/asset data from per-object position and mutable
state. Borrow when one owner already outlives all users; otherwise use `Rc` within
one thread or `Arc` where the inner type's thread-safety permits sharing.

An interner maps equal strings to a canonical shared value. A table holding strong
references retains those strings until removal or table destruction. For a compiler,
scoping the table to a compilation may be sufficient; a process-global interner
for unbounded user input is an unbounded retention policy. Weak entries require
cleanup and can allow a new canonical allocation after all users release a value.
Pointer equality is therefore only meaningful within the interner's documented
identity scope. Measure before adding interning; hashing and reference counting
have costs, and shared mutability can invalidate the intended immutable model.

## Bridge: independent axes, one capability boundary

Suppose several report kinds must render both to terminal text and to an HTML
backend. The report model is one axis; the rendering backend is the other. Let
report traversal invoke a renderer's semantic operations, rather than making
`HtmlSalesReport`, `TextSalesReport`, `HtmlInventoryReport`, and so on. The backend
handles escaping and representation; the report owns domain meaning.

Use a generic renderer for statically selected backends or a borrowed dyn renderer
for runtime selection. A bridge may need only one backend trait and ordinary
report functions, not a second hierarchy of abstract “report” classes. If both
axes are closed and tiny, an enum and a function can still be simpler. Test that
each backend preserves meaning (including escaping), not just that calls dispatch.

## Sources

Adapted from StructWeave [10 structural patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/10-design-patterns-structural.md),
with API constraints from [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/checklist.html)
and [Deref](https://doc.rust-lang.org/std/ops/trait.Deref.html).
Standard I/O contract: [Write](https://doc.rust-lang.org/std/io/trait.Write.html).
The examples replace upstream illustrative codecs/services with real std-only
operations; no copied “successful” placeholder transport or encoder is used.
