# python-api-design

A standalone Python API/design skill: static typing and runtime validation,
SOLID, creation/composition/collaboration decisions, and class mechanics that can
break consumer contracts. Functions, dataclasses, small adapters and explicit
composition precede abstract factories or repository layers. No sibling skill,
third-party package, online source, or framework is needed to use the bundle.

- [Installation](#install-from-a-checkout)
- [Example prompts](#example-prompts)
- [Reference index](#reference-index)
- [Commands and version limits](#runnable-examples-and-verification-limits)
- [Design decisions](#consolidation-and-correction-decisions)
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

## Reference index

| File | Local coverage and executable examples |
|---|---|
| [SKILL.md](SKILL.md) | Routing, consumer-contract workflow, high-risk caveats, migration/evidence guard |
| [Typing contracts](references/typing-contracts.md) | Types versus runtime checks, validated byte-range value, TypedDict parsing, protocol presence limits, generic relationships, variance, overloads, version/introspection/checker gates |
| [Creation](references/creational.md) | Singleton, factory method, abstract factory, builder, prototype, object pool; validated options, real text encoders, shallow/deep alias behavior |
| [Composition](references/structural.md) | Adapter, bridge, composite, decorator, facade, flyweight, proxy; UTF-8 adapter, ParamSpec decorator, real gzip/JSON facade |
| [Behavior](references/behavioral.md) | All ten source behavioral patterns plus context-manager/coroutine decisions; strategies, chain, state transitions, command/memento undo, observer cleanup, AST visitor, restoration on error |
| [Class mechanics](references/class-mechanics.md) | Every SOLID principle, state sharing, substitutability, C3/cooperative super, descriptors/properties, slots, subclass hooks/metaclasses; concrete diamond and independent descriptor state |

Five references deliberately separate static typing and class mechanics from the
three pattern families. This keeps runtime validation, MRO, and descriptor traps
available without loading the whole pattern catalogue. Detailed concurrent runtime
implementation, deployment/DB transactions, data structures, everyday idioms, stdlib
catalogues, and testing methodology can hand off by name to the corresponding
optional Python skills; the local examples and design guidance do not depend on them.

## Runnable examples and verification limits

From this bundle directory:

```sh
python3 -m doctest SKILL.md references/*.md
```

All `pycon` fences are stdlib-only, deterministic, local executable examples targeting
Python **3.11+**. Assertions check output, rejection, alias isolation, transition
failure, history behavior, callback cleanup and restoration. Assertions in examples
are tests, not production input validation. No external service, installation, or
network is exercised. Each executable fence supplies its own imports/helpers.

These commands are reproducible check instructions, **not a claim of a passing run**.
Implementation did not run checks; integration owns execution. The available runtime
is CPython 3.14.8, not evidence of Python 3.11–3.13 or another interpreter being
executed. Doctest does not perform static checking, discover missing overload
coverage, prove protocol substitutability, or establish thread safety/security.

Use the consuming project's actual Python minimum and pinned checker/configuration.
The optional checker recipe in the typing reference requires an already available
mypy or Pyright; mypy is absent in the implementation environment. Static examples
and expected rejection cases have not been checker-verified. Dynamic descriptor
examples intentionally illustrate runtime semantics, not a fully overloaded generic
descriptor typing API. No global checker installation is required or recommended.

Newer features are explanatory, not baseline example requirements: Python 3.12 adds
`type`/type-parameter syntax and `typing.override`; 3.13 adds `ReadOnly`, `TypeIs`,
and type-parameter defaults; 3.14 adds default deferred annotations and `annotationlib`.
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
[typing](https://docs.python.org/3.14/library/typing.html),
[ABCs](https://docs.python.org/3.14/library/abc.html),
[annotationlib](https://docs.python.org/3.14/library/annotationlib.html),
[dataclasses](https://docs.python.org/3.14/library/dataclasses.html),
[copy](https://docs.python.org/3.14/library/copy.html),
[functools](https://docs.python.org/3.14/library/functools.html), and the
[descriptor guide](https://docs.python.org/3.14/howto/descriptor.html).
They support version-sensitive corrections; use local guidance offline.
Upstream material is MIT-licensed; the exact original notice is in
[LICENSE.upstream](LICENSE.upstream).
