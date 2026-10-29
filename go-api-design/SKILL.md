---
name: go-api-design
description: >
  Use when designing or reviewing Go public APIs, generic constraints and type
  inference, interface method sets or typed nil, consumer-owned contracts, SOLID
  tradeoffs, constructors and functional options, or creation, composition and
  behavioral design patterns such as adapters, middleware, observers and state.
---

# Go API Design

## Route by decision

| Need or symptom | Default / local reference |
|---|---|
| Generic signature, `~`, inference, `comparable`, generic methods | Preserve type relationships, not abstraction for its own sake — [Generics](references/generics.md) |
| Interface boundary, method set, typed nil, SOLID, substitutability | Define the consumer's behavioral contract — [Contracts](references/contracts.md) |
| Constructor, singleton, factory, builder, clone, pool, options | Ordinary construction first — [Construction](references/construction-patterns.md) |
| Adapter, bridge, composite, decorator, facade, flyweight, proxy | Explicit composition — [Composition](references/composition-patterns.md) |
| Chain, command, iterator, mediator, memento, observer, state, strategy, template, visitor | Functions and owned state — [Behavior](references/behavior-patterns.md) |

Load only the needed local reference; no sibling or online documentation is
required. Pattern names do not mandate interfaces or structs.

## Workflow

1. **Read consumers.** Record supported versions, callers and dependency owners.
   Specify inputs, zero/nil, missing versus failed results, ordering, partial
   success, blocking, mutation and cleanup.
2. **Minimize representation.** Prefer concrete values/functions; function parameters
   for one policy, consumer-owned interfaces for capabilities, type parameters for
   relationships across types. External boundaries may have one implementation.
3. **State invariants.** Validate external data before side effects. Define constructor
   copy/borrow rules for slices/maps, zero-value usability, resource closers and
   independence of built snapshots.
4. **Wire at the owner.** Construct dependencies explicitly in `main` or their owning
   scope and pass them to consumers. Prefer stdlib contracts. Expose startup errors
   and release acquisitions when later construction fails.
5. **Test real consumers.** Method satisfaction proves only compilation. Exercise
   size limits, EOF/short writes, errors, cancellation, typed nil, aliasing and
   failure-state preservation across implementations.
6. **Finish migration.** Update all affected callers, docs and tests. Document
   signature/default/error/ownership/lifecycle changes; unresolved consumers block
   completion, rather than count as compatibility work.

## High-risk guardrails

- **Interfaces are not pointers.** A typed nil pointer stored in an interface is
  non-nil. Return literal `nil` for success; do not hide producer bugs with a
  universal reflection-based nil check. Pointer/value method sets differ.
- **`comparable` is not panic immunity.** Since Go 1.20, `any` can satisfy a
  `comparable` constraint; comparing equal dynamic slice/map/function types or
  using an unhashable dynamic map key can panic. NaN is not equal to itself.
- **Composition is not inheritance.** Embedding promotes methods; it does not
  provide virtual dispatch or automatically preserve wrapper optional interfaces.
- **Ownership survives a pattern name.** Shallow copies keep nested aliases;
  `sync.Once` protects initialization, not future mutation; `sync.Pool` neither
  bounds resources nor guarantees retention or cleanup. Never copy used sync types.
- **SOLID is a tradeoff.** No fixed interface method count, mandatory repository,
  automatic registry or interface-per-struct rule. Keep closed branching when clear.

## Version gate

Read `go.mod`, `toolchain`, CI and supported consumers before using newer syntax.
Generics require Go 1.18; comparison constraint satisfaction changed in 1.20;
`cmp`/`slices`/`maps` and `sync.OnceValues` arrived in 1.21; range-over-function and
iterator collection helpers in 1.23; generic aliases in 1.24. This bundle's isolated
[examples](examples/go.mod) declare **Go 1.25.0**; older versions are not certified.

## Completion and evidence

Report toolchain, exact commands, observed results and unperformed checks. Compile
acceptance does not prove behavior, race freedom, security or live API compatibility.
The [README](README.md) records commands, coverage, correction decisions and the
[upstream notice](LICENSE.upstream). Optional handoffs: **go-tdd** for test workflows,
**go-concurrency** for synchronization/lifetimes, **go-system-design** for application
boundaries, and **go-algorithms** for data-structure implementation; none is required.
