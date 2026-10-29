# Optimization Patterns

Choose a pattern only when it addresses the measured bottleneck. Prefer the
simplest adequate algorithm, representation, or allocation change; the section
order is not an optimization priority or a promise of improvement.

## Allocations

```rust
// Reuse a caller-owned buffer when retaining capacity is useful.
fn process_into(items: &[u32], out: &mut Vec<u32>) {
    out.clear();
    out.extend_from_slice(items);
}

let mut out = Vec::with_capacity(3);
process_into(&[1, 2, 3], &mut out);
assert_eq!(out, [1, 2, 3]);
let capacity = out.capacity();
process_into(&[4], &mut out);
assert_eq!(out, [4]);
assert_eq!(out.capacity(), capacity);
```

Avoid clone-to-satisfy-borrowck; design ownership instead. Pool or reuse objects
under measured allocator pressure. Inline collections such as `SmallVec` trade
allocation rate for a larger value and fallback checks; measure the size distribution.

## Data-oriented layout

```rust
// AoS: fields of one entity adjacent, but updates touch one field at a time.
struct Entity { position: f32, velocity: f32, health: f32 }

// SoA: one field's array adjacent — cache-friendly for whole-column passes.
struct Entities {
    positions: Vec<f32>,
    velocities: Vec<f32>,
    health: Vec<f32>,
}
fn update(entities: &mut Entities, dt: f32) {
    assert_eq!(entities.positions.len(), entities.velocities.len());
    for (p, v) in entities.positions.iter_mut().zip(&entities.velocities) {
        *p += *v * dt;
    }
}

let mut entities = Entities {
    positions: vec![0.0, 10.0], velocities: vec![2.0, -1.0], health: vec![1.0; 2],
};
update(&mut entities, 2.0);
assert_eq!(entities.positions, [4.0, 8.0]);
```

Check layout with `std::mem::size_of` / `align_of`. Reordering `#[repr(C)]`
fields changes offsets and can break an established foreign/public ABI; do it
only when the layout contract permits it. Preserve column lengths and entity
identity when using separate arrays; `zip` alone silently truncates.

## Zero-copy parsing

```rust
use std::borrow::Cow;

struct Parsed<'a> { name: Cow<'a, str>, values: &'a [u8] }
// Borrow from the input; allocate only when escaping/decoding forces it.
```

## SIMD and strings

Check compiler vectorization and existing libraries before hand-writing SIMD.
[`std::simd`](https://doc.rust-lang.org/std/simd/index.html) is currently a
nightly-only `portable_simd` API; do not silently change a stable project's
toolchain. Target-specific intrinsics need the applicable feature preconditions
and a supported fallback. Preserve tail elements and define whether floating-point
reassociation, rounding changes, NaNs, and infinities are acceptable before
changing a reduction. Test that contract against a suitable scalar oracle.

`compact_str::CompactString` for small strings; interning for repeated keys.
Prefer integer IDs over dynamic string keys in hot maps.

## Compiler hints

```rust
#[cold] fn handle_error() { }          // request optimization for a rare path
#[inline(always)] fn hot() { }         // a hint to measure, not a speed guarantee
#[inline(never)] fn cold() { }
```

## False sharing

An atomic hotspot or scaling loss does not identify false sharing. Establish
which addresses each worker updates and which cache lines contain them. Updates
to the same location are true sharing: padding cannot remove that contention.
For independently updated locations sharing a line, test target-appropriate
padding against its larger footprint. The following illustrates 64-byte alignment,
not a portable cache-line-size guarantee.

```rust
use std::sync::atomic::AtomicU64;

// Independently written fields may share a line, depending on their placement.
struct AdjacentCounters { inflight: AtomicU64, completed: AtomicU64 }

// Candidate for a target where this separation is sufficient.
#[repr(align(64))]
struct PaddedAtomicU64(AtomicU64);

struct SeparatedCounters { inflight: PaddedAtomicU64, completed: PaddedAtomicU64 }
assert_eq!(std::mem::align_of::<PaddedAtomicU64>(), 64);
```

## Lock contention

Symptom: most time in lock/unlock, throughput falls as threads rise, high
system-time percentage.

This example accepts a positive worker limit, handles empty/short input, and
spawns at most that many scoped workers. It borrows keys while counting and clones
each distinct key once for the owned result. Worker panics propagate after scoped
workers finish; it is not a reusable thread pool or a measured speedup.

```rust
use std::{collections::HashMap, num::NonZeroUsize, thread};

fn parallel_count(data: &[String], limit: NonZeroUsize) -> HashMap<String, usize> {
    let workers = limit.get().min(data.len());
    if workers == 0 {
        return HashMap::new();
    }
    let chunk_len = data.len().div_ceil(workers);
    let counts = thread::scope(|scope| {
        let handles: Vec<_> = data.chunks(chunk_len).map(|chunk| {
            scope.spawn(move || {
                let mut local = HashMap::new();
                for key in chunk {
                    *local.entry(key.as_str()).or_insert(0_usize) += 1;
                }
                local
            })
        }).collect();

        let mut counts = HashMap::new();
        for handle in handles {
            for (key, count) in handle.join().expect("counting worker panicked") {
                *counts.entry(key).or_insert(0_usize) += count;
            }
        }
        counts
    });
    counts.into_iter().map(|(key, count)| (key.to_owned(), count)).collect()
}

assert!(NonZeroUsize::new(0).is_none()); // Reject zero before spawning.
assert!(parallel_count(&[], NonZeroUsize::new(4).unwrap()).is_empty());
let data: Vec<String> = ["a", "b", "a", "c", "b", "a", "d"]
    .into_iter().map(String::from).collect();
let expected = HashMap::from([
    (String::from("a"), 3), (String::from("b"), 2),
    (String::from("c"), 1), (String::from("d"), 1),
]);
for workers in [1, 2, 3, 4, 10] { // Includes uneven partitions and limit > len.
    assert_eq!(parallel_count(&data, NonZeroUsize::new(workers).unwrap()), expected);
}
```

For read-heavy workloads, measure `RwLock<HashMap>` against the existing lock;
read/write ratios alone do not determine a winner. For independent writes,
consider sharding while preserving cross-key invariants and lock ordering.

## NUMA

Symptom: multi-socket server, scaling stalls, memory-migration latency from
work-stealing schedulers moving tasks across nodes.

```bash
numactl --cpunodebind=0 --membind=0 ./target/release/app
```

Measure placement and memory access before/after node binding or node-local pools.
An allocator swap alone does not establish NUMA locality; keep deployment CPU
and memory constraints in the workload contract.

## Data structure selection

| Scenario | Choice | Reason |
|---|---|---|
| Independent concurrent writes | Sharded map | Candidate for less lock contention; cross-shard invariants still matter |
| Read-heavy, few writes | `RwLock<HashMap>` | Concurrent readers; writers still exclude readers |
| Small dataset | `Vec` + linear scan | Hash overhead may dominate; measure |
| Fixed key set | Enum + array | Zero hashing |
| Queue workloads | `VecDeque` | Cache-friendly, no per-node alloc |

## Trap table

| Trap | Symptom | Fix |
|---|---|---|
| One heavily shared atomic | True sharing | Reduce/batch updates or shard and merge |
| Independently updated locations sharing a line | False sharing | Measure target-appropriate separation |
| One global mutex | Lock contention | Shard, then merge |
| Cross-NUMA allocation | Memory migration | Node binding + node-local pools |
| Frequent small allocs | Allocator pressure | Pooling, `SmallVec`, reuse |
| `LinkedList` | Cache misses on traversal | `Vec` / `VecDeque` |
| Clone to dodge lifetimes | Hidden copies | Ownership redesign, borrow |

## Review checklist

- [ ] Profiled; bottleneck measured, not assumed
- [ ] Algorithm and data structure optimal for the access pattern
- [ ] Unnecessary allocations and clones removed
- [ ] Cache-friendly layout; contention minimized
- [ ] Parallelism used only where it pays
- [ ] Correctness tests pass before and after
- [ ] Benchmarks show a repeatable win; code stays readable
