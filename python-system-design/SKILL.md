---
name: python-system-design
description: >
  Use when structuring Python packages or modular monoliths, choosing Django,
  Flask, FastAPI, WSGI or ASGI, or designing durable jobs, database transaction
  ownership, startup configuration, secrets and deployment boundaries.
---

# Python System Design

## Route the work

| Decision | Default and reference |
|---|---|
| Package layout, dependency direction, installation or service split | Keep a cohesive package/modular monolith; test the installed wheel. [Packages and boundaries](references/packages-boundaries.md) |
| Framework/runtime, resource lifetime or background work | Reuse the supported framework; choose task lifetime before tooling. [Web and jobs](references/web-jobs.md) |
| Transactions, configuration or trust boundaries | One transaction owner per use case; parse settings at startup. [Persistence and configuration](references/persistence-config.md) |

Load the relevant reference before designing its boundary. All guidance is local;
external sources and sibling skills are not installation prerequisites.

## Design workflow

1. **Trace one operation.** Identify callers, authorization, validated inputs,
   state changes, external effects and public errors. Record the project's Python,
   framework, database, broker and deployment versions before selecting APIs.
2. **State success and failure semantics.** Name what commits together, what may
   be lost or duplicated, and whether success means accepted or completed. Ask
   the owner before choosing an unresolved loss, duplicate-effect or destructive
   policy.
3. **Keep boundaries earned.** Use concrete application functions and framework
   conventions, not mandatory repositories, DI containers or internal event buses.
   Adapters translate transport input/errors; shared rules need no web imports.
   Split services only for a real ownership, isolation or scaling boundary.
4. **Assign resource lifetimes.** Settings belong to startup, clients/pools to
   workers, sessions/transactions to operations. Pair acquisition with cleanup,
   including partial startup failure and shutdown. Deferred work receives stable
   identifiers and opens its own resources, not request-owned sessions or handles.
5. **Exercise and migrate the real boundary.** Use an installed artifact outside
   the checkout, the production database for transaction claims and real workers
   for delivery claims. Update callers, migrations, configuration and permissions
   together. During multi-file/deployment cutovers, track them as pending,
   migrated, verified or blocked.

## High-risk gotchas

- **After-response is not durable.** Process-local callbacks can be lost, and
  their failure cannot change a sent response. Required work needs persistent
  acceptance, bounded retry, duplicate handling and terminal status.
- **Database plus broker is a dual write.** An after-commit hook avoids publishing
  rolled-back work but leaves a crash gap. Use an outbox when losing the
  notification is unacceptable; consumers still need idempotency. A timeout can
  leave remote effects unknown, not safely retryable under a new identity.
- **Closing is not committing.** Follow the session API's transaction contract.
  Helpers must not commit independently when the use case needs atomicity.
  Database constraints, not check-then-insert, enforce uniqueness under races.
- **Worker processes multiply resources.** Budget pools across replicas and
  workers. ASGI neither makes blocking drivers nonblocking nor guarantees CPU
  parallelism; match the server, middleware and drivers to the execution model.
- **Types are not trust-boundary validation.** Validate and authorize requests,
  settings, broker messages and remote responses. Do not use `assert` for
  production validation, accept untrusted pickle or leak secrets through logs.

## Completion and evidence

A completed change has a concrete caller, public error behavior, explicit
resource/transaction ownership, installation steps and a failure check at the
consequential boundary. For jobs, document restart behavior and distinguish
accepted, queued, running, completed and failed. Check rollback after a later
write fails, durable state from another connection, and missing/malformed
configuration without real infrastructure.

Do not substitute doubles for required boundary checks or silently skip blocked
work. Report executed checks, runtime/dependency versions and unverified paths.
SQLite does not prove PostgreSQL locking; in-process HTTP does not prove proxies
or multi-worker behavior. These guides are not a production application.

## Optional handoffs and attribution

Use **python-idiomatic** for ordinary import/error mechanics, **python-api-design**
for type and composition contracts, **python-concurrency** for task cancellation,
backpressure and thread/process implementation, **python-tdd** for test workflow,
and **python-stdlib** for general I/O and serialization details, when installed.
None is required to use this bundle.

Examples target Python 3.11+ with the runtime qualifications in [README](README.md).
Source mapping, adaptation decisions and installation are there; retain the
[upstream MIT license](LICENSE.upstream) with the bundle.
