# Safety, initialization, and abstraction proofs

## Decide whether unsafe belongs here

An unsafe function declares obligations for its **caller**; an unsafe trait
provides obligations for its **implementor**; an unsafe block/impl records that
those obligations have been discharged. A safe abstraction must uphold its
invariants for arbitrary safe clients, including clients with surprising
`Clone`, `Drop`, comparison, or callback implementations.
[Nomicon: safe and unsafe interaction](https://doc.rust-lang.org/nomicon/safe-unsafe-meaning.html).

The familiar operations include raw-pointer dereferences, unsafe calls, mutable
static access, unsafe trait implementations, and union field reads. Writing a
union field does not by itself require unsafe; reading one requires proving the
result is valid for that field's type. The keyword is not permission to create
invalid values or bypass synchronization. Prefer `Mutex`, atomics, `OnceLock`, or
other safe state management to `static mut`.
[Reference: unsafety](https://doc.rust-lang.org/reference/unsafety.html),
[Reference: unions](https://doc.rust-lang.org/reference/items/unions.html).

A `debug_assert!` can document an invariant but must not be its only enforcer
before unsafe access in builds that disable it. Inspect the effective consumer
profile, not just this library's manifest; Cargo uses workspace-root profiles.
An independently established type/private invariant or unsafe caller contract
can make the assertion redundant. Do not infer a defect from lexical proximity.
[debug_assert contract](https://doc.rust-lang.org/std/macro.debug_assert.html),
[Cargo profile scope](https://doc.rust-lang.org/cargo/reference/profiles.html).

## Raw pointers: prove the operation, not the address

| Obligation | How to establish it | Common false proof |
|---|---|---|
| Allocation and extent | Derive from a live owner/reference; track accessible length and capacity independently | Non-null, plausible address, or two adjacent allocations |
| Alignment | Owner layout or explicit alignment guarantee; use `read_unaligned`/`write_unaligned` when appropriate | x86 happened to tolerate it |
| Initialized, valid `T` | A completed write of valid fields/elements; validate foreign integers before making restricted Rust types | Memory was allocated or filled with zero |
| Lifetime | Keep the owner alive, prevent reallocation, and bind returned reference lifetimes to the borrow | Invent `'static` through a cast or assume raw pointers extend lifetimes |
| Aliasing permissions | Shared immutable access, or exclusive mutable access, for the reference's live duration | A cast from `*const T` to `*mut T` grants mutability |
| Provenance | Derive the pointer from the relevant allocation with sufficient permissions | Equal numeric addresses imply interchangeable pointers |
| Thread safety | Synchronize conflicting accesses and obey foreign thread-affinity contracts | Volatile, `Arc`, or a raw pointer makes access atomic |

These are separate requirements. `NonNull::new` checks nullness, not liveness,
alignment, initialization, or ownership. Merely constructing `&*ptr` or
`&mut *ptr` incurs reference requirements even if no later read occurs.
[std pointer safety and conversion](https://doc.rust-lang.org/std/ptr/index.html#pointer-to-reference-conversion).

### Slices and pointer arithmetic

- `from_raw_parts` / `from_raw_parts_mut` require one allocation containing the
  whole range, initialized elements, non-null alignment even when length is zero
  or `T` is zero-sized, a byte size at most `isize::MAX`, and no address wrap.
  Mutable slices additionally exclude other accesses not derived from them for
  their lifetime. Handle a foreign `(NULL, 0)` convention before constructing a
  Rust reference; it is not a valid raw-slice constructor input.
  [Mutable slice contract](https://doc.rust-lang.org/std/slice/fn.from_raw_parts_mut.html).
- `add` / `offset` have in-bounds arithmetic obligations independent of a later
  dereference. A one-past-end pointer is useful but cannot be read as a nonzero
  sized value. `wrapping_add` / `wrapping_offset` relax arithmetic requirements,
  not access requirements; they do not make out-of-bounds memory readable.
  [Pointer provenance](https://doc.rust-lang.org/std/ptr/index.html#provenance).
- Do not join allocations into one slice just because their addresses happen
  to touch. Do not retain a `Vec::as_ptr` across a mutation that can reallocate.
  Keep the borrow/owner and the pointer's allowed range together.
  [Pointer allocation model](https://doc.rust-lang.org/std/ptr/index.html#allocation).

### Aliasing and provenance without folklore

Raw pointers may alias; that does not erase the restrictions of references from
which they were derived. A live shared reference prevents mutation of its bytes
except inside `UnsafeCell`. An exclusive reference excludes unrelated accesses.
Reborrows derived from it are normal; “two `&mut` values exist” alone is not a
complete explanation of a violation. Track derivation, which bytes are accessed,
and reference liveness. `UnsafeCell` is not a data-race exemption or a license
for multiple active exclusive references.
Include foreign callbacks that can access the same bytes while a Rust reference
is live; the foreign call does not suspend that reference's obligations.
[Reference aliasing rules](https://doc.rust-lang.org/reference/behavior-considered-undefined.html#r-undefined.alias).

Pointers carry permissions as well as addresses. Prefer keeping pointers as
pointers. For tagging/address adjustment, `addr`, `with_addr`, and `map_addr`
allow explicit strict-provenance workflows; clear tags before use and retain a
pointer with the right provenance. Do not claim every integer round-trip is
always UB: exposed-provenance APIs exist, but have different assumptions and
weaker tooling support. Neither approach revives a freed allocation or enlarges
access permissions. Exact semantics are still evolving.
[std provenance and APIs](https://doc.rust-lang.org/std/ptr/index.html#strict-provenance).

A raw pointer cast itself is not a read, a reference construction, or a proof of
validity. Dropping slice metadata does not shrink the underlying allocation to
one element; retain the actual bounds separately. By-value `transmute` requires
equal sizes and valid source/result values, not equal alignment of those values;
pointee alignment and ownership still matter. Prefer explicit byte conversions.
Union fields have no language-level active-field restriction: prove validity at
the read type, including initialization. An integer's accepting all bit patterns
does **not** permit reading uninitialized bytes or padding as that integer.
[transmute contract](https://doc.rust-lang.org/std/mem/fn.transmute.html),
[union reads](https://doc.rust-lang.org/reference/items/unions.html#reading-and-writing-union-fields),
[MaybeUninit invariants](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html#initialization-invariant).

### Packed data and hardware

Never create an unaligned reference as an intermediate step. For a packed field,
use `&raw const value.field` and an unaligned read, or copy an accessible field by
value. Formatting can implicitly borrow a field, so copy it into an aligned
local first. Prefer explicit byte decoding for serialized formats: C layout is
not a portable wire format.
[Reference: packed alignment](https://doc.rust-lang.org/reference/type-layout.html#the-alignment-modifiers).

`repr(packed)` changes alignment, not the unspecified Rust field order. When
interoperation genuinely requires both C ordering and packing, inspect
`repr(C, packed)` and the exact foreign layout; neither substitutes for a
portable byte decoder or makes an unaligned reference valid.

MMIO is a separate, target-specific contract: mapped register address, width,
alignment, access side effects, ordering, and exclusive device access. Use the
platform's established register API and required volatile operations, not a
repeatedly returned `&'static mut Registers`. Volatile is not atomic or a thread
synchronization mechanism. Volatile access outside Rust allocations has specific
hardware exceptions to ordinary pointer rules; those exceptions do not justify
ordinary heap/reference accesses.
[std volatile safety](https://doc.rust-lang.org/std/ptr/fn.read_volatile.html).

## Initialization and destruction

`MaybeUninit<T>` is storage that may not yet contain a valid `T`; it is not a
runtime initialization tracker. `MaybeUninit::zeroed()` is not generic default
construction. Zero is invalid for references and many ownership types, and an
uninitialized integer is not simply an arbitrary stable integer value.
[Initialization invariants](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html#initialization-invariant).

Use this transition discipline:

1. Allocate storage without claiming initialized values. Prefer `Vec::push`,
   `resize`, `Option<T>`, or safe constructors when they express the state.
2. Write a valid `T` with `MaybeUninit::write` or a justified raw `ptr::write`.
   Writing an uninitialized place by normal assignment can attempt to drop its
   old value. Do not form `&mut T` to initialize an invalid `T`.
3. Publish initialization only after the write succeeds. `assume_init`,
   `assume_init_ref`, and `assume_init_mut` require initialization already to be
   true; they cannot be used to obtain a reference for initial construction.
4. For a partially initialized array/buffer, track the exact initialized prefix.
   Clean that prefix on errors or panics with a guard; never drop uninitialized
   slots. Keep safe client callbacks outside transiently broken invariants.
5. Transfer ownership once. `MaybeUninit<T>` itself does not drop `T`; after
   `assume_init` the resulting `T` has normal destruction. After
   `assume_init_drop`, the slot is uninitialized again for your state machine.
   Do not read or drop it as `T` until it has been reinitialized.

[Sources: MaybeUninit examples and APIs](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html),
[raw read ownership](https://doc.rust-lang.org/std/ptr/fn.read.html#ownership-of-the-returned-value).

Destruction is the reverse transition. Before invoking a potentially panicking
element destructor, remove that element from metadata that would allow another
read/drop, or install an unwind guard that preserves memory safety. Audit custom
`clear`, truncate, iterators, and safe reuse after a caught panic, not just
construction. Memory safety after unwind is mandatory; transactional rollback
of logical state is a separate promise.
[drop_in_place example](https://doc.rust-lang.org/std/ptr/fn.drop_in_place.html),
[Nomicon exception safety](https://doc.rust-lang.org/nomicon/exception-safety.html).

For FFI output, the foreign contract must guarantee the writable bound **before**
the call. A returned `written <= capacity` check is useful but cannot undo an
out-of-bounds write that already happened. Assume initialization/set `Vec` length
only for a prefix the success contract guarantees was initialized. Failure may
leave output untouched or partially written; read/drop it only as documented.
Capacity is storage, not initialized length.

`ptr::read` bit-copies even non-`Copy` types; it does not invalidate the original
place for you. Both copies of a `String` cannot become independent owners.
Likewise, `copy_nonoverlapping` is not `Clone`: it requires non-overlapping ranges
and a coherent ownership transition. Prefer `mem::replace`, `mem::take`, or
`mem::swap` over manual move sequences.
[std raw read](https://doc.rust-lang.org/std/ptr/fn.read.html).

A small valid example shows initialization handing destruction to the owner.
`Option<T>` is preferable for ordinary application state; this example makes the
low-level transition and exactly-once destruction observable without UB:

```rust
use std::cell::Cell;
use std::mem::MaybeUninit;

struct Counted<'a>(&'a Cell<usize>);

impl Drop for Counted<'_> {
    fn drop(&mut self) {
        self.0.set(self.0.get() + 1);
    }
}

let drops = Cell::new(0);
let mut slot = MaybeUninit::uninit();
slot.write(Counted(&drops));
// SAFETY: write initialized this slot exactly once with a valid Counted.
// assume_init consumes the storage and transfers its value to one owner.
let owner = unsafe { slot.assume_init() };
assert_eq!(drops.get(), 0);
drop(owner);
assert_eq!(drops.get(), 1);
```

`ManuallyDrop<T>` suppresses destruction but still requires a valid `T`; it is
not uninitialized storage. Prefer ownership APIs such as `Box::into_raw` to
manually disassembling owners. If manual transfer is unavoidable, suppress the
old destructor before any step that could panic and produce two owners.
Safe callers can `mem::forget` your guard: leaks may be acceptable, dangling
borrowed callbacks are not. Safety must not rely on every returned guard being
dropped. [std forget safety](https://doc.rust-lang.org/std/mem/fn.forget.html).

Do not expose a manually dropped inner value through safe accessors or derived
`Debug`/`Clone`/comparison/hash implementations. Prefer `Option::take` or consuming
ownership APIs over a separate flag plus a zombie `ManuallyDrop` field. Rules for
moving a dropped `Box`-containing `ManuallyDrop` have changed across Rust versions;
this bundle's 1.85 baseline does not rely on newer allowances.
[ManuallyDrop hazards and version caveat](https://doc.rust-lang.org/std/mem/struct.ManuallyDrop.html).

For a forgettable proxy such as a draining iterator, establish a safe conservative
owner state **before** returning the proxy. Forgetting may leak more resources,
but cannot leave the owner claiming moved-out values are live. A destructor that
repairs invariants only on normal scope exit is insufficient.
[Nomicon leak amplification](https://doc.rust-lang.org/nomicon/leaking.html).

## Unsafe traits and pinning

- Mark a trait unsafe only when unsafe consumers need to rely on an implementor
  contract that safe code cannot enforce. Specify that contract precisely in
  `# Safety`; justify each implementation. A bad safe `Ord` or `Clone` impl may
  break logical expectations but must not be trusted to preserve memory safety.
  [Nomicon: unsafe traits](https://doc.rust-lang.org/nomicon/safe-unsafe-meaning.html).
  In particular, generic `Iterator::size_hint`/`ExactSizeIterator::len` and
  `Read::read` results are not unchecked bounds proofs. Safe implementations can
  lie or panic; count actual initialized elements and validate before unsafe use.
  `Read::read` also requires an initialized byte buffer: an implementation may
  inspect it. Do not reinterpret uninitialized `[MaybeUninit<u8>]` storage as
  `&mut [u8]` to obtain that buffer.
  [ExactSizeIterator](https://doc.rust-lang.org/std/iter/trait.ExactSizeIterator.html),
  [Read contract](https://doc.rust-lang.org/std/io/trait.Read.html#method.read).
- Prove `Send` and `Sync` separately: `Send` permits transferring ownership;
  `Sync` permits sharing `&T` between threads. Check pointee trait bounds,
  synchronization, foreign global state, callbacks, and which thread may drop
  the handle. `Arc` does not make an arbitrary pointee thread-safe. A pointer
  not being dereferenced in one method says nothing about the entire type's
  destructor and other methods. Prefer automatic traits through existing safe
  fields rather than unconditional unsafe impls.
  [Nomicon: Send and Sync](https://doc.rust-lang.org/nomicon/send-and-sync.html).
- A raw-pointer field does not carry a borrow lifetime. If a custom wrapper
  represents borrowing, encode it in the type and audit variance; an unconstrained
  returned lifetime is unsound. Do not use lifetime `transmute` to turn a
  short-lived allocation into long-lived storage.
  [std pointer conversion](https://doc.rust-lang.org/std/ptr/index.html#pointer-to-reference-conversion).
- Pinning establishes an address-stability contract for the pointee, not its
  heap buffers, and does not prevent all mutation. Moving a `String` handle is
  different from reallocating its buffer. Prefer offsets instead of stored
  self-references; if genuinely needed, audit `Unpin`, construction, projection,
  replacement, and the pinning drop guarantee together. `Pin<Box<T>>` alone
  does not make an arbitrary self-referential design sound.
  [std pin contract](https://doc.rust-lang.org/std/pin/index.html).
  Dropping a `Pin<&mut T>` does not end an established pinning obligation on a
  `!Unpin` pointee. Review structural projections and destruction before storage
  reuse, including panicking field destructors. Structural pinning requires the
  enclosing type not to be `repr(packed)`: packed fields may move for destruction
  rather than being dropped in place. Follow the structural-pinning requirements
  of the linked `Pin` contract, not a blanket ban on using `Pin` with `Unpin` data.

The Rust Reference explicitly describes its UB list as non-exhaustive. Distinguish
“this public function is unsound” from “every invocation immediately has UB.”
Do not execute a bad lifetime cast or invalid `bool` to illustrate the issue;
explain the violating safe call sequence and test the corrected abstraction.
[Reference: soundness and validity](https://doc.rust-lang.org/reference/behavior-considered-undefined.html).
