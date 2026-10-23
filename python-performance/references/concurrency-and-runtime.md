# Concurrency, runtime, and startup performance

## Contents

- [Choose an execution model](#choose-an-execution-model)
- [Inspect runtime capabilities](#inspect-runtime-capabilities)
- [Budget concurrency](#budget-concurrency)
- [Use threads and free threading correctly](#use-threads-and-free-threading-correctly)
- [Bound asynchronous pipelines](#bound-asynchronous-pipelines)
- [Use processes and subinterpreters deliberately](#use-processes-and-subinterpreters-deliberately)
- [Measure startup and interpreter changes](#measure-startup-and-interpreter-changes)

## Choose an execution model

Select experiments from measured bottlenecks; compare actual workloads without assuming speedups.

| Observed work | Candidate | Constraints |
| --- | --- | --- |
| Blocking network/filesystem calls | Bounded threads | Remote/connection capacity, blocking duration, shared state |
| Independent waits using async libraries | Bounded async admission | Loop stalls, downstream capacity |
| Pure-Python CPU, GIL enabled | Reduce operations; then processes/isolated interpreters | Initialization, serialization, memory, load balance |
| Native CPU releasing the GIL | Threads/native parallelism | Verify release and thread safety; native pools, memory bandwidth |
| CPU, verified free-threaded build | Threads after compatibility/correctness checks | Shared-object contention, synchronization |
| Import-dominated short command | Reduce initialization | Startup, first-use latency |

Classify costly operations, distinguishing bytecode from native work: ordinary threads share one GIL within a GIL-enabled interpreter; extensions can release it for suitable native work/blocking I/O. [CPython thread states/GIL](https://docs.python.org/3.15/c-api/threads.html), [threading](https://docs.python.org/3.15/library/threading.html)

## Inspect runtime capabilities

Record implementation, exact version/build, OS, dependencies, effective limits; match documentation. Probe configuration rather than infer it from version:

```python
import concurrent.futures as cf
import inspect
import sys
import sysconfig

capabilities = {
    "free_threaded_build": sysconfig.get_config_var("Py_GIL_DISABLED") == 1,
    "gil_enabled_now": getattr(sys, "_is_gil_enabled", lambda: None)(),
    "interpreter_pool": hasattr(cf, "InterpreterPoolExecutor"),
    "map_buffersize": "buffersize" in inspect.signature(cf.Executor.map).parameters,
}
```

Treat `None` as unknown GIL state. Distinguish build support from live `sys._is_gil_enabled()` state; recheck **inside the application after extension imports**, which may re-enable the GIL if unsupported. A separate capture helper cannot establish eventual application state. [Free-threading detection/compatibility](https://docs.python.org/3.15/howto/free-threading-python.html)

## Budget concurrency

Sweep a few worker/batch sizes; record throughput, tail latency, errors, CPU utilization, peak memory, queue depth, and end-to-end initialization/transfer. Larger batches may reduce scheduling overhead but delay small tasks or unbalance worker loads.

Budget server processes, application workers, and BLAS/OpenMP threads together. NumPy may use threaded BLAS; apply backend controls or `threadpoolctl` as needed. [NumPy configuration](https://numpy.org/doc/stable/reference/global_state.html)

Inspect resources: `os.process_cpu_count()` (3.13+) reflects CPUs usable by the calling thread, affinity, and configured overrides; it cannot establish the full container CPU-time budget. [CPU counts](https://docs.python.org/3.15/library/os.html#os.process_cpu_count)

On Linux, investigate throttling via the relevant cgroup's `cpu.max`, `cpu.stat` throttling statistics, and inherited constraints. Quotas cap CPU time per period regardless of workers. [cgroup v2 CPU](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html#cpu)

Bound pending tasks, payloads, connections, and retained results alongside active workers. Choose backpressure, rejection, or durable buffering to requirements. Beyond sustainable downstream capacity, concurrency can relocate waits into queues. Check contention, nested pools, and bandwidth before adding workers.

## Use threads and free threading correctly

Treat free threading as a separate runtime choice: optional since 3.13, supported since 3.14, still optional. Verify installation mode, dependencies, and profiler support. [PEP 779](https://peps.python.org/pep-0779/)

Protect compound/read-modify-write invariants with locks or owned, partitioned state; container protection is insufficient. Test ordering, concurrent failures, cancellation, reproducibility. Measure one-thread overhead, scaling, and memory. [Thread safety](https://docs.python.org/3.15/howto/free-threading-python.html#thread-safety)

Check each NumPy operation: many native routines release the GIL; object-dtype operations generally do not. Prefer worker-owned arrays/shared read-only inputs. Concurrent mutation/resizing can race or crash; free threading adds object-dtype hazards. [NumPy thread safety](https://numpy.org/doc/stable/reference/thread_safety.html)

## Bound asynchronous pipelines

Find loop stalls from blocking clients, synchronous filesystem work, CPU loops, serialization, and logging before adding tasks. Asyncio debug mode's configurable slow-callback threshold defaults to 100 ms; rebenchmark without diagnostics. [Asyncio development](https://docs.python.org/3.14/library/asyncio-dev.html)

Use `asyncio.to_thread()` (3.9+) for thread-suitable blocking work. With the GIL enabled, pure-Python CPU normally remains serial; native GIL-releasing work is an exception. Evaluate process/interpreter executors for substantial CPU work. [to_thread](https://docs.python.org/3.14/library/asyncio-task.html#asyncio.to_thread)

Stream through `asyncio.Queue(maxsize=N)`, positive `N`, and fixed consumers; full queues block producers. Bound task creation/admission: semaphores limit protected operations, not already-allocated tasks. [Queues](https://docs.python.org/3.15/library/asyncio-queue.html), [semaphores](https://docs.python.org/3.15/library/asyncio-sync.html#asyncio.Semaphore)

Use `TaskGroup` (3.11+) for shared task lifetime and sibling cancellation on failure. Preserve semantics: `gather()` propagating the first exception does not automatically cancel other awaitables. Clean up with `try/finally`; normally propagate `CancelledError`. Apply external-wait deadlines and verify cleanup. [Tasks/cancellation](https://docs.python.org/3.14/library/asyncio-task.html)

Stream results/retain required aggregates. Measure connection-pool waits, retry load, downstream limits. Inspect suspension points: `async def` leaves synchronous work blocking.

## Use processes and subinterpreters deliberately

Send compact inputs, reuse workers, batch to amortize transfer. Put callables in importable modules; guard process-starting entry points with `if __name__ == "__main__":`. Verify serialization: REPL-local functions, lambdas, closures may fail. [Multiprocessing guidelines](https://docs.python.org/3.14/library/multiprocessing.html#programming-guidelines)

Inspect start methods: 3.14 removed default `fork` everywhere; supported POSIX generally uses `forkserver`, macOS/Windows `spawn`. Check patch-level exceptions and available methods. Accept caller-supplied library contexts; avoid forcing `fork` to recover older benchmark results. [Start methods](https://docs.python.org/3.14/library/multiprocessing.html#contexts-and-start-methods)

Measure parent/worker memory together. Consider shared memory when repeated large-buffer copies demonstrably dominate; specify ownership, synchronization, `close()`, appropriate `unlink()` cleanup. Arbitrary Python objects are not transparently shared. [Shared memory](https://docs.python.org/3.15/library/multiprocessing.shared_memory.html)

On 3.14+, `Executor.map(..., buffersize=N)` bounds submissions with unyielded results. Tune `chunksize` separately; it affects process pools only. Avoid waiting for same-pool tasks inside saturated pools. `cancel_futures=True` cancels pending tasks, not running work; timeouts do not prove execution stopped. [Executors](https://docs.python.org/3.14/library/concurrent.futures.html)

Evaluate `InterpreterPoolExecutor` (3.14+): isolated interpreters, each with its own GIL; pickled callables, arguments, and results. Measure transfer costs. [InterpreterPoolExecutor](https://docs.python.org/3.14/library/concurrent.futures.html#interpreterpoolexecutor)

Account for isolated imports/runtime state; verify extension compatibility. Mutable objects are generally copied, not implicitly shared. Creating an interpreter alone starts no thread; the executor combines both. Isolation is no security boundary. [Multiple interpreters](https://docs.python.org/3.15/library/concurrent.interpreters.html)

## Measure startup and interpreter changes

Measure fresh-process startup separately from warm services. Attribute imports with `python -X importtime -m your_package`; 3.14+ adds `-X importtime=2` for cached imports. Multithreaded output may be unreliable; rebenchmark without tracing. `python -O` changes assertions/`__debug__`; avoid treating it as a general speed switch. [Command-line options](https://docs.python.org/3.15/using/cmdline.html)

Defer optional heavy initialization only when semantics permit. Python 3.15 explicit lazy imports defer errors/side effects and can alter import order. Check plugin registration, monkey-patching, dependency failures, first-use latency. Avoid global lazy-import changes from reusable libraries; consider carefully placed local imports on older targets. [PEP 810](https://peps.python.org/pep-0810/)

Rerun representative workload benchmarks for interpreter upgrades/JIT builds on supported targets. CPython's JIT remains experimental in 3.15. `sys._jit` (3.14+) is implementation/build-specific; inspect availability/enabled state outside timed loops. Avoid branching on `sys._jit.is_active()` in benchmarks: observation can interfere with tracing. [JIT introspection](https://docs.python.org/3.15/library/sys.html#sys._jit), [3.15 JIT](https://docs.python.org/3.15/whatsnew/3.15.html#upgraded-experimental-jit-compiler)

For PyPy, validate dependencies, C-extension behavior, startup, memory, sustained throughput. Include representative repeated execution for JIT warm-up and startup for short jobs. Avoid automatically applying CPython micro-tuning. [PyPy performance](https://pypy.org/performance.html), [compatibility/warm-up](https://doc.pypy.org/faq.html)
