---
name: go-system-design
description: >
  Use when organizing Go packages or modules, deciding internal versus pkg,
  evolving a CLI or net/http service, choosing clean/hexagonal/DDD boundaries,
  or assigning startup configuration, SQL transaction and shutdown ownership.
---

# Go System Design

## Route the work

| Decision or symptom | Default and reference |
|---|---|
| Flat/features/layers, import cycles, `internal`, `pkg`, modules | Earn each boundary; packages are not modules. [Packages and boundaries](references/packages-boundaries.md) |
| Clean/hexagonal architecture, ports, aggregates, shared models | Isolate real policy without copying a skeleton. [Packages and boundaries](references/packages-boundaries.md) |
| CLI versus HTTP, explicit wiring, resources, graceful shutdown | Share the operation, not the transport; assign an owner. [Applications and lifecycle](references/applications-lifecycle.md) |
| Config validation, SQL pool/transaction identity, external effects | Parse at startup; commit one coherent operation. [Transactions and configuration](references/transactions-config.md) |

Read the relevant guide before changing boundaries; no sibling or upstream checkout
is required. Commands and source/correction mapping: [README](README.md).
Retain [LICENSE.upstream](LICENSE.upstream).

## Workflow

1. **Trace one operation.** Name callers, validation/authorization, policy, state
   changes, external effects and public success/errors. Record Go/toolchain
   baseline, drivers and deployment constraints.
2. **Minimize boundaries.** Split files before packages when sufficient. Use concrete
   operations and explicit constructor arguments; consumer-owned interfaces need
   real capability/policy seams. Team size and line count dictate neither
   architecture nor service splits.
3. **Define consistency/identity.** What commits together, in which exact transaction,
   and what may be lost, duplicated or unknown? Resolve unclear destructive/loss
   policies rather than choosing silently.
4. **Assign lifetimes.** Parse config once; assign owners to process pools, operation
   transactions, request resources and workers. Unwind partial startup; stop
   accepting, drain/join, then close dependencies with a deadline.
5. **Migrate the path.** Update imports, callers, constructors, public error
   translation, configuration and schema/deployment contracts. Preserve unrelated
   behavior when moving code between packages.

## High-risk guards

- `internal` restricts the importer tree rooted at its parent, **not simply the
  module**. `pkg` and `cmd` are ordinary directory names, not access controls.
- Keep SQL/HTTP types out of policy only where independence matters. A universal
  `domain` package, generic repository, DI container or forwarding service is not
  required. Domain code can use standard-library types and packages.
- `*sql.DB` is a pool; every atomic statement must use the same `*sql.Tx`.
  Sharing a pool or context does not share a transaction. Check commit errors;
  a failed/unknown commit is not proof that retrying the mutation is safe.
- Constraints enforce uniqueness under races. A save followed by event publishing
  is a dual write; ignoring the publisher error does not create reliable delivery.
- Cancellation is cooperative, not preemption. Passing a context cannot unblock
  an arbitrary reader or make after-response goroutines durable. Own and join work.
- `os.Exit`/fatal logging skip defers. `Shutdown` needs its own live deadline and
  does not manage application workers or hijacked connections. Close pools last.
- Validate external settings/requests and keep secrets out of responses/logs.
  Tags are not validation; unexported fields do not make mutable aliases immutable.

## Version and completion evidence

Runnable examples target **Go 1.25.0+**, use only stdlib and local module code, and
need no downloaded modules. Method-aware HTTP patterns require Go 1.22+ and normal
modern mux semantics. Core readers, explicit wiring and `database/sql` are older
APIs; the declared example baseline is not an older-version certification.

A complete change has concrete callers, public failure behavior, configuration
and resource/transaction owners, plus a boundary regression. Use the bundled
line-count CLI and self-stopping loopback demo as runnable examples, not a fake
application or production framework. For SQL/durability claims, use the actual
engine/driver and restart/failure tests; HTTP recorders cannot establish them.
Report only executed commands, runtime versions and observed results, with blocked
or unverified paths named explicitly. Authoring this bundle does not run its checks.

Optional handoffs: **go-idiomatic** for ordinary language/error mechanics,
**go-api-design** for interface/type contracts, **go-concurrency** for worker
coordination, **go-stdlib** for I/O/network APIs, and **go-tdd** for test workflow.
