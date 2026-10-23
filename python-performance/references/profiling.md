# Profiling Python workloads

## Contents

- [Select the smallest useful profiler](#select-the-smallest-useful-profiler)
- [Interpret deterministic function profiles](#interpret-deterministic-function-profiles)
- [Sample running and asynchronous work](#sample-running-and-asynchronous-work)
- [Escalate to system and native evidence](#escalate-to-system-and-native-evidence)
- [Investigate lines and memory](#investigate-lines-and-memory)
- [Turn evidence into a hypothesis](#turn-evidence-into-a-hypothesis)

Confirm interpreter/build, platform and installed tool version; replace example workloads/PIDs. Profile a specific question; validate changes with an unprofiled benchmark.

For live services, use an authorized, bounded capture; record collection overhead
and monitor its effect.

## Select the smallest useful profiler

Compare wall and CPU time without overinterpreting either: parent-process CPU
excludes child work, throttling can inflate wall time, and low aggregate CPU can
hide one saturated thread. Correlate workload and system metrics.

| Question | Tool | Boundary |
| --- | --- | --- |
| Python 3.15 elapsed/CPU concentration? | [`profiling.sampling`](https://docs.python.org/3.15/library/profiling.sampling.html) | Select wall/CPU mode and thread scope; sampling estimates, not exact counts. |
| Existing compatible CPython process? | [`py-spy`](https://github.com/benfred/py-spy) | External samples; attach permissions, interpreter/native support vary. |
| Functions and call paths? | [cProfile](https://docs.python.org/3.14/library/profile.html) / [3.15 profiling.tracing](https://docs.python.org/3.15/library/profiling.tracing.html) | Instrumentation perturbs execution; exact counts do not ensure unbiased timing. |
| Statements in a known hot function? | [line_profiler](https://kernprof.readthedocs.io/en/latest/) | Instrument suspects only; concurrency/async may produce unexpected results. |
| Python/native time, allocations or copying by line? | [Scalene](https://github.com/plasma-umass/scalene) | Select needed modes; verify installed CLI and validate estimates. |
| Retained/peak Python allocations? | [tracemalloc](https://docs.python.org/3.14/library/tracemalloc.html) | Start early; distinguish snapshots from peaks. |
| Allocation sites, including native extensions? | [Memray](https://bloomberg.github.io/memray/run.html) | Allocation traces differ from RSS; native stacks/Python-object tracing add cost. |

Capture a representative broad profile, then narrow unresolved questions. Avoid simultaneous heavyweight profilers; include every contributing worker/task. Preserve functioning `memory_profiler` workflows where appropriate, but choose supported tools for new investigations: it is [no longer actively maintained](https://github.com/pythonprofilers/memory_profiler).

## Interpret deterministic function profiles

Use the broadly compatible command:

```bash
python -m cProfile -o workload.prof workload.py
python -m pstats workload.prof
```

In interactive pstats, use `sort cumulative`, `stats 30`, then `sort time`,
`stats 30`; inspect `callers` and `callees`.

On 3.15, use the new name `profiling.tracing` or compatible `cProfile`; avoid preferring pure-Python `profile`, [deprecated from 3.15](https://docs.python.org/3.15/library/profile.html).

Read the local profile:

```python
import pstats
from pstats import SortKey

stats = pstats.Stats("workload.prof")
stats.sort_stats(SortKey.CUMULATIVE).print_stats(25)
stats.sort_stats(SortKey.TIME).print_stats(25)
stats.print_callers("suspect_function")
```

Use cumulative time (`cumtime`, includes subcalls) for expensive paths, then self time (`tottime`, excludes subcalls) for function work. Do not sum cumulative rows: ancestors overlap. Check repeated calls; follow callers/callees before editing low-self-time coordinators. [pstats](https://docs.python.org/3.15/library/pstats.html)

Compare implementations unprofiled: per-event overhead can bias Python/native comparisons. Investigate expensive native calls with native profiling before rewriting Python lines.

## Sample running and asynchronous work

On Python 3.15, compare CPU activity with elapsed waits:

```bash
python -m profiling.sampling run --mode=cpu --flamegraph -o cpu.html workload.py
python -m profiling.sampling run --mode=wall --flamegraph -o wall.html workload.py
```

Match profiler/target minor versions and free-threaded/GIL builds. Choose `--all-threads` when needed. Treat `--native` as native boundaries, not full C/C++ stacks. Consider `--async-aware` for asyncio; never combine it with CPU/GIL modes, `--all-threads` or `--native`. Check installed help for advanced flags.

For supported CPython runtimes or native stacks, use py-spy with an authorized PID:

```bash
py-spy record -o cpu.svg -- python workload.py
py-spy record -o service.svg --pid 12345
```

- `--subprocesses`: include child Python processes.
- `--native`: platform-dependent; symbols help.
- `--gil`: exclude extensions releasing the GIL; incomplete CPU view.
- `--idle`: change idle-thread filtering.
- `--nonblocking`: avoid sampling pauses; expect possible incomplete/error samples.

Do not promise zero perturbation or change machine security policy to attach. Read flame-graph width as the selected aggregate sample measure, not individual-call chronology. Missing/narrow frames may reflect sampling resolution or scope; compare identical workloads, not graph appearance.

## Escalate to system and native evidence

When Python profiles cannot explain CPU time, correlate native stacks with CPU utilization, context switches, page faults, I/O and throttling. Check symbols/child coverage before interpreting missing frames. Trace lock/pool/queue waits; do not classify every wall-time gap as network I/O.

On supported Linux architectures/builds, CPython 3.12+ exposes Python functions to `perf`. Check `sysconfig.get_config_var("HAVE_PERF_TRAMPOLINE")` and unwinding requirements. Follow the [official walkthrough](https://docs.python.org/3.14/howto/perf_profiling.html) for frame pointers, DWARF and alternative support modes. Use `-X perf` only diagnostically, with bounded sampling and existing permissions; rebenchmark uninstrumented.

## Investigate lines and memory

For a known hot function, import `profile` from `line_profiler`, decorate it, and run with `LINE_PROFILE=1`. Do not infer GPU kernel duration from Python line timing: asynchronous work may appear at a later synchronizing call.

Use Scalene to separate Python/native time, allocation growth or copying. Current upstream uses `scalene run workload.py` and `scalene view`; older CLIs differ. Review generated optimization suggestions independently.

Start `tracemalloc` before relevant allocations. Compare snapshots around repeated equivalent work for retention; use `get_traced_memory()` for current/peak traced bytes. `reset_peak()` resets to current usage, not zero. Snapshots may miss allocations created and freed between them. Record tracer overhead; validate timing separately.

Attribute native allocations:

```bash
memray run --native -o allocations.bin workload.py
memray flamegraph -o allocations.html allocations.bin
```

Use `--native` for native frames; ordinary mode still captures native allocations. Expect much larger/slower traces with `--trace-python-allocators`, which records individual Python allocator events. Generate native reports on the same machine with required shared-library symbols.

Read Memray's default flame graph as allocations live at recorded heap peak. Treat its leak view as allocations still allocated at tracking end, including intentional retention. Choose temporary-allocation/temporal views for those distinct questions. [Report modes](https://bloomberg.github.io/memray/flamegraph.html)

Report allocation volume, peak live heap, retained heap and RSS separately. RSS may lag frees through allocator retention, differ through shared/swapped pages, or rise only upon touching lazily allocated pages. An RSS plateau alone does not prove a Python-object leak. [Memory overview](https://bloomberg.github.io/memray/memory.html)

## Turn evidence into a hypothesis

Record the expensive operation, inputs, frequency and contribution to the user-visible goal. Distinguish CPU/native work, allocation/copying and I/O/lock/queue waits; correlate request/endpoint or batch timing when workloads share a process.

Form one falsifiable hypothesis: conversion copies, duplicate database requests, or process-boundary overhead for tiny tasks dominate. Change that mechanism; repeat the profile and uninstrumented end-to-end measurement.

Preserve profile, command, workload, time window and scope; disclose excluded workers, missing symbols, sampling errors and incompatible features. Stop profiling once evidence supports an experiment; validate with [benchmarking](benchmarking.md).
