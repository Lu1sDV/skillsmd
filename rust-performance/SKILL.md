---
name: rust-performance
description: >
  Use when Rust code is slow, allocates too much, regresses latency or
  throughput, or has bloated binaries and long compile times. Covers the
  evidence pipeline (workload contract, reproducible baseline, profiling,
  single-cause change, re-measurement), optimization priority from algorithm
  down to SIMD, and concrete fixes for allocation, cache, false sharing, lock
  contention, and NUMA. Triggers: cargo bench, Criterion, samply, perf,
  flamegraph, heaptrack, DHAT, cargo-bloat, p99, hot path.
---

# Rust Performance

Optimize from evidence. Define the user-visible metric, reproduce the workload,
establish a stable baseline, profile the dominant cost, change one cause, and
prove both correctness and improvement.

## Quick Reference

Optimization priority — always fix the highest rung first:

```text
1. Algorithm choice    10x-1000x   biggest impact
2. Data structure       2x-10x
3. Reduce allocations   2x-5x
4. Cache locality       1.5x-3x
5. SIMD / parallelism   2x-8x
```

Pick the measurement layer before touching code:

| Question | Tool |
|---|---|
| Is a pure operation faster? | Criterion / Divan microbenchmark |
| Did instruction-level cost change? | iai-callgrind (deterministic, CI-friendly) |
| Where is CPU time spent? | samply, `cargo flamegraph`, perf, Instruments |
| Where are allocations retained? | DHAT, heaptrack, allocator metrics |
| Why is the binary large? | `cargo bloat`, feature inspection |
| What drives compile time? | `cargo build --timings`, `cargo llvm-lines` |
| Does the service meet its SLO? | representative load test + observability |

A microbenchmark never proves end-to-end latency, overload behavior, or memory
bounds. Match the tool to the question.

## Workflow

### 1. Define the performance contract

Record workload, dataset, inputs, concurrency, platform, CPU/memory limits,
toolchain, target, features, allocator, build profile, warm-up, cache state,
and the success metric. Separate throughput from p50/p95/p99 latency, and
steady state from startup/shutdown.

Do not optimize debug builds or synthetic inputs unless they are the real
problem.

### 2. Establish a reproducible baseline

- Verify correctness before benchmarking.
- Use release-like settings (opt-level, codegen-units, LTO, panic strategy,
  target-cpu) deliberately and record them.
- Isolate background load, thermal throttling, and noisy shared runners.
- Keep raw samples and variance, not one average.

### 3. Add regression tests before optimizing

**Correctness-first gate**: if the change touches parsing, I/O, or float
formatting, add or extend the regression test *before* benchmarking.

```text
1. BASELINE   cargo test        current behavior pinned
2. TEST       add regression tests for the code you will change
3. OPTIMIZE   change one cause
4. VERIFY     cargo test        correctness preserved
5. BENCHMARK  cargo bench       improvement measured
```

### 4. Profile before editing

Capture a profile under the failing workload with symbols preserved, using the
same optimized artifact you intend to compare. Separate on-CPU work, waiting,
lock contention, I/O, allocation, page faults, and scheduler overhead.

### 5. Optimize the dominant cause

Common wins: algorithmic complexity, fewer passes, batching, avoiding repeated
parsing or allocation, borrowing instead of cloning, data-layout changes,
reduced synchronization, bounded queues, streaming, feature reduction, moving
CPU work off async workers.

Unsafe, custom allocators, SIMD, lock-free structures, and caching are last
resorts — only after simpler changes fall short, and only with documented
invariants plus tests.

### 6. Track memory, size, and build cost

Peak RSS, retained heap, allocation rate, fragmentation, cache growth, buffer
bounds, binary sections, monomorphization, debug info, enabled features, macro
expansion, incremental versus clean compile time.

### 7. Prove the result

Rerun correctness tests and the exact baseline protocol. Report absolute and
relative numbers, variance, hardware/software context, tradeoffs, and any
secondary-metric regression. Add a durable benchmark or budget only when the
environment reliably detects the threshold.

## Hard Rules

- Never benchmark without documenting the build profile.
- Never optimize without a profile showing the dominant cost.
- Never trade correctness or safety for speed: prove invariants with tests.
- Never micro-optimize cold paths or accept <20% wins at the cost of clarity.
- Keep cold paths readable; spend complexity only in verified hot loops.

## Diagnostics: symptom to cause

| Symptom | Likely cause | Fix |
|---|---|---|
| One core at 100%, many atomic RMW ops, more threads = slower | False sharing | `#[repr(align(64))]` per counter |
| Time in lock/unlock, degrades with threads | Lock contention | thread-local sharding, merge at end; DashMap for concurrent writes |
| Scaling stalls on multi-socket | Cross-NUMA access | `numactl --cpunodebind/--membind`, NUMA-aware pools |
| Allocator pressure, many small allocs | Per-item allocation | preallocate, reuse buffers, `SmallVec`, object pooling |
| O(n²) growth in a loop | Repeated concatenation / rehash | `with_capacity`, batch ops, integer keys over strings |
| High LLC misses on linear scans | Pointer chasing / poor layout | SoA instead of AoS, `Vec`/`VecDeque` over `LinkedList` / `Box` chains |

Patterns, code, and expanded triage tables:
[references/optimization-patterns.md](references/optimization-patterns.md).
Tooling, benchmark templates, build profiles, and report format:
[references/measurement-and-profiling.md](references/measurement-and-profiling.md).

## Completion Criteria

- Representative workload and user-visible metric defined.
- Reproducible baseline recorded before the change.
- Dominant cost identified by profile, not guessed.
- Correctness preserved, proven by targeted tests.
- Re-measured under the same protocol; uncertainty and tradeoffs reported.
- Stable regression check added, or the environment's noise floor explained.

## Data Privacy

This skill does not collect, transmit, or store data. Profiles, heap dumps,
symbols, and benchmark datasets can contain sensitive information — confirm
storage and upload policy before sharing them.
