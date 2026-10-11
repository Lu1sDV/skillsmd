# Graph and index patterns: 10, 14–16

Use dense vertex IDs `0..graph.len()` for these examples. Adjacency lists take
O(V + E) storage even when edges are sparse. Validate IDs at an input boundary;
never interpret an out-of-range endpoint as “unreachable”. All fences are
standalone and require only the standard library.

## 10. BFS and DFS

**BFS applicability:** reachability, levels, shortest **unweighted** distances.
Invariant: enqueue a vertex only at first discovery; its distance is final then.
Marking only at dequeue can enqueue duplicates and inflate storage/work. A
`VecDeque` is the FIFO; a visited/distance vector avoids hashing dense IDs.

**DFS applicability:** reachability, traversal, components, stateful entry/exit
processing. Invariant: each frame retains its next unexplored edge. An explicit
frame stack reproduces recursive DFS order and uses O(V) rather than call-stack
space. To classify directed cycles use gray/black state, not a single visited
bit. A traversal does not enumerate all simple paths.

Both cost O(V + E) time including the validation pass and O(V) state. Actual
traversal visits only the reachable component; start DFS/BFS from each still
unvisited vertex to traverse a disconnected graph. The return order depends on
adjacency order. `Err` distinguishes malformed graph/start from a valid traversal.

```rust
use std::collections::VecDeque;

fn validate(graph: &[Vec<usize>], start: usize) -> Result<(), &'static str> {
    if start >= graph.len() { return Err("invalid start vertex"); }
    if graph.iter().flatten().any(|&v| v >= graph.len()) {
        return Err("invalid edge endpoint");
    }
    Ok(())
}

fn bfs_distances(graph: &[Vec<usize>], start: usize)
    -> Result<Vec<Option<usize>>, &'static str>
{
    validate(graph, start)?;
    let mut distance = vec![None; graph.len()];
    let mut queue = VecDeque::from([start]);
    distance[start] = Some(0_usize);
    while let Some(u) = queue.pop_front() {
        let next_distance = distance[u].unwrap() + 1;
        for &v in &graph[u] {
            if distance[v].is_none() {
                distance[v] = Some(next_distance);
                queue.push_back(v);
            }
        }
    }
    Ok(distance)
}

fn dfs_order(graph: &[Vec<usize>], start: usize)
    -> Result<Vec<usize>, &'static str>
{
    validate(graph, start)?;
    let mut visited = vec![false; graph.len()];
    let mut order = vec![start];
    let mut stack = vec![(start, 0_usize)];
    visited[start] = true;
    while let Some((u, next_edge)) = stack.last_mut() {
        if *next_edge == graph[*u].len() {
            stack.pop();
            continue;
        }
        let v = graph[*u][*next_edge];
        *next_edge += 1;
        if !visited[v] {
            visited[v] = true;
            order.push(v);
            stack.push((v, 0));
        }
    }
    Ok(order)
}
let graph = vec![vec![1, 2], vec![2], vec![0], vec![]];
assert_eq!(bfs_distances(&graph, 0), Ok(vec![Some(0), Some(1), Some(1), None]));
assert_eq!(dfs_order(&graph, 0), Ok(vec![0, 1, 2]));
assert_eq!(dfs_order(&[vec![0]], 0), Ok(vec![0]));
assert!(bfs_distances(&[], 0).is_err());
assert!(bfs_distances(&[vec![1]], 0).is_err());
```

Distances fit in `usize`: a shortest simple path has at most V−1 edges, and a
valid allocated adjacency vector bounds V. For weighted distances that argument
does not bound sums of weights; use appropriate checked arithmetic.

### Adaptations without changing the invariant

- **Level order:** record the queue length before processing a level and pop
  exactly that many elements, or group by BFS distance. Do not let newly enqueued
  children extend the current level.
- **Number of islands:** define four- versus eight-neighbor connectivity,
  validate a rectangular grid and its cell alphabet, and handle both zero rows
  and zero columns. Mark land at discovery, then use a queue/stack. If mutating
  land to water is disallowed, use visited flags. O(rows·cols) time and worst-case
  space; deep recursive flood fill can exhaust the stack.
- **Neighbor arithmetic:** guard `row > 0` before `row - 1`; compare the positive
  neighbor against row length. Ragged grids require each row's own bounds, not
  silently reusing the first row's length.
- **Path reconstruction:** record each vertex's predecessor at discovery and
  walk parents backward after reaching the destination; reverse the result.
- **Weighted graphs:** use 0–1 BFS only for weights 0/1, or Dijkstra with a
  min-heap for nonnegative weights; these are distinct contracts, not BFS with a
  weight field added. This reference does not claim to implement those variants.

## 14. Topological sort

**Use:** dependency scheduling and DAG recurrences. Edges here are `u -> v`
meaning u must precede v. Kahn's invariant: indegree is the number of edges from
vertices not yet emitted; the queue contains remaining zero-indegree vertices.
Emit every vertex, including isolated ones. Fewer than V emitted means a cycle.
O(V + E) time/O(V) auxiliary state, excluding the input graph and output order.

Duplicate edges are counted and decremented separately, preserving the invariant.
The output is one valid order, not necessarily the lexicographically smallest;
a min-heap ready set would make selection O(log V) per emitted vertex.

```rust
use std::collections::VecDeque;
fn topological_order(graph: &[Vec<usize>])
    -> Result<Option<Vec<usize>>, &'static str>
{
    let n = graph.len();
    let mut indegree = vec![0_usize; n];
    for neighbors in graph {
        for &v in neighbors {
            if v >= n { return Err("invalid edge endpoint"); }
            indegree[v] = indegree[v].checked_add(1).ok_or("indegree overflow")?;
        }
    }
    let mut ready = VecDeque::new();
    for (v, &degree) in indegree.iter().enumerate() {
        if degree == 0 { ready.push_back(v); }
    }
    let mut order = Vec::with_capacity(n);
    while let Some(u) = ready.pop_front() {
        order.push(u);
        for &v in &graph[u] {
            indegree[v] -= 1;
            if indegree[v] == 0 { ready.push_back(v); }
        }
    }
    Ok((order.len() == n).then_some(order))
}
assert_eq!(topological_order(&[]), Ok(Some(vec![])));
assert_eq!(topological_order(&[vec![1, 1], vec![2], vec![]]),
           Ok(Some(vec![0, 1, 2])));
assert_eq!(topological_order(&[vec![1], vec![0]]), Ok(None));
assert_eq!(topological_order(&[vec![0]]), Ok(None));
assert!(topological_order(&[vec![1]]).is_err());
```

When input is `(course, prerequisite)`, insert `prerequisite -> course`, not the
other way round. Test the invariant `position[u] < position[v]` for every edge,
not a single arbitrary order, unless tie-breaking is part of the specification.
The explicit zero-degree loop also avoids copying edition-2021 reference-pattern
closures into edition 2024 without adapting match ergonomics.

## 15. Union-find (disjoint-set union)

**Use:** incremental undirected connectivity, redundant-edge detection, Kruskal
component merges. Not directed reachability and not arbitrary edge deletion.
Invariant: parent links form rooted trees; a root points to itself and its size
is the component cardinality. Attach the smaller component to the larger and
compress paths. Initialization O(V); a sequence of operations has amortized
O(α(V)) per operation/O(V) storage. The amortized bound is not worst-case O(1).

```rust
struct UnionFind {
    parent: Vec<usize>,
    size: Vec<usize>,
    components: usize,
}
impl UnionFind {
    fn new(n: usize) -> Self {
        Self { parent: (0..n).collect(), size: vec![1; n], components: n }
    }
    fn find(&mut self, mut x: usize) -> usize {
        assert!(x < self.parent.len(), "invalid vertex");
        while self.parent[x] != x {
            let parent = self.parent[x];
            self.parent[x] = self.parent[parent]; // Path halving.
            x = self.parent[x];
        }
        x
    }
    fn union(&mut self, a: usize, b: usize) -> bool {
        let (mut a, mut b) = (self.find(a), self.find(b));
        if a == b { return false; }
        if self.size[a] < self.size[b] { std::mem::swap(&mut a, &mut b); }
        self.parent[b] = a;
        self.size[a] += self.size[b]; // Disjoint sizes sum to at most initial n.
        self.components -= 1;
        true
    }
    fn connected(&mut self, a: usize, b: usize) -> bool {
        self.find(a) == self.find(b)
    }
}
let mut sets = UnionFind::new(4);
assert!(sets.union(0, 1));
assert!(sets.union(2, 3));
assert!(sets.union(1, 2));
assert!(!sets.union(0, 3));
assert!(sets.connected(0, 2));
assert_eq!(sets.components, 1);
assert_eq!(UnionFind::new(0).components, 0);
```

IDs are caller-validated; these assertions catch programmer misuse. `find` needs
`&mut self` because compression mutates the representation even though the
mathematical partition is unchanged. Rank, if used instead of size, is a bound
from union history, not the current tree height after compression. Do not expose
parents as stable component IDs across future unions.

## 16. Trie

**Use:** repeated prefix membership over strings. If only exact lookup is needed,
a `HashSet<String>` is simpler; if sorted ranges suffice, consider `BTreeSet`.
Invariant: each edge consumes exactly one chosen symbol; a terminal bit marks an
entire inserted word separately from prefix existence. The empty prefix always
exists; the empty word exists only after insertion.

This trie compares exact Unicode scalar values and uses arena indices. Flat
nodes avoid recursive destruction of a long nested trie; no `Rc<RefCell<_>>` or
unsafe pointers are needed. Expected O(L) insertion/query for L scalars with hash
children, O(total inserted scalars) upper bound on nodes/edges. Hash key order is
not lexicographic traversal order. Per-node maps have overhead: fixed alphabets
may justify arrays only after validation and memory analysis.

```rust
use std::collections::HashMap;
#[derive(Default)]
struct Node {
    children: HashMap<char, usize>,
    terminal: bool,
}
struct Trie {
    nodes: Vec<Node>,
}
impl Trie {
    fn new() -> Self { Self { nodes: vec![Node::default()] } }
    fn insert(&mut self, word: &str) {
        let mut node = 0;
        for c in word.chars() {
            let existing = self.nodes[node].children.get(&c).copied();
            node = match existing {
                Some(next) => next,
                None => {
                    let next = self.nodes.len();
                    self.nodes.push(Node::default());
                    self.nodes[node].children.insert(c, next);
                    next
                }
            };
        }
        self.nodes[node].terminal = true;
    }
    fn locate(&self, key: &str) -> Option<usize> {
        let mut node = 0;
        for c in key.chars() {
            node = *self.nodes[node].children.get(&c)?;
        }
        Some(node)
    }
    fn contains(&self, word: &str) -> bool {
        self.locate(word).is_some_and(|node| self.nodes[node].terminal)
    }
    fn starts_with(&self, prefix: &str) -> bool { self.locate(prefix).is_some() }
}
let mut trie = Trie::new();
assert!(trie.starts_with(""));
assert!(!trie.contains(""));
trie.insert("日é");
trie.insert("日é"); // Idempotent insertion.
assert!(trie.starts_with("日"));
assert!(!trie.contains("日"));
assert!(trie.contains("日é"));
assert!(!trie.contains("é日"));
trie.insert("");
assert!(trie.contains(""));
```

Normalization, grapheme clusters and case folding are deliberately not implied
by Unicode scalar iteration. Apply a specified transformation consistently at
both insertion and lookup only when the product contract calls for it.

## Sources

Synthesized from pinned StructWeave [04-interview-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/04-interview-patterns.md)
and graph/custom-node sections of [03-data-structures](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/03-data-structures.md).
Collection contracts follow the [standard library guide](https://doc.rust-lang.org/std/collections/index.html);
text semantics follow [`str`](https://doc.rust-lang.org/std/primitive.str.html).
Corrections include explicit endpoint validation, disconnected/empty semantics,
bounded explicit traversal stacks, cycle-vs-malformed-input distinction, valid
edition-2024 iteration, and nonrecursive trie storage.
