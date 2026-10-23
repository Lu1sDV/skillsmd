# Search and optimization patterns 11–13, 17

## Contents

- [11. Backtracking](#11-backtracking)
- [Adapting the search safely](#adapting-the-search-safely)
- [12. Dynamic programming](#12-dynamic-programming)
- [Unbounded coin change: ascending capacity](#unbounded-coin-change-ascending-capacity)
- [0/1 knapsack: descending capacity](#01-knapsack-descending-capacity)
- [Longest common / increasing subsequences](#longest-common--increasing-subsequences)
- [13. Greedy](#13-greedy)
- [17. Bit manipulation](#17-bit-manipulation)

Choose the state model before optimizing loops. Backtracking enumerates choices;
DP merges histories with equivalent futures; greedy discards alternatives only
with a proof. Integer operation counts below assume bounded operand sizes.
Examples are finite and stdlib-only; assertions are checks, not input validation.

## 11. Backtracking

Maintain a partial answer, enumerate valid next choices, recurse, then undo every
mutation. Copy a finished answer rather than appending the shared working list.
Sort a copy and skip **equal choices at the same depth** for unique-value subsets;
skipping every repeated value would incorrectly remove subsets like `[1, 1]`.

```pycon
>>> def unique_subsets(values):
...     ordered = sorted(values)
...     result, path = [], []
...     def visit(start):
...         result.append(path.copy())
...         for index in range(start, len(ordered)):
...             if index > start and ordered[index] == ordered[index - 1]:
...                 continue
...             path.append(ordered[index])
...             visit(index + 1)
...             path.pop()
...     visit(0)
...     return result
>>> source = [2, 1, 1]
>>> assert unique_subsets(source) == [[], [1], [1, 1], [1, 1, 2], [1, 2], [2]]
>>> assert source == [2, 1, 1]
>>> assert unique_subsets([]) == [[]]
>>> answers = unique_subsets([1])
>>> answers[0].append(9)
>>> assert answers[1] == [1]
>>> from itertools import combinations, permutations, product
>>> assert list(combinations([1, 2, 3], 0)) == [()]
>>> assert list(permutations([], 0)) == [()]
>>> assert list(permutations([1, 1])) == [(1, 1), (1, 1)]
>>> assert list(product([0, 1], repeat=2)) == [(0, 0), (0, 1), (1, 0), (1, 1)]

```

Subsets take O(n·2^n) time/output size in the distinct-value worst case; extra
state O(n) for path/recursion plus sorted copy, excluding output. Recursive
examples are for bounded problem sizes, not arbitrary input-controlled depth.
Combinatorial iterators treat items as distinct by **position**, not value;
`combinations([1,1],1)` therefore repeats the value. They pool finite inputs and
consume memory even when output is lazy. Generators cannot make exponential
output linear. `set(permutations(...))` deduplicates after doing all the work;
for many duplicates use a value→remaining-count map during generation.

### Adapting the search safely

| Task | State and next choice | Boundary / cost obligation |
|---|---|---|
| Permutations | Unused positions/counts; emit when length n | O(n·n!) materialized worst case; copied `remaining` slices at each depth can add O(n²) live storage; in-place swaps must be restored |
| Choose k of 1..n | Increasing next value; choose only while enough values remain | Require `0 <= k <= n`; k=0 yields `[[]]`; materialized cost at least k·C(n,k), plus search overhead |
| Reusable combination sum | Nondecreasing candidate index; recurse at same index with reduced remainder | Require distinct **positive integers**, target ≥0; zero/negative candidates break termination, duplicate candidates duplicate results |
| N-Queens | One row per depth; occupied columns, row−col and row+col diagonals | Undo all three sets; n≥0; n=0 convention is one empty placement; enumeration remains factorial/exponential with board output cost |

For reusable combination sum: sort unique positive candidates, keep `(start,
remaining, path)`, emit a copy when remaining is zero, and break the candidate
loop once candidate > remaining. A step strictly decreases remaining, giving
depth ≤ target/min(candidate); empty candidates yield `[[]]` only for target zero.
Time is output/search-tree dependent, not universally O(2^n). For n-queens build
boards only at complete solutions; producing each board costs O(n²) characters.
When a generator can suspend inside mutated shared state, restoration belongs
in `try/finally` if cancellation/early close can escape that state.

## 12. Dynamic programming

1. Define a state that contains all information needed for future choices.
2. Write base/impossible states and the recurrence before storage optimization.
3. Prove dependencies are acyclic and choose a valid evaluation order.
4. Budget states × transitions, plus value sizes and reconstruction data.
5. Optimize retained rows/cells only after identifying which previous values
   each update needs; in-place update direction changes semantics.

Top-down memoization is useful for sparse reachable states; bottom-up avoids
interpreter recursion depth and often has predictable memory. `@cache` requires
hashable arguments and retains keys/results. Capture a fixed immutable problem
inside a local cached function instead of passing an unhashable grid/list, and
do not mutate captured data while cache entries remain valid.

```pycon
>>> from functools import cache
>>> def fibonacci(n):
...     if type(n) is not int or n < 0:
...         raise ValueError('nonnegative integer required')
...     @cache
...     def at(index):
...         if index < 2:
...             return index
...         return at(index - 1) + at(index - 2)
...     return at(n)
>>> assert fibonacci(0) == 0 and fibonacci(10) == 55
>>> def stair_ways(n):
...     if type(n) is not int or n < 0:
...         raise ValueError('nonnegative integer required')
...     previous, current = 1, 1
...     for _ in range(n):
...         previous, current = current, previous + current
...     return previous
>>> assert [stair_ways(n) for n in range(5)] == [1, 1, 2, 3, 5]

```

There is one way to climb zero stairs (the empty sequence), unlike Fibonacci's
zero base. Fibonacci has O(n) distinct states/additions and O(n) cached entries
and recursion depth; the iterative stairs recurrence keeps O(1) integer objects,
not O(1) **bits**. These growing integers make arithmetic/storage costs larger
than unit-cost operation counts. Memoization does not make large recursive n safe.

### Unbounded coin change: ascending capacity

`dp[x]` is minimum coins for x using processed coin denominations; ascending x
permits using the same denomination again. No solution is `None`, distinct from
zero coins needed for amount zero. Inputs are read-only.

```pycon
>>> def fewest_coins(coins, amount):
...     if type(amount) is not int or amount < 0:
...         raise ValueError('invalid amount')
...     if any(type(coin) is not int or coin <= 0 for coin in coins):
...         raise ValueError('positive integer coins required')
...     impossible = amount + 1
...     dp = [0] + [impossible] * amount
...     for coin in coins:
...         for value in range(coin, amount + 1):
...             dp[value] = min(dp[value], dp[value - coin] + 1)
...     return None if dp[amount] == impossible else dp[amount]
>>> assert fewest_coins([1, 3, 4], 6) == 2  # Greedy 4+1+1 is worse.
>>> assert fewest_coins([2], 3) is None
>>> assert fewest_coins([], 0) == 0 and fewest_coins([], 1) is None
>>> assert fewest_coins([2, 2], 4) == 2
>>> fewest_coins([0, 1], 2)
Traceback (most recent call last):
...
ValueError: positive integer coins required

```

O(c·A + c + A) time, O(A) state, for c coins and amount A, including validation
and initialization (even when one dimension is zero). This is pseudopolynomial
in the numeric amount, not polynomial in its bit-length encoding. Duplicated
coins do not change the minimum but waste transitions; for **counting ways**,
duplicate denominations must be deduplicated and coin-first vs amount-first
loops distinguish unordered combinations from ordered sequences.

### 0/1 knapsack: descending capacity

Each item may be taken at most once. Descending capacity means `dp[room-weight]`
still belongs to the previous-item state; ascending order would permit reuse.
This version permits selecting no items, supports negative values by ignoring
unprofitable choices, and requires strictly positive integer weights.

```pycon
>>> def knapsack(weights, values, capacity):
...     if type(capacity) is not int or capacity < 0 or len(weights) != len(values):
...         raise ValueError('invalid capacity or mismatched items')
...     if any(type(weight) is not int or weight <= 0 for weight in weights):
...         raise ValueError('positive integer weights required')
...     dp = [0] * (capacity + 1)
...     for weight, value in zip(weights, values, strict=True):
...         for room in range(capacity, weight - 1, -1):
...             dp[room] = max(dp[room], dp[room - weight] + value)
...     return dp[capacity]
>>> assert knapsack([2], [3], 4) == 3  # Not 6: no item reuse.
>>> assert knapsack([2, 3, 4], [3, 4, 5], 5) == 7
>>> assert knapsack([], [], 0) == 0
>>> assert knapsack([1], [-2], 2) == 0
>>> knapsack([2], [], 3)
Traceback (most recent call last):
...
ValueError: invalid capacity or mismatched items

```

O(n·C+n+C) time, O(C) state. Space optimization loses the straightforward item
traceback; retain predecessor/item layers or reconstruct deliberately if actual
items, rather than optimum value alone, are required.

### Longest common / increasing subsequences

LCS state is the optimum for two prefixes. Match → diagonal+1; mismatch → max
of previous-row same-column and current-row previous-column. Code points, not
bytes/grapheme clusters, are compared; no normalization is implicit.

```pycon
>>> def lcs_length(first, second):
...     if len(first) < len(second):
...         first, second = second, first
...     previous = [0] * (len(second) + 1)
...     for char in first:
...         current = [0]
...         for column, other in enumerate(second, 1):
...             current.append(previous[column - 1] + 1 if char == other
...                            else max(previous[column], current[-1]))
...         previous = current
...     return previous[-1]
>>> assert lcs_length('a🙂b', '🙂b') == 2
>>> assert lcs_length('', 'abc') == 0 and lcs_length('abc', 'def') == 0
>>> from bisect import bisect_left
>>> def lis_length(values):
...     tails = []
...     for value in values:
...         index = bisect_left(tails, value)
...         if index == len(tails):
...             tails.append(value)
...         else:
...             tails[index] = value
...     return len(tails)
>>> assert lis_length([]) == 0
>>> assert lis_length([2, 2, 2]) == 1
>>> assert lis_length([3, 1, 2, 0, 4]) == 3

```

LCS uses O(m·n + m+n) time including empty-dimension behavior, O(min(m,n)+1)
auxiliary cells. LIS `tails[i]` is the smallest known final value for a strictly
increasing subsequence of length i+1. It is **not** necessarily an actual
subsequence. O(n log(n+1)) time/O(n) state; use `bisect_right` for nondecreasing
rather than strictly increasing. The basic O(n²) LIS recurrence uses
`dp[i]=1+max(dp[j] for j<i if a[j]<a[i], default=0)` and must return zero on empty
input instead of calling `max([])`.

## 13. Greedy

Require an exchange/stays-ahead proof; “local optimum” is not a selection rule.
For maximum count of nonoverlapping positive-duration half-open intervals,
choose earliest finish: replacing an optimum's first interval with the earliest
finisher leaves at least as much room for all later choices. Weighted interval
value is a different problem requiring DP, not this greedy rule.

```pycon
>>> def select_intervals(intervals):
...     ordered = sorted(((start, end) for start, end in intervals),
...                      key=lambda interval: (interval[1], interval[0]))
...     if any(start >= end for start, end in ordered):
...         raise ValueError('positive-duration intervals required')
...     result, last_end = [], None
...     for start, end in ordered:
...         if last_end is None or start >= last_end:
...             result.append((start, end))
...             last_end = end
...     return result
>>> assert select_intervals([]) == []
>>> assert select_intervals([(-4, -2), (-2, 0), (-3, 1)]) == [(-4, -2), (-2, 0)]
>>> from itertools import combinations
>>> candidates = [(0, 2), (0, 3), (2, 4), (3, 4), (4, 5)]
>>> for size in range(len(candidates) + 1):
...     for batch in combinations(candidates, size):
...         best = 0
...         for count in range(len(batch) + 1):
...             for chosen in combinations(batch, count):
...                 ordered = sorted(chosen)
...                 if all(a[1] <= b[0] for a, b in zip(ordered, ordered[1:])):
...                     best = max(best, count)
...         assert len(select_intervals(batch)) == best

```

O(n log n) time/O(n) sorting/copy state plus output; input unchanged. Ties have a
defined deterministic order here, not a unique mathematical solution.

For jump games, require nonnegative integer jump limits and define empty input.
Reachability tracks the farthest reachable index: an index beyond it is
unreachable. Minimum jumps groups reachable indices into BFS-like layers;
choose a new layer only at the previous frontier and report a stalled frontier,
rather than returning a plausible jump count for unreachable inputs.

```pycon
>>> def minimum_jumps(limits):
...     if any(type(limit) is not int or limit < 0 for limit in limits):
...         raise ValueError('nonnegative integer limits required')
...     if not limits:
...         return None  # No destination.
...     end = farthest = jumps = 0
...     for index in range(len(limits) - 1):
...         farthest = max(farthest, index + limits[index])
...         if index == end:
...             if farthest == end:
...                 return None
...             jumps += 1
...             end = farthest
...             if end >= len(limits) - 1:
...                 return jumps
...     return jumps
>>> assert minimum_jumps([2, 3, 1, 1, 4]) == 2
>>> assert minimum_jumps([1, 0, 1]) is None
>>> assert minimum_jumps([0]) == 0 and minimum_jumps([]) is None

```

O(n) time/O(1) auxiliary, including validation. A frontier includes every index
reachable in at most the current number of jumps; maximizing the next frontier
cannot miss a better path with that same jump count.

Gas-station selection requires equally sized nonempty gas/cost sequences and
nonnegative quantities. If total gas < total cost, impossible; otherwise scan
net differences, resetting candidate start after any negative running tank.
Every station in that failed segment is ruled out by its negative prefix, so
one pass suffices. Empty input has no starting station.
For equal-duration unit tasks on one processor with uniform nonnegative cooldown
c between identical labels, minimum slots are
`max(total_tasks, (max_count-1)*(c+1)+number_of_labels_at_max_count)`; empty tasks
return zero **before** `max`. This is not valid for different task durations or
per-task cooldowns. Counts require O(distinct labels) state, not universal O(1).

## 17. Bit manipulation

Python ints have arbitrary precision and bitwise operations behave as if there
were infinitely many two's-complement sign bits. `~x == -x-1`; right shifting a
negative value does not eventually reach zero. `int.bit_count()` counts ones in
the **absolute value**, not a chosen fixed-width representation. Specify width
when modeling machine registers/protocol fields, and bound width at an external
boundary so input cannot request unbounded allocation.

```pycon
>>> def toggle_unsigned(value, index, width):
...     if type(width) is not int or width <= 0:
...         raise ValueError('positive integer width required')
...     if type(index) is not int or not 0 <= index < width:
...         raise ValueError('bit outside width')
...     if type(value) is not int or not 0 <= value < (1 << width):
...         raise ValueError('value outside unsigned width')
...     return value ^ (1 << index)
>>> assert toggle_unsigned(0, 7, 8) == 128
>>> assert toggle_unsigned(255, 7, 8) == 127
>>> toggle_unsigned(0, -1, 8)
Traceback (most recent call last):
...
ValueError: bit outside width
>>> toggle_unsigned(-1, 0, 8)
Traceback (most recent call last):
...
ValueError: value outside unsigned width
>>> def power_of_two(value):
...     return value > 0 and value & (value - 1) == 0
>>> assert power_of_two(1024) and not power_of_two(0) and not power_of_two(-2)
>>> assert (-1).bit_count() == 1
>>> assert (-1 & ((1 << 8) - 1)).bit_count() == 8
>>> value, index = 0b1010, 2
>>> assert (value >> index) & 1 == 0            # Test
>>> assert value | (1 << index) == 0b1110      # Set
>>> assert value & ~(1 << 1) == 0b1000         # Clear

```

For unsigned width w, mask `x & ((1<<w)-1)` after an operation when wraparound is
intended. Decode a signed result by subtracting `1<<w` if its sign bit is set.
Bit operations and `bit_count` scale with the operand's representation; a single
operation is not unconditionally O(1). Negative shifts raise `ValueError`.

XOR cancellation finds a singleton only when exactly one value occurs once and
every other value occurs twice (or, more generally, only one has odd parity).
It does not validate multiplicity, and empty XOR zero is not a valid singleton.

```pycon
>>> from functools import reduce
>>> from operator import xor
>>> def singleton_among_pairs(values):
...     if not values:
...         raise ValueError('nonempty paired domain required')
...     return reduce(xor, values, 0)
>>> assert singleton_among_pairs([4, -2, 4]) == -2
>>> assert singleton_among_pairs([0]) == 0
>>> singleton_among_pairs([])
Traceback (most recent call last):
...
ValueError: nonempty paired domain required
>>> def bit_subsets(values):
...     return [[value for index, value in enumerate(values) if mask & (1 << index)]
...             for mask in range(1 << len(values))]
>>> assert bit_subsets([]) == [[]]
>>> assert bit_subsets([1, 2]) == [[], [1], [2], [1, 2]]

```

XOR uses O(n) bounded-width operations/O(1) integer accumulators under its stated
contract. For the “all other values appear three times” variant, maintain per-bit
counts modulo three over an explicitly bounded width and decode signed output,
or maintain two masks for residues one/two with carefully ordered updates;
normalizing to finite width avoids assuming machine overflow in Python.
Bit subsets enumerate positions (duplicates in input can duplicate output),
O(n·2^n) operations and output size under bounded masks, not O(n). Use backtracking
if constraints can prune most choices.

Semantics: [functools.cache](https://docs.python.org/3.11/library/functools.html#functools.cache),
[itertools combinatorics](https://docs.python.org/3.11/library/itertools.html),
[integer bit operations](https://docs.python.org/3.11/library/stdtypes.html#bitwise-operations-on-integer-types).
