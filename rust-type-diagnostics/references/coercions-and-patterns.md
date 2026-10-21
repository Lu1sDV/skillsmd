# Coercions, patterns, and receiver types

Use this reference when an expected/found mismatch survives ordinary ownership
analysis. Examples target edition 2024; intentional failures isolate a rule, not
compiler wording. They do not establish an MSRV. For ordinary reborrowing and
ownership, use `rust-idiomatic`; for receiver/API design, use `rust-api-design`.

## 1. Locate the expected type before changing the expression

Record the expression's actual type, the expected type, and where that expectation
comes from. An unannotated `let` can preserve a concrete type that a later use
cannot convert inside its container. Inference is not a general conversion search.

Ordinary coercion sites include explicitly typed bindings, statics/constants,
assignments, function arguments, declared return types, and constructor fields.
An expected type can propagate into array/tuple elements, parentheses, and block
tail expressions. A method's **receiver** uses different adjustment rules (§6).

```rust
fn byte_count(text: &str) -> usize { text.len() }
let nested = Box::new(String::from("signal"));
let concrete = &nested;                 // &Box<String>, not &str
let text: &str = concrete;              // repeated dereference coercion
assert_eq!(text, "signal");
assert_eq!(byte_count(concrete), 6);     // argument expects &str
```

Repeated `Deref` steps can reach `str`; they do not prove that arbitrary coercion
kinds compose transitively. The Reference explicitly says general transitivity is
not fully supported. For example, dereferencing a boxed array and unsizing the
array need an explicit boundary here:

```rust,compile_fail,E0308
let boxed = Box::new([3u8, 5, 8]);
let bytes: &[u8] = &boxed;
```

The source is `&Box<[u8; 3]>`, not an array reference. Make that reference explicit
and let array-to-slice unsizing occur at the annotated binding; no copy is needed:

```rust
let boxed = Box::new([3u8, 5, 8]);
let bytes: &[u8] = &*boxed;
assert_eq!(bytes, &[3, 5, 8]);
```

## 2. Trait bounds do not search coercible implementations

For a generic call, first write down the inferred type parameter and check the
bound for **that type**. An implementation for `&str` is not an implementation
for `&String`, even though the latter can coerce to the former at a suitable site.

```rust,compile_fail,E0277
trait Label { fn width(self) -> usize; }
impl Label for &str { fn width(self) -> usize { self.len() } }
fn width<T: Label>(value: T) -> usize { value.width() }
let name = String::from("reed");
let size = width(&name);                // inferred T = &String
```

Supply the intended target before trait matching, rather than adding an unrelated
implementation. These two calls establish the same `T = &str` contract:

```rust
trait Label { fn width(self) -> usize; }
impl Label for &str { fn width(self) -> usize { self.len() } }
fn width<T: Label>(value: T) -> usize { value.width() }
let name = String::from("reed");
let label: &str = &name;
assert_eq!(width(label), 4);
assert_eq!(width::<&str>(&name), 4);
```

This is a trait-selection barrier, not a claim that generic function arguments
never coerce. Once `T` is specified, the parameter has a known target type.

## 3. Function items retain identity until coerced

Each function item has its own zero-sized type, including its identity and type
arguments. Equal signatures do not make two item types equal. Compiler diagnostics
often show the identity in braces after the signature.

```rust,compile_fail,E0308
fn raise(n: i32) -> i32 { n + 1 }
fn lower(n: i32) -> i32 { n - 1 }
let mut operation = raise;              // the item type of raise
operation = lower;                     // a different item type
```

If replacement or homogeneous storage is intended, choose a function-pointer
signature at the first binding or collection construction:

```rust
fn raise(n: i32) -> i32 { n + 1 }
fn lower(n: i32) -> i32 { n - 1 }
let mut operation: fn(i32) -> i32 = raise;
assert_eq!(operation(6), 7);
operation = lower;
assert_eq!(operation(6), 5);
let operations: [fn(i32) -> i32; 2] = [raise, lower];
assert_eq!(operations.map(|f| f(6)), [7, 5]);
```

An unannotated `if`/`match` can also coerce compatible function items to a common
pointer type. Passing an item to a generic `F: Fn(...)` does **not** inherently
require that conversion. Do not erase identity unless the contract needs it.

## 4. Give branches and collection elements the intended target

Least-upper-bound coercion handles branch results and array elements; it is not
an unrestricted search for a trait shared by unrelated concrete types.

```rust,compile_fail,E0308
let count = 12u16;
let word = String::from("twelve");
let selected = if count > 0 { &count } else { &word };
```

Both values implement `Display`, but inference does not invent `&dyn Display`.
If display-only access is intended, supply that target where values meet:

```rust
use std::fmt::Display;
let count = 12u16;
let word = String::from("twelve");
let selected: &dyn Display = if count > 0 { &count } else { &word };
assert_eq!(selected.to_string(), "12");
let labels: [&dyn Display; 2] = [&count, &word];
assert_eq!(labels.map(|value| value.to_string()), ["12", "twelve"]);
```

The same diagnostic applies to `match` arms. For collections, establish the target
at element construction or explicitly map elements to that target. An already
constructed `Vec<&Concrete>` does not generally coerce into `Vec<&dyn Trait>`;
coercion does not recursively rewrite arbitrary generic containers.

## 5. Count reference layers separately from binding modes

Work outside-in: record the scrutinee type, each matched reference layer, the
current default binding mode, then the final binding type.

- A reference pattern `&p` / `&mut p` matches a reference layer and continues with
  its referent. It is not an instruction to borrow the binding.
- `ref name` / `ref mut name` chooses a borrowing binding mode for the matched
  place. It does not remove an existing reference layer.
- A function parameter's declared type determines what callers pass;
  `fn inspect(ref text: String)` still takes an owned `String`.

```rust
let number = 27u16;
let &copied = &number;
let ref extra = &number;
let _: u16 = copied;
let _: &&u16 = extra;
assert_eq!(copied, **extra);
let pair = (String::from("north"), 4u8);
let (name, rank) = &pair;                // ergonomic reference bindings
let _: &String = name;
let _: &u8 = rank;
assert_eq!((name.as_str(), *rank), ("north", 4));
```

### Edition 2024 match ergonomics (supplemental primary-source material)

This modern edition material supplements, rather than describes coverage in,
the source book. The default binding mode starts as `move`. Matching a reference
with a structural non-reference pattern, such as the tuple pattern above,
automatically dereferences it and updates the mode to `ref` or `ref mut`.
Encountering shared access keeps subsequent bindings shared; an ordinary bare
identifier does not itself trigger structural reference matching.

In edition 2024, explicit `mut`, `ref`, and `ref mut` binding modifiers are allowed
only while the default mode is `move`. Reference patterns `&` / `&mut` likewise
require that mode: they cannot follow an implicitly skipped reference layer.

```rust,compile_fail
let pair = (String::from("west"), 2u8);
let (ref name, _) = &pair;              // default mode already became ref
```

This is an edition restriction, not an extra-reference operation. The smallest
fix is to remove redundant `ref`: `let (name, _) = &pair;`. Alternatively, spell
out the leading reference to keep the prefix explicit:

```rust
let pair = (String::from("west"), 2u8);
let &(ref name, rank) = &pair;
assert_eq!(name, "west");
assert_eq!(rank, 2);
```

Before edition 2024, redundant explicit `ref`/`ref mut` was permitted; `mut` could
reset the binding mode to `move`, and reference patterns could reset it too.
Do not interpret an older-edition pattern using only the 2024 restrictions.

## 6. Resolve methods using each intermediate receiver

Dot-call lookup builds candidate receivers by repeated autodereferencing, then
an array-to-slice unsizing attempt, and inserts shared/mutable reference
candidates. This **autoderef/autoref** process is not ordinary argument coercion.
For instance, `String::from("ok").len()` can borrow its receiver automatically;
a free function taking `&str` still requires a borrowed argument, not a `String`.

For a failing chain, split at the first rejected step and record each return
and next receiver type. Finding a method does not grant the ownership, mutability,
or lifetime needed to call it:

```rust,compile_fail,E0507
let mut words = vec![String::from("blue")];
let bytes = words.last_mut().unwrap().into_bytes();
```

Here `last_mut()` returns `Option<&mut String>`, `unwrap()` returns `&mut String`,
and `String::into_bytes(self)` requires an owned `String`. Receiver adjustment
cannot move that non-`Copy` value out of borrowed storage. Preserve the collection
with a borrowed byte view, or, only if removal is intended, extract the owner:

```rust
let mut words = vec![String::from("blue")];
let borrowed: &[u8] = words.last().unwrap().as_bytes();
assert_eq!(borrowed, b"blue");
let owned: Vec<u8> = words.pop().unwrap().into_bytes();
assert_eq!(owned.as_slice(), b"blue");
assert!(words.is_empty());
```

A method returning `()` changes the next receiver to `()`; it does not prohibit
all further methods. Diagnose that immediate type, not the chain's original one.

## Primary sources

- [Reference: coercion sites, types, and LUB](https://doc.rust-lang.org/reference/type-coercions.html), including its transitivity caveat.
- [RFC 401: trait matching barrier](https://rust-lang.github.io/rfcs/0401-coercions.html#coercions); historical rationale, not authority for every current RFC example.
- [Reference: function item types](https://doc.rust-lang.org/reference/types/function-item.html).
- [Reference: binding modes](https://doc.rust-lang.org/reference/patterns.html#binding-modes) and [reference patterns](https://doc.rust-lang.org/reference/patterns.html#reference-patterns).
- [Edition Guide: Rust 2024 match ergonomics reservations](https://doc.rust-lang.org/edition-guide/rust-2024/match-ergonomics.html).
- [Reference: method-call receiver lookup](https://doc.rust-lang.org/reference/expressions/method-call-expr.html).
