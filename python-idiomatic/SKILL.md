---
name: python-idiomatic
description: >
  Use when writing or reviewing Python language semantics, fixing aliasing,
  mutable defaults, late-bound closures, exhausted generators, import cycles,
  swallowed exceptions, or resource leaks; choosing comprehensions, decorators,
  context managers, match statements, or Python environment/debugging tools.
---

# Python Idiomatic

## Route by symptom

| Task | Load |
|---|---|
| Identity/equality, copying, defaults, scope, numbers/text, ordinary classes | [Language semantics](references/language-semantics.md) |
| Generator exhaustion, comprehensions, zip, match, decorators/caches | [Iteration and decorators](references/iteration-decorators.md) |
| Narrow handlers, exception chaining, cleanup, lazy resource lifetime | [Errors and resources](references/errors-resources.md) |
| Imports, environment mismatch, lint/debug/profile, version gates | [Workflow and versions](references/workflow-versions.md) |

Load only the relevant guide. All guidance needed for this scope is local;
detailed library APIs, architecture, algorithms, concurrency and test methodology
are separate tasks.

## Workflow

1. Read the project's supported Python versions and tool configuration. Establish
   absence semantics, aliasing/mutation, single-pass versus reusable input, and
   resource ownership before changing behavior.
2. Trace the failure through object identities/rebinding, iterator consumption,
   traceback causes, or module execution order. Ask the owner if unresolved
   ownership or data-loss policy determines the fix.
3. Prefer a built-in/stdlib operation or direct loop. Preserve failure, lifetime,
   and execution-model behavior; laziness, copying and argument binding are
   observable contracts, not cosmetic choices.
4. Update affected callers together. For multi-file work, track pending, complete
   and blocked changes/checks.
5. Select checks under repository policy: repeated calls, passed empty containers,
   alias independence, one-shot streams, malformed input and cleanup on failure
   as relevant. Preserve the supported runtime instead of adopting local syntax
   or replacing tools by habit.

## High-risk gotchas

- Assignment and shallow copying share objects; frozen outer containers are not
  deeply immutable. Default arguments and closure capture can retain shared state.
- Preserve valid zero/empty values: use `is None` or a private sentinel for absence.
  An exhausted generator is still truthy.
- Lazy execution defers errors and can retain resources. `break` does not promise
  iterator closure. Never return an iterator over a closed resource or close a
  borrowed stream without ownership transfer.
- Catch expected failures around the smallest relevant operation. Preserve causes
  and consumer failures during cleanup; silent empty results are not recovery.
  Assertions and type annotations do not validate untrusted input.
- Context-manager exit behavior is resource-specific. Decorators must preserve
  arguments, results, exceptions and sync/async/generator execution models.
- Check [version gates](references/workflow-versions.md#version-gates-preserve-the-declared-minimum)
  before adopting syntax or introspection changes. Bundle examples target Python
  3.11+ and stdlib only; newer features are labelled recipes, not baseline checks.

## Completion and evidence

Report the semantic change and affected callers, mutation/resource policy, boundary
cases, exact checks actually run and remaining runtime/version gaps. Do not silently
skip required work or call static review runtime verification.

Optional installed-skill handoffs: **python-stdlib** for library APIs,
**python-api-design** for typing/class protocols, **python-concurrency** for
execution coordination, **python-algorithms** for data structures/complexity,
**python-tdd** for tests, **python-system-design** for packaging/deployment.
None is an installation dependency.

See [README](README.md#sources-and-adaptation) for pinned source coverage,
correction decisions, installation and example commands;
[LICENSE.upstream](LICENSE.upstream) preserves attribution.
