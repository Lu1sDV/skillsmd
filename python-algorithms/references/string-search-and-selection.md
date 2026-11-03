# String search and selection 18–19

## Contents

- [18. String search](#18-string-search)
- [19. Selection and order statistics](#19-selection-and-order-statistics)
- [Streaming top-k](#streaming-top-k)

Use these techniques only when their output contract is needed. For ordinary
Python text and ordering work, start with built-in operations and measure before
replacing them with a Python implementation of a textbook algorithm.

## 18. String search

Specify `str` code points versus bytes, normalization/case policy, empty-pattern
behavior, overlapping matches, and required output positions. Normalization and
case-folding can change length, so transformed offsets need not index the original
text. No arbitrary character is a safe delimiter for unrestricted input.

| Required result | Starting technique | Contract / reason to go beyond built-ins |
|---|---|---|
| Membership or first literal occurrence | `pattern in text`, `str.find` | Use `find` only when the position is needed; do not promise an undocumented complexity across interpreters |
| All overlapping occurrences or matching across streamed chunks | KMP / prefix function | Retain matched-prefix state across chunks; after a match, resume from the proper border instead of resetting blindly |
| Prefix match lengths / borders / periods | Z-function or prefix function | Define `z[0]` convention and empty input; use an out-of-domain token if combining pattern and text |
| Window fingerprints / candidate substring equality | Rolling hash, then exact verification | Collisions remain possible, including with multiple hashes; equality is not established by the fingerprint alone |
| Palindrome radius at every center | Manacher when linear work is needed | Define odd/even center and radius conventions; do not mix boundary formulas from different variants |
| One of many dictionary patterns | Established Aho–Corasick implementation | Budget automaton construction, alphabet representation and number of emitted matches |

KMP processes text and pattern with O(n+m) comparisons under constant-cost symbol
equality; retained matcher state is O(m), plus output. Its border transition
preserves the longest viable matched prefix after a mismatch. See the
[original KMP paper](https://doi.org/10.1137/0206024) and
[machine-checked formulation](https://isa-afp.org/entries/KnuthMorrisPratt.html).

Treat the other rows as selection guidance, not a supplied implementation.
For Manacher, an explicit-center representation mirrors index `i` about `c` at
`2*c-i`; an even-center or half-open-boundary implementation needs its own
derived index. Clip reused radii to the known right boundary before expansion.
For a whole-string repetition of period `p`, require both prefix agreement and
`len(text) % p == 0`; a truncated final period is a different contract.

Before adopting custom code, compare with bounded brute-force substring/radius
oracles. Include empty input, all-equal text, odd/even palindromes, overlap,
pattern-longer-than-text, delimiter characters, non-ASCII symbols and chunk
boundaries. For rolling hashes, force collisions with a small test modulus to
prove the exact-verification path. Do not copy a large algorithm catalogue to
avoid this focused validation.

Python semantics: [string methods](https://docs.python.org/3.15/library/stdtypes.html#string-methods).

## 19. Selection and order statistics

Specify zero- versus one-based rank, duplicates versus distinct values, stable
tie handling, NaN policy, mutation and whether an ordered result is required.

| Output / access pattern | Candidate | Cost or limitation |
|---|---|---|
| One extremum | `min` / `max` | One pass; define empty-input result |
| Small k best elements | `heapq.nsmallest` / `nlargest` | Bounded heap is useful when k is small; output includes duplicates |
| Full ordering or k close to n | `sorted` | Stable ordered result; O(n log n) comparisons and O(n) storage |
| One rank, mutable random-access array | Quickselect when justified | Expected O(n) with suitable randomization; adversarial partitioning can be O(n²) |
| Strict worst-case selection requirement | Verified deterministic selection or bounded fallback | A median-of-medians implementation needs a proved pivot/range invariant; constants and complexity matter |
| Existing numerical array | Its documented `partition` / `argpartition` | Verify copies, axis, tie and NaN semantics; partitioned output is not sorted |

If implementing quickselect, ensure a strict partition progress measure and use
three-way partitioning for many equal values. Copy first unless mutation is part
of the API. A depth/work limit with sorting fallback bounds worst-case behavior
by sorting's bound; it does **not** turn the algorithm into worst-case linear
selection. Prefer a simpler stdlib solution when its measured cost is acceptable.
[heapq selection guidance](https://docs.python.org/3.15/library/heapq.html#heapq.nlargest)

## Streaming top-k

Maintain the largest k items in a **min-heap**: the root is the worst retained
item. Replace it only when a new value is larger. This integer example consumes
a finite stream once, preserves duplicates, returns sorted output, and returns
all available values when the input has fewer than k items.

```pycon
>>> import heapq
>>> def largest_k(values, k):
...     if type(k) is not int or k < 0:
...         raise ValueError('nonnegative integer k required')
...     if k == 0:
...         return []  # Deliberately does not consume values.
...     kept = []
...     for value in values:
...         if len(kept) < k:
...             heapq.heappush(kept, value)
...         elif value > kept[0]:
...             heapq.heapreplace(kept, value)
...     return sorted(kept, reverse=True)
>>> assert largest_k(iter([4, 1, 4, -2, 9]), 3) == [9, 4, 4]
>>> assert largest_k([], 2) == [] and largest_k([1], 4) == [1]
>>> assert largest_k([2, 2], 1) == [2]
>>> untouched = iter([7])
>>> assert largest_k(untouched, 0) == [] and next(untouched) == 7

```

For `k > 0`, storage is O(min(n,k)); time is O(n log(min(n,k)+1)) plus final
O(min(n,k) log(min(n,k)+1)) ordering. Count comparison/key costs separately.
Prefer `heapq.nlargest` in application code unless a live incremental state is
needed. For records, define the priority and tie policy explicitly; a generic
heap tuple must not accidentally compare nonorderable payloads.
