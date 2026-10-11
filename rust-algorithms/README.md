# rust-algorithms

A self-contained Claude Code skill for choosing Rust collections and implementing
algorithmic solutions with explicit invariants, preconditions and complexity.
It preserves all 17 pattern families from StructWeave's Rust algorithm guide,
with complete standard-library implementations and executable boundary assertions.

## Install from this checkout

Run from the repository root:

```bash
mkdir -p ~/.claude/skills
cp -r rust-algorithms ~/.claude/skills/
```

Copy the entire directory, including `references/` and `LICENSE.upstream`. No
plugin marketplace manifest or external Rust dependencies are required by this
bundle. The optional handoff skills are not required for its examples to work.

## Usage prompts

- “Use rust-algorithms to choose a collection and prove this Rust window invariant.”
- “Review my two-sum, prefix-sum and median code for overflow and empty inputs.”
- “Implement Unicode-scalar LCS; make the indexing and complexity explicit.”
- “Show a Rust BFS, topological sort and union-find with distinct graph contracts.”
- “Compare backtracking, DP and greedy for this problem before writing the loop.”
- “Explain all 17 Rust algorithm pattern families with their preconditions.”

## Scope and reference index

Start with [SKILL.md](SKILL.md), which routes by task and summarizes all families.
Only load the relevant detailed reference for an individual problem.

| Reference | Coverage |
|---|---|
| [Collections and contracts](references/collections-and-contracts.md) | Vec/slices, HashMap/HashSet, String/str, VecDeque, BinaryHeap, BTreeMap/BTreeSet, LinkedList tradeoffs; tree/list/graph modeling, iterators, ordering and arithmetic pitfalls |
| [Sequence patterns](references/sequence-patterns.md) | 1 two pointers, 2 sliding window, 3 binary search, 4 prefix sum, 5 monotonic stack, 6 hash map patterns, 7 two heaps, 8 merge intervals, 9 cyclic sort |
| [Graph and index patterns](references/graph-and-index-patterns.md) | 10 BFS/DFS, 14 topological sort, 15 union-find, 16 trie |
| [Search and optimization](references/search-and-optimization.md) | 11 backtracking, 12 dynamic programming, 13 greedy, 17 bit manipulation |

Each family includes applicability, state/loop invariants, preconditions,
complexity, edge cases and at least one complete reusable Rust implementation.
Related variants include decision guidance rather than a second catalog of
near-identical templates. General Rust compiler/ownership help belongs to the
optional **rust-idiomatic** skill; test-driven change design to **rust-tdd**;
measured profiling/optimization to the existing **rust-performance** skill.

## Run the executable examples

The fences target **Rust 1.85+ with edition 2024** and the standard library only.
Select the project's actual MSRV/edition before copying code; these examples do
not use let chains. These are runnable checks, not a claim that they have passed
on any particular toolchain.

From this repository's root:

```bash
rustdoc --test --edition=2024 rust-algorithms/references/collections-and-contracts.md
rustdoc --test --edition=2024 rust-algorithms/references/sequence-patterns.md
rustdoc --test --edition=2024 rust-algorithms/references/graph-and-index-patterns.md
rustdoc --test --edition=2024 rust-algorithms/references/search-and-optimization.md
```

To check the installed standalone copy independently of the repository:

```bash
rustdoc --test --edition=2024 ~/.claude/skills/rust-algorithms/references/collections-and-contracts.md
rustdoc --test --edition=2024 ~/.claude/skills/rust-algorithms/references/sequence-patterns.md
rustdoc --test --edition=2024 ~/.claude/skills/rust-algorithms/references/graph-and-index-patterns.md
rustdoc --test --edition=2024 ~/.claude/skills/rust-algorithms/references/search-and-optimization.md
```

Assertions cover such cases as empty/singleton sequences, integer extremes,
invalid windows and domains, repeated values, UTF-8 boundaries, empty targets,
empty medians, graph cycles and invalid IDs, Unicode prefixes, DP count overflow,
and invalid bit shifts. Application-specific tests still need to exercise its
input boundary, output ordering, allocation budget and error policy.

## Consolidation and adaptation decisions

- Chapters 03 and 04 become one collection/algorithm bundle: selection guidance
  stays in the entrypoint and deeper material is grouped into four cohesive
  references. All 17 families remain explicit; the upstream quick-reference
  omission of intervals/cyclic sort is not carried forward.
- Chapter 13 contributes relevant capacity-vs-length, clone/move, allocation,
  unspecified map order, float ordering and integer-overflow traps. General
  compiler, concurrency, macro and unsafe questions are intentionally owned by
  the other suite skills, not duplicated here.
- Original incomplete templates are replaced with isolated executable examples.
  Variants explain their additional obligations: rotated-search duplicates,
  positive combination-sum candidates, bounded cyclic-sort values, weighted
  versus unweighted traversal, interval endpoint policy and knapsack loop order.
- Empty-input underflow and empty minimum-window-target loops are corrected.
  Pair arithmetic is widened before operations; aggregate/count overflow is
  checked where a bound is not guaranteed. Heap medians return `None` when empty.
- Text algorithms distinguish byte offsets, Unicode scalars and grapheme clusters.
  LCS uses scalar-sized state; minimum covering windows borrow valid UTF-8 byte
  ranges and explicitly minimize byte length. No implicit Unicode normalization
  or case-folding claim is made.
- Heap ordering/equality agree through standard tuple/Reverse keys. LinkedList is
  not recommended for arbitrary O(1) middle insertion. Graph representation
  distinguishes dense vertex IDs from dense edge sets. Traversal/trie examples
  avoid input-depth recursion where a simple explicit stack/arena suffices.
- No unsupported “percentage of interview problems solved”, guaranteed fastest
  collection, or compilation-implies-correctness claim is retained.

## Sources and attribution

Derived through original synthesis and corrected examples from StructWeave at
Rust-content revision `49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`:

- [03-data-structures.md](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/03-data-structures.md)
- [04-interview-patterns.md](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/04-interview-patterns.md)
- [13-interview-trap-questions.md](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md) — relevant collection, string/ownership, numeric and ordering portions.

Upstream MIT attribution: [LICENSE.upstream](LICENSE.upstream).
First-party semantic references used in the adaptation:

- [Standard collections: selection and complexity](https://doc.rust-lang.org/std/collections/index.html)
- [BinaryHeap guarantees and ordering](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html)
- [Ord consistency requirements](https://doc.rust-lang.org/std/cmp/trait.Ord.html)
- [str: UTF-8, byte lengths and scalar iteration](https://doc.rust-lang.org/std/primitive.str.html)
- [Rust Reference: integer overflow](https://doc.rust-lang.org/reference/expressions/operator-expr.html#overflow)
