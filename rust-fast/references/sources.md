# Sources

Every claim in [SKILL.md](../SKILL.md) and
[anti-patterns.md](anti-patterns.md) traces to one of these. The split is by
authority, not by authorship: **Primary** is first-party project
documentation — the Rust Performance Book, the Rust Book, Cargo/rustc/Clippy/
Tokio docs. **Secondary** is independent material, including authors reporting
their own benchmarks. Secondary sources are used for their measurements, not
their opinions; where a secondary claim conflicts with documentation, this skill
follows the documentation.

Compiled 2026-10-02 from a 199-URL candidate pool. 153 distinct sources are
cited below (52 first-party, 101 community); every numeric claim in this skill
traces to one of them.

---

## Primary — first-party documentation and reference

### The Rust Performance Book (Nicholas Nethercote and others)

The single densest source; most allocation, layout, iterator, and build-config
claims come from here.

- [Heap Allocations](https://nnethercote.github.io/perf-book/heap-allocations.html) — allocation costs, the 10-allocs/Minstr ≈ 1% figure, DHAT, `Vec` growth 0/4/8/16/32/64, `SmallVec`/`ArrayVec`, `Cow`, `clone_from`, workhorse collections, `BufRead::lines` allocation, `dhat-rs` heap-usage tests
- [Iterators](https://nnethercote.github.io/perf-book/iterators.html) — `collect` when only iterating, `extend` vs collect-then-append, `size_hint`, `chain`, `filter_map`, `chunks_exact`, `iter().copied()`
- [Type Sizes](https://nnethercote.github.io/perf-book/type-sizes.html) — shrinking frequently-instantiated types, conditional boxing, DHAT copy profiling; its 128-byte move threshold is not a portable guarantee
- [Build Configuration](https://nnethercote.github.io/perf-book/build-configuration.html) — release 10–100×, LTO 10–20%, `codegen-units`, alternative allocators, `target-cpu=native`, PGO 10%+, `panic = "abort"`, `opt-level` s/z
- [Hashing](https://nnethercote.github.io/perf-book/hashing.html) — SipHash default, fnv/fxhash/ahash/nohash comparison, the 6% / 1–4% / 4–84% rustc measurements
- [Inlining](https://nnethercote.github.io/perf-book/inlining.html) — suggestion semantics, non-transitivity, cross-crate cost, hot/cold split
- [I/O](https://nnethercote.github.io/perf-book/io.html) — buffered reading
- [Profiling](https://nnethercote.github.io/perf-book/profiling.html) — profiler selection
- [Repository](https://github.com/nnethercote/perf-book) — source

### The Rust Programming Language

- [Performance in Loops vs. Iterators](https://doc.rust-lang.org/book/ch13-04-performance.html) — the 19,620,300 ns vs 19,234,900 ns benchmark; zero-cost abstractions
- [Applying Concurrency with Async](https://doc.rust-lang.org/stable/book/ch17-02-concurrency-with-async.html) — async execution model
- [Fearless Concurrency](https://doc.rust-lang.org/book/ch16-00-concurrency.html)
- [Asynchronous Programming in Rust](https://rust-lang.github.io/async-book/part-guide/concurrency.html)
- [Unsafe Rust](https://doc.rust-lang.org/book/ch20-01-unsafe-rust.html)
- [`Iterator::collect`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.collect) — `FromIterator` contract, size-driven reservation
- [`Iterator::size_hint`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#trait.Iterator.size_hint) — default `(0, None)`, the `(0..10).filter(even)` → `(0, Some(10))` example, the rule against relying on it for safety
- [`Cow`](https://doc.rust-lang.org/std/borrow/enum.Cow.html) — borrowed/owned union, `to_mut` clone-on-write
- [`LinkedList`](https://doc.rust-lang.org/beta/std/collections/struct.LinkedList.html) — documented as rarely the right choice
- [`HashMap`](https://doc.rust-lang.org/std/collections/struct.HashMap.html)
- [Global Allocators](https://doc.rust-lang.org/std/alloc/index.html) · [`System`](https://doc.rust-lang.org/std/alloc/struct.System.html)
- [Clone](https://doc.rust-lang.org/std/clone/trait.Clone.html) · [`FromStr`](https://doc.rust-lang.org/std/str/trait.FromStr.html)

### Cargo / rustc

- [Cargo Profiles reference](https://doc.rust-lang.org/stable/cargo/reference/profiles.html) — `opt-level` values, the "level 3 can be slower than 2" and "`s`/`z` not necessarily smaller" warnings, LTO modes, codegen-units defaults (256 incremental / 16 non-incremental), incremental, workspace-root-only scope, `panic` ignored by build scripts and proc macros
- [Optimizing Build Performance](https://doc.rust-lang.org/stable/cargo/guide/build-performance.html) — measure the actual workflow, `line-tables-only` debug info, Cranelift (nightly), `-Zthreads=8`, alternative linkers, feature unification
- [Profile-Guided Optimization (rustc book)](https://doc.rust-lang.org/rustc/profile-guided-optimization.html) — instrument → sample → rebuild flow
- [PGO in the compiler dev guide](https://rustc-dev-guide.rust-lang.org/profile-guided-optimization.html)
- [Monomorphization](https://rustc-dev-guide.rust-lang.org/backend/monomorph.html)
- [Rust Compiler Performance Survey 2025](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results) — 3,700+ responses, 6/10 satisfaction, 55% waiting >10 s, linking always from scratch, debuginfo cycle measurements, ~42% using no build-performance mechanism
- [Clippy lint groups](https://doc.rust-lang.org/stable/clippy/lints.html) — what `correctness`/`perf`/`pedantic`/`restriction`/`nursery` mean and when to allow
- [Clippy lint catalog](https://rust-lang.github.io/rust-clippy/master/index.html) — authoritative text and group for every lint named in this skill
- [unstable-sort RFC 1884](https://github.com/rust-lang/rfcs/blob/master/text/1884-unstable-sort.md)
- [Explicit monomorphization (internals discussion)](https://internals.rust-lang.org/t/explicit-monomorphization-for-compilation-time-reduction/15907) — proposal only, not stable
- [LTO / codegen-units clarification (rust #48518)](https://github.com/rust-lang/rust/issues/48518)
- [LTO-slowed-build report (rust #48371)](https://github.com/rust-lang/rust/issues/48371)

### Tokio

- [Reducing tail latencies with automatic cooperative task yielding](https://tokio.rs/blog/2020-04-preemption) — not preemptive, the 128-operations-per-tick budget, ~3× tail-latency reduction in some cases, no automatic thread injection
- [Runtime reference](https://docs.rs/tokio/latest/tokio/runtime/index.html) — one worker per available core by default, the bounded-task/bounded-poll fairness precondition, `block_in_place`, `prewarm-fd-table`
- [`mpsc::channel`](https://docs.rs/tokio/latest/tokio/sync/mpsc/fn.channel.html) — bounded, backpressure, capacity ≥ 1
- [`mpsc::unbounded_channel`](https://docs.rs/tokio/latest/tokio/sync/mpsc/fn.unbounded_channel.html) — no backpressure, memory exhaustion may abort the process
- [`spawn_blocking`](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html)

### Crates

- [memchr](https://github.com/BurntSushi/memchr) — SIMD/SWAR byte and substring search, runtime AVX2 detection, adaptive algorithms
- [simd-json](https://github.com/simd-lite/simd-json) — SIMD JSON parsing, runtime CPU detection, allocator recommendation, the 8-digits-at-a-time tradeoff
- [smallvec](https://docs.rs/smallvec/latest/smallvec/) — inline capacity, cache-locality claim, the `union` size reduction
- [serde field attributes](https://serde.rs/field-attrs.html) · [lifetimes](https://serde.rs/lifetimes.html) — `#[serde(borrow)]`, zero-copy constraints, when borrowing is impossible
- [arc-swap performance notes](https://docs.rs/arc-swap/latest/arc_swap/docs/performance/index.html)
- [parking_lot](https://github.com/vvuk/rust-parking_lot) · [DashMap](https://github.com/xacrimon/dashmap)
- [rustc-hash](https://crates.io/crates/rustc-hash) ([repo](https://github.com/rust-lang/rustc-hash)) · [fx-hash](https://crates.io/crates/fx-hash) · [serde](https://serde.rs/) · [simd-json docs](https://docs.rs/simd-json/latest/simd_json) · [ArcSwap](https://docs.rs/arc-swap/latest/arc_swap/)

---

## Secondary — community articles and measured case studies

Used for their numbers. Where an article's opinion conflicts with another
source, this skill follows the primary source.

### Measured optimization case studies

- [Optimization adventures: making a parallel Rust workload 10x faster with (or without) Rayon](https://gendignoux.com/blog/2024/11/18/rust-rayon-optimized.html) — 2× on 8 threads initially; `strace -cf` showing 5,079 futex / 64,938 `sched_yield` calls; `with_max_len(1)` 2× slower; 10%/20% gain from pinned custom threads; 5× fewer steals with bulk stealing; 8 threads on 4 cores sharing L1/L2
- [Optimization adventures: data-oriented design](https://gendignoux.com/blog/2024/12/02/rust-data-oriented-design.html) — `Vec<Vec<usize>>` 216 B → 48 B flat `Box<[u8]>` lists, 776 KB vs 137 KB text, up to 20% faster; bit-packing to 3 bytes at least 30% slower; sorted input 2.85%→1.33% branch misses, 5.36 s→4.63 s; sorted-roots LLC misses 14× worse; small-vector storage 12–25%
- [Rust zero-cost abstractions vs. SIMD](https://turbopuffer.com/blog/zero-cost) — 6.5 ms per-item `next()` vs ~110 µs batched at 512 over 100k integers (60×); ~130 µs scalar estimate; the definition of zero-cost
- [Inside Rust's std and parking_lot mutexes — who wins?](https://blog.cuongle.dev/p/inside-rusts-std-and-parking-lot-mutexes-who-win) — the four contention scenarios, 9% / 18.5% / 51× / 120× figures, ~0.5 ms eventual-fairness timer, `unlock_fair()`; [benchmark code](https://github.com/cuongleqq/mutex-benches)
- [Atomics vs Mutex in Rust: Why Mutex Won Under Heavy Contention](https://ratuldawar.github.io/posts/atomics-vs-mutex-contention/) — the Criterion counter table (2/4/8 threads, 200k/1M increments)
- [Improve Rust Compile Time by 108X](https://burn.dev/blog/improve-rust-compile-time-by-108x) — 108 s → ~14 s and 29 MB → 2.5 MB by collapsing generics; LLVM opt level 3→0 giving ~5 s → ~1 s; the author's explicit note that their bottleneck was generated IR volume
- [Tips For Faster Rust Compile Times](https://corrode.dev/blog/tips-for-faster-rust-compile-times) — `cargo check` 2–3×, `cargo build --timings`, `cargo llvm-lines` (1,107 copies, `drop_in_place` 1,395 lines / 83 copies), `-Zself-profile`, `-Ztime-passes` linker phase numbers, bindgen feature removal ~13 s / ~9 s, the caveat that disabling features does not always help, macOS `split-debuginfo` reports, `cargo-nextest` 1.37–3.38×

### Mistake catalogs

- [The 7 Rust Anti-Patterns That Are Secretly Killing Your Performance](https://medium.com/solo-devs/the-7-rust-anti-patterns-that-are-secretly-killing-your-performance-and-how-to-fix-them-in-2025-dcebfdef7b54)
- [Anti-Patterns — Rust Design Patterns](https://rust-unofficial.github.io/patterns/anti_patterns/index.html) · [repository](https://github.com/rust-unofficial/patterns)
- [Appendix C: Anti-Patterns — Rust Patterns Book](https://rust-patterns.com/book/33-appendix-c-anti-patterns.html)
- [Recognizing Anti-Patterns in Rust](https://softwarepatternslexicon.com/rust/anti-patterns-and-common-pitfalls/recognizing-anti-patterns-in-rust/) · [index](https://softwarepatternslexicon.com/rust/anti-patterns-and-common-pitfalls/)
- [Pitfalls of Safe Rust](https://corrode.dev/blog/pitfalls-of-safe-rust) — overflow checks, `as` truncation, bounds-checked indexing
- [The Problem with Clones in Rust](https://hamy.xyz/blog/2026-02_the-problem-with-clones-in-rust)
- [Ownership, performance, and when cloning is actually the right choice? — users.rust-lang.org](https://users.rust-lang.org/t/ownership-performance-and-when-cloning-is-actually-the-right-choice/138475) — the community consensus that clone is fine unless measured
- [Understanding clone vs clone_from](https://users.rust-lang.org/t/understanding-clone-vs-clone-from-and-in-place-calculations/113400)
- [Should I get worried about cloning things around? — r/rust](https://www.reddit.com/r/rust/comments/swfog4/should_i_get_worried_about_cloning_things_around/)
- [Avoiding Clones: Borrowing Smart in Rust](https://dev.to/sgchris/avoiding-clones-borrowing-smart-in-rust-41af) · [How to Avoid Unnecessary Clones in Rust](https://www.rustfaq.org/en/how-to-avoid-unnecessary-clones-in-rust/)
- [Is using `Copy`/`Clone` to fix "use of moved value" expensive? — Stack Overflow](https://stackoverflow.com/questions/69602261/is-using-copy-and-clone-to-fix-use-of-moved-value-expensive)
- [Avoiding excessive clone — microsoft/RustTraining](https://github.com/microsoft/RustTraining/blob/main/c-cpp-book/src/ch17-1-avoiding-excessive-clone.md)
- [We all know `iter` is faster than `loop`, but why? — users.rust-lang.org](https://users.rust-lang.org/t/we-all-know-iter-is-faster-than-loop-but-why/51486)
- [Code generation for iterator chains](https://users.rust-lang.org/t/code-generation-for-iterator-chains/5621)
- [Strings on stack much faster than String](https://users.rust-lang.org/t/strings-on-stack-much-faster-than-string/87122)

### Async and runtime practice

- [Top 5 Tokio Runtime Mistakes That Quietly Kill Your Async Rust](https://www.techbuddies.io/2026/03/21/top-5-tokio-runtime-mistakes-that-quietly-kill-your-async-rust) — blocking workers, over-spawning, nested `block_on`, unbounded queues, runtime sizing as a measured exception
- [7 Hidden Tokio Runtime Mistakes](https://medium.com/techkoala-insights/7-hidden-tokio-runtime-mistakes-that-are-killing-your-rust-app-performance-b99ce5580c95)
- [Rust Async Secrets That Cut API Latency in Half](https://dev.to/speed_engineer/rust-async-secrets-that-cut-api-latency-in-half-2g3l)
- [Rust Concurrency: Common Async Pitfalls Explained](https://dev.to/leapcell/rust-concurrency-common-async-pitfalls-explained-53p1)
- [tokio-blocked — detect blocking code in async tasks](https://github.com/theduke/tokio-blocked)
- [tokio discussion #4703 — performance issues](https://github.com/tokio-rs/tokio/discussions/4703)
- [tokio issue #4321 — unbounded MPSC memory under back-pressure](https://github.com/tokio-rs/tokio/issues/4321)
- [Tokio performance tag archive](https://www.techbuddies.io/tag/tokio-performance/)
- [Rust Async Runtimes: Tokio vs async-std vs smol](https://lucaberton.com/blog/rust-async-runtimes-tokio-2026)
- [ResExt — anyhow-like ergonomics with thiserror-like performance](https://users.rust-lang.org/t/resext-anyhow-like-error-handling-with-thiserror-like-performance/138251)
- [Error handling libraries: anyhow vs thiserror vs eyre](https://www.pistack.xyz/posts/2026-06-22-rust-error-handling-anyhow-thiserror-eyre-guide) · [Rustify on Result/Option/`?`](https://rustify.rs/articles/rust-error-handling-result-option)

### Data structures, layout, and hashing

- [Cache-Friendly Data Layout — rustacean wiki](https://github.com/AgriciDaniel/rustacean/blob/main/wiki/patterns/Cache-Friendly%20Data%20Layout.md)
- [Why Your Rust Code Is Slow: Writing Cache-Friendly Code](https://elitedev.in/rust/why_your_rust_code_is_slow_writing_cache-friendly_code_for_real_performance/)
- [Optimizing for Cache Locality in Rust](https://softwarepatternslexicon.com/rust/performance-optimization-patterns/optimizing-for-cache-locality)
- [Rust Performance — data locality (Stanza)](https://www.stanza.dev/courses/rust-performance/memory/rust-perf-data-locality) · [cargo profiles (Stanza)](https://www.stanza.dev/courses/rust-performance/profiles/rust-perf-cargo-profiles)
- [Performance: Vec vs LinkedList vs VecDeque](https://www.rustfaq.org/en/performance-vec-vs-linkedlist-vs-vecdeque-which-to-use) · [Cache-Friendly Data Structures](https://www.rustfaq.org/en/cache-friendly-data-structures-in-rust/)
- [vec-vs-list comparison — matklad](https://github.com/matklad/vec-vs-list)
- [Faster HashMap for sequential keys — Stack Overflow](https://stackoverflow.com/questions/70551997/faster-hashmap-for-sequential-keys)
- [Hashing algorithms for HashMap in Rust: performance and security](https://blog.devgenius.io/hashing-algorithms-for-hashmap-in-rust-a-deep-dive-into-performance-and-security-3ae181798bb9)
- [hashmap-benchmark — kumagi](https://github.com/kumagi/hashmap-benchmark)
- [HashMap performance — users.rust-lang.org](https://users.rust-lang.org/t/hashmap-performance/6476) · [HashMap performance (page 2)](https://users.rust-lang.org/t/hashmap-performance/6476?page=2)
- [HashMap Examples for .NET developers](https://www.dotnetperls.com/hashmap-rust)
- [Monomorphization and Code Bloat — notes.camadkins.com](https://notes.camadkins.com/cs/languages/rust/monomorphization-and-code-bloat)
- [What Is Monomorphization and How Does It Affect Binary Size?](https://www.rustfaq.org/en/what-is-monomorphization-and-how-does-it-affect-binary-size/)
- [Rust's Zero-Cost Abstractions, What Monomorphization Actually Does to Your Code](https://dev.to/shayan_holakouee/rusts-zero-cost-abstractions-what-monomorphization-actually-does-to-your-code-5dim)
- [The Hidden Cost of Monomorphization](https://medium.com/@theopinionatedev/the-hidden-cost-of-monomorphization-why-generics-make-rust-binaries-huge-ff04edffb5e9)
- [Monomorphization vs Dynamic Dispatch](https://users.rust-lang.org/t/monomorphization-vs-dynamic-dispatch/65593) · [What technique cuts compile times?](https://users.rust-lang.org/t/whats-the-name-of-this-technique-for-cutting-down-compile-times-from-monomorphization/89172)
- [Generics: the full picture — microsoft/RustTraining](https://github.com/microsoft/RustTraining/blob/main/rust-patterns-book/src/ch01-generics-the-full-picture.md)

### Allocators, I/O, and codegen

- [Top 7 Rust Custom Allocators Mistakes That Kill Performance](https://www.techbuddies.io/2026/04/02/top-7-rust-custom-allocators-mistakes-that-kill-performance/) — `#[global_allocator]` shape, the allocation/deallocation ownership rule across FFI, per-thread arenas
- [Default musl allocator considered harmful to performance](https://nickb.dev/blog/default-musl-allocator-considered-harmful-to-performance/) — the glibc 0.17 s vs musl 1.18 s / 199,786 context switches / 1m56.9 s on 48 cores figures; mimalloc-on-musl recipe; reported 2–20× slowdowns elsewhere; mallocng did not help
- [Rust allocator: jemalloc vs mimalloc vs tcmalloc](https://www.kunalganglani.com/blog/rust-allocator-jemalloc-mimalloc-tcmalloc)
- [The Power of jemalloc and mimalloc in Rust — and when to use them](https://medium.com/@syntaxSavage/the-power-of-jemalloc-and-mimalloc-in-rust-and-when-to-use-them-820deb8996fe)
- [Benchmark with different allocators — rust-analyzer #1441](https://github.com/rust-lang/rust-analyzer/issues/1441)
- [Why is the `format!` macro slower than pushing into a String directly? — Stack Overflow](https://stackoverflow.com/questions/63690623/why-is-the-format-macro-slower-than-pushing-into-a-string-directly)
- [Fastest alternative to `format!`](https://users.rust-lang.org/t/fastest-alternative-to-format/116027) · [Efficiency of `println!` and `format!`](https://users.rust-lang.org/t/efficiency-of-println-and-format/52772) · [`format_args!` is slow (rust #76490)](https://github.com/rust-lang/rust/issues/76490)
- [Understanding Rust's Auto-Vectorization](https://users.rust-lang.org/t/understanding-rusts-auto-vectorization-and-methods-for-speed-increase/84891) · [Auto vectorization with Rust — Stack Overflow](https://stackoverflow.com/questions/73118583/auto-vectorization-with-rust) · [How to disable auto vectorization](https://users.rust-lang.org/t/how-to-disable-auto-vectorization-during-compilation-time/104811)
- [Optimizing Rust Performance with Unsafe Code](https://softwarepatternslexicon.com/rust/performance-optimization-patterns/using-unsafe-code-for-performance/)
- [Why is `String`'s equality comparison slower than `&[u8]`? — internals.rust-lang.org](https://internals.rust-lang.org/t/why-is-strings-equality-comparison-slower-than-u8/21866)
- [String vs `&str` — Stack Overflow](https://stackoverflow.com/questions/24158114/what-are-the-differences-between-rusts-string-and-str) · [Converting String to Bytes and Back](https://thelinuxcode.com/rust-string-bytes-bytes-string/) · [`Bytes`](https://docs.rs/bytes/latest/bytes/struct.Bytes.html)
- [PGO is ineffective for Rust — but why? — LLVM discourse](https://discourse.llvm.org/t/pgo-is-ineffective-for-rust-but-why/53044) · [llvm-dev thread](https://lists.llvm.org/pipermail/llvm-dev/2019-September/135383.html) · [BOLT + LTO + PGO discussion](https://users.rust-lang.org/t/rust-article-or-tutorial-idea-optimizing-with-bolt-lto-pgo/70328)
- [Rust Performance on Windows — LTO, PGO and Release Build Optimisation](https://rust-pc.github.io/rust-windows-performance.html) · [Why does LTO increase my binary size? — Stack Overflow](https://stackoverflow.com/questions/52291006/why-does-using-lto-increase-the-size-of-my-rust-binary)

### Parallelism, benchmarking, and build time

- [Data Parallelism with Rust and Rayon — Shuttle](https://www.shuttle.dev/blog/2024/04/11/using-rayon-rust) · [Rayon Data Parallelism Playbook](https://agricidaniel.github.io/rustacean/patterns/Rayon-Data-Parallelism-Playbook) · [Bad performance with rayon? — users.rust-lang.org](https://users.rust-lang.org/t/bad-performance-with-rayon/81290) · [Is rayon always worth it? — r/rust](https://www.reddit.com/r/rust/comments/1348njv/is_rayon_always_worth_it/)
- [Avoid Over-Optimization in Concurrent Code](https://techxcelerate.ntxm.org/docs/rust/concurrency-and-parallelism/concurrency-safety-and-best-practices/avoid-overoptimization-in-concurrent-code/)
- [Optimizing Rust with Criterion benchmarks — CodezUp](https://codezup.com/optimizing-rust-code-for-performance-tips-tricks-benchmarks/)
- [10 Proven Techniques to Maximize Rust Performance Without Sacrificing Safety](https://dev.to/nithinbharathwaj/10-proven-techniques-to-maximize-rust-performance-without-sacrificing-safety-53e8)
- [Rust Compile Time Optimization — RustLab](https://www.rustlab.dev/articles/rust-compile-time-optimization) · [15+ Practical Compile-Time Tips — REINtech](https://reintech.io/blog/how-to-speed-up-rust-compile-times-practical-optimization-tips) · [Reducing Compilation Time — DEV](https://dev.to/sgchris/reducing-compilation-time-practical-tips-4k1) · [Rust slow to compile — TechBloat](https://www.techbloat.com/rust-slow-to-compile-heres-how-to-speed-it-up.html) · [8 Compilation Techniques — elitedev](https://elitedev.in/rust/8_rust_compilation_techniques_that_slashed_my_build_times_from_minutes_to_seconds/)
- [Zero-Copy Serialization with Serde](https://softwarepatternslexicon.com/rust/performance-optimization-patterns/zero-copy-serialization-with-serde/) · [rust-json-parsing-benchmarks](https://github.com/AnnikaCodes/rust-json-parsing-benchmarks) · [How I Beat serde_json on my first day](https://medium.com/@aidenaistar/how-i-beat-serde-json-performance-on-my-first-day-with-rust-df0029cd1322) · [How SIMD made json-steroids faster, then slower, then faster](https://medium.com/@stas29a/how-simd-made-rust-json-steroids-faster-then-slower-then-faster-again-e4dbb3717be4)
- [Should I use binary search? — rust-dsa](https://rust-dsa.github.io/algorithms/search_algorithms/binary_search.html) · [Binary Search vs Linear Search real cost](https://leyaa.ai/codefly/learn/dsa-rust/part-2/dsa-rust-binary-search-vs-linear-search-real-cost-difference/why)
- [Profiling, Allocation, and Concurrency Techniques for High-Performance Rust Services](https://www.prismnews.com/hobbies/rust-programming/profiling-allocation-and-concurrency-techniques-for-high)

---

## Sources deliberately not relied on

- `[lorem, ipsum].join(" ").to_string()` style AI-generated listicles and SEO
  farm pages, and marketplace mirrors of existing `rust-performance` skills
  (e.g. [SkillsMP](https://skillsmp.com/skills/nathan-gage-autoverse-plugins-autoverse-tools-skills-rust-performance-skill-md)). Consulted for discovery, not cited for facts.

## Corrections applied during compilation

- `simd-json`'s README claims no numeric speedup over `serde_json`; the speedup
  figures in the wild are unverified. This skill states only its documented
  behavior (runtime SIMD detection, allocator recommendation, the
  `swar-number-parsing` tradeoff).
- `single_char_pattern`'s own docs say "benchmarks have proven inconclusive" —
  it is listed as a clarity win, not a performance win.
- `large_enum_variant`'s docs explicitly warn it cannot see your variant
  distribution and that boxing can be counter-productive. Listed as measure-first.
- The "PGO is ineffective for Rust" LLVM thread predates modern PGO; the rustc
  book documents PGO as supported and the Performance Book reports 10%+ gains.
  The skill states the process and the caveat, not a contradiction.
- Tokio's 128-operation budget is from the 2020/0.2 article and is described as a
  heuristic picked because it "felt good" — not a user-tunable constant.