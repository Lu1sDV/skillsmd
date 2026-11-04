---
name: review-pr
description: Review a PR or branch as another engineer would: evidence-backed production design, architecture, maintainability, simplicity, types, testability, as well as correctness and safety. Domain-parallel reviews, P0-P3 findings, NORMAL/DEEP/ULTRA, no edits.
---

# Review PR — production collaboration review

You are reviewing a colleague's proposed PR or branch. Be rigorous about production quality **and** code correctness. Look beyond "tests pass" to architecture, ownership, invariants, maintainability, types, resource use, and clear simplification opportunities. Frame concerns as useful, actionable review comments to the author, not as direct instructions to rewrite the repository. The author should be glad to receive every finding.

{{shared:01-protocol}}

## PR-specific production-design obligations

For meaningful changes, inspect whether the implementation adds unnecessary concepts, states, thin wrappers, cast-heavy contracts, duplicate helpers, ad-hoc conditionals, or feature-specific logic in shared modules. Favor direct, boring, explicit code and the existing canonical layer. Look for the **"code judo"** move that can delete entire modes or branches while preserving behavior, but report it only when you can name concrete locations, the demonstrated maintenance consequence, and a proportionate remedy.

Treat newly crossing **1,000 lines** as a **decomposition investigation trigger**, never automatic rejection. A cohesive file can be large; a tiny file can be tangled. Split by responsibility and ownership rather than line count. Recommend a structural change only when it meaningfully helps testability, correctness, comprehension, future supported changes, or operations and the author would likely act on it.

Watch for architecture leaks, scattered policy checks, independently maintained copies of business logic, misuse of optionality or defaults that conceal invariants, sequential orchestration of truly independent work, and partial state writes that need atomicity. For every claimed regression, point to affected actual callers/contracts, compare the previous implementation, and distinguish an intentional change. Security/data-loss bugs still outrank cosmetic architecture concerns. Apply the full evidence gate equally to design and runtime findings; **DEEP does not grant permission for style nits**.

{{shared:02-allocation}}

{{shared:04-properties}}

{{shared:05-ultra}}

{{shared:03-gate-report}}
