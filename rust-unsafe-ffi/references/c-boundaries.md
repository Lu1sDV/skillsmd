# C boundaries: ABI, ownership, and callbacks

## Specify the interface before binding it

For each function, write down: exact C declaration and target calling convention;
scalar widths/signedness; pointer nullability, lengths, and ownership; whether
memory may be retained; failure/output rules; thread/reentrancy restrictions;
and panic/exception behavior. Rust cannot check an extern signature against a
header. A mismatch can compile and link and still be UB.
[Nomicon: calling foreign functions](https://doc.rust-lang.org/nomicon/ffi.html#calling-foreign-functions).

| Boundary choice | Guidance |
|---|---|
| C function | Match the target ABI with `extern "C"`; use `extern "system"` when the platform API requires it |
| Native shared/static Rust export | Build a `cdylib`/`staticlib`, not a Rust `dylib` as a stable C API |
| C `int`, `char`, `long` | Use the corresponding `std::ffi::c_*` aliases; do not assume C `char` is signed or `long` is always 64-bit |
| Fixed-width protocol field | Agree on `uint32_t`/`u32`, etc.; check the actual header instead of substituting `usize` |
| Rust-owned implementation object | Opaque pointer plus create/use/release operations; keep internal layout private |
| Buffer | Pointer plus explicitly documented element/byte count and capacity, or a struct of those fields |
| Nullable callback | `Option<unsafe extern "C" fn(...)>` when invocation has preconditions; no null function pointer values or transmute |
| C++ class/exception API | Use a deliberate C-compatible bridge, or an existing audited binding solution; `extern "C"` does not directly describe C++ object semantics |

[Sources: Nomicon FFI](https://doc.rust-lang.org/nomicon/ffi.html),
[C type aliases](https://doc.rust-lang.org/std/ffi/index.html).

### Layout is not validity

`#[repr(C)]` establishes field ordering/padding according to the target's C
representation, not a universal size across platforms. It does not recursively
change nested Rust types, stabilize `String`/`Vec`/trait-object layout, eliminate
padding, or make arbitrary bytes valid. `#[repr(transparent)]` can preserve a
suitable single field's layout/ABI, but does not erase a wrapper's invariants.
[Reference layout](https://doc.rust-lang.org/reference/type-layout.html).

Model extensible C enums/bitflags as integers at the raw boundary and validate
before constructing a Rust enum. Rust enums may hold only valid discriminants;
`repr(C)` does not change that. Likewise, receive untrusted boolean-like integers
as integers and validate rather than letting C fabricate an invalid Rust `bool`.
Read a union variant only when its tag/contract makes that field's value valid.
[Reference enum caveats](https://doc.rust-lang.org/reference/type-layout.html#reprc-field-less-enums),
[validity rules](https://doc.rust-lang.org/reference/behavior-considered-undefined.html#invalid-values).

Use `sizeof`, alignment, and field-offset checks on **both** sides for the actual
target/compiler flags. Avoid serializing struct padding or comparing it as
initialized bytes. Do not expose Rust references, slices, `&str`, `CStr`, `Result`,
or Rust ownership containers directly as a general-purpose C wire interface.
[CStr ABI caveat](https://doc.rust-lang.org/std/ffi/struct.CStr.html),
[Reference layout](https://doc.rust-lang.org/reference/type-layout.html).

## Complete safe-wrapper contract example

This is a real Rust-implemented C ABI operation with a safe Rust wrapper, not a
mock foreign function. It writes a checked `u32` sum into caller-owned storage.
A native library with this same documented output contract could be wrapped in
the same way, but its implementation/header must be audited separately. For
Rust-only arithmetic use `checked_add` directly, not this boundary layer.

Contract: status `0` means a valid `u32` was written; `1` means overflow and the
output was not touched. The output storage is borrowed only during the call;
there is no allocation, retained pointer, callback, or unwinding path. C callers
must meet the documented safety requirements, just like unsafe Rust callers.

```rust
#![deny(unsafe_op_in_unsafe_fn)]

use std::ffi::c_int;
use std::mem::MaybeUninit;

/// Writes a checked sum; returns 0 on success or 1 on overflow.
/// On overflow, leaves the output storage unchanged.
///
/// # Safety
/// `out` must be non-null, aligned, and writable for one u32 for this call.
/// It may be uninitialized. The caller must grant exclusive access to those
/// bytes for the call. This function never retains the pointer.
// SAFETY: This standalone example defines this prefixed symbol exactly once,
// with the C signature documented below; it does not replace a runtime symbol.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn skillsmd_checked_add_u32(
    left: u32,
    right: u32,
    out: *mut u32,
) -> c_int {
    match left.checked_add(right) {
        Some(value) => {
            // SAFETY: The caller provides exclusive, aligned, writable storage.
            // write initializes it without reading or dropping previous contents.
            unsafe { out.write(value) };
            0
        }
        None => 1,
    }
}

#[derive(Debug, PartialEq, Eq)]
enum AddError {
    Overflow,
}

fn add(left: u32, right: u32) -> Result<u32, AddError> {
    let mut out = MaybeUninit::<u32>::uninit();
    // SAFETY: out owns aligned storage for one u32. Nothing else accesses it
    // during this synchronous call, which does not retain the pointer.
    let status = unsafe { skillsmd_checked_add_u32(left, right, out.as_mut_ptr()) };
    if status == 0 {
        // SAFETY: The implementation's status-0 contract guarantees a complete
        // u32 write. The value is read only here, after successful initialization.
        Ok(unsafe { out.assume_init() })
    } else {
        // The implementation returns only 0 or 1; the error path never reads out.
        Err(AddError::Overflow)
    }
}

fn main() {
    assert_eq!(add(0, 0), Ok(0));
    assert_eq!(add(u32::MAX, 0), Ok(u32::MAX));
    assert_eq!(add(u32::MAX, 1), Err(AddError::Overflow));
    let mut unchanged = 37;
    // SAFETY: unchanged is valid aligned storage, borrowed exclusively here.
    let status = unsafe { skillsmd_checked_add_u32(u32::MAX, 1, &mut unchanged) };
    assert_eq!(status, 1);
    assert_eq!(unchanged, 37);
}
```

The wrapper proves allocation, alignment, aliasing, lifetime, initialization, and
failure behavior separately. Checking `status` would be insufficient if the
callee might overrun the output or claim success without initializing it.
[MaybeUninit output pointers](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html#out-pointers).

### Real C caller for this example

Save the complete Rust fence above as `wrapper.rs` and this complete C program as
`caller.c` in a scratch directory. This is a Linux native-linking recipe requiring
Rust 1.85+, a C11 compiler, and a compatible native linker; it is **not** part of
the dependency-free Rust doctest. It tests an actual ABI call in a separate C
translation unit, not just a Rust call using the C calling convention.

```c
#include <assert.h>
#include <stdint.h>

/* out must be aligned, writable, non-null, and exclusively accessible.
   Returns 0 and writes the sum, or 1 and leaves out unchanged. */
extern int skillsmd_checked_add_u32(uint32_t left, uint32_t right, uint32_t *out);

int main(void) {
    uint32_t out = 99;
    assert(skillsmd_checked_add_u32(0, 0, &out) == 0);
    assert(out == 0);
    assert(skillsmd_checked_add_u32(UINT32_MAX, 0, &out) == 0);
    assert(out == UINT32_MAX);
    assert(skillsmd_checked_add_u32(UINT32_MAX, 1, &out) == 1);
    assert(out == UINT32_MAX);
    return 0;
}
```

```sh
rustc --edition=2024 --crate-type=cdylib --crate-name rust_unsafe_ffi_demo wrapper.rs -o librust_unsafe_ffi_demo.so
cc -std=c11 -Wall -Wextra -Werror caller.c -L. -lrust_unsafe_ffi_demo -Wl,-rpath,'$ORIGIN' -o caller
./caller
```

For deployed APIs, keep the declaration and safety/ownership documentation in a
versioned header. Windows/macOS artifact names, export rules, and loader settings
need platform-specific build configuration.
[Nomicon: Rust from C](https://doc.rust-lang.org/nomicon/ffi.html#calling-rust-code-from-c).

## Ownership and lifetimes

- **Borrowed input:** The Rust owner remains alive and unmodified for the required
  access period. Passing a pointer from a temporary owner is unsafe if the owner
  dies before the foreign use. For retained pointers, an ordinary call-scoped
  borrow is insufficient; registration must own/pin appropriate storage or
  enforce a longer lifetime, including teardown.
- **Foreign-owned handle:** Keep the release function paired with the constructor.
  Use a private RAII wrapper, reject documented null/error results, and release
  exactly once. Review whether `Drop` must run on the creation thread and what
  happens on a failed construction. A raw pointer alone does not prove ownership.
- **Rust-owned transfer:** `Box::into_raw` relinquishes ownership; recover it with
  the matching `Box::from_raw` contract exactly once. Do not use C `free` on that
  pointer. A foreign allocation needs the foreign allocator's release operation,
  not an arbitrary `Box::from_raw` conversion.
- **Borrowed result:** Tie `&T`, `&[T]`, or `&CStr` to the owning handle's borrow.
  If another foreign call invalidates that storage, prevent such a call during
  the borrow or copy into an owned Rust value first.

[Sources: Nomicon ownership/destructors](https://doc.rust-lang.org/nomicon/ffi.html#destructors),
[Box raw ownership](https://doc.rust-lang.org/std/boxed/struct.Box.html#method.from_raw),
[CStr lifetime caveat](https://doc.rust-lang.org/std/ffi/struct.CStr.html#method.from_ptr).

### C strings and writable buffers

`CString::new` rejects interior NUL; `CString::as_ptr` borrows read-only memory.
Keep the owner alive and do not cast away constness for a C writer. A C string is
not necessarily UTF-8: use `to_str` for validation, `to_bytes` for bytes, or an
explicitly chosen lossy conversion. `CStr::from_ptr` requires non-null readable
memory through an in-allocation terminator, within its documented size bound,
and no mutation for the returned borrow. It cannot safely probe an arbitrary
pointer to see whether a terminator exists.
[Sources: CStr](https://doc.rust-lang.org/std/ffi/struct.CStr.html#method.from_ptr),
[CString](https://doc.rust-lang.org/std/ffi/struct.CString.html).

Use a bounded initialized buffer or a correctly managed `MaybeUninit` buffer for
foreign writes. Validate the produced length/termination only after the foreign
contract has ensured memory safety. When you already have a valid byte slice,
prefer safe `CStr::from_bytes_with_nul` / `from_bytes_until_nul`.

`CString::into_raw` transfers ownership. Returning it with `CString::from_raw`
requires the same allocation, exactly once, with its original string length:
foreign code must not insert an earlier NUL or remove/move the final NUL. This
is different from a freely mutable C allocation.
[Ownership contract](https://doc.rust-lang.org/std/ffi/struct.CString.html#method.from_raw).

This complete example exercises validation and a correct ownership round trip:

```rust
use std::ffi::{CStr, CString};

assert!(CString::new(b"a\0b".to_vec()).is_err());
assert!(CStr::from_bytes_with_nul(b"unterminated").is_err());
let bytes = CString::new(vec![0xff]).unwrap();
assert!(bytes.to_str().is_err()); // NUL-terminated is not the same as UTF-8.

let raw = CString::new("owned").unwrap().into_raw();
{
    // SAFETY: raw comes from a live CString allocation; no writer or other
    // owner exists, and its terminator is unchanged. This borrow ends here.
    let borrowed = unsafe { CStr::from_ptr(raw) };
    assert_eq!(borrowed.to_bytes(), b"owned");
}
// SAFETY: Same pointer from into_raw, unchanged length, no outstanding access,
// and this is the only ownership reclamation.
let owner = unsafe { CString::from_raw(raw) };
assert_eq!(owner.as_bytes_with_nul(), b"owned\0");
drop(owner);
```

## Callback lifetime and reentrancy

A function pointer plus `*mut c_void` context is the usual C-compatible closure
bridge. Keep the Rust closure/object in owned stable storage; a trait object's
fat pointer is not interchangeable with one C data pointer. Use a concrete
context type or another sized owner. The trampoline has the exact callback ABI,
checks documented optional cases, and recovers only the correctly typed context.
[Nomicon callbacks](https://doc.rust-lang.org/nomicon/ffi.html#targeting-callbacks-to-rust-objects).

Before offering a **safe** registration API, prove all of these:

1. Can registration fail after taking ownership or invoking the callback? Match
   the library's precise ownership transition on each status.
2. Is invocation synchronous, deferred, concurrent, or reentrant? An `FnMut`
   trampoline cannot create simultaneous `&mut` references to the same context.
   A non-reentrant mutex can deadlock if the callback recursively triggers itself.
   A normal safe recursive method is not inherently UB; conflicting accesses are.
3. Can foreign threads invoke it? Enforce the necessary `Send`/`Sync` bounds and
   synchronization, including destruction and library thread affinity.
4. Does unregister wait for all in-flight callbacks and prevent new ones? If not,
   add the library's required quiescence/join protocol **before** freeing context.
5. Is forgotten registration safe? A returned guard borrowing a stack closure
   cannot rely solely on `Drop` to unregister: safe `mem::forget` can let the stack
   value die while the callback remains. Own the context so forgetting leaks it,
   or use a scoped protocol that completes all callbacks before the scope returns.
6. Can the callback panic? Contain recoverable Rust panics inside the trampoline,
   or deliberately specify abort behavior. Do not let a C callback ABI silently
   determine an unintended application failure policy.

[Sources: asynchronous callbacks](https://doc.rust-lang.org/nomicon/ffi.html#asynchronous-callbacks),
[forget is safe](https://doc.rust-lang.org/std/mem/fn.forget.html#safety).

## Rust 2024 syntax and unwinding

- Declare imports with `unsafe extern "C" { ... }`. Foreign functions default
  to unsafe; an explicit `safe fn` declaration is justified only if **all** safe
  calls meet its contract. Correct signature/ABI is still the declaration
  author's responsibility. Do not mark C `abs(int)` universally safe without
  accounting for its minimum-integer overflow precondition.
  [Edition Guide: extern blocks](https://doc.rust-lang.org/edition-guide/rust-2024/unsafe-extern.html).
- Export names/link sections with `#[unsafe(no_mangle)]`,
  `#[unsafe(export_name = "...")]`, or `#[unsafe(link_section = "...")]`.
  Prove uniqueness and symbol/section compatibility; a distinctive prefix is a
  naming policy, not a proof that a linked dependency has no collision.
  [Edition Guide: attributes](https://doc.rust-lang.org/edition-guide/rust-2024/unsafe-attributes.html).
- `unsafe_op_in_unsafe_fn` warns by default in 2024. Use explicit small blocks
  inside unsafe functions and consider `#![deny(unsafe_op_in_unsafe_fn)]` to keep
  new operations visible. Migration tooling cannot verify the safety argument.
  [Edition Guide: unsafe operations](https://doc.rust-lang.org/edition-guide/rust-2024/unsafe-op-in-unsafe-fn.html).

| Situation | Consequence / policy |
|---|---|
| Rust panic reaches a non-unwinding `extern "C"` boundary | Process aborts; it is not simply “all FFI panics are UB” |
| Foreign exception enters through a non-unwinding ABI | UB; catch/translate it on the foreign side |
| Deliberate cross-language unwinding | Use matching `C-unwind` declarations/pointers and compatible code/runtimes throughout |
| `panic=abort` | `catch_unwind` cannot recover; the process aborts |
| Catching a foreign unwind with Rust `catch_unwind` | Not a portable exception adapter; current Reference permits abort or an opaque `Err`, unspecified which |
| Foreign `longjmp` skips Rust frames/destructors | Can violate Rust runtime assumptions; do not use it as error propagation across Rust frames |

Prefer explicit error statuses/results rather than panic-based expected failures.
If using `catch_unwind`, it must enclose the panicking **Rust implementation
inside** the boundary; a catcher outside an `extern "C"` function is too late.
Review panic payload destruction and any cleanup after the catch, too; those can
panic. Avoid blind `AssertUnwindSafe` that hides broken state invariants.
[Sources: Reference panic](https://doc.rust-lang.org/reference/panic.html#unwinding-across-ffi-boundaries),
[Nomicon unwinding](https://doc.rust-lang.org/nomicon/ffi.html#ffi-and-unwinding),
[Reference runtime assumptions](https://doc.rust-lang.org/reference/behavior-considered-undefined.html#r-undefined.runtime).

## Binding generation and build integration

`bindgen` generates Rust declarations from C headers; `cbindgen` generates C/C++
headers from a Rust API. Generated declarations are a raw layer, not proof of
ownership, callback teardown, thread safety, or unwinding. Match the target,
header version, include paths, preprocessor definitions, native compiler flags,
and generator version. Review regenerated diffs and keep Rust 2024 extern/unsafe
attribute syntax consistent with the selected generator and project edition.
[bindgen guide](https://rust-lang.github.io/rust-bindgen/),
[cbindgen documentation](https://github.com/mozilla/cbindgen).

Keep a small handwritten safe layer above generated bindings. Reuse the project's
native discovery/build conventions; link the real library and test its errors.
`safer_ffi` or an existing C++ bridge may help enforce supported representations,
but is an explicit dependency decision, not a substitute for these contracts.
Do not add a binding framework just for a few stable scalar functions.
