# rust-performance

Writing, reviewing, and measuring performant Rust in one bundle. Covers
allocation, iterators, layout, hashing, async/concurrency, build configuration,
and Clippy gates alongside baselines, profiling, benchmarks, and regression checks.

Consolidates the former `rust-fast` bundle into `rust-performance`; there is no
separate skill to install or hand off to. Writing guidance retains its first-party
documentation and measured case-study attribution in [references/sources.md](references/sources.md).

Consolidates and merges three upstream `rust-performance` skills:

| Source | Contribution |
|---|---|
| [full-stack-skills/rust-skills](https://www.skills.sh/full-stack-skills/rust-skills/rust-performance) | Measurement-layer routing, benchmark/regression-gate discipline, memory + binary-size + compile-time tracking |
| [terraphim/terraphim-skills](https://www.skills.sh/terraphim/terraphim-skills/rust-performance) | Correctness-first gate, tooling commands, build profiles, Criterion/hyperfine templates, PR checklist |
| [huiali/rust-skills](https://www.skills.sh/huiali/rust-skills/rust-performance) | Concrete patterns and contention/NUMA topics; fixed optimization ordering and universal gains are deliberately omitted |

## Install

```bash
cp -r rust-performance ~/.claude/skills/
```

Or via the marketplace:

```
/plugin install rust-performance@Lu1sDV/skillsmd
```

## Contents

- [`SKILL.md`](SKILL.md) — compact writing/review gates, section routing, conditional measurement workflow, and completion evidence
- [`references/optimization-patterns.md`](references/optimization-patterns.md) — allocation, layout, zero-copy, SIMD, false sharing, contention, NUMA
- [`references/measurement-and-profiling.md`](references/measurement-and-profiling.md) — tooling commands, build profiles, benchmark templates, regression gates, report format

- [`references/anti-patterns.md`](references/anti-patterns.md) — detailed writing mistakes, costs, measurements, and fixes
- [`references/sources.md`](references/sources.md) — source catalog and corrections for writing guidance

## Consolidation decisions

- Keep one `rust-performance` entry point and all four references: both writing
  decisions and measured diagnosis belong to the same performance workflow.
- Remove cross-skill handoffs and merge hard rules. Profiling is required for
  optimization claims, not for ordinary initial implementation.
- Drop the former blanket 20% clarity threshold: complexity must earn its cost
  on the actual workload, not meet a universal percentage.
- Keep benchmark anecdotes and detailed catalogs in references. Prioritize the
  measured dominant cause instead of a fixed ladder or assumed speedup range.
- Distinguish blocking from async mutex guards and true from false sharing;
  preserve foreign layout and floating-point contracts during optimization.

## Example checks

The dependency-free examples in `optimization-patterns.md` can be checked with
Rust 1.85 or newer:

```bash
rustdoc --test --edition=2024 references/optimization-patterns.md
```

The scoped counting example rejects a zero worker limit through `NonZeroUsize`,
handles empty input and limits larger than the input, and checks uneven partitions
against explicit expected counts. These checks establish example behavior, not
a performance improvement. Benchmark harnesses with project placeholders are
marked schematic and require the consuming project's dependencies and workload.
