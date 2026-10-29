# Python Performance

Diagnose Python bottlenecks and evaluate optimizations against representative
workloads. Use it for CPU, memory, I/O, database, concurrency, startup, or
numerical performance problems, and for reviewing whether a proposed speedup
preserves required behavior.

## Use

```text
Use $python-performance to profile this workload, identify the limiting resource, and compare one justified optimization with the baseline.
```

The [skill workflow](SKILL.md) establishes the measurement contract, gathers
evidence, changes one mechanism, and compares equivalent work. Reports retain
correctness checks, variability, resource tradeoffs, and reproduction commands.
Load supporting references only for the problem being investigated.

## Contents

- [Profiling](references/profiling.md): select evidence for the suspected bottleneck.
- [Benchmarking](references/benchmarking.md): compare matched runs and avoid misleading speedups.
- [Report template](references/report-template.md): record the contract, evidence, and decision.
- [Environment helper](scripts/capture_environment.py): capture interpreter and package metadata without importing target packages; run it with the workload's interpreter.
- [Sources and scope](references/sources-and-scope.md): provenance, primary authorities, and version-sensitive guidance.

## Install

Copy the complete `python-performance/` folder into the skill directory recognized
by your agent, preserving its references, helper script, and agent metadata.
