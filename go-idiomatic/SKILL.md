---
name: go-idiomatic
description: >
  Use when writing or reviewing everyday Go, fixing slice aliasing, nil values,
  UTF-8 indexing, overflow, loop captures, error shadowing, defer/resource leaks,
  receiver copying, initialization surprises, or module/toolchain mismatches.
---

# Go Idiomatic

## Route by task or symptom

| Task | Load |
|---|---|
| Types, control flow, functions, receivers, equality, nil, loop capture | [Language semantics](references/language-semantics.md) |
| Slice/map aliasing, retained storage, UTF-8, numeric bounds | [Values and storage](references/values-storage.md) |
| Error wrapping/shadowing, defer, close failures, panic/exit | [Errors and resources](references/errors-resources.md) |
| Naming, imports/init, modules, tools and version gates | [Workflow and versions](references/workflow-versions.md) |

Load only the relevant local guide; sibling skills are optional.

## Workflow

1. Read `go.mod`, supported versions, build tags and tool configuration. Distinguish
   compiler from module language version; check permission for toolchain downloads.
2. Trace callers and ownership: copies, shared storage, mutation and resource closure.
3. Define absence, empty input, malformed UTF-8, numeric bounds and equality.
   Never conflate valid zero with absence or failure with empty success.
4. Prefer direct functions, built-ins or stdlib. Preserve observable contracts;
   keep interface/generic API design outside semantic bug fixes.
5. Return contextual errors; scope cleanup to resource lifetime. Update all affected
   callers and add named regressions for the real boundary.
6. Run only authorized checks. Separate actual commands/results from proposed
   checks and static reasoning.

## High-risk guardrails

- Go passes values by value, including pointers and slice/map descriptors.
  A copied descriptor is not independent data; append can overwrite an alias.
- A capacity-limited slice prevents append from reusing that capacity; it does
  not isolate existing elements or release a retained backing array.
- Nil maps can be read, ranged and deleted from, but not assigned into. Nil and
  non-nil empty slices both have length zero but may encode differently.
- Interfaces holding typed nil pointers are not nil. Dynamic uncomparable values
  can panic on equality; do not blindly compare arbitrary `any` values.
- Value receivers copy fields, not referenced data. Never copy synchronization
  primitives after first use, including by assignment, range or value receivers.
- Go 1.22 per-iteration variables apply to declarations in loops under the newer
  language version, not assignment to existing variables. Race freedom is separate.
- `:=` in an inner block can hide an outer `err`; return the actual failed error.
  Deferred closures can change named results; prefer explicit returns elsewhere.
- Defer arguments/receivers bind immediately and execute LIFO at function return.
  Register cleanup only after successful acquisition. `os.Exit`/`log.Fatal` skip it.
- Strings are bytes, not guaranteed UTF-8. Range decodes runes with byte indices;
  rune count is not grapheme count. Check boundaries before slicing/conversion.
- Integer arithmetic does not check business bounds. Constants and runtime
  floating-point arithmetic differ; validate range, NaN and infinity explicitly.

## Version and evidence gate

Runnable samples require **Go 1.25+**, stdlib only, with `go 1.25.0` in their own
module. Most core semantics predate that baseline. Newer language/library features
are labelled in [workflow](references/workflow-versions.md); do not lower the
module version and assume the same loop behavior.

Report changed contracts, callsites, resource/alias ownership, exercised boundary
cases, exact checks run, and unverified platforms/toolchains. Static reading is
not execution. See [README](README.md) for commands, complete pinned chapter
coverage and correction decisions, and [LICENSE.upstream](LICENSE.upstream).

Optional topic handoffs: **go-api-design** (interfaces/generics/composition),
**go-algorithms** (collections/algorithms), **go-concurrency** (coordination),
**go-stdlib** (package APIs), **go-tdd** (testing), **go-system-design** (architecture).
