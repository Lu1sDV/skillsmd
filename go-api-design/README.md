# go-api-design

A standalone Go API/design skill for generic contracts, interfaces and method sets,
SOLID tradeoffs, and creation/composition/behavior patterns. Ordinary functions,
values, consumer-owned capabilities and explicit ownership precede factories,
registries and frameworks. All guidance and examples are local; no sibling skill,
external service, third-party package or upstream download is required.

- [Installation](#install-from-a-checkout)
- [Usage prompts](#example-prompts)
- [Reference index](#reference-index)
- [Commands and limits](#runnable-examples-and-verification-limits)
- [Decision records](#consolidation-and-correction-decisions)
- [Pinned source map](#pinned-source-map-and-attribution)

## Install from a checkout

From the repository root:

```sh
mkdir -p ~/.claude/skills
cp -r go-api-design ~/.claude/skills/
```

Preserve changes in an existing installed copy before copying over it; the command
can overwrite same-named files. Keep SKILL.md, all references, examples, this README
and LICENSE.upstream together. Installation is optional and is not performed by
the skill itself.

## Example prompts

- “Review this Go API's constraints, inference and `comparable` panic assumptions.”
- “Why does my pointer method work directly but not satisfy this interface?”
- “Replace these factories with constructors/options without losing validation.”
- “Check our builder and cache for mutable aliases, typed nil and lifecycle errors.”
- “Design an iterator that stops upstream and an observer with safe unsubscribe.”
- “Review this command/state/template implementation for failure-state preservation.”

## Reference index

| File | Coverage |
|---|---|
| [SKILL.md](SKILL.md) | Fast routing, consumer-first workflow, essential guards and version gate |
| [Generics](references/generics.md) | Type sets, constraints, inference, method restrictions, generic collection/result/optional/lazy/cache contracts, stdlib alternatives and version traps |
| [Contracts](references/contracts.md) | Interface behavior, method sets, typed nil, assertions, promotion, all SOLID principles as tradeoffs, dependency/failure ownership |
| [Construction](references/construction-patterns.md) | All seven creation families: singleton, factory method, abstract factory, builder, prototype, object pool, functional options; ordinary constructors first |
| [Composition](references/composition-patterns.md) | Adapter/function adapter, bridge, composite, decorator/Reader/HTTP, facade, flyweight, proxy variants; capability/alias/cache boundaries |
| [Behavior](references/behavior-patterns.md) | Chain, command/jobs, iterator/map/filter/take/pagination/tree, mediator/events/chat, memento, observer, state, strategy, template and visitor; breaker/retry/bulkhead decisions |
| [API examples](examples/api.go) | Generic signatures, Stack clearing, independent Clone/Build, concrete JSON family, validated writer options and real writes |
| [Collaboration examples](examples/patterns.go) | Replayable lazy Take, snapshot observer/unsubscribe and pure state transitions |
| [Named regressions](examples/examples_test.go) | Constraint/runtime traps, method sets, alias isolation, invalid inputs, exact byte boundary, write/EOF errors, cached initialization failure, iterator pulls/replay, self-unsubscribe and rejected transitions |
| [Runnable demo](examples/cmd/demo/main.go) | Builder/clone isolation, JSON encode/decode family, writer options and generic sum |

Five references separate type theory and contract questions from the three pattern
families. The source's repeated examples are consolidated by decision and invariant,
not reproduced as a class-per-pattern catalogue. Optional handoffs by name to
**go-idiomatic**, **go-algorithms**, **go-concurrency**, **go-stdlib**, **go-tdd** and
**go-system-design** do not create installation dependencies.

## Runnable examples and verification limits

From this bundle directory, using an already installed Go **1.25+** toolchain:

```sh
cd examples
GOTOOLCHAIN=local go test ./...
GOTOOLCHAIN=local go run ./cmd/demo
GOTOOLCHAIN=local go vet ./...
GOTOOLCHAIN=local go test -race ./...
```

The isolated module declares `go 1.25.0`, uses only the standard library, and has
no root module or external dependencies. `GOTOOLCHAIN=local` avoids automatic
network toolchain downloads; an older installed toolchain will report that the
module requires a newer version. Race checking additionally needs a supported
platform and its C toolchain/runtime requirements.

Expected demo output:

```text
tags: contracts / independent
title: Go API
sum: 6
```

The Go examples have named behavior/boundary regressions and deterministic
`Example` outputs. Markdown snippets are explanatory; exact executable sources are
linked beside them. The comparison panic regression deliberately recovers only to
assert a documented language trap, not as production error handling.

Verified on 2026-10-29 with Go 1.26.10 linux/amd64 in an isolated bundle copy:
race-enabled tests, `go vet`, and the demo passed. Go 1.25 or older toolchains
were not executed. Local stdlib tests do
not prove SQL/SDK/network compatibility, race freedom of every documented design,
security, allocation savings or production resource-pool correctness. No DB driver,
server, plugin loader or service is hidden behind a mock success implementation.

Core language generics require 1.18; comparable satisfaction changed in 1.20;
`cmp`, `maps`, `slices`, built-in min/max and Once helpers require 1.21; `cmp.Or`
requires 1.22; range-over-function/iter and collection helpers require 1.23; generic
aliases require 1.24. Those gates explain APIs, not certify those older toolchains.

## Consolidation and correction decisions

1. **Keep the entrypoint a router.** Five directly linked references retain detailed
   source coverage without front-loading the full pattern catalogue. Use a concrete
   function/config before a hierarchy; do not introduce a second convention.
2. **Treat SOLID as consumer questions.** No fixed method/line count, mandatory
   service/repository layer, ban on `*sql.DB`, registry-for-every-switch rule or
   second-implementation prerequisite. Useful boundaries can have one implementation;
   small programs can keep concrete dependencies. Method satisfaction is not a
   proof of durability, failure semantics or substitutability.
3. **Correct generic safety and ordering claims.** `comparable` can admit interface
   arguments with uncomparable dynamic values; NaN needs policy. Explain inference
   and no method-specific type parameters. Clear removed collection slots; clones
   are shallow unless copied recursively. Do not binary-search descending data with
   an ascending search, subtract comparison operands that can overflow, or discard
   slice-operation return values. Prefer stdlib utilities over duplicate catalogues.
4. **Correct visibility and nil traps.** An exported constructor can return an
   unexported type usable through inference. Exported members promoted through an
   unexported embedded type can be accessed externally (source Q41 is wrong).
   Typed nil is not a nil interface; automatic address-taking does not change
   interface method sets. Literal nil on successful error returns beats reflection
   in every consumer.
5. **Make initialization and options honest.** Once caches failure, not retries;
   resetting it while callers read state is unsafe. OnceValues re-panics, and Once.Do
   does not rerun after panic. Inject dependencies rather than race-prone global test
   setters. Validate options and final invariants before effects; builders snapshot
   owned data. Source SQL interpolation risks injection, and fake SDK/HTTP methods
   do not establish real work. Encode/decode and writer examples here do real work.
6. **Separate pooling and copying from ownership.** sync.Pool has no retention,
   bound or resource-close guarantee; reset is not secure erasure. Source custom
   pool races sends with Close and accepts closed-channel zero values, while its
   worker-pool submission can block before result draining. Keep these lifecycle
   requirements explicit rather than publish an incomplete replacement. sql.DB
   already pools connections. Gob is schema serialization, not arbitrary deep copy.
7. **Correct composition contracts.** Preserve Reader bytes even with a simultaneous
   error. Embedding/Unwrap alone does not expose optional ResponseWriter capabilities.
   Map locks do not guarantee single-flight loading, invalidation ordering or safe
   mutable aliases; propagate lazy-load errors and authorization failures rather
   than return denial as ordinary content. Facades do not make multi-step migrations
   atomic, and allocation/cache savings need measurement.
8. **Correct callback and iterator lifetime.** Snapshot callbacks under lock, execute
   outside it, and document idempotent unsubscribe/snapshot semantics. Only the owner
   closes a channel; work queues are not broadcast. Take(0) must not start upstream,
   Take(n) must not pull n+1, and early stop must propagate. Error-bearing iterators
   terminate after their error; page fetches need cancellation/error policy.
9. **Correct history and dispatch.** Commands validate byte/UTF-8 boundaries and
   commit history only after success; failed undo/redo preserves history and state.
   State rejects illegal transitions before mutation. Embedding is not virtual
   template dispatch; pass hooks explicitly. Visitor is explicit traversal/dispatch,
   not a reason to make a closed AST extensible. Retries require bounded attempts,
   cancellation before the first attempt and an idempotency/error classification.
   Breakers require first half-open admission and stale-completion policy; bulkheads
   require owned capacity. These remain selection/lifecycle guidance, not certified
   production resilience implementations.

## Pinned source map and attribution

Original synthesis adapted from StructWeave-Algorithms revision
`e2a796e212d431c906c85957ea3c203ce0e2218f`. Chapters 06, 08, 09, 10 and 11 were
read in full by the two bundle writers; selected interface/type sections of 07
and 12 supplement them. Upstream is source material, not authority for corrected
claims. Every meaningful family is retained locally, not delegated to a sibling.

| Pinned upstream chapter | Consolidated destination |
|---|---|
| [06 Generics](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/06-generics.md) | Generics; constraints, functions/types/inference, collections, Result/Optional/lazy/cache, stdlib and algorithm contract map |
| [08 SOLID](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/08-solid-principles.md) | Contracts/workflow; cohesion, extension, substitution, segregation, dependency ownership and composition root |
| [09 Creational](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/09-design-patterns-creational.md) | Construction; all seven families, initialization errors, factories/registries, ownership, options and pool hazards |
| [10 Structural](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/10-design-patterns-structural.md) | Composition; all seven families and practical capability/cache/facade decisions |
| [11 Behavioral](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/11-design-patterns-behavioral.md) | Behavior; all ten named families plus breaker/retry/bulkhead selections |
| [07 Traps](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/07-trap-questions.md) | Selected nil (411–509), receivers (892–1005), equality (1083–1171), aliases/promotion (1245–1316), assertions (1577–1804) |
| [12 Anti-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/12-anti-patterns.md) | Interface sections (499–657), explicit initialization (1143–1201); qualified return-type and interface-size claims |

First-party correction citations are placed next to their guidance:
[Go specification](https://go.dev/ref/spec), [Go FAQ](https://go.dev/doc/faq),
[io](https://pkg.go.dev/io), [sync](https://pkg.go.dev/sync),
[database/sql](https://pkg.go.dev/database/sql), [gob](https://pkg.go.dev/encoding/gob).
The bundle works offline; these links are attribution/correction references.
Upstream is MIT-licensed; the exact original notice is in [LICENSE.upstream](LICENSE.upstream).
