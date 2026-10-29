# typescript-language-runtime

Align TypeScript's static contracts with the JavaScript execution path. The [skill workflow](SKILL.md) covers runtime validation, nullish values, functions/classes, module boundaries, migrations, and feature compatibility.

## Use

`Use $typescript-language-runtime to diagnose why this TypeScript script compiles but fails under Node.`

Copy this complete folder, including references and `LICENSE.upstream`, into the skill location supported by your agent.

## References

- [Runtime boundary validation](references/runtime-boundaries.md): validate external values before promising a type.
- [Runtime compatibility](references/runtime-compatibility.md): type stripping, transforms, modules, decorators, and host API support.

## Source and license

Adapted from [StructWeave TypeScript](https://github.com/nirajkvinit/StructWeave-Algorithms/tree/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript), chapters 01 and 07, at the pinned source snapshot. Retain the bundled [MIT notice](LICENSE.upstream) when copying or redistributing this skill.
