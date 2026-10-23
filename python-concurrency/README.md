# python-concurrency

A self-contained skill for choosing Python concurrency mechanisms and making
worker ownership, bounded admission, failure, cancellation, and shutdown explicit.
It covers threads/processes/executors, asyncio structured lifetime, and CPython
3.14 free-threading and interpreter semantics without requiring sibling skills.

## Install

From a repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r python-concurrency ~/.claude/skills/
```

Preserve local changes before replacing an existing installation. Copy the
entire bundle so its references and license remain available. Installation adds
instructions, not runtime dependencies; no package or framework is installed.

## Usage prompts

- "Choose threads, asyncio, or processes for this mixed I/O and CPU pipeline."
- "Review this TaskGroup for cancellation, partial effects, and worker cleanup."
- "Bound this queue without leaving an unbounded backlog of waiting tasks."
- "Explain why cancelling to_thread did not stop my blocking operation."
- "Make this worker pool portable to Python 3.14 forkserver and interpreter isolation."

## Reference index

| File | Load for |
|---|---|
| [SKILL.md](SKILL.md) | Mechanism routing, contract workflow, high-risk pitfalls, completion evidence |
| [Execution and coordination](references/execution-and-coordination.md) | Threads, synchronization, bounded queues, rate limiting, executors, process ownership/smoke recipe, deadlock diagnosis |
| [Async lifecycle](references/asyncio-lifecycle.md) | TaskGroup failure, deadlines, cancellation, backpressure, queue accounting, thread bridging, shutdown |
| [Runtime versions](references/runtime-versions.md) | Version gates, GIL probes, free-threaded builds, start methods, 3.14 interpreters/context flags |

## Runnable examples and limits

From inside this bundle, including an isolated copied installation:

```sh
python3 -m doctest references/*.md
```

Or from the repository root:

```sh
python3 -m doctest python-concurrency/references/*.md
```

These commands are verification instructions, not a claim of passing checks.
Run in an ordinary Python process, not an already-running notebook event loop.
All `pycon` fences are dependency-free and use Python 3.11+ except the explicitly
guarded interpreter check, which executes only on CPython 3.14+. The examples
exercise sibling failure/cleanup, zero-budget cancellation cleanup,
queue ordering/accounting/backpressure and error paths,
thread invariant protection, monotonic rate-limit boundaries, and the continued
lifetime of a thread after its asyncio awaiter is cancelled. They use local
primitives and bounded work, not a network service or arbitrary sleeps.

Thread/queue five-second deadlines are watchdogs, not latency assertions.
An integration harness should put an outer process deadline around documentation
checks too; event-loop timeouts cannot interrupt non-yielding code. Finite tests
do not prove liveness under every schedule or establish performance.

### Optional real-process and interpreter-executor checks

The complete, clearly marked process recipe lives in
[Execution and coordination](references/execution-and-coordination.md#optional-real-process-smoke-recipe).
Save that `python` fence as `/tmp/python-concurrency-process-smoke.py`, then run:

```sh
python3 /tmp/python-concurrency-process-smoke.py spawn
python3 /tmp/python-concurrency-process-smoke.py forkserver
```

Run forkserver only where `multiprocessing.get_all_start_methods()` includes it.
These are real-process smoke commands, not part of doctest: they need an
importable writable script path, process creation permissions, and an outer
startup/shutdown timeout. The recipe checks empty/successful mapping and worker
exception propagation; it does not benchmark speedup or all shutdown failures.

The [runtime reference](references/runtime-versions.md) also has an optional
`InterpreterPoolExecutor` recipe requiring CPython 3.14+, separately from its
guarded direct-interpreter doctest. A normal GIL-enabled run does not validate a
free-threaded deployment, extension compatibility, native thread safety, or
multi-core gains. Re-run the relevant checks on the actual build/dependencies.
Multiprocessing is unavailable on Android/iOS/WASI; interpreter/executor APIs
are unavailable on WASI. Preserve a consuming project's supported version floor.

## Source map and decisions

Adapted from **StructWeave-Algorithms** Python content at commit
`0b88a786ef09681717a805d9f7e0b195ab610f6c`, rather than mutable branch URLs:

| Pinned source | Local coverage |
|---|---|
| [07 — Concurrency and async](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/07-concurrency-async.md) | All major topics: selection/GIL, thread primitives, queues, process pools/IPC/shared state, futures, asyncio scheduling/lifetime/limits, free threading/interpreters; interview ordering/queue/limiter/RW-lock material consolidated into standard-primitives guidance |
| [13 — Anti-patterns and best practices, concurrency section and async exercise](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/13-anti-patterns-best-practices.md#concurrency-anti-patterns) | Compound updates, workload selection, blocking inside async functions, missing awaits, background ownership, shared async state |
| [14 — Interview traps, GIL implications and async/await gotchas](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/14-interview-trap-questions.md#gil-implications) | GIL limits, guarded process startup, await/scheduling distinction, host event loops, joining background tasks |

Consolidation/correction decisions:

**Entrypoint concision:** keep routing and lifetime policy always loaded; detailed
mechanisms and runnable checks live in the directly linked references, with
contents lists for navigation. The return-42 TaskGroup check was removed because
the retained sibling-failure/cleanup and bounded-pipeline checks exercise
meaningful TaskGroup behavior instead.

1. **Organize by lifetime and workload, not interview order.** Standard queues,
   events, conditions, and locks replace custom blocking-queue/ordering machinery.
   Ordinary locks are the starting point instead of the source's reader-preference
   RW-lock sketch, whose fairness/starvation policy is unspecified.
2. **Do not promise observed races or speedups.** An unlocked counter is not a
   portable atomic contract, but the source's exact claim that it will print a
   smaller count is not a reliable regression test on modern CPython. Processes,
   free-threading, and interpreters are candidates, not universal speed wins.
3. **Correct async race and lifetime claims.** A plain built-in list append in
   one loop thread is not itself a task-interleaving lost update. Invariants
   spanning suspension need ownership/synchronization. Bare `create_task()` is
   replaced with explicit supervision; no nested-loop patch is recommended.
4. **Fix queue completion semantics.** Account for sentinels too; distinguish
   `task_done()` from business success. Do not wait for queue completion after a
   failed TaskGroup has discarded queued work. Bound backlog as well as workers.
   If bounded thread-queue publication fails, inspect the worker before reporting
   `Full`; otherwise a dead consumer's original error is masked. The regression
   includes trailing work after a rejected item, not just a singleton failure.
5. **Separate rate from concurrency.** A semaphore limits simultaneous work,
   not requests per time window; elapsed-time admission uses a monotonic clock.
6. **Use actual 3.14 APIs and limits.** Interpreter `.exec()`/`.call()` replace
   the source's nonexistent `.run()`. Interpreters need threads for parallelism,
   compatible extensions, and explicit destruction. They are not a security
   sandbox for the source's proposed untrusted-code use case.
   The isolated CPython 3.14.8 smoke exposed `prepare_main(list)` rejection:
   it requires shareable values, unlike `call`'s broader transfer support.
   The corrected example explicitly transfers JSON text and verifies that
   mutation of the decoded list does not alter the caller's original.
7. **Distinguish build and runtime.** Free threading began experimentally in
   3.13 and is supported but optional in 3.14. GIL state, extension imports,
   process start defaults, and context flags are checked explicitly; thread
   context inheritance is not unconditional. Patch-level doc/runtime differences
   are recorded, including the 3.14.9 no-writable-temp forkserver fallback.
8. **Expand cancellation from first-party contracts.** TaskGroup observes sibling
   cleanup; deadlines do not roll back effects. Cancelling a `to_thread` awaiter
   cannot stop an already-running callable; signal/observe its real lifetime.

Sensitive claims were checked against the Python documentation linked beside
each reference. Those links are supporting sources, not dependencies required
to use the installed skill. The original upstream MIT license is preserved
verbatim in [LICENSE.upstream](LICENSE.upstream).
