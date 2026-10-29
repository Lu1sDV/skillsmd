# I/O and files

## Contents

- [Reader and Writer contracts](#reader-and-writer-contracts)
- [Buffering and scanning](#buffering-and-scanning)
- [File ownership and durability](#file-ownership-and-durability)
- [Paths and filesystem interfaces](#paths-and-filesystem-interfaces)
- [Formatting and process boundaries](#formatting-and-process-boundaries)

## Reader and Writer contracts

| Need | API | Contract to preserve |
|---|---|---|
| Stream all bytes | `io.Copy(dst, src)` | Returns count and error; partial output is possible |
| Exactly N bytes | `io.ReadFull(r, buf)` / `io.CopyN(w, r, n)` | Short input is an error; `CopyN` is not merely an upper bound |
| Small bounded input | `io.ReadAll(io.LimitReader(r, limit+1))` | Reject length above limit; use a valid nonoverflowing bound |
| Concatenate readers | `io.MultiReader` | Reads sequentially, not concurrently |
| Mirror writes | `io.MultiWriter` | Stops on a failing/short writer; no rollback of earlier outputs |
| Inspect bytes as consumed | `io.TeeReader` | Synchronous writes, no internal buffer; writer errors become read errors |
| Read fixed region | `io.NewSectionReader` | Bounds a `ReaderAt`; offset/length are caller contracts |
| Connect producer/consumer | `io.Pipe` | Unbuffered handoff; coordinate early exit and close with errors |
| Discard a stream | `io.Copy(io.Discard, r)` | Still consumes time/bandwidth; bound hostile streams |

A reader may return `(n > 0, io.EOF)`. Process those bytes before examining the
error. A short read with no error is not EOF; `(0, nil)` is not EOF either. A
writer must return a non-nil error when `n < len(p)`. Neither interface promises
to fill a buffer, retain a passed buffer, or own/close its caller's stream.
Prefer the standard copying functions to loops that accidentally drop final data.

Complete function fragment (imports `fmt` and `io`; caller owns `r`):

```go
func readSmall(r io.Reader) ([]byte, error) {
    const limit = 4096
    data, err := io.ReadAll(io.LimitReader(r, limit+1))
    if err != nil {
        return nil, fmt.Errorf("read document: %w", err)
    }
    if len(data) > limit {
        return nil, fmt.Errorf("document exceeds %d bytes", limit)
    }
    return data, nil
}
```

Reading one extra byte detects excess; reading only `limit` can accept a valid
prefix of an oversized document. A byte limit is not a time limit: the underlying
network operation also needs cancellation/deadlines. This function rejects partial
data on non-EOF errors deliberately; a streaming consumer may have a different
partial-result contract. The executable [settings reader](../examples/boundaries.go)
and [regressions](../examples/boundaries_test.go) cover bytes returned with EOF,
exact size boundaries, and a transport error after partial input.

## Buffering and scanning

- `bufio.Scanner` is convenient for bounded tokens. Configure `Split` and `Buffer`
  **before** scanning; `Buffer`/`Split` panic after scanning starts. The default
  maximum buffer is 64 KiB, but delimiter/buffering overhead means this is not a
  promise to accept every 64 KiB token. Set a deliberate bound, not unlimited growth.
- Always check `Scanner.Err()` after the loop. `ScanLines` strips line endings;
  a final unterminated line is still a token. `Bytes()` aliases scanner memory;
  clone if retained across `Scan`. `Text()` returns a separately owned string.
- `bufio.Reader.ReadString`/`ReadBytes` can return data **and** an error, including
  an unterminated final line with EOF. `ReadSlice` and `Peek` expose borrowed data
  invalidated by subsequent reads. Prefer a reader for oversized records or
  custom recovery, while enforcing your own record-size policy.
- `bufio.Writer.Write` may only fill its buffer. Check each write and `Flush()`
  before closing the underlying writer. Neither wrapping nor flushing transfers
  ownership of that writer. `csv.Writer` exposes buffered failures via `Error()`
  after `Flush`; base64's encoder flushes its final block through `Close()`.
- Pipes need cancellation in both directions: if the consumer stops, close its
  pipe end so a producer blocked on `Write` wakes. The owner joins the producer;
  a deferred close in a function that can never return does not prevent a leak.

## File ownership and durability

Check acquisition errors before arranging cleanup. `os.Open` is read-only;
`os.Create` opens read/write and creates **or truncates**. `OpenFile` expresses
append, exclusive creation, read/write and permission requirements explicitly.
Creating with mode `0600` does not tighten an existing file's permissions.

`os.ReadFile`/`WriteFile` suit small trusted inputs. `WriteFile` is not an atomic
replacement: a failure can leave partial output. If callers require atomic
visibility or durability, design the same-filesystem temporary file, permissions,
flush/sync, rename and directory-sync sequence for the target OS/filesystem.
Do not label a bare rename universally crash-safe. No such durability claim is
made by the examples here.

- Close each file when its work ends. A defer in a long-running loop waits for
  the enclosing function, not the current iteration; put per-file work in a helper.
- Preserve a primary read/write error and any relevant cleanup error, e.g.
  `errors.Join` (Go 1.20+). For buffered output: flush, then close, reporting both
  where useful. Not every read-only close failure changes the result contract.
- `ReadDir` returns sorted entries; `DirEntry.Info` can fail after enumeration.
  `MkdirAll` is idempotent for existing directories, not proof of trusted ancestry.
  `RemoveAll` is destructive; validate scope and ownership before using it.
- `Chdir`, environment mutations and default loggers affect the whole process.
  Prefer explicit base directories/config values, especially in concurrent code.

## Paths and filesystem interfaces

| Input namespace | Operation | Limit |
|---|---|---|
| OS file path | `path/filepath` (`Join`, `Clean`, `Rel`, `Abs`, `Ext`, `Match`) | OS-specific separators; cleaning is lexical |
| URL-style slash path | `path` or `net/url` | Do not use OS path joining to construct URLs |
| `fs.FS` name | `fs.ValidPath`, `fs.ReadFile`, `fs.WalkDir`, `fs.Sub` | Slash-separated relative names; `.` is the root |
| Bundled assets | `embed.FS` with `//go:embed` | Build-time inclusion, not live disk updates |
| Recursive file discovery | `filepath.WalkDir` / `fs.WalkDir` | Handle callback errors before using `DirEntry` |

`filepath.Glob("**/*.go")` is **not** recursive globstar syntax: `*` cannot cross
a separator. Use `WalkDir` when recursion is required. `WalkDir` does not follow
directory symlinks; do not infer that arbitrary later file operations are safe.

`os.DirFS` and `fs.Sub` are abstractions, **not** chroot/security sandboxes; symlinks
may lead outside the intended tree. `filepath.IsLocal` is lexical only. For
hostile relative paths, Go 1.24+ `os.OpenRoot`/`Root.Open` provide traversal-resistant
access; check OS-specific restrictions and still apply file-type/authorization
policy. A root is not a size quota, mount namespace or special-device filter.

Use `testing/fstest.MapFS` for deterministic consumer tests and `fstest.TestFS`
for an FS implementation's contract. A map-backed FS does not prove symlink,
permissions, durability or platform behavior; exercise those on the real filesystem.
Optional **go-tdd** owns test strategy.

## Formatting and process boundaries

`fmt` supports `%v` (default), `%+v` (struct field names), `%#v` (Go-syntax-style
representation), `%T` (type), `%q` (quoted string/rune), `%d`/`%x` (numbers), and
width/precision (`%06d`, `%.2f`). Custom `Formatter`, `Stringer` and `GoStringer`
methods affect output: `%#v` is not a universal round-trip serializer. Check
`Fprintf`/`Fprintln` errors on meaningful outputs; diagnostics belong on stderr,
machine-readable results on stdout. Scanning functions return conversion counts
and errors: never treat a partially scanned record as complete.

Use `os.LookupEnv` when absent and empty are different. `os.Args[1:]` excludes the
program name; `flag.FlagSet` handles options. `os.Exit` and `log.Fatal` bypass
deferred cleanup. Return errors through a `run` function, then choose the process
exit status only after its resources are closed. UID/GID APIs are OS-dependent.

## Primary references

[io](https://pkg.go.dev/io), [bufio](https://pkg.go.dev/bufio),
[os](https://pkg.go.dev/os), [filepath](https://pkg.go.dev/path/filepath),
[io/fs](https://pkg.go.dev/io/fs), [embed](https://pkg.go.dev/embed),
[traversal-resistant access](https://go.dev/blog/osroot),
[fmt](https://pkg.go.dev/fmt).
