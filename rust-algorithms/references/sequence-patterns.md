# Sequence patterns: 1–9

Each fence is a standalone, dependency-free example. Preconditions stated as
caller obligations are not silently validated in a hot loop; validate untrusted
input once at the boundary. `n` counts elements, and text algorithms below count
Unicode scalars unless explicitly stated otherwise.

## 1. Two pointers

**Use:** sorted pair search, filtering/compaction, palindromes, container area.
For sorted pairs, if the endpoint sum is too small, the left endpoint cannot
pair with any remaining smaller right endpoint; the symmetric argument removes
the right endpoint when too large. The remaining region is `[left, right)`.
Sorted ascending input is required; checking it costs O(n). Pair search is O(n)
time/O(1) space. Widen two `i32` operands before adding.

```rust
fn sorted_pair(nums: &[i32], target: i64) -> Option<(usize, usize)> {
    let (mut left, mut right) = (0, nums.len());
    while right - left >= 2 {
        let last = right - 1;
        let sum = i64::from(nums[left]) + i64::from(nums[last]);
        match sum.cmp(&target) {
            std::cmp::Ordering::Less => left += 1,
            std::cmp::Ordering::Greater => right -= 1,
            std::cmp::Ordering::Equal => return Some((left, last)),
        }
    }
    None
}
assert_eq!(sorted_pair(&[], 0), None);
assert_eq!(sorted_pair(&[3], 6), None);
assert_eq!(sorted_pair(&[2, 2], 4), Some((0, 1)));
assert_eq!(sorted_pair(&[i32::MAX, i32::MAX], 4_294_967_294), Some((0, 1)));
```

For compaction maintain `write <= read`; retained elements occupy `[0, write)`.
Use `Vec::retain` or sorted `Vec::dedup` when possible. If returning a new logical
length from a mutable slice, the tail remains unspecified; truncate a vector
explicitly if callers need its physical length changed.

Container area requires nonnegative heights: move the shorter endpoint because
reducing width cannot improve area while keeping that limiting height. Use an
unsigned height type and checked/widened `height * width`; no area exists for
fewer than two bars. Palindromes can compare a double-ended `chars()` iterator
without collecting. Filtering and case folding are separate requirements: do
not advertise ASCII lowercase as Unicode-insensitive equality.

## 2. Sliding window

**Use:** contiguous fixed-size aggregates or variable regions whose invalidity
can be repaired by moving the left boundary forward. A window sum with arbitrary
negative inputs is fine at **fixed width**; monotone sum-threshold shrinking is
not. Every element enters/leaves at most once, giving O(n) time.

Fixed-width semantics: reject `k == 0` and `k > len` with `Ok(None)`. Accumulate in
`i64` with checked arithmetic; overflow returns an error rather than a fabricated
maximum. Space is O(1). Inputs are `i32`, so after a representable window sum,
removing one element can still overflow in theory; every step is checked.

```rust
fn max_window(nums: &[i32], k: usize) -> Result<Option<i64>, &'static str> {
    if k == 0 || k > nums.len() {
        return Ok(None);
    }
    let mut sum = 0_i64;
    for &x in &nums[..k] {
        sum = sum.checked_add(i64::from(x)).ok_or("sum overflow")?;
    }
    let mut best = sum;
    for i in k..nums.len() {
        sum = sum.checked_sub(i64::from(nums[i - k])).ok_or("sum overflow")?;
        sum = sum.checked_add(i64::from(nums[i])).ok_or("sum overflow")?;
        best = best.max(sum);
    }
    Ok(Some(best))
}
assert_eq!(max_window(&[], 1), Ok(None));
assert_eq!(max_window(&[1], 0), Ok(None));
assert_eq!(max_window(&[-5, -2, -3], 2), Ok(Some(-5)));
assert_eq!(max_window(&[i32::MAX, i32::MAX], 2), Ok(Some(4_294_967_294)));
```

For longest distinct substring, the last position of each scalar is sufficient;
no `Vec<char>` or frequency-shrinking loop is needed. `left` never moves backward.
Expected O(n) time and O(d) space for d distinct scalars.

```rust
use std::collections::HashMap;
fn longest_distinct(s: &str) -> usize {
    let mut last_seen = HashMap::new();
    let (mut left, mut best) = (0, 0);
    for (right, c) in s.chars().enumerate() {
        if let Some(previous) = last_seen.insert(c, right) {
            left = left.max(previous + 1);
        }
        best = best.max(right + 1 - left);
    }
    best
}
assert_eq!(longest_distinct(""), 0);
assert_eq!(longest_distinct("abba"), 2);
assert_eq!(longest_distinct("é日éa"), 3);
```

For minimum covering window, retain multiplicities and count how many distinct
required scalars meet their quota. An empty target has the empty answer; return
before entering a shrink loop. This implementation minimizes byte length, returns
an original borrowed substring, and uses `char_indices` for valid boundaries.
Expected O(source bytes + target bytes) time/O(distinct target scalars) space;
there is no copied source character array. Each scalar is visited at most twice.

```rust
use std::collections::HashMap;
fn minimum_cover<'a>(s: &'a str, target: &str) -> Option<&'a str> {
    if target.is_empty() {
        return Some(&s[..0]);
    }
    let mut counts: HashMap<char, (usize, usize)> = HashMap::new();
    for c in target.chars() {
        counts.entry(c).or_default().0 += 1;
    }
    let required = counts.len();
    let mut formed = 0;
    let mut left = 0;
    let mut left_chars = s.char_indices();
    let mut best: Option<(usize, usize)> = None;
    for (offset, c) in s.char_indices() {
        let end = offset + c.len_utf8();
        if let Some((need, have)) = counts.get_mut(&c) {
            *have += 1;
            if *have == *need { formed += 1; }
        }
        while formed == required {
            if best.map_or(true, |(a, b)| end - left < b - a) {
                best = Some((left, end));
            }
            let (start, removed) = left_chars.next().unwrap();
            left = start + removed.len_utf8();
            if let Some((need, have)) = counts.get_mut(&removed) {
                if *have == *need { formed -= 1; }
                *have -= 1;
            }
        }
    }
    best.map(|(a, b)| &s[a..b])
}
assert_eq!(minimum_cover("abc", ""), Some(""));
assert_eq!(minimum_cover("", "a"), None);
assert_eq!(minimum_cover("ADOBECODEBANC", "ABC"), Some("BANC"));
assert_eq!(minimum_cover("日aé日", "é日"), Some("é日"));
assert_eq!(minimum_cover("aa", "aaa"), None);
```

If the contract minimizes **scalar count**, track scalar ordinals alongside byte
boundaries and compare those lengths instead. Byte and scalar minima need not
coincide. Grapheme matching needs a different tokenizer.

## 3. Binary search

**Use:** sorted membership/boundaries or an answer domain with a monotone
feasibility predicate. Maintain a half-open candidate region; each iteration
strictly reduces it. `left + (right - left) / 2` avoids midpoint addition overflow.
O(log n) comparisons/O(1) space; multiply by feasibility-check cost for answer
search. Do not sort merely to search once unless reordering/cost is acceptable.

```rust
fn first_true(n: usize, mut predicate: impl FnMut(usize) -> bool) -> usize {
    let (mut left, mut right) = (0, n);
    while left < right {
        let mid = left + (right - left) / 2;
        if predicate(mid) { right = mid; } else { left = mid + 1; }
    }
    left // n means no true position.
}
let values = [1, 2, 2, 4];
assert_eq!(values.partition_point(|&x| x < 2), 1); // Lower bound.
assert_eq!(values.partition_point(|&x| x <= 2), 3); // Upper bound.
assert_eq!(first_true(values.len(), |i| values[i] >= 2), 1);
assert_eq!(first_true(0, |_| panic!("empty domain")), 0);
assert_eq!(first_true(3, |_| false), 3);
assert_eq!(values.binary_search(&3), Err(3));
```

Rotated sorted search can discard a sorted half in O(log n) when elements are
distinct. Duplicates can make both ends/mid equal and hide which half is sorted;
shrinking ambiguous endpoints can degrade to O(n). State this precondition,
not an unconditional logarithmic guarantee. `partition_point` similarly requires
a true-prefix/false-suffix predicate, not an arbitrary condition.

## 4. Prefix sum

**Use:** static range sums and subarray-sum counting. `prefix[i]` is the sum of
`nums[..i]`; use half-open query ranges `[start, end)` consistently. Build O(n),
query O(1), storage O(n). Prefix and subtraction overflow are separate checks.

```rust
struct Prefix(Vec<i64>);
impl Prefix {
    fn new(nums: &[i32]) -> Option<Self> {
        let mut sums = Vec::with_capacity(nums.len().checked_add(1)?);
        sums.push(0_i64);
        for &x in nums {
            sums.push(sums.last()?.checked_add(i64::from(x))?);
        }
        Some(Self(sums))
    }
    fn sum(&self, start: usize, end: usize) -> Option<i64> {
        if start > end { return None; }
        self.0.get(end)?.checked_sub(*self.0.get(start)?)
    }
}
let p = Prefix::new(&[i32::MAX, i32::MAX, -1]).unwrap();
assert_eq!(p.sum(0, 2), Some(4_294_967_294));
assert_eq!(p.sum(1, 1), Some(0));
assert_eq!(p.sum(2, 1), None);
assert_eq!(p.sum(0, 4), None);
assert_eq!(Prefix::new(&[]).unwrap().sum(0, 0), Some(0));
```

For number of subarrays summing to k, seed prefix-frequency map with `{0: 1}`.
At each new prefix `s`, add the prior count of `s - k` **before** inserting `s`;
otherwise an empty subarray is counted when k is zero. This works with negative
values in expected O(n) time/O(n) space. Check prefix arithmetic, `s-k`, frequency
and answer counts independently; the number of subarrays can be quadratic.
Product-except-self uses left/right accumulators in O(n) time/O(1) space beyond
output and naturally handles zeros, but needs a checked product or established
bound. Do not divide by the total product or assume `i32` multiplication fits.

## 5. Monotonic stack

**Use:** next greater/smaller values, temperature waiting times, histogram areas.
Store unresolved **indices**, not just values. Each index is pushed/popped at
most once: O(n) time/O(n) space. Equality handling encodes strict versus non-strict
queries. Return `Option<usize>` rather than mixing a sentinel with valid values.

```rust
fn next_greater_index(nums: &[i32]) -> Vec<Option<usize>> {
    let mut answer = vec![None; nums.len()];
    let mut stack: Vec<usize> = Vec::new();
    for i in 0..nums.len() {
        while let Some(&j) = stack.last() {
            if nums[j] >= nums[i] { break; }
            stack.pop();
            answer[j] = Some(i);
        }
        stack.push(i);
    }
    answer
}
assert!(next_greater_index(&[]).is_empty());
assert_eq!(next_greater_index(&[2, 2, 3, -1]), [Some(2), Some(2), None, None]);
```

Daily temperatures converts `Some(next)` to `next - current`, keeping `usize`
distances rather than narrowing to `i32`. Histogram stacks maintain increasing
heights; on popping height h at position i, its width ends at i and starts just
after the new stack top (or zero). Flush at the end without cloning the input;
a virtual sentinel avoids allocating a copied heights vector. Require
nonnegative heights and checked/widened area multiplication.

## 6. Hash map patterns

**Use:** complements, frequencies, equivalence grouping. In two-sum the map only
contains *earlier* indices, preventing reuse of the current item. Expected O(n)
time/O(n) space. Here target and values are `i32`; subtraction is widened so the
complement may safely be outside the `i32` domain and simply not match.

```rust
use std::collections::HashMap;
fn pair(nums: &[i32], target: i32) -> Option<(usize, usize)> {
    let mut seen = HashMap::new();
    for (i, &x) in nums.iter().enumerate() {
        let complement = i64::from(target) - i64::from(x);
        if let Some(&j) = seen.get(&complement) { return Some((j, i)); }
        seen.insert(i64::from(x), i);
    }
    None
}
assert_eq!(pair(&[], 0), None);
assert_eq!(pair(&[3], 6), None);
assert_eq!(pair(&[3, 3], 6), Some((0, 1)));
assert_eq!(pair(&[i32::MIN, i32::MAX], -1), Some((0, 1)));
```

- Count with `*entry(key).or_insert(0_usize) += 1`; counts of a finite slice fit
  its length. Persistent streaming counters need an overflow policy.
- Top-k frequent values: buckets indexed by frequency cost O(n + d) space and
  expected O(n) time; a size-k heap costs O(d log k) after counting and O(k)
  additional space. Handle k=0 before collecting; define k>d and tie semantics.
  Hash iteration does not give deterministic tie order.
- Anagram grouping: sort `Vec<char>` keys for exact Unicode scalar equivalence,
  O(sum L·log L) key work. A `[usize; 26]` signature is O(L) only with validated
  lowercase ASCII. Normalization/case folding are not implicit. Consume owned
  strings into result groups instead of cloning them; sort output only if the
  contract requires deterministic order.

## 7. Two heaps

**Use:** online median. Invariants: all lower-half values ≤ all upper-half values;
lower has either the same number of values or one extra. Insertion O(log n)
amortized including growth, median O(1), total storage O(n). Empty median is
`None`. Convert before adding; the mean of any two `i32` values is exact in f64.

```rust
use std::cmp::Reverse;
use std::collections::BinaryHeap;
#[derive(Default)]
struct Median {
    lower: BinaryHeap<i32>,
    upper: BinaryHeap<Reverse<i32>>,
}
impl Median {
    fn insert(&mut self, x: i32) {
        self.lower.push(x);
        self.upper.push(Reverse(self.lower.pop().unwrap()));
        if self.upper.len() > self.lower.len() {
            self.lower.push(self.upper.pop().unwrap().0);
        }
    }
    fn get(&self) -> Option<f64> {
        let low = f64::from(*self.lower.peek()?);
        if self.lower.len() > self.upper.len() { return Some(low); }
        Some((low + f64::from(self.upper.peek()?.0)) / 2.0)
    }
}
let mut median = Median::default();
assert_eq!(median.get(), None);
median.insert(i32::MIN);
median.insert(i32::MAX);
assert_eq!(median.get(), Some(-0.5));
median.insert(0);
assert_eq!(median.get(), Some(0.0));
```

Sliding-window median also needs deletion: the insertion-only structure does not
support arbitrary removal. Choose a multiset design or carefully specified lazy
deletion with logical sizes; do not paste this structure and claim O(log n)
window updates without accounting for expiry.

## 8. Merge intervals

**Use:** union of ranges. This implementation uses **closed** intervals `[start,
end]`, requires `start <= end`, and merges touching endpoints. For half-open
intervals decide whether touching ranges should coalesce; strict overlap uses
`start < last_end`, and empty intervals need an explicit policy. Sorted scan
invariant: output is disjoint and represents exactly the processed union.
O(n log n) time, O(n) output, O(1) auxiliary space beyond output.

```rust
fn merge(intervals: &mut [(i32, i32)]) -> Vec<(i32, i32)> {
    assert!(intervals.iter().all(|&(a, b)| a <= b), "reversed interval");
    intervals.sort_unstable();
    let mut result: Vec<(i32, i32)> = Vec::new();
    for &(start, end) in intervals.iter() {
        if let Some(last) = result.last_mut() {
            if start <= last.1 {
                last.1 = last.1.max(end);
                continue;
            }
        }
        result.push((start, end));
    }
    result
}
assert!(merge(&mut []).is_empty());
assert_eq!(merge(&mut [(3, 5), (1, 3), (8, 8)]), [(1, 5), (8, 8)]);
```

Insert-one-interval can be O(n) without sorting **only** if existing intervals
are already sorted and disjoint under the same endpoint policy: emit earlier
intervals, expand the new one while overlapping, then emit the rest. Use pairs
or a struct, not `Vec<Vec<i32>>` that permits malformed endpoint counts. Integer
adjacency is distinct from touching; avoid `end + 1` overflow if adjacency merges.

## 9. Cyclic sort

**Use:** values map directly to bounded positions. Here n values must be distinct
members of `0..=n`, with one missing value. Values below n belong at their own
index; n has no slot. Every swap places a value correctly. O(n) time/O(1) space,
input reordered. This checked version reports invalid range/duplicates; on a
duplicate error the input may already be partially reordered.

```rust
fn missing(nums: &mut [usize]) -> Result<usize, &'static str> {
    let n = nums.len();
    if nums.iter().any(|&x| x > n) { return Err("value outside 0..=n"); }
    let mut i = 0;
    while i < n {
        let destination = nums[i];
        if destination == n || destination == i {
            i += 1;
        } else if nums[destination] == destination {
            return Err("duplicate value");
        } else {
            nums.swap(i, destination);
        }
    }
    let mut absent = None;
    for (i, &value) in nums.iter().enumerate() {
        if i != value {
            if absent.is_some() { return Err("duplicate n"); }
            absent = Some(i);
        }
    }
    Ok(absent.unwrap_or(n))
}
assert_eq!(missing(&mut []), Ok(0));
assert_eq!(missing(&mut [3, 0, 1]), Ok(2));
assert_eq!(missing(&mut [0, 1]), Ok(2));
assert!(missing(&mut [1, 1]).is_err());
assert!(missing(&mut [2, 2]).is_err());
assert!(missing(&mut [3, 0]).is_err());
```

For values `1..=n`, the destination is `value - 1` only after validating that
range. Floyd duplicate detection is a different, read-only functional-graph
technique: the classic n+1-element problem requires every value in `1..=n` and
the promised duplicate structure. It is O(n) time/O(1) space but is not a general
replacement for duplicate detection on arbitrary integers.

## Sources

Original implementations and contracts synthesized from pinned StructWeave
[04-interview-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/04-interview-patterns.md)
and [03-data-structures](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/03-data-structures.md).
Collection, string, ordering, and arithmetic guarantees are documented in
[collections and contracts](collections-and-contracts.md). Empty-input
underflow, empty minimum-window targets, overflow, rotated-search duplicates,
invalid cyclic-sort domains, and missing median semantics are deliberately
corrected rather than preserved from the examples.
