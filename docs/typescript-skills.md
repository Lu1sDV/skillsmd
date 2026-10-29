# TypeScript Skills: Macro Topics

Nine reusable skills distilled from the sixteen numbered chapters of the [StructWeave TypeScript guide](https://github.com/nirajkvinit/StructWeave-Algorithms/tree/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript).

**Source snapshot:** `e2a796e212d431c906c85957ea3c203ce0e2218f`

**Reviewed:** 2026-10-29

**Scope:** TypeScript language/runtime, type modeling, collections, algorithms, asynchronous code, software design, tooling, testing, and interview diagnostics.

## Macro-topic catalog

| Macro topic | Skill | Primary chapters | Typical task |
| --- | --- | --- | --- |
| Language and runtime foundations | [typescript-language-runtime](../typescript-language-runtime/SKILL.md) | 01, 07 | Implement or migrate TypeScript with the correct runtime and module assumptions |
| Type modeling and generic APIs | [typescript-type-modeling](../typescript-type-modeling/SKILL.md) | 03, 05 | Model domain states, narrow unknown data, and design reusable type-safe contracts |
| Collections and standard-library APIs | [typescript-collections](../typescript-collections/SKILL.md) | 02, 15 | Select and implement collections with explicit ownership, equality, and complexity |
| Algorithmic problem solving | [typescript-algorithm-patterns](../typescript-algorithm-patterns/SKILL.md) | 04 | Choose a problem-solving pattern, state its invariant, and verify edge cases |
| Asynchrony and concurrency | [typescript-async-concurrency](../typescript-async-concurrency/SKILL.md) | 06; async portions of 15 | Implement bounded work, error propagation, cancellation, retry, and async iteration |
| Tooling, testing, and TDD | [typescript-tooling-tdd](../typescript-tooling-tdd/SKILL.md) | 08, 16 | Diagnose the toolchain and implement changes through focused, meaningful checks |
| Maintainable architecture and code quality | [typescript-maintainable-design](../typescript-maintainable-design/SKILL.md) | 09, 13 | Refactor responsibilities, dependencies, contracts, and ownership without changing supported behavior |
| Design-pattern selection and implementation | [typescript-design-patterns](../typescript-design-patterns/SKILL.md) | 10, 11, 12 | Apply the smallest useful creational, structural, or behavioral pattern |
| Interview reasoning and diagnostics | [typescript-interview-review](../typescript-interview-review/SKILL.md) | 14 | Explain a surprising result, validate a compiler claim, or practice a focused interview question |

## Why these boundaries

Group related chapters around tasks an agent performs. Keep syntax and runtime together because execution choices constrain which syntax works. Combine type-system and utility-type material because they jointly define API contracts. Combine collections and built-in APIs because selection depends on equality, ownership, iteration, and runtime support.

Keep algorithm solving separate from collection implementation: selecting an invariant is a different task from implementing its supporting heap or queue. Keep async orchestration separate because settlement, cancellation, and resource lifetime require their own verification. Combine tooling and TDD so checks run through the actual project configuration.

Separate maintainable design from named design patterns. The former diagnoses responsibilities and contracts; the latter selects an implementation mechanism once a specific source of variation is established. Reserve interview review for explanation and diagnosis; use the domain skill for implementation work.

## Package shape

Each TypeScript skill folder at the repository root is independently usable and contains:

- `SKILL.md`: trigger metadata and a practical workflow.
- `agents/openai.yaml`: a display name, short description, and example invocation.
- `references/`: focused details loaded only when needed.
- `LICENSE.upstream`: the upstream MIT license and attribution.

The main documents intentionally remain short. They specify decisions, invariants, common failure modes, verification, and expected outputs. References retain detailed selection rules and adaptation notes. They are rewritten operational guidance, not verbatim copies of the source chapters or a complete TypeScript textbook.

Use uppercase `SKILL.md` for each skill entry point. Add the complete folder, including its references and license, to the skill location recognized by the consuming agent. Repository storage alone does not install or activate a skill in any particular product.

## Source coverage

All sixteen numbered source chapters have an explicit primary destination. The source README serves as the overview rather than a separate skill.

| Chapter | Source | Primary destination |
| --- | --- | --- |
| 01 | [Syntax quick reference](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/01-syntax-quick-reference.md) | Language and runtime |
| 02 | [Data structures](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/02-data-structures.md) | Collections |
| 03 | [Type system mastery](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/03-type-system-mastery.md) | Type modeling |
| 04 | [Interview patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/04-interview-patterns.md) | Algorithm patterns |
| 05 | [Utility types and generics](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/05-utility-types-generics.md) | Type modeling |
| 06 | [Async patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/06-async-patterns.md) | Async concurrency |
| 07 | [Modern TypeScript](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/07-modern-typescript.md) | Language and runtime |
| 08 | [Tooling and testing](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/08-tooling-testing.md) | Tooling and TDD |
| 09 | [SOLID principles](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/09-solid-principles.md) | Maintainable design |
| 10 | [Creational patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/10-design-patterns-creational.md) | Design patterns |
| 11 | [Structural patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/11-design-patterns-structural.md) | Design patterns |
| 12 | [Behavioral patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/12-design-patterns-behavioral.md) | Design patterns |
| 13 | [Anti-patterns and best practices](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/13-anti-patterns-best-practices.md) | Maintainable design |
| 14 | [Interview trap questions](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/14-interview-trap-questions.md) | Interview review |
| 15 | [Standard-library essentials](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/15-std-library-essentials.md) | Collections; async portions routed to async concurrency |
| 16 | [Test-driven development](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/16-test-driven-development.md) | Tooling and TDD |

## Algorithm and pattern coverage

The algorithm skill covers the source's seventeen families: two pointers, sliding window, binary search, prefix sums, monotonic stacks, hash-map patterns, two heaps, interval merging, cyclic sort, BFS/DFS, backtracking, dynamic programming, greedy methods, topological sorting, union-find, tries, and bit manipulation. Read only the reference relevant to the problem.

The design-pattern skill covers the source's five creational, seven structural, and ten behavioral patterns. It preserves the source's actual scope rather than claiming to cover every named pattern in software design.

## Corrections applied during adaptation

Treat source snippets as learning examples and inspect their contracts before reuse. The new skills address these findings:

| Area | Source issue or limitation | Guidance in this set |
| --- | --- | --- |
| Runtime support | Broad native-TypeScript and version claims | Check actual runtime support; separate stripping, transformation, type checking, and host APIs |
| Type-system history | `satisfies` attributed to the wrong release | Identify it as a TypeScript 4.9 feature when history matters |
| Runtime validation | Guards assert field types after testing only property existence | Check values and every field promised by the predicate |
| Function variance | Reversed callback/substitution examples | Check contravariant parameter direction and method exceptions under the actual compiler settings |
| Async limits | Some sample pools retain settled work or remove the wrong promise | Track exact active tasks, test peak concurrency, and make settlement policy explicit |
| Empty inputs | Minimum-window and LIS examples omit important empty cases | Define empty-input contracts before entering loops or reducing results |
| Traversal complexity | Queue examples repeatedly remove the first array element | Use a head cursor or suitable queue and account for actual operations |
| Immutability | A shallow freeze of a clone is described as deep immutability | Separate copying, ownership, readonly types, and runtime freezing |
| Testing | Some properties compare the same implementation to itself or assume all objects round-trip through JSON | Use independent invariants and a supported input domain |
| TDD | A cleanup example introduces additional validation behavior | Add each new rule through its own behavior test |

Primary references for significant language/tooling corrections: [Node TypeScript support](https://nodejs.org/api/typescript.html), [TypeScript 4.9](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html), [strict function variance](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-6.html), [TypeScript 5.5 narrowing](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-5.html), and [Vitest type checking](https://vitest.dev/guide/testing-types.html). Further source links are bundled with the relevant skill.

## Example requests

- `Use $typescript-language-runtime to diagnose why this TypeScript script compiles but fails under Node.`
- `Use $typescript-type-modeling to model these API states and validate incoming JSON.`
- `Use $typescript-collections to choose and implement a queue for this workload.`
- `Use $typescript-algorithm-patterns to solve this interval problem and justify the invariant.`
- `Use $typescript-async-concurrency to implement a bounded pool with explicit rejection behavior.`
- `Use $typescript-tooling-tdd to reproduce this bug, fix it, and run the relevant project checks.`
- `Use $typescript-maintainable-design to refactor this service while preserving its public contract.`
- `Use $typescript-design-patterns to choose a simple design for interchangeable payment providers.`
- `Use $typescript-interview-review to explain this callback-variance question with a compiler-checked example.`

## Validation performed

- Passed the skill-creator structural validator for all nine skills.
- Checked frontmatter, folder/name agreement, UI metadata, literal invocation names, required attribution, and absence of template placeholders.
- Resolved all 29 local file links in the prepared set and all 66 pinned source-file links, including their section anchors.
- Compiled all four included TypeScript examples with TypeScript 5.8.3 using `strict`, `noUncheckedIndexedAccess`, and `exactOptionalPropertyTypes`.
- Exercised the skills independently on runtime metric validation with a correlated generic property reader, ordered bounded concurrency with first-error handling and draining, and a Unicode-aware minimum-cover substring algorithm.
- Passed the three exercises' compiler and runtime checks under TypeScript 5.8.3 and Node v24.22.1. The algorithm exercise also matched an independent bounded brute-force oracle.

These checks establish package integrity and representative skill behavior. They do not constitute exhaustive testing of every upstream teaching example or every compiler/runtime version. Temporary exercise implementations are excluded from the skill package.

## Repository integration

The suite follows the repository's root-level skill layout and `Use when` description convention. Each skill retains its local references and the upstream MIT notice as `LICENSE.upstream`. The root README links every skill; existing CI discovers the new `SKILL.md` files automatically for validation and manifest generation.

## Attribution

Adapted from [StructWeave-Algorithms](https://github.com/nirajkvinit/StructWeave-Algorithms), copyright (c) 2024-2025 StructWeave Contributors, distributed under the MIT License. The upstream license is included in each skill folder so attribution travels with an independently copied skill.
