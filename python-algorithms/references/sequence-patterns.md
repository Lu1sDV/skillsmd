# Sequence patterns 1–9

## Contents

- [1. Two pointers](#1-two-pointers)
- [2. Sliding window](#2-sliding-window)
- [3. Binary search](#3-binary-search)
- [4. Prefix sum](#4-prefix-sum)
- [5. Monotonic stack](#5-monotonic-stack)
- [6. Hash map patterns](#6-hash-map-patterns)
- [7. Two heaps](#7-two-heaps)
- [8. Merge intervals](#8-merge-intervals)
- [9. Cyclic sort / bounded-domain placement](#9-cyclic-sort--bounded-domain-placement)

Examples accept integer lists/sequences unless stated; input is read-only except
for the explicitly mutating compaction and cyclic-placement functions. Complexity
counts bounded-size element operations; expected bounds apply to hashing.

## 1. Two pointers

On a nondecreasing sequence, a sum below target excludes the current left
endpoint (even with the largest remaining partner); above target excludes the
right endpoint. Require distinct indices, not distinct values. Sorting first
costs O(n log n) and changes indices; preserve `(value, original_index)` pairs
when the caller needs original positions.

```pycon
>>> def sorted_pair(nums, target):
...     left, right = 0, len(nums) - 1
...     while left < right:
...         total = nums[left] + nums[right]
...         if total == target:
...             return left, right
...         if total < target:
...             left += 1
...         else:
...             right -= 1
...     return None
>>> assert sorted_pair([], 0) is None
>>> assert sorted_pair([3], 6) is None
>>> assert sorted_pair([3, 3], 6) == (0, 1)
>>> assert sorted_pair([-4, -1, 2, 7], 3) == (0, 3)
>>> def compact_sorted(nums):
...     written = 0
...     for value in nums:
...         if written == 0 or value != nums[written - 1]:
...             nums[written] = value
...             written += 1
...     return written
>>> data = [1, 1, 2, 2, 3]
>>> size = compact_sorted(data)
>>> assert data[:size] == [1, 2, 3] and len(data) == 5
>>> assert compact_sorted([]) == 0

```

Both loops are O(n), O(1) auxiliary. Compaction mutates the prefix but does not
shrink the list; its tail is unspecified. To shrink, `del nums[size:]` mutates
length too. Three-sum: sort a copy, fix each distinct first value, run pair search
on its suffix, and after an answer skip equal values at both endpoints. This
produces unique value triples in O(n²) time, with O(n) sorting/copy workspace plus
output, not universally O(1) space.

For a nonnegative-height container, moving the shorter endpoint is sound:
keeping it cannot improve height and only reduces width. Empty/singleton returns
area zero. Palindrome pointers compare code points under the declared filter;
for full normalized caseless text, normalize/casefold before comparison and
budget that transformed copy. Water trapping instead tracks left/right maxima
or resolves bounded basins with a stack; nonnegative heights and unit bar widths
are part of both problems' contracts.

## 2. Sliding window

A fixed-size sum window works even with negative numbers. Reject k outside
`1..len(nums)`; returning zero for an invalid window would conceal errors and
conflict with valid all-negative answers. Each step removes exactly the outgoing
item and adds the incoming one.

```pycon
>>> from itertools import islice
>>> def max_window_sum(nums, k):
...     if not 1 <= k <= len(nums):
...         raise ValueError('invalid window size')
...     total = best = sum(islice(nums, k))
...     for right in range(k, len(nums)):
...         total += nums[right] - nums[right - k]
...         best = max(best, total)
...     return best
>>> assert max_window_sum([-4, -2, -8], 2) == -6
>>> assert max_window_sum([5], 1) == 5
>>> max_window_sum([], 0)
Traceback (most recent call last):
...
ValueError: invalid window size
>>> def shortest_sum_at_least(nums, target):
...     if target <= 0 or any(value < 0 for value in nums):
...         raise ValueError('positive target and nonnegative values required')
...     left = total = 0
...     best = len(nums) + 1
...     for right, value in enumerate(nums):
...         total += value
...         while total >= target:
...             best = min(best, right - left + 1)
...             total -= nums[left]
...             left += 1
...     return 0 if best > len(nums) else best
>>> assert shortest_sum_at_least([0, 2, 0, 3], 5) == 3
>>> assert shortest_sum_at_least([], 1) == 0
>>> assert shortest_sum_at_least([1, 1], 3) == 0
>>> shortest_sum_at_least([1, -1, 5], 5)
Traceback (most recent call last):
...
ValueError: positive target and nonnegative values required

```

O(n) time, O(1) auxiliary, including domain scan. For the shortest sum window,
nonnegative additions never reduce the sum and removing left never increases
it; each pointer advances at most n times. Signed sums need another invariant:
use prefix counts for exact sums (§4), or prefix sums with a monotonic deque for
shortest sum-at-least (maintain increasing prefix values and discard dominated
starts). Do not reuse the nonnegative loop on signed input.

Character windows maintain counts or last positions instead of numeric sums:

```pycon
>>> def longest_unique(text):
...     last, left, best = {}, 0, 0
...     for right, char in enumerate(text):
...         left = max(left, last.get(char, -1) + 1)
...         last[char] = right
...         best = max(best, right - left + 1)
...     return best
>>> assert longest_unique('abba') == 2
>>> assert longest_unique('é🙂é') == 2 and longest_unique('') == 0

```

Expected O(n) time, O(distinct code points) state. For a minimum covering
substring, count required multiplicities, expand right, increment `formed` only
when a required count is reached, then shrink while all distinct requirements
are formed. Decrement `formed` when removal drops a count below its requirement.
Record best `(start, length)` and slice once; return `''` immediately for empty
target. Repeated target letters matter; presence sets alone are wrong.
For anagram starts use fixed length `len(pattern)` and the same multiplicities;
define empty-pattern semantics explicitly (e.g. reject it). Comparing two full
Counters every step costs O(n·u) for u distinct tracked symbols; O(n) requires a
fixed bounded alphabet or an incrementally maintained mismatch count.

For each window maximum, a deque stores candidate indices in decreasing value
order. Expire indices `< right-k+1`; remove from the back while candidate value
`<= current` (the newer equal value survives longer); append current; emit the
front once a full window exists. Each index enters/leaves once: O(n) time, O(k)
state plus output. Validate k as in the sum example.

## 3. Binary search

Use `bisect` for sorted random-access sequences. Boundaries encode duplicates
without an ambiguous “some matching index”. Validate sortedness at the boundary
if not guaranteed, but that validation makes a single checked lookup O(n).

```pycon
>>> from bisect import bisect_left, bisect_right
>>> def equal_range(nums, value):
...     return bisect_left(nums, value), bisect_right(nums, value)
>>> assert equal_range([1, 2, 2, 2, 4], 2) == (1, 4)
>>> assert equal_range([], 2) == (0, 0)
>>> assert equal_range([1, 3], 2) == (1, 1)
>>> records = [('a', 10), ('b', 20)]
>>> assert bisect_left(records, 15, key=lambda row: row[1]) == 1
>>> def first_true(stop, predicate):
...     if stop < 0:
...         raise ValueError('negative search bound')
...     left, right = 0, stop
...     while left < right:
...         middle = (left + right) // 2
...         if predicate(middle):
...             right = middle
...         else:
...             left = middle + 1
...     return left  # stop means no True in [0, stop).
>>> assert first_true(10, lambda x: x * x >= 20) == 5
>>> assert first_true(0, lambda x: True) == 0
>>> assert first_true(4, lambda x: False) == 4

```

The predicate must be False then True and side-effect independent; O(log n)
predicate calls, plus predicate cost. `bisect`'s `key` is not applied to the
search value; `insort` applies key for search and inserts the original record.
The subsequent O(n) shift dominates insertion. A rotated sorted-array search
can choose a sorted half only when duplicates do not obscure the boundary;
with equal left/middle/right values, shrinking endpoints may degrade to O(n).
Peak search requires nonempty input and an adjacent-inequality assumption for a
strict peak; plateaus require a different specification. Binary search on shipping
capacity needs positive days, nonnegative weights and a monotone feasibility
check that preserves package order; handle empty weights before `max(weights)`.
Search `[max(weights), sum(weights)]` in O(n log(R+1)) work for range width R.

## 4. Prefix sum

Use a leading zero and half-open `[left, right)` query bounds. A prefix array
represents a snapshot: source mutations do not update it. For signed exact-sum
subarrays, the number of earlier prefixes equal to `current-target` is the
number of valid starts, including duplicates.

```pycon
>>> from itertools import accumulate
>>> def range_sum(prefix, left, right):
...     if not 0 <= left <= right < len(prefix):
...         raise ValueError('invalid half-open range')
...     return prefix[right] - prefix[left]
>>> prefix = list(accumulate([3, -2, 4], initial=0))
>>> assert range_sum(prefix, 0, 3) == 5
>>> assert range_sum(prefix, 1, 1) == 0
>>> assert range_sum([0], 0, 0) == 0
>>> def count_sum(nums, target):
...     counts = {0: 1}
...     total = answer = 0
...     for value in nums:
...         total += value
...         answer += counts.get(total - target, 0)
...         counts[total] = counts.get(total, 0) + 1
...     return answer
>>> assert count_sum([0, 0], 0) == 3
>>> assert count_sum([1, -1, 1], 1) == 3
>>> assert count_sum([], 0) == 0
>>> from itertools import product
>>> for size in range(5):
...     for values in product((-1, 0, 1), repeat=size):
...         brute = sum(sum(values[i:j]) == 0
...                     for i in range(size) for j in range(i + 1, size + 1))
...         assert count_sum(values, 0) == brute

```

Build O(n) time/space; query O(1). Counting is expected O(n) time/O(n) space;
query **before** inserting current prefix, avoiding empty subarrays. For length≥2
sum divisible by k, store the earliest index of each prefix remainder and seed
`0: -1`; use raw prefix totals for k=0, avoiding division by zero. State is O(n)
when k=0 and O(min(n+1, abs(k))) otherwise. Product-except-self uses left products
in the output then a right-running product, handling zero values without division;
O(n) arithmetic operations, O(1) extra accumulators plus output (integer widths
can grow). Empty output is `[]`; singleton output is `[1]`.

## 5. Monotonic stack

Store unresolved indices. For a **strictly** warmer/greater element, pop only
when old value `< new value`; equality must not resolve a candidate.

```pycon
>>> def warmer_wait(temps):
...     waiting, answer = [], [0] * len(temps)
...     for day, temperature in enumerate(temps):
...         while waiting and temps[waiting[-1]] < temperature:
...             previous = waiting.pop()
...             answer[previous] = day - previous
...         waiting.append(day)
...     return answer
>>> assert warmer_wait([30, 30, 31, 29]) == [2, 1, 0, 0]
>>> assert warmer_wait([]) == []
>>> assert warmer_wait([3, 2, 1]) == [0, 0, 0]

```

Each index is pushed/popped at most once: O(n) time/O(n) state plus output, not
O(n²) despite the nested loop. For next-greater **values**, use `None` for missing
rather than `-1` if negative values are allowed. For histogram rectangles with
nonnegative heights, store `(earliest_start, height)`: pop taller bars at index i,
score `height*(i-start)`, carry the earliest popped start into the new bar, then
flush remaining bars at n. Equal-height handling must retain the earliest start.
Rain-water stacks pop basin bottoms when a taller right wall arrives; require a
remaining left wall, then add `(right-left-1)*(min(walls)-bottom)`.

## 6. Hash map patterns

Check a complement before storing current index, preventing reuse of one item.
`setdefault` preserves the earliest duplicate index when that is the contract.

```pycon
>>> def pair_indices(nums, target):
...     first = {}
...     for index, value in enumerate(nums):
...         complement = target - value
...         if complement in first:
...             return first[complement], index
...         first.setdefault(value, index)
...     return None
>>> assert pair_indices([3], 6) is None
>>> assert pair_indices([3, 3], 6) == (0, 1)
>>> assert pair_indices([], 0) is None
>>> from collections import defaultdict, Counter
>>> def anagram_groups(words):
...     groups = defaultdict(list)
...     for word in words:
...         groups[tuple(sorted(word))].append(word)
...     return list(groups.values())
>>> assert anagram_groups(['éa', 'aé', '', '']) == [['éa', 'aé'], ['', '']]
>>> assert anagram_groups([]) == []
>>> assert Counter('baba').most_common(1) == [('b', 2)]

```

Pair search expected O(n) time/O(n) space. Sorted anagram keys cost
O(sum(L log(L+1))) time and O(sum L) retained keys/output references; a 26-count
key is O(L) only for validated lowercase ASCII. It must not index arbitrary
Unicode with `ord(c)-ord('a')`. No implicit normalization is performed here.
Longest-consecutive sequence: build a set, start a forward run only if `x-1` is
absent; every distinct value belongs to one run, expected O(n) time/O(n) space.
For Sudoku use separate row/column/box sets, with `box=(row//3)*3+col//3` for a
9×9 board; validate shape and allowed symbols before checking duplicates.

## 7. Two heaps

Maintain a negated lower-half heap and upper-half min-heap. Lower size equals
upper size or exceeds it by one; every lower value ≤ every upper value. This
integer-only median uses `Fraction` to avoid float precision loss/overflow for
large integer totals; convert at the presentation boundary if floats are wanted.

```pycon
>>> import heapq
>>> from fractions import Fraction
>>> class RunningMedian:
...     def __init__(self):
...         self.lower, self.upper = [], []
...     def add(self, value):
...         heapq.heappush(self.lower, -value)
...         heapq.heappush(self.upper, -heapq.heappop(self.lower))
...         if len(self.upper) > len(self.lower):
...             heapq.heappush(self.lower, -heapq.heappop(self.upper))
...     def median(self):
...         if not self.lower:
...             return None
...         if len(self.lower) > len(self.upper):
...             return Fraction(-self.lower[0])
...         return Fraction(-self.lower[0] + self.upper[0], 2)
>>> stream = RunningMedian()
>>> assert stream.median() is None
>>> for value, expected in [(5, 5), (1, 3), (1, 1), (9, 3)]:
...     stream.add(value)
...     assert stream.median() == expected
>>> big = RunningMedian()
>>> big.add(10**1000)
>>> big.add(10**1000 + 1)
>>> assert big.median() * 2 == 2 * 10**1000 + 1

```

O(log n) amortized heap insertion, O(1) root reads per median, O(n) stored items;
Fraction arithmetic and large integers add operand-size cost. Duplicate values
are independent observations. Deleting a sliding-window item needs more than
this class: two heaps with lazy deletion require **logical live sizes separate
from physical heap lengths**, stale-root pruning before comparisons/medians,
and rebalancing on live counts. Stale buried entries can grow to O(n) without
compaction; do not claim automatic O(k) physical storage. For modest windows,
a sorted list plus `bisect_left` deletion/`insort` is simpler and bounded to O(k)
space but O(nk) shifts. Do not copy an unverified lazy-deletion template.

## 8. Merge intervals

This implementation merges **closed** integer intervals, including touching
endpoints, and returns independent immutable pairs without modifying caller
lists. For half-open occupancy `[start, end)`, touching intervals need not overlap
and zero-length intervals occupy no time; choose semantics before changing `<=`.

```pycon
>>> def merge_closed(intervals):
...     ordered = sorted((start, end) for start, end in intervals)
...     if any(start > end for start, end in ordered):
...         raise ValueError('reversed interval')
...     result = []
...     for start, end in ordered:
...         if result and start <= result[-1][1]:
...             result[-1] = (result[-1][0], max(result[-1][1], end))
...         else:
...             result.append((start, end))
...     return result
>>> original = [[3, 4], [1, 3], [7, 7]]
>>> assert merge_closed(original) == [(1, 4), (7, 7)]
>>> assert original == [[3, 4], [1, 3], [7, 7]]
>>> assert merge_closed([]) == []
>>> assert merge_closed([(1, 5), (2, 3), (1, 5)]) == [(1, 5)]
>>> merge_closed([(3, 2)])
Traceback (most recent call last):
...
ValueError: reversed interval

```

Sorted processed intervals form a union whose last element is the only candidate
for overlap with the next interval. O(n log n) time/O(n) sorting storage plus
output. If input is already sorted/disjoint, inserting one interval is O(n): emit
those ending before it, expand through overlaps, emit it, then the untouched
suffix. Copy pairs if the result must not alias mutable inputs. Meeting rooms
usually use half-open intervals with positive duration: sort by start, remove
all end-times `<= start`, push current end and track the maximum active heap
size. O(n log n) time/O(n) space; reject or explicitly ignore empty meetings.

## 9. Cyclic sort / bounded-domain placement

For values in `1..n`, map value x to index x−1. A swap puts at least one value
in its home; the equality guard prevents duplicate swaps forever. With duplicates
this **places representatives**, not a general sorted multiset. A true sorted
permutation requires each value exactly once. Validate the entire domain before
mutation so a bad later value cannot leave a partially modified caller list.

```pycon
>>> def missing_values_in_place(nums):
...     n = len(nums)
...     if any(type(value) is not int or not 1 <= value <= n for value in nums):
...         raise ValueError('values must be integers in 1..n')
...     index = 0
...     while index < n:
...         home = nums[index] - 1
...         if nums[index] != nums[home]:
...             nums[index], nums[home] = nums[home], nums[index]
...         else:
...             index += 1
...     return [index + 1 for index, value in enumerate(nums) if value != index + 1]
>>> values = [4, 3, 2, 7, 8, 2, 3, 1]
>>> assert missing_values_in_place(values) == [5, 6]
>>> permutation = [3, 1, 2]
>>> assert missing_values_in_place(permutation) == [] and permutation == [1, 2, 3]
>>> assert missing_values_in_place([2, 2]) == [1]
>>> assert missing_values_in_place([]) == []
>>> invalid = [2, 0]
>>> missing_values_in_place(invalid)
Traceback (most recent call last):
...
ValueError: values must be integers in 1..n
>>> assert invalid == [2, 0]

```

O(n) time, O(1) placement state plus O(n) possible output. For one missing number
in `0..n` with n distinct inputs, map x to index x and skip x==n; reject negatives
before indexing. Sum/XOR formulas are simpler if uniqueness and domain are
already guaranteed, but neither validates those assumptions. Sign-marking
`abs(x)-1` for duplicates requires original values `1..n`, mutates signs and
emits an extra occurrence for every repetition after the first; “each duplicate
once” therefore requires at-most-twice multiplicity or explicit deduplication.

Semantics: [bisect](https://docs.python.org/3.11/library/bisect.html),
[itertools](https://docs.python.org/3.11/library/itertools.html),
[fractions](https://docs.python.org/3.11/library/fractions.html).
