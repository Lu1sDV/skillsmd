# typescript-type-modeling

Model TypeScript domain states and API relationships with useful inference and explicit validation boundaries. The [skill workflow](SKILL.md) covers narrowing, generics, mapped/conditional types, branded identities, generated-schema ownership, and accepted/rejected call-site checks.

## Use

`Use $typescript-type-modeling to model these API states and verify that invalid calls are rejected without weakening inference.`

Copy this complete folder, including references and `LICENSE.upstream`, into the skill location supported by your agent.

## References

- [Type-design decisions](references/type-design-decisions.md): representations, brands, schema ownership, generics, utilities, distribution, and specificity.
- [Type-contract checks](references/type-contract-checks.md): positive and negative examples, inference, exhaustiveness, callback variance, and runtime claims.

## Source and license

Adapted from [StructWeave TypeScript](https://github.com/nirajkvinit/StructWeave-Algorithms/tree/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript), chapters 03 and 05, at the pinned source snapshot. Retain the bundled [MIT notice](LICENSE.upstream) when copying or redistributing this skill.
