# Language and ownership

## Syntax with intent

| Construct | Use / boundary |
|---|---|
| `let`, `let mut`, shadowing | Bind immutable by default; shadowing makes a new binding and can change type |
| `[T; N]`, `&[T]`, `Vec<T>` | Fixed-size owned array, borrowed sequence, growable owned sequence |
| `usize` / `isize` | Target-sized integers; convert external lengths/indexes with validation |
| `if`, `match`, block tail | Expressions return a value; a trailing semicolon makes a statement |
| `0..n` / `0..=n` | Half-open / inclusive range; choose endpoints deliberately |
| `loop { break value; }` | Produce a value from a loop; labels target enclosing loops |
| `match` | Exhaustive branching; guards do not establish exhaustiveness |
| `if let` / `while let` | One interesting pattern / repeated extraction |
| `let PATTERN = value else { return ...; };` | Early exit; else must diverge; requires Rust 1.65+ |
| `struct`, tuple struct, enum | Named product, wrapper, alternatives with associated data |
| `impl Type`, `Self`, `self` | Associated functions and methods; receiver chooses borrow/mutation/consumption |
| `trait`, `impl Trait for Type`, `where` | State required behavior; keep bounds no stronger than operations need |
| `use`, `mod`, `pub(crate)` | Import names, declare modules, restrict visibility to the crate |

A `const` denotes a constant value; a `static` denotes a program-lifetime storage
location. Neither implies interior mutation is safe. `char` is one Unicode scalar;
`b'x'` is a byte. Integer/float inference often defaults to `i32`/`f64`, but context
can change it; annotate at parsing and numeric boundaries.

A trait implementation may supply associated types and methods. Derive routine
traits only when field-wise semantics are right. `Eq` can be implemented manually
but promises reflexive equality; floats with NaN do not implement it. `Hash` must
agree with equality, and `Ord::cmp == Equal` must agree with `Eq`. Architecture,
dyn compatibility and domain wrappers belong to optional **rust-api-design**.

```rust
trait Measure {
    fn bytes(&self) -> usize;
}
impl Measure for str {
    fn bytes(&self) -> usize { self.len() }
}
fn nonempty<T: Measure + ?Sized>(value: &T) -> bool {
    value.bytes() != 0
}
assert!(nonempty("é"));
assert!(!nonempty(""));
```

`?Sized` relaxes the normally implicit `Sized` bound, letting the borrowed generic
accept `str`. Argument `impl Trait` expresses a generic bound; return `impl Trait`
hides one concrete return type, not arbitrary unrelated types from each branch.

## Choose ownership before choosing a pointer

| Requirement | Representation |
|---|---|
| Inspect data during a call | `&T`, often `&str`, `&[T]`, `&Path` |
| Mutate existing data exclusively | `&mut T` |
| Retain beyond the caller's borrow or consume a resource | Owned `T` |
| Indirection / recursive sized layout / owned trait object | `Box<T>` |
| Genuinely shared single-thread ownership | `Rc<T>`; `Weak<T>` for non-owning links |
| Share ownership between threads | `Arc<T>` with appropriate `Send`/`Sync` bounds; hand off concurrency design |
| Return borrowed data sometimes, owned data other times | `Cow<'a, str>` when that contract is useful |

`Rc::clone` and `Arc::clone` clone a handle, not `T`. Reference cycles can leak;
`Weak::upgrade` returns `None` after the last strong owner disappears. `Arc` does
not make arbitrary `T` thread-safe. `&T` is `Copy`; `&mut T` is not. An owned value
is dropped when its owning scope ends or it is explicitly consumed by `drop`,
unless moved elsewhere. Scope-based resource management does not mean destructors
run after process abort/exit or that flush errors can be reported from `Drop`.

`Cell<T>` moves values in/out without exposing references: `get` requires `Copy`,
but `set` and `replace` also work for non-`Copy` values. `RefCell<T>` dynamically
checks borrows; conflicting `borrow`/`borrow_mut` calls panic. Use `try_borrow*`
when conflicts are an expected error, not to conceal a broken ownership design.
Neither is a replacement for cross-thread synchronization.

## Diagnose compiler errors at the owner

| Diagnostic | Inspect first | Usual solution |
|---|---|---|
| E0382 moved value | Which use transfers ownership? | Borrow, reorder, or move once; clone only for independent ownership |
| E0505 move while borrowed | Later reference use | Finish borrowed work before moving or pass a borrow |
| E0502/E0499 overlapping access | Which borrow still has a future use? | Shorten scope, split disjoint data, `iter_mut`, `entry` |
| E0507 move out of borrowed content | Is removal intended? | Borrow; `Option::take`, `mem::take`/`replace`, or collection removal |
| E0597/E0515 insufficient lifetime | Who owns the returned data? | Return ownership or a reference tied to an input |
| E0106 missing lifetime | Ambiguous output/input relation | Annotate actual relation, not every reference with one lifetime |

Do not move a `String` out of `v[i]`: indexing borrows the element. If ownership
must transfer, use `pop`, `remove`, `swap_remove` (changes order), or consume the
collection. Borrow with `first`/`get` if removal is not the contract.

### Partial moves and reborrows

Moving one non-`Copy` field leaves unmoved fields usable, including other
non-`Copy` fields. The whole struct cannot be used until reinitialized. Struct
update syntax can also move fields. A type with its own `Drop` implementation
cannot have non-`Copy` fields moved out directly; replace the field with a valid
value instead. These are field/ownership rules, not stack-versus-heap rules.

```rust
struct Record { name: String, note: String }
let record = Record { name: "Ada".into(), note: "active".into() };
let name = record.name;
assert_eq!(name, "Ada");
assert_eq!(record.note, "active");

let mut text = String::from("a");
let original = &mut text;
let shorter = &mut *original;
shorter.push('b');
original.push('c'); // Legal: shorter has no later use.
assert_eq!(text, "abc");

let mut values = [1, 2, 3];
let (left, right) = values.split_at_mut(1);
left[0] += right[0];
assert_eq!(values, [3, 2, 3]);
```

This deliberately fails: the whole value is needed after its name was moved.

```rust,compile_fail
#[derive(Debug)]
struct Record { name: String, count: usize }
let record = Record { name: "Ada".into(), count: 1 };
let name = record.name;
println!("{record:?} {name}");
```

## Lifetimes: constraints, not storage management

A borrow lasts as long as required by its uses, subject to drop and control-flow
constraints. Non-lexical lifetimes often end a borrow at last use; this does not
early-drop a `RefMut`, lock guard, or owner. Use an explicit block or `drop(guard)`
when resource release matters.

Elision gives each input reference its own lifetime; with exactly one input
lifetime, output references use it. In a method, elided outputs use the `&self` or
`&mut self` receiver's lifetime. Multiple possible sources require a relation:
`fn choose<'a>(a: &'a str, b: &'a str) -> &'a str` permits the caller to use the
result only within a common valid borrow region. It does not make the original
owners live equally long and cannot extend the shorter-lived input.

`'a: 'b` means `'a` outlives `'b`. `T: 'a` means the lifetimes contained in `T`
outlive `'a`, not that this particular value stays alive until then. `String`
satisfies `T: 'static` and can be dropped immediately; a borrow of a local string
does not. A `&'static str` refers to program-lifetime data but the reference binding
itself can be short-lived. Never leak data merely to satisfy a bound.

Higher-ranked bounds quantify over *any* input borrow lifetime.
`Fn(&str) -> &str` already has the elided higher-ranked relationship below;
spelling `for<'a>` explicitly is not a magical fix for identical semantics. If
closure inference is too narrow, a named function or expected function type can
state the intended relationship.

```rust
fn apply<F>(f: F) -> String
where F: for<'a> Fn(&'a str) -> &'a str,
{
    let owned = String::from("  useful  ");
    f(&owned).to_owned() // Return ownership, not a reference to this local.
}
fn trim(s: &str) -> &str { s.trim() }
assert_eq!(apply(trim), "useful");
```

`move` closures capture by value but may capture a reference value; they are not
automatically `'static`. The body determines `Fn`/`FnMut`/`FnOnce`: consuming a
capture may make the closure callable only once. A noncapturing closure can
coerce to a function pointer; a capturing closure cannot.

For self-referential data, keep owned data and validated offsets/IDs, or borrow
from an external owner. Moving a `String` handle does not relocate its heap
buffer, but mutation can reallocate it and safe construction still cannot express
an unrestricted owner plus a borrow into itself. Pinning the outer struct alone
does not prohibit buffer mutation. Do not introduce raw pointers or `Pin` as a
casual borrow-checker workaround.

## Sources

Adapted chapter coverage: upstream 01 syntax, 02 ownership, 05 basic trait idioms,
and 13 ownership/lifetime traps; pinned links in the [source map](../README.md#sources-and-adaptation).
Authoritative semantics:
- [Partial moves](https://doc.rust-lang.org/rust-by-example/scope/move/partial_move.html)
- [Lifetime bounds and HRTBs](https://doc.rust-lang.org/reference/trait-bounds.html)
- [Lifetime elision](https://doc.rust-lang.org/reference/lifetime-elision.html)
- [Cell](https://doc.rust-lang.org/std/cell/struct.Cell.html) and [RefCell](https://doc.rust-lang.org/std/cell/struct.RefCell.html)
- [Closure types](https://doc.rust-lang.org/reference/types/closure.html)
