# Runtime versions, free threading, and interpreters

## Contents

- [Version, build and active mode](#keep-version-build-and-active-mode-separate)
- [Multiprocessing defaults](#multiprocessing-defaults-inspect-rather-than-assume)
- [Multiple interpreters and isolation](#python-314-multiple-interpreters-are-not-a-security-boundary)
- [Python 3.14 context behavior](#python-314-context-behavior-is-configurable)
- [First-party contracts](#first-party-contracts)

## Keep version, build, and active mode separate

| Version | Relevant change | Do not infer |
|---|---|---|
| 3.9 | `asyncio.to_thread()` | Cancelling its awaiter stops a running thread |
| 3.11 | `TaskGroup`, `ExceptionGroup`/`except*`, `asyncio.timeout()` | Old `gather()` code has the same failure policy |
| 3.12 | Optional eager task factory; multithreaded fork may warn | A task always begins only after its creator yields |
| 3.13 | Experimental free-threaded CPython; thread/async queue shutdown APIs | Every Python binary has the GIL disabled |
| 3.14 | Free threading officially supported but optional; Python-level multiple-interpreter APIs; `InterpreterPoolExecutor` | Ordinary CPython becomes free-threaded by default |
| 3.14 | `Thread(context=...)`, context inheritance flags, `Executor.map(buffersize=...)` | All builds share context defaults or an executor submission bound |
| 3.14 | Multiprocessing defaults change away from fork; pool terminate/kill helpers | Fork is still the default on Linux, or forced termination runs cleanup |

Preserve the consuming project's supported versions. Examples in the other
references use Python 3.11+; the interpreter example below is guarded and executes
only on CPython 3.14+. These APIs may be unavailable on restricted
platforms: multiprocessing is unavailable on Android/iOS/WASI, and the documented
interpreter/executor APIs are unavailable on WASI.

### Free-threaded build capability is not current GIL state

CPython 3.13 introduced optional free-threaded builds. Python 3.14 moves them
from experimental to officially supported, **still optional**, status. A `t`
suffix is a common executable naming convention, not a reliable feature probe.

- `sysconfig.get_config_var("Py_GIL_DISABLED") == 1` detects build support.
- CPython's `sys._is_gil_enabled()` (3.13+) reports current GIL state.
- A free-threaded build can run with the GIL enabled through `PYTHON_GIL` or
  `-X gil`. Importing an extension that is not marked free-threading-compatible
  can re-enable it with a warning. Check after relevant imports.
- The underscore probe is implementation-specific; do not assume another
  Python implementation provides it. Do not use a version string to conclude
  the active runtime has no GIL.

This Python 3.11+-compatible probe has no fixed version/build-dependent output.
An absent GIL probe means unknown here, not disabled.

```pycon
>>> import sys
>>> import sysconfig
>>> supports_free_threading = sysconfig.get_config_var("Py_GIL_DISABLED") == 1
>>> probe = getattr(sys, "_is_gil_enabled", None)
>>> gil_enabled = probe() if probe is not None else None
>>> assert isinstance(supports_free_threading, bool)
>>> assert gil_enabled is None or isinstance(gil_enabled, bool)

```

Parallel execution does not remove application races. Built-in containers use
internal synchronization in free-threaded CPython, but a check followed by a
mutation or a multi-field update is not one transaction. Prefer explicit locks
or message ownership over relying on internal container locks. Iterator sharing,
callbacks into user code, and third-party extensions require their own contracts.
Do not access another running thread's frame locals in free-threaded CPython;
the documented limitation includes potential crashes.

Do not promise upstream's fixed single-thread overhead or multi-core speedup.
Workload, contention, allocation, extension support, and hardware all matter.
Compare equivalent builds and end-to-end work; an available free-threaded binary
alone does not demonstrate that the application's dependencies support it.

## Multiprocessing defaults: inspect rather than assume

- Windows uses **spawn**. macOS has used **spawn** by default since Python 3.8.
- Python 3.14 uses **forkserver** on supported non-macOS POSIX platforms such as
  Linux; **fork is no longer the default on any platform**. Python 3.14.9 adds a
  documented fallback to spawn if no writable temporary directory is available.
  Earlier 3.14 patch releases can instead fail to start the fork server there.
- Earlier common Linux/POSIX Python releases defaulted to fork. Spawn/forkserver
  therefore expose hidden assumptions about inherited globals and non-picklable
  worker functions during upgrades, not only on Windows.
- Forking an already multithreaded process is unsafe; from Python 3.12 the
  detected multithreaded fork path may emit `DeprecationWarning`. Do not select
  fork merely to make an unimportable worker seem to work.

For diagnostics, inspect `multiprocessing.get_all_start_methods()` and
`multiprocessing.get_context().get_start_method()`. Choose an explicit compatible
context at the application boundary when reproducibility requires it. A library
should accept that context, not globally call `set_start_method()` behind its
callers' backs. Spawn/forkserver importability and the main-entry guard apply
on POSIX too. See the [real-process smoke recipe](execution-and-coordination.md#optional-real-process-smoke-recipe).

## Python 3.14 multiple interpreters are not a security boundary

`concurrent.interpreters` exposes isolated interpreter state in one process.
Each interpreter has its own imports, module objects, globals, and builtins;
isolated interpreters have independent GILs on GIL-enabled CPython. Ordinary
mutable Python objects are not implicitly shared. Most transferred objects are
copied, often with pickle; supported immutable objects can be transferred more
efficiently. Dedicated cross-interpreter queues and supported shared buffers
have explicit sharing contracts and still need synchronization/lifetime design.

Transfer support is API-specific. On CPython 3.14.8, `prepare_main` requires
shareable values and rejects a list with `NotShareableError`; do not infer that
it has the same pickle fallback as `call` or `InterpreterPoolExecutor`. Pass
supported immutable values, or explicitly encode a trusted message as below.
Check the deployed runtime rather than relying on a newer documentation page's
general statement that most objects are copied with pickle.

Creating an interpreter alone provides **no concurrency**. `Interpreter.exec()`
and `Interpreter.call()` run in the current OS thread and block until complete.
Use separate threads or `InterpreterPoolExecutor` for simultaneous execution.
The upstream `.run(...)` examples are replaced with the actual 3.14 `.exec(...)`
and `.call(...)` API. Close owned interpreters in `finally`, after any work using
them has finished; do not depend on finalizers.

This guarded check exercises explicit JSON message transfer, retained interpreter
state, returned values, and deterministic destruction on CPython 3.14+. It creates
no child process and does not demonstrate multi-core speedup. The caller's list
remains unchanged after the receiving interpreter mutates its decoded copy.

```pycon
>>> import sys
>>> if sys.implementation.name == "cpython" and sys.version_info >= (3, 14):
...     from concurrent import interpreters
...     import json
...     original = [1, 2]
...     interpreter = interpreters.create()
...     try:
...         interpreter.prepare_main(payload=json.dumps(original))
...         interpreter.exec("import json; items = json.loads(payload); items.append(3)")
...         interpreter.exec("assert items == [1, 2, 3]")
...         assert original == [1, 2]
...         assert interpreter.call(sum, [4, 5]) == 9
...     finally:
...         interpreter.close()

```

`InterpreterPoolExecutor` combines worker threads with one interpreter per
worker and familiar future result/error observation. It serializes callables,
arguments, and results with pickle; favor importable module-level callables and
small explicit messages. Initializers/imports run separately in each interpreter.
Check every relevant extension's multi-interpreter support, separately from its
free-threading support. These are different compatibility obligations.

Optional Python 3.14+ recipe, **not included in doctest execution**:

```python
from concurrent.futures import InterpreterPoolExecutor

with InterpreterPoolExecutor(max_workers=2) as pool:
    assert list(pool.map(pow, [2, 3], [4, 2], buffersize=2)) == [16, 9]
```

The worker interpreters share an OS process, not independent security domains.
Process-global OS resources and native extension bugs can affect peers; an
extension can violate isolation or crash the whole process. Do not run hostile
plugins safely merely by placing them in another interpreter. Untrusted code
requires an actual security design and OS isolation, not this API or pickle.
Likewise, lower startup/memory costs than processes are workload-dependent, not
a universal guarantee.

## Python 3.14 context behavior is configurable

`threading.Thread(context=...)` is new in 3.14. Without an explicit context,
`sys.flags.thread_inherit_context` controls copying from the thread calling
`start()`: it defaults **true for free-threaded builds, false otherwise**.
Pass `contextvars.copy_context()` for an explicit copy or a new
`contextvars.Context()` for an empty context. Do not concurrently enter one
Context instance from multiple threads; create each needed copy separately.

`sys.flags.context_aware_warnings` also defaults true in free-threaded builds
and false otherwise. When enabled, `warnings.catch_warnings()` keeps its filter
state in a context variable rather than modifying process-global filters.
Warning-filter context and thread-context inheritance are related but separate
flags. Do not teach that all Python 3.14 threads always inherit context.

`asyncio.to_thread()` copies the current context independent of the ordinary
Thread default. Direct `run_in_executor()` calls do not automatically provide
the same copy behavior. Request context is not shared mutable application state
and not a guarantee of durable background work.

## First-party contracts

- [Python free-threading how-to: build/state probes, thread safety, contexts, limitations](https://docs.python.org/3.14/howto/free-threading-python.html)
- [3.14 free threading is supported but optional](https://docs.python.org/3.14/whatsnew/3.14.html#free-threaded-python-is-officially-supported)
- [Multiprocessing contexts/start methods and patch-level changes](https://docs.python.org/3.14/library/multiprocessing.html#contexts-and-start-methods)
- [Interpreter isolation, calls, queues, and security warning](https://docs.python.org/3.14/library/concurrent.interpreters.html)
- [InterpreterPoolExecutor and map buffering](https://docs.python.org/3.14/library/concurrent.futures.html#interpreterpoolexecutor)
- [Thread context argument and defaults](https://docs.python.org/3.14/library/threading.html#threading.Thread)
- [Context entry restriction](https://docs.python.org/3.14/library/contextvars.html#contextvars.Context)

The `/3.14/` documentation tracks patch releases. Apply the actual deployed
patch's behavior; reading newer docs does not upgrade a runtime.
