# Correctness and boundaries

## Failure policy

Distinguish absence (`Option`) from recoverable failure (`Result`); propagate with
`?` when policy is unchanged. Malformed external data and expected operational
failures should not become incidental `unwrap()` panics. A documented panic
precondition for programmer misuse can be legitimate: safe is not panic-free.

Prefer types that exclude invalid inputs; otherwise check at the boundary.
Validate offset/length arithmetic before indexing and choose explicit overflow
semantics. `debug_assert!` is only a diagnostic for independently established
invariants: neither required side effects nor a memory-safety proof may depend on
its execution.

## Mutation on error

For a caller-owned output buffer, specify one contract: unchanged on error,
partial progress with a reported usable length, or modified output to discard.
Test that exact promise. `Result<usize, E>` reports a length only on success unless
`E` carries progress. An ordinary `&mut [T]` already contains initialized values;
call the result a *written prefix*, not newly initialized storage.

Keep `Drop` nonpanicking. Offer explicit fallible finalization and alternatives to
blocking destruction when those behaviors matter.

## Unsafe and foreign interfaces

Prefer a safe implementation. Necessary unsafe code needs a narrow boundary and
a concrete proof for each operation's validity, alignment, initialization,
aliasing, lifetime, and thread requirements; comments must explain the proof.

Match the actual foreign ABI and layout: a C `long` is not universally `i64`.
Serialization instead needs specified widths and byte order. State allocator
ownership, release responsibility, callbacks, and unwind behavior. Neither
`repr(C)` nor a debug assertion proves that arbitrary bytes are valid Rust values.

Basis: API Guidelines [dependability](https://rust-lang.github.io/api-guidelines/dependability.html)
and [failure documentation](https://rust-lang.github.io/api-guidelines/documentation.html#c-failure);
[gist](https://gist.github.com/auser/c3161f55a8393faa8af5ddda68c6befa) §§4–5, 10, 14,
with corrected panic, buffer, and FFI interpretations.
