# go-idiomatic

Everyday Go semantics, ownership, error handling and tooling decisions. Start at
[SKILL.md](SKILL.md); library catalogues, API theory and testing methodology are
intentionally separate topics, not required installations.

## Install and use

From the repository root, first check that `~/.claude/skills/go-idiomatic` does not
already contain a local installation you need to preserve. Copy only into an absent
destination; if it exists, compare/merge deliberately rather than overwriting:

```sh
mkdir -p ~/.claude/skills
cp -r go-idiomatic ~/.claude/skills/
```

Example prompts:

- “Explain why this append overwrites another slice; preserve caller ownership.”
- “Fix this Go error-shadowing/resource-cleanup path without hiding close errors.”
- “Review Go 1.22 loop captures against this module's language version.”
- “Check UTF-8 and integer-boundary behavior, not just ASCII happy paths.”

## Reference index

| Reference | Scope |
|---|---|
| [Language semantics](references/language-semantics.md) | Declarations, functions/control flow, receivers, nil, assertions, equality |
| [Values and storage](references/values-storage.md) | Aliases/backing arrays, map operations, text and numeric boundaries |
| [Errors and resources](references/errors-resources.md) | Wrapping, shadowing, defer/close ownership, panic versus exit |
| [Workflow and versions](references/workflow-versions.md) | Names, imports/init, modules/tools, feature gates and diagnostic limits |

## Runnable examples and limits

[examples](examples/go.mod) is a standalone stdlib-only module requiring **Go 1.25+**
(`go 1.25.0`). Core operations are older; loop declaration examples require Go 1.22
language semantics and `errors.Join` requires Go 1.20. No lower version is certified.
Verified on 2026-10-29 with Go 1.26.10 linux/amd64 in an isolated bundle copy:
race-enabled tests, `go vet`, and the real temporary-file demo passed.

From the repository root (or substitute an isolated copied bundle path):

```sh
cd go-idiomatic/examples
GOTOOLCHAIN=local go test ./...
GOTOOLCHAIN=local go vet ./...
GOTOOLCHAIN=local go run ./cmd/demo
```

Expected demo output:

```text
loops: declared [1 2 3] assigned [3 3 3]
storage: abcd zb
UTF-8: A世
overflow rejected; file limit enforced
```

The demo performs explicit failure checks, creates/reads a real temporary file,
rejects oversized content, removes its temporary directory and exits nonzero on
failure. Named tests and Go Example output checks cover independent prefix storage,
capacity-limited aliasing, negative/excess lengths, valid replacement rune versus
invalid UTF-8, zero/exact/overflow integer boundaries, missing-file error identity,
empty/exact/oversized files and declared-versus-assigned captures. They do not
inject OS close failures, prove absence of descriptor leaks, measure allocations,
prove race freedom or certify cross-platform/version support.

For formatting use `gofmt -w` on changed Go files under repository policy. Broader
race/fuzz/benchmark recipes route to **go-tdd**, not this example's acceptance claim.
No network access, external tools, root module, sibling installation or upstream
checkout is needed for these examples once a suitable Go compiler is installed.

## Sources and complete coverage

Adapted from StructWeave-Algorithms, pinned to
[`e2a796e212d431c906c85957ea3c203ce0e2218f`](https://github.com/nirajkvinit/StructWeave-Algorithms/tree/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang).
The upstream [MIT notice](LICENSE.upstream) is included verbatim. All four primary
chapters were read fully; section-level mapping below records both local ownership
and intentional topic handoffs. Handoffs are named topics, not links required to
make this bundle work.

| Primary chapter and sections | Local treatment or explicit topic handoff |
|---|---|
| [01 Syntax](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/01-syntax-quick-reference.md): Variables & Types; Control Flow; Functions; Pointers; Structs & Methods | Language semantics; values/storage; defer in errors/resources; embedding basics local, composition design → go-api-design |
| 01: Interfaces; Type Assertions & Type Switches | Nil/assertion/method-set/equality mechanics local; interface contracts, optional capability API design → go-api-design; heap extraction → go-algorithms; context values → go-concurrency; JSON boundaries → go-stdlib |
| 01: Generics (before/after, syntax, constraints, patterns, aliases) | Feature gates local; generic signatures/type sets/performance tradeoffs → go-api-design; generic stack/Map/Filter and sorting use → go-algorithms |
| 01: Error Handling; String Operations; Type Conversions; Quick Reference Card | Errors/resources; text/numbers/storage; detailed strings/strconv APIs → go-stdlib; goroutines/channels → go-concurrency; collection operations → go-algorithms |
| [05 Idioms](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/05-idioms-best-practices.md): Naming Conventions; Error Handling; Memory Management | All local across four guides, interface naming mechanics local |
| 05: Interface Design | Nil/type-switch mechanics local; accept/return contracts, small/composed interfaces and compile-time satisfaction checks → go-api-design |
| 05: Testing (basic, tables, benchmarks/B.Loop, fuzz, helpers) | go-tdd; named tests here demonstrate semantics rather than duplicate testing instruction |
| 05: Structured Logging (slog, handlers, context, attributes) | go-stdlib; request tracing/operational policies → go-system-design; version gate/secret-logging caution local |
| 05: Modern Tooling (tool directive, lint, workflow, profiling, JSON tags) | Module/tool/linter workflow and profiling safety local; JSON omitzero/omitempty → go-stdlib; coverage/bench/race → go-tdd; production diagnostics and builds/deployment → go-system-design |
| 05: Common Pitfalls 1–6; Go Proverbs; Interview Code Style; Quick Reference; Resources/Tools | Nil/append/capture/comparison local; proverbs qualified in workflow; solution structure/helpers/complexity local, actual two-sum/profit/grid algorithms → go-algorithms; resource/tool links remain optional further reading |
| [07 Traps](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/07-trap-questions.md): §1 Q1–5 slices/arrays; §2 Q6–10 maps | Values/storage, including shared rows/retention/non-addressable values; Q9 concurrent map safety → go-concurrency |
| 07: §3 Q11–13 channels; §13 Q42–44 concurrency | go-concurrency: nil/open/closed operations, buffered drain, leaks, WaitGroup timing, select/default; Q43 sync-copy mechanics also local |
| 07: §4 Q14–16 interface nil; §5 Q17–21 defer | Language semantics; errors/resources; reflection nil helper deliberately replaced by explicit contracts |
| 07: §6 Q22–25 strings/runes; §7 Q26–28 loops | Values/storage and language semantics; concurrent execution/lifetime of Q28 → go-concurrency |
| 07: §8 Q29–31 receivers; §9 Q32–34 init; §10 Q35–37 equality | Language semantics; workflow; interface method-set design → go-api-design |
| 07: §11 Q38–39 errors; §12 Q40–41 type system; §14 Q45–46 shadowing; §15 Q47–49 numbers; §16 Q50–55 assertions | All mechanics local, including corrected embedding/constant arithmetic; optional capability API/retry policy → go-api-design/go-stdlib; no ownership inferred from Closer assertion |
| 07: Danger Zones; Version-Specific Behavior; Study Tips | Consolidated guardrails/version table and named executable cases; domain handoffs above apply to repeated items |
| [12 Anti-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/12-anti-patterns.md): Concurrency Anti-Patterns 1–6 | go-concurrency: leaks, bounded spawning, Add ordering, closed sends, races; sync-copy ownership also local |
| 12: Error Handling Anti-Patterns 1–6 | Errors/resources: swallowed errors, ambiguous nil, panic, context wrapping, error inspection, acquire-before-defer |
| 12: Interface Anti-Patterns 1–4 | go-api-design: unexported return types, giant/premature interfaces, return-type choices; not repeated as blanket rules here |
| 12: Memory and Performance Anti-Patterns 1–6 | Values/storage and errors/resources: retention, maps, builder/join, preallocation, receiver/pointer choice, loop defer |
| 12: Package Design Anti-Patterns 1–3 | Purpose naming local; cyclic dependencies/package splitting → go-system-design; export/API boundary design → go-api-design |
| 12: Code Style Anti-Patterns 1–6 | Local: nil len, switches, explicit returns, init, blank identifiers; slice concatenation API/version local, collection implementation → go-algorithms |
| 12: Testing Anti-Patterns 1–4 | go-tdd: public behavior, synchronized tests, purposeful tables, race CI; avoid unconditional platform-independent race claims |
| 12: Detection Tools; Quick Reference; Resources | Workflow: vet/linter versions, profiling limits; runtime race/test instrumentation → go-tdd; repeated fixes consolidated, not undigested source copies |

## Adaptation decisions and corrections

1. **Consolidation:** four topic-based references replace overlapping syntax, idiom,
   trap and anti-pattern listings. Keep this entrypoint for routing/guards only;
   standalone handoff topics prevent duplicate interface, algorithm or test guides.
2. **Loop versions:** new loop variables depend on the language version and `:=`
   declaration; assignment `=` still reuses variables. Deterministic closures avoid
   the source's sleeps and race-prone examples.
3. **Aliasing/retention:** a full slice expression is append isolation only, not
   element isolation or memory release. Validate prefix lengths rather than slicing
   fixed indices unconditionally; clone/shallow-copy distinctions are explicit.
4. **Text defects:** upstream Q22–25 claim multibyte outputs for ASCII literals
   `cafe`, `hello`, `Go!`, and `Hello, world`. Correct actual bytes/runes and use
   `café`/`世` where UTF-8 is intended. Code points are not grapheme clusters.
5. **Numeric defects:** Q48's constant sum compares equal after constant rounding;
   use runtime variable operands to demonstrate rounding. Q49's floating constant
   division by zero fails compilation too; runtime zero operands are different.
   Enforce bounds before arithmetic; do not promise overflow exceptions.
6. **Visibility defects:** Q41 incorrectly hides an exported promoted field through
   an unexported embedded type; exported unambiguous selectors can be accessible.
   `init` is special, not a reserved keyword. Detailed API design belongs elsewhere.
7. **Errors/cleanup:** acquire-check-defer stays mandatory, but nil `*os.File.Close`
   need not panic (it returns an invalid-file error). Preserve read and close errors
   with Join, document ownership and keep exit outside cleanup scope; no ignored
   open errors or pseudo-runnable `...` functions survive as complete examples.
8. **Memory/performance qualifications:** map shrinking is not guaranteed; deleted
   referents can become collectible and replacement does not free aliased storage.
   `sync.Pool` is not compaction. Drop fixed “>64 bytes” pointer thresholds, claims
   of all pointers allocating, and blanket generic zero-overhead promises. A used
   synchronization value must not be copied, not “undefined behavior” for every
   pristine zero-value assignment. Runtime concurrent-map failures are not guaranteed
   detection of every race.
9. **Tooling corrections:** version-pin external tools; don't copy stale mixed-major
   golangci-lint configuration, old Air module names or blanket test-error exclusions.
   The source's `concat(slices [][]int) { return slices.Concat(...) }` shadows the
   imported package: name the parameter `parts` when using `slices.Concat(parts...)`.
   Protect diagnostic endpoints and handle listener failures, not ignored errors.
10. **Rules are contextual:** no hard five-method interface ceiling, blanket globals
    ban, universal channels-over-mutexes mandate, or requirement to wrap/log every
    propagation. An unexported concrete return type is usable through inference and
    exported members, though it can hinder explicit naming (API topic). Accepting
    interfaces/returning concretes is a heuristic, not an absolute or a Postel-law
    correctness proof. Logging should not leak secrets or duplicate every layer.
