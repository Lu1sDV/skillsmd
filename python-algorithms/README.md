# python-algorithms

A self-contained Python collection/algorithm skill preserving **all 17 families
listed in StructWeave's Python chapter 04**, with focused string-search and
selection extensions. It combines collection choice, invariants, explicit input
contracts, complexity, mutation/copy behavior and bounded runnable examples.

Baseline: **CPython 3.15**, latest stable patch **3.15.2**, verified **2026-11-03**
against the [Python release page](https://www.python.org/downloads/release/python-3152/).
Treat older consuming-project support as a compatibility constraint rather than
silently changing its support policy. Recheck the stable release at maintenance.

## Install from this checkout

Run from the repository root:

```sh
mkdir -p ~/.claude/skills
cp -r python-algorithms ~/.claude/skills/
```

Copy the entire bundle, including `references/` and `LICENSE.upstream`. Before
replacing an existing installed copy, preserve its local changes elsewhere; this
command is not a merge strategy. No plugin manifest, sibling skill, external
package or source checkout is required at skill-use time.

## Usage prompts

- “Use python-algorithms to choose a collection and explain its real costs.”
- “Review this signed-sum window and duplicate handling before changing it.”
- “Implement cycle-safe BFS, dependency ordering and union-find with boundary checks.”
- “Choose backtracking, DP or greedy and justify the invariant for this problem.”
- “Review my median heaps, cyclic placement and integer bit-width assumptions.”

## Reference index and source coverage

Start with the concise routing/workflow in [SKILL.md](SKILL.md); the original 17
families, targeted extensions and executable examples live in these references.

| Reference | Local coverage |
|---|---|
| [Collections and contracts](references/collections-and-contracts.md) | Chapter 02 lists/sorting/slices, tuples/namedtuple, dict/defaultdict/Counter/OrderedDict, sets/frozenset, deque, heapq, strings, linked nodes, trees, graph representations and complexity; algorithm-specific chapter 05 helpers |
| [Sequence patterns](references/sequence-patterns.md) | 1 two pointers, 2 sliding window, 3 binary search, 4 prefix sum, 5 monotonic stack, 6 hash-map patterns, 7 two heaps, 8 merge intervals, 9 cyclic sort |
| [Graph and index patterns](references/graph-and-index-patterns.md) | 10 BFS/DFS and 0–1 BFS, 14 topological sort, 15 union-find, 16 trie; grid/tree/clone, connectivity and dynamic range/rank guidance |
| [Search and optimization](references/search-and-optimization.md) | 11 backtracking, 12 dynamic programming, 13 greedy, 17 bit manipulation; cache budgets, bitset reachability, interval order, knapsack, subsequences and finite-width policy |
| [String search and selection](references/string-search-and-selection.md) | 18 string-search selection and correctness obligations, 19 order statistics and bounded streaming top-k |

Families have concrete implementations and boundary assertions; related source
examples receive local adaptation guidance rather than a duplicate template
catalogue. This is an algorithm guide, not an application framework. Optional
**python-stdlib**, **python-idiomatic**, **python-api-design** and **python-tdd**
handoffs cover general utilities, language traps, public contracts and testing
workflow respectively; none is a runtime dependency.

## Run the executable examples

From this bundle directory, using **Python 3.15** and only the standard library:

```sh
python3 -m doctest references/*.md
```

The same command works in a copied standalone bundle. `pycon` examples use finite
inputs and deterministic assertions; the prefix-sum and greedy examples compare
against bounded brute-force oracles. No network, third-party tools or persistent
writes are needed. Report the runtime and actual results when running them.
Assertions are example tests, never production trust-boundary validation.

Runtime limits: recursive backtracking/memoization examples require bounded
problem sizes and remain subject to interpreter recursion limits. Collection
costs describe conventional CPython implementations with operand-size caveats,
not cross-interpreter language guarantees. The running-median example uses public
max-heap APIs available on the 3.15 baseline (introduced in 3.14); adapt only when
an older declared consumer runtime explicitly requires it.

## Consolidation and correction decisions

- **One algorithm bundle, five practical references.** Chapter 02 container
  contracts precede the actual chapter 04 families; relevant chapter 05 APIs
  are integrated where used. General stdlib APIs intentionally belong to
  python-stdlib rather than being duplicated here.
- **Keep the entrypoint a router.** Pattern families remain named there, while
  their full complexity catalogue stays with the implementations and container
  contracts in the linked references. Existing families remain available.
- **Explicit preconditions instead of broad pattern slogans.** Signed sum
  windows, distinct-index pair search, duplicate/Unicode anagram keys, positive
  combination-sum candidates, strict-LIS duplicates, interval endpoints,
  cyclic-placement domains and jump-game failure cases are specified locally.
- **Mutation is visible.** Cyclic placement validates before modifying input;
  interval merging returns independent tuples rather than aliasing/modifying
  an original interval. Three-sum sorting and CPython sorting workspace are
  included in space costs. Prefixes are snapshots and graph reads preserve input.
- **Do not import broken templates.** Sliding-window median needs logical heap
  sizes, pruning and a physical-storage policy; the source's use of physical
  lengths is not a correct lazy-deletion invariant. The working streaming
  median is supplied instead, with a clear bounded-space sorted-list choice
  and requirements for adapting to deletion. Its integer median is exact via
  Fraction, avoiding float loss/overflow; no empty-heap indexing occurs.
- **Correct algorithm boundaries.** BFS shortest paths are unit/equal-weight;
  Dijkstra needs nonnegative weights. Global DFS visitation does not enumerate
  all paths. Cycle errors are distinct from an empty topological order, graph
  IDs reject negative indexing, and node equality uses identity for cycles.
- **Correct cost and stdlib claims.** Dict popitem is LIFO; tuple hashability
  depends on contents; Counter updates can preserve negative counts; anagram
  Counter comparisons are not always O(1). Sorted-string grouping includes
  O(L log L) keys, recursive remaining-list slicing can take O(n²) live space,
  union-find counting includes E edges, and lazy heaps need not stay O(k).
- **Python integer/text semantics, not machine assumptions.** No fixed-word
  overflow claims; bit costs scale with representation and negative shifts/
  signed right shifts are explicit. Text algorithms compare code points, not
  grapheme clusters. No unsupported “90% of problems”, fastest-container or
  measured-performance claims are retained.
- **Repair consumer-visible boundaries.** Zero-stair count is one; empty LIS,
  task schedules, medians, trees and subsets have deliberate semantics. Invalid
  windows do not become a misleading zero result; malformed intervals/domains
  raise errors. Cached functions receive hashable state, not a mutable grid.

## Community curation reviewed 2026-11-03

Use community material to identify gaps; the runtime contract, algorithm invariant
and bounded oracle decide what enters the bundle. These are selection decisions,
not a claim that every candidate in the supplied catalogue was audited:

| Retrieved candidate | Retained / changed | Excluded and why |
|---|---|---|
| [CodeHalwell dynamic programming](https://github.com/CodeHalwell/fable-skills/blob/main/skills/dynamic-programming/SKILL.md) | Default LRU capacity, state/transition budget, interval dependency order | Fixed Python size/throughput ceilings, recursion speed ratios and mandatory recursion-first dogma lack portable evidence |
| [CodeHalwell structure selection](https://github.com/CodeHalwell/fable-skills/blob/main/skills/data-structures-selection/SKILL.md) | Operation-driven choice, bitsets, key information loss, range/rank distinctions | Universal byte costs and speedups, blanket sorted-array claims, approximate-result tools outside this bundle's concrete gaps |
| [sequenzia string algorithms](https://github.com/sequenzia/agent-alchemy/blob/main/claude/cs-tools/skills/string-algorithms/SKILL.md) | Compact task-to-technique map, delimiter/collision/radius validation obligations | Templates not imported; empty-input, delimiter and mirror-boundary cases need independent proof, and fixed hash-error assurances need a probability model |

The additional 0–1 BFS and top-k examples are locally written from explicit
invariants. Retain bounded oracle checks; do not assign an upstream commit pin to
a mutable URL or to a file-content hash. Keep the existing StructWeave source
notice and license below.

## Sources and attribution

Original synthesis/adaptation from StructWeave pinned at Python-content commit
`0b88a786ef09681717a805d9f7e0b195ab610f6c`:

- [02-data-structures.md](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/02-data-structures.md) — all container/custom-structure and complexity sections.
- [04-interview-patterns.md](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/04-interview-patterns.md) — all 17 listed families, with local variant guidance.
- [05-standard-library.md](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/05-standard-library.md) — algorithm-specific collections, itertools, functools cache/comparison, bisect, heapq, math, operator keys and copying.

Upstream MIT text is preserved in [LICENSE.upstream](LICENSE.upstream).
First-party semantics used for corrections:
[built-in types](https://docs.python.org/3.15/library/stdtypes.html),
[collections](https://docs.python.org/3.15/library/collections.html),
[heapq, including 3.14 max-heaps](https://docs.python.org/3.15/library/heapq.html),
[bisect](https://docs.python.org/3.15/library/bisect.html),
[itertools](https://docs.python.org/3.15/library/itertools.html),
[functools](https://docs.python.org/3.15/library/functools.html),
[sorting](https://docs.python.org/3.15/howto/sorting.html), and
[integer bit operations](https://docs.python.org/3.15/library/stdtypes.html#bitwise-operations-on-integer-types).
