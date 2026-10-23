# Collections and contracts

## Contents

- [Selection and complexity](#selection-and-complexity)
- [Copies, aliasing, duplicates and empty inputs](#copies-aliasing-duplicates-and-empty-inputs)
- [Heaps: ordering is a contract](#heaps-ordering-is-a-contract)
- [Custom linked lists: identity, not value equality](#custom-linked-lists-identity-not-value-equality)
- [Trees and graph representations](#trees-and-graph-representations)
- [Numeric and iterator helpers](#numeric-and-iterator-helpers)

Use the built-ins unless link identity, ordered partitions or prefix lookup is
part of the problem. Costs describe conventional CPython containers with
bounded-cost element operations, not a Python-language performance guarantee.

## Selection and complexity

| Need | Choose | Important costs and limits |
|---|---|---|
| Random access, dynamic array, stack | `list` | Index O(1); append/end-pop amortized O(1), an individual resize O(n); front/middle shifts and membership O(n) |
| Fixed record, composite key | `tuple`, `namedtuple` | Index O(1), scan O(n); immutable outer record, not necessarily immutable/hashable contents |
| Key → value, counting/grouping | `dict`, `Counter`, `defaultdict` | Expected O(1) lookup/update per bounded-cost key, collision worst case O(n); iteration O(n) |
| Membership, deduplication | `set`, `frozenset` | Expected O(1) membership; no promised iteration order; immutable `frozenset` is hashable |
| Queue, both-ended worklist | `collections.deque` | O(1) endpoint operations, middle indexing O(n); `maxlen` silently evicts from opposite end on append |
| Repeated minimum, top-k | `heapq` on a list | `heapify` O(n); push/pop O(log n) heap adjustments (list growth amortized); root O(1); arbitrary search/delete O(n) |
| Sorted range boundaries | Sorted list + `bisect` | O(log n) comparisons for search, O(n) insertion; sort first |
| Reorderable eviction cache | `OrderedDict` | `move_to_end`, `popitem(last=False)`; use `lru_cache` for bounded pure-function memoization instead |
| Text | `str` | Immutable code-point sequence; slices/builds allocate; use `''.join(parts)` for predictable linear assembly in total output length |

Set union visits both inputs; intersection normally visits the smaller set;
difference visits the left set. These are expected hash-based bounds plus output
allocation and key cost. Sorting is stable, worst-case O(n log n) comparisons,
adaptive to existing runs; CPython may use O(n) temporary space even for
`list.sort()`. `sorted()` additionally creates a new list. Prefer `key=` (computed
once per item during sorting) over `cmp_to_key` unless ordering truly needs a
comparator. Reject NaN or define an explicit policy before ordered algorithms.

Tuple/list choices are about the contract, not “heterogeneous vs homogeneous”
requirements. `dict.popitem()` is LIFO, not arbitrary, on the targeted versions;
set pop is arbitrary. `d.keys()/items()/values()` are live views, not snapshots.
Avoid changing a container's size while traversing it.

## Copies, aliasing, duplicates and empty inputs

```pycon
>>> rows = [[0] * 2 for _ in range(2)]
>>> rows[0][0] = 7
>>> assert rows == [[7, 0], [0, 0]]
>>> shallow = rows.copy()
>>> shallow[0][1] = 8
>>> assert rows[0] == [7, 8]  # Only the outer list was copied.
>>> independent = [row.copy() for row in rows]
>>> independent[0][0] = 9
>>> assert rows[0][0] == 7
>>> assert list(dict.fromkeys([3, 1, 3, 2])) == [3, 1, 2]
>>> assert min([], default=None) is None
>>> assert list(zip([], [])) == []

```

`[[0] * cols] * rows` aliases each row. `dict.fromkeys(keys, [])` shares a single
list across keys; use a comprehension or `defaultdict(list)`. A shallow copy
preserves references intentionally; `deepcopy` recursively copies supported
objects with memoization, including cycles, but is not a substitute for an
ownership contract. `zip` truncates to the shorter iterable; use `strict=True`
when a length mismatch is an error. `zip(*[])` produces no columns: unpacking it
into two variables fails. Slices cost O(number copied), including reverse slices.

```pycon
>>> from collections import Counter, defaultdict, namedtuple, OrderedDict
>>> groups = defaultdict(list)
>>> for name, team in [('Ana', 'ops'), ('Bo', 'dev'), ('Cy', 'ops')]:
...     groups[team].append(name)
>>> assert groups['ops'] == ['Ana', 'Cy']
>>> assert groups.get('absent') is None and 'absent' not in groups
>>> counts = Counter('aab')
>>> assert counts['missing'] == 0 and 'missing' not in counts
>>> counts.subtract('abb')
>>> assert counts == Counter(a=1, b=-1)
>>> assert counts - Counter() == Counter(a=1)  # Multiset subtraction drops <= 0.
>>> Point = namedtuple('Point', 'x y', defaults=[0, 0])
>>> assert Point(3)._replace(y=4) == (3, 4)
>>> order = OrderedDict(a=1, b=2)
>>> order.move_to_end('a')
>>> assert order.popitem(last=False) == ('b', 2)

```

`defaultdict[key]` inserts a missing value; `get` does not. `Counter.subtract`
preserves zero/negative counts, whereas multiset `+/-/&/|` omit nonpositive
results. `most_common(k)` breaks equal-count ties by first encounter; enforce a
separate sort key for a different policy. Counting n items costs expected O(n);
selecting k from u distinct keys usually costs O(u log k) for small k, with
special cases for k≤1 or k≥u, and O(u log u) for all results.

## Heaps: ordering is a contract

Python 3.11 examples use a min-heap; negate numeric priorities for a max-heap.
Public `_max` APIs exist starting in Python 3.14, so “Python only has min-heaps”
is no longer generally true. Do not negate arbitrary records. Ties need a unique
counter before a nonorderable payload.

```pycon
>>> import heapq
>>> from itertools import count
>>> serial = count()
>>> pending = []
>>> first, second = {'job': 'backup'}, {'job': 'restore'}
>>> heapq.heappush(pending, (2, next(serial), first))
>>> heapq.heappush(pending, (2, next(serial), second))
>>> assert heapq.heappop(pending)[2] is first
>>> assert heapq.heappop(pending)[2] is second
>>> assert list(heapq.merge([], [1, 3], [1, 2])) == [1, 1, 2, 3]
>>> assert heapq.nlargest(2, [4, 1, 4]) == [4, 4]
>>> heap = [5]
>>> assert heapq.heappushpop(heap, 2) == 2 and heap == [5]
>>> assert heapq.heapreplace(heap, 1) == 5 and heap == [1]

```

`heapify` mutates; copy first if the caller owns the list. `heapreplace` requires
a nonempty heap and always removes the old root; `heappushpop` can immediately
return the new value and works on an empty heap. Never alter a stored priority
in place without repairing the heap. `heapq.merge` requires every input sorted
in the same direction; it streams N outputs in O(N log k) heap work and O(k)
state for k active streams, not an arbitrary-input sort. Top-k selection is
usually O(n log k) for small positive k; k=1 and k near n take different paths.
For kth-largest, require `1 <= k <= n`; the root of a size-k min-heap is the kth
largest including duplicates, not the kth distinct value.

## Custom linked lists: identity, not value equality

Use a list/deque for an ordinary stack/queue. A singly linked node supports O(1)
insertion after a known node, not O(1) search or arbitrary deletion without its
predecessor. Reversal rewires caller-owned nodes. Detect/reject cycles before
reversal or an unbounded “convert to list” traversal.

```pycon
>>> from dataclasses import dataclass
>>> @dataclass(eq=False)
... class Link:
...     value: int
...     next: 'Link | None' = None
>>> def has_cycle(head):
...     slow = fast = head
...     while fast is not None and fast.next is not None:
...         slow = slow.next
...         fast = fast.next.next
...         if slow is fast:
...             return True
...     return False
>>> def reverse_links(head):
...     if has_cycle(head):
...         raise ValueError('cyclic list')
...     previous = None
...     while head is not None:
...         following = head.next
...         head.next = previous
...         previous, head = head, following
...     return previous
>>> head = Link(1, Link(1, Link(2)))
>>> assert not has_cycle(head)  # Equal values are not identical nodes.
>>> tail = head.next.next
>>> reversed_head = reverse_links(head)
>>> assert reversed_head is tail and head.next is None
>>> assert reversed_head.next.next is head
>>> assert reverse_links(None) is None
>>> loop = Link(3)
>>> loop.next = loop
>>> assert has_cycle(loop)
>>> reverse_links(loop)
Traceback (most recent call last):
...
ValueError: cyclic list

```

Detection and reversal each cost O(n) time, O(1) auxiliary node references.
Fast/slow middle-finding on an acyclic chain advances slow once, fast twice;
with `while fast and fast.next`, an even-length chain returns the second middle.
Do not use recursive structural dataclass equality to identify cyclic nodes.

## Trees and graph representations

A binary tree is not necessarily a search tree; an unbalanced BST can have
O(n) search. Stdlib does not provide an automatically balanced mutable BST.
Represent a missing root as `None`, not as a node whose value happens to be
`None`. Level-order construction needs a defined encoding (compact child slots
vs heap-array indices); reject orphan nonempty slots rather than silently losing
nodes. Avoid repeated recursive list concatenation: a skewed tree can make it
quadratic. Iterative inorder uses O(h) stack plus O(n) output, O(n) time:

```pycon
>>> from dataclasses import dataclass
>>> @dataclass(eq=False)
... class Tree:
...     value: int
...     left: 'Tree | None' = None
...     right: 'Tree | None' = None
>>> def inorder(root):
...     result, stack = [], []
...     while root is not None or stack:
...         while root is not None:
...             stack.append(root)
...             root = root.left
...         root = stack.pop()
...         result.append(root.value)
...         root = root.right
...     return result
>>> assert inorder(None) == []
>>> assert inorder(Tree(2, Tree(1), Tree(3))) == [1, 2, 3]

```

Preorder uses a stack: pop/emit node then push right followed by left. Postorder
uses `(node, expanded)` frames, pushing the expanded parent before its children;
emit only expanded frames. These assume an acyclic tree with no shared child;
use a graph visited set if identity can recur.

| Graph representation | Storage | Neighbor iteration / edge lookup |
|---|---|---|
| `list[list[int]]` adjacency, IDs 0..V−1 | O(V + E) | O(degree) / O(degree) |
| `dict[node, list[node]]` | O(V + E) | Supports sparse hashable labels; include isolated vertices explicitly |
| Adjacency sets | O(V + E) | Expected O(1) membership; deduplicates parallel edges, loses neighbor ordering |
| Independent-row V×V matrix | O(V²) | O(V) neighbor scan, O(1) edge lookup |

Decide directed/undirected (store both orientations for undirected), parallel
edges, self-loops and absent-edge sentinel. A weighted matrix cannot use zero
for “no edge” if zero-weight edges are allowed. Graph cloning needs an
identity→new-node map populated **before** following edges, preserving cycles
and shared neighbors; a shallow container copy does not clone a graph.
For complete traversals, dependency order, union-find and trie implementations,
load [Graph and index patterns](graph-and-index-patterns.md).

## Numeric and iterator helpers

Prefer `math.isqrt(n)` to floating square roots for exact nonnegative-integer
square tests (`r = isqrt(n); r*r == n`). `math.comb/perm` count possibilities
without enumerating them; `math.gcd/lcm/prod` avoid custom folds.
`operator.itemgetter/attrgetter` are convenient sort keys, not asymptotic changes.
`itertools.accumulate(..., initial=0)` builds prefix totals; `islice` bounds
iterator consumption. `groupby` groups adjacent equal keys only; sort by the
same key first when global grouping is needed. Combinatorial iterators pool
finite input and still produce combinatorial output; `cycle` retains seen items.

Semantics: [built-in types](https://docs.python.org/3.11/library/stdtypes.html),
[collections](https://docs.python.org/3.11/library/collections.html),
[heapq](https://docs.python.org/3/library/heapq.html),
[sorting](https://docs.python.org/3.11/howto/sorting.html).
