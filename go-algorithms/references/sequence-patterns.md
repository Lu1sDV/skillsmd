# Sequence patterns (families 1–6)

## Contents

1. [Two pointers](#1-two-pointers)
2. [Sliding window](#2-sliding-window)
3. [Binary search](#3-binary-search)
4. [Prefix sum](#4-prefix-sum)
5. [Monotonic stack](#5-monotonic-stack)
6. [Hash-map patterns](#6-hash-map-patterns)

Complexity assumes fixed-width arithmetic with proven-safe values; validate or
check overflow when the input domain does not prove it. Slice inputs below may be
nil. Text is bytes unless explicitly decoded to runes; code points are not
user-perceived graphemes. [Examples](../examples/algorithms.go) contain complete
runnable corrections for minimum windows and histogram boundaries.

## 1. Two pointers

**Sorted two-sum:** keep l<r; if sum is below target, no pair using l with an
index <=r can work, so increment l; similarly decrement r for above target.
O(n) time, O(1) auxiliary space, no mutation, no pair on fewer than two items.
Return explicit found/index pair; state zero- vs one-based indexing. Sorting
unsorted input costs O(n log n), changes positions and may require indexed copies.
Prove `a[l]+a[r]` fits or compare with checked arithmetic. An overflowing sum
invalidates the direction decision, not just the returned result.

**Sorted deduplication:** retained prefix contains each value once, and fast
scans untouched suffix. Empty returns length zero. Write at slow only for a new
value; return `nums[:slow]` (or the new length). O(n)/O(1), mutates aliases; clear
the obsolete tail for references. `slices.Compact` implements adjacent dedup.

**Container with most water:** nonnegative heights; candidate area is
`min(height[l],height[r])*(r-l)`. Move a shorter side: shrinking width while
keeping that side cannot improve its limiting height. O(n)/O(1), empty/singleton
area zero. Check the product for overflow; negative heights violate the model.

## 2. Sliding window

**Fixed-length maximum sum:** require 1<=k<=n. Seed the result with the first
window, not zero (all-negative inputs are valid). Maintain exact sum of the last
k entries by adding incoming/removing outgoing. O(n)/O(1); checked intermediate
arithmetic matters even when the final answer fits. Decide invalid-k error vs
no-answer; do not index or quietly return zero for k>n.

**Variable windows:** each index enters/exits at most once; linear time follows
only if updates/validity tests are O(1) expected. A sum-at-least-target shrinking
window needs nonnegative numbers; signed numbers destroy the monotonicity.

**Longest substring without repeats:** map unit -> last index; maintain unique
window [left,right]. Set `left=max(left,last+1)`, not simply last+1, to prevent
moving backwards. Empty length zero. O(n) expected time, O(distinct units) map
space; rune conversion adds O(n) space if used. The source byte version counts
UTF-8 bytes, not characters.

**Minimum covering substring:** count multiplicities required by t; keep window
counts and how many distinct requirements are exactly satisfied. Expand right,
then shrink while every requirement is met, recording shorter windows before
removal. Removing a required unit below its quota invalidates the window. Empty
target returns `""` **before shrinking**; the original loop otherwise advances
left beyond the source and panics. No cover also returns `""`. Define earliest
window as the tie-breaker. The runnable `MinWindow` validates UTF-8, works on runes,
and returns a newly constructed string, not a tiny substring retaining a large
input. Expected O(n+m) time and O(n+m) space including rune conversions/output;
a byte-index version can use a fixed alphabet table and constant auxiliary space.
Rune equality does not normalize composed/decomposed forms.

Complete safe byte-alphabet version (use only when bytes are the intended units):

```go
func MinWindowBytes(s, target string) string {
    if len(target) == 0 || len(target) > len(s) {
        return ""
    }
    var need [256]int
    for i := 0; i < len(target); i++ {
        need[target[i]]++
    }
    missing, left := len(target), 0
    bestStart, bestLen := 0, len(s)+1
    for right := 0; right < len(s); right++ {
        if need[s[right]] > 0 {
            missing--
        }
        need[s[right]]--
        for missing == 0 {
            if size := right-left+1; size < bestLen {
                bestStart, bestLen = left, size
            }
            need[s[left]]++
            if need[s[left]] > 0 {
                missing++
            }
            left++
        }
    }
    if bestLen > len(s) {
        return ""
    }
    return s[bestStart:bestStart+bestLen] // shares string storage
}
```

## 3. Binary search

For lower bound use half-open [l,r): all indices before l are <target, all at/after
r are >=target. Midpoint `l+(r-l)/2`; update l=mid+1 on too-small, otherwise r=mid.
The shrinking interval proves termination, including empty input. Upper bound
changes `<` to `<=`. Prefer `sort.Search` or `slices.BinarySearch`; a returned n is
valid as an insertion point, invalid as an element index. O(log n) comparisons,
O(1) auxiliary space for the iterative search. Predicate evaluation cost multiplies
the bound. An answer-domain search needs a monotone feasibility predicate and a
proved feasible/infeasible bracket, not a guess that halving always works.

**Rotated sorted search:** with distinct values, one half is sorted; test target
membership in that half's bounds before discarding it. O(log n)/O(1). Duplicates
can make both halves indistinguishable (e.g. [1,0,1,1,1]); explicit boundary
shrinking may degrade to O(n). Do not claim the chapter's distinct-case routine
handles every duplicate rotation. Empty result is not found; no mutation.

## 4. Prefix sum

`prefix[0]=0`, `prefix[i+1]=prefix[i]+nums[i]`; inclusive range [i,j] is
`prefix[j+1]-prefix[i]`, or half-open [l,r) is `prefix[r]-prefix[l]`.
Validate bounds and use one endpoint convention consistently. Build O(n) time and
space, query O(1); static prefix arrays do not update themselves after mutation.
Both accumulation and query subtraction may overflow.

**Count subarrays summing to k:** seed frequencies with `{0:1}`. For each prefix p,
add `seen[p-k]`, then increment `seen[p]`. Query before insert avoids counting the
empty interval when k=0; frequency (not membership) counts repeated prefixes.
Works for signed values where a sum window does not. Expected O(n) time/O(n)
space; empty input gives zero. Count may reach n(n+1)/2, separately from prefix
sum bounds; neither is automatically safe in `int`.

## 5. Monotonic stack

**Next greater:** keep unresolved indices with non-increasing values. On a new
strictly larger value, pop and resolve until order is restored. Push each index
once, pop at most once: O(n) total/O(n) space despite the nested loop. Decide
strict `>` vs greater-or-equal. Return next index with -1 (unambiguous), or a
value plus found bit: a value sentinel -1 collides with real negative values.
**Daily temperatures** uses the same stack and stores `i-poppedIndex`; zero means
no warmer future day, duplicates do not resolve. Empty output is empty.

**Largest histogram rectangle:** nonnegative heights. A popped bar is the limiting
height; right boundary is the current smaller bar, left boundary is just after
remaining stack top, or zero when empty. Area = height * width. Flush with a
virtual final zero rather than `append(heights,0)`: append may overwrite spare
capacity visible to an alias even though caller length does not change.
`LargestRectangle` in the executable examples validates heights and product bounds
before returning an area. O(n) time/O(n) auxiliary stack, no input writes; empty
area zero. Equal-height bars may remain until flush without changing the bound.

## 6. Hash-map patterns

- **Two-sum complement:** look up target-x before storing x->index, so one entry
  cannot pair with itself; repeated equal values still work. Expected O(n)/O(n),
  no mutation. Check complement overflow (or prove bounded inputs).
- **Top-k frequent:** count n values, distribute each distinct key into bucket
  indexed by frequency 1..n, traverse descending frequency and stop after k.
  Validate 0<=k<=distinct; k=0 yields empty. Do not blindly slice to k if invalid.
  Expected O(n) time/O(n) storage with unspecified tie order; sorting ties adds
  cost. A size-k min-heap of distinct keys costs O(n+d log(k+1)), O(d+k) including
  the frequency map; it does not remove counting storage.
- **Anagrams:** sorted byte keys are suitable only for a byte alphabet. For
  Unicode character anagrams, decode runes, sort runes, stringify key, define
  normalization first. Per word length L: O(L log L) comparison work and O(L)
  key construction; fixed alphabet frequency-array keys offer O(L) only with a
  proved alphabet. Output group/map order is unspecified unless sorted explicitly.
- **Counting/grouping/memoization:** zero-value map reads help counts; comma-ok
  preserves cached zero answers. Memo keys must encode all relevant state.
  Cyclic recursion needs in-progress detection or a different recurrence.

See [collections](collections-and-contracts.md) for map/set key and ownership
contracts; hash lookup is expected O(1) only under the stated key/hash cost model.
