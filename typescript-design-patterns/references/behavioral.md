# Behavioral patterns

Choose from the contract governing decisions, communication, state, or traversal.
Prefer a typed function or discriminated union before introducing a hierarchy.

## Strategy, State, and Template Method

1. For Strategy, state the shared input/output/error contract. Let the client
   choose policy explicitly; keep policy independent from the context's storage.
2. Test each strategy against common constraints. Verify edge inputs and document
   the behavior intentionally allowed to differ.
3. For State, write a transition table before implementation. Distinguish valid
   transitions, idempotent repeats, and rejected actions. Preserve data required
   by later states rather than discarding it accidentally during replacement.
4. Use a discriminant to make legal state data visible to the compiler. Check
   exhaustiveness and validate runtime transitions even with static state types.
5. For Template Method, identify mandatory steps, extension hooks, and cleanup.
   Protect ordering and error invariants. Prefer composed callbacks when runtime
   configuration or simple function substitution satisfies the requirement.

## Observer and Mediator

- Define an event-to-payload type map. Correlate event names with payloads; a
  generic payload paired with an unrestricted string does not enforce that relation.
- Assign each subscription a disposal owner. Return an unsubscribe function or
  follow the project's established disposable pattern; avoid orphan listeners.
- Define ordering, duplicate subscriptions, mutation during notification, and
  reentrancy. Decide whether notification uses a snapshot of the listener set.
- Define listener failures explicitly: stop, isolate/report, or aggregate. If
  listeners may be async, decide whether publishers await them and how rejections
  are observed; a `void` callback type does not by itself prevent returned promises.
- Keep a mediator scoped to a cohesive coordination problem. Preserve explicit
  dependencies for required operations rather than hiding them behind global events.

## Command and Memento

1. Decide whether history records actions, snapshots, or both. Define snapshot
   isolation, allowed value shapes, and a memory/history limit appropriate to use.
2. Capture command parameters and any prior state needed for reversal. Define
   whether repeated execution means redo, retry, or a new action.
3. Record a command in successful history only after its operation succeeds.
   Define behavior after partial failure; several effects are not automatically
   atomic because they live in one command.
4. Reverse composite commands in reverse order. For external side effects, design
   an explicit compensation contract instead of assuming exact undo is possible.
5. Clear the redo branch after a new edit. Test initial/empty history, undo to the
   earliest state, redo to the latest, and a new edit after undo.
6. Restore an isolated snapshot or explicitly documented shared state. JSON
   serialization is not a general clone of arbitrary TypeScript values.

## Chains, iterators, and visitors

| Pattern | Preserve | Check |
| --- | --- | --- |
| Chain of Responsibility | Handler order, stop/pass meaning, completion and errors | No handler, early stop, thrown/rejected error, duplicate continuation |
| Iterator | Traversal order, exhaustion, mutation policy, resource ownership | Empty input, repeated iteration, early exit, generator cleanup |
| Visitor | Complete node handling and result type for an operation | Every node kind, nested structures, unsupported operators, invalid data |

For middleware, distinguish a chain that stops at one handler from a pipeline
where multiple stages intentionally run. Await downstream work when cleanup or
post-processing depends on it; do not fire-and-forget `next()`.

For iteration, use the standard protocol when consumers expect `for...of` or
`for await...of`. A custom `hasNext()/next()` API is a separate contract. Avoid
repeated `shift()` in large breadth-first traversal; define graph/cycle behavior
when the data is not guaranteed to be a tree.

Use Visitor when operations vary over a stable node family; prefer exhaustive
functions when node variants change frequently. Parameterize the result to avoid
pervasive result assertions. Verify each operator's semantics;
the source evaluator's unary `!` example returns its operand unchanged, so do not
reuse that implementation as a correct evaluator.

## Source

Adapted topic selection from [chapter 12: Behavioral Design Patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/12-design-patterns-behavioral.md).
Use its ten covered patterns as the taxonomy; add lifecycle, failure, history,
and type-correlation checks when translating examples into real code.
