# Graph and index patterns 10, 14–16

## Contents

- [10. BFS / DFS](#10-bfs--dfs)
- [Grids, trees and cloning](#grids-trees-and-cloning)
- [14. Topological sort](#14-topological-sort)
- [15. Union-find / disjoint sets](#15-union-find--disjoint-sets)
- [16. Trie / prefix tree](#16-trie--prefix-tree)

Choose representation and direction first. Examples use adjacency lists indexed
by integer vertices `0..V-1`; invalid negative IDs must not become valid Python
negative indices. The graph is read-only during traversal. Costs assume bounded
ID operations; output is separate from auxiliary work state.

## 10. BFS / DFS

BFS's queue processes vertices by nondecreasing unweighted distance. Mark on
**discovery**, before enqueueing, so cycles/parallel edges do not repeatedly add
vertices. Distance `None` means unreachable. An empty graph has no valid source.
This version validates the whole graph before traversal, so its total time is
O(V+E), including disconnected components' validation; traversal alone visits
only the source's reachable component.

```pycon
>>> from collections import deque
>>> def validate_graph(graph):
...     n = len(graph)
...     for neighbors in graph:
...         for vertex in neighbors:
...             if type(vertex) is not int or not 0 <= vertex < n:
...                 raise ValueError('invalid vertex')
>>> def bfs_distances(graph, start):
...     validate_graph(graph)
...     if type(start) is not int or not 0 <= start < len(graph):
...         raise ValueError('invalid source')
...     distance = [None] * len(graph)
...     distance[start] = 0
...     pending = deque([start])
...     while pending:
...         vertex = pending.popleft()
...         for neighbor in graph[vertex]:
...             if distance[neighbor] is None:
...                 distance[neighbor] = distance[vertex] + 1
...                 pending.append(neighbor)
...     return distance
>>> graph = [[1, 1], [0, 2], [2], []]
>>> assert bfs_distances(graph, 0) == [0, 1, 2, None]
>>> assert bfs_distances([[]], 0) == [0]
>>> bfs_distances([], 0)
Traceback (most recent call last):
...
ValueError: invalid source
>>> bfs_distances([[-1]], 0)
Traceback (most recent call last):
...
ValueError: invalid vertex
>>> def dfs_forest(graph):
...     validate_graph(graph)
...     seen, order = set(), []
...     for root in range(len(graph)):
...         if root in seen:
...             continue
...         seen.add(root)
...         order.append(root)
...         frames = [iter(graph[root])]
...         while frames:
...             neighbor = next(frames[-1], None)
...             if neighbor is None:
...                 frames.pop()
...             elif neighbor not in seen:
...                 seen.add(neighbor)
...                 order.append(neighbor)
...                 frames.append(iter(graph[neighbor]))
...     return order
>>> assert dfs_forest(graph) == [0, 1, 2, 3]
>>> assert dfs_forest([]) == []
>>> assert graph == [[1, 1], [0, 2], [2], []]

```

Both use O(V) auxiliary state (plus output); DFS frames preserve recursive
neighbor order without interpreter recursion or duplicate queued entries. A
stack of whole neighbor copies could instead add O(E) temporary storage. A
single-start DFS finds reachability, not every simple path; path enumeration
needs path-local visited state restored on backtrack and may be exponential.
To detect a directed cycle with DFS, maintain unseen/active/finished colors:
an edge to an active ancestor closes a cycle; an edge to any visited vertex
does not necessarily do so. For undirected graphs, exclude the parent **edge**
when cycle-checking; parallel edges require edge identities or a clear simple-
graph contract.

### Grids, trees and cloning

- A rectangular grid is an implicit graph. Validate rectangular shape, coordinates
  and blocked start/end before indexing. Empty grid or zero columns has no valid
  cell. Four-way vs eight-way movement changes connectivity and distance.
- Islands: scan each cell, start a worklist at each unseen land cell and mark
  neighbors on discovery. O(rows·cols) time and worst-case state. A separate
  visited set preserves input; overwriting land mutates it. Use an explicit
  worklist instead of recursion on a potentially huge island.
- Unit-cost grid shortest path is BFS; return distance zero when a traversable
  source equals target. Weighted edges are not covered by that invariant.
  Dijkstra requires **nonnegative** weights, uses relaxation and a min-heap,
  discards entries whose distance is stale, and needs heap tie breakers for
  nonorderable labels. Negative weights require a different algorithm.
- Tree level-order traversal uses `deque` and processes `len(queue)` nodes per
  level. Empty root gives `[]`. Tree traversals assume no cycles/shared child;
  if not guaranteed, treat the input as a graph (see collection reference).
- Clone a reachable object graph using `original identity -> clone`. Allocate
  and register a clone before traversing its outgoing edges, then append the
  corresponding cloned neighbors. Preserve sharing, self-loops and parallel
  edges; equal node values do not imply equal node identities. O(V+E) total
  time/output storage plus O(V) map/queue state; payload deep-copy policy is
  separate from cloning topology.

## 14. Topological sort

An edge `u -> v` means u must complete **before** v. Kahn's queue contains nodes
whose remaining indegree is zero. Consume all vertices, including isolated ones;
if fewer than V are emitted, a directed cycle remains. Raise on a cycle instead
of returning the same `[]` used for a valid empty graph. Repeated edges are
counted and decremented symmetrically; do not deduplicate only one side.

```pycon
>>> from collections import deque
>>> def topological_order(n, edges):
...     if type(n) is not int or n < 0:
...         raise ValueError('invalid vertex count')
...     graph, indegree = [[] for _ in range(n)], [0] * n
...     for before, after in edges:
...         if any(type(v) is not int or not 0 <= v < n for v in (before, after)):
...             raise ValueError('invalid vertex')
...         graph[before].append(after)
...         indegree[after] += 1
...     ready = deque(v for v in range(n) if indegree[v] == 0)
...     order = []
...     while ready:
...         vertex = ready.popleft()
...         order.append(vertex)
...         for neighbor in graph[vertex]:
...             indegree[neighbor] -= 1
...             if indegree[neighbor] == 0:
...                 ready.append(neighbor)
...     if len(order) != n:
...         raise ValueError('directed cycle')
...     return order
>>> edges = [(0, 2), (0, 2), (1, 2), (2, 3)]
>>> order = topological_order(5, edges)
>>> positions = {node: index for index, node in enumerate(order)}
>>> assert set(order) == set(range(5))
>>> assert all(positions[a] < positions[b] for a, b in edges)
>>> assert topological_order(0, []) == []
>>> topological_order(2, [(0, 1), (1, 0)])
Traceback (most recent call last):
...
ValueError: directed cycle
>>> topological_order(1, [(0, 0)])
Traceback (most recent call last):
...
ValueError: directed cycle
>>> topological_order(1, [(-1, 0)])
Traceback (most recent call last):
...
ValueError: invalid vertex

```

O(V+E) time and storage including constructed adjacency; O(V) work state beyond
adjacency/output. This returns one valid order, deterministic for fixed edge
iteration order, not necessarily lexicographically smallest. Use a min-heap
instead of queue for smallest-ready-ID ordering, adding O(V log V) heap work.
Course prerequisite records `(course, prerequisite)` must be reversed into
`(prerequisite, course)`. Feasibility is successful complete consumption, not
`bool(order)` (zero courses is feasible). Topological order is undefined for
cyclic dependencies; do not quietly publish the partial order as complete.

## 15. Union-find / disjoint sets

Use for incremental undirected connectivity, component counts, redundant edges
or Kruskal's MST. It does not express directed reachability, paths or arbitrary
edge deletion. Parents form a forest; roots own sizes; path halving shortens
future find operations. Even `find` mutates internal parent pointers.

```pycon
>>> class UnionFind:
...     def __init__(self, n):
...         if type(n) is not int or n < 0:
...             raise ValueError('invalid element count')
...         self.parent = list(range(n))
...         self.size = [1] * n
...         self.components = n
...     def find(self, value):
...         if type(value) is not int or not 0 <= value < len(self.parent):
...             raise ValueError('invalid element')
...         while value != self.parent[value]:
...             self.parent[value] = self.parent[self.parent[value]]
...             value = self.parent[value]
...         return value
...     def union(self, first, second):
...         a, b = self.find(first), self.find(second)
...         if a == b:
...             return False
...         if self.size[a] < self.size[b]:
...             a, b = b, a
...         self.parent[b] = a
...         self.size[a] += self.size[b]
...         self.components -= 1
...         return True
...     def connected(self, first, second):
...         return self.find(first) == self.find(second)
>>> groups = UnionFind(4)
>>> assert groups.union(0, 1) and groups.union(2, 3)
>>> assert not groups.union(1, 0) and not groups.union(2, 2)
>>> assert groups.components == 2 and not groups.connected(0, 3)
>>> assert groups.union(1, 3) and groups.components == 1
>>> assert groups.connected(0, 2)
>>> assert UnionFind(0).components == 0
>>> groups.find(-1)
Traceback (most recent call last):
...
ValueError: invalid element

```

Initialization O(V) time/space; m operations with compression and size/rank
balancing cost O(m·α(V)) amortized after initialization, not an unconditional
worst-case O(1) each. Component counting on E edges costs O(V + E·α(V)), not just
O(V·α(V)). In a simple undirected graph, a failed union identifies an edge that
closes a cycle; self-loops also fail and a repeated parallel edge fails under
multigraph semantics. Choose whether to reject/deduplicate duplicates instead.
Kruskal sorts weighted undirected edges, accepts only successful unions and
requires V−1 accepted edges for a connected spanning tree; otherwise it yields
a spanning forest, not a complete MST. Edge sorting usually dominates.

## 16. Trie / prefix tree

A terminal marker distinguishes complete words from prefixes; store it separately
from child labels so arbitrary Unicode characters cannot collide with a sentinel.
Duplicate insertion is idempotent for set semantics; occurrence counts would need
separate state. Strings are sequences of code points; choose normalization and
case-folding **before** insertion and lookup if required by the domain.

```pycon
>>> class TrieNode:
...     def __init__(self):
...         self.children = {}
...         self.terminal = False
>>> class Trie:
...     def __init__(self):
...         self.root = TrieNode()
...     def insert(self, word):
...         node = self.root
...         for char in word:
...             if char not in node.children:
...                 node.children[char] = TrieNode()
...             node = node.children[char]
...         node.terminal = True
...     def _node(self, text):
...         node = self.root
...         for char in text:
...             node = node.children.get(char)
...             if node is None:
...                 return None
...         return node
...     def contains(self, word):
...         node = self._node(word)
...         return node is not None and node.terminal
...     def starts_with(self, prefix):
...         return self._node(prefix) is not None
>>> words = Trie()
>>> assert words.starts_with('') and not words.contains('')
>>> words.insert('éclair')
>>> words.insert('éclair')
>>> assert words.starts_with('é') and not words.contains('é')
>>> assert words.contains('éclair') and not words.starts_with('🙂')
>>> words.insert('')
>>> assert words.contains('')

```

Expected O(L) key traversal for length L, O(total distinct stored-prefix symbols)
nodes/edges. Insert/lookup do not copy the input string; inserting does allocate
new nodes when needed. Autocomplete first locates the prefix then traverses its
subtree, emitting terminal words; include output construction cost, and sort
children if lexicographic output is required. For deletion, clear terminal and
prune only childless nonterminal suffix nodes, never a shared prefix.

Board word search combines a trie with path-local DFS/backtracking: validate
nonempty rectangular board or return `[]`, move only to adjacent unused cells,
follow existing child edges, emit only terminal words and restore visitation on
return. Use a separate visited set unless mutation is allowed; a magic character
like `'#'` is unsafe if it can appear as real board data. Deduplicate answers
explicitly and sort if deterministic order matters. Maximum word length bounds
path depth; trie pruning helps in practice but does not remove worst-case
exponential path enumeration.

First-party container semantics: [deque](https://docs.python.org/3.11/library/collections.html#collections.deque),
[hashable objects](https://docs.python.org/3.11/glossary.html#term-hashable).
