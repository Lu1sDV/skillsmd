---
name: go-algorithms
description: >
  Use when choosing Go slices, maps, sets, queues, heaps, linked lists, trees or
  graphs, or implementing two pointers, sliding windows, binary search, prefix
  sums, monotonic stacks, hash-map patterns, two heaps, merge intervals, cyclic
  sort, BFS/DFS, backtracking, dynamic programming, greedy or topological sort.
  Covers invariants, complexity, Unicode, integer overflow and mutation contracts.
---

# Go Algorithms

## Route by invariant

| Task / symptom | Load |
|---|---|
| Collection choice, copying, nil/empty, queue costs, slices/maps/cmp versions | [Collections and contracts](references/collections-and-contracts.md) |
| Two pointers, windows, binary search, prefix sums, monotonic stacks, hashing | [Sequence patterns](references/sequence-patterns.md) |
| Two heaps, interval merge, cyclic placement | [Ordering and placement](references/ordering-and-placement.md) |
| Trees, BFS/DFS, islands, topological order, backtracking, DP, greedy | [Traversal and optimization](references/traversal-and-optimization.md) |

Load only the relevant guide. All **14** source families are covered; its **17**
heading is wrong, not a request to invent three families.

## Workflow

1. Define size, sortedness, duplicates, missing values, interval endpoints, graph
   direction/weights, text unit, integer bounds and output order. Distinguish valid
   empty/no-answer results from invalid input.
2. Specify whether sorting, swapping, relinking, grid marking or heapification may
   mutate caller data. Shallow clones retain nested aliases.
3. State invariant and progress measure: justify candidate elimination, duplicate
   placement termination, greedy choices or acyclic DP dependencies.
4. Prefer `slices`, `maps`, `cmp`, `sort.Search`, `container/heap` and plain
   slices/maps. Helpers need actual reuse, not tutorial type parameters.
5. Count validation, sorting, key construction, rune conversion, output copying,
   recursion, adjacency construction and retained capacity. Map bounds are expected,
   not guaranteed constant time; long keys cost work.
6. Leave relevant runnable cases: empty/singleton, repeats, signed values, Unicode,
   extreme integers, aliasing, malformed domains, disconnected graphs and cycles.
   Compare bounded optimized cases with a simple oracle when useful.

## High-risk guardrails

- `s[1:]` is O(1), not a shift; it can retain a backing array. Clear consumed
  pointers. Use a head-index slice for bounded BFS, a ring for sustained queues.
- `slices.SortFunc` comparators use `cmp.Compare`, never subtraction. Binary search
  must use the same ordering as sorting; reversed slices are not ascending.
- `slices.Min/Max`, heap peek/pop and stack pop need an explicit empty policy.
  Return `(value, ok)` rather than an ambiguous zero sentinel.
- Signed arithmetic can overflow silently. Check sums/products/differences or
  prove bounds; casting to `int64` is not sufficient for arbitrary `int64` inputs.
- Threshold sum windows require nonnegative inputs. Exact signed subarray sums
  use prefix counts. Minimum-window search must return immediately for empty target.
- Byte strings are not Unicode characters. Rune algorithms count code points,
  not grapheme clusters or canonically equivalent spellings; validate UTF-8 if
  replacement of malformed bytes would change the problem.
- BFS shortest paths require equal-weight edges. DFS traversal is not enumeration
  of all simple paths. Input-controlled recursion needs a depth/resource policy.
- Never emit a partial topological order as a successful complete order. Validate
  vertex IDs; account for every edge occurrence in indegree and adjacency alike.
- Do not copy mutable median/heap state by value after use. A `comparable` generic
  argument instantiated with `any` can still panic on a slice/map/function key.

## Versions and completion evidence

Samples require **Go 1.25+**, stdlib only; no newer API is needed. Preserve the
consumer's version: consult [feature gates and behavioral differences](references/collections-and-contracts.md#generic-helpers-and-version-gates)
before choosing generic, collection, iterator or weak-pointer APIs.

Report input preconditions, invariant, termination, ownership, empty/error
semantics and full time/space costs. Report only checks actually executed.
[README](README.md) provides runnable commands, source coverage and corrections;
[LICENSE.upstream](LICENSE.upstream) preserves the upstream notice.

Optional handoffs: **go-idiomatic** for language/error issues, **go-api-design**
for generic public contracts, **go-tdd** for test strategy. This bundle does not
require sibling installs or an upstream checkout.
