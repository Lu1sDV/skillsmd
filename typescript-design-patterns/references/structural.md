# Structural patterns

Identify the contract boundary and ownership of wrapped objects before choosing
how to compose them. Prefer ordinary functions or objects when they express it.

## Select and reject

| Requirement | Choose | Avoid when |
| --- | --- | --- |
| Translate a legacy/external interface into a desired contract | Adapter | A direct call already matches the consumer's needs |
| Separate two dimensions that vary independently | Bridge | There is only one meaningful dimension of change |
| Operate uniformly on leaves and nested groups | Composite | The data is flat or leaf/group operations are fundamentally different |
| Combine optional responsibilities around a common interface | Decorator | One explicit function is clearer than a configurable wrapper stack |
| Offer a smaller entry point to a subsystem | Facade | It would hide necessary controls or become a new god object |
| Share repeated immutable intrinsic data | Flyweight | Memory sharing has no meaningful benefit or data must vary per instance |
| Mediate access, lazy lifetime, or caching behind a contract | Proxy | Indirection changes identity/behavior without serving a requirement |

## Adapt contracts and simplify interfaces

1. For an Adapter, enumerate mismatches: field names, units, timestamps, optional
   values, callbacks versus promises, error forms, and lifecycle operations.
2. Validate external input before adaptation. Do not treat an interface annotation
   as evidence that a response has the expected shape.
3. Preserve meaningful information. If mapping names or dates is lossy, define
   the accepted limitation instead of promising a reversible transformation.
4. For callback-to-promise conversion, settle exactly once, propagate errors,
   and define cancellation or multi-event behavior when present.
5. For a Facade, expose the common operation while retaining necessary error,
   cancellation, resource, and configuration controls. Keep orchestration focused.
6. For a Bridge, vary each dimension independently and test representative
   combinations. Do not reproduce a product of subclasses behind new names.

## Compose wrappers

- Define wrapper order explicitly. Logging outside a cache records cache hits;
  logging inside records underlying fetches. Recovery inside a cache may cache
  fallback values. Choose the intended observable behavior.
- Preserve synchronous versus asynchronous results, rejected errors, cancellation,
  and method receivers. Use `try/finally` for timing/cleanup that must run on failure.
- Keep cache keys tied to every argument and context that influences the result.
  Define invalidation after writes, expiry, memory bounds, and returned-value
  mutation policy. Decide whether concurrent misses share in-flight work.
- Do not silently convert operational errors into a valid-looking fallback.
  Require a domain-appropriate recovery contract when adding recovery wrappers.
- Distinguish the Decorator pattern from TypeScript `@decorator` syntax. Object
  composition and higher-order functions need no decorator compiler setting.

## Handle Proxy semantics deliberately

Use an explicit interface wrapper unless dynamic property interception is needed.
For JavaScript `Proxy`, verify the relevant property-access, receiver, enumeration,
descriptor, and invariant behavior; native methods/private fields may need special
receiver handling. Do not assume a proxy is indistinguishable from its target.

For protected/public data, construct an explicit projection containing allowed
fields. `Omit<T, K>` changes a type only, and hiding a property in `get`/`ownKeys`
does not necessarily hide its value through descriptors or other reflective APIs.
Put actual authorization in the service boundary that owns access.

For lazy proxies, decide which operations initialize the target and what happens
after initialization failure. For caching proxies, apply the wrapper cache rules
above and keep writes consistent with cached reads.

## Compose trees and shared data

| Pattern | Establish | Verify |
| --- | --- | --- |
| Composite | Leaf/group contract, child ownership, traversal order, mutation policy | Empty groups, deep trees, shared children, cycles if inputs can contain them |
| Flyweight | Immutable intrinsic state versus per-instance extrinsic state | Sharing identity, accidental shared mutation, key collisions, retained memory |

For Composite, reject cycles if the API promises a tree; otherwise use graph-aware
traversal with a visited policy. Use iterative traversal for deep untrusted input
when recursion depth is a concrete risk. Prefer a head-index queue over repeated
front removal for broad breadth-first traversal.

For Flyweight, include all intrinsic fields in the cache identity and establish
eviction or scope. Measure retained memory on a representative workload before
claiming a memory improvement. Count shared-state ownership as part of the cost.

## Verify through the public contract

Exercise the wrapped and unwrapped implementation with equivalent inputs where
their behavior should match. Cover error paths, wrapper composition order,
mutation, cleanup, and concurrency when relevant. Test Adapter round trips only
when reversibility is actually part of the contract.

## Source

Adapted topic selection from [chapter 11: Structural Design Patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/11-design-patterns-structural.md).
Qualify its proxy and cache examples with the access, reflective behavior,
invalidation, and lifetime requirements above.
