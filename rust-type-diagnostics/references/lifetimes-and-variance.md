# Lifetimes and variance: diagnose the relationship

Use this when an outlives obligation, nested reference, or callback signature is
rejected. For ordinary borrowing and elision, use `rust-idiomatic` instead.
Examples target edition 2024; these rules do not depend on changing editions.
No MSRV compatibility is asserted.

## Diagnostic order

1. Write the actual and expected types, including **each** nested lifetime.
2. Establish well-formedness: what must hold for the signature's types to exist?
   Collect explicit bounds and implied outlives bounds before adding new ones.
3. Separate lifetime obligations from ordinary trait obligations. A valid
   reference can imply `T: 'a`; it does not imply `T: Clone` or `T: Debug`.
4. Trace the parameter's position through every enclosing type. A longer borrow
   can substitute for a shorter one only where variance permits it.
5. For callbacks, distinguish one fixed input lifetime from `for<'a>`: the latter
   requires support for every input lifetime, including a borrow created locally.
6. Preserve the intended storage/callback contract. Do not add `'static`, clone,
   leak, or cast merely to bypass the rejected relationship.

## Well-formedness supplies outlives bounds, not arbitrary traits

For `&'a T` to be well formed, `T: 'a` must hold. That requirement is available
inside a function whose parameter or output contains this reference type.
Here `relay` needs no redundant explicit `T: 'a`:

```rust
fn require_outlives<'a, T: 'a>(value: &'a T) -> &'a T {
    value
}

fn relay<'a, T>(value: &'a T) -> &'a T {
    require_outlives(value)
}

let name = String::from("Mira");
assert_eq!(relay(&name).as_str(), "Mira");
```

An unrelated pair of parameters supplies no such evidence. This fails with
E0309 because nothing establishes `T: 'a`:

```rust,compile_fail,E0309
fn require_outlives<'a, T: 'a>() {}

fn missing_relationship<'a, T>() {
    require_outlives::<'a, T>();
}
```

The smallest fix, if this generic operation really requires the relationship,
is `fn missing_relationship<'a, T: 'a>()`. Do not invent an unused reference
parameter merely to make its well-formedness imply a needed bound.

In contrast, a type declaration's ordinary trait bound must be restated by a
function using that type. This rejection is E0277, not a lifetime failure:

```rust,compile_fail,E0277
struct CopySlot<T: Copy>(T);

fn read_slot<T>(slot: CopySlot<T>) -> T {
    slot.0
}
```

The fix makes the actual trait requirement explicit:

```rust
struct CopySlot<T: Copy>(T);

fn read_slot<T: Copy>(slot: CopySlot<T>) -> T {
    slot.0
}

assert_eq!(read_slot(CopySlot(37_u32)), 37);
```

Implied outlives requirements also arise from fields in type definitions and
from types in impl headers. Always connect the exact lifetime: merely declaring
`'a` beside `T` does not relate them, and an elided lifetime is not automatically
that named `'a`.

## `T: 'a` does not set a value's destruction time

A type outlives bound constrains borrowed content represented in `T`: its
lifetime parameters must outlive `'a`. It does not make a particular value stay
alive for `'a`. A separate `&'a T` also requires a valid borrow of that value.
An owned `String` satisfies `'static` without its local value living forever:

```rust
fn accept_static_type<T: 'static>(value: T) -> T {
    value
}

let length = {
    let temporary = accept_static_type(String::from("brief"));
    temporary.len()
}; // The String is dropped here, despite String: 'static.
assert_eq!(length, 5);
```

Lifetime parameters are erased for code generation; naming a lifetime does not
produce a machine-code specialization per borrow duration. This is distinct
from monomorphization over concrete type parameters. Neither elision nor
explicit lifetime syntax extends the backing storage's lifetime.

## Variance belongs to a parameter position

For `'long: 'short`, `&'long str` is a subtype of `&'short str`.
Covariance preserves this direction, contravariance reverses it, and invariance
permits neither substitution on that basis. Outlives includes equality.

| Type position | Variance |
|---|---|
| `&'a T` in `'a`, and in `T` | Covariant in both |
| `&'a mut T` in `'a` | Covariant |
| `&'a mut T` in `T` | Invariant |
| `Vec<T>` in `T` | Covariant |
| `fn(T) -> U` | Contravariant in `T`, covariant in `U` |

Trace nested positions rather than labeling a whole type “covariant.” For
`&'outer mut &'inner str`, the outer borrow can shorten, but the inner reference
is in the invariant referent position. For user-defined structs/enums, inspect
all fields; conflicting co-/contravariant uses make that parameter invariant.

Shortening mutable access without changing its referent type is permitted:

```rust
fn shorten<'long: 'short, 'short, T>(value: &'long mut T) -> &'short mut T {
    value
}

let mut count = 3;
*shorten(&mut count) += 4;
assert_eq!(count, 7);
```

### Why a mutable vector cannot have its element lifetime rewritten

The helper below correctly connects the inserted reference to the vector's
element lifetime. Its body is valid. The call fails with E0597 because the
explicit `Vec<&'static str>` fixes that lifetime to `'static`:

```rust,compile_fail,E0597
fn append<'a>(items: &mut Vec<&'a str>, item: &'a str) {
    items.push(item);
}

let mut items: Vec<&'static str> = vec!["fixed"];
let local = String::from("local");
append(&mut items, &local);
assert_eq!(items, ["fixed", "local"]);
```

Although `Vec<T>` is covariant in `T`, the surrounding `&mut` is invariant in
its referent. If `&mut Vec<&'static str>` could become a mutable vector of
shorter references, a caller could insert a short borrow into storage still
advertised as containing only static references. Shortening the **outer** borrow
cannot authorize that write.

If the intended vector holds local borrows, remove the unnecessary static
element annotation. Literal references can shorten to the inferred lifetime:

```rust
fn append<'a>(items: &mut Vec<&'a str>, item: &'a str) {
    items.push(item);
}

let local = String::from("local");
let mut items = vec!["fixed"];
append(&mut items, &local);
assert_eq!(items, ["fixed", "local"]);
assert_eq!(items.join("/"), "fixed/local");
```

If the vector really promises static elements, retain that contract and supply
static input instead. A lifetime annotation cannot extend `local`'s storage.

## Function inputs reverse substitutability; quantifiers add another rule

For a **fixed** `'short`, a function accepting `&'short str` can serve a caller
that promises to supply only `&'static str`. The inputs supplied by that caller
are valid for the callback. This is function-input contravariance:

```rust
fn restrict_input<'short>(callback: fn(&'short str) -> usize)
    -> fn(&'static str) -> usize
{
    callback
}

fn length(text: &str) -> usize {
    text.len()
}

assert_eq!(restrict_input(length)("ready"), 5);
```

Separately, `fn(&str) -> usize` means `for<'a> fn(&'a str) -> usize`, not one
unspecified short lifetime. A static-only callback does not satisfy that
universal requirement. The following assignment fails with E0308:

```rust,compile_fail,E0308
fn static_length(text: &'static str) -> usize {
    text.len()
}

let callback: for<'a> fn(&'a str) -> usize = static_length;
```

The smallest fix, if the callback only reads its argument, is to remove its
unnecessary static restriction. The caller below actually exercises a local
borrow; a literal-only test would not demonstrate why the generality matters:

```rust
fn measure_local(callback: for<'a> fn(&'a str) -> usize) -> usize {
    let text = String::from("local input");
    callback(&text)
}

fn length(text: &str) -> usize {
    text.len()
}

assert_eq!(measure_local(length), 11);
```

For a generic callable, the corresponding requirement is
`F: for<'a> Fn(&'a str) -> usize`. If the callback really stores only static
references, do not pretend it accepts arbitrary borrows: the caller's contract
must instead supply static data. Higher-ranked lifetimes are not runtime checks
and cannot make a local reference static.

## Primary references

- [Lifetime and implied bounds](https://doc.rust-lang.org/reference/trait-bounds.html#implied-bounds), including the distinction from ordinary trait bounds.
- [Lifetime bounds](https://doc.rust-lang.org/reference/trait-bounds.html#lifetime-bounds) and [higher-ranked trait bounds](https://doc.rust-lang.org/reference/trait-bounds.html#higher-ranked-trait-bounds).
- [Subtyping and variance](https://doc.rust-lang.org/reference/subtyping.html), including built-in parameter positions and higher-ranked subtyping.
- [Function pointer types](https://doc.rust-lang.org/reference/types/function-pointer.html).
