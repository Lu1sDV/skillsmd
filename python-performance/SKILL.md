---
name: python-performance
description: >
  Use when profiling, benchmarking, or optimizing Python CPU, memory, I/O,
  database, concurrency, startup, or numerical workloads; investigating leaks
  and performance regressions; reviewing optimization proposals; or validating
  before/after performance without changing behavior.
---

# Python Performance

## Workflow

1. **Define the contract.** Inspect the project, tests and telemetry. Set a primary
   metric, acceptance threshold, representative inputs and guardrails. Record
   runtime/dependencies, deployment limits, cold/warm state and measurement
   boundaries. Infer routine details; ask only for missing experiment-changing facts.
2. **Find the limiting resource.** Establish a baseline, then collect bounded
   evidence for CPU, waiting, allocation, queries or startup. Follow the relevant
   reference below; investigate observations before choosing an optimization.
3. **Rank mechanisms.** Compare benefit, implementation cost, correctness risk and
   maintenance; state cause, affected fraction, tradeoff and falsifying measurement.
   Prefer removing work, better algorithms
   and representations, then bounded streaming/batching/reuse, justified caching,
   concurrency or compilation. Reserve syntax tuning for measured hot paths.
4. **Change one mechanism.** Preserve values, types, ordering, duplicates,
   mutation/aliasing, exceptions, precision, transactions and cancellation.
   Use existing dependencies and supported versions; add complexity only for a
   demonstrated need. Run existing tests plus focused checks for changed semantics.
5. **Compare equivalent work.** Read the benchmarking reference before claiming
   improvement. Use repeated, matched, unprofiled runs; include required setup,
   conversion, transfers and result consumption. Report variability, cold versus
   steady state, and relevant memory/latency/error/cost guardrails. Retain raw results.
6. **Decide.** Re-profile material improvements. Accept only useful gains that
   justify maintenance and resource costs; otherwise retain the simpler version.
   Broaden verification only for a concrete remaining risk. If execution or inputs
   are unavailable, give a reproducible plan and label changes as hypotheses.

## Load by task

Load only the relevant reference or section; do not read the whole bundle by default.

| Task | Reference |
|---|---|
| Locate CPU, wall-time, native or allocation hotspots | [Profiling](references/profiling.md) |
| Establish a speedup, service-load result or regression gate | [Benchmarking](references/benchmarking.md) |
| Reduce repeated work; choose containers, iteration or representations | [Algorithms and Python](references/algorithms-and-python.md) |
| Diagnose peaks, retention, caches or GC | [Memory and caching](references/memory-and-caching.md) |
| Choose workers/async; inspect GIL, quotas, imports or runtimes | [Concurrency and runtime](references/concurrency-and-runtime.md) |
| Improve queries, transactions, HTTP, files or serialization | [I/O and databases](references/io-and-databases.md) |
| Optimize arrays/dataframes, compilation or existing GPU work | [Numerical and data](references/numerical-and-data.md) |
| Review a proposed optimization for common failure modes | [Antipatterns](references/antipatterns.md) |
| Record the contract, reproduction and results | [Report template](references/report-template.md) |
| Check provenance, version gates or maintain this skill | [Sources and scope](references/sources-and-scope.md) |

Capture baseline metadata with the workload's interpreter:

```sh
python /path/to/python-performance/scripts/capture_environment.py --package numpy > environment.json
```

The helper describes its own process without importing target packages. Record
deployment limits separately; recheck GIL state after application extension imports.

## Handoff

Report objective/environment, bottleneck evidence, change/rationale, correctness
checks, before/after metrics with units and variability, tradeoffs and reproduction
commands. Keep unknowns explicit; distinguish measurements from estimates and cite
version-sensitive or library-specific claims. Never improve a benchmark by dropping
results, validation, precision, failed requests or required work.
