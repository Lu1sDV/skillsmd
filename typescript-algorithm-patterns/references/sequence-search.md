# Sequence and Search Patterns

## 1. Two pointers

Choose converging pointers only when an ordering or geometric argument explains which pointer may advance. Preserve original indices if sorting. For fast/slow compaction, define the valid written prefix and whether returned length or a new array is required. Handle duplicates deliberately.

Include sorting in the time bound; do not automatically claim constant auxiliary space for an engine's built-in sort.

## 2. Sliding window

For a fixed window, validate integer size and define behavior when size is zero or exceeds input length. For a variable window, identify the maintained state and the monotonic condition that makes shrinking safe.

For sum thresholds, require the appropriate positive/nonnegative domain and target assumptions; arbitrary negative values may require prefix sums or another algorithm. For frequency windows, update counts and the number of satisfied requirements separately.

Handle an empty target before a minimum-window loop. Keep character representation consistent across source and target. Track only required keys if claiming space proportional to the target alphabet; retaining all input characters changes that bound.

## 3. Binary search

Choose and keep one interval convention, such as half-open `[lo, hi)`. Define lower-bound versus upper-bound equality behavior. Show that each update strictly shrinks the unresolved range.

For answer-space search, define a monotone predicate and valid search bounds. For rotated arrays, specify whether duplicates are possible; duplicate ambiguity can remove the logarithmic guarantee. Define empty input and not-found output explicitly.

## 4. Prefix sum

Define `prefix[0] = 0` and the exact endpoint convention for range subtraction. For counting target-sum subarrays, initialize the empty-prefix count, query the needed previous prefix, then record the current prefix.

Use a count of occurrences, not a set, when multiple matching prefixes matter. Check numerical bounds. For prefix/suffix products, account for zero values and distinguish output storage from auxiliary storage.

## 5. Monotonic stack

Store indices when distances or widths are needed. State whether the stack is strictly or weakly increasing/decreasing, and choose the equal-value pop rule accordingly.

Charge each index at most one push and one pop to justify linear time. For histograms, derive width from the previous remaining boundary and flush the stack with a safe sentinel or final pass. Do not generalize a monotonic stack to every expression-evaluation task.

## 6. Hash-map patterns

For two-sum, query the complement before inserting the current value so one position is not reused. For counting/grouping, define absent defaults and equality semantics. Use `has` when stored undefined is meaningful.

For anagrams, define alphabet/normalization and include key construction, sorting, or encoding in complexity. For consecutive runs, begin only at values lacking a predecessor; check safe-integer assumptions.

Distinguish expected hash access from a language-level worst-case guarantee.

## 7. Two heaps

Keep the lower half in a max heap and upper half in a min heap. Preserve both invariants: every lower value is no greater than every upper value, and heap sizes differ by at most one under the chosen convention.

Define empty median behavior and even-count averaging. Use explicit comparators and charge insertion/rebalancing as O(log n). Test ascending, descending, duplicate, and alternating-extreme streams.

## 8. Merge intervals

Specify closed or half-open ranges and whether touching endpoints count as overlap. Sort by start only when permitted; include its cost. Maintain a disjoint merged prefix and extend the last interval when appropriate.

For insertion into an already sorted disjoint list, document those preconditions. Avoid mutating caller-owned nested tuples or the inserted interval when the contract promises preservation. Reject or normalize inverted endpoints deliberately.

## 9. Cyclic sort

Require a finite integer domain that maps safely to array indices. Check bounds before swapping and ensure a swap changes the state; skip a value already at its destination, including duplicates.

Distinguish the domains 1..n and 0..n. Define the missing/duplicate-value assumptions before using a sum or XOR shortcut. Keep input mutation explicit and account for precision limits in arithmetic shortcuts.

## Sources

- [StructWeave: sequence patterns 1–9](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/04-interview-patterns.md#1-two-pointers)
- [StructWeave: heap implementation](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/02-data-structures.md#priority-queue-heap)
