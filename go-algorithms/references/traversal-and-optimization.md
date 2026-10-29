# Traversal and optimization (families 10–14)

## Contents

10. [BFS/DFS](#10-bfsdfs)
11. [Backtracking](#11-backtracking)
12. [Dynamic programming](#12-dynamic-programming)
13. [Greedy](#13-greedy)
14. [Topological sort](#14-topological-sort)

## 10. BFS/DFS

Use integer IDs or node pointers as visited keys. A value node struct containing
`Neighbors []...` is not comparable and cannot be a map key; the source's generic
`map[Node]bool` template needs that concrete representation decision first.

**Graph BFS:** mark visited at enqueue; FIFO processes nondecreasing edge distance.
Start has distance zero; every newly discovered neighbor has parent distance+1.
This gives shortest paths for unweighted/equal-positive-weight edges, not arbitrary
weighted edges. Sparse adjacency lists: O(V+E) time and O(V) auxiliary state over
the reachable subgraph; collecting/storing the graph costs O(V+E). Scan all
vertices to cover disconnected components. A nil adjacency slice means no outgoing
edges; decide whether a missing start ID is invalid or an isolated vertex.
Use a slice/head queue as in [collections](collections-and-contracts.md), not a
new queue abstraction. For indefinite graphs, neither BFS nor DFS has a blanket
finite-completeness guarantee.

**Tree level order:** nil root gives empty output. At each iteration, freeze the
current frontier's size/end before enqueueing children; otherwise the current
level absorbs later levels. O(n) time, O(width) live frontier and O(n) collected
output. A head-index queue without compaction can retain O(n) backing storage,
even if the live frontier is smaller. Omit visited only for a real tree with no
cycles or shared descendants.

**DFS:** recursive calls or an explicit stack mark each vertex once. Standard
visited traversal costs O(V+E), **not enumeration of all paths**. Path enumeration
can be exponential; use path-local visitation to forbid repeated vertices on a
simple path and undo it on return. Iterative traversal marking on pop may enqueue
duplicates and use O(E) pending entries; marking on push bounds them by O(V) when
only visitation (not exact recursive finish order) is needed. To reproduce
postorder/finish states use stack frames with neighbor position. Recursion can
reach O(V) depth, including a linear tree; Go's growing stacks are not unbounded.

**Number of islands:** choose 4-neighbor connectivity and land/water symbols.
For each unvisited land cell, increment count and flood-fill the whole component.
The chapter mutates land to water; clone each row to preserve input or use a
visited matrix. Validate rectangular shape before relying on `len(grid[0])`, or
bound each neighbor by its own row length. Empty grid/empty rows yield zero.
O(cells) time for a rectangular bounded-degree grid; O(cells) worst-case explicit
stack/visited or recursion space. Do not claim O(1) space merely because the grid
itself marks visits. Reject unknown cell symbols if the input contract requires
binary cells.

Other tree/list operations (traversals, BST validation, depth, LCA, middle,
reversal and cycle detection) are retained in [collections](collections-and-contracts.md).
A heap supports Dijkstra as a collection use case; Dijkstra additionally requires
nonnegative edge weights and overflow-safe accumulated distances. Neither source
chapter implements a Dijkstra family; do not pretend it is one of three missing
families advertised by the source's “17 patterns” heading.

## 11. Backtracking

State = choices made, remaining choices, and constraints. Append a choice, recurse,
then undo every mutation (path length, used flag, counts). Copy a path before
saving; appending the live slice aliases storage and corrupts past answers.

**Subsets:** recurse with increasing start index; append a copy at every node.
For n distinct items, 2^n results, total output elements n*2^(n-1), so O(n*2^n)
time/output storage, O(n) path/stack excluding output. Empty input has **one empty
subset**, not zero subsets. Duplicate input yields duplicate value-subsets unless
you sort a clone and skip equal choices at the same recursion depth.

**Permutations:** use a bool per input index and recurse until path length n;
then copy path. For distinct items there are n! length-n outputs: O(n*n!) output
work/space, O(n) path/used/stack excluding output. Empty input has one empty
permutation. To deduplicate repeated values, sort a clone and skip an equal value
when the preceding equal index is unused at this depth. Reusing all choices
without a used set/remaining-depth bound is not “permutations” and can recurse
forever. Bound output for untrusted n; iterators save materialized output space
only if production stops immediately when yield returns false.

Complete representative subset implementation (index-distinct semantics):

```go
func Subsets(nums []int) [][]int {
    result := make([][]int, 0)
    path := make([]int, 0, len(nums))
    var visit func(int)
    visit = func(start int) {
        saved := make([]int, len(path))
        copy(saved, path)
        result = append(result, saved)
        for i := start; i < len(nums); i++ {
            path = append(path, nums[i])
            visit(i+1)
            path = path[:len(path)-1]
        }
    }
    visit(0)
    return result
}
```

## 12. Dynamic programming

Define state meaning, recurrence, base cases, valid index domain and dependency
order before writing a table. Memoization = top-down caching; tabulation =
bottom-up dependency order. Count reachable states * transitions per state, plus
key/comparison/copy cost. A recurrence with cycles is not made valid by a map.
Rolling storage is sound only when no overwritten state is needed later.

**Climbing stairs:** for n steps with moves 1 or 2, use ways(0)=1, ways(1)=1,
ways(n)=ways(n-1)+ways(n-2). Reject negative n. The source returns 0 for n=0;
that is inconsistent with the empty-sequence counting convention used here, so
this bundle chooses and documents 1. Rolling previous-two values: O(n) additions,
O(1) storage, but finite machine integers overflow for modest n; checked addition
must signal overflow, or use `math/big.Int` and account for growing digit costs.
The generic 1D template must not index dp[1] for an empty/single-state table.

**Longest common subsequence:** state dp[i][j] is LCS length of prefixes i,j.
Zero row/column are zero. If final units match, dp[i-1][j-1]+1; else
max(dp[i-1][j],dp[i][j-1]). The chapter indexes bytes; rune LCS should decode
strings first and explicitly exclude grapheme/normalization semantics. Empty
input gives zero. Time O(m*n), full-table space O(m*n), two-row/one-row length-only
space O(min(m,n)) plus rune conversion O(m+n). Reconstructing a subsequence needs
additional decisions/storage; do not claim it comes free from a rolling length
calculation. These are lengths, so they fit in int when the inputs do.

The generic 2D table recipe needs allocated independent rows, base row/column
initialization and loop ordering that satisfies the chosen recurrence. An arbitrary
“DP is O(n)” claim is meaningless without states and transitions.

## 13. Greedy

Require an exchange or stays-ahead proof; local convenience is not evidence of
global optimality. Sorting, if needed, is part of the total cost, but greedy does
not inherently cost O(n log n).

**Jump game:** for nonnegative maximum forward jump lengths, keep the furthest
reachable index. If current i exceeds reach, impossible; otherwise extend reach.
All indices up to reach are accessible, so the furthest boundary dominates any
shorter route. O(n)/O(1), no mutation. Define empty input as vacuously reachable
(as the source does) or reject it explicitly. Avoid `i+nums[i]` overflow by
checking `nums[i]>=last-i` first and returning true when the end is reachable;
only then add if the bounded sum remains below last. Negative lengths violate
the model and must be checked first if input is untrusted.

**Task scheduler:** unit-duration uppercase A–Z tasks, one CPU, reorder freely,
uniform nonnegative cooldown c between equal tasks. Count max frequency f and
number q tied at f. Minimum slots `max(total,(f-1)*(c+1)+q)` because the most
frequent tasks force f-1 separated frames, while other tasks can fill idle slots.
This computes a **length**, not a schedule. Empty task input must return zero
before computing q; otherwise the source counts all 26 zero frequencies as ties
and can return a positive nonsense answer. Validate alphabet/cooldown and check
product/addition overflow. Fixed alphabet gives O(total+26) time, O(26) space;
variable durations, per-task cooldowns or multiple CPUs invalidate this formula.

## 14. Topological sort

Kahn's algorithm: graph directed dependency->dependent, indegree = number of
unprocessed incoming edges. Initially enqueue **every** zero-indegree vertex,
including isolated vertices. Pop, append to result, decrement each outgoing
edge's destination, enqueue on transition to zero. Every emitted vertex has all
prerequisites emitted; remove each edge once. Finish only if result length == V.
If shorter, a cycle remains; report failure and do not present the partial list
as complete. Empty graph is a successful empty order, not a cycle.

Time O(V+E), adjacency O(V+E), indegrees/queue/output O(V). Repeated edge records
are fine if counted both in indegree and adjacency; deduplicating one side alone
breaks the invariant. Validate nonnegative V and endpoints before indexing.
Multiple valid orders are normal: tests should check each edge's ordering, not
one incidental permutation, unless deterministic tie order is explicitly required.
An initial numeric vertex scan and input-ordered adjacency yield deterministic
FIFO order; lexicographically smallest order needs a heap and O((V+E) log V)-style
accounting rather than asserting it for a plain FIFO.

The runnable `Topological` in [algorithms.go](../examples/algorithms.go) accepts
edge pairs `[from,to]`, rejects invalid IDs and cycles, and returns no partial
result on error. The source course-prerequisite pair convention is `[course,
prerequisite]` instead: reverse that input pair when adapting it.
