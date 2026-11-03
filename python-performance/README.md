# Python Performance

Diagnose Python bottlenecks and evaluate optimizations against representative
workloads. Use it for CPU, memory, I/O, database, concurrency, startup, or
numerical performance problems, and for reviewing whether a proposed speedup
preserves required behavior.

Baseline: **CPython 3.15**, latest stable patch **3.15.2**, verified **2026-11-03**
against the [Python release page](https://www.python.org/downloads/release/python-3152/).
Check dependency/build compatibility separately; do not silently upgrade a
consuming project's declared support policy.

## Use

```text
Use $python-performance to profile this workload, identify the limiting resource, and compare one justified optimization with the baseline.
```

The [skill workflow](SKILL.md) establishes the measurement contract, gathers
evidence, changes one mechanism, and compares equivalent work. Reports retain
correctness checks, variability, resource tradeoffs, and reproduction commands.
Load supporting references only for the problem being investigated.

## Contents

- [Profiling](references/profiling.md): select bounded evidence, interpret call paths and diagnose slow test suites.
- [Benchmarking](references/benchmarking.md): compare matched runs, calibrate noise and validate on held-back workloads.
- [Memory and caching](references/memory-and-caching.md): distinguish peaks, retention and non-heap resource leaks.
- [Report template](references/report-template.md): record the contract, evidence, and decision.
- [Environment helper](scripts/capture_environment.py): capture interpreter and package metadata without importing target packages; run it with the workload's interpreter.
- [Sources and scope](references/sources-and-scope.md): provenance, primary authorities, and version-sensitive guidance.

Community curation retains useful decision procedures after checking maintainer
documentation. It excludes transferred speedup/overhead percentages, mandatory
statistics engines, native-kernel templates and package-version names treated as
compatibility guarantees. Detailed decisions live in Sources and scope so normal
skill use loads only the relevant technical guide.

## Install

Copy the complete `python-performance/` folder into the skill directory recognized
by your agent, preserving its references, helper script, and agent metadata.
