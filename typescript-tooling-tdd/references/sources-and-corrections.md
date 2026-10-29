# Sources and Adaptation Notes

Base this skill on StructWeave-Algorithms commit `e2a796e212d431c906c85957ea3c203ce0e2218f`, reviewed on 2026-10-29. Use the pinned links for historical context; check official documentation matching the consuming project's installed versions before applying version-sensitive syntax or configuration.

## Chapter coverage

| Source | Sections adapted | Skill location |
| --- | --- | --- |
| [08-tooling-testing.md](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/08-tooling-testing.md) | Runtime/build tools, compiler configuration, linting, Vitest, debugging, workflow, CI | Main workflow and tooling-decisions reference |
| [16-test-driven-development.md](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/16-test-driven-development.md) | Red-green-refactor, QA cases, properties, doubles, fixtures, coverage, testability, async tests, regression and legacy workflows | Main workflow and testing-strategy reference |

## Correct or qualify the examples

- Do not copy package version recommendations or config schemas as current defaults. Derive them from the actual project and matching official documentation.
- Separate type checking from execution and transpilation. Verify the runtime environment even when the compiler accepts an API or alias.
- Treat the email-validator example as a teaching sequence. The source's final refactor adds local-part and domain rules that change accepted inputs; require new tests for those rules. Do not present its simplified checks as complete email validation.
- Replace tautological sort checks with independent order and multiset assertions against the function under test.
- Restrict JSON round-trip properties to a supported value domain; generic generated objects do not have universal JSON identity.
- Report property-based runs as sampled evidence, not proof over all inputs.
- Use the documented assertion semantics: Vitest `toBe` uses `Object.is`, rather than exactly `===`.
- Avoid carrying over unsupported defect-reduction percentages, benchmark rankings, universal test durations, or exact test-layer ratios.
- Preserve a supported legacy contract during characterization, but do not silently endorse a known defect as the new requirement.

Use official references linked from the other two references for language, runner, and property-testing details. Keep upstream attribution in `LICENSE.upstream` when redistributing the skill.
