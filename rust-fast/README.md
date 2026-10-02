# rust-fast

Write-fast Rust: the decisions that make code fast by construction, and the
mistakes that cost the most when you get them wrong.

Synthesis of 153 sources, weighted toward first-party documentation — The Rust
Performance Book, the Rust Book, Cargo/rustc reference, Tokio docs, and
Clippy's own lint catalog — with measured case studies for the numbers.

| Source class | Contribution |
|---|---|
| The Rust Performance Book (nnethercote) | Allocation costs, `Vec` growth, `Cow`/`SmallVec`/`Rc`, iterators, hashing, build configuration, inlining |
| The Rust Book + std docs | Loop-vs-iterator benchmarks, `collect`/`size_hint` contracts, zero-cost abstractions |
| Cargo / rustc reference | Profile semantics, LTO, codegen-units, monomorphization, build-time levers |
| Tokio docs + blog | Non-preemption, spawn_blocking, channel backpressure, fairness preconditions |
| Clippy lint catalog | The mechanical half of every rule, with group and current behavior |
| Measured case studies | Rayon/SIMD/allocator/contention/compile-time numbers, with their caveats |

## What it covers

- **Allocation** — reserve, reuse buffers, `clone_from`, `Cow`, `SmallVec` vs
  `ArrayVec`, `Rc`/`Arc` clone semantics, `size_hint`
- **Iterators** — the "iterators are slower" myth, the real abstraction-boundary
  cost (measured 60×), `filter_map`, `chunks_exact`, `copied`
- **Data layout** — target-dependent move costs, conditional boxing, flattening, index width,
  why bit-packing lost 30%
- **Hashing** — SipHash vs fxhash vs ahash with rustc's own measurements
- **Concurrency** — atomics vs mutex tables, std vs parking_lot under four
  contention shapes, Tokio blocking and backpressure, Rayon granularity
- **Build config** — LTO, codegen-units, `opt-level`, `target-cpu`, PGO,
  allocators, monomorphization, compile-time levers in the order that works
- **Clippy gates** — the exact lints and groups that catch each mistake

## Install

```bash
cp -r rust-fast ~/.claude/skills/
```

Or via the marketplace:

```
/plugin install rust-fast@Lu1sDV/skillsmd
```

## Structure

```
rust-fast/
├── SKILL.md                        # Mistake/fix table, per-area rules, review gates
└── references/
    ├── anti-patterns.md            # Full catalog: cost, measurement, fix, code
    └── sources.md                  # Every source, primary vs secondary
```

## Relationship to `rust-performance`

| Skill | Question |
|---|---|
| `rust-fast` | "Is this code fast by construction?" — decisions while writing and reviewing |
| `rust-performance` | "Why is this build slow?" — measure, profile, prove the fix |

Hand off to `rust-performance` when you need a baseline or a profile rather
than a code change.