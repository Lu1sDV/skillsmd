# python-api-design

A standalone Python API/design skill: public compatibility, checker operations,
static typing and runtime validation,
SOLID, creation/composition/collaboration decisions, and class mechanics that can
break consumer contracts. Functions, dataclasses, small adapters and explicit
composition precede abstract factories or repository layers. No sibling skill,
third-party package, online source, or framework is needed to use the bundle.

- [Installation](#install-from-a-checkout)
- [Example prompts](#example-prompts)
- [Reference index](#reference-index)
- [Commands and version limits](#runnable-examples-and-verification-limits)
- [Design decisions](#consolidation-and-correction-decisions)
- [Selective community integration](#selective-community-integration-2026-11-03)
- [Source map and attribution](#pinned-source-map-and-attribution)

## Install from a checkout

From the repository root:

```sh
mkdir -p ~/.claude/skills
cp -r python-api-design ~/.claude/skills/
```

Preserve local changes in an existing installed copy before replacing it. Keep
`SKILL.md`, all references, this README, and `LICENSE.upstream` together. Installation
is optional and is not performed by the skill itself.

## Example prompts

- “Review this Python API for annotation/validation confusion and mutation leaks.”
- “Choose a callable, Protocol, ABC, or concrete dependency for these consumers.”
- “Replace this factory/repository hierarchy with explicit composition where safe.”
- “Design undo/redo and observer delivery with clear failure and lifetime semantics.”
- “Explain why this mixin, descriptor, or frozen dataclass violates the public contract.”
- “Can we change this default or response field without breaking current clients?”
- “Make our type-checking gate cover public consumers and the installed package.”

## Reference index

| File | Local coverage and executable examples |
|---|---|
| [SKILL.md](SKILL.md) | Routing, consumer-contract workflow, high-risk caveats, migration/evidence guard |
| [Evolution and public surface](references/evolution.md) | Consumer-directed compatibility, public exports, default migration with a 3.15 sentinel, deprecation, HTTP input/output schemas, generated-client and route review |
| [Checker operations](references/checker-operations.md) | Scope and toolchain, untyped-code coverage, strictness migration, suppressions, installed `py.typed` and positive/negative consumer checks |
| [Typing contracts](references/typing-contracts.md) | Types versus runtime checks, validated byte-range value, TypedDict parsing, protocol presence limits, generics, variance, overloads, optional Pydantic boundaries and version/introspection gates |
| [Creation](references/creational.md) | Singleton, factory method, abstract factory, builder, prototype, object pool; validated options, real text encoders, shallow/deep alias behavior |
| [Composition](references/structural.md) | Adapter, bridge, composite, decorator, facade, flyweight, proxy; UTF-8 adapter, ParamSpec decorator, real gzip/JSON facade |
| [Behavior](references/behavioral.md) | All ten source behavioral patterns plus context-manager/coroutine decisions; strategies, chain, state transitions, command/memento undo, observer cleanup, AST visitor, restoration on error |
| [Class mechanics](references/class-mechanics.md) | SOLID, state sharing, deliberate dataclass policies, secret representation, operator fallback, substitutability, C3/cooperative super, descriptors, subclass hooks and metaclasses |

Seven references separate compatibility, checker operations, static typing and
class mechanics from the three existing pattern families. This keeps runtime
validation, MRO and descriptor traps
available without loading the whole pattern catalogue. Detailed concurrent runtime
implementation, deployment/DB transactions, data structures, everyday idioms, stdlib
catalogues, and testing methodology can hand off by name to the corresponding
optional Python skills; the local examples and design guidance do not depend on them.

## Runnable examples and verification limits

From this bundle directory:

```sh
python3.15 -m doctest SKILL.md references/*.md
```

Guidance and new-project examples target stable **Python 3.15**. The
[official downloads page](https://www.python.org/downloads/) listed **3.15.2** as
the latest stable release when checked on **2026-11-03**. Preserve an existing
project's declared Python minimum; do not raise it merely to copy an example.

All `pycon` fences are stdlib-only, deterministic, local executable examples.
The evolution example uses the 3.15 builtin `sentinel`; older examples retain
compatible spellings where a rewrite would add no clarity. Assertions check
output, rejection, alias isolation, transition
failure, history behavior, callback cleanup and restoration. Assertions in examples
are tests, not production input validation. No external service, installation, or
network is exercised. Each executable fence supplies its own imports/helpers.

On 2026-11-03 the bundle's runtime doctests passed with **CPython 3.15.2**.
The evolution sentinel example also passed a focused **mypy 2.4.1**, strict,
Python-3.15-target check: its accepted consumer retained `tuple[str, ...]`, while
integer-list and string-`sort` consumers produced the intended `list-item` and
`arg-type` diagnostics. Omitted and explicit defaults were checked separately,
including one caller-attributed `DeprecationWarning` for omission.

This is not a claim that every code fragment was statically checked or that other
Python versions/interpreters were executed. Doctests do not discover missing
overload coverage, prove substitutability, or establish thread safety/security.
Dynamic descriptor examples illustrate runtime semantics, not a fully overloaded
generic descriptor API. Pydantic/FastAPI notes were checked against primary docs;
no framework integration or generated SDK was exercised by these stdlib tests.
Use the consumer's pinned checker/configuration; no global checker installation is
required by the skill.

Version gates remain useful for existing projects: Python 3.12 adds
`type`/type-parameter syntax and `typing.override`; 3.13 adds `ReadOnly`, `TypeIs`,
and type-parameter defaults; 3.14 adds default deferred annotations and `annotationlib`;
3.15 adds `sentinel`, `frozendict`, `TypeForm` and closed/extra-item TypedDict contracts.
Future annotations do not backport newer syntax. Runtime protocol lookup changes
in 3.12, and `cached_property` no longer carries its former lock from 3.12 onward.
The reference records these limits instead of extrapolating one runtime's results.

## Consolidation and correction decisions

- **Keep the entrypoint a router.** Move the unique validated `ByteRange` example
  unchanged to typing contracts and the SOLID table to class mechanics. Keep all
  pattern families and executable examples local, with contents lists for longer
  documents; do not require the whole catalogue for an ordinary API change.

- **Keep SOLID as consumer-contract questions.** Remove arbitrary method/line-count
  thresholds, required service/repository layers, and automatic replacement of closed
  branching with registries. A useful protocol can describe a single external
  implementation; implementation count alone does not decide whether a boundary helps.
- **Separate typing from validation.** TypedDict is an ordinary runtime dict;
  Protocol signatures, Literal/NewType/Final/ReadOnly, casts, and annotations do not
  validate data. `runtime_checkable` checks presence, not signatures or behavior.
  ABC enforcement occurs when instantiating an abstract subclass, not at its definition.
- **Correct generic promises.** An `int` bound does not make `x + 1` preserve an
  arbitrary subtype `T`. `Never` and `NoReturn` have equivalent bottom-type meaning.
  Preserve callback signatures with ParamSpec; do not replace missing evidence with Any.
- **Gate annotation behavior.** Deferred evaluation is the 3.14 default, not a
  universal zero-cost property; future-import stringification is a different model.
  Resolution/introspection can execute code and fail on unavailable names.
- **Keep all source families without class-per-pattern boilerplate.** Cover six
  creational families (including object pool), seven structural families, and ten
  behavioral families. Prefer stdlib operations to placeholder transports, fake
  video codecs, XOR “encryption,” printed SQL, and pretend payment success.
- **Correct ownership/immutability claims.** Frozen records and read-only views are
  shallow unless their contents are also immutable. `deepcopy` is not guaranteed
  independence of resources; `dataclasses.replace` is not a deep copy. Builders
  must snapshot mutable state and define reuse, not share recipients across results.
- **Correct singleton/pool/cache implications.** Module identity is per interpreter,
  not process-wide distributed uniqueness. Allocation locks do not secure later
  initialization. Pool capacity must include checked-out/reserved resources, and
  rejected resources need disposal; queue coherence is not full pool correctness.
- **Correct wrapper and memory claims.** `__getattr__` does not forward implicit
  special methods. `wraps` preserves metadata, not semantic compatibility. Slots do
  not share/intern payloads or imply fixed memory savings; repeated references are
  not repeated copies of a texture's bytes. Cache keys must include all intrinsic
  state, and cache presence must not be tested by truthiness.
- **Correct behavioral edge cases.** Empty pages can still have a next cursor;
  command failure must not corrupt undo/redo, and undo need not exist for irreversible
  commands. Observer delivery requires failure/reentrancy/unsubscribe policy; one
  queue is competing-consumer work, not broadcast. `singledispatch` is single dispatch.
  Temporary restoration must distinguish missing from present-with-None.
- **Correct class traps.** Inherited B must precede its ancestor A in C3 order, not
  follow it. Descriptor class access needs an explicit policy and state must live
  per instance. `__set_name__` is not called automatically on later assignment;
  metaclass class creation and instance construction are different phases.

## Selective community integration (2026-11-03)

The supplied candidate review was a discovery map, not verification. Relevant
source files were read directly; retained runtime/library claims were checked
against the primary references linked in the destination. The table pins the
inspected sources. The new guidance and examples are an independent synthesis;
community scripts and framework templates were neither executed nor vendored.

| Candidate source at inspected revision | Decision and destination |
|---|---|
| [wdm0006 API design](https://github.com/wdm0006/python-skills/blob/456ad29b98671a310dcb56165c6f0d7c63ca2c19/skills/python/api-design/SKILL.md) and [evolution](https://github.com/wdm0006/python-skills/blob/456ad29b98671a310dcb56165c6f0d7c63ca2c19/skills/python/api-design/EVOLUTION.md) | **Adapt** public-import checks, omitted/default transitions and honest result completeness into `evolution.md`. Reject universally safe additive fields, appended NamedTuple safety, exhaustive `__all__` guarantees and mandatory major-version policy. |
| [PostHog dataclasses](https://github.com/PostHog/posthog/blob/b8095bf610dfadb1fb5b10193d34d2fafcc7468a/.agents/skills/writing-dataclasses/SKILL.md) | **Adapt** constructor/layout/representation choices into class mechanics. Keep NamedTuple when tuple behavior is intended; freezing neither deeply freezes values nor guarantees successful hashing. No project-specific decorator or numeric tuple threshold. |
| [Polar API surface](https://github.com/polarsource/polar/blob/62fe70c438c17e45065542b1944743f722702381/.agents/skills/api-surface-review/SKILL.md) | **Adapt** server/schema/client review into evolution. Correct input versus output defaults; treat schema hiding as a contract change. Reject mandatory Int32, universal union names, status-per-error and unfiltered-list policies. |
| [Paldom typing operations](https://github.com/paldom/python-skills/blob/70aa0cf9926285dbef6ac39bc36990ece230cd09/skills/python-typing/SKILL.md) | **Adapt** pinned tooling, coverage, gradual strictness and artifact checks. Correct mypy per-module override support and missing-marker consequences. Omit checker popularity rankings, stale version pins and blanket error suppression. |
| [Pydantic guidance](https://github.com/pydantic/pydantic/blob/77fad186682d0c22cad713e34ca9b8b830362ed0/.agents/skills/pydantic/SKILL.md) | **Adapt** field metadata, validation and declared-type serialization into typing contracts. Do not ban future annotations, decorator validators or internal models categorically. Keep dependency-specific behavior optional. |
| [Google ADK typing](https://github.com/google/adk-python/blob/766275863d1e80489344f0fbe5b4bfa3b933a9a9/.agents/skills/adk-style/references/typing.md) | **Adapt** justified casts/suppressions and behavior-preserving typing changes; retain real boundary validation. Do not adopt house import/visibility rules or annotations-everywhere churn. |
| [SD.Next API review](https://github.com/vladmandic/sdnext/blob/6657d06112ed8e924e93eed099af44ea8d892417/.github/skills/check-api/SKILL.md) | **Adopt** the need to follow delegated route registration and distinguish runtime schema inspection from static review. No application-specific route inventory. |
| [wispbit operator rule](https://github.com/wispbit-ai/skills/blob/8b2c7d0ceca0204634dd308970629c4cd4a5a05f/skills/python-expert-best-practices-code-review/rules/operators-return-notimplemented.md) | **Adapt** operator fallback into class mechanics. Reject the claim that every augmented operator must mutate and return `self`. |
| [nathan-gage review index](https://github.com/nathan-gage/python-skills/blob/c5b961b32447e1be7dedea45ef166e74bb987f77/skills/python-best-practices/SKILL.md) and [pprm11 idioms](https://github.com/pprm11/persona/blob/32cb10ee314cab6ba6ba61490a0e32dcd6c29f90/skills/python-idioms/SKILL.md) | **Adapt** evidence before a finding and independent test expectations into the workflow. The 75-rule catalogue and general test methodology are not imported. |
| [pproenca's Python design-pattern kit](https://github.com/pproenca/dot-skills/blob/cf93c57cac89d6fc3e4194686000411567f5caf3/skills/.experimental/implementation-design-patterns-python/SKILL.md) ([gotchas](https://github.com/pproenca/dot-skills/blob/cf93c57cac89d6fc3e4194686000411567f5caf3/skills/.experimental/implementation-design-patterns-python/gotchas.md)) | **Adapt narrowly:** problem-shape activation cues; distinguish factory lookup failures from constructor failures; explicit traversal order, visitor expansion cost and concurrent-cache limits. **Do not import** the overlapping 22-pattern catalogue or examples that overpromise singleton creation, deferred undo, observer unsubscribe behavior or flyweight memory savings. No community code vendored. |

Other proposal clusters were screened by scope and overlap rather than treated
as automatically approved additions:

| Proposal cluster | Decision |
|---|---|
| New `configuration.md` | **Reject duplication.** Keep one API injection/boundary note; startup sources, secrets and precedence belong to system design. |
| FastAPI/Django/SQLModel/CLI/agent templates and framework release anecdotes | **Defer.** Preserve general contract checks and the few verified Pydantic/FastAPI schema nuances above. No extra framework catalogue, preferred stack, or unverified HEAD-only feature recipes. |
| Database migration guide | **Route to system design.** Database locks, expand/contract rollout and transaction ownership need their own consequential boundary evidence. |
| Refactor playbook, architecture-score matrix and constructor-size thresholds | **Reject expansion.** Existing consumer/invariant decisions cover the need; fixed sizes and mandatory interview rounds do not establish a defect. |
| Error envelopes, exception groups, cancellation and everyday hygiene | **Keep existing ownership.** Preserve public error/completeness contracts here; general error/resource mechanics remain with python-idiomatic/concurrency. |
| Pagination/testing workflow catalogues | **Adapt narrowly.** Keep stable order, continuation validation and independent consumer expectations; avoid database/test infrastructure templates. |

Unretained claims about framework versions, security advisories or particular
community defects are not independently certified by this table. They are not
required to use the skill and were not promoted into its instructions.

## Pinned source map and attribution

Original synthesis adapted from StructWeave-Algorithms, Python-content revision
`0b88a786ef09681717a805d9f7e0b195ab610f6c`. The main chapters were read in full;
class-design and copy/MRO/descriptor/metaclass sections were selected from the trap
chapters. Upstream is source material, not the authority for corrected claims.

| Pinned upstream chapter | Consolidated destination |
|---|---|
| [06 Modern type hints](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/06-type-hints-modern.md) | Typing contracts; baseline/version/introspection guidance |
| [09 SOLID](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/09-solid-principles.md) | SKILL workflow and class-mechanics SOLID table; consumer-owned capabilities |
| [10 Creational](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/10-design-patterns-creational.md) | Creation, copying, initialization, resource ownership |
| [11 Structural](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/11-design-patterns-structural.md) | Composition, wrappers, sharing and facade recipes |
| [12 Behavioral](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/12-design-patterns-behavioral.md) | Behavior, history, event delivery, traversal and scoped restoration |
| [13 Anti-patterns: class design](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/13-anti-patterns-best-practices.md) | Class mechanics; construction and mutable-state guardrails |
| [14 Traps: class/API selections](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/14-interview-trap-questions.md) | Copying, class/instance state, MRO, descriptors, metaclasses |

First-party correction references, also linked near their guidance:
[typing](https://docs.python.org/3.15/library/typing.html),
[ABCs](https://docs.python.org/3.15/library/abc.html),
[annotationlib](https://docs.python.org/3.15/library/annotationlib.html),
[dataclasses](https://docs.python.org/3.15/library/dataclasses.html),
[copy](https://docs.python.org/3.15/library/copy.html),
[functools](https://docs.python.org/3.15/library/functools.html), and the
[descriptor guide](https://docs.python.org/3.15/howto/descriptor.html).
They support version-sensitive corrections; use local guidance offline.
Upstream material is MIT-licensed; the exact original notice is in
[LICENSE.upstream](LICENSE.upstream).
