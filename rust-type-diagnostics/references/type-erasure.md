# Type erasure: identify what was erased

Use this reference for a failed downcast or a surprising `'static` requirement,
not to choose an application's polymorphism architecture. Enums, domain-trait
methods, and generic APIs remain `rust-api-design` decisions.

## Diagnostic sequence

1. Find the expression that first became `dyn Any`, not just the later downcast.
2. Record the concrete erased type, including references and smart pointers.
   Erasing `String`, `&'static str`, and `Box<String>` produces different types.
3. Check whether the erased type contains non-`'static` borrows. The borrow of
   the erased value itself may be short-lived; its concrete type must meet `Any`.
4. Decide which operation is intended:

| Operation | Supported relationship |
|---|---|
| Concrete value to trait object | The concrete type implements the target trait |
| Upcast a trait object | The target is a supertrait; supported on Rust 1.86+ |
| `downcast_ref::<T>` / `downcast_mut::<T>` | The erased value's exact concrete type is `T` |
| `is::<T>()` | Exact concrete identity, without obtaining the value |
| Discover an unrelated trait implementation using `Any` | Not provided by stable `Any`; use a known concrete type or explicit interface |

A `None` result is a legitimate type mismatch, not a signal to use an unchecked
cast. Check the erasure site, then handle absence according to the caller's
contract. Do not convert the entire domain API to `Any` to remove one diagnostic.

## `'static` constrains the erased type, not the borrow of the object

This fails because `View` contains a borrow of a local allocation. A short-lived
`&dyn Any` does not remove the requirement on the concrete type implementing Any.

```rust,compile_fail,E0597
use std::any::Any;

struct View<'a>(&'a str);
let source = String::from("borrowed payload");
let view = View(source.as_str());
let erased: &dyn Any = &view;
assert!(erased.is::<View<'_>>());
```

An owned `String` has no borrowed content and qualifies, even when the value and
its borrow are local. This example borrows the owner; it does not leak it or
extend its storage duration.

```rust
use std::any::Any;

let source = String::from("owned payload");
let erased: &dyn Any = &source;
let restored = erased.downcast_ref::<String>().expect("erased a String");
assert_eq!(restored.as_str(), "owned payload");
assert!(erased.downcast_ref::<u32>().is_none());
```

If retaining a borrowed `View` is the actual API contract, keep a lifetime-aware
domain trait or enum instead. Allocating owned copies just to satisfy `Any` is
not a neutral fix.

## Domain trait to Any: upcasting is not sideways trait discovery

**Version boundary: trait upcasting stabilized in Rust 1.86.** This is a modern
supplement to the book, whose helper-removal example instead changes storage to
`dyn Any`. On an older declared MSRV, keep the project's existing object-safe
`as_any` bridge or obtain approval for a compiler-policy change.

Keeping `Reading: Any` preserves the domain interface while permitting an
upcast. Its supertrait is meaningful: it constrains implementing types and
establishes the supported conversion.

```rust
use std::any::Any;

trait Reading: Any {
    fn value(&self) -> u32;
}
struct Counter(u32);
impl Reading for Counter {
    fn value(&self) -> u32 { self.0 }
}

let mut counter = Counter(7);
let domain: &dyn Reading = &counter;
assert_eq!(domain.value(), 7);
let erased: &dyn Any = domain;
assert_eq!(erased.downcast_ref::<Counter>().unwrap().0, 7);
assert!(erased.downcast_ref::<u32>().is_none());

let domain: &mut dyn Reading = &mut counter;
let erased: &mut dyn Any = domain;
erased.downcast_mut::<Counter>().unwrap().0 += 1;
assert_eq!(counter.value(), 8);
```

If the erased `Counter` also implements a separate `Reset` trait, downcasting to
`Counter` and then coercing that concrete reference to `dyn Reset` is possible.
`downcast_ref::<&dyn Reset>()` does something else: it searches for an erased
reference value of that exact type and, on success, returns a reference to that
reference. It does not query which traits an erased `Counter` implements.

Similarly, converting `&domain` into `Any` attempts to erase the reference
wrapper, not the original payload, and that wrapper may also fail the `'static`
requirement. Do not add another `&` as a speculative fix.

## Smart-pointer method lookup can inspect the wrapper

`Box<dyn Any>` itself implements `Any`. Calling `.type_id()` on that box can
therefore report the box type, while calling through `&dyn Any` reports the
payload. Decide which layer is intended explicitly.

```rust
use std::any::{Any, TypeId};

let boxed: Box<dyn Any> = Box::new(vec![2_u8, 5, 8]);
assert_eq!(boxed.type_id(), TypeId::of::<Box<dyn Any>>());
let payload: &dyn Any = boxed.as_ref();
assert_eq!(payload.type_id(), TypeId::of::<Vec<u8>>());
assert_eq!(payload.downcast_ref::<Vec<u8>>().unwrap().as_slice(), &[2, 5, 8]);
assert!(payload.downcast_ref::<Box<Vec<u8>>>().is_none());
```

The same principle applies to reference/container layers at an erasure site.
Do not use `type_name` strings as an equality test or persistent type identifier;
use the typed downcast or `TypeId` comparison for in-process exact identity.

## Boundaries and evidence

- This reference covers borrowed downcasting. Do not silently replace it with an
  owned downcast: consuming a box changes ownership and failure handling.
- Choosing `Any` is not a remedy for a non-dyn-compatible trait. Route generic
  method, associated-type, or public-interface redesign to `rust-api-design`.
- Validate the desired concrete case **and** a mismatched type. For mutable
  access, observe the mutation through the original owner after the borrow ends.
- No unchecked downcasts, vtable manipulation, or lifetime extension are needed.

Primary references:
- [Any and smart-pointer identity](https://doc.rust-lang.org/std/any/index.html)
- [Any's bound and borrowed downcasts](https://doc.rust-lang.org/std/any/trait.Any.html)
- [Trait-object upcasting](https://doc.rust-lang.org/reference/type-coercions.html#unsized-coercions)
- [Rust 1.86 stabilization](https://blog.rust-lang.org/2025/04/03/Rust-1.86.0/)

Book origin: Chapter 8, especially downcasting and conversion between trait
objects. Exact-type correction, wrapper diagnostics and modern upcasting are
primary-source supplements; see [sources](sources.md).
