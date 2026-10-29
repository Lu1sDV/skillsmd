# Collections and contracts

## Contents

- [Choose by operation](#choose-by-operation)
- [Slices, ownership and sorting](#slices-ownership-and-sorting)
- [Maps and sets](#maps-and-sets)
- [Stacks, queues and heaps](#stacks-queues-and-heaps)
- [Lists, trees and graphs](#lists-trees-and-graphs)
- [Generic helpers and version gates](#generic-helpers-and-version-gates)

## Choose by operation

Costs below assume fixed-size values and comparisons; include element/key work
for strings, aggregates and callbacks. Space includes backing storage, not just
slice headers. No container here is automatically safe for concurrent mutation.

| Structure | Useful operations / costs | Preconditions and limitations |
|---|---|---|
| Slice | Index O(1), scan/copy O(n), append amortized O(1), ordered insert/delete O(n) | Append may allocate and copy O(n); swap-delete O(1) loses order |
| Map / set | Expected O(1) lookup/insert/delete, O(n) scan under normal hashing | Not a worst-case guarantee; no ordering contract; keys must be comparable |
| Slice stack | Top/pop O(1), push amortized O(1), scan O(n) | Empty guard; zero removed pointer-bearing elements |
| Slice queue | Front/reslice O(1), enqueue amortized O(1) | Reslicing does not shift; retained storage/unused prefix matters |
| Ring queue | Amortized O(1) push/pop | Reuse slots; resize copies; fixed ring needs full policy |
| `container/list` | Known-element insertion/removal O(1), indexed search O(n) | Per-element allocation, pointers, `any` values; not inherently faster than slices |
| Heap | Build O(n), root O(1), push/pop/fix O(log n), arbitrary search O(n) | Maintain heap invariant; not a fully sorted sequence |
| BST | Search/insert/delete O(h), traversal O(n) | h can be n; logarithmic only with balancing/height assumptions |
| Adjacency list | Storage O(V+E), full traversal O(V+E) | Undirected edges stored twice; isolated vertices must be represented |
| Adjacency matrix | Storage O(V²), edge test O(1), full traversal O(V²) | Distinguish zero weight from absent edge |

## Slices, ownership and sorting

A slice is a descriptor over an array: length bounds indexing, capacity bounds
reslicing/append reuse. `sub := s[a:b]` and `s[:]` share elements; neither clones.
`sub := s[a:b:b]` stops append from overwriting the following elements, but writes
to existing elements still alias. `slices.Clone` copies elements shallowly;
clone each row separately for an independent `[][]T` matrix. Iterate each row's
own length when ragged input is supported. Validate rectangularity otherwise.

Nil and non-nil empty slices both have length zero; nil is distinguishable with
`== nil` and commonly JSON-encodes as `null` rather than `[]`. Empty non-nil
slices need not own a separate allocation. Slices cannot be compared with `==`
except against nil; `slices.Equal` compares elements and regards nil/empty as equal.
For float elements, NaN equality still needs an explicit problem policy.

Insertion/deletion/filtering mutate shared storage. Always assign the returned
slice from `slices.Insert`, `Delete`, `Compact` or append. `Compact` only removes
**adjacent** equals; sort first only if order may change. For stable arbitrary
order deduplication, use a seen map and append first occurrences. In-place filter:
write retained values to a prefix, `clear(s[newLen:])`, then reslice. The clear is
important for references retained by a longer-lived backing array. Swap-delete
also clears the old final slot. `clear` requires Go 1.21; Go 1.22+ slice shrinking
helpers such as `Delete` and `Compact` clear their obsolete tail elements.

Use `slices.Sort` for ordered values, `SortFunc` for custom order,
`SortStableFunc` when equal-key relative order matters. Comparison must be a strict
weak ordering. **Never return `a-b`**: integer overflow can reverse the sign.
`cmp.Compare(a,b)` gives a safe signed comparison; descending uses
`cmp.Compare(b,a)`. For multiple keys compare the first unequal key. NaN needs a
consistent float order; `cmp.Compare` supplies one (NaN before non-NaN).

Complete helper, usable with a sorted ascending input:

```go
import "sort"

func EqualRange(nums []int, target int) (int, int) {
    lower := sort.Search(len(nums), func(i int) bool { return nums[i] >= target })
    upper := sort.Search(len(nums), func(i int) bool { return nums[i] > target })
    return lower, upper // half-open; equal means absent
}
```

`sort.Search` returns n if no predicate is true. `slices.BinarySearch` returns
insertion index and found flag; never index with the result before checking.
Search is O(log n) comparisons; sorted insertion still shifts O(n). Sorting a
clone adds O(n) storage. `slices.Sort`/`SortFunc` are O(n log n) comparisons, but
callback and element movement cost still matter; do not assume zero workspace for
every sorting implementation, especially stable sorting. `slices.Min/Max` panic
on empty slices. `Contains/Index/Equal` scan; `Reverse` mutates in O(n).

The source sorts descending and then performs ascending `BinarySearch` on the same
slice; these operations are not compatible. Re-sort ascending or use a matching
`BinarySearchFunc` comparator.

## Maps and sets

Use `make(map[K]V)` or a literal before writes. Reads/delete/len/range on a nil map
are safe; writes panic. The comma-ok form distinguishes absent from a stored
zero. Assignment aliases the same map. `maps.Clone` is shallow; `maps.Copy` needs
a non-nil destination when there is anything to write and overwrites matching
keys. `maps.Equal` requires comparable values; use `EqualFunc` otherwise.
`DeleteFunc` mutates. Iteration order is **unspecified**, not a promise of a fresh
random permutation; sort keys for deterministic output.

Use struct keys, e.g. `struct{ Row, Col int }`, rather than stringifying tuples.
All fields must be comparable. Interface-containing keys can still panic at
runtime when the dynamic value is not comparable. `Set[any]` is not an exemption.
`map[T]struct{}` encodes membership; the empty value has size zero, but the map
and each key/entry still consume memory. `map[T]bool` is also fine when false vs
absent is not significant. No speculative Set class is needed.

Set union: insert keys from both maps, expected O(a+b) time and output space.
Intersection: iterate the smaller set and probe the other, expected O(min(a,b))
time plus result storage. Difference: iterate A, keep keys absent from B,
expected O(a). Counts, grouping, complement lookup and memoization are map
applications, not separate container types. Group-by-first-character must handle
empty strings and choose byte/rune semantics. Memoization needs complete state
keys and a separate visiting state for cycles; an answer cache alone is not cycle
detection.

## Stacks, queues and heaps

For parentheses, keep unmatched opening brackets on a stack; every closer must
match the top. Define whether non-brackets are rejected or ignored. Empty input
is valid. Time O(n), auxiliary space O(n). Do not make zero a sentinel for an
empty stack that may legitimately hold zero.

For one bounded BFS, a slice and head index are enough:

```go
// Complete traversal for integer vertex IDs; missing adjacency means no edges.
func BFS(graph map[int][]int, start int) []int {
    seen := map[int]bool{start: true}
    queue := []int{start}
    for head := 0; head < len(queue); head++ {
        for _, next := range graph[queue[head]] {
            if !seen[next] {
                seen[next] = true // mark at enqueue, not at dequeue
                queue = append(queue, next)
            }
        }
    }
    return queue // also the traversal order; O(reachable V+E), O(reachable V)
}
```

For pointer queues clear consumed slots if the queue outlives their processing.
`q = q[1:]` is also O(1), but may retain the original allocation and old pointers;
append may allocate because prefix capacity cannot be reused. No universal
"1000 operations" threshold justifies switching to a list. Use a ring/occasional
compaction for an indefinitely reused queue. A list dequeue must check
`Front()!=nil` before `Remove` and assertion of `Value`.

Heap array positions encode a complete binary tree: children of i are 2*i+1
and 2*i+2, parent for i>0 is (i-1)/2. A min-heap requires parent<=children,
not ordering between siblings; a max-heap reverses comparison. Let the stdlib
maintain these indices rather than duplicating sift code.

`container/heap` needs `Len/Less/Swap`, plus pointer-receiver `Push/Pop` that
append/remove the **last** slot. The package-level `heap.Pop` swaps/reorders to
extract the root; directly calling the method does not. Clear removed pointer
slots. `heap.Init` mutates O(n); `heap.Fix` repairs a changed priority in O(log n),
using tracked indices if items move. Top-k largest keeps a min-heap of size k;
validate 1 <= k <= n. Time O(n log(k+1)), space O(k); root is kth largest, not a
sorted top-k list. See [ordering](ordering-and-placement.md) and its runnable
median example for the actual heap interface rather than custom sift scaffolding.

## Lists, trees and graphs

Minimal node shapes (independent types; not a generic container framework):

```go
type ListNode struct {
    Value int
    Next *ListNode
}
type TreeNode struct {
    Value int
    Left, Right *TreeNode
}
```

Use nodes only when link identity/constant-time known-position edits matter.
For singly linked removal, the predecessor or head link is needed: a node alone
is not enough to remove an arbitrary final node in O(1). Traversal/length require
an acyclic chain or a cycle policy. Dummy head simplifies removing head matches.
Fast/slow finds the **second** middle for even lengths with the standard
`fast != nil && fast.Next != nil` loop; Floyd cycle detection is O(n)/O(1).
Reversal saves `next`, sets `current.Next=previous`, then advances; O(n)/O(1),
destructive, invalid for an unchecked cyclic list. Nil head is a valid empty list.

Trees require genuine acyclic parent-child ownership if traversal omits visited
tracking. Inorder is left/root/right (sorted only for a valid BST); preorder is
root/left/right (construction); postorder is left/right/root (child-dependent
work). Traversals cost O(n) plus O(h) stack and O(n) if collecting output. Max
depth uses `1+max(leftDepth,rightDepth)` with nil depth zero. Validate BST with
optional ancestor bounds, not just immediate children or MinInt/MaxInt sentinels;
decide whether duplicates are permitted. LCA compares node identity, not value;
the usual recursive split algorithm assumes **both targets exist** or it may
return the sole present target. Verify presence if absent targets are permitted.
Go GC reclaims unreachable trees; postorder is not required for ordinary freeing.

Graph representations, traversal, level snapshots, islands and topological sort
are detailed in [traversal](traversal-and-optimization.md). Use a visited set for
cyclic graphs; a rooted tree with shared children is a DAG, not necessarily a tree.

## Generic helpers and version gates

| Feature | First stable version | Use / caveat |
|---|---|---|
| Type parameters, `any`, `comparable` | Go 1.18 | Use a concrete type when only one is needed |
| `slices`, `maps`, `cmp`; built-in `min/max/clear` | Go 1.21 | Replace hand-written Contains/Index/Reverse/Min/Max wrappers |
| `cmp.Or` | Go 1.22 | First nonzero argument, not short-circuit evaluation |
| `maps.Keys/Values`, `slices.Collect/Sorted`, range over iterator functions | Go 1.23 | Keys/Values return iterators, not slices; iteration is unordered |
| Generic type aliases, `weak` | Go 1.24 | Neither requires a new collection framework |

`keys := slices.Sorted(maps.Keys(m))` is deterministic Go 1.23+ key collection.
Iterator producers must stop when `yield` returns false; collection consumes the
iterator and allocates storage. `cmp.Ordered` does not make arithmetic overflow
safe. Generic absolute value over signed integers fails on minimum integer unless
you reject it or return a suitable unsigned magnitude. Count/ordered-unique can
remain local loops; no need to build a generic utility library.

Weak-reference cache coverage from chapter 02: `weak.Make(ptr)` does not keep the
referent alive; `Value()` may return nil and a map lookup must handle that miss
and stale key cleanup. Initialize the map before insertion. Weak pointers are
not an eviction bound, ownership guarantee or replacement for explicit capacity;
a copied returned `V` is still shallow. Do not depend on when GC runs. The
optional chapter-06 LRU illustrates map-to-list-node indexing: move an accessed
node to front; evict tail and delete the matching map key on overflow. Validate
capacity (reject negative; define zero as no storage), and maintain head/tail
links. Expected O(1) operations, O(capacity) entries; `container/list` avoids
rewriting a doubly linked list when typed nodes are not needed.

Go 1.24's Swiss-table map implementation is an implementation detail, not a
portable complexity or "60% faster" contract. Benchmark a real workload/toolchain
before promising any percentage improvement.
