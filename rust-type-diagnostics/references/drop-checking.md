# Drop checking: identify the last possible use

Use when a compiler diagnostic mentions a borrow being used when an owner is
dropped, or when actual destruction timing contradicts a last-use assumption.
Ordinary moves and partial moves belong to `rust-idiomatic`; unsafe manual
cleanup, pinning implementations and FFI belong to `rust-unsafe-ffi`.

## Diagnostic sequence

1. Identify the owning value, its borrowed fields, and any `Drop` implementation.
   Distinguish dropping a reference from dropping the owner it points to.
2. Find the owner's actual drop scope or explicit move into `drop`. A last
   ordinary reference use does not automatically destroy an owning guard.
3. Read the compiler's later-use note. A destructor can use borrowed fields even
   if this particular implementation does not currently inspect them. Type
   checking does not generally specialize caller borrow rules to that body.
4. Check whether earlier destruction preserves the contract. Use a smaller
   owner scope or `drop(owner)` when the work is genuinely complete. If the
   resource must remain live, change access order or the ownership design instead.
5. Exercise the destructor's observable effect and the later access. Compilation
   alone cannot tell whether releasing a lock/resource earlier was intended.

## A destructor is a possible later borrow use

The following cannot inspect `count` while `Update` still owns its exclusive
borrow. `Drop` is allowed to mutate through that valid reference; the problem is
interleaving another access before its ownership obligation is finished.

```rust,compile_fail,E0502
struct Update<'a>(&'a mut u32);
impl Drop for Update<'_> {
    fn drop(&mut self) { *self.0 += 1; }
}

let mut count = 4;
let update = Update(&mut count);
assert_eq!(count, 4);
```

There is no later explicit use of `update`: its implicit scope-exit destructor
keeps the borrow relevant. Removing the `Drop` implementation makes this
particular example compile; it is not an acceptable application fix when that
cleanup is required.

Ending the owner scope first both satisfies the rule and makes the mutation
observable. This is a safe lifetime/design fix, not a drop-check bypass.

```rust
struct Update<'a>(&'a mut u32);
impl Drop for Update<'_> {
    fn drop(&mut self) { *self.0 += 1; }
}

let mut count = 4;
{
    let _update = Update(&mut count);
}
assert_eq!(count, 5);
```

A type's own `Drop` also prevents directly moving out its non-`Copy` fields.
Do not remove required cleanup to permit a partial move. Use the existing
ownership contract (for example a meaningful replacement value) and route the
ordinary field-extraction decision to `rust-idiomatic`.

## Declaration order is not a universal reverse-creation rule

| Object | Relevant destruction rule |
|---|---|
| Local bindings leaving one scope | Reverse declaration order |
| Temporaries leaving their drop scope | Reverse creation order within that scope |
| A value with its own `Drop` | Its `Drop::drop` runs before its fields are recursively dropped |
| Struct/active enum fields | Field declaration order, not initializer order |
| Tuple elements; array/owned-slice elements | Element order |
| `Vec` elements | No stable guarantee of element destruction order |

Moving a value transfers the cleanup obligation to its new owner. Overwriting
an initialized place drops the old value. Consequently, lexical declaration
order alone does not describe all destruction in a program.

The example below separates local-binding order from field order and deliberately
initializes the fields in the opposite order to their declarations.

```rust
use std::cell::RefCell;

struct Trace<'a>(&'static str, &'a RefCell<Vec<&'static str>>);
impl Drop for Trace<'_> {
    fn drop(&mut self) { self.1.borrow_mut().push(self.0); }
}
struct Pair<'a> {
    first: Trace<'a>,
    second: Trace<'a>,
}

let events = RefCell::new(Vec::new());
{
    let _early = Trace("early", &events);
    let _pair = Pair {
        second: Trace("second field", &events),
        first: Trace("first field", &events),
    };
    let _late = Trace("late", &events);
}
assert_eq!(*events.borrow(), ["late", "first field", "second field", "early"]);
```

This asserts field/local rules, **not** the order of dropping items in a vector.
The vector is only an observation log. Never promote a particular `Vec` run's
printed order into a stable API guarantee.

## Temporary scopes depend on syntax and edition

Separate temporary lifetime extension from ordinary borrow inference. A borrow
of a temporary in one initializer can live differently from an apparently
similar reference obtained through a function call. Consult the exact expression
and edition rather than adding an annotation to a dangling-reference problem.

**Rust 2024:** `if let` scrutinee temporaries end before the `else` block, and
block-tail temporaries have narrower scopes than in earlier editions. This is
supplementary language guidance, not a rule established by the book's examples.

The `None` branch here requires the shared runtime borrow to have ended before
taking the mutable borrow. This deliberately runs as edition 2024:

```rust,edition2024
use std::cell::RefCell;

let state = RefCell::new(None::<u32>);
if let Some(value) = *state.borrow() {
    assert_eq!(value, 9);
} else {
    *state.borrow_mut() = Some(9);
}
assert_eq!(*state.borrow(), Some(9));
```

On earlier editions, the scrutinee's `Ref` can remain live through `else` and
make this path panic. A contract-preserving fix can explicitly finish the read
in an earlier statement, rather than changing the project's edition:

```rust
use std::cell::RefCell;

let state = RefCell::new(None::<u32>);
let needs_value = state.borrow().is_none();
if needs_value {
    *state.borrow_mut() = Some(9);
}
assert_eq!(*state.borrow(), Some(9));
```

## Gotchas and boundaries

- `drop(&owner)` drops a reference, not the owned resource. `_guard` is a binding;
  a wildcard pattern `_` is not a named owner retaining a newly produced guard.
- NLL can end a borrow before scope exit; it does not automatically run an
  owner's destructor at its last source-level use.
- `#[may_dangle]` is an unstable **unsafe promise**, not a way to tell the
  compiler to ignore a real use. Do not use it to repair safe application code.
- `mem::forget` leaks cleanup obligations; it is not ordinary early release.
  Never recommend it as a default benchmarking technique or borrow-check fix.
- `ManuallyDrop` suppresses automatic cleanup; it does not remove validity,
  aliasing or exactly-once-destruction obligations. Hand off that implementation.
- Do not promise destructors run on abort or process termination. `catch_unwind`
  catches unwinding panics, not aborts, and does not roll back state or guarantee
  successful cleanup. A second escaping panic during unwinding can abort.
- `(value, &value)` either borrows an outer value while copying the first element
  or conflicts with moving it; it does not construct a self-reference by magic.
  A sound self-referential abstraction requires a separate design review.

Primary references:
- [Drop checking and its unsafe escape hatch](https://doc.rust-lang.org/nomicon/dropck.html)
- [Destructors, drop scopes and temporary lifetime extension](https://doc.rust-lang.org/reference/destructors.html)
- [Vec guarantees](https://doc.rust-lang.org/std/vec/struct.Vec.html#guarantees)
- [Panic recovery limitations](https://doc.rust-lang.org/std/panic/fn.catch_unwind.html)

Book origin: Chapter 9's drop checking and destruction-order questions. Unsafe
escape-hatch recipes, self-reference generalizations and leaking benchmarks are
not adopted; see [sources](sources.md).
