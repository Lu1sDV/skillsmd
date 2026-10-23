# Execution and coordination

## Contents

- [Select against the actual workload](#select-against-the-actual-workload)
- [Thread ownership and synchronization](#thread-ownership-and-synchronization)
- [Processes: portability and data ownership](#processes-portability-and-data-ownership)
- [Diagnose hangs before changing limits](#diagnose-hangs-before-changing-limits)
- [First-party contracts](#first-party-contracts)

## Select against the actual workload

| Work | Candidate | Main cost or constraint |
|---|---|---|
| Small finite computation | Sequential function | Concurrency overhead can dominate |
| Blocking I/O with an existing synchronous client | `ThreadPoolExecutor` | Set client deadlines; bound outstanding submissions |
| Native CPU work that releases the GIL | Threads, after measurement | Library thread safety and nested native thread pools |
| Pure-Python CPU work on GIL-enabled CPython | `ProcessPoolExecutor` | Pickling, startup, separate heaps, platform limits |
| CPU work on free-threaded CPython | Threads, after compatibility checks | Shared-state contention; no guaranteed speedup |
| CPU work with interpreter-local dependencies, Python 3.14+ | `InterpreterPoolExecutor` | Isolated imports/state and serialization |
| Large async-compatible I/O workload | Async worker tasks | See [Async lifecycle](asyncio-lifecycle.md) |

Use the project's existing client/runtime rather than rewrite it just to use
async. A mixed pipeline can keep async I/O on its loop and send sufficiently
large CPU batches to a process pool via `loop.run_in_executor(pool, callable,
argument)`. Own that pool at application scope; do not create one per request.
Do not run blocking executor shutdown in the event-loop thread while workers
need that loop to finish.

`Executor.map()` yields in input order; `as_completed()` yields completion
order. Retrieve every result so exceptions reach the owner. A `result(timeout)`
timeout stops waiting, **not the work**. `Future.cancel()` cannot cancel an
already-running call. `shutdown(cancel_futures=True)` cancels work that has not
started, not running work; a context manager waits for its workers.

Bounded worker count does not bound submissions. On 3.11–3.13, use a bounded
submission window or explicit bounded work queue for large input. Python 3.14
adds `map(..., buffersize=N)` to bound submitted work whose results have not
been yielded; process-pool `chunksize` additionally controls batching. It is not
a byte limit or a limit on results the caller chooses to accumulate.

## Thread ownership and synchronization

| Primitive | Appropriate use | Important limit |
|---|---|---|
| `Thread(target=..., args=...)` | Owned persistent worker with explicit stop/join | `join()` waits but does not propagate its exception |
| `ThreadPoolExecutor` | Finite independent calls and result/error propagation | Do not make workers wait for jobs queued to the same exhausted pool |
| `Lock` | Protect an entire compound invariant | Acquire all relevant reads/writes consistently; avoid blocking calls inside |
| `RLock` | Genuine same-thread recursive acquisition | Reentrancy does not solve lock ordering or contention |
| `Condition` | Wait until protected state satisfies a predicate | Mutate under the same lock; `wait_for()` rechecks after waking |
| `Semaphore` / `BoundedSemaphore` | Limit simultaneous resource occupants | No time-based rate guarantee; no bound on waiting threads |
| `Event` | Sticky readiness/stop notification | Not a count of messages; set does not interrupt arbitrary blocking I/O |
| `queue.Queue(maxsize=N)` | Bounded thread-safe handoff | `qsize()`/`empty()` are observations, not atomic admission decisions |

For a condition, use `with condition:`, check the result of
`condition.wait_for(predicate, timeout=...)`, and change the predicate's state
under that same lock before notifying. `notify()` does not release the lock;
waiters can proceed only after reacquiring it. Define a closed/stopped state in
the predicate if production can end without another item.

Prefer non-daemon workers and explicit stop/join over interpreter teardown.
Daemon workers may stop without resource cleanup. Use `try/finally` to signal a
stop event even when the owning scope fails, and make blocking operations
interruptible with their own API deadlines. Python does not provide a safe
general-purpose way to forcibly stop a running thread.

### A lock protects a multi-field transaction

One shared lock covers the check, decrement, and count update. Worker results
are collected, so a thrown exception is not mistaken for a successful join.

```pycon
>>> from concurrent.futures import ThreadPoolExecutor
>>> from threading import Lock
>>> def sell_once():
...     inventory = {"remaining": 1, "sold": 0}
...     lock = Lock()
...     def buy(_):
...         with lock:
...             if inventory["remaining"] == 0:
...                 return False
...             inventory["remaining"] -= 1
...             inventory["sold"] += 1
...             return True
...     with ThreadPoolExecutor(max_workers=2) as pool:
...         purchases = list(pool.map(buy, range(8)))
...     assert inventory == {"remaining": 0, "sold": 1}
...     return sum(purchases)
>>> assert sell_once() == 1

```

A one-run successful unlocked counter test would not establish thread safety.
The GIL does not promise atomicity for arbitrary compound Python operations;
bytecode and scheduling details differ across Python versions and builds.

### Queue drain, sentinel accounting, and observed failure

This finite, single-consumer protocol preserves FIFO order and includes its
sentinel in unfinished-work accounting. Each accepted `get()` has exactly one
`task_done()`, even for the sentinel. Observe the worker's result both after
publication and when publication fills a queue whose consumer has failed; a
`Full` watchdog must not replace the original worker exception. Call `join()`
only after successful worker completion. Queue timeouts are watchdogs, not
synchronization delays; failure aborts this local operation and discards its
unprocessed backlog rather than claiming it was drained.

```pycon
>>> from concurrent.futures import ThreadPoolExecutor
>>> from queue import Full, Queue
>>> def drain(values):
...     work = Queue(maxsize=1)
...     stop = object()
...     def consume():
...         output = []
...         while True:
...             item = work.get(timeout=5)
...             try:
...                 if item is stop:
...                     return output
...                 if item < 0:
...                     raise ValueError("negative job")
...                 output.append(item * 2)
...             finally:
...                 work.task_done()
...     with ThreadPoolExecutor(max_workers=1) as pool:
...         worker = pool.submit(consume)
...         try:
...             for value in values:
...                 work.put(value, timeout=5)
...             work.put(stop, timeout=5)
...         except Full:
...             if worker.done():
...                 worker.result()  # Propagate the consumer's error, not queue.Full.
...             raise
...         output = worker.result(timeout=5)
...         work.join()
...     return output
>>> assert drain(()) == []
>>> assert drain((3, 1, 2)) == [6, 2, 4]
>>> try:
...     drain((-1, 1, 2))  # The worker fails while more work still needs publication.
... except ValueError:
...     pass
... else:
...     raise AssertionError("worker failure was lost")

```

For many consumers, send one sentinel per consumer after stopping producers.
A sentinel is an in-process protocol, not a durable queue acknowledgment. With
process serialization, use a value/tag sentinel, not `object()` identity.
If arbitrary consumers can die while production continues, combine bounded
put/get deadlines with supervision; `queue.join()` cannot diagnose dead workers.
Python 3.13+ queue shutdown is an alternative to sentinels, not a requirement
for these Python 3.11-compatible examples.

### Time-based limiting is different from a semaphore

This local sliding-window limiter rejects excess calls rather than sleeping.
It samples a monotonic clock while holding the lock. The injected clock makes
the exact boundary check deterministic. Capacity is shared only within this
one limiter instance/process; distributed rate limiting needs another owner.

```pycon
>>> from collections import deque
>>> from threading import Lock
>>> from time import monotonic
>>> class WindowLimiter:
...     def __init__(self, limit, seconds, clock=monotonic):
...         if limit < 1 or seconds <= 0:
...             raise ValueError("positive limit and window required")
...         self.limit, self.seconds, self.clock = limit, seconds, clock
...         self.accepted = deque()
...         self.lock = Lock()
...     def allow(self):
...         with self.lock:
...             now = self.clock()
...             while self.accepted and now - self.accepted[0] >= self.seconds:
...                 self.accepted.popleft()
...             if len(self.accepted) >= self.limit:
...                 return False
...             self.accepted.append(now)
...             return True
>>> now = [0.0]
>>> limiter = WindowLimiter(2, 10, clock=lambda: now[0])
>>> assert [limiter.allow() for _ in range(3)] == [True, True, False]
>>> now[0] = 10.0
>>> assert limiter.allow()
>>> assert len(limiter.accepted) == 1

```

This has O(limit) retained timestamps; each accepted timestamp is added/removed
once. A wall clock can jump and is the wrong elapsed-time source. There is no
stdlib reader/writer lock: start with an ordinary `Lock`, or publish immutable
snapshots. Do not adopt the upstream custom reader-preference lock without a
fairness/starvation policy and tests simply because reads are frequent.

## Processes: portability and data ownership

- Put worker functions at importable module top level. Lambdas, nested functions,
  and notebook/doctest `__main__` functions are not portable process workers.
- Guard process creation with `if __name__ == "__main__":`, including on POSIX
  when using spawn/forkserver. Children must be able to import the main module
  without recursively creating processes.
- Select an application context with `multiprocessing.get_context(...)` and
  pass it as `mp_context` to `ProcessPoolExecutor`. Libraries should accept the
  caller's context rather than mutate the global start method. Create locks,
  queues, and processes from compatible contexts.
- Send small, picklable inputs/results. Pickle is not safe for untrusted data.
  Copying a huge object per job can erase parallel gains; batch measured work.
- `multiprocessing.Queue` serializes messages; a receiver normally gets a copy.
  `Value`/`Array` share storage, not compound transaction safety: hold
  `counter.get_lock()` across a whole `counter.value += 1` update.
- `Manager()` provides server-process proxies with IPC overhead. A proxy
  dictionary's check-then-update is still multiple operations; use a shared
  lock or one owner. `SharedMemory` needs explicit synchronization and close/
  unlink ownership. Prefer message passing until sharing is demonstrably needed.
- Drain process queue output while children can run; joining a producer before
  reading its buffered output can deadlock. Close queues and join feeder threads
  according to ownership. Inspect process exit codes and worker errors.
- Forced process termination can skip `finally`, lose effects, or corrupt queues
  and leave locks held. Escalation is not graceful cancellation. Python 3.14's
  pool `terminate_workers()` / `kill_workers()` act on the entire pool.

### Optional real-process smoke recipe

**Not a doctest.** Save this complete fence as
`/tmp/python-concurrency-process-smoke.py` in a normal writable environment.
Run `python3 /tmp/python-concurrency-process-smoke.py spawn`; on a host supporting
forkserver, also run `python3 /tmp/python-concurrency-process-smoke.py forkserver`.
It requires Python 3.11+, local process creation, and an importable script path.
A surrounding CI/process timeout should also cover startup and shutdown; the
future timeout alone does not bound executor context-manager shutdown.

```python
import multiprocessing as mp
import sys
from concurrent.futures import ProcessPoolExecutor


def square(value):
    if value < 0:
        raise ValueError("negative job")
    return value * value


if __name__ == "__main__":
    method = sys.argv[1] if len(sys.argv) > 1 else "spawn"
    context = mp.get_context(method)
    with ProcessPoolExecutor(max_workers=2, mp_context=context) as pool:
        assert list(pool.map(square, ())) == []
        assert list(pool.map(square, (0, 2, 3))) == [0, 4, 9]
        failure = pool.submit(square, -1)
        try:
            failure.result(timeout=10)
        except ValueError as error:
            assert str(error) == "negative job"
        else:
            raise AssertionError("worker failure was lost")
    print("process smoke passed")
```

## Diagnose hangs before changing limits

Draw who waits for what: full queue versus producer join; empty queue versus
missing sentinel; worker waiting on a future in its own exhausted executor;
lock held across a callback or I/O; process join versus undrained queue. Collect
thread stacks with `faulthandler`, name tasks/threads, and inspect queue depth
and unfinished work. Do not hide a cycle by adding sleeps or more workers.

## First-party contracts

- [Threading: locks, conditions, events, and shutdown](https://docs.python.org/3.14/library/threading.html)
- [Thread-safe queues and task accounting](https://docs.python.org/3.14/library/queue.html)
- [Executors: map buffering, errors, cancellation, and deadlocks](https://docs.python.org/3.14/library/concurrent.futures.html)
- [Multiprocessing: contexts, IPC, shared state, and programming guidelines](https://docs.python.org/3.14/library/multiprocessing.html)
- [GIL mutation FAQ](https://docs.python.org/3.14/faq/library.html#what-kinds-of-global-value-mutation-are-thread-safe) describes CPython details, not a portable application transaction guarantee.
