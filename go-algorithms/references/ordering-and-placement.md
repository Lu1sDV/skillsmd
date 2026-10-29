# Ordering and placement (families 7–9)

## Contents

7. [Two heaps](#7-two-heaps)
8. [Merge intervals](#8-merge-intervals)
9. [Cyclic sort](#9-cyclic-sort)

Runnable implementations: [algorithms.go](../examples/algorithms.go) and
[median.go](../examples/median.go); regressions: [examples_test.go](../examples/examples_test.go).

## 7. Two heaps

For a growing stream, maintain a max-heap of the lower half and min-heap of the
upper half. Invariants: every lower element <= every upper element;
`len(lower)==len(upper)` or `len(lower)==len(upper)+1`. Push into lower, move its
maximum to upper, and move upper's minimum back if upper became larger. This
preserves partition ordering and the size bound. Each insert O(log(n+1)); central
value retrieval O(1); stored stream O(n). Heap storage must not alias caller data.
No sorting of the whole stream is necessary.

An empty stream has no median: return a found flag, not an unchecked root access.
For even size, `(lowerRoot+upperRoot)/2` overflows before float conversion.
Converting each to float before addition avoids integer overflow, but float64
cannot exactly represent every 64-bit integer or every exact median. The runnable
`Median.Middle` returns the two **integer central values** (equal for odd size),
allowing callers to choose exact rational arithmetic or a documented floating
approximation. This also represents the exact median of MinInt and MaxInt
without overflow/lost cancellation. Do not copy a populated Median by value:
its slices share backing storage, and concurrent calls require synchronization.

The `container/heap` interface's receiver `Pop` removes the last slot, while
package `heap.Pop` removes the root after restoration. Do not negate values to
implement max-heap order: `-MinInt` overflows; use reversed comparison instead.
The adapter's `any` assertion is internal with a fixed int-only call contract,
not unvalidated external polymorphism.

Streaming median does **not** solve sliding-window median deletion. Removing
expired items needs tracked indices + `heap.Remove`, or lazy deletion with
logical live sizes, stale-root pruning and a physical-storage policy. Claiming
O(window) storage while indefinitely retaining stale heap elements is wrong.

## 8. Merge intervals

Choose endpoint semantics first: closed [a,b] merges when next.Start<=last.End;
half-open [a,b) usually merges overlap only when next.Start<last.End, with a
separate policy if adjacency should coalesce. Empty intervals need a defined rule.
Reject reversed intervals before sorting/mutation. Fixed struct fields avoid
malformed `[][]int` entries with fewer than two endpoints.

Sort ascending start, then end with `cmp.Compare` (not subtraction). Invariant:
result is sorted/disjoint, and its last interval covers exactly the connected
component of all processed intervals. If overlap, extend end with max; otherwise
append. Time O(n log n) comparisons plus O(n) scan. Output needs O(n) space;
cloning input for nonmutation adds O(n) even if scan uses constant extra state.

The chapter's result starts with `intervals[0]` and updates `last[1]`: it both
sorts the caller's outer slice and **mutates nested endpoint slices**. Cloning
only the outer `[][]int` does not fix this. The executable `Merge` accepts
`[]Interval`, clones the value elements, and compacts only that clone; modifying
its result cannot change the input. Empty input returns nil, a valid empty result.

Complete nonmutating implementation (same contract as the executable):

```go
import (
    "cmp"
    "fmt"
    "slices"
)

type Interval struct { Start, End int }

func Merge(input []Interval) ([]Interval, error) {
    for _, interval := range input {
        if interval.Start > interval.End {
            return nil, fmt.Errorf("reversed interval: %v", interval)
        }
    }
    ordered := slices.Clone(input)
    slices.SortFunc(ordered, func(a, b Interval) int {
        if c := cmp.Compare(a.Start, b.Start); c != 0 {
            return c
        }
        return cmp.Compare(a.End, b.End)
    })
    count := 0
    for _, current := range ordered {
        if count == 0 || current.Start > ordered[count-1].End {
            ordered[count] = current
            count++
        } else {
            ordered[count-1].End = max(ordered[count-1].End, current.End)
        }
    }
    return ordered[:count], nil
}
```

This returns a compacted slice retaining the full cloned allocation; O(n) memory
is accurate even when the merged result length is one. No endpoint arithmetic is
needed, so MinInt/MaxInt endpoints are safe.

## 9. Cyclic sort

This is bounded-domain **placement**, not a general integer sorting algorithm.

**Missing number in [0,n]:** preconditions are n distinct integers each between
0 and n, inclusive; exactly one of n+1 possible values is absent. Put each value
v<n at index v until current index is correct or contains sentinel n; scan for
first index with wrong value, else missing n. Each successful swap settles a
value permanently: O(n) time, O(1) auxiliary storage for a trusted in-place core.
Empty input yields zero. Negative values are invalid before any indexing.

The source condition `j<n && j!=i` does not prevent swapping identical duplicates
forever (e.g. [1,1]); negative values pass j<n and panic at nums[j]. Either prove
distinct/range preconditions or validate them first. A duplicate-aware swap guard
`nums[i]!=nums[j]` ensures progress, but **does not establish** that the input
has exactly one missing value. Avoid silently turning malformed data into a
plausible answer.

The runnable `MissingNumber` validates range and uniqueness with a bool slice,
clones input, then places values. Its end-to-end cost is O(n) time **and O(n)
auxiliary space**, not O(1); this cost buys a nonmutating checked public boundary.
If a trusted caller already guarantees uniqueness and owns the slice, the core
placement loop needs no validation allocation or copy.

**Duplicate in [1,n]:** for a slice of length n with values in 1..n, map v to
index v-1. Swap only if `nums[i]!=nums[v-1]`, otherwise advance; each successful
swap establishes a correct slot. After placement, a mismatched value identifies
a duplicate. Finding **one** duplicate vs every distinct duplicate, multiplicities
and no-duplicate behavior are different contracts. Validate domain before any
swaps, choose -1/found flag only when it cannot collide with a valid result, and
state destructive ownership. O(n)/O(1) for this core; validation/copy may add O(n).
Floyd's functional-graph duplicate method has different input assumptions and is
not interchangeable without proof.
