---
name: rust-fast
description: >
  Use when writing or reviewing Rust code that must be fast, or when a code
  review asks "is this idiomatic-performant Rust?". Covers the allocation,
  iterator, data-layout, hashing, async/concurrency, allocator, and build-profile
  decisions that make code fast by construction, plus the clippy lints that
  catch the common ones. Also the myths to stop repeating: iterators are not
  slower than loops, clone is not automatically bad, a faster hasher is not a
  faster program. Triggers: hot path, zero-copy, with_capacity, SmallVec,
  Cow, size_hint, bounds check, monomorphization, target-cpu, clippy::perf,
  await_holding_lock, spawn_blocking, rayon, parking_lot, code review, PR review.
---

# Writing Fast Rust

Fast Rust is written, not patched. Most Rust performance is decided by a dozen
small choices made while typing: how many times you allocate, how wide your hot
types are, whether a lock or an await sits on the path, and what the release
profile does. This skill is the write-time and review-time decision list.

For the other half — profiling a slow binary, baselining, benchmarking,
proving a win — use the `rust-performance` skill. This one assumes you are
writing or reviewing code, and that some of the hot path is known.

**The one rule: don't apply any of this to cold code.** Every rule below costs
readability. A rule earns its cost in code that runs a lot. If you cannot name
the path it speeds up, write the readable version.

## Quick Reference: mistakes and fixes

| Mistake | Cost | Fix |
|---|---|---|
| `clone()` to get past the borrow checker, reflexively | allocation + copy per call | borrow; keep clone only where measured |
| `Vec::new()` then `push` in a loop | realloc at caps 0,4,8,16,32,… | `with_capacity(n)` when n is known |
| `Vec::new()` + `resize(n, 0)` | alloc + separate memset | `vec![0; n]` (uses `alloc_zeroed`) |
| Building a `Vec` per loop iteration | one alloc per iteration | hoist the `Vec` out, `clear()` each pass |
| `.lines()` over a file | one `String` alloc per line | `read_line` into a reused buffer |
| `format!` on a hot path | `String` alloc | literal, or `format_args!` into a reused buffer |
| `to_owned()`/`to_string()` in a signature | alloc per call | take `&str` + a lifetime |
| `Box<Rc<T>>`, `Arc<&T>`, nested smart pointers | extra indirection, extra word | flatten to one owner |
| `collect()` into a `Vec` you only iterate | alloc for nothing | return `impl Iterator` |
| Custom iterator with no `size_hint` | repeated realloc on `collect` | implement `size_hint` |
| `filter(..).map(..)` in a measured bottleneck | adapter overhead may survive optimization | benchmark equivalent `filter_map`, preserving predicate and output |
| `chunks()` when the size divides evenly | remainder branch per chunk | `chunks_exact` |
| Iterating `&T` for small `Copy` types | worse codegen than by-value | `iter().copied()` |
| Per-element `next()` across an abstraction edge | blocks unrolling/SIMD | batch (e.g. 512) and iterate an array |
| `LinkedList`/`Box`-chains for sequence data | pointer chase per step | `Vec`/`VecDeque`/`SmallVec` |
| Large hot enum variant | larger values and potentially costly moves | measure layout costs and variant frequency before boxing |
| 64-bit indices for values that fit in 8 bits | 8× the storage per index | narrow the index type |
| Bit-packing a record for cache density | unpack work in the hot loop | measure both; packing can lose 30% |
| Default SipHash for internal, trusted keys | hash cost on every map op | `rustc-hash`, benchmark before switching |
| One shared atomic counter across threads | cache-line ping-pong | per-thread counters, reduce at the end |
| Blocking or CPU-heavy work on a Tokio worker | starves other tasks | `spawn_blocking`; bound CPU concurrency or use Rayon |
| Unbounded channel in front of a slow consumer | grows until OOM/abort | bounded `mpsc::channel(n)` |
| `MutexGuard` held across `.await` | makes the future non-`Send`; can deadlock a worker | scope the lock, or an async mutex |
| `spawn` per trivial item | scheduler overhead > work | batch items per task |
| Blindly enabling `lto = "fat"` | long link, may not help | `lto = "thin"` first, measure |
| Lock-free/`unsafe`/SIMD before the simple fix | bugs + build time for a cold win | profile first |

## Allocation

Allocations are moderately expensive: a global lock, allocator bookkeeping,
possibly a syscall. Small allocations are not automatically cheaper than large
ones. From rustc's own experience, removing **10 allocations per million
instructions** is worth roughly **1%** — real, but not a rewrite.

1. **Reserve when the size is known.** Growth is quasi-doubling, and the first
   capacity depends on element size — current `RawVec` starts at 8 elements for
   1-byte types and 4 for most others, then doubles. Filling a 20-element vector
   of a moderate-size type by `push` therefore costs four allocations;
   `Vec::with_capacity(20)` costs one. The exact sequence is an implementation
   detail, not a guarantee.
2. **Hoist buffers out of loops.** A "workhorse" `Vec` declared outside the loop
   and `clear()`ed each iteration keeps its capacity and allocates zero times
   steady-state. Same trick for a reused `String` and `read_line`, instead of
   `BufRead::lines()` which returns `io::Result<String>` and allocates per line.
3. **Pass `&mut Vec`, don't return a new one**, when a function builds up a
   collection the caller already owns.
4. **`clone_from` reuses the destination's allocation.** `a.clone_from(&b)` beats
   `a = b.clone()` when `a` already has capacity to spare.
5. **`Rc`/`Arc::clone` is a refcount bump, not a copy.** Sharing one large value
   behind an `Arc` beats deep-cloning it — unless the value is rarely shared, in
   which case the refcount adds an allocation that plain ownership wouldn't need.
6. **`Cow` for mixed borrowed/owned data.** `Vec<Cow<'static, str>>` holds
   literals for free and only allocates for the formatted ones. Call `to_mut`
   only in the branch that needs mutable access: it clones immediately if the
   value is still borrowed, even if you never write through the reference.
7. **`SmallVec<[T; N]>` for many short vectors** — inline storage up to `N`, then
   spill to heap. It is *slightly slower than `Vec` for ordinary operations*
   (every op checks inline-vs-heap) and makes the struct bigger when `N` or `T`
   is large. If you know the exact maximum length, `ArrayVec` is faster because
   it never falls back. Measure before adopting either.
8. **Give custom iterators a `size_hint`.** `collect` uses it to reserve in one
   shot. Give the tightest truthful bound; never claim an exact count for a
   filter you haven't evaluated.

## Iterators

**Myth: iterators are slower than `for` loops.** The Rust Book benchmarks both
over the same input: `19,620,300 ns` for the explicit loop vs `19,234,900 ns`
for the iterator chain — the same, within noise. Iterators are zero-cost; prefer
the clearer one.

**But zero-cost means "no cost versus equivalent hand-written code", not "the
optimization opportunity survives".** Where the abstraction boundary itself is
the problem, batch. Measured: a merge iterator driven with one `next()` call per
item took 6.5 ms over 100k integers; batched at 512 and traversed as a plain
array it took ~110 µs — **60×** — because the per-item call serialized the work
and blocked unrolling and SIMD.

Micro-choices that do matter inside a genuinely hot iterator:

- Benchmark an equivalent `filter_map` against `filter(p).map(f)`; preserve
  the predicate and output type, including any `Option` returned by `f`.
- Avoid `chain` in hot iterators; it is slower than a single iterator.
- `chunks_exact` over `chunks` when the size divides the slice evenly.
- `iter().copied()` over `iter()` for small integer types — by-value beats
  by-reference in the generated code.
- Return `impl Iterator` from a function instead of a `Vec` when the caller
  only iterates.

## Data layout and types

- **Large types can make moves expensive.** Whether a move becomes a `memcpy`
  call, inline instructions, or is eliminated depends on compiler, target, and
  context; 128 bytes is not a portable cutoff. Measure copying and layout costs.
  Boxing a large enum variant can shrink the enum, but adds allocation and
  indirection, especially costly when that variant is common. Apply
  `large_enum_variant` and `result_large_err` suggestions only after considering
  variant frequency and measuring the tradeoff.
- **Contiguous over pointer-chasing.** `Vec`/`VecDeque`/`Box<[T]>` over
  `LinkedList`, `Vec<Box<T>>`, or linked `Box` chains.
- **Flatten nesting and narrow indices.** In one measured case, replacing
  `Vec<Vec<usize>>` with two flat `Box<[u8]>` lists shrank a sample record from
  216 to 48 bytes and the working set from 5.7× the text input down, for up to
  **20%** runtime.
- **Cache misses are not the only objective.** Bit-packing one dataset's ranking
  payload into three bytes cut measured data-cache misses and made execution
  **at least 30% slower** — the unpack work in the hot loop cost more than the
  misses saved. Measure end-to-end, never proxies.
- **Sorting helps branches and can hurt locality.** Reading pre-sorted input cut
  branch misses and gave ~14% in one benchmark. Sorting the already-allocated
  root objects instead also came out faster (~5%) than the unsorted baseline, but
  raised LLC-load misses **14×**, so it lost to reading pre-sorted input. The
  extra cache pressure ate most of the branch-prediction win. If you sort for
  locality, say so in a comment — it's fragile.

## Hashing

The default `HashMap` hasher is SipHash 1-3: collision-resistant and
deliberately slow, especially for short and integer keys. Measured inside rustc:
`fnv → fxhash` gave **up to 6%** faster, but `fxhash → ahash` was **1–4%
slower** and `fxhash → default` was **4–84% slower**. Faster is not better —
measure your key distribution.

Switch only when profiling says hashing is hot, and never for keys an untrusted
party controls (the DoS resistance is the point of the default).

## Concurrency and async

- **A mutex can beat a naive atomic under contention.** One shared counter:
  2 threads → atomics ~5× faster; 8 threads → mutex ~1.34× faster, because
  cache-line ownership handoff dominates when every thread hammers the same
  line. The mutex arbitrates and reduces simultaneous hammering. Fix the
  sharing rather than the primitive: per-thread counters merged at the end, then
  the atomic is uncontended again.
- **There is no universally faster mutex.** Short critical sections and moderate
  contention favored `std` (**9%** higher throughput in one benchmark).
  Bursty loads favored `parking_lot` (**18.5%** higher throughput). Where a
  thread holds the lock for 500 µs, `std` starved other threads (95% variation)
  and `parking_lot` did not (1.9%) at the cost of ~7.5% throughput — its
  eventual-fairness handoff fires around 0.5 ms. Sleeping or doing I/O under a
  lock is the actual bug in that scenario.
- **Tokio is not preemptive.** Bound uninterrupted work between yields, not
  total task lifetime: long-lived async tasks are fine when they yield regularly.
  Move blocking operations to `spawn_blocking`. For many CPU-heavy jobs, limit
  concurrency with a semaphore or use a bounded CPU executor such as Rayon;
  the blocking pool's large default thread limit is not a CPU concurrency budget.
- **Bounded channels.** An unbounded channel has no backpressure and buffers
  until memory is exhausted — the only bound is the machine, and exhaustion can
  abort the process. Use `mpsc::channel(n)` and pick `n` from the workload.
- **Never hold a `MutexGuard` across `.await`** (nor a `RefCell` borrow). Scope
  the lock, or use an async-aware mutex. This is a correctness bug first.
- **Don't `block_on` inside a runtime worker**, and don't spawn a task per
  trivial item — batch. Worker count defaults to one per CPU core; only override
  it after measuring, and remember container CPU quotas.
- **Rayon has no magic threshold.** Trivial work can lose outright: a forum
  report of a 50k `i32` sum showed the sequential version ~9× faster, and a
  separate participant's playground check showed the sequential sum constant-fold
  to a single `mov` while Rayon kept its scheduling machinery. Tuning splitting is
  not one-directional either: `with_max_len(1)` measured **2× slower than a
  specialized custom pool** on random input while helping skewed input. Tune
  `with_min_len`/`with_max_len` against a real workload.

## Build and compile configuration

Only the workspace-root `Cargo.toml` profile settings apply.

| Setting | Effect |
|---|---|
| `--release` vs dev | 10–100×. Never tune a debug build |
| `codegen-units = 1` | better runtime and smaller binary, slower compile (default: 256 incremental / 16 otherwise) |
| `lto = "thin"` | 10–20% possible, substantially faster to link than fat |
| `lto = "fat"` | more aggressive, **may not improve** speed or size |
| `opt-level = 3` | can be *slower* than `2`; `"z"` disables loop vectorization |
| `target-cpu = native` | emits AVX etc.; loses portability of the binary |
| PGO | 10%+ possible; needs a representative profile run; unsupported for crates.io binaries |
| `panic = "abort"` | smaller binary, slightly faster, less compile time — no unwinding |
| Allocator swap | measure; on `musl` targets the default allocator is a known cliff |

**Monomorphization is the compile-time tax on generics.** Every distinct type
combination is a fresh instantiation. In one project, replacing real
element-type generics with a single shared type cut incremental compile time from
108s to 14s; across that project's whole optimization pass the binary went 29 MB
→ 2.5 MB. Find the bloat with `cargo llvm-lines` (it reports generated LLVM IR
lines and the number of copies of each function); confirm with
`-Zprint-mono-items`.

**Compile-time levers, in order:** `cargo build --timings` to find the blocking
crate → `cargo check` in the inner loop (**2–3×** faster than `cargo build` when
no artifact is needed) → `[profile.dev] debug = "line-tables-only"` and
`debug = false` for dependencies (2–30% cycle improvement in compiler
benchmarks) → `lld`/`mold` if linking dominates → trim dependencies and features.
Trimming features does *not* always help; one large project got slower. Proc
macros are the worst offenders — complex ones take 20+ seconds to compile.

## Code-review gates

`clippy::perf` is warn-by-default, so plain `cargo clippy` already catches the
mechanical half of the table above. The `suspicious` lints below are also
warn-by-default. Opt in to the rest explicitly:

| Lint | Group | Catches |
|---|---|---|
| `slow_vector_initialization` | perf (warn) | `Vec::new()` + `resize` instead of `vec![0; n]` |
| `vec_init_then_push` | perf (warn) | `Vec::new()` followed by literal pushes |
| `useless_vec` | perf (warn) | `&vec![..]` where `&[..]` works |
| `large_enum_variant` | perf (warn) | one oversized enum variant |
| `result_large_err` | perf (warn) | oversized `Result::Err`, which propagates upward |
| `boxed_local` | perf (warn) | `Box<T>` where `T` on the stack is fine |
| `manual_memcpy` | perf (warn) | element-by-element copy loop |
| `redundant_allocation` | perf (warn) | `Box<Rc<T>>`, `Arc<&T>`, nested owners |
| `unnecessary_to_owned` | perf (warn) | `to_owned()`/`to_string()` that allocates needlessly |
| `manual_str_repeat` | perf (warn) | hand-rolled `repeat` |
| `needless_pass_by_value` | pedantic | by-value params that aren't consumed (may force a clone) |
| `inefficient_to_string` | pedantic | `.to_string()` on `&&T` — bypasses the specialized impl |
| `single_char_pattern` | pedantic | `"x"` where `'x'` works (perf inconclusive; clarity win) |
| `redundant_clone` | nursery (allow) | `clone()` of a value about to be dropped — LLVM often can't remove it |
| `or_fun_call` | nursery (allow) | `unwrap_or(expensive())` instead of `unwrap_or_else` |
| `needless_collect` | nursery (allow) | `collect().len()` |
| `large_stack_frames` | nursery (allow) | huge stack allocations |
| `await_holding_lock` | suspicious | `MutexGuard` across `.await` |
| `await_holding_refcell_ref` | suspicious | `RefCell` borrow across `.await` |

Clippy's own groups: `perf` is "compiler can't trivially optimize this, but a
slightly different expression helps" — easy to apply. `pedantic` false positives
are intentional; cherry-pick lints rather than enabling the whole group.

## Hard rules

- Do not add performance-motivated complexity to cold code. Ordinary cloning,
  boxing, and dependencies required for functionality or readable ownership
  remain valid; do not replace them with speculative optimizations.
- Do not claim a speedup without a before/after number on the same workload.
- Do not trade correctness or safety for speed. `unsafe` needs documented
  invariants plus tests.
- Do not add a faster hasher, allocator, or build flag "just in case". Each has
  a documented case where it loses.
- Do not report cache misses, instruction counts, or branch misses as the
  result. Report end-to-end time.

## Depth

Deeper detail, with the sources behind each claim:
[references/anti-patterns.md](references/anti-patterns.md) — the full mistake
catalog, what each one costs, the measurement that shows it, and the code.
[references/sources.md](references/sources.md) — every source consulted, marked
primary or secondary, with what it supports.

Hand off to the `rust-performance` skill when you need to profile, baseline, or
benchmark a change rather than write one.