# Search and optimization patterns: 11–13, 17

These techniques depend on a proof about states, not on Rust syntax. Start with a
small brute-force oracle, identify repeated work or discardable choices, then
state the recurrence/pruning/greedy invariant. Every Rust fence below is isolated
and dependency-free.

## 11. Backtracking

**Use:** enumerate subsets, permutations, combinations and constraint solutions.
Invariant: `path` is the current partial solution; every mutable choice is undone
before visiting its sibling. A monotonically advancing index or decreasing
nonnegative remainder proves termination. Prune only when no extension can solve
the problem; do not conflate “currently not a solution” with “cannot become one”.

For subsets of n distinct input values, increasing chosen indices prevents
reordering duplicates. There are 2^n subsets; visiting has O(2^n) callback calls,
O(n) path/stack storage, and materializing all results costs O(n·2^n) time and
output space. The empty input has one subset: the empty subset.

```rust
fn visit_subsets(nums: &[i32], mut visit: impl FnMut(&[i32])) {
    fn walk(nums: &[i32], start: usize, path: &mut Vec<i32>,
            visit: &mut impl FnMut(&[i32])) {
        visit(path);
        for i in start..nums.len() {
            path.push(nums[i]);
            walk(nums, i + 1, path, visit);
            path.pop();
        }
    }
    let mut path = Vec::with_capacity(nums.len());
    walk(nums, 0, &mut path, &mut visit);
}
let mut subsets = Vec::new();
visit_subsets(&[1, 2], |path| subsets.push(path.to_vec()));
assert_eq!(subsets, vec![vec![], vec![1], vec![1, 2], vec![2]]);
let mut empty_count = 0;
visit_subsets(&[], |path| { assert!(path.is_empty()); empty_count += 1; });
assert_eq!(empty_count, 1);
```

The callback avoids retaining all output when the consumer only aggregates it;
`path.to_vec()` above is necessary only because the example retains snapshots.
The API borrows the temporary path; callers cannot keep that slice after the
callback returns. Bound input depth/output at an external boundary. Recursive
algorithms can exhaust the stack even before their enormous output completes.

| Variant | State and progress | Preconditions / cost |
|---|---|---|
| Unique subsets from duplicates | Sort a permitted copy/input; skip equal candidates at the same depth | Do not skip the same value at deeper levels; materialized output bound O(n·2^n) |
| Permutations | `used[i]` or swap into current position; recurse to next position; undo | Distinct values give n! results, O(n·n!) materialized time/space; O(n) working state |
| Unique permutations | Sorted values; skip an equal candidate when its previous equal index is unused at this depth | A global seen-value set would incorrectly disallow repeated occurrences |
| Combination sum with reuse | Nondecreasing candidate index, recurse with the same index after selecting | Positive candidates, nonnegative target, deduplicate candidates; zero/negative candidates break decreasing-remainder termination |
| Combination sum without reuse | Recurse with `i + 1` | Each input occurrence consumed at most once; duplicate policy still explicit |

For positive combination candidates, stop a branch when candidate > remainder,
then subtract only after that comparison. If sorted, break rather than continue.
Target zero yields the empty combination. With k candidate choices and maximum
depth d = target/min_candidate, a coarse bound is O(k^d·d) when retaining results;
actual count depends on pruning. Do not present all backtracking as O(2^n).

## 12. Dynamic programming

**Use:** repeated subproblems with a state sufficient to determine future
possibilities. Define the mathematical meaning of a cell before choosing its
array layout. Prove base cases, dependency order and transition, then consider
rolling storage. Time = number of states × transition work; space = retained
states plus input conversion/output. Memoized recursion still has call-stack
cost and must distinguish “not computed” from a valid zero answer.

### Longest common subsequence over Unicode scalars

`dp[j]` after each outer iteration is LCS length of the processed prefix of a
and `b[..j]`. While overwriting a row, save the old diagonal before replacing a
cell. A match extends that diagonal; a mismatch takes max(top, left).
O(m·n) time and O(n) auxiliary space for n scalars of b, including its `Vec<char>`.
When asymmetry matters, choose the shorter scalar sequence as the stored row;
byte length is not scalar count. This returns a length, not a reconstructed LCS.

```rust
fn lcs_len(a: &str, b: &str) -> usize {
    let b: Vec<char> = b.chars().collect();
    let mut dp = vec![0_usize; b.len() + 1];
    for left in a.chars() {
        let mut diagonal = 0;
        for (j, &right) in b.iter().enumerate() {
            let top = dp[j + 1];
            dp[j + 1] = if left == right {
                diagonal + 1
            } else {
                dp[j].max(top)
            };
            diagonal = top;
        }
    }
    dp[b.len()]
}
assert_eq!(lcs_len("", "日"), 0);
assert_eq!(lcs_len("abcde", "ace"), 3);
assert_eq!(lcs_len("é日a", "日éa"), 2);
assert_eq!(lcs_len("é", "e\u{301}"), 0); // No implicit normalization.
```

Lengths are bounded by the number of input scalars, so additions fit. The
upstream byte-length table dimensions combined with character indexing could
panic on non-ASCII strings; this implementation consistently uses scalar counts.
For reconstructing the sequence, keep choices/full rows or use a separately
justified divide-and-conquer reconstruction instead of claiming the rolling row
contains enough history.

### Counting states needs an overflow policy

For 1- or 2-step stairs, the base `ways(0) = 1` represents the one empty path.
`Option<u64>` here means a count exists but may not be representable. It is not a
no-solution sentinel. O(n) time/O(1) space until the first overflow; no final
unused Fibonacci term is computed.

```rust
fn stair_ways(n: usize) -> Option<u64> {
    let (mut previous, mut current) = (1_u64, 1_u64);
    for _ in 2..=n {
        let next = previous.checked_add(current)?;
        previous = current;
        current = next;
    }
    Some(current)
}
assert_eq!(stair_ways(0), Some(1));
assert_eq!(stair_ways(1), Some(1));
assert_eq!(stair_ways(4), Some(5));
assert_eq!(stair_ways(93), None);
```

### Transition direction changes the problem

| Problem | State / transition | Preconditions / costs |
|---|---|---|
| 0/1 knapsack | Best value for capacity w; update w downward for each item | Equal weight/value lengths, nonnegative weights/capacity; O(items·capacity) time/O(capacity) row space |
| Unbounded knapsack | Reusing current item is allowed; update capacity upward | Positive weights for recurrence progress; zero-weight positive-value items make optimum unbounded |
| Minimum coin count | `dp[0]=Some(0)`; reachable `dp[a-c] + 1` competes for minimum | Positive coin denominations, nonnegative bounded amount; O(amount·coins) time/O(amount) space |
| Grid/path count | Sum already completed predecessor states | Validate grid shape/blocked semantics; checked sums or explicit modular arithmetic |

Use unsigned domain types only after validating signed external input. Negative
capacity cast to `usize` can request huge storage. For 0/1 knapsack, downward
iteration uses each item at most once; upward iteration silently changes it to
unbounded reuse. Zero-weight items are legal in the 0/1 problem if each item is
processed exactly once; define whether the empty selection is allowed when
values are negative. Use checked value addition or a proven bound. For coin
change, `Option<usize>` prevents accidental `MAX + 1` from an unreachable cell;
zero amount is reachable with zero coins. Bound memory before allocating an
amount/capacity-sized table.

## 13. Greedy

**Use:** only when an exchange argument or stays-ahead invariant proves that a
local choice preserves an optimal solution. Producing a plausible answer on a
few samples is not evidence. Weighted scheduling, arbitrary coin systems and
knapsack are common cases where a tempting greedy rule fails.

### Maximum number of nonoverlapping activities

Contract: positive-duration half-open intervals `[start, end)`, equal value per
activity, touching endpoints compatible. Choose the earliest finishing feasible
activity. Exchange proof: replace the first activity of an optimum with the
one finishing earliest; later feasible choices remain feasible. Repeat on the
remaining suffix. Sorting O(n log n), scan O(n), O(1) auxiliary beyond output.

```rust
fn activities(intervals: &mut [(i32, i32)]) -> Vec<(i32, i32)> {
    assert!(intervals.iter().all(|&(a, b)| a < b), "positive duration required");
    intervals.sort_unstable_by_key(|&(start, end)| (end, start));
    let mut chosen = Vec::new();
    let mut last_end = None;
    for &(start, end) in intervals.iter() {
        if last_end.map_or(true, |previous| start >= previous) {
            chosen.push((start, end));
            last_end = Some(end);
        }
    }
    chosen
}
assert!(activities(&mut []).is_empty());
assert_eq!(activities(&mut [(0, 4), (1, 2), (2, 3), (3, 5)]),
           [(1, 2), (2, 3), (3, 5)]);
assert_eq!(activities(&mut [(i32::MIN, i32::MIN + 1)]).len(), 1);
```

For closed intervals with forbidden endpoint overlap, compatibility changes to
`start > previous_end`. Empty/zero-duration intervals require a separate explicit
model, not an accidental choice of tie order. Weighted activity selection needs
DP; the earliest-finish proof assumes every activity contributes one unit.

### Reachability in jump game

Contract: each entry is a nonnegative **maximum** jump distance, any smaller jump
is allowed, and the empty array has no start/end and returns false. Invariant:
every index through `farthest` is reachable. If i exceeds it, no later index can
be reached. O(n) time/O(1) space. Clamp reach to the last relevant index: saturation
is mathematically valid here because larger distances are observationally equal,
not because overflow should generally be hidden.

```rust
fn can_reach_end(jumps: &[usize]) -> bool {
    let Some(last) = jumps.len().checked_sub(1) else { return false; };
    let mut farthest = 0;
    for (i, &jump) in jumps.iter().enumerate() {
        if i > farthest { return false; }
        farthest = farthest.max(i.saturating_add(jump).min(last));
        if farthest == last { return true; }
    }
    false
}
assert!(!can_reach_end(&[]));
assert!(can_reach_end(&[0]));
assert!(can_reach_end(&[2, 3, 1, 1, 4]));
assert!(!can_reach_end(&[3, 2, 1, 0, 4]));
assert!(can_reach_end(&[usize::MAX, 0]));
```

A problem requiring **exact** jump lengths or backward jumps has a different
reachability structure; the interval invariant above no longer follows.

## 17. Bit manipulation

**Use:** fixed-width masks, membership flags, parity/XOR cancellation, subset
state encoding. Work in an unsigned type; explicitly validate the bit index.
A shift by the word width or more is overflow, not portable truncation. For a
fixed u64, these operations are O(1) time/space; iterating set bits costs
O(popcount), and enumerating masks for n elements still costs O(2^n).

```rust
fn is_set(value: u64, bit: u32) -> Option<bool> {
    Some(value & 1_u64.checked_shl(bit)? != 0)
}
fn set_bit(value: u64, bit: u32) -> Option<u64> {
    Some(value | 1_u64.checked_shl(bit)?)
}
fn clear_bit(value: u64, bit: u32) -> Option<u64> {
    Some(value & !1_u64.checked_shl(bit)?)
}
fn toggle_bit(value: u64, bit: u32) -> Option<u64> {
    Some(value ^ 1_u64.checked_shl(bit)?)
}
fn lowest_set_bit(value: u64) -> u64 {
    value & value.wrapping_neg() // Deliberate modulo-2^64 arithmetic.
}
fn clear_lowest_set_bit(value: u64) -> u64 {
    value & value.wrapping_sub(1) // Also maps zero to zero.
}
assert_eq!(set_bit(0, 63), Some(1_u64 << 63));
assert_eq!(set_bit(0, 64), None);
assert_eq!(is_set(8, 3), Some(true));
assert_eq!(clear_bit(10, 1), Some(8));
assert_eq!(toggle_bit(10, 3), Some(2));
assert_eq!(lowest_set_bit(0), 0);
assert_eq!(lowest_set_bit(1_u64 << 63), 1_u64 << 63);
assert_eq!(clear_lowest_set_bit(0), 0);
assert_eq!(clear_lowest_set_bit(0b1010), 0b1000);
assert_eq!(0b1010_u64.count_ones(), 2);
assert!(!0_u64.is_power_of_two());
assert!((1_u64 << 63).is_power_of_two());
```

XOR cancellation returns the unpaired value **only** under the promise that one
value occurs an odd number of times and all others an even number (the classic
problem uses exactly one once and all others twice). It neither validates this
promise nor identifies arbitrary duplicates. Empty XOR is zero but that does
not mean an empty input contains a single number.

```rust
fn unpaired(nums: &[i32]) -> i32 {
    nums.iter().copied().fold(0, |a, b| a ^ b)
}
assert_eq!(unpaired(&[i32::MIN, 7, i32::MIN]), 7);
assert_eq!(unpaired(&[2, 2, 0]), 0);
let counts: Vec<_> = (0_u32..=4).map(u32::count_ones).collect();
assert_eq!(counts, [0, 1, 1, 2, 1]);
```

`count_ones`, `trailing_zeros`, `leading_zeros`, `rotate_left` and
`is_power_of_two` avoid hand-written loops. `trailing_zeros(0)` returns the word
width, not a valid bit position; guard zero before indexing with it. Negating a
signed minimum to isolate its low bit overflows; the unsigned wrapping formula
above explicitly expresses modular arithmetic.

## Sources

Synthesized from pinned StructWeave [04-interview-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/04-interview-patterns.md)
and integer/collection pitfalls in [13-interview-trap-questions](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md).
See the Rust Reference's [overflow rules](https://doc.rust-lang.org/reference/expressions/operator-expr.html#overflow)
and standard [`str` semantics](https://doc.rust-lang.org/std/primitive.str.html).
Corrections include finite combination recursion, output-sensitive complexity,
Unicode LCS dimensions, empty-path stair semantics, checked counts, explicit
knapsack direction, nonnegative jumps, and width-checked unsigned bit operations.
