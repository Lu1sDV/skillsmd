# go-stdlib

Go standard-library APIs grouped by boundary: streams/files, text/encoding,
time/networking, and collections/runtime integration. Self-contained; no sibling
skill, upstream checkout or external package is needed to use the guidance.

## Install

From the skillsmd checkout; preserve local edits before replacing an installation:

```sh
mkdir -p ~/.claude/skills
cp -r go-stdlib ~/.claude/skills/
```

## Usage

- “Fix this Reader loop that drops the final bytes.”
- “Accept exactly one bounded JSON object and reject trailing input.”
- “Review this HTTP client for body limits, timeouts and resource ownership.”
- “Why does this CSV export succeed even though the destination failed?”
- “Check filepath.Glob recursion, iterator values and timer version assumptions.”

## Reference index

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Trigger, routing, workflow and essential boundary rules |
| [I/O and files](references/io-files.md) | fmt/io/bufio/os, paths, fs/embedding, process ownership |
| [Text and encoding](references/text-encoding.md) | strings/bytes/strconv/regexp/unicode; JSON/XML/CSV/base64/gob |
| [Time and networking](references/time-network.md) | Clocks, time zones/timers/context, HTTP, URL and sockets |
| [Collections and runtime](references/collections-runtime.md) | slices/maps/sort/heaps/lists, sync/test routing, errors, logging, flags, math/random/crypto, SQL |
| [Executable boundary reader](examples/boundaries.go) | One bounded settings document, explicit errors and domain validation |
| [Runnable checks](examples/boundaries_test.go) | EOF-with-data, partial failure, size/JSON boundaries, CSV flush and iterator semantics |

## Runnable examples

Requires an installed Go **1.25+** toolchain; examples declare `go 1.25.0` and use
only the standard library. From this bundle's `examples/` directory:

```sh
GOWORK=off GOTOOLCHAIN=local go test -count=1 ./...
GOWORK=off GOTOOLCHAIN=local go vet ./...
printf '%s\n' '{"name":"Ada","limit":3}' | GOWORK=off GOTOOLCHAIN=local go run ./cmd/demo
```

The demo writes `{"name":"Ada","limit":3}` and a newline to stdout. Invalid input
such as `null`, unknown fields, multiple documents, a blank name or a limit outside
1–100 produces a nonzero exit, a diagnostic on stderr and no successful JSON.
Input is capped at 256 bytes, including trailing whitespace. The reader borrows
stdin; it does not close a caller-owned stream.

Copying just this bundle to a temporary directory and running the same commands
needs no repository-root module or sibling files. The checks exercise specific
contracts, not every prose recipe. HTTP/socket/SQL integration, adversarial parser
agreement, real disk durability, alternate OSes and minimum-toolchain execution
are separate checks; no SQL driver is bundled. Markdown function fragments state
required imports and are not automatically executed by `go test`.

Verified on 2026-10-29 with Go 1.26.10 linux/amd64 in an isolated copy:
race-enabled tests, `go vet`, valid/invalid stdin demos and the `/dev/full` output
failure probe passed. Older toolchain and external-integration limits above remain.

## Sources and adaptation

Adapted from StructWeave Contributors' [Go standard-library chapter](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/14-standard-library-essentials.md),
pinned at commit `e2a796e212d431c906c85957ea3c203ce0e2218f`. The chapter was read
fully (lines 1–3270). [LICENSE.upstream](LICENSE.upstream) retains the MIT notice
verbatim. Primary Go package/release documentation supports contract corrections;
links are citations, not dependencies during skill use.

| Source sections | Destination |
|---|---|
| Philosophy, core I/O, filesystem operations | I/O and files; stdlib-first selection throughout |
| String/data manipulation and all five encoding families | Text and encoding |
| Collections and iterator versions | Collections/runtime API table; algorithm implementation is an optional go-algorithms handoff |
| Time/context and networking | Time and networking; coordination is an optional go-concurrency handoff |
| Sync/atomic, testing/fstest/synctest | Collections/runtime selection index; detailed execution workflows in optional go-concurrency/go-tdd |
| Errors, log/slog, flag, math/random/crypto, database/sql | Collections and runtime |
| Quick cards and ten interview questions | Merged into the relevant topic rather than repeated |

### Consolidation and correction decisions

- Group API contracts by actual boundary; do not duplicate language, algorithm,
  concurrency and test workflows. Keep all primary package families discoverable.
- Correct the source Reader loop: bytes returned with EOF are real data. `CopyN`
  requires exactly N bytes for success, not merely a maximum. Bound full reads and
  preserve transport errors rather than accepting a valid-looking partial result.
- Check acquisition, buffered output, CSV flush and close errors. `os.Create`
  opens read/write, and neither WriteFile nor bare rename is universally atomic
  and durable. A deferred close is not sufficient if its enclosing loop never ends.
- Correct `strings.Lines` newline preservation, `slices.Backward` index/value pairs,
  and `slices.Sorted` returning a slice. `filepath.Glob` has no recursive globstar.
  `sort` is not deprecated; Clip does not promise to free underlying storage.
- `Decoder.More` concerns container elements; use Decode-until-EOF for top-level
  streams. Unknown-field rejection is not duplicate-key rejection or canonical
  JSON. Avoid unchecked assertions and float-to-int truncation of untrusted values.
- Reject toy regexes as complete IP/email/phone validators, arbitrary parser
  input sizes, allocation-free Append claims without capacity, fixed speedups,
  and a guarantee that `%#v` is always compilable round-trip code.
- Preserve caller contexts and set time/body limits. HTTP non-2xx is a result,
  not automatically an error; closing a listener must end its Accept loop.
  Timer semantics are module/runtime-config-sensitive; cancellation is not joining.
- Correct stable Go 1.25 synctest.Test versus experimental Run. Protect each
  shared invariant with one lock, not the source's separate Mutex/RWMutex examples
  accidentally combined around one counter. Pool is not bounded resource storage.
- Keep log output separate from machine-readable stdout; avoid a custom slog
  wrapper that loses behavior when WithAttrs/WithGroup is called. Logging does
  not promise delivery/durability or automatic secret redaction.
- Correct SQL handle/connection and rollback/error semantics; transaction snippets
  are not a complete financial transfer. Driver/database/authorization prerequisites
  remain explicit. Preserve crypto/rand version semantics and do not present MD5,
  raw hashes, base64 or math/rand as password/secret/encryption solutions.
