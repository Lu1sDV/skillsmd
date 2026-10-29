# Traversal and Connectivity

## 10. BFS and DFS

Define directed/undirected edges, vertex domain, isolated vertices, and whether the traversal covers one reachable component or the entire graph.

For BFS, enqueue the source, mark discovery when enqueuing, and use constant/amortized-time dequeue mechanics. Track parents or distance when the output needs paths. Use BFS's shortest-path guarantee only for unweighted/equal-weight edges.

For DFS, distinguish unvisited, active, and finished state when detecting directed cycles; a generic visited set alone does not encode the active recursion path. For undirected cycles, account for the parent edge and multigraph semantics.

Choose an explicit stack when depth may be large. For grid traversal, validate shape or declare a rectangular-grid precondition, define neighbor directions, and choose a separate visited structure when input mutation is forbidden.

For level order, capture the live queue boundary at the start of each level. Count O(V+E) work only after accounting for representation, visitation, and queue operations.

## 14. Topological sort

Define an edge as prerequisite -> dependent consistently. Initialize all vertices, including isolated ones, and compute indegrees with a deliberate duplicate-edge policy.

Process zero-indegree vertices using a proper FIFO queue or a heap if lexicographic order is required. Decrement indegrees once per represented edge. A result containing fewer vertices than the graph indicates a cycle.

Specify the result for an empty DAG separately from failure; an empty array used for both can be ambiguous for callers. If diagnosing cycles is required, return an explicit status or additional cycle information.

Use O(V+E) time with adjacency lists and appropriate queue operations; charge heap-based ordering separately.

## 15. Union-find

Maintain one parent root per component. Combine path compression with union by rank or size. Increment rank only when equally ranked roots merge, or update sizes under a consistent convention.

Validate vertex bounds before find/union. Decrement a component count only for a successful merge. Test self-unions, duplicate edges, already connected vertices, and isolated vertices.

Use union-find for connectivity under insertions; do not assume it solves directed reachability or arbitrary deletions.

For V vertices and E edge unions, state initialization plus union/find cost, conventionally O(V + E alpha(V)) under the standard amortized analysis, with O(V) storage.

## 16. Trie

Define the symbol unit and normalization before insertion/search. Mark word termination independently from child existence so a word can be a prefix of another word.

Distinguish full-word search from prefix existence. Decide whether the empty word may be stored. For deletion, prune only nodes that are neither needed by another word nor terminal themselves.

Use Map children for a general symbol alphabet; consider a fixed array only with an explicit bounded alphabet and memory tradeoff. Count operations in symbols traversed, plus the assumed child-lookup cost.

## Verification prompts

- Traverse a graph with two components, an isolated vertex, a self-loop, and converging paths.
- Resolve a DAG with multiple valid orders, then add a cycle and verify failure reporting.
- Merge the same edge twice and verify that component count changes once.
- Insert both a word and its longer extension; confirm exact search differs from prefix search.
- Traverse a long chain without relying on an unbounded call stack.

## Sources

- [StructWeave: BFS/DFS](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/04-interview-patterns.md#10-bfsdfs)
- [StructWeave: topological sort](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/04-interview-patterns.md#14-topological-sort)
- [StructWeave: union-find](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/04-interview-patterns.md#15-union-find)
- [StructWeave: trie](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/04-interview-patterns.md#16-trie)
