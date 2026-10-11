# rust-tdd

A standalone Rust test-driven-development skill: write an observable failing
behavior, implement the smallest complete fix, then refactor with green evidence.
It applies QA boundary/equivalence thinking to features, bug fixes, and legacy
code, with practical property tests, test doubles, fixtures, async/concurrent/CLI
workflows, Cargo selection, CI, and coverage interpretation.

## Install from this checkout

Run from the repository root:

```sh
mkdir -p ~/.claude/skills
cp -r rust-tdd ~/.claude/skills/
```

The installed bundle is self-contained. References use bundle-relative links;
other skills are optional named handoffs. No plugin marketplace manifest or
marketplace install command is assumed.

## Example prompts

- “Use rust-tdd to add inventory reservations. Exact-stock requests must work;
  insufficient requests must leave stock unchanged.”
- “Use rust-tdd to fix this Rust parser bug. Add the regression before the fix
  and test the adjacent boundaries without broadening the accepted format.”
- “Characterize this legacy Rust component, isolate its clock input, then make
  the approved expiry change using red-green-refactor.”
- “Use proptest to exercise this state transition; keep shrunk failures and
  replace properties that only test the generator.”
- “Review these Tokio and CLI tests for false positives, leaked tasks, and
  nondeterminism. Explain what the coverage report cannot establish.”

## Reference index

| File | Use |
|---|---|
| [SKILL.md](SKILL.md) | Trigger, routing, TDD cycle, complete reservation example, QA gates and handoffs |
| [Workflows and testability](references/workflows-and-testability.md) | Feature/bug/legacy sequences, partition table, functional core, native harness semantics |
| [Properties, doubles, and fixtures](references/properties-doubles-fixtures.md) | proptest strategy/oracle/shrinking recipe, mockall traps, rstest cases and isolation |
| [Scenarios and tooling](references/scenarios-and-tooling.md) | Async lifecycle, asserted threaded reservation example, CLI assertions, Cargo/CI and coverage |
| [Sources](references/sources.md) | Pinned upstream chapters, first-party technical sources, explicit corrections |

## Scope and adaptation decisions

The primary source is StructWeave chapter 18, **Test-Driven Development**, with
chapter 07 test commands and CI consolidated into the scenario reference. TDD is
not folded into a generic testing/tooling skill. The workflow preserves meaningful
red evidence, green implementation, refactoring, failure-state assertions,
proptest shrinking, mockall/rstest decisions, and when a discovery spike or
characterization is more appropriate than forcing test-first work.

Examples are original complete implementations, not upstream's partial email
validator, undefined fixtures, or empty Loom model. Unsupported empirical TDD
statistics, universal coverage targets, and fixed pyramid ratios are omitted.
Property tests do not claim exhaustive input coverage; concurrency tests do not
claim proof over every schedule. Library-specific recipes identify their runtime
or dev-dependency requirements rather than adding dependencies to this repository.

For system-wide strategy, use optional **test-engineering**; for production
runtime design, **rust-concurrency**; for general Cargo/editor/compiler workflow,
**rust-idiomatic**; for measured tuning, **rust-performance**. Each is an optional
handoff, not an installation dependency. Upstream attribution and MIT notice are
in [sources](references/sources.md) and [LICENSE.upstream](LICENSE.upstream).

## Runnable documentation checks

These commands execute every standalone Rust fence in this bundle, from the
repository root, using only `rustdoc` and the standard library:

```sh
rustdoc --test --edition=2024 rust-tdd/SKILL.md
rustdoc --test --edition=2024 rust-tdd/references/scenarios-and-tooling.md
```

For a copied installation, the same checks work without this repository:

```sh
rustdoc --test --edition=2024 ~/.claude/skills/rust-tdd/SKILL.md
rustdoc --test --edition=2024 ~/.claude/skills/rust-tdd/references/scenarios-and-tooling.md
```

Edition 2024 requires Rust 1.85 or later. These are permanent verification
commands, not recorded passing results. The other references contain prose,
command/configuration guidance, and inline project-specific recipes rather than
standalone Rust programs. Optional proptest/Mockall/rstest/Tokio/Loom/coverage
recipes require the target project's compatible dependencies and runtime setup;
the rustdoc checks above do not validate those external integrations.
