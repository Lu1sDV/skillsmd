---
name: python-api-design
description: >
  Use when designing or reviewing Python public APIs and compatibility, schema
  evolution, static-checker coverage, generic type contracts, Protocol/ABC
  boundaries, TypedDict schemas, dataclass invariants, dependency
  injection, or SOLID and design patterns: factories, builders, adapters,
  decorators, state machines, shallow immutability, cooperative MRO, and descriptors.
---

# Python API Design

## Route by decision

| Need | Default / reference |
|---|---|
| Public exports, changed defaults, deprecation, HTTP/schema compatibility | Review actual consumers and generated contracts — [Evolution and public surface](references/evolution.md) |
| Public types, generics, Protocol/ABC, external schemas | Concrete signatures; validate separately — [Typing contracts](references/typing-contracts.md), including the validated `ByteRange` example |
| Establish or repair type-checking coverage; distribute typed libraries | Reuse the project's checker and verify downstream types — [Checker operations](references/checker-operations.md) |
| Constructor, singleton, factory, builder, prototype, pool | Direct construction and explicit resource owner — [Creation](references/creational.md) |
| Adapter, bridge, composite, decorator, facade, flyweight, proxy | Explicit composition — [Composition](references/structural.md) |
| Chain, command, iterator, mediator, memento, observer, state, strategy, template, visitor | Ordinary control flow and owned state — [Behavior](references/behavioral.md) |
| SOLID, mutable class state, inheritance, MRO, descriptors | Consumer contracts and composition before mixins — [Class mechanics](references/class-mechanics.md) |

Load only the relevant reference. Pattern names do not require classes or frameworks.
Recognize unnamed pattern-shaped problems: constructor variants, parallel
subclasses, repeated mode dispatch, undo/history, event subscribers or tree
traversal. These are review cues, not automatic reasons for more layers.
Use Python 3.15 for new projects; preserve an existing project's declared minimum.

## Workflow

1. **Define compatibility and behavior.** Read actual callers, supported Python
   versions and checker configuration. Specify inputs/units, missing versus failed
   results, ordering, exceptions, side effects, mutation-on-error, blocking, and
   mutable-value/resource ownership. Ask the API owner about unresolved observable
   choices rather than silently changing policy.
2. **Choose a representation.** Function for an operation, dataclass for a record,
   enum/union for a closed domain; object when state and invariants belong together.
   Choose dataclass constructor, mutation and layout policies deliberately. Use a
   callable for one injected operation or a small protocol for a capability.
3. **Validate at the trust boundary.** Decode external data into `object`, check
   shape/domain before side effects, then construct typed values. Annotations,
   `cast`, `TypedDict`, and `NewType` do not validate input.
4. **Integrate a real consumer.** Pass policies/resources explicitly and create/close
   resources where their lifetime is owned. Preserve initialization and operation
   failures through adapters; specify partial-success behavior. No pretend transports
   or success strings standing in for work.
5. **Check substitutability and exposure.** Test documented import paths and follow
   delegated route registration; inspect generated schemas when relevant. Exercise
   accepted/rejected inputs, aliases/mutation, failure-state preservation and cleanup. Run shared
   behavioral checks for interchangeable implementations and separate positive/
   negative static-checker cases; neither proves the other's contract.
6. **Close the migration.** Update callers/examples and document changed parameter
   names/kinds, defaults, returns, mutability, exceptions, and cleanup. Preserve old
   behavior during a documented deprecation window; hiding a schema is not migration. Track each
   consumer as pending, migrated, verified, or blocked; unresolved consumers prevent
   a completion claim.

## High-risk gotchas

- **Presence is not compatibility.** Runtime protocols check members, not signatures
  or behavior. ABCs block abstract instantiation, not incompatible overrides.
- **Read-only is not independent.** `Mapping` and mapping proxies can expose live
  mutable state; frozen records and shallow copies can retain nested aliases.
- **Wrappers can bypass contracts.** `__getattr__` does not forward implicit special
  methods. Review validation/access checks, authorization-aware cache keys, and
  resource lifetime; retries of non-idempotent effects can duplicate work.
- **Annotations are versioned and executable.** Python 3.14+ defers them by default;
  3.11–3.13 does not. Introspection can execute expressions. Preserve the project's
  minimum version; consult the typing reference before changing syntax/evaluation.

## Completion and evidence

Report interpreter/checker versions, commands, observed outcomes, and unperformed
checks. Do not claim completion with missing boundary checks, bypassed invariants,
or unresolved consumers. Doctests do not establish static acceptance or untested
runtime compatibility.

This bundle works alone; optional handoffs are **python-tdd** for regression work,
**python-concurrency** for synchronization/cancellation, and **python-system-design**
for configuration/deployment/transaction ownership. Guidance targets stable Python
3.15; [README](README.md) records example/version gates, commands, source decisions, and
the [upstream license](LICENSE.upstream).
