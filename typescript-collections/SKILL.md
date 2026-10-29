---
name: typescript-collections
description: >
  Use when choosing, implementing, or reviewing TypeScript collections and JavaScript
  runtime APIs: arrays, maps, sets, queues, heaps, linked structures, generators, text and
  binary processing, JSON, cloning, dates, or numeric data where ordering, equality,
  mutation, memory, or runtime compatibility matters.
---

# TypeScript Collections and Runtime APIs

## Establish the contract

1. Inspect the existing runtime, `tsconfig`, libraries, dependencies, and test commands before choosing APIs.
2. Record input size, key/value domain, ordering, equality, missing-value behavior, and ownership of mutable data.
3. Distinguish a known record shape from a dynamic dictionary; distinguish a materialized collection from a stream.
4. Define whether the result must preserve input objects, nested objects, insertion order, or serializable form.
5. Identify numerical bounds, character representation, byte order, and timezone whenever the operation depends on them.

## Choose the representation

| Requirement | Starting choice | Verify |
| --- | --- | --- |
| Ordered sequence or LIFO stack | `Array<T>` | Mutation, sparse entries, removal costs |
| Membership or deduplication | `Set<T>` | Identity versus value equality |
| Dynamic keys and frequent lookup | `Map<K, V>` | Missing versus stored `undefined`; key identity |
| Fixed named fields | Interface/type plus object | Runtime validation at external boundaries |
| Dynamic property dictionary | Object with deliberate prototype policy or `Map` | Own keys, coercion, serialization |
| FIFO processing | Head-index queue or deque | Compaction and release of consumed references |
| Repeated minimum/maximum extraction | Binary heap with explicit comparator | Heap invariant and empty-state behavior |
| Local insertion/removal with node references | Linked structure | Head, tail, size, ownership |
| Dense numeric/binary storage | Typed array and `DataView` | Range, shared buffer, endianness |
| Metadata tied to object lifetime | `WeakMap` / `WeakSet` | No enumeration; nondeterministic collection |
| Potentially large or infinite sequence | Iterator/generator | Laziness, termination, cleanup |

Prefer the simplest representation that meets the contract. Use `typescript-algorithm-patterns` when selecting a problem-solving algorithm; use `typescript-async-concurrency` when coordinating asynchronous work.

## Preserve collection semantics

- Use numeric comparators for numeric sorting; define tie ordering and whether sorting may mutate the input.
- Treat array spread, object spread, `slice`, and `Object.assign` as shallow copies.
- Allocate each matrix row independently; avoid `fill` with a shared mutable object.
- Use `has` when missing entries must differ from stored `undefined`; do not use truthiness to detect stored zero, false, or empty string.
- Preserve object-key identity in Map/Set; do not assume separately allocated objects deduplicate by their fields.
- Use `Object.hasOwn` for own-property checks when supported by the target; account for inherited enumerable keys with `for...in`.
- Treat `Record<string, T>` as a type declaration, not a guarantee that every runtime key is present.
- Use labeled tuples for coordinates, edges, and intervals; guard indices under the project's strict checking settings.
- Require a comparator for a generic heap; do not cast arbitrary `T` values to numbers to invent one.
- Define empty `pop`, `peek`, and `dequeue` results without assertions that disguise absence.

Read [collection invariants](references/collection-invariants.md) for queue, heap, graph, linked-structure, and complexity decisions.

## Preserve runtime semantics

- Choose UTF-16 code units, Unicode code points, or grapheme clusters explicitly; use one representation throughout an algorithm.
- Keep `number` and `bigint` arithmetic separate; check safe-integer and overflow assumptions before using sums, masks, or counts.
- Define elapsed-time calculations separately from calendar arithmetic; make formatting locale and timezone explicit when they affect results.
- Parse JSON into `unknown`, validate its structure, and define handling for Dates, Maps, Sets, cycles, and bigint.
- Use `structuredClone` only for supported data; do not assume class behavior or functions survive cloning.
- Treat `Object.freeze` as shallow; cloning and then freezing does not recursively freeze nested objects.
- Preserve errors and their causes; narrow caught values instead of assuming every thrown value is an `Error`.
- Avoid correctness-critical dependence on garbage collection or finalizers; make cache eviction explicit when required.
- Check target runtime support for modern APIs independently from TypeScript's `lib` declarations.

Read [runtime API checks](references/runtime-api-checks.md) for generators, Unicode, binary data, JSON, dates, and reflection.

## Analyze the cost

1. Count scans, sorting, copies, shifts, allocations, key construction, and materialized output.
2. Label expected/amortized costs and engine assumptions; do not promise worst-case constant-time Map/Set operations.
3. Distinguish bottom-up heapify from repeated insertion; their construction costs differ.
4. Account for retained queue prefixes and cached values as well as live logical elements.
5. Avoid spreads into `Math.max`, `Math.min`, or other function argument lists for unbounded input; reduce or iterate instead.

## Verify the behavior

- Exercise empty/singleton collections, missing keys, duplicate keys, stored falsy values, and repeated object identities.
- Check both outer-container mutation and nested-object aliasing when the contract promises preservation.
- Verify queue order and reset, heap ordering after mixed operations, and linked-list head/tail invariants.
- Test iterator early termination, zero/invalid chunk sizes, and zero-input zip behavior where relevant.
- Use large representative inputs to expose accidental quadratic work or argument/recursion limits.
- Run the project's typecheck and relevant existing tests; add focused regression cases for actual changed behavior.

## Deliver

Return the implementation or review findings, representation choice, mutation/equality contract, time and space assumptions, and checks performed. State any unresolved runtime support or input-domain assumption.

## Sources

- [StructWeave: data structures](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/02-data-structures.md)
- [StructWeave: standard library essentials](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/15-std-library-essentials.md)
- [ECMAScript keyed collections](https://tc39.es/ecma262/multipage/keyed-collections.html)
- [HTML structured cloning](https://html.spec.whatwg.org/multipage/structured-data.html#structured-cloning)
