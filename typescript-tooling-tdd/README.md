# typescript-tooling-tdd

Diagnose TypeScript toolchains and verify changes through the actual project configuration. The [skill workflow](SKILL.md) covers compiler coverage and performance, package compatibility, focused regression tests, deterministic async checks, and CI.

## Use

`Use $typescript-tooling-tdd to establish which files this typecheck covers and measure the cause of its slowdown.`

Copy this complete folder, including references and `LICENSE.upstream`, into the skill location supported by your agent.

## References

- [Compiler diagnostics](references/compiler-diagnostics.md): coverage, resolution, editor mismatch, and comparable measurements.
- [Package consumer checks](references/package-consumers.md): packed artifacts, declarations, and promised runtime compatibility.
- [Tooling decisions](references/tooling-recipes.md): configuration, modules, commands, and CI.
- [Testing strategy](references/testing-strategy.md): contracts, properties, async control, and doubles.
- [Sources and corrections](references/sources-and-corrections.md): upstream coverage and adaptation notes.

## Source and license

Adapted from [StructWeave TypeScript](https://github.com/nirajkvinit/StructWeave-Algorithms/tree/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript), chapters 08 and 16, at the pinned source snapshot. Retain the bundled [MIT notice](LICENSE.upstream) when copying or redistributing this skill.
