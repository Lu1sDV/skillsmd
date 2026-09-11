# Optimization Patterns

Concrete Rust fixes, ordered by the priority ladder: algorithm, data
structure, allocations, cache locality, SIMD/parallelism. Apply only after a
profile shows the code is hot.

## Allocations

```rust
// Preallocate known sizes.
let mut vec = Vec::with_capacity(1000);

// Reuse buffers across calls instead of returning fresh Vecs.
fn process_into(items: &[Item], out: &mut Vec<String>) {
    out.clear();
    out.extend(items.iter().map(|i| i.name.clone()));
}

// Small collections on the stack.
use smallvec::SmallVec;
let tags: SmallVec<[String; 4]> = SmallVec::new();
```

Avoid clone-to-satisfy-borrowck; design ownership instead. Pool or reuse
objects under allocator pressure.

## Data-oriented layout

```rust
// AoS: fields of one entity adjacent, but updates touch one field at a time.
struct Entity { position: Vec3, velocity: Vec3, health: f32 }
let entities: Vec<Entity>;

// SoA: one field's array adjacent — cache-friendly for whole-column passes.
struct Entities {
    positions: Vec<Vec3>,
    velocities: Vec<Vec3>,
    health: Vec<f32>,
}
fn update(entities: &mut Entities, dt: f32) {
    for (p, v) in entities.positions.iter_mut().zip(&entities.velocities) {
        *p += *v * dt;
    }
}
```

Check layout explicitly with `std::mem::size_of` / `align_of`; order fields to
kill padding in `#[repr(C)]` structs.

## Zero-copy parsing

```rust
use std::borrow::Cow;

struct Parsed<'a> { name: Cow<'a, str>, values: &'a [u8] }
// Borrow from the input; allocate only when escaping/decoding forces it.
```

## SIMD and strings

```rust
use std::simd::{f32x8, SimdFloat};
fn sum_simd(data: &[f32]) -> f32 {
    let chunks = data.chunks_exact(8);
    let tail = chunks.remainder();
    let acc = chunks
        .map(|c| f32x8::from_slice(c))
        .fold(f32x8::splat(0.0), |a, x| a + x)
        .reduce_sum();
    acc + tail.iter().sum::<f32>()
}
```

`compact_str::CompactString` for small strings; interning for repeated keys.
Prefer integer IDs over dynamic string keys in hot maps.

## Compiler hints

```rust
#[cold] fn handle_error() { }          // move rare paths out of line
#[inline(always)] fn hot() { }         // verified hot, tiny body
#[inline(never)] fn cold() { }
#[target_feature(enable = "avx2")]     // requires unsafe + runtime check
unsafe fn simd_path() { }
```

## False sharing

Symptom: one core saturated, high LLC-load-misses and locked instructions in
`perf stat -d`, more threads makes it slower, hotspots in atomic `fetch_add`.

```rust
// Bad: two atomics share one cache line; cores ping-pong the line.
struct ShardCounters { inflight: AtomicU64, completed: AtomicU64 }

// Good: isolate each counter on its own line.
#[repr(align(64))]
struct PaddedAtomicU64(AtomicU64);

struct ShardCounters { inflight: PaddedAtomicU64, completed: PaddedAtomicU64 }
```

## Lock contention

Symptom: most time in lock/unlock, throughput falls as threads rise, high
system-time percentage.

```rust
// Bad: every thread serializes on one Mutex<HashMap>.
// Good: thread-local shards, merged once at the end.
pub fn parallel_count(data: &[String], n: usize) -> HashMap<String, usize> {
    let handles: Vec<_> = data.chunks(data.len() / n).map(|chunk| {
        let chunk = chunk.to_vec();
        std::thread::spawn(move || {
            let mut local = HashMap::new();
            for k in &chunk { *local.entry(k.clone()).or_insert(0) += 1; }
            local
        })
    }).collect();

    let mut result = HashMap::new();
    for h in handles {
        for (k, v) in h.join().unwrap() {
            *result.entry(k).or_insert(0) += v;
        }
    }
    result
}
```

Read-heavy with rare writes: `RwLock<HashMap>`; concurrent writes: `DashMap`
or sharding.

## NUMA

Symptom: multi-socket server, scaling stalls, memory-migration latency from
work-stealing schedulers moving tasks across nodes.

```rust
#[global_allocator]
static ALLOC: jemallocator::Jemalloc = jemallocator::Jemalloc;
```

Bind work to nodes (`numactl --cpunodebind=0 --membind=0`), allocate per-node
pools, and borrow rather than copy across nodes.

## Data structure selection

| Scenario | Choice | Reason |
|---|---|---|
| Concurrent writes | DashMap / sharded map | Less lock contention |
| Read-heavy, few writes | `RwLock<HashMap>` | Readers do not block |
| Small dataset | `Vec` + linear scan | Hash overhead dominates |
| Fixed key set | Enum + array | Zero hashing |
| Queue workloads | `VecDeque` | Cache-friendly, no per-node alloc |

## Trap table

| Trap | Symptom | Fix |
|---|---|---|
| Adjacent atomics | False sharing | `#[repr(align(64))]` |
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
