# Rust Anti-Patterns: cost, evidence, fix

Each entry: what the code looks like, what it costs, the measurement that
proves it, and the fix. Ordered by how often it shows up. Claims marked
*(measured)* come from a benchmark in the cited source; claims marked
*(estimated)* are reasoning from the source's data, not a direct measurement.

Primary sources are listed in [sources.md](sources.md).

---

## 1. Allocation

### 1.1 Push without reserving

```rust
let mut v = Vec::new();
for x in input { v.push(x); }        // reallocs as capacity grows
```

Growth is quasi-doubling, and the first capacity depends on element size —
current `RawVec` starts at 8 elements for 1-byte types and 4 for most other
nonzero-sized types up to 1 KiB, then doubles. Each step copies the elements and
frees the old block. Filling a 20-element vector of a moderate-size type by
`push` therefore costs four allocations:

```rust
let mut v = Vec::with_capacity(input.len());
```

**Dedup:** this is the same rule as `vec_init_then_push`, `reserve` →
`with_capacity`, and "give your iterator a `size_hint`". One family: *say how
big it is before filling it*.

### 1.2 Allocating a buffer per iteration

```rust
for item in items {
    let mut scratch = Vec::new();     // new allocation every pass
    process(item, &mut scratch);
}
```

```rust
let mut scratch = Vec::new();
for item in items {
    scratch.clear();                  // keeps capacity; allocates zero times after warm-up
    process(item, &mut scratch);
}
```

Tradeoff: reusing a buffer couples the iterations, so the code no longer reads
as "each pass is independent". The heap allocation is real; the readability
cost is real. Use it where the loop actually runs often.

The same shape applies to a `String` and to `BufRead::lines()`:

```rust
for line in reader.lines() { process(&line?); }        // String per line
```

```rust
let mut line = String::new();
while reader.read_line(&mut line)? != 0 {
    // Match lines(): remove CR only as part of a CRLF terminator.
    let trimmed = match line.strip_suffix('\n') {
        Some(s) => s.strip_suffix('\r').unwrap_or(s),
        None => &line,
    };
    process(trimmed);
    line.clear();
}
```

This drops a per-line allocation to at most a handful total. It requires
`process` to take `&str`. Do not `trim()` here — `lines()` strips only the line
terminator, and trimming more would change behaviour.

### 1.3 `Vec::new()` + `resize(n, 0)` instead of `vec![0; n]`

```rust
let mut v = Vec::new();
v.resize(n, 0);                       // allocate, then zero in a second pass
```

`vec![0; n]` can request zeroed storage in a single allocator call, where the
`Vec::new()` + `resize` form allocates and then initializes separately. The
default `GlobalAlloc::alloc_zeroed` still does both steps underneath, so this is
an opportunity for allocator-specific zeroed pages rather than a guaranteed
halving of work — the standard docs only promise it is "potentially faster".
Clippy: `slow_vector_initialization`.

### 1.4 `clone()` used to escape the borrow checker

```rust
fn process(items: &Vec<Item>) {
    let owned = items.clone();        // copies the whole vector
    heavy(&owned);
}
```

```rust
fn process(items: &[Item]) { heavy(items); }
```

But the mirror mistake is real too: **`clone()` is not automatically the
problem.** rustc's own practice is to profile, find hot clone sites, and only
remove the ones that are actually hot. `Clippy::redundant_clone` only fires when
the value is cloned and immediately dropped, where LLVM often fails to elide the
allocation.

Related: `Rc`/`Arc::clone` bumps a refcount and does **not** allocate. Sharing one
large structure behind an `Arc` is nearly free next to cloning it — unless the
value is rarely shared, where the refcount adds an allocation that plain
ownership would not need.

`clone_from` reuses the destination's existing allocation **when the source
fits in the destination's capacity**:

```rust
let source = vec![1_u32, 2, 3];
let mut v1: Vec<u32> = Vec::with_capacity(99);
v1.clone_from(&source);   // reuses v1's allocation; source is allocated separately
```

If the source is longer than the destination's capacity, the vector still has
to grow.

### 1.5 Returning a collection the caller only iterates

```rust
fn filtered<'a>(xs: &'a [T], keep: impl Fn(&T) -> bool) -> Vec<&'a T> {
    xs.iter().filter(|x| keep(x)).collect()   // Vec<&T>: the borrow is free
}
```

Every call allocates. Returning `impl Iterator<Item = &T>` moves the cost to
the caller, who may never need it. The tradeoff is a lifetime in the return
type, which is why people write the `Vec` version in the first place. Clippy:
`needless_collect`.


### 1.6 `format!` on a hot path

`format!` produces a `String`, so it allocates. In a hot path:

```rust
let msg = format!("parse error at line {}", line);   // allocation
log("parse error");                                  // literal: none
```

For a constant-plus-input case, write into a reused buffer with
`write!`/`format_args!` rather than constructing a fresh `String`. Clippy has no
lint for this; it is a profile-driven change only.

### 1.7 `to_owned()`/`to_string()` in a signature

```rust
fn handle(name: String)          // caller can still move an existing String in
fn handle(name: &str)            // caller passes what it has
```

An owned signature does not itself allocate — a caller can move an existing
`String` in for free. The saving appears when the caller would otherwise have to
build or clone a `String` solely for this call. It also complicates lifetimes,
which is why owned signatures are common. The borrowed form is available only
while the backing data stays alive: a lifetime annotation describes and enforces
that relationship, it does not extend the data's life. A struct that must
outlive the text needs ownership, shared ownership, or longer-lived storage.

### 1.8 Nesting smart pointers

```rust
fn f(x: Box<Rc<T>>) / Arc<&T> / Rc<Arc<T>>   // extra word + extra indirection
```

Clippy: `redundant_allocation`. One owner.

### 1.9 `SmallVec` without measuring

`SmallVec<[T; N]>` keeps up to `N` elements inline. It reliably reduces
allocation rate but **is slightly slower than `Vec` for ordinary operations** —
every operation checks whether the elements are inline or heap. Large `N` or a
large `T` makes the `SmallVec` bigger than the `Vec` it replaces and makes
copying it slower. If you know the exact maximum length, `ArrayVec` avoids the
heap fallback entirely and is faster.

Measured in one project: inline small-vector storage cut runtime **12–25%** for a
workload whose `BigInt` values were `Vec<BigDigit>` — one heap indirection for a
value that fits in a `u64`.

---

## 2. Iterators

### 2.1 The myth

> "Iterators are slower than `for` loops."

The Rust Book measures both on the same text: explicit loop `19,620,300 ±
915,700 ns/iter`, iterator chain `19,234,900 ± 657,200 ns/iter` — the same
within variance. The Book's own point is that it is "not to prove that the two
versions are equivalent"; it says equivalent loop and iterator code optimizes
similarly *in many cases*, and recommends re-measuring on your own inputs.
Write the iterator.

### 2.2 The real cost: abstraction at the hot boundary

"Zero-cost" means no cost versus *equivalent hand-written code*. It does not
mean the optimization opportunity survives crossing the abstraction.

Measured, 100k integers through a recursive merge iterator:

| Driver | Time |
|---|---|
| one `next()` call per item | 6.5 ms |
| estimated scalar work | ~130 µs |
| batch 512, then iterate a plain array | ~110 µs (**60×**) |

Each individual `next()` compiles to something like a hand-written call. The
problem is that the *loop shape is hidden*, so LLVM cannot unroll or vectorize
across calls. When you own both sides of a hot iterator, expose a batch API.

### 2.3 Adapter micro-costs

- To fuse `filter(p).map(f)`, preserve both operations:
  `filter_map(|x| if p(&x) { Some(f(x)) } else { None })` for predicates taking
  a reference to the iterator item. An `Option`-returning `f` does not justify
  `filter_map(f)`: that drops `p` and unwraps/discards output options.
  Whether the equivalent fused adapter is faster requires measurement.
- `chain` can be slower than a single iterator. Avoid in hot paths.
- `chunks_exact` when the chunk size divides the length exactly; otherwise
  `chunks_exact` + `remainder`. Same for `chunks_mut`, `rchunks*`.
- `iter().copied()` over `iter()` for small integer element types — the consumer
  gets values by value and LLVM generates better code.
- `size_hint` on hand-written iterators so `collect`/`extend` reserve once.

---

## 3. Data layout

### 3.1 Large hot types

Large values can increase copying costs, but 128 bytes is not a portable
`memcpy` threshold. Compiler version, target, and surrounding code determine
whether moves are calls, inline instructions, or eliminated. Measure first.
Boxing an enum variant shrinks inline storage but adds allocation and pointer
indirection; it is more promising when the large variant is rare.

```rust
enum Message { Small(Small), Huge(HugeData) }   // every value is HugeData-sized
enum Message { Small(Small), Huge(Box<HugeData>) }
```

Clippy: `large_enum_variant`, `result_large_err`. Both warn; both are worth
*measuring* before acting — `large_enum_variant` cannot know your actual variant
distribution, and boxing a large variant of a `Copy` type removes the `Copy`
impl.

### 3.2 Contiguity

`Vec`, `VecDeque`, `Box<[T]>` put elements next to each other. `LinkedList`,
`Vec<Box<T>>`, and `Box` chains make every step a pointer dereference. Use the
contiguous form unless you have a specific need for stable references or O(1)
removal from the middle.

### 3.3 Flatten and narrow

Measured, one real dataset:

| Representation | Record size | Notes |
|---|---|---|
| `Vec<Vec<usize>>` | 216 B | nested allocation, 64-bit indices for ≤256 values |
| two flat `Box<[u8]>` lists | 48 B | up to **20%** faster |

For 1000 records, deserialized data was 776 KB against 137 KB of text input —
5.7× blowup from nesting, over-allocation after parsing, and wide indices.
Flattening the nesting and narrowing the index type recovered most of it.

This pays off when the working set exceeds cache and the per-item computation is
small — and the source notes it *compounds* with arithmetic optimizations, since
making the hot loop cheaper raises the relative value of fixing its layout.
Optimize the math and the layout together.

### 3.4 Bit-packing: a documented loss

Packing one example's whole ranking payload (three bits per candidate plus one
split bit) into three bytes reduced measured data-cache misses and made
execution **at least 30% slower** — the unpack work in the hot loop outweighed
the misses saved, and it required substantially more complex traits. Note the
byte count is that example's total payload; arbitrary records will not fit in
three bytes.

Rule: a cache-miss counter is not a result. Packing trades misses for
instructions; measure elapsed time.

### 3.5 Sorting: helps branches, hurts locality

Same project, 100k records:

| Change | Branch misses | Elapsed | LLC-load misses |
|---|---|---|---|
| unsorted input (baseline) | 2.85% (498M) | 5.358 s | 782,226 |
| read pre-sorted input | 1.33% (233M) | 4.633 s (**~14%**) | 747,867 |
| sort the already-allocated roots | — | 5.084 s (**~5%**) | 10,657,891 (**~14×**) |

Sorting the roots was still faster than doing nothing, but it scattered the
allocation references: LLC-load misses went up more than 13×, which ate most of
the branch-prediction win and left it well behind reading pre-sorted input.
Sorting then cloning to rebuild allocations in sorted order gave another ~10%,
but that relies on the allocator handing out sequential chunks — implicit
behaviour worth replacing with an arena if you depend on it.

---

## 4. Hashing

The default `HashMap`/`HashSet` hasher was SipHash 1-3 at the time the
Performance Book was written — the standard leaves the algorithm unspecified, so
treat the name as a time-sensitive detail. Its cost is deliberate:
collision-resistance against attacker-chosen keys.

Measured inside rustc:

| Change | Result |
|---|---|
| `fnv` → `fxhash` | up to **6% faster** |
| `fxhash` → `ahash` | **1–4% slower** |
| `fxhash` → default | **4–84% slower** |

Note the direction: the "better" hasher (ahash) lost to the cruder one
(fxhash). Available options: `rustc-hash` (fastest, weakest), `fxhash` (older
rustc-hash), `fnv` (better quality, slower), `ahash` (uses AES instructions
where available). For random integer newtype keys, `nohash_hasher` skips hashing
entirely.

Rules: switch only when profiling says hashing is hot. Never for
attacker-controlled keys — that's what the default is for. Measure with your key
distribution, not a microbenchmark of the hasher.

---

## 5. Concurrency

### 5.1 A mutex can beat a naive atomic

One shared counter, Criterion, total time — a deliberately naive atomic pattern,
not a general verdict on atomics:

| Increments/thread | Threads | `AtomicU64::fetch_add` | `Mutex<u64>` | Winner |
|---:|---:|---:|---:|---|
| 200k | 2 | 1.44 ms | 7.15 ms | atomic ~4.98× |
| 200k | 4 | 6.40 ms | 11.65 ms | atomic ~1.82× |
| 200k | 8 | 25.75 ms | 19.18 ms | **mutex ~1.34×** |
| 1M | 2 | 7.63 ms | 45.83 ms | atomic ~6.00× |
| 1M | 4 | 35.21 ms | 60.59 ms | atomic ~1.72× |
| 1M | 8 | 133.23 ms | 97.88 ms | **mutex ~1.36×** |

At 8 threads every thread hammers the same cache line and ownership ping-pongs.
The mutex's arbitration reduces simultaneous hammering and wins. The source's own
conclusion is that a mutex "can outperform naive atomics in highly contended
single-counter patterns", and its profiling points at an AArch64 atomic RMW path
— so this is not an architecture-independent contention threshold.

Fix the sharing rather than the primitive: per-thread counters or thread-local
sharding, merged at the end. Then the atomic is uncontended and wins again.

### 5.2 `std::sync::Mutex` vs `parking_lot::Mutex`

Four scenarios, Linux, futex backend, 10–15 s each:

| Scenario | Winner | Numbers |
|---|---|---|
| 4 threads, short critical section | `std` | 9% higher throughput |
| 8 threads, 500 µs sleep holding lock | `parking_lot` | std: 66–1394 ops/thread (95% variation), wait SD 188.73 ms. parking_lot: 860–877 (1.9%), wait SD 3.67 ms (~51× more stable) at 7.5% lower throughput |
| 8 threads, bursty 200 ms on / 800 ms idle | `parking_lot` | 18.5% higher throughput, 24.8% more stable waits; std kept lower tails |
| 6 threads, one hogs the lock 500 µs | `parking_lot` | std: hog 12242 ops, others 6–16 each. parking_lot: hog 9168, others ~7100. +261.6% throughput, wait SD 1.09 ms vs 130.76 ms (~120×) |

There is no universally faster mutex. `std` is a strong baseline for short,
low-contention critical sections. `parking_lot` wins when fairness and
starvation resistance matter — its eventual-fairness handoff fires at ~0.5 ms,
and `unlock_fair()` requests it explicitly.

The real lesson from the last two rows is not "use parking_lot". It is: **sleeping
or doing I/O under a lock is a design bug.** No mutex makes that good.

### 5.3 Blocking a Tokio worker

Tokio's scheduler is cooperative, not preemptive. `.await` is an *opportunity* to
yield — if the awaited resource is already ready, the task never yields and no
other task on that worker runs. Tokio will not detect this and add threads.

```rust
async fn handler(req: Request) -> Response {
    let data = std::fs::read_to_string("/etc/config")?;   // blocks the worker
    heavy_cpu(&data);                                      // blocks the worker
    ...
}
```

```rust
async fn handler(req: Request) -> Response {
    let data = tokio::task::spawn_blocking(|| {
        std::fs::read_to_string("/etc/config")
    }).await??;
    ...
}
```

Tokio 0.2.14 introduced a per-task budget of **128 operations per tick**
(chosen because it "felt good" in their tests — a heuristic, not a tuning knob).
Exhausting it makes Tokio resources report not-ready until the task yields.
Measured effect: tail latency reduced **almost 3× in some cases**.

Bound uninterrupted work between yields, not the lifetime of an async task.
Long-lived tasks that yield regularly belong on the async runtime. Move blocking
operations to `spawn_blocking`; for many CPU-heavy computations, bound concurrent
jobs with a semaphore or use a bounded CPU executor such as Rayon. The blocking
pool's large default thread limit is intended for blocking I/O, not CPU budgeting.

Same class of bug: calling `block_on` from inside a runtime worker.

### 5.4 Unbounded channels

```rust
let (tx, rx) = tokio::sync::mpsc::unbounded_channel();   // no backpressure
```

Succeeds while the receiver is open; if the receiver falls behind, memory grows
until the system is exhausted and the process can abort. Use
`mpsc::channel(n)` with a finite `n` chosen from the workload, so `send().await`
applies backpressure.

### 5.5 Guard held across `.await`

```rust
async fn update(&self) {
    let mut state = self.state.lock().unwrap();
    state.push(compute().await);          // guard held across a suspension point
}
```

The mechanism is not thread migration. `std::sync::MutexGuard` is not `Send`, so
holding one across an `.await` makes the future non-`Send` and `tokio::spawn`
rejects it at compile time. On a local executor, or with a guard type that is
`Send`, a contender can instead block the worker the suspended lock holder needs
— a deadlock, and starvation of whatever else shares that worker. Either way the
fix is the same: scope the lock so it is dropped before the `.await`, or use an
async-aware mutex, which is designed to be held across one. Clippy:
`await_holding_lock` (suspicious group).

Same class of bug for `RefCell` borrows across `.await`, where the failure is a
runtime borrow panic rather than a deadlock: `await_holding_refcell_ref`.

### 5.6 Over-spawning

One task per trivial item makes scheduling and bookkeeping cost more than the
work. Batch. Likewise the mirror error: parallelism added without checking that
the work is big enough.

### 5.7 Rayon

No item-count threshold exists. A forum report of a 50,000-element `i32` sum
showed the sequential version ~9× faster (timings `193` vs `1756` in the poster's
own units, build mode and warm-up unspecified, and first runs also pay
thread-pool startup). A separate participant's playground check showed the
sequential sum constant-folding to `movl $50000, %eax` while Rayon kept its full
scheduling machinery — an illustration of what the optimizer can do, not a proven
cause of the original timings.

Splitting granularity is not one-directional either:

| Configuration | Workload | Baseline | Result |
|---|---|---|---|
| `with_max_len(1)` | random input | the specialized custom pool | **~2× slower** |
| default Rayon | random input | the custom pool | slower (see study's charts) |
| tuned Rayon | heavily skewed input | the custom pool | ~4% slower |

Smaller leaves meant more splitting and queue traffic, which outweighed better
load balance. Tune `with_min_len`/`with_max_len` against a representative
distribution.

One machine in that study had 8 hardware threads on 4 cores sharing L1/L2 —
logical parallelism did not scale linearly. Count physical cores.

---

## 6. Build configuration

Only the workspace-root `Cargo.toml` profile is honoured.

| Setting | Effect | Caveat |
|---|---|---|
| `--release` | 10–100× vs dev | dev also keeps debug assertions and overflow checks |
| `codegen-units = 1` | better runtime, smaller binary | slower compile (defaults: 256 incremental, 16 non-incremental) |
| `lto = "thin"` | 10–20% possible | substantially faster to link than fat, similar gains |
| `lto = "fat"` | more aggressive | **may not improve** speed or size |
| `lto = "off"` | faster builds | likely slower and larger |
| `opt-level = 3` | fastest in most cases | can be *slower* than `2` |
| `opt-level = "s"` | size-oriented | slightly more inlining/vectorization than `"z"` |
| `opt-level = "z"` | smallest | **disables loop vectorization**; not guaranteed smaller |
| `panic = "abort"` | smaller, slightly faster | no unwinding; ignored by tests/benches/build scripts/proc macros |
| `target-cpu = native` | emits AVX and friends | binary no longer runs on older CPUs |
| PGO | 10%+ possible | needs a representative profile run; unsupported for crates.io binaries |

Cargo's own doc explicitly warns that `s`/`z` are not necessarily smaller and
that level 3 can be slower than 2. Re-measure across rustc versions.

### 6.1 Allocators

```toml
[dependencies]
mimalloc = "0.1"
```

```rust
#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;
```

Allocator swap is **measurement-dependent** — there is no reproducible
before/after number in the sources consulted; the wins reported are large but
program- and platform-specific, and they cost binary size and compile time.

The exception worth knowing: the **default `musl` allocator** is a documented
cliff. One measurement on a single machine: glibc 0.17 s elapsed vs musl 1.18 s
(~7×), with voluntary context switches 1,196 vs 199,786 (~167×) and `strace`
showing 6.7 s vs 0.5 s in futex. A synthetic 48-core run: 0.169 s vs 1m56.9 s.
Other projects report 2–20× musl slowdowns, attributed to thread/allocation
contention. musl 1.2.1's mallocng did not change that result.

On musl targets, treat allocator contention as a high-priority suspect and
measure the swap. The evidence above comes from allocation-contention
workloads, so it justifies looking here first — it does not waive the
measurement requirement. Everywhere else, profile first.

### 6.2 Monomorphization

Every distinct type argument combination is a separate instantiation. Measured
in one project (incremental rebuilds of CubeCL matrix-multiplication benchmarks):

| Step | Before | After |
|---|---|---|
| replace real generic element-type params with one shared type | 108 s | 14 s |
| binary size, measured across that project's *whole* optimization pass | 29 MB | 2.5 MB |

The compile-time figure is that first step alone. The binary size is the
before/after of the entire optimization pass (further steps changed the shape
representation and LLVM opt level), not the immediate result of step one.

Find the bloat with `cargo llvm-lines` — the tool's own README example shows
`drop_in_place` at 1,395 LLVM IR lines across 83 copies. `-Zprint-mono-items`
confirms. `-Zshare-generics` and "explicit monomorphization" are
nightly/experimental proposals, not available fixes.

### 6.3 Compile time, in the order that works

1. `cargo build --timings` — find the crate blocking everything else.
2. `cargo check` in the inner loop: **2–3×** faster than `cargo build` when no
   artifact is needed.
3. `[profile.dev] debug = "line-tables-only"` plus `debug = false` for
   dependencies — faster codegen, faster linking, smaller `target`. Compiler
   benchmarks: **2–30%** cycle improvement from reducing debuginfo.
4. Faster linker (`lld`, `mold`) — only if linking actually dominates. Linking
   always runs from scratch, so it dominates incremental rebuilds.
5. Remove unused dependencies and features — but this does **not** always help.
   One reported `bindgen` feature removal saved ~13 s debug / ~9 s release; the
   same source cites a project where disabling features made builds slower.
6. `cargo tree --duplicate` to consolidate versions.
7. Proc macros are the expensive tail — complex ones take 20+ s to compile.
   `-Zmacro-stats` quantifies output.

The 2025 Rust compiler survey backs the shape of this: 3,700+ responses, average
satisfaction **6/10**, **55%** waiting over 10 s for rebuilds, with dependency
count and project size correlating most strongly.

### 6.4 Inlining

`#[inline]` is a suggestion; `#[inline(always)]` and `#[inline(never)]` are
strong suggestions. Inlining is not transitive — marking `f` does not request
that `f` and its callee `g` both inline; mark both. Best candidates are tiny
functions and single-call-site functions, which the compiler often inlines
unaided. Cross-crate inlining duplicates code and costs compile time, and an
`#[inline]` can make runtime *worse* by blocking a nearby function from inlining.
Measure after adding attributes.

---

## 7. Clippy gates

```bash
# perf and suspicious are warn-by-default: plain `cargo clippy` covers them.
# Cherry-pick from the rest, per Clippy's own guidance:
cargo clippy -- \
  -W clippy::needless_pass_by_value \
  -W clippy::inefficient_to_string \
  -W clippy::redundant_clone \
  -W clippy::or_fun_call \
  -W clippy::needless_collect \
  -W clippy::large_stack_frames
```

Per Clippy's own docs: `correctness` is the only deny-by-default group and is
never meant to be allowed; `perf` covers "code the compiler can't trivially
optimize, but that a slightly different expression helps" and is easy to apply;
`pedantic` false positives are intentional, so cherry-pick rather than enabling
the whole group; `restriction` and `nursery` should always be cherry-picked.

## Review checklist

- [ ] No allocation in the hot path that a borrow or a reused buffer removes
- [ ] Collections reserved or given a `size_hint` before filling
- [ ] No per-iteration buffer allocation
- [ ] Large hot types measured; boxing justified by copying costs and variant frequency
- [ ] Contiguous containers, not pointer-chasing chains
- [ ] Indices and field widths sized to the actual data range
- [ ] Hashing measured before the hasher is swapped; not attacker-controlled keys
- [ ] No blocking or CPU-heavy work on an async worker
- [ ] Channels bounded; guards not held across `.await`
- [ ] Shared mutable state sharded, not hammered
- [ ] No speculative performance complexity on cold paths; ordinary ownership choices remain valid
- [ ] Release profile sane; allocator and PGO changes measured, not assumed