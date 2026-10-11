---
name: rust-algorithms
description: >
  Use when choosing Rust collections or implementing and reviewing algorithmic
  solutions: two pointers, sliding windows, binary search, prefix sums, monotonic
  stacks, hash maps, streaming medians, intervals, cyclic sort, BFS/DFS,
  backtracking, dynamic programming, greedy algorithms, topological sort,
  union-find, tries, or bit manipulation. Covers invariants, complexity,
  empty inputs, overflow, and UTF-8 correctness rather than general Rust syntax.
---

# Rust Algorithms

## Quick reference: load only the relevant guide

| Task | Reference |
|---|---|
| Choose collections, model graphs/trees, handle strings or ordering | [Collections and contracts](references/collections-and-contracts.md) |
| Scan/search sequences; aggregate ranges; maintain ordered partitions | [Sequence patterns 1–9](references/sequence-patterns.md) |
| Traverse graphs; order dependencies; track connectivity; match prefixes | [Graph and index patterns 10, 14–16](references/graph-and-index-patterns.md) |
| Enumerate choices; optimize recurrences; prove greedy choices; use bits | [Search and optimization patterns 11–13, 17](references/search-and-optimization.md) |

## Pattern selection

Costs assume constant-time element comparison/arithmetic; hashing strings also
costs their length. Auxiliary space excludes returned output unless stated.
Expected hash-table bounds are not deterministic worst-case guarantees.

| # | Family | Signal and required invariant | Typical time / auxiliary space |
|---|---|---|---|
| 1 | Two pointers | Sorted pair search; eliminated region cannot contain answer | O(n) / O(1) |
| 2 | Sliding window | Contiguous region; incremental state and monotone shrinking | O(n) / O(distinct symbols) |
| 3 | Binary search | Sorted slice or a proven monotone predicate | O(log n) predicate calls / O(1) |
| 4 | Prefix sum | Repeated static range sums; prefix represents `[0, i)` | O(n) build, O(1) query / O(n) |
| 5 | Monotonic stack | Next greater/smaller; unresolved indices ordered by value | O(n) / O(n) |
| 6 | Hash map | Complements, counts, grouping; key captures exact equivalence | Expected O(n), plus key work / O(n) |
| 7 | Two heaps | Streaming median; lower half ≤ upper half, sizes differ ≤ 1 | O(log n) amortized insert, O(1) median / O(n) |
| 8 | Merge intervals | Explicit endpoint semantics; sorted processed union | O(n log n) / O(1) beyond output with unstable sort |
| 9 | Cyclic sort | Values map into bounded index domain; swaps fix a position | O(n) / O(1) |
| 10 | BFS/DFS | Valid graph IDs; each vertex discovered once | O(V + E) / O(V) |
| 11 | Backtracking | Finite choices; undo each mutation; pruning is sound | Subsets O(n·2^n), permutations O(n·n!) when materialized / O(n) |
| 12 | Dynamic programming | State summarizes history; acyclic dependency recurrence | States × transitions / stored states |
| 13 | Greedy | Exchange or stays-ahead proof; local choice preserves optimum | Problem-specific; activity selection O(n log n) / O(1) beyond output |
| 14 | Topological sort | Directed graph; indegree counts remaining incoming edges | O(V + E) / O(V) |
| 15 | Union-find | Parent forest with valid IDs; union by size/rank + compression | O(α(V)) amortized per operation / O(V) |
| 16 | Trie | One edge per chosen symbol; terminal flag separate from prefix | Expected O(L) per key / O(total stored symbols) |
| 17 | Bit manipulation | Fixed-width unsigned domain; checked shift positions | O(1) per word operation / O(1) |

## Workflow

1. **Write the contract before the loop.** Define input bounds, duplicate policy,
   sortedness, interval endpoints, graph direction, character unit, and whether
   mutation is permitted. Pick the project's edition and MSRV, not the newest
   syntax by default. Examples here target edition 2024, Rust 1.85+; no let chains.
2. **Specify the empty case and failure representation.** Prefer `Option` for no
   answer and `Result` for malformed data. Do not overload `-1` when it can be a
   valid value. Assertions in these guides enforce programmer preconditions;
   validate external input with an error at the application boundary.
3. **Try the standard library first.** `binary_search`, `partition_point`,
   `dedup`, `retain`, sorting, `Reverse`, and `entry` replace many custom loops.
   Use `&[T]`/`&str` for read-only inputs; mutate `&mut [T]` when length is fixed.
4. **State the invariant and termination argument.** Name what the indices,
   stack, queue, heap partition, or DP cells mean. Show why every discarded
   candidate cannot be needed. “Looks like sliding window” is not a proof.
5. **Budget arithmetic and storage.** Widen *before* arithmetic; use checked
   operations if a bound is not established. Include output size, recursion
   depth, hash key construction, validation and sorting in the complexity.
6. **Implement a complete path.** Preserve ordering contracts and input
   ownership. Allocate only the state the algorithm requires. Avoid cloning an
   entire graph/string/vector merely to make borrowing easier.
7. **Exercise boundaries and compare with a simple oracle.** Check empty and
   singleton inputs, all equal values, extremes, impossible answers, duplicate
   keys, non-ASCII text, cycles and disconnected graphs as applicable. For small
   inputs, compare the optimized algorithm with brute force.

## Non-negotiable pitfalls

- `len() - 1` underflows on empty input. Prefer half-open `[left, right)` ranges
  or guard the empty case. `saturating_sub` is not a substitute for a valid
  indexing invariant.
- Integer overflow is affected by compiler/profile settings. Do not make
  correctness depend on debug panic versus release wrapping. Negating a signed
  minimum, subtracting complements, products, prefix totals, DP counts, and
  shifts need explicit policies.
- `str::len()` counts bytes; `chars()` counts Unicode scalar values, not grapheme
  clusters. Never dimension a `Vec<char>` algorithm with byte length. Byte
  indexing is appropriate only for a byte-domain problem or validated ASCII.
- Sliding a sum window by shrinking when the sum is too large generally needs
  nonnegative values. Signed values need a different proof, often prefix sums
  plus a map. Distinct-symbol windows do not have that restriction.
- `HashMap` order is unspecified, not undefined behavior. Sort final output or
  use `BTreeMap` when deterministic order is part of the contract.
- `BinaryHeap` is a max-heap, and iteration is not sorted. Use `Reverse` for a
  min-heap. `Ord`, `PartialOrd`, and equality must agree, including tie handling.
- BFS gives shortest paths for **unweighted/equal-weight** edges, not arbitrary
  weights. DFS visits a reachable component, not all paths or all components.
- Exponential output cannot become linear by using iterators. Recursion also
  consumes stack; use an explicit stack for input-controlled deep traversal.

## Completion criteria

- Every precondition is documented and either guaranteed by the caller or
  checked at a trust boundary; checks are included in stated total costs.
- The loop/state invariant, termination measure, result semantics, time bound,
  auxiliary space and output size are explicit.
- Empty inputs, Unicode semantics, integer extremes, invalid domains, duplicates
  and no-answer cases are deliberate, not accidents of a sample input.
- Runnable assertions cover the relevant boundary; verification results are
  reported only after actually executing the command.

## Handoffs

If installed, use **rust-idiomatic** for borrowing/compiler issues and production
string/I/O semantics; **rust-tdd** for a red-green-refactor workflow and regression
properties; **rust-performance** for measured allocation/layout/profiling work.
Algorithm selection belongs here; benchmark claims require measurement.

## Sources

Adapted and corrected from StructWeave's pinned [data structures](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/03-data-structures.md),
[17 patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/04-interview-patterns.md),
and relevant [interview traps](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md).
First-party semantics and adaptation notes are linked in the references and
[README](README.md); upstream attribution is in [LICENSE.upstream](LICENSE.upstream).
