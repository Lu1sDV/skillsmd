# Creational patterns

Choose a creation abstraction only when construction, product selection, copying,
or lifetime has a contract beyond an ordinary object literal or constructor.

## Select and reject

| Requirement | Candidate and TypeScript form | Reject when |
| --- | --- | --- |
| Select a product behind one public contract | Use a typed factory function; use Factory Method when subclasses supply a creation hook | Direct construction is already clear and stable |
| Create compatible families of related products | Use an Abstract Factory as an interface or object of creators | There is one product or no family compatibility rule |
| Enforce construction stages or many interacting options | Use a Builder with validated `build()` or staged types | An options object plus defaults expresses the constraints |
| Copy configured instances with defined semantics | Use Prototype with an explicit `clone()` method | Ordinary construction is cheap or copying semantics are undefined |
| Share one managed instance within a specific scope | Use an injected scoped resource or module-owned Singleton | Isolation, multiple configurations, or independent instances are required |

## Factories and product families

1. Put the public product contract before the concrete classes. Return a useful
   interface or discriminated union; avoid leaking construction details to callers.
2. Validate runtime selectors and configuration. A TypeScript union does not make
   parsed strings valid. Give unknown selections an explicit error/result policy.
3. Preserve useful output precision. Use overloads or a typed mapping when a
   literal selector must imply a specific return type; otherwise return a union
   and let callers narrow it.
4. For a family, define what makes products compatible. Keep their creation under
   one selected factory and test the supported combinations.
5. For registrations, define duplicate-key and missing-key behavior. Establish
   whether registration is closed after startup or can change at runtime.

Use a simple factory function as the default creation seam. Reserve the name
Factory Method for the pattern in which a base workflow delegates creation to
subclass behavior; a switch returning objects does not require that hierarchy.

## Builders and configuration

- List required fields and cross-field constraints. Enforce them at the point
  a valid object becomes usable; retain runtime validation for external inputs.
- Prefer an options object for independent optional values. Use staged types
  only when the sequence itself is a useful caller constraint.
- Decide whether setters mutate a builder or return a new builder. Test reuse
  and interleaved branches so one configuration does not alter another unexpectedly.
- Return a snapshot if later builder edits must not change built results. A spread
  only copies one level; handle nested arrays/objects according to ownership.
- Preserve literal types deliberately with `as const` or a suitable `const` type
  parameter when supported. Ordinary generic object inference can widen primitive
  properties; `satisfies` checks compatibility without serving as runtime validation.
- Distinguish shallow `Readonly<T>` and `Object.freeze` from deep immutability.

## Prototypes and cloning

Define the allowed source values and the meaning of an independent copy before
implementing a generic-looking clone function.

| Source characteristic | Decide and test |
| --- | --- |
| Nested mutable data | Copy required levels; verify later mutation does not leak |
| Shared references and cycles | Preserve topology, deliberately duplicate, or reject |
| Classes and methods | Reconstruct domain instances or reject unsupported objects |
| Dates, Maps, Sets, typed arrays | Preserve required value semantics |
| Resource handles and subscriptions | Recreate, share intentionally, or prohibit copying |
| Identity/timestamps | Preserve or regenerate according to the domain contract |

Use `structuredClone` only for supported data whose semantics match the task.
Use explicit domain cloning for behavior-rich instances. Do not present a
recursive object/array copier as a correct clone of arbitrary `T`; prototypes,
descriptors, symbols, cycles, and special objects need deliberate handling.

## Shared instances and initialization

1. Name the scope: request, tenant, application module, worker, or process.
   Do not equate module caching with one instance across all deployment contexts.
2. Prefer injecting a shared instance where callers need test isolation or
   configurable lifetime. Avoid mutable global state as an implicit dependency.
3. Track initialized state independently if the factory can return `0`, `false`,
   an empty string, or `undefined`; truthiness is not a valid cache sentinel.
4. For async initialization, share one in-flight promise when duplicate startup
   is forbidden. Publish usable state only after initialization succeeds.
5. Define failure policy: retain the failure or allow a controlled retry. Clear
   failed state consistently if retry is supported; do not leave half-initialized
   objects reachable by later callers.
6. Define disposal and reinitialization. Test concurrent first access, failure,
   repeated disposal, and test-suite isolation when those behaviors matter.

## Source

Adapted topic selection from [chapter 10: Creational Design Patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/10-design-patterns-creational.md).
Treat its singleton, clone, and literal-inference examples as teaching material;
use the explicit contracts and qualifications above when implementing them.
