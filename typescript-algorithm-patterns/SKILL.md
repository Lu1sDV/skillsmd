---
name: typescript-algorithm-patterns
description: >
  Use when solving, implementing, explaining, debugging, or optimizing TypeScript algorithm
  problems and coding interview solutions involving sequences, searching, trees, graphs,
  connectivity, dynamic programming, backtracking, greedy choices, tries, heaps, or bit
  manipulation. Select patterns from valid preconditions, establish invariants, and verify
  complexity and edge cases.
---

# TypeScript Algorithm Patterns

## Define the problem

1. Write the input/output signature and define empty, not-found, invalid-input, and duplicate behavior.
2. Record bounds, sortedness, integer range, character representation, graph direction, and interval endpoint convention.
3. Establish whether inputs and nested elements may be mutated, whether indices refer to original ordering, and whether all results must be materialized.
4. Identify the required runtime and strict compiler settings; inspect any supplied node/heap/graph types.
5. State a simple correct baseline before choosing an optimization.

## Select a pattern from a valid precondition

| Pattern | Evidence that supports selection | Reference |
| --- | --- | --- |
| Two pointers | Sorted pair search, partitioning, or a valid two-ended invariant | Sequence |
| Sliding window | Contiguous range with maintainable state and justified expansion/shrinking | Sequence |
| Binary search | Sorted domain or monotone feasibility predicate | Sequence |
| Prefix sum | Repeated range sums or differences between prefix states | Sequence |
| Monotonic stack | Next/previous greater/smaller boundary | Sequence |
| Hash-map patterns | Complement, frequency, grouping, or membership lookup | Sequence |
| Two heaps | Streaming median or maintaining ordered lower/upper halves | Sequence |
| Merge intervals | Range union/conflict with defined endpoint semantics | Sequence |
| Cyclic sort | Integer-to-index mapping with checked bounds and progress | Sequence |
| BFS/DFS | Reachability, tree traversal, components, or unweighted shortest path | Traversal |
| Backtracking | Enumerating feasible choices with reversible state | Optimization |
| Dynamic programming | Repeated subproblems with a sufficient reusable state | Optimization |
| Greedy | A justified exchange, dominance, or stays-ahead argument | Optimization |
| Topological sort | Ordering dependencies in a directed graph | Traversal |
| Union-find | Incremental undirected connectivity or component merging | Traversal |
| Trie | Repeated prefix queries over a defined symbol sequence | Traversal |
| Bit manipulation | A bounded bit domain or deliberate bigint representation | Optimization |

Load only the relevant reference:

- [Sequence and search patterns](references/sequence-search.md): patterns 1–9 in the source.
- [Traversal and connectivity](references/traversal-connectivity.md): BFS/DFS, topological sort, union-find, and trie.
- [Optimization and enumeration](references/optimization-enumeration.md): backtracking, dynamic programming, greedy, and bit manipulation.

Do not infer a shrinking sum window from the word “subarray” when negatives invalidate the invariant. Do not infer greedy correctness merely because a local choice looks favorable.

## Derive the solution before coding

1. State the loop invariant, recurrence, or search-state meaning in concrete terms.
2. Define initialization, transition, answer extraction, and termination; prove that each transition preserves the required property.
3. State why discarded candidates cannot contain a better answer.
4. Separate correctness from performance assumptions, including expected hash-map cost.
5. Choose typed tuples, discriminated results, and explicit absent values where they clarify the contract.
6. Use `typescript-collections` for data-structure implementation details when needed.

## Implement without changing the contract

- Preserve input order or copy before sorting when original indices or non-mutation are required.
- Copy nested interval tuples when merging would otherwise mutate caller-owned data.
- Use a head-index queue or deque for BFS/topological traversal; mark discovery on enqueue when each vertex should enter once.
- Use iterative traversal when recursion depth can exceed the runtime's stack.
- Guard empty input and bounded indices; justify any non-null assertion through an actual invariant.
- Maintain one character model throughout string algorithms; do not mix code-point iteration with code-unit offsets.
- Check safe-integer limits for sums, products, and counts; restrict number bitwise operations to the intended 32-bit domain.
- Define empty target behavior before entering minimum-window loops, and empty LIS length before taking a maximum.
- Copy accepted backtracking paths and restore mutable state after exploring each choice.

## Verify correctness and complexity

1. Trace a normal case and the smallest boundary case through the invariant.
2. Exercise relevant empty/singleton, duplicate, zero, negative, sorted/reversed, disconnected, cyclic, and no-solution cases.
3. Compare optimized output against a simple oracle on bounded inputs when it can expose a concrete correctness risk.
4. Verify mutation promises independently from output correctness.
5. Count sorting, heap operations, string-key construction, array shifts/copies, and repeated scans.
6. State recursion depth, stored state, and output size separately; do not call exponential output O(n) total space.
7. Run the project's typecheck and relevant tests; use targeted regression cases for discovered defects.

## Deliver

Return the chosen pattern and its preconditions, the invariant or recurrence, an idiomatic TypeScript implementation, time and auxiliary/output-space bounds, and validation results. Explain alternative approaches only when their tradeoffs affect this problem.

For an interview explanation, show one concise trace and the reason the algorithm terminates. For a code review, rank concrete correctness and complexity issues and provide minimal fixes.

## Sources

- [StructWeave: all 17 interview patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/04-interview-patterns.md)
- [StructWeave: TypeScript data structures](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/02-data-structures.md)
- [ECMAScript numeric operations](https://tc39.es/ecma262/multipage/ecmascript-data-types-and-values.html#sec-numeric-types)
