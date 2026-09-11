# Measurement and Profiling

## Profiling commands

```bash
cargo build --release
samply record ./target/release/app          # sampling profiler, Firefox UI
cargo flamegraph -- <args>                  # flamegraph from perf
perf stat -d ./target/release/app           # IPC, cache, LLC misses, atomics
heaptrack ./target/release/app              # allocation / retained-heap tracking
valgrind --tool=cachegrind ./target/release/app
valgrind --tool=dhat ./target/release/app
numactl --hardware                          # NUMA topology
```

Preserve symbols (`debug = true` in the bench/release profile) and profile the
same artifact you benchmark. A stripped or debug artifact measures something
else.

## Build profiles

Keep profiles explicit — the profile changes the result more than most code
edits.

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

```rust
use criterion::{black_box, criterion_group, criterion_main, BenchmarkId, Criterion};

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

`black_box` every input and result so the optimizer cannot delete the work.

## CLI comparison

```bash
hyperfine --warmup 3 \
    './target/release/app-before input.txt' \
    './target/release/app-after  input.txt'

hyperfine --warmup 3 --runs 10 --export-markdown bench.md \
    './target/release/app input.txt'
```

## Regression gates

- Compare the same commit, toolchain, dependency graph, and hardware.
- Record raw samples and dispersion, not a single mean.
- Use iai-callgrind for instruction-count gates: deterministic and immune to
  runner noise; wall-clock gates on shared CI are flaky.
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
[ ] Benchmark script included (Criterion or hyperfine)
[ ] Before/after numbers on the same machine
[ ] Build profile explicitly noted
[ ] >50% improvement: flamegraph/perf evidence attached
[ ] Unsafe code: invariants documented and tested
[ ] Secondary metrics checked (memory, binary size, compile time)
```
