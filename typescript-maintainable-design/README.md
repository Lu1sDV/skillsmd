# typescript-maintainable-design

Review and refactor TypeScript around concrete behavior contracts and dependency boundaries. The [skill workflow](SKILL.md) applies SOLID to coupling, inheritance, interfaces, state, errors, and imports while requiring evidence for performance changes.

## Use

`Use $typescript-maintainable-design to refactor this service's dependencies while preserving its public behavior and failure contract.`

Copy this complete folder, including references and `LICENSE.upstream`, into the skill location supported by your agent.

## References

- [Focused review checklist](references/review-checklist.md): runtime boundaries, substitution, ownership, import cycles, measured performance, and a pass/fail/pass probe for module-boundary rules.

## Source and license

Adapted from [StructWeave TypeScript](https://github.com/nirajkvinit/StructWeave-Algorithms/tree/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript), chapters 09 and 13, at the pinned source snapshot. Retain the bundled [MIT notice](LICENSE.upstream) when copying or redistributing this skill.
