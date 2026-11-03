# Asyncio lifecycle, cancellation, and backpressure

## Contents

- [Start and own tasks deliberately](#start-and-own-tasks-deliberately)
- [Close streams and generators](#close-streams-and-generators-at-the-owned-boundary)
- [Cancellation and deadlines](#cancellation-and-deadlines-describe-lifetime-not-rollback)
- [Bound admission and worker lifetime together](#bound-admission-and-worker-lifetime-together)
- [Keep blocking work off the loop](#keep-blocking-work-off-the-loop-without-losing-its-real-lifetime)
- [Async state and limiting pitfalls](#async-state-and-limiting-pitfalls)
- [AnyIO and Trio boundaries](#anyio-and-trio-change-the-cancellation-contract)
- [Inspect a stalled loop](#inspect-a-stalled-loop)
- [First-party contracts](#first-party-contracts)

## Start and own tasks deliberately

Calling an `async def` function creates a coroutine object; it does not execute
its body. `await` executes/awaits it in the current task. Creating a task
schedules concurrent progress; do not depend on it starting before or after a
particular following statement (eager task execution is configurable).

At a script boundary, use `asyncio.run(main())`. In a notebook, framework,
server, or other host that already owns a running event loop, await the coroutine
in that loop. Do not patch in nested loops to avoid deciding runtime ownership.
Use `asyncio.get_running_loop()` inside async code when a loop object is needed.

| API | Result/error policy | Lifetime obligation |
|---|---|---|
| `await coroutine()` | One operation, current task | Caller owns its effects and cleanup |
| `TaskGroup` (3.11+) | Related children; ordinary failure cancels siblings and is grouped on exit | All children finish before group exit |
| `gather(*aws)` | Input-ordered results; first ordinary exception propagates without cancelling siblings | Know who awaits surviving children |
| `gather(..., return_exceptions=True)` | Failures become result values | Inspect each outcome; do not mistake failure values for success |
| `wait(tasks, ...)` | Returns done/pending sets; accepts tasks/futures, not raw coroutines on 3.11+ | Pending work is not cancelled automatically |
| `as_completed(...)` | Consume outcomes as they finish | Retain handles and settle remaining work on early exit |
| `create_task()` | Returns a task handle, not durable delivery | Retain, observe, and join/cancel it through a supervisor |

The loop keeps only weak task references. A set of live tasks prevents premature
collection, but a discard callback alone does not retrieve failures. An owner must
also observe outcomes and drain/cancel survivors. `asyncio.run()` cancels pending
tasks during shutdown; starting background work immediately before `main` returns
does not guarantee it will finish.

With `gather(..., return_exceptions=True)`, outcomes can include
`BaseException` values, notably `CancelledError`; checking only `Exception` misses
cancellation. If successful results can themselves be exception objects, use a
tagged result contract instead of guessing success from `isinstance`.

`asyncio.Future` and `concurrent.futures.Future` are different contracts. A
blocking executor future's `result()` must not block the event-loop thread.
Use `run_in_executor`, `asyncio.to_thread`, or `asyncio.wrap_future` as appropriate.

### TaskGroup failure waits for sibling cleanup

An event establishes that the sibling entered its protected lifetime before
the other task fails. The assertion proves cancellation, error propagation,
and cleanup without relying on a sleep or on task-start order.

```pycon
>>> import asyncio
>>> async def failure_and_cleanup():
...     started = asyncio.Event()
...     cleanup = []
...     failures = []
...     async def sibling():
...         try:
...             started.set()
...             await asyncio.Event().wait()
...         finally:
...             cleanup.append("released")
...     async def fail():
...         await started.wait()
...         raise ValueError("job failed")
...     try:
...         async with asyncio.TaskGroup() as group:
...             sibling_task = group.create_task(sibling())
...             group.create_task(fail())
...     except* ValueError as errors:
...         failures.extend(str(error) for error in errors.exceptions)
...     assert sibling_task.cancelled()
...     return cleanup, failures
>>> assert asyncio.run(failure_and_cleanup()) == (["released"], ["job failed"])

```

The example's group contains one failing leaf. Real nested groups can contain
nested `ExceptionGroup` values. Use `except*` to handle selected exception types;
leave unrelated failures visible. `KeyboardInterrupt` and `SystemExit` have
special re-raise behavior after children finish. A child that ends by ordinary
cancellation alone does not trigger the same sibling-failure policy.

## Close streams and generators at the owned boundary

When this consumer owns an async generator and may stop early, use
`contextlib.aclosing()` so its cleanup runs before leaving the consumer's context.
An `async for` break does not itself call `aclose()`. Borrowed streams keep their
caller's lifetime contract; `AsyncIterator` alone does not promise an `aclose` API.

```pycon
>>> import asyncio
>>> from contextlib import aclosing
>>> async def first_record():
...     released = []
...     async def records():
...         try:
...             yield "first"
...             yield "second"
...         finally:
...             released.append("closed")
...     async with aclosing(records()) as stream:
...         async for record in stream:
...             assert record == "first" and released == []
...             break
...     assert released == ["closed"]
>>> asyncio.run(first_record())

```

For an idle timeout, decide whether the budget measures time waiting for the next
item or time since the last item including consumer processing. Keep one pending
`anext()` owner; on timeout cancel and await it before closing the generator.
Do not call `aclose()` while another task is executing `__anext__()`, or repeatedly
cancel reads if the underlying stream cannot safely resume. A resettable watchdog
is justified only when a whole-stream deadline does not express the contract.

## Cancellation and deadlines describe lifetime, not rollback

`task.cancel()` requests delivery of `asyncio.CancelledError` at a future
opportunity; it does not forcibly interrupt CPU work. A non-yielding loop can
block cancellation, timeouts, and every other task in that event-loop thread.
`CancelledError` derives from `BaseException`, not `Exception`.
`Task.cancelling()` counts outstanding cancellation requests; `cancelled()` becomes
true only after the task actually finishes by propagating cancellation. A positive
count is not proof of completed cleanup, and another cancellation can interrupt an
await inside cleanup. Prefer lexical resource release and a bounded shutdown owner.

1. Acquire a resource, then put release in `finally` or an async context manager.
2. If catching `CancelledError` to perform cleanup, normally re-raise it. Do not
   turn cancellation into an ordinary successful return or casually call
   `uncancel()`; structured concurrency uses cancellation internally.
3. After requesting cancellation, await the task to observe it finishing.
   `cancel()` alone does not prove cleanup ran. For a manually owned collection,
   cancel outstanding tasks and await all outcomes, inspecting unexpected errors.
4. Define partially completed effects separately: a cancelled database/HTTP
   operation may already have committed. Retry only with an application-defined
   idempotency/transaction policy, not because a timeout looks like failure.

`asyncio.timeout(seconds)` (3.11+) bounds a scope by cancelling the current task
and converts its own cancellation to built-in `TimeoutError` **outside** the
scope. `timeout_at(deadline)` uses the loop's monotonic clock; carry one deadline
through multiple stages rather than restart a full budget at every call.
`wait_for(aw, timeout)` cancels the awaited operation on timeout and waits for
cancellation, so its elapsed time can exceed the timeout. Cleanup that blocks or
suppresses cancellation can also prevent prompt scope exit.

This zero-budget test deterministically reaches a real suspension point, then
proves `finally` completed before the timeout was observed. It is not a latency
benchmark or an arbitrary delay used to coordinate tasks.

```pycon
>>> import asyncio
>>> async def deadline_cleanup():
...     cleanup = []
...     try:
...         async with asyncio.timeout(0):
...             try:
...                 await asyncio.Event().wait()
...             finally:
...                 cleanup.append("closed")
...     except TimeoutError:
...         return cleanup
...     raise AssertionError("deadline did not expire")
>>> assert asyncio.run(deadline_cleanup()) == ["closed"]

```

`shield(task)` prevents the caller's cancellation from being forwarded to that
inner task; the caller still receives `CancelledError`. Retain and eventually
observe the shielded task. Shielding is not a substitute for a cleanup owner,
a shutdown deadline, or rollback.

## Bound admission and worker lifetime together

A semaphore inside a million created tasks limits active operations but leaves
a million waiting task objects. Prefer a small fixed worker set and a bounded
queue. Bound item bytes and result retention too; queue capacity counts items,
not memory. `asyncio.Queue(maxsize=0)` is unbounded.

This two-worker pipeline preserves input order only by explicitly carrying
indices. Results accumulate because this finite API returns a list; for a large
stream, yield results to a bounded downstream consumer instead. On failure,
TaskGroup cancels the other workers and the producer, including a producer
blocked on a full queue. On success, one sentinel per worker closes input.
Every retrieved item, including sentinels, is accounted for in `finally`.

```pycon
>>> import asyncio
>>> async def bounded_double(values):
...     queue = asyncio.Queue(maxsize=1)
...     stop = object()
...     results = []
...     async def produce():
...         for index, value in enumerate(values):
...             await queue.put((index, value))
...         for _ in range(2):
...             await queue.put(stop)
...     async def consume():
...         while True:
...             item = await queue.get()
...             try:
...                 if item is stop:
...                     return
...                 index, value = item
...                 if value < 0:
...                     raise ValueError("negative job")
...                 results.append((index, value * 2))
...             finally:
...                 queue.task_done()
...     async with asyncio.TaskGroup() as group:
...         group.create_task(produce())
...         for _ in range(2):
...             group.create_task(consume())
...     await queue.join()
...     return [value for index, value in sorted(results)]
>>> assert asyncio.run(bounded_double(())) == []
>>> assert asyncio.run(bounded_double((4, 1, 4, 0))) == [8, 2, 8, 0]
>>> failures = []
>>> try:
...     asyncio.run(bounded_double((-1, 1, 2, 3)))
... except* ValueError as errors:
...     failures.extend(str(error) for error in errors.exceptions)
>>> assert failures == ["negative job"]

```

`queue.join()` comes **after successful group exit** here: the failure path
raises instead of waiting forever for items discarded when consumers were
cancelled. `task_done()` is queue accounting, not a success acknowledgment.
A production pipeline that must preserve accepted jobs needs an explicit
failure/requeue/durable-ack protocol. This example intentionally discards local
unprocessed work on failure.

To see backpressure directly, the second put below is known to have reached
its blocking point before the consumer removes the first item. Releasing one
slot lets it complete; it cannot silently overwrite or drop the first value.

```pycon
>>> import asyncio
>>> async def one_slot():
...     queue = asyncio.Queue(maxsize=1)
...     entered = asyncio.Event()
...     await queue.put("first")
...     async def put_second():
...         entered.set()
...         await queue.put("second")
...     async with asyncio.TaskGroup() as group:
...         pending = group.create_task(put_second())
...         await entered.wait()
...         assert not pending.done()
...         first = await queue.get()
...         queue.task_done()
...     second = await queue.get()
...     queue.task_done()
...     await queue.join()
...     return first, second
>>> assert asyncio.run(one_slot()) == ("first", "second")

```

For graceful shutdown: stop admission, finish/stop producers, close input, drain
or discard by policy, await workers and inspect outcomes, then close shared
resources. Python 3.13+ `Queue.shutdown()` can replace a sentinel protocol.
Immediate shutdown can discard queued work and relax normal `join()` accounting;
it is not evidence that discarded work ran.

## Keep blocking work off the loop without losing its real lifetime

Use async-native APIs when already available. `await asyncio.to_thread(fn, ...)`
(3.9+) runs a blocking callable in a thread and propagates the current
`contextvars` context. `loop.run_in_executor(pool, fn, ...)` uses an explicitly
owned thread/process executor; it does not automatically copy context variables
like `to_thread` does. Use thread-safe loop submission methods from other
threads; `asyncio.Queue`, `Event`, and `Lock` are not OS-thread-safe.

Cancelling the `to_thread` task cancels the **awaiter**, not a callable already
running in an OS thread. The callable still needs a deadline or cooperative stop
signal. `asyncio.run()` also shuts down its default executor on exit; leaving a
thread stuck is not fixed by letting the coroutine return.

This check proves the cancelled task is done while the blocking callable is still
waiting. Its owner signals release and awaits the callable's final cleanup
notification in `finally`. That notification is not an OS-thread join: pool
threads can be reused. `asyncio.run()` shuts down its default executor before
the outer assertion returns. The thread posts event changes with
`call_soon_threadsafe`, not direct mutation of asyncio objects. Five-second waits
are failure watchdogs, not coordination.

```pycon
>>> import asyncio
>>> from threading import Event
>>> async def cancelled_thread_awaiter():
...     loop = asyncio.get_running_loop()
...     started = asyncio.Event()
...     finished = asyncio.Event()
...     release = Event()
...     outcomes = []
...     def blocking():
...         loop.call_soon_threadsafe(started.set)
...         try:
...             outcomes.append(release.wait(timeout=5))
...         finally:
...             loop.call_soon_threadsafe(finished.set)
...     task = asyncio.create_task(asyncio.to_thread(blocking))
...     try:
...         await asyncio.wait_for(started.wait(), timeout=5)
...         task.cancel()
...         try:
...             await task
...         except asyncio.CancelledError:
...             pass  # The owner observes the expected cancellation.
...         assert task.cancelled() and not finished.is_set()
...     finally:
...         release.set()
...         await asyncio.wait_for(finished.wait(), timeout=5)
...     assert outcomes == [True]
...     return task.cancelled(), finished.is_set()
>>> assert asyncio.run(cancelled_thread_awaiter()) == (True, True)

```

`to_thread` typically does not parallelize pure-Python CPU computation on a
GIL-enabled build; extensions releasing the GIL and free-threaded builds differ.
If thread code requires the loop to complete a callback, do not synchronously
join that thread or executor from the loop before the callback can run.

## Async state and limiting pitfalls

- Awaiting operations in a list comprehension is sequential unless tasks are
  created/scheduled separately. `gather` does not make blocking functions async.
- In a single loop thread, a plain list append without an intervening await is
  not itself a task-interleaving race. A multi-step invariant spanning an await
  can be: read balance, await, write stale balance. Avoid that suspension, use
  `asyncio.Lock` consistently, or give one task ownership of the state.
- An async lock can span awaits but may serialize slow I/O or form a wait cycle.
  `asyncio.Lock` is not reentrant: a helper cannot reacquire its caller's held
  lock. A blocking `threading.Lock` acquisition on the loop can deadlock it.
- Concurrency limiting is not rate limiting. A semaphore bounds simultaneous
  operations; time-based admission needs a monotonic-time policy. A local limiter
  is not a cross-process/service-wide limit.
- Do not create request-scoped background tasks for work that must survive a
  request or process exit. Hand off to an explicit service supervisor or a
  durable queue according to the application contract.

## AnyIO and Trio change the cancellation contract

Keep asyncio when its dependencies and `TaskGroup` satisfy the application.
Choose AnyIO/backend portability or Trio because the project needs those
contracts; changing libraries is not a prerequisite for structured concurrency.

| Boundary | Review before migration |
|---|---|
| Cancellation | Asyncio delivers cancellation requests; AnyIO/Trio cancel scopes can raise repeatedly at checkpoints while the scope remains cancelled. |
| Cleanup | Under level cancellation, awaited cleanup needs a bounded shielded scope when it must run; re-raise cancellation afterward. `asyncio.shield` has different ownership behavior. |
| Capacity | AnyIO `CapacityLimiter` tracks borrowers; it is not a request rate limiter or a bound on all tasks waiting for tokens. |
| Queues | Memory object streams have separately owned send/receive ends; close every send clone for end-of-stream. Buffer size zero means rendezvous, unlike `asyncio.Queue(0)`. |
| Dependencies | An asyncio-only client remains asyncio-only when called from AnyIO. Exercise every backend the library actually promises. |

Use `get_cancelled_exc_class()` for AnyIO cancellation handling. Inspect the
installed AnyIO/Trio version before translating task handles or thread offloading;
do not copy asyncio shutdown recipes by renaming functions. Framework request-loop
and thread-affinity rules belong to the framework's runtime contract.

## Inspect a stalled loop

Reproduce with `asyncio.run(..., debug=True)` or `PYTHONASYNCIODEBUG=1` and visible
resource warnings. Name tasks; inspect `all_tasks()` and task stacks. Adjust
`loop.slow_callback_duration` to the relevant budget: it detects slow callbacks,
not every form of awaited downstream delay. Review Ruff's optional `ASYNC` rules
against the project's selected version/configuration; lint cannot prove liveness.

On supported CPython 3.14+ environments, `python -m asyncio ps PID` and
`python -m asyncio pstree PID` inspect another process's task graph. Check platform,
interpreter compatibility and attach permissions first; do not infer idle time or
a deadlock from one snapshot. No tool inspection substitutes for a wait graph.

## First-party contracts

- [Task creation, TaskGroup, cancellation, gather, wait, deadlines, shield, to_thread](https://docs.python.org/3.15/library/asyncio-task.html)
- [Deterministic async-generator cleanup](https://docs.python.org/3.15/library/contextlib.html#contextlib.aclosing)
- [Runner shutdown](https://docs.python.org/3.15/library/asyncio-runner.html)
- [Asyncio queues, task accounting, and shutdown](https://docs.python.org/3.15/library/asyncio-queue.html)
- [Asyncio synchronization](https://docs.python.org/3.15/library/asyncio-sync.html)
- [Asyncio development: blocking code and cross-thread submission](https://docs.python.org/3.15/library/asyncio-dev.html)
- [Task graph CLI, CPython 3.15.2 documentation source](https://github.com/python/cpython/blob/v3.15.2/Doc/library/asyncio-tools.rst)
- [Executor future cancellation cannot stop running work](https://docs.python.org/3.15/library/concurrent.futures.html#concurrent.futures.Future.cancel)
- [AnyIO cancellation and bounded shielding](https://anyio.readthedocs.io/en/stable/cancellation.html)
- [AnyIO capacity limiters](https://anyio.readthedocs.io/en/stable/synchronization.html#capacity-limiters)
- [AnyIO memory object stream ownership](https://anyio.readthedocs.io/en/stable/streams.html#memory-object-streams)
- [Ruff ASYNC rules](https://docs.astral.sh/ruff/rules/#flake8-async-async)
