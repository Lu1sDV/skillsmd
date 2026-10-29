# Measurement and Profiling

## Profiling commands

```bash
cargo build --release
samply record ./target/release/app          # sampling profiler, Firefox UI
cargo flamegraph -- <args>                  # flamegraph from perf
perf stat -d ./target/release/app           # counters; available events vary by CPU
heaptrack ./target/release/app              # allocation / retained-heap tracking
valgrind --tool=cachegrind ./target/release/app
valgrind --tool=dhat ./target/release/app
numactl --hardware                          # NUMA topology
```

Preserve symbols (`debug = true` in the selected profile) and profile the artifact
you benchmark. Keep optimization settings representative; debug-build performance
is a valid separate target, while stripped symbols can obscure attribution.

## Build profiles

Keep profiles explicit. These settings are comparison candidates, not a faster
default for every project; preserve the existing baseline before changing them.

```toml
[profile.release]
opt-level = 3
lto = "thin"
codegen-units = 1

[profile.release-lto]
inherits = "release"
lto = "fat"

[profile.bench]
inherits = "release"
debug = true   # profiling symbols
```

Always state which profile produced every number.

## Criterion benchmark template

Adapt this schematic harness to the project's Criterion version and real fixture
and implementation functions; it is not a standalone example.

```rust,ignore
use std::hint::black_box;
use criterion::{criterion_group, criterion_main, BenchmarkId, Criterion};

fn bench_variants(c: &mut Criterion) {
    let mut group = c.benchmark_group("processing");
    for size in [100, 1000, 10000] {
        let data = generate_data(size);
        group.bench_with_input(BenchmarkId::new("original", size), &data,
            |b, d| b.iter(|| original_impl(black_box(d))));
        group.bench_with_input(BenchmarkId::new("optimized", size), &data,
            |b, d| b.iter(|| optimized_impl(black_box(d))));
    }
    group.finish();
}

criterion_group!(benches, bench_variants);
criterion_main!(benches);
```

Use `black_box` where values would otherwise permit unrealistic elimination or
constant folding; it is a best-effort optimization barrier, not a guarantee.
Choose the timed region deliberately: `iter` is suitable when repeated calls and
result destruction match the question; a consuming/mutating input may need fresh
setup via `iter_batched` or `iter_batched_ref`. Excluding setup/drop is valid only
when the stated metric excludes those costs. Match batch size to memory limits.
See [Criterion timing loops](https://bheisler.github.io/criterion.rs/book/user_guide/timing_loops.html)
and [`black_box`](https://doc.rust-lang.org/std/hint/fn.black_box.html).

## CLI comparison

```bash
hyperfine --warmup 3 \
    './target/release/app-before input.txt' \
    './target/release/app-after  input.txt'

hyperfine --warmup 3 --runs 10 --export-markdown bench.md \
    './target/release/app input.txt'
```

## Regression gates

- Record baseline and candidate revisions; hold toolchain, dependency graph,
  hardware, workload, and build settings fixed except for the intended change.
- Record raw samples and dispersion, not a single mean.
- Consider iai-callgrind for instruction-count gates; control inputs and execution
  nondeterminism. Wall-clock gates on shared CI need a measured noise floor.
- Enforce a threshold only where the noise floor is measurably below it;
  otherwise report the trend and gate manually.

## Report format

```markdown
## Performance Results

**Machine**: <CPU/arch>, <RAM>
**Profile**: release-lto (lto=fat, codegen-units=1)
**Dataset**: <size/shape>

| Metric | Before | After | Change |
|---|---|---|---|
| Time (mean) | 45.2s | 12.3s | -73% |
| Memory (peak) | 2.1 GB | 850 MB | -60% |
| Throughput | 22 MB/s | 81 MB/s | +3.7x |

**Profiling**: flamegraph shows the hot path moved from X to Y.
**Tradeoffs**: <secondary metric regression, memory for speed, complexity cost>
```

## Performance change checklist

```
[ ] Regression tests added/extended for changed paths
[ ] Tests pass BEFORE benchmarking
[ ] Benchmark script or exact reproduction commands included
[ ] Before/after numbers on the same machine
[ ] Build profile explicitly noted
[ ] Profile evidence explains the changed dominant cost
[ ] Unsafe code: invariants documented and tested
[ ] Secondary metrics checked (memory, binary size, compile time)
```
