# rust-performance

Evidence-first Rust performance work: define the metric, reproduce the
workload, baseline, profile, fix one cause, prove correctness and improvement.

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

- [`SKILL.md`](SKILL.md) — priority ladder, measurement routing, workflow, hard rules, symptom-to-cause triage
- [`references/optimization-patterns.md`](references/optimization-patterns.md) — allocation, layout, zero-copy, SIMD, false sharing, contention, NUMA
- [`references/measurement-and-profiling.md`](references/measurement-and-profiling.md) — tooling commands, build profiles, benchmark templates, regression gates, report format
