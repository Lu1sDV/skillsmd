---
name: rust-performance
description: >
  Use when writing or reviewing performance-sensitive Rust, reducing allocations,
  profiling slow code, investigating latency or throughput regressions, or diagnosing
  binary size and compile time. Covers cost-aware implementation, representative
  baselines, profiling, measured changes, and regression checks. Triggers include
  hot path, zero-copy, Criterion, cargo bench, samply, perf, flamegraph, DHAT,
  cargo-bloat, p99, contention, and performance code review.
---

# Rust Performance

Keep cold code readable. For known hot paths, make ownership, allocation,
layout, and concurrency costs deliberate. For an optimization claim, reproduce
the workload and establish before/after evidence; a plausible rewrite is not a
measured improvement.

## Load only the relevant reference or section

| Task | Read |
|---|---|
| Allocation, buffer reuse, cloning, small collections | [Allocation](references/anti-patterns.md#1-allocation) |
| Iterator overhead, batching, layout, or hashing | [Iterators](references/anti-patterns.md#2-iterators), [layout](references/anti-patterns.md#3-data-layout), or [hashing](references/anti-patterns.md#4-hashing) |
| Async worker stalls, locks, queues, task granularity | [Concurrency](references/anti-patterns.md#5-concurrency) |
| Compiler settings, binary/build cost, lint review | [Build configuration](references/anti-patterns.md#6-build-configuration) or [Clippy](references/anti-patterns.md#7-clippy-gates) |
| Layout changes, sharding, SIMD, or NUMA | [Optimization patterns](references/optimization-patterns.md) |
| Profiler/benchmark commands and result reporting | [Measurement and profiling](references/measurement-and-profiling.md) |

Historical benchmark figures and their conditions live in the references. They
suggest experiments; they do not predict a speedup in the current project.

## Establish the task and contract

1. Read the callers, repository instructions, toolchain, edition/MSRV, targets,
   feature selection, allocator, and build profiles. Preserve compatibility and
   the actual deployment constraints.
2. Separate **initial writing/review** from **diagnosing a regression or claiming
   a speedup**. Ordinary ownership choices do not require a profiler. New
   performance-motivated complexity requires evidence that its cost matters.
3. Name the user-visible metric: latency distribution, throughput, peak/retained
   memory, allocations, artifact size, or developer build time. State acceptable
   tradeoffs and the workload that must retain its behavior.

## Writing and review gates

- **Preserve semantics before reducing work.** Keep parsing errors, text
  terminators, ordering, floating-point requirements, and partial I/O behavior.
  Reusing a line buffer must not turn precise newline removal into `trim()`.
- **Give ownership a reason.** Borrow for inspection; retain ownership when the
  caller needs an independent value. `Arc::clone` shares a handle; an owned
  parameter can accept a move without allocating. Do not remove useful clones
  merely to satisfy a blanket rule.
- **Make repeated storage costs visible.** Reserve a known bound, reuse buffers
  where lifetimes permit, and avoid collecting solely to iterate. Account for
  retained capacity; `SmallVec`, pooling, and interning introduce their own costs.
  Iterator bounds must be truthful, not optimistic allocation hints.
- **Treat micro-rewrites as candidates.** Iterator versus loop, `filter_map`,
  `chain`, copied items, boxing, and inlining have workload-dependent outcomes.
  Preserve the contract and measure the actual hot path before preferring one.
- **Check layout and key domains.** Boxing trades inline size for allocation and
  indirection. Narrow indices only after validating bounds. Preserve established
  `repr(C)` layouts. Change a hasher only after measuring and reviewing whether
  keys can be attacker-controlled.
- **Keep async workers available.** Move blocking work off runtime workers;
  bound CPU concurrency and queued/task state. A blocking mutex guard should not
  span `.await`; an async mutex may, but still needs a cancellation and wait-cycle
  review. A channel capacity alone does not bound all waiting tasks or payloads.
- **Diagnose sharing before padding.** Contention on the same atomic needs less
  sharing, batching, or sharding. Distinct hot locations on one cache line may
  need padding; confirm the addresses and target layout first.
- **Review configuration as a tradeoff.** LTO, codegen units, target CPU, allocator,
  and PGO can change portability, size, and build time as well as execution time.
  Clippy suggestions are review prompts; use the project's selected lint policy.

## Diagnose and measure

### 1. Define a reproducible workload

Record dataset shape, inputs, concurrency, CPU/memory limits, hardware, dependency
and compiler versions, target/features, allocator, profile, warm-up, and cache
state. Separate steady state from startup/shutdown and throughput from tail
latency. Use the deployed profile unless debug/build performance is the actual
problem; say explicitly when a synthetic workload is the intended target.

### 2. Preserve a baseline and correctness oracle

Run the relevant existing checks. Before changing parsing, I/O, numeric behavior,
or another fragile contract, add a focused regression if coverage is missing.
Record the baseline artifact/revision and raw samples with dispersion. Control
background load, thermal effects, and noisy runners enough to resolve the desired
change. Decide whether setup, input restoration, and destruction belong in timing.

### 3. Choose the measurement layer

| Question | Candidate evidence |
|---|---|
| Does one operation cost less? | Criterion/Divan with a representative input and timed region |
| Did instruction-level work change? | iai-callgrind with controlled inputs and configuration |
| Where is CPU time spent? | samply, flamegraph, perf, or platform profiler with symbols |
| Where does memory go? | Allocation/retention profiler, allocator metrics, and peak RSS |
| Why are build/artifact costs high? | `cargo build --timings`, `cargo llvm-lines`, `cargo bloat`, feature inspection |
| Does a service meet its objective? | Representative load, latency distribution, overload behavior, observability |

A microbenchmark does not establish service latency or memory bounds. Hardware
counters explain a result; they do not replace the user-visible metric.

### 4. Find and change the dominant cause

Profile the representative workload with symbols using the artifact being
compared. Distinguish CPU work from waiting, locks, I/O, allocation, page faults,
and scheduler overhead. Prioritize the measured bottleneck; simpler algorithm,
representation, and allocation changes are good candidates when they address it.
There is no fixed optimization order or portable speedup multiplier.

Change one cause at a time. Unsafe code, custom allocation, SIMD, lock-free
structures, and caches require a concrete need, explicit invariants, and tests;
prefer a simpler adequate change. Preserve synchronization and lifetime contracts.

### 5. Re-measure and report

Run the correctness checks and the same baseline protocol on the candidate.
Report absolute and relative numbers, variation, revisions, environment, and
tradeoffs. Check relevant secondary metrics: tail latency, peak/retained memory,
allocation rate, binary size, compile time, or startup cost. Retain a durable
benchmark/budget only where its noise floor can detect the intended regression.

## Completion criteria

- Writing/review decisions preserve behavior and avoid speculative complexity.
- Optimization claims identify the workload, baseline, dominant cost, and changed
  cause; no claim exceeds the measurements actually performed.
- Correctness checks cover the changed contract and report their execution scope.
- Before/after results include uncertainty and relevant secondary regressions.
- Missing tools, untested targets, and proposed checks remain explicit limits.

Profiles, symbols, heap dumps, and datasets may contain sensitive information;
follow the project's storage/sharing policy. [Sources](references/sources.md)
provide attribution and deeper evidence, not a required preload.
