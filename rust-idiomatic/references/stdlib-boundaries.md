# Standard-library boundaries

## Text, bytes, and allocation semantics

`String`/`str` are UTF-8. `len` and `find` use byte offsets; `chars` iterates Unicode
scalars and `char_indices` pairs them with byte offsets. Neither counts grapheme
clusters. Combining marks and joined sequences can contain multiple scalars for
one visible character. Use a suitable Unicode segmentation library only when the
actual contract needs graphemes; ASCII protocols can operate on validated bytes.

String range indexing panics on out-of-bounds or non-boundary offsets. Use `get`
for an optional slice, or derive boundaries from `char_indices`. Repeated
`chars().nth(i)` rescans prefixes; iterate once rather than pretending strings
provide constant-time scalar indexing. Case conversion can expand text and does
not perform general Unicode normalization. `trim` removes Unicode whitespace.

```rust
fn first_scalar(input: &str) -> Option<&str> {
    let first = input.chars().next()?;
    input.get(..first.len_utf8())
}
assert_eq!(first_scalar(""), None);
assert_eq!(first_scalar("éclair"), Some("é"));
assert_eq!("é".len(), 2);
assert_eq!("é".get(..1), None);
assert_eq!("e\u{301}".chars().count(), 2);
assert_eq!(first_scalar("e\u{301}"), Some("e")); // Scalar, not whole grapheme.
```

| Operation | Ownership / cost semantics |
|---|---|
| Borrow `&string` as `&str` | View, no new string buffer |
| Move `String` or identity `String -> String` conversion | Transfer existing handle/buffer, not a deep copy |
| `&str.to_owned()`, `.to_string()`, `String::from(&str)` | Owned copy; nonempty input needs storage; do not claim different intrinsic speed |
| `String::clone()` | Independent string contents, unlike `Rc::clone` |
| `String::new()` / `Vec::new()` | Empty without allocating a backing buffer |
| `format!` | Produces an owned `String`; do not claim every invocation necessarily allocates, including empty output |
| `push_str`, `push` | Reuse sufficient capacity; growth may allocate |
| `Cow::Borrowed` / `Cow::Owned` | Borrow or own; `to_mut` clones a borrowed value, `into_owned` clones only when borrowed |
| `collect::<Vec<_>>()` | Materializes a collection; no universal promise about allocation reuse |

Formatting directly with `write!` into an existing `String` (`std::fmt::Write`) or
writer (`std::io::Write`) avoids a separate `format!` result. The two `Write`
traits have different error types. Measurement, allocator choice and layout tuning
belong to optional **rust-performance**.

## Collections: semantics before cleverness

| Need | Default | Important behavior |
|---|---|---|
| Sequence / stack | `Vec` | `remove` shifts; `swap_remove` changes order; `get` checks bounds |
| Queue / both ends | `VecDeque` | Logical order may wrap; not necessarily one contiguous slice |
| Key lookup / uniqueness | `HashMap` / `HashSet` | Iteration order unspecified; use borrowed lookup when key supports it |
| Sorted keys / ranges | `BTreeMap` / `BTreeSet` | Key order is defined; validate range bounds |
| Priority queue | `BinaryHeap` | Max-heap; use `Reverse` for minimum; iteration is not sorted |

`Vec::with_capacity(n)` initializes zero elements and reserves at least `n`
slots, not exactly `n` as a portable guarantee. `reserve(additional)` is relative
to **length**, not current capacity. `clear` drops elements but retains capacity;
`shrink_to_fit` is a request, not a guarantee of equality with length. Zero-sized
elements need no element allocation even for nonzero length/capacity. Never expose
uninitialized capacity by manually increasing length in ordinary safe code.

`entry(key).or_insert_with(f)` delays the value computation but constructs the key
before lookup. `or_default()` expresses a real default; do not build custom cache
or entry abstractions without need. Keys must keep hash/equality/order stable while
stored. A custom `Ord` comparing only priority must have matching equality, or use
an explicitly ordered tuple with a tie-breaker. Prefer `Vec`/`VecDeque` over
`LinkedList` unless a demonstrated operation requires its properties; arbitrary
index lookup and splitting a list are not magically constant time.

```rust
use std::collections::HashMap;
let mut groups: HashMap<&str, Vec<u32>> = HashMap::new();
groups.entry("red").or_default().push(1);
groups.entry("red").or_default().push(2);
assert_eq!(groups.get("red").unwrap(), &[1, 2]);

let mut values = Vec::<u8>::with_capacity(4);
assert!(values.is_empty());
assert!(values.capacity() >= 4);
assert_eq!(values.get(0), None);
values.push(7);
let capacity = values.capacity();
values.clear();
assert_eq!(values.len(), 0);
assert_eq!(values.capacity(), capacity);
```

Algorithm-specific complexity and implementation guidance belong to optional
**rust-algorithms**, not a second catalog here.

## Iteration: lazy adapters, consuming operations

- `iter()` borrows elements; `iter_mut()` mutably borrows; owned `Vec::into_iter()`
  yields owned elements. `into_iter()` on `&Vec<T>` yields references: the receiver,
  not the method name alone, determines ownership. `for` uses `IntoIterator`.
- `map`, `filter`, `inspect`, `scan`, `take` construct lazy adapters. `for`, `sum`,
  `fold`, `collect`, `any`, `find` consume work. `scan` is not a terminal consumer.
- `filter` sees a reference to each item: on `.iter()` its predicate sees `&&T`.
  `copied` requires `Copy`; `cloned` calls `Clone` and can allocate/share per item.
- `zip` truncates to the shorter side; validate lengths first if equality matters.
  `any`/`all` short-circuit; `all` on empty input is true. Do not use them when all
  side effects must execute. `reduce`, `min`, `max` return `None` for empty input.
- `take_while` consumes the first item that fails its predicate. Use `peekable` if
  that separator belongs to later processing. `by_ref()` borrows an iterator so a
  partial consumer does not move the original iterator.
- `windows(0)`, `chunks(0)`, and `step_by(0)` panic. `chunks_exact` leaves a remainder
  which must be handled when data loss is not allowed.
- `flatten` over `Option` or `Result` discards missing/error cases. For fallible
  processing use `collect::<Result<_, _>>()`, `try_fold`, or an explicit `?` loop.
- Iterators need not remain exhausted after one `None`; use `fuse()` when that
  property is required for a custom iterator. Avoid promising identical codegen
  for every iterator and loop; semantics first, measure relevant cost later.

## Line endings: remove framing, not data

`BufRead::read_line` appends valid UTF-8, includes the `\n` delimiter if present,
and returns zero bytes at EOF. Reusing the buffer requires `clear` before each
record. `BufRead::lines` removes one LF or one CRLF terminator and yields a
`Result<String>` for each line; it preserves a bare trailing CR. Do not substitute
`trim_end()` or `trim_end_matches(['\r', '\n'])`: those can erase payload.
`str::lines()` borrows slices with LF/CRLF semantics and does not invent a final
empty record solely from a terminal newline. Use `split_inclusive('\n')` or raw
reads when exact terminators must be preserved.

This dependency-free example normalizes LF/CRLF records to LF while retaining
payload spaces and a bare CR. It also appends LF to a final unterminated record;
that is an explicit normalization contract, not byte-preserving copying. It uses
one reusable text buffer, propagates I/O/UTF-8 errors, and flushes output.

```rust
use std::io::{self, BufRead, Write};

fn normalize_lines(mut input: impl BufRead, mut output: impl Write) -> io::Result<()> {
    let mut line = String::new();
    loop {
        line.clear();
        if input.read_line(&mut line)? == 0 { break; }
        if line.ends_with('\n') {
            line.pop();
            if line.ends_with('\r') { line.pop(); }
        }
        writeln!(output, "{line}")?;
    }
    output.flush()
}

let mut output = Vec::new();
normalize_lines(&b"  a  \r\n\r\nlast\r"[..], &mut output).unwrap();
assert_eq!(output, b"  a  \n\nlast\r\n");
let mut empty = Vec::new();
normalize_lines(&b""[..], &mut empty).unwrap();
assert!(empty.is_empty());
assert!(normalize_lines(&b"\xff\n"[..], Vec::new()).is_err());
let lines: Vec<_> = "a\r\n\nlast\r".lines().collect();
assert_eq!(lines, ["a", "", "last\r"]);
```

`read_line` can grow without bound if no newline arrives. This example assumes
finite trusted input; for untrusted streams enforce a byte/record-size policy
and a read deadline at the transport layer. A byte limit reached is not genuine
EOF: detect and reject truncation rather than accepting a partial record. Use
`read_until`/byte buffers when invalid UTF-8 is valid input.

## I/O, filesystem, and OS boundaries

- `Read::read` and `Write::write` may transfer fewer bytes than requested. Use
  `read_exact`/`write_all` when the full fixed-size transfer is the contract;
  handle `UnexpectedEof` and I/O failure. Empty reads are not data.
- Buffer repeated small filesystem reads/writes with `BufReader`/`BufWriter`.
  Already-buffered and in-memory sources may not need another buffer. Keep one
  reader per stream; discarding it can discard unread buffered bytes.
- `BufWriter` drop cannot report flush errors. Flush explicitly and propagate the
  result. Flushing does not guarantee storage durability; `File::sync_all` and
  platform-specific directory/rename considerations are a separate requirement.
- `fs::read` reads bytes, `read_to_string` validates UTF-8 and reads the whole file;
  limit whole-file reads for untrusted sizes. Stream when bounded memory matters.
- `fs::write` and `File::create` overwrite/truncate. `OpenOptions` must express one
  intent: replacement (`write + create + truncate`), append (`append + create`),
  or exclusive creation (`write + create_new`). Do not blindly combine append and
  truncate; do not check existence and then create when exclusivity matters.
- Both opening `read_dir` and individual directory entries can fail. Directory
  order is unspecified. `metadata` follows symlinks; `symlink_metadata` inspects
  the link itself. An existence check is neither authorization nor a race-free
  guarantee that the subsequent operation succeeds.
- Use `&Path`/`PathBuf` and `OsStr`/`OsString` for OS paths, not mandatory UTF-8.
  `to_str()` can return `None`; lossy display is only for diagnostics. `join` or
  `push` with an absolute path can replace the prefix; neither `join` nor lexical
  `..` filtering is a sandbox. Symlink races need an appropriate security design.
- Use `args_os`/`var_os` for OS-native arguments/environment; UTF-8 APIs can reject
  or panic on non-Unicode data. Distinguish missing `env::var` from `NotUnicode`.
  Treat current directory and environment as process-wide state.
- In edition 2024 `env::set_var`/`remove_var` are unsafe because of platform
  multithreading hazards. Prefer passing configuration or `Command::env` for a
  child. A newly added `unsafe` block is not a safety proof.
- `Instant` measures elapsed time; `SystemTime` provides wall-clock timestamps
  and fallible differences. Monotonic clocks are platform-dependent and subject
  to rare platform bugs; `Instant::checked_duration_since` detects reversed order.
  Use checked duration arithmetic where overflow matters; do not infer time zones
  or civil-calendar behavior from raw `SystemTime`.

Synchronization, channels, atomics, and async execution belong to optional
**rust-concurrency**; do not use this reference to justify a lock or memory order.

## Sources

Adapted from upstream 17, iterator/string portions of 01/05, and ordinary 13 traps;
pinned links in the [source map](../README.md#sources-and-adaptation).
- [String, UTF-8 and allocation](https://doc.rust-lang.org/std/string/struct.String.html)
- [Vec guarantees](https://doc.rust-lang.org/std/vec/struct.Vec.html#guarantees)
- [Iterator contracts](https://doc.rust-lang.org/std/iter/trait.Iterator.html)
- [BufRead line semantics](https://doc.rust-lang.org/std/io/trait.BufRead.html)
- [BufWriter flush errors](https://doc.rust-lang.org/std/io/struct.BufWriter.html)
- [Filesystem](https://doc.rust-lang.org/std/fs/) and [Path](https://doc.rust-lang.org/std/path/struct.Path.html)
- [Newly unsafe environment functions](https://doc.rust-lang.org/edition-guide/rust-2024/newly-unsafe-functions.html)
- [Instant platform behavior](https://doc.rust-lang.org/std/time/struct.Instant.html)
