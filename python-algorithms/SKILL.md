---
name: python-algorithms
description: >
  Use when choosing Python collections or implementing and reviewing two pointers,
  sliding windows, binary search, prefix sums, monotonic stacks, hash-map patterns,
  two heaps, merge intervals, cyclic sort, BFS/DFS, backtracking, dynamic programming,
  greedy algorithms, topological sort, union-find, tries, or bit manipulation.
  Covers invariants, complexity, mutation, duplicates, cycles, and boundary cases.
---

# Python Algorithms

## Route by invariant

| Task / pattern families | Load |
|---|---|
| Container choice, lists/trees/graphs, copying, ordering, real costs | [Collections and contracts](references/collections-and-contracts.md) |
| 1 two pointers; 2 sliding window; 3 binary search; 4 prefix sum; 5 monotonic stack; 6 hash maps; 7 two heaps; 8 merge intervals; 9 cyclic sort | [Sequence patterns](references/sequence-patterns.md) |
| 10 BFS/DFS; 14 topological sort; 15 union-find; 16 trie | [Graph and index patterns](references/graph-and-index-patterns.md) |
| 11 backtracking; 12 dynamic programming; 13 greedy; 17 bit manipulation | [Search and optimization](references/search-and-optimization.md) |

Load only the needed guide; all 17 families, implementations and cost caveats
ship locally. Prefer built-in containers and stdlib helpers over custom structures
unless link identity or another problem-specific operation requires them.

## Workflow

1. Specify the input domain/size, sortedness, duplicates, interval endpoints,
   graph direction, text unit, output order, failure/empty outcomes and mutation
   policy. Ask the owner before resolving ambiguous destructive behavior.
2. Write the invariant and termination measure before implementation. Explain why
   a discarded candidate cannot win, how cycles/duplicates terminate, or why DP
   dependencies are acyclic. Greedy choices require an exchange/stays-ahead proof.
3. Budget validation, sorting, slicing, key construction, integer widths, recursion,
   adjacency construction and output. Hash-table bounds are expected, not worst-case;
   unit-cost arithmetic assumptions must be stated.
4. Keep mutation explicit: sorting, heapifying, cyclic placement and link reversal
   change input. Validate domains before destructive indexing; shallow copies
   retain children. Track pending, complete and blocked items for multi-file work.
5. Check relevant empty/singleton, all-equal, signed, duplicate, Unicode, no-solution,
   cycle/disconnected and invalid-domain cases. Compare optimized results with a
   bounded simple oracle where practical; preserve the consumer's Python versions.

## High-risk gotchas

- Threshold-shrinking sum windows need nonnegative values; signed exact sums use
  prefix counts. Binary search needs a monotone predicate, not just a halving loop.
- `bisect` finds boundaries, not equality; insertion still shifts O(n) items.
  Slices and sorting workspace count toward space/time claims.
- Heap ties need `(priority, sequence_number, payload)` for nonorderable payloads.
  Sliding-window heaps need logical live sizes, stale-entry pruning and a physical
  storage policy; the streaming-median example alone does not support deletion.
- BFS shortest paths require equal-weight edges; Dijkstra requires nonnegative
  weights. Global DFS visitation is not simple-path enumeration. Use iterative
  traversal for input-controlled depth; memoization does not remove recursion depth.
- Cyclic placement requires a bounded index domain and duplicate-aware progress.
  It does not sort arbitrary integers or every duplicate-containing multiset.
- Python integers are arbitrary precision; bit-operation cost grows with width.
  Negative right shifts retain sign: mask to a specified width or reject negatives.
  Text algorithms operate on code points unless normalization/graphemes are specified.
- Use exceptions for invalid external input, not assertions. No-answer sentinels
  must not collide with valid results. Do not publish a partial dependency order
  as complete when a cycle remains.

## Completion and evidence

Report preconditions, mutation/copy behavior, invariant/termination, output/failure
semantics and full time/space costs. Include executed checks and remaining gaps;
do not silently skip required checks or present proposed commands as passing.
Examples target Python 3.11+, stdlib only; commands are in [README](README.md#run-the-executable-examples).

Optional installed-skill handoffs: **python-idiomatic** for language/error/import
issues, **python-stdlib** for general library APIs, **python-api-design** for public
contracts/typing and **python-tdd** for tests. None is required.

See [README](README.md#sources-and-attribution) for pinned sources, consolidation
decisions and installation; [LICENSE.upstream](LICENSE.upstream) for attribution.
