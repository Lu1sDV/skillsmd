# Web runtime and background jobs

## Contents

- [Select the framework](#select-the-framework-not-a-benchmark-slogan)
- [WSGI and ASGI](#wsgi-and-asgi-what-the-interface-actually-promises)
- [Resources and deployment](#resources-and-deployment)
- [Choose task lifetime before task tooling](#choose-task-lifetime-before-task-tooling)
- [Durable does not mean exactly once](#durable-does-not-mean-exactly-once)
- [Celery delivery and worker limits](#celery-delivery-and-worker-limits)
- [Evidence at the runtime boundary](#evidence-at-the-runtime-boundary)

## Select the framework, not a benchmark slogan

Prefer an existing supported framework. For a new application:

| Need | Candidate | Consequence |
|---|---|---|
| Integrated ORM, migrations, auth, forms, admin, templates | Django | Reuse these conventions instead of assembling replacements |
| Small synchronous web surface with deliberately chosen extensions | Flask | You own selection/integration of persistence, auth and API validation |
| Typed HTTP API schemas/OpenAPI and async-capable endpoints | FastAPI | Persistence, migrations and full authentication policy remain separate choices |
| Long-lived async connections/WebSockets | ASGI-capable framework and server | Verify middleware, drivers, proxy and connection limits end to end |

FastAPI is a web framework, not just a library alternative to Django. Python
annotations are not universal runtime enforcement: FastAPI validates supported
request schemas, while application invariants and authorization still need code.
Django REST Framework, GraphQL integrations, Flask extensions, brokers and ORMs
are optional dependencies, not capabilities provided by installing Python.
Do not rank frameworks as universally faster; measure the actual database,
serialization, middleware and workload with an explicit concurrency budget.

## WSGI and ASGI: what the interface actually promises

[WSGI (PEP 3333)](https://peps.python.org/pep-3333/) calls
`application(environ, start_response)` and consumes an iterable of **bytes**.
Server workers/threads may handle multiple requests; WSGI does not require the
whole deployment to execute requests serially. An HTTP server/proxy may terminate
HTTP/2 and translate to WSGI; WSGI itself has no native WebSocket event protocol.

[ASGI 3](https://asgi.readthedocs.io/en/stable/specs/main.html) awaits
`application(scope, receive, send)`. HTTP scopes last one request; WebSocket scopes
last the connection. Events carry request/response bodies and disconnects.
Lifespan is a separate startup/shutdown protocol. ASGI permits multiple protocols,
but actual HTTP/2/WebSocket support depends on the server and its configuration;
it is not guaranteed by declaring `async def` or choosing Uvicorn.

Prefer framework middleware to writing gateway code. For custom middleware:

- WSGI bodies can stream lazily. Timing only the call that returns the iterable
  misses body generation. Preserve iteration and `close()` cleanup even on errors;
  use a monotonic clock for durations and avoid leaking response contents.
- ASGI middleware must handle/pass through supported scope types, not silently
  swallow lifespan or WebSocket messages. Copy `scope` before modifying it. A
  response's headers may already be sent when streaming fails; do not promise that
  every downstream failure becomes a clean JSON error.

### Match execution to drivers

FastAPI runs framework-invoked ordinary `def` handlers/dependencies in its
threadpool. Arbitrary synchronous helpers called **inside** `async def` are not
automatically offloaded. Use awaitable drivers for async paths; otherwise retain
sync handlers or explicitly bound offloading. A threadpool is not infinite and
CPU-heavy work is not made cheap by changing syntax. See [FastAPI's execution
rules](https://fastapi.tiangolo.com/async/#very-technical-details).

Flask supports async views with the `async` extra (since Flask 2.0), but under its
normal WSGI execution each request still occupies a worker. Its per-view event
loop stops when the view completes, cancelling unfinished spawned tasks. An ASGI
adapter changes loop lifetime, not job durability. See [Flask async limits](https://flask.palletsprojects.com/en/stable/async-await/).

Django supports WSGI and ASGI; synchronous middleware can require sync adaptation.
In Django **6.0**, async ORM calls do not provide async transaction blocks: put a
transactional operation in one synchronous function and call it via
`sync_to_async`, preserving thread-sensitive resource ownership. Do not disable
async safety guards to bypass this. Recheck the consuming Django version before
assuming this limitation has changed. See [Django 6.0 async support](https://docs.djangoproject.com/en/6.0/topics/async/).

## Resources and deployment

Create reusable clients/pools at startup and close them at shutdown. In FastAPI,
prefer its [lifespan context](https://fastapi.tiangolo.com/advanced/events/).
Use the real library API: SQLAlchemy async engines have `dispose()`; the source's
`engine.disconnect()` is not a generic SQLAlchemy engine method. Resource
acquisition and cleanup should be paired with context managers/`try/finally`,
including partial startup failure. Name the last use: streams and yielded
iterators can outlive the function that returned them. Test cancellation cleanup
separately from ordinary exceptions; do not depend on garbage collection or
finalizers for correctness. Do not perform production I/O at import time.

Each worker process/replica has independent memory and lifespan initialization.
A mutable global cache is not a shared cache, and startup hooks are not a
cluster-wide once-only migration mechanism. Pool budget upper bound includes
replicas × web workers × per-worker pool capacity plus job workers and admin
connections. Leave database headroom and bound pool wait time.

Use a server compatible with the application interface and platform; verify its
protocols rather than inferring them from the framework. Development reloaders,
Flask's development server and Django `runserver` are not production deployment
plans. See [deployment and operations](deployment-operations.md) for artifact
builds, migrations, proxies, health and graceful drain. A client disconnect does
not imply database rollback; report unknown outcomes and support recovery by a
stable operation identity where required.

## Choose task lifetime before task tooling

| Work contract | Appropriate mechanism | Failure boundary |
|---|---|---|
| Result required in this response | Await/call it with deadlines | Request failure/cancellation is observable |
| Small best-effort after-response effect | Framework background callback | Process crash/redeploy can lose work; response is already sent |
| Application-owned transient loop/work | Managed task group with shutdown ownership | No persistent acceptance or restart recovery |
| Must survive web worker loss or be retried separately | Durable job record/queue plus worker | Must configure persistence, acknowledgement and recovery |
| Periodic required work | Existing scheduler plus durable job acceptance | Prevent unwanted overlapping executions and duplicate scheduling |

FastAPI/Starlette [BackgroundTasks](https://fastapi.tiangolo.com/tutorial/background-tasks/)
runs callbacks after the response, in the application process. It is not a
persistent queue. Plain `asyncio.create_task()` also needs an owner that retains,
observes and shuts down the task; it is not a reliability mechanism. Do not pass
a request session, uploaded-file handle or soon-to-be-deleted temporary path to
work that outlives that resource. Pass an ID/object-store key and open new
resources inside the job.

Queue choice is optional and should follow existing operations:

- **Celery:** task routing, retries and workflows with a supported broker. Choose
  the broker/result backend and acknowledgement policy deliberately; a result
  backend is not needed for every fire-and-forget job.
- **RQ:** straightforward Python jobs on Redis/Valkey in currently documented
  versions. Confirm the installed release's supported datastore, serializer,
  scheduler and worker platform rather than assuming old feature matrices.
- **Dramatiq:** actor-style jobs and retry middleware with RabbitMQ/Redis broker
  options. Check retry/time-limit units and middleware in the installed version.

Primary references: [Celery tasks](https://docs.celeryq.dev/en/stable/userguide/tasks.html),
[RQ jobs](https://python-rq.org/docs/), [Dramatiq guide](https://dramatiq.io/guide.html).
Brokers, worker processes and any monitoring/scheduler extras are prerequisites.
These selection notes do not install or configure them.

## Durable does not mean exactly once

For required work, specify all of the following:

1. **Acceptance:** persist a job ID or outbox entry before promising durable
   acceptance. A `202 Accepted` response should identify how the caller learns
   terminal status; it does not mean completed.
2. **Arguments/trust:** send bounded versioned data and stable identifiers, not
   live ORM/session objects. Validate the message at the worker boundary. Restrict
   broker access and accepted serializers; never deserialize untrusted pickle.
3. **Duplicates:** claim a unique operation key and its recorded payload/result
   atomically with the local effect. Check-then-mark is racy. Reject the same key
   reused with a different payload. Queue job IDs alone do not prove exactly-once
   effects, particularly after jobs expire or an external call times out.
4. **Retry policy:** retry known transient failures with bounded backoff/jitter,
   an attempt/age limit and I/O timeouts. Do not endlessly retry invalid input or
   swallow permanent errors into apparent success. Expose terminal failure and
   a deliberate operator replay path. Specify whether a limit counts retries or
   total attempts, and count nested SDK/client/worker retries against one end-to-end
   budget. A timeout does not prove the effect failed; retry safety comes from the
   operation/provider contract, not a universal HTTP-status allowlist.
5. **Delivery settings:** Celery normally acknowledges before execution.
   `acks_late` shifts acknowledgement later but does not by itself cover every
   worker-loss case; consult `task_reject_on_worker_lost` and broker behavior.
   Test crash/redelivery with real workers before claiming recovery guarantees.
6. **External effects:** a database transaction cannot roll back a sent email or
   payment. Use the provider's idempotency key/reconciliation contract where
   available. A timeout may mean the remote effect happened but the response was
   lost. Do not blindly repeat it under a new key.
7. **Scheduling/backpressure:** ensure only the intended scheduler instances run,
   limit concurrency/prefetch/queue growth and measure oldest-job age. A broker
   changes where work waits; it does not create unlimited capacity.

For a database change followed by publish, commit-then-enqueue has a crash gap;
enqueue-then-commit can run work for a rolled-back record. An after-commit hook
solves only the latter. When required, write an outbox row in the same database
transaction as the business change, dispatch committed rows later, and mark them
sent only after publication. A dispatcher crash after publish can duplicate a
message; consumers still need idempotency. Do not claim atomicity across arbitrary
remote systems or add an outbox when the effect is explicitly expendable.

## Celery delivery and worker limits

The following qualifies **Celery 5.6** behavior; verify the broker, pool and installed
release. These are policy choices, not a configuration block to enable wholesale.

| Control | Consequence to verify |
|---|---|
| `task_acks_late` (disabled by default) | Early acknowledgement leaves a loss window after acknowledgement and before completion. Late acknowledgement permits redelivery, so effects must tolerate duplicates. Neither setting establishes a universal exactly-once or at-most-once guarantee. |
| `task_reject_on_worker_lost` (disabled by default) | Late acknowledgement still acknowledges some child-process exits; enabling rejection allows requeue in those cases but can create poison-message loops. |
| `worker_prefetch_multiplier` (default 4) | A multiplier of 1 with late acknowledgement suits long jobs with little reservation ahead of execution; larger values can improve short-job throughput. Route distinct workloads separately. |
| Redis `visibility_timeout` (default 3600 seconds) | An unacknowledged job can be delivered again when the timeout expires. Include execution and ETA/countdown waiting; increasing it also delays recovery after forced loss. It is not a universal broker setting. |
| `task_soft_time_limit` / `task_time_limit` | A supported soft limit permits bounded cleanup; a hard limit forcibly ends execution and cannot promise cleanup. Use I/O deadlines first, and verify pool/platform support. |

Normal task exceptions are normally acknowledged even with late acknowledgement;
configure application retries deliberately. Celery `max_retries=3` permits the
initial attempt plus three retries, not three total attempts. Prefetch multiplier
1 with early acknowledgement can still reserve an extra job per execution slot;
Celery 5.6's `worker_disable_prefetch` is a Redis-only alternative, not a portable
way to disable reservations. `gevent` does not implement soft time limits and
cannot enforce its hard limit while a task blocks. Prefork child recycling can
bound accumulated leaks (`worker_max_tasks_per_child` / `worker_max_memory_per_child`),
but is not an immediate per-task memory cap or a repair for a growing queue.

Primary references: [task acknowledgement/retry](https://docs.celeryq.dev/en/stable/userguide/tasks.html),
[configuration defaults](https://docs.celeryq.dev/en/stable/userguide/configuration.html),
[prefetch tradeoffs](https://docs.celeryq.dev/en/stable/userguide/optimizing.html),
[Redis visibility](https://docs.celeryq.dev/en/stable/getting-started/backends-and-brokers/redis.html)
and [worker limits](https://docs.celeryq.dev/en/stable/userguide/workers.html).

## Evidence at the runtime boundary

Use framework client tests for schema/auth/error translation, including lifespan
startup/shutdown. In-process transports do not prove sockets, reverse proxies,
worker startup or client-disconnect semantics. Add a loopback server check when
those contracts matter. For durable work, run a real broker/worker and observe
serialized payloads, retry, duplicate delivery, worker loss and terminal status;
Celery eager mode is not delivery testing. Keep optional infrastructure tests
separate from the dependency-free examples in this bundle.
