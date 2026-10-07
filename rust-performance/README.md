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
| [huiali/rust-skills](https://www.skills.sh/huiali/rust-skills/rust-performance) | Optimization priority ladder, concrete patterns, false sharing / lock contention / NUMA triage, trap tables |

## Install

```bash
cp -r rust-performance ~/.claude/skills/
```

Or via the marketplace:

```
/plugin install rust-performance@Lu1sDV/skillsmd
```

## Contents

- [`SKILL.md`](SKILL.md) — writing/review guidance, Clippy gates, priority ladder, measurement routing, workflow, hard rules, and symptom-to-cause triage
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
