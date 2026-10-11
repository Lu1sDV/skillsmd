# Collections and contracts

## Choose by the operation, not by familiarity

The [standard collection guide](https://doc.rust-lang.org/std/collections/index.html)
distinguishes expected hashing costs from amortized growth costs. These costs
assume O(1) comparison/hash work on the element; a long string key changes that.

| Collection | Use | Cost and failure modes |
|---|---|---|
| `Vec<T>` / `&[T]` | Dense sequence, stack, DP, visited flags | O(1) index/pop, amortized O(1) push; middle insert/remove O(n). `swap_remove` O(1) loses order. |
| `VecDeque<T>` | BFS, queue, two-ended window | O(1) pop at either end, amortized O(1) push; not necessarily one contiguous slice. Avoid `Vec::remove(0)` loops. |
| `HashMap<K,V>` / `HashSet<T>` | Counts, membership, complements | Expected O(1) lookup/update for fixed-size keys; adversarial collisions can degrade it. Default hashing includes randomized seeding; do not replace it blindly for untrusted keys. |
| `BTreeMap<K,V>` / `BTreeSet<T>` | Sorted keys, predecessor/successor, ranges | O(log n) lookup/update, range traversal O(log n + k) for k returned entries. Keys require a consistent `Ord`. |
| `BinaryHeap<T>` | Repeated extreme, top-k, median halves | Max-heap; O(1) peek, O(log n) pop, at most O(log n) sift per push plus occasional allocation. Heapify from a vector is O(n). |
| `LinkedList<T>` | Specific list split/append semantics | Finding an arbitrary middle position is O(n); no blanket O(1) indexed insertion. Prefer Vec/VecDeque for ordinary algorithms. |
| `String` / `&str` | Owned UTF-8 / borrowed UTF-8 | Byte length O(1), scalar count O(bytes); no integer character indexing. |

Heap insertion bounds used in the pattern guide are amortized over allocation:
a single growth may move O(n) elements. See [BinaryHeap](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html).

## Sequence and ownership traps

- `Vec::with_capacity(n)` reserves room for **at least** n elements; length stays
  zero. Populate with `push`, or initialize with `vec![value; n]`. Never use
  `set_len` to avoid initialization in a safe algorithm.
- `sort` preserves the relative order of equal keys; `sort_unstable` does not
  and avoids auxiliary allocation. Neither is universally “faster”. Descend
  with `b.cmp(a)` or `Reverse`, not `-key` (signed minimum overflows).
- `dedup` removes adjacent duplicates. Sort first only if destroying input order
  is allowed; otherwise track membership or preserve the first occurrence.
- `binary_search` requires ordering consistent with its comparison; with
  duplicates it can return any equal index. Use `partition_point` for a boundary.
- `chunks(0)` and `windows(0)` panic. Rotations require `k <= len`; normalizing
  `k % len` itself requires a nonempty sequence.
- `iter` borrows, `iter_mut` mutably borrows, `into_iter` on an owned collection
  moves elements. `Clone` is explicit, not automatic `Copy`; cloning `Vec` or
  `String` copies contents, while cloning `Rc` shares the allocation.
- A reference into a vector cannot remain in use across a push that mutably
  borrows it. Keep an index and reborrow after mutation; indices themselves
  become stale after insertion/removal/reordering.

```rust
use std::cmp::Reverse;
use std::collections::{BTreeMap, HashMap, HashSet};

let mut values = Vec::with_capacity(4);
assert_eq!(values.len(), 0);
assert!(values.capacity() >= 4);
values.extend([i32::MIN, 2, 2, -1]);
values.sort_unstable_by_key(|&x| Reverse(x));
values.dedup();
assert_eq!(values, [2, -1, i32::MIN]);

let mut counts = HashMap::new();
for c in "ééa".chars() {
    *counts.entry(c).or_insert(0_usize) += 1;
}
assert_eq!(counts.get(&'é'), Some(&2));
let sorted: BTreeMap<_, _> = counts.into_iter().collect();
assert_eq!(sorted.keys().copied().collect::<Vec<_>>(), ['a', 'é']);
let a: HashSet<_> = [1, 2].into_iter().collect();
let b: HashSet<_> = [2, 3].into_iter().collect();
// Set algebra iterators yield references; copy only when an owned set is needed.
let intersection: HashSet<_> = a.intersection(&b).copied().collect();
assert_eq!(intersection, HashSet::from([2]));
```

Use `entry(...).or_insert_with(...)` for lazy value construction;
`or_insert(expensive())` evaluates eagerly. The key passed into `entry` is also
constructed eagerly: `map.get("key")` can borrow an existing `String` key without
allocating, whereas `map.entry("key".to_owned())` constructs an owned key.
Mutable map/set keys must not change their hashing or equality while stored.
Hash iteration order is unspecified, and current `HashMap` iteration scans
capacity, not only length; do not promise O(len) after a large reserve.

## Priority and floating-point ordering

A heap comparator that ignores a name while derived equality compares it violates
[`Ord`'s consistency requirements](https://doc.rust-lang.org/std/cmp/trait.Ord.html).
Prefer a tuple key with an explicit deterministic tie-breaker. For payloads that
do not implement `Ord`, keep payloads in separate indexed storage and heap
`(priority, id)`; do not add unrelated ordering to the payload type.

```rust
use std::cmp::Reverse;
use std::collections::BinaryHeap;

let mut pending = BinaryHeap::from([
    Reverse((3, 0_usize)), Reverse((1, 2)), Reverse((1, 1)),
]);
assert_eq!(pending.pop(), Some(Reverse((1, 1))));
assert_eq!(pending.pop(), Some(Reverse((1, 2))));

// Floats have PartialOrd, not Ord; define the NaN policy explicitly.
let mut scores = [f64::NAN, 2.0, -1.0];
scores.sort_by(f64::total_cmp);
assert_eq!(&scores[..2], &[-1.0, 2.0]);
assert!(scores[2].is_nan());
```

`partial_cmp(...).unwrap()` panics on NaN. An epsilon comparison is not a total
order (approximate equality is generally not transitive); do not use it as a
sort/heap comparator. `total_cmp` defines an order including signed zero/NaNs,
not approximate mathematical equality. For domain-specific tolerances, specify
absolute/relative tolerance and non-finite-value policy separately.

## UTF-8: choose the unit before the data structure

[`str` documentation](https://doc.rust-lang.org/std/primitive.str.html) defines byte
indices and Unicode scalar iteration. A `char` is not a user-perceived grapheme.

| Contract | Representation |
|---|---|
| Raw bytes or validated ASCII | `&[u8]`; fixed count array only after validating alphabet |
| Unicode scalar sequence | Stream `chars()`; collect `Vec<char>` only for random access |
| Return an original substring | Track `char_indices()` byte boundaries and borrow `&str` |
| Grapheme clusters, normalization, case folding | Specify semantics; use an appropriate Unicode library if the project requires it |

Repeated `s.chars().nth(i)` walks the prefix repeatedly and can make a loop
quadratic. A scalar index is **not** a valid string-slicing byte index. `get`
returns `None` for invalid ranges or UTF-8 boundaries rather than panicking.
ASCII lowercase is not Unicode case folding, and Unicode lowercasing can expand
one scalar into several. Anagrams/palindromes need an explicit normalization and
case policy; this bundle's Unicode algorithms compare exact scalar values.

```rust
fn first_scalars(s: &str, count: usize) -> &str {
    let end = s.char_indices().nth(count).map_or(s.len(), |(i, _)| i);
    &s[..end]
}
assert_eq!(first_scalars("é日a", 2), "é日");
assert_eq!(first_scalars("é日a", 0), "");
assert_eq!(first_scalars("é", 9), "é");
assert_eq!("é".get(..1), None);
assert_eq!("e\u{301}".chars().count(), 2); // Two scalars, often one grapheme.
```

Build output with `String::push`/`push_str`, `join`, or an iterator collection.
Return a borrowed slice when the result is an unchanged region of the input.
`to_owned`, `to_string`, and `String::from(&str)` create owned text; converting an
already owned `String` to `String` just moves it. Empty values need not allocate.

## Model trees, lists, and graphs without unnecessary shared ownership

- A singly owned tree/list uses `Option<Box<Node>>`. `Option::take` moves a child
  link out before rewiring it; no payload clone is needed.
- `Rc<RefCell<Node>>` is justified by shared single-threaded mutable ownership,
  not by “tree” alone. Shorten runtime borrows before recursive calls. Strong
  cycles leak; use `Weak` back-links where ownership requires them.
- An arena `Vec<Node>` plus IDs is useful for parent links and algorithms needing
  many cross-links. Validate IDs and establish how deletion affects them.
- `Vec<Vec<usize>>` is an adjacency list for **dense vertex IDs** `0..V`, not only
  dense edge sets. It costs O(V + E) space and works well for sparse edges.
- `HashMap<Key, Vec<Key>>` handles arbitrary labels; remapping labels to dense
  IDs can simplify visited/DP arrays. Include destination-only vertices.
- `Vec<Vec<(usize, Weight)>>` models weighted adjacency. BFS is not a weighted
  shortest-path substitute. Dijkstra requires nonnegative weights.
- An edge list suits Kruskal/edge scans. An adjacency matrix costs O(V²) and
  gives O(1) edge lookup; use `Option<Weight>` for absence when zero is a valid
  weight. Undirected adjacency normally records each edge both ways.

```rust
#[derive(Debug)]
struct Node {
    value: i32,
    next: Option<Box<Node>>,
}
fn reverse(mut head: Option<Box<Node>>) -> Option<Box<Node>> {
    let mut previous = None;
    while let Some(mut node) = head {
        head = node.next.take();
        node.next = previous;
        previous = Some(node);
    }
    previous
}
let head = Some(Box::new(Node {
    value: 1,
    next: Some(Box::new(Node { value: 2, next: None })),
}));
let reversed = reverse(head).unwrap();
assert_eq!(reversed.value, 2);
assert_eq!(reversed.next.as_ref().unwrap().value, 1);
assert!(reverse(None).is_none());
```

Reversal is O(n) time/O(1) auxiliary storage, but recursively dropping a very deep
boxed chain can still exhaust the stack; explicitly unlink nodes when destroying
untrusted-depth structures, or use an arena. Do not conflate iterative traversal
with iterative destruction.

## Iterators and arithmetic contracts

Prefer `(1..=n)` over a custom counting iterator. A custom iterator is useful
when it packages real traversal state. `next` returns `Option<Item>`; returning
`None` once does not inherently promise never to resume (`FusedIterator` adds
that contract). Do not claim exact size without proving it.

```rust
struct AscendingBits(u64);
impl Iterator for AscendingBits {
    type Item = u32;
    fn next(&mut self) -> Option<Self::Item> {
        if self.0 == 0 {
            return None;
        }
        let position = self.0.trailing_zeros();
        self.0 &= self.0 - 1; // Nonzero guard proves subtraction is valid.
        Some(position)
    }
}
assert_eq!(AscendingBits(0b1010).collect::<Vec<_>>(), [1, 3]);
let mut empty = AscendingBits(0);
assert_eq!(empty.next(), None);
assert_eq!(empty.next(), None);
```

Widen before addition (`i64::from(a) + i64::from(b)`), not after. Arbitrary-length
sums/products/counts may overflow even a wider type: prove a bound or propagate
`checked_*` failure. Saturation is only correct for a clamping contract; wrapping
is only correct for modular arithmetic. Profile defaults are not guarantees;
[overflow checks are configurable](https://doc.rust-lang.org/reference/expressions/operator-expr.html#overflow),
and some constant overflows are rejected at compile time. Validate signed input
before casting to `usize`, and validate allocation sizes at an external boundary.

## Sources and corrections

Synthesized from pinned StructWeave [03-data-structures](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/03-data-structures.md)
and collection/memory/standard-library sections of [13-interview-trap-questions](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md).
Corrects inconsistent heap equality, arbitrary-middle LinkedList claims, capacity
exactness, byte/scalar confusion, floating-point ordering, overly broad allocation
claims, and unconditional debug/release overflow claims. Official semantics are
linked alongside their decisions above.
