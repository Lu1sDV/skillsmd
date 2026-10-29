# Collection Invariants

## Arrays, maps, sets, and records

| Decision | Preserve |
| --- | --- |
| Sort an array | Comparator consistency; numeric ordering; allowed mutation; tie behavior |
| Copy nested data | Required copy depth; deliberate shared references |
| Count or group | Correct absent-key default; no truthiness check for stored zero |
| Deduplicate | SameValueZero for primitives and identity for objects; domain-specific keys if value equality is required |
| Serialize Map/Set | Explicit representation and round-trip policy |
| Use an object dictionary | Own-property checks and prototype policy; property-key coercion |
| Use weak collections | Appropriate weakly holdable keys; no size or iteration requirement |

Check runtime and compiler-library support before using weak collections with non-registered symbols. Do not assume every primitive can be weakly held.

Treat `Object.groupBy` results as null-prototype objects. Do not call inherited object methods on them. Use `Map.groupBy` when grouping requires arbitrary key identity and the runtime supports it.

## FIFO queues

Maintain `head <= tail` and define the live range. For a finite traversal, an array plus a moving head avoids repeated front removal. For a long-lived queue, compact or use a ring buffer and release consumed references.

Mark a graph node as discovered when enqueuing it if each vertex should enter once. Measure frontier size from live elements, not the backing array's historical length. For level traversal, capture the current level boundary before appending the next level.

Do not claim linear traversal while charging `Array.shift` as constant time. A Map-backed queue also needs an index-reset policy for prolonged operation.

## Binary heaps

Require `(a, b) => number` with a documented sign convention. Maintain the parent-versus-child ordering after every insertion and removal. Define behavior for ties, empty heaps, NaN-like priorities, and mutable priority fields.

| Operation | Typical binary-heap bound |
| --- | --- |
| Peek root | O(1) |
| Insert or remove root | O(log n) |
| Bottom-up heapify | O(n) |
| Build by n insertions | O(n log n) worst case |
| Search arbitrary value | O(n) |

Use two heaps for a running median only while both the partition-order and size-balance invariants hold. Define the median of an empty stream explicitly.

## Lists, trees, and graphs

- Update both head and tail when inserting/removing the first or last list node; keep size synchronized.
- Make nullability explicit on tree/list links; keep mutation ownership clear.
- Distinguish directed from undirected edges and include isolated vertices when the task needs them.
- Represent weighted edges with labeled tuples or objects; distinguish absent edges from zero-weight edges.
- Use iterative traversal when depth may exceed the runtime's call stack.
- Distinguish active-path cycle detection from a global seen set; a repeated reference in a DAG is not automatically a cycle.

## Complexity assumptions

Use expected O(1) Map/Set access only as a stated practical assumption. ECMAScript requires average sublinear access, not a particular hash-table implementation or worst-case O(1). Include key creation and comparison costs in the full operation.

Treat array-end insertion as amortized in the usual dynamic-array model; include linear work for copying or front removal. Do not promise a universal time or memory algorithm for built-in sort across runtimes.

## Source sections

- [Data structures: queue, heap, custom structures, and complexity](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/02-data-structures.md#queue-implementation)
- [Standard library: collections](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/15-std-library-essentials.md#collections--data-structures)
- [ECMAScript Map semantics and access requirements](https://tc39.es/ecma262/multipage/keyed-collections.html#sec-map-objects)
- [ECMAScript Object.groupBy](https://tc39.es/ecma262/multipage/fundamental-objects.html#sec-object.groupby)
