# Go Algorithms

A self-contained skill for collection choice and invariant-driven Go algorithms.
All references and stdlib-only executable examples are local; using the skill
does not require an upstream checkout or another skill installation.

## Install

From this repository, first check whether `~/.claude/skills/go-algorithms` already
exists. Preserve an existing installation by choosing another destination or
backing it up; the copy command merges/overwrites an existing directory.

```bash
mkdir -p ~/.claude/skills
cp -r go-algorithms ~/.claude/skills/
```

Example prompts:

- “Choose a queue for a bounded Go BFS; explain real dequeue and retained-memory costs.”
- “Review this minimum-window function for empty targets, duplicate runes and Unicode semantics.”
- “Merge closed intervals without changing caller data, including MinInt/MaxInt endpoints.”
- “Prove this cyclic placement loop terminates and report checked-boundary space costs.”
- “Explain all fourteen algorithm families actually present in the pinned Go guides.”

## Reference index

| Reference | Coverage |
|---|---|
| [Collections and contracts](references/collections-and-contracts.md) | Slices, matrices, maps, sets, stacks, queues, heaps, lists, trees, graphs, generic helpers, version gates, weak caches and map implementation caveats |
| [Sequence patterns](references/sequence-patterns.md) | Families 1–6: two pointers, sliding windows, binary search, prefix sums, monotonic stacks, hash maps |
| [Ordering and placement](references/ordering-and-placement.md) | Families 7–9: two heaps, merge intervals, cyclic sort |
| [Traversal and optimization](references/traversal-and-optimization.md) | Families 10–14: BFS/DFS, backtracking, DP, greedy, topological sort |

## Run the executable examples

Minimum for this sample module: **Go 1.25**. The module uses stdlib only, declares
`go 1.25.0`, and has no external dependencies. General collection APIs may be
older: generics 1.18; slices/maps/cmp and min/max/clear 1.21; cmp.Or 1.22;
iterator APIs 1.23; aliases/weak 1.24. These version distinctions are documented
in the collection reference; samples do not require weak references or aliases.
Do not assume certification on older Go releases from these API introduction dates.

From this bundle's `examples/` directory (including an isolated copied install):

```bash
go test ./...
go run ./cmd/demo
```

Optional formatting/static checks for the integrator, from the same directory:

```bash
gofmt -w algorithms.go median.go examples_test.go cmd/demo/main.go
go vet ./...
```

Demo output (observed during verification):

```text
window: BANC
merged: [{1 8}]
missing: 2
histogram: 10
median central values: 3 5 true
dependency order: [0 1 2 3]
```

[Example functions and named tests](examples/examples_test.go) cover empty target,
empty input, multiplicity, earliest ties, Unicode/invalid UTF-8, normalization
non-equivalence, interval ownership and overflow-safe extreme comparison, duplicate
and invalid cyclic placement domains, histogram spare-capacity preservation and
area overflow, empty/extreme streaming medians, and full vs cyclic/invalid graph
orders with isolated vertices and duplicate edges. A bounded independent brute
window oracle compares all 121 source strings of length <=4 against all 13 target
strings of length <=2 over `{a,b,猫}` (1,573 combinations).

The median API returns exact central integer values rather than a potentially
inexact float mean. Examples are instructional, in-memory and single-threaded;
they are not benchmarks or a general algorithms framework. Reference-only recipes
are not all separately executable regressions. Verified on 2026-10-29 with Go
1.26.10 linux/amd64 in an isolated copy: race-enabled tests, `go vet`, and the
demo passed. Vet first identified unkeyed external Interval literals in the demo;
named fields corrected them and the affected checks passed afterward.

## Pinned source coverage

Adapted from StructWeave-Algorithms commit
`e2a796e212d431c906c85957ea3c203ce0e2218f` (MIT). Source links are attribution,
not runtime prerequisites. The two primary chapters were read in full:

| Primary source and exact extent | Local coverage |
|---|---|
| [02-data-structures.md, lines 1–1866](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/02-data-structures.md) | All ten listed sections: slices (including 2D, sorting, copies and nil/empty); maps (frequency, complement, dedup, grouping, memoization, composite keys); stacks (parentheses/next greater); queues (slice/list, BFS, level order); heaps (interface, array mapping via heap contract, top-k and costs); linked lists (nodes, traverse/length/insert/delete, dummy head, middle, cycle, reversal); trees (nodes, three traversal orders, depth, BST bounds, LCA); graphs (direction, weights, list/matrix, recursive/iterative DFS and BFS); sets (membership, union/intersection); generic helpers (maps/slices/cmp, iterators, stack/set, aliases, weak cache, Swiss tables). Collections reference and traversal/ordering guides consolidate these topics. |
| [04-interview-patterns.md, lines 1–1218](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/04-interview-patterns.md) | All **14 actual** families: 1 two pointers (sorted two-sum/dedup/water); 2 windows (fixed, longest unique, minimum cover); 3 binary search (boundaries/rotation); 4 prefix sums (range/count exact sums); 5 monotonic stack (next greater/temperatures/histogram); 6 hashing (two-sum/top-k frequency/anagrams); 7 two heaps (median); 8 intervals; 9 cyclic missing/duplicate; 10 BFS/DFS/islands; 11 subsets/permutations; 12 1D/2D DP, stairs/LCS; 13 jump game/task scheduling; 14 topological sort. Generic utility appendix is consolidated into stdlib/local loops, not duplicated as a helper library. |
| [06-generics.md, supplemental portions](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/06-generics.md) | Consulted lines 1–120, 378–513 (stack/queue/set), 722–832 (slices/maps/cmp), 888–1078 (binary search, min-heap, LRU). Algorithm-related advice is incorporated in collections/search/heap guidance; no claim to cover this entire generic API chapter. |

## Consolidation and correction decisions

1. **Count actual content, not the slogan.** Chapter 04 line 3 advertises “17
   patterns”; its TOC and implemented family headings contain **14**. Preserve
   those fourteen without inventing union-find/trie/bit families to fill the gap.
2. **Prefer stdlib and direct slices/maps.** Collapse repeated Min/Max/Contains/
   Reverse, generic stack/set and hand-rolled heap recipes into built-ins,
   `slices`, `maps`, `cmp`, and `container/heap`. Keep list/tree invariants and
   optional LRU/weak-cache caveats, not generic framework scaffolding.
3. **Correct complexity claims.** Slice front reslicing is O(1), not O(n) shifting;
   no arbitrary list-switch threshold. BST operations are O(height), not always
   O(log n). Map costs are expected and key-dependent; remove the unsupported
   universal Swiss-table “60% faster” promise. Output costs make subsets
   O(n*2^n), permutations O(n*n!); DFS traversal does not enumerate all paths in
   O(V+E). Copy/validation/frontier retention count toward space.
4. **Make ordering and ownership real.** Replace subtraction comparators; ascending
   binary search cannot follow descending sort. Explain shallow slice/map clones,
   nested interval mutation, retained references and histogram sentinel append
   overwriting alias-visible spare capacity. Runnable merge/histogram preserve input.
5. **Correct domain failures rather than hide them.** Empty minimum-window target
   returns immediately; malformed UTF-8 is rejected for rune semantics. Check
   fixed-window k, top-k bounds, cyclic ranges/duplicates, invalid graph IDs and
   cycles. The source missing-number loop can panic on negatives or fail to
   terminate on duplicates. Empty scheduler returns zero instead of counting
   26 tied zero frequencies. State rotated-search distinctness and grid shape.
6. **Specify mathematical contracts.** Use rune rather than byte character claims;
   no implicit normalization/grapheme support. Empty stairs counts one empty
   sequence; reject negative n and guard recurrence overflow. Median central
   integer pairs avoid both overflow and float precision loss; other arithmetic
   requires bounds/checks. LCA assumes both targets exist or must verify presence.
7. **Do not promise versions together.** cmp.Or is 1.22, iterator APIs 1.23, aliases
   and weak 1.24; generic helpers are not all 1.21 APIs. Shrinking slices helpers
   clear obsolete tails in Go 1.22+, unlike older behavior.

The complete upstream notice is preserved in [LICENSE.upstream](LICENSE.upstream).
