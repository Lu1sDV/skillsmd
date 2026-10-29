---
name: typescript-maintainable-design
description: >
  Use when reviewing or refactoring TypeScript modules and services for excessive coupling,
  invalid inheritance, broad interfaces, dependency injection, unsafe assertions, mutable
  shared state, swallowed errors, circular imports, or maintainability and anti-pattern
  concerns. Apply SOLID through explicit behavior contracts and focused dependencies; tie
  performance changes to measured workloads and route detailed algorithm, async, and type-
  system work to specialist skills.
---

# TypeScript Maintainable Design

Turn a concrete design problem into a small, behavior-preserving change. Use
SOLID to reason about boundaries; judge the result by observable behavior and
the cost of the next required change.

## Establish the contract

1. Read the repository instructions, package scripts, compiler configuration,
   affected callers, and existing tests. Keep the established module/framework
   conventions unless the task requires changing them.
2. State the current problem and one representative example. Separate a
   correctness defect from maintainability friction or an unmeasured speed claim.
3. Record input/output types, accepted values, errors, mutation, ordering, and
   resource lifetime. Distinguish compile-time promises from runtime guarantees.
4. Identify external boundaries: parsed JSON, storage, requests, environment
   values, plugin callbacks, and untyped libraries. Track where validation occurs.
5. For a refactor, preserve these contracts. For a bug fix, identify the specific
   behavior that must change and verify the corrected behavior.

## Select the smallest intervention

| Observed pressure | Apply this lens | Prefer this intervention |
| --- | --- | --- |
| Policy, persistence, and presentation change for different reasons | Single responsibility | Extract cohesive functions or modules; retain an orchestrator where useful |
| Several implementations vary behind a stable contract | Open/closed | Inject a typed strategy/function or introduce a registration seam |
| An implementation narrows valid inputs or weakens outputs/behavior | Liskov substitution | Repair the contract, use capability interfaces, or replace inheritance with composition |
| Consumers implement or depend on members they do not use | Interface segregation | Accept a focused role interface, `Pick`, or a small function type |
| Domain behavior directly constructs replaceable I/O dependencies | Dependency inversion | Inject a domain-owned port; wire concrete adapters at the application boundary |

Keep an exhaustive discriminated-union switch for a small closed set of cases.
Introduce an extension mechanism only for a real variation requirement. Do not
create a class, interface, factory, and container for every function.

Read [the review checklist](references/review-checklist.md) for boundary,
state, import, error, and performance checks relevant to the concrete problem.

## Implement with explicit ownership

1. Keep domain calculations independent of network, storage, clocks, and mutable
   global state where those dependencies obstruct the requested behavior or tests.
2. Inject the smallest useful interface or callback. Define ownership of opening,
   closing, resetting, and sharing resources; keep construction at a clear boundary.
3. Validate external values from `unknown`. Use a guard or the project's existing
   schema library that checks every property its resulting type promises.
4. Replace invalid boolean combinations with discriminated states. Preserve valid
   falsey values; choose `??` when only `null` and `undefined` mean absence.
5. Handle or propagate errors deliberately. Retain causes and distinguish expected
   domain failure from operational exceptions. Do not report success after failure.
6. Give every promise an owner that awaits, returns, or explicitly handles it.
   Preserve cancellation, partial-success, and retry semantics during extraction.
7. Resolve import cycles by changing dependency direction, extracting shared types,
   or introducing a port. Use `import type` for type-only dependencies. Inspect the
   resulting graph; replacing a barrel import alone may leave the cycle intact.
8. Make small edits around the identified seam. Preserve public names and data
   shapes unless a migration is explicitly part of the task.

## Preserve the hard invariants

- Treat type assignability as one check, not proof of behavioral substitution.
  Accept at least the contract's input domain and preserve promised outputs,
  errors, effects, and state invariants. A broader accepted input is generally safe.
- Distinguish method parameter bivariance from function-property checking under
  `strictFunctionTypes`; do not rely on the compiler to prove an LSP argument.
- Treat `readonly`, `as const`, `Pick`, and `Omit` as type-level tools. Use explicit
  runtime projection to omit sensitive fields and explicit copying/freezing when
  the runtime contract requires it.
- Preserve duplicate handling, insertion order, equality, and aliasing when
  replacing arrays with Maps/Sets or copying with mutation.
- Retain shared-state scope deliberately. A module-owned object does not imply
  a unique instance across workers, processes, or separately loaded module copies.
- Treat line counts, class names, dependency counts, and engine-shape thresholds
  as clues to investigate, never automatic reasons to restructure working code.

## Verify the change

1. Run the existing typecheck and the focused behavior checks for changed callers.
   Add a regression case for an actual defect; avoid tests that merely mirror
   the new private implementation.
2. For replaceable implementations, exercise the same contract with representative
   inputs and failures. Check mutation, error propagation, and state isolation.
3. For boundaries, test malformed, missing, null, and falsey values that matter
   to the domain. Verify rejected data never reaches the trusted core.
4. For lifecycle changes, check repeat calls, cleanup, and independent tests.
   For import changes, run the applicable build/runtime entry point.
5. For a performance requirement, compare the original and changed code on the
   same representative workload and verify identical observable results.

## Deliver the result

Explain the original problem, selected boundary, behavior preserved or changed,
and validation evidence. For a review, prioritize concrete findings with file
locations and consequences. For an implementation, show the relevant change
and any migration or compatibility limit. Do not claim unrun checks passed.

## Source basis

Adapt the concepts from these pinned teaching guides; treat their examples as
illustrations and verify actual project contracts before implementation:

- [SOLID principles, chapter 09](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/09-solid-principles.md)
- [Anti-patterns and best practices, chapter 13](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/13-anti-patterns-best-practices.md)
