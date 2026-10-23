# python-idiomatic

Task-oriented Python language semantics, readable iteration, decorators,
exceptions/resource ownership, imports, and day-to-day tooling. Self-contained:
no sibling skill installation or upstream checkout is needed to use it.

## Install

From the skillsmd checkout (preserve local changes before replacing an existing
installation):

```sh
mkdir -p ~/.claude/skills
cp -r python-idiomatic ~/.claude/skills/
```

## Usage

- “Why do calls to this function share items, and how can I preserve a passed list?”
- “Review this generator pipeline for exhaustion and resource lifetime bugs.”
- “Make this decorator preserve arguments, results, metadata, and exceptions.”
- “Fix this import cycle without adding a module cache or sys.path hack.”
- “Check these Python 3.14 examples against our Python 3.10 minimum.”

## Reference index

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Concise trigger, symptom routing, workflow and high-risk rules; examples live in the references |
| [Language semantics](references/language-semantics.md) | Values, numbers/text, mutation/copying, defaults, scope, ordinary classes |
| [Iteration and decorators](references/iteration-decorators.md) | Comprehensions, iterator consumption, match/loop flow, wrappers/caches |
| [Errors and resources](references/errors-resources.md) | Narrow handlers, chaining, context managers, ownership, GC |
| [Workflow and versions](references/workflow-versions.md) | Environments, imports, analysis/debug/profile tools, compatibility |

## Runnable examples and runtime limits

From this bundle directory:

```sh
python3 -m doctest references/*.md
```

`pycon` examples are standard-library-only, deterministic, and intended for Python
3.11+. They include assertions/expected outcomes for aliasing, empty arguments,
iterator exhaustion/misalignment, rejected values, and cleanup after failure.
No checks were run during authoring; integrated validation is owned by the parent.
The command tests examples, not every prose claim, every supported Python version,
OS behavior, free-threaded build, optional tool, or real application integration.
Shell/tool recipes need their named environment/tools and are not doctests.
Python 3.11–3.14 features are explicitly gated; no newer syntax is parsed by the
3.11 examples. Remote process debugging requires platform/permission support and
authorized targets. No network, filesystem fixture, third-party package, or
special runtime is required by the doctests.

## Sources and adaptation

Original synthesis adapted from StructWeave-Algorithms at Python-content commit
`0b88a786ef09681717a805d9f7e0b195ab610f6c` by StructWeave Contributors. The original
MIT notice is retained verbatim in [LICENSE.upstream](LICENSE.upstream).

| Pinned source | Local coverage / intentional boundary |
|---|---|
| [01 — Syntax quick reference](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/01-syntax-quick-reference.md) | Full chapter read: assignment/types/numbers/strings/functions/classes → language; flow/match → iteration; errors → resources; version features → workflow. Typing architecture → optional python-api-design; concurrency/interpreters → python-concurrency; compression → python-stdlib; complexity/import algorithm catalogue → python-algorithms. |
| [03 — Pythonic idioms](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/03-pythonic-idioms.md) | Full chapter read: comprehensions/generators/decorators/unpacking/walrus/iteration → iteration; EAFP/context managers → resources; mutability/closure/type traps → language. Detailed grouping/cache APIs → optional python-stdlib; memoized DP → python-algorithms. |
| [08 — Tooling and testing](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/08-tooling-testing.md) | General debugging/formatting/lint/environments/project configuration/profiling → workflow. Packaging structure → optional python-system-design; tests/test CI → python-tdd. |
| [13 — Anti-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/13-anti-patterns-best-practices.md) | Mutable defaults/closures, exception handling, memory/performance, code style, imports → four references. Class design → optional python-api-design; concurrency → python-concurrency; testing → python-tdd. |
| [14 — Interview traps](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/14-interview-trap-questions.md) | Identity/defaults/closures/copies/LEGB/list repetition/class state/dictionary behavior/interning → language; generator exhaustion → iteration; reference counting/GC → resources. MRO/new/descriptors/metaclasses → optional python-api-design; GIL/async → python-concurrency. |

### Consolidation and correction decisions

- Organize by failure/task, not chapter. Keep ordinary object semantics here;
  detailed architecture and library catalogues are named optional handoffs, not
  external file dependencies. Prefer functions/direct loops over pattern scaffolds.
- Keep detailed choices and examples in the four directly linked references.
  The former entrypoint's `add_item` doctest duplicated the reference's
  `append_tag` default/empty-container regression; retain that regression locally
  rather than teaching it twice.
- Preserve passed empty containers with `is None`; reject the upstream summary's
  `items or []` fix. Default-value capture retains an object reference; it does
  not create a closure cell or recursively freeze a value.
- Remove deterministic claims about integer/string/tuple identity, exact refcounts,
  fixed object sizes, and fixed speedups. These vary with implementation/build,
  compilation context, input, and measurement setup.
- A shallow tuple copy need not make a new tuple; `deepcopy` preserves graph
  relationships and custom semantics rather than guaranteeing universal isolation.
  Frozen dataclasses are not deeply immutable; cycles alone do not prove leaks.
- Don't reproduce a mutable, value-hashed Vector, comparison methods that assume
  operand attributes, or a constructor bypassing property validation.
- `raise ... from None` hides exception context display, not its traceback.
  Correct manual `try/finally` is valid; upstream's open-before-try example does
  not enter that finally if acquisition fails. Prefer `with` for clarity, not
  because that example inherently references an unbound handle.
- Resource-owning generators need deterministic closure on early termination;
  context-manager exit is not universally transaction/closure/atomicity behavior.
- Groupby groups adjacent runs: sorting is needed for global grouping, not all
  uses. Strict zip detects mismatches during consumption, not before effects.
- F-string opposite-quote interpolation existed before 3.12; gate quote reuse
  and grammar relaxations correctly. T-strings don't sanitize SQL; deferred
  annotations don't enforce runtime argument types. Keep newer syntax out of
  baseline doctests, retain portable parenthesized except clauses, and use the
  documented `disable_remote_debug` flag spelling rather than upstream's hyphens.
- Ruff isn't a complete drop-in replacement for all Pylint/Flake8 capabilities;
  retain existing tool policy. Use monotonic duration clocks and measured workload
  evidence, not wall-clock timers or unconditional performance claims.

References include first-party Python documentation links for semantic and
version-sensitive details; links are supporting citations, not required reading
or network dependencies at skill use time.
