---
name: typescript-design-patterns
description: >
  Use when choosing, implementing, or reviewing TypeScript design patterns for creation,
  composition, communication, and state: factories, builders, cloning, shared-resource
  lifetime, adapters, facades, wrappers, composites, proxies, flyweights, strategies, state
  machines, observers, mediators, commands, undo/redo, middleware, iterators, template
  methods, or visitors. Compare candidates with plain functions, objects, modules, or
  discriminated unions and preserve behavior and lifecycle contracts.
---

# TypeScript Design Patterns

Choose a pattern from the problem's variation and ownership requirements.
Keep the implementation as small as the contract allows.

## Define the design pressure

1. Read the existing interfaces, callers, module conventions, and tests around
   the requested change. Identify the runtime and compiler features available.
2. State what varies: object creation, implementation combinations, behavior,
   state transitions, event recipients, or operations over a stable structure.
3. State what stays stable: a client contract, construction invariant, ordering
   rule, state transition rule, or lifecycle boundary.
4. Record relevant constraints: sync/async behavior, mutation, identity, error
   propagation, cancellation, disposal, serialization, and concurrent use.
5. Compare a plain function/object with one or two candidate patterns. Choose
   based on the current requirement; avoid abstractions for hypothetical variants.

## Select one family reference

| Problem | Read |
| --- | --- |
| Product selection, compatible families, construction stages, copies, shared resources | [Creational patterns](references/creational.md) |
| Contract translation, wrappers, trees, independent dimensions, access, shared data | [Structural patterns](references/structural.md) |
| Policy, transitions, events, coordination, undo, middleware, traversal, extension hooks | [Behavioral patterns](references/behavioral.md) |

Load only the family needed for the task. Use the other references only when
comparing overlapping choices, such as Decorator versus Proxy or Command versus
Memento. Keep creation policy separate from the behavior being created.

## Implement the contract

1. Define the smallest type the client needs. Prefer typed functions for a single
   operation, composed objects for capabilities, and classes when identity or
   lifecycle makes them useful.
2. Keep construction and external I/O wiring at clear boundaries. Reuse the
   project's established libraries and integration conventions.
3. Preserve input/output relationships with generics or discriminants. Localize
   necessary assertions and verify the invariant behind them; do not silence a
   mismatch with `any` or a broad assertion.
4. Validate untrusted runtime inputs before treating them as a factory choice,
   event payload, configuration, or transition. Types alone do not validate data.
5. Define state and resource ownership explicitly. Bound caches/history where
   appropriate; return disposal/unsubscribe handles for owned registrations.
6. Make failures observable. Define retry, rollback, and partial-completion policy
   when a wrapper, chain, command, or initialization performs several effects.
7. Keep examples small and executable in their stated environment. Replace
   teaching stubs with the user's real adapters when producing application code.

## Verify the pattern's invariant

| Family | Verify |
| --- | --- |
| Creation | Required fields, invalid choices, compatible product family, clone independence, shared initialization and failure policy |
| Structure | Contract translation, wrapper order, method receiver behavior, cache invalidation, access policy, empty/deep composites |
| Behavior | Legal/illegal transitions, event-payload correlation, listener cleanup, failure propagation, undo/redo history, traversal order |

Run the repository's typecheck and focused behavior checks. For replacement
implementations, run the same public contract against each. For async components,
include concurrent calls, rejection, cancellation, and cleanup when relevant.
Add tests for meaningful behavior or concrete defects, not for the existence of
pattern-named classes.

## Deliver the result

Explain the requirement, chosen pattern, simpler alternative considered, and
resulting public contract. Include the implementation or focused review findings,
verification evidence, and material tradeoffs such as indirection, retained state,
or lifecycle complexity. State which checks were not run.

## Source basis

Use the 22 patterns covered by the pinned teaching guides as the source taxonomy.
Apply the qualifications in the references instead of copying samples blindly.

- [Creational patterns, chapter 10](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/10-design-patterns-creational.md)
- [Structural patterns, chapter 11](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/11-design-patterns-structural.md)
- [Behavioral patterns, chapter 12](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/12-design-patterns-behavioral.md)
