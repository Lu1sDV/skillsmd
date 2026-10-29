---
name: go-stdlib
description: >
  Use when choosing or debugging Go standard-library APIs for Reader/Writer and
  file ownership, Scanner limits, JSON/CSV/XML decoding, UTF-8 and regex, time
  parsing, HTTP clients/servers, URL/path handling, slog, flags, randomness or
  database/sql; especially truncated input, unchecked flushes and unbounded reads.
---

# Go Standard Library

## Route by boundary

| Task | Load |
|---|---|
| Short reads/writes, Scanner, buffering, files, paths and fs.FS | [I/O and files](references/io-files.md) |
| Text/bytes, conversion, regex, JSON/XML/CSV/base64/gob | [Text and encoding](references/text-encoding.md) |
| Time zones/timers, context, HTTP, URLs and sockets | [Time and networking](references/time-network.md) |
| Collections, errors, logging, flags, math/random/crypto and SQL | [Collections and runtime APIs](references/collections-runtime.md) |

Load only the relevant local guide; no sibling or network access is required.

## Workflow

1. Read `go.mod`, build tags and dependencies. Establish supported language/library
   versions, input trust, byte/record limits and resource ownership.
2. Trace partial-data/error, borrowed-buffer, nil/empty, single-JSON/stream and
   buffered-output contracts.
3. Prefer existing stdlib operations. Separate decoding from domain validation:
   parsing URLs, paths or numbers neither authorizes nor validates their use.
4. Preserve errors/cancellation. Reuse HTTP clients and database pools; close
   per-operation bodies/rows/files at their actual lifetime boundary.
5. Exercise relevant malformed/truncated/oversized input, writer failure,
   cancellation and cleanup. Report commands, version gaps and unexercised services.

## Non-negotiable contracts

- A `Read` may return bytes **and** `io.EOF` or another error. Consume `p[:n]`
  before handling the error; use `io.Copy`/`ReadFull` rather than an ad-hoc loop.
- Bound untrusted reads. `LimitReader` silently ends at its limit; read one extra
  byte to detect excess, or use `http.MaxBytesReader` at an HTTP request boundary.
- Check `Scanner.Err`, buffered `Flush`, CSV `Error`, and relevant `Close` errors.
  Returning success before output reaches its destination can lose data.
- One `json.Decoder.Decode` accepts a prefix. Require a second decode to return
  `io.EOF` for exactly one document; `More` is for array/object elements.
- HTTP non-2xx is not a `Client.Do` error. Check status and bound body consumption.
  An incoming request already has a context: use `r.Context()`, not a new root.
- Path cleaning is lexical, not a symlink-safe sandbox. URL parsing is not an
  SSRF policy. Base64 is not encryption; `math/rand` is not secret generation.
- `sql.Open` returns a pool handle, not proof of connectivity. Keep a transaction
  on its `*sql.Tx`, check `Scan`/`rows.Err`/`Commit`, and use driver placeholders.
- Stdlib does not imply universal concurrency safety. Maps/buffers/builders and
  compound invariants need explicit ownership or synchronization.

## Versions and scope

Runnable samples declare Go **1.25.0+**, stdlib only. References label older
feature gates: `slices`/`maps`/`slog` 1.21, ServeMux method/path patterns and
`math/rand/v2` 1.22, iterators 1.23, string sequence APIs 1.24. Respect the target
module instead of treating the author's toolchain as its minimum.

Optional handoffs: **go-idiomatic** for language semantics/error design,
**go-algorithms** for collection invariants/complexity, **go-api-design** for
interfaces/generic APIs, **go-concurrency** for coordination,
**go-tdd** for test workflows, **go-system-design** for service architecture.

See [README](README.md) for installation, pinned source coverage, correction
decisions and runnable examples; [LICENSE.upstream](LICENSE.upstream) preserves
upstream attribution.
