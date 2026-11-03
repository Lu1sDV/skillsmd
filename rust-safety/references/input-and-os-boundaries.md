# Input, identity, and operating-system boundaries

## Contents

- [Validate the consumed representation](#validate-the-consumed-representation)
- [Bounded input is not truncated success](#bounded-input-is-not-truncated-success)
- [Raw descriptors are resources, not arbitrary integers](#raw-descriptors-are-resources-not-arbitrary-integers)
- [Paths and confinement](#paths-and-confinement)
- [Process execution and inherited authority](#process-execution-and-inherited-authority)
- [Output and persistence](#output-and-persistence)

## Validate the consumed representation

Identify the original input, each conversion, the final consumer, and its authority.
Validation must apply to the representation that consumer actually interprets.
A type conversion alone is not domain validation, and an encoding failure is not
permission to substitute an empty/default identity.

| Input | Review question | Common trap |
|---|---|---|
| Length/count/offset | Was the quota checked before conversion, multiplication, addition, or allocation? | `as usize` truncation; representable but enormous counts |
| UTF-8/string range | Are byte offsets valid boundaries and in range? | `.len()` counts bytes; unchecked user slicing panics |
| Path/OS string | Is identity preserved through validation and access? | `to_string_lossy` becomes an authorization key |
| Reader/iterator result | Does unsafe code validate the actual count/initialization? | Trusting a safe trait implementation as an unchecked bounds proof |
| Floating-point value | Are NaN/Inf and signed zero meaningful in this domain? | Ordering or equality assumed from numeric-looking input |

Use `try_from` and checked arithmetic where overflow/narrowing must reject input.
Check against the actual destination extent and policy limit too. Cargo's debug
and release overflow behavior are configurable defaults, not language-wide
rules; division/remainder also have their own panic cases. Saturation/wrapping
are deliberate semantics, not general validation fixes.
[Overflow semantics](https://doc.rust-lang.org/reference/expressions/operator-expr.html#overflow),
[Cargo profiles](https://doc.rust-lang.org/cargo/reference/profiles.html#overflow-checks).

For byte-framed data use byte buffers until UTF-8 is actually part of the contract.
`str::get` can reject invalid ranges without a panic. For OS paths/arguments keep
`Path`/`OsStr`/`OsString`; distinct invalid byte sequences may collapse to the same
replacement-character string under lossy conversion. Use lossy display for
explicitly non-authoritative diagnostics, not authorization, deduplication, or
reopening the selected object. Platform case/normalization rules need separate
analysis; Rust strings do not define filesystem identity.
[str slicing](https://doc.rust-lang.org/std/primitive.str.html#method.get),
[lossy conversion](https://doc.rust-lang.org/std/string/struct.String.html#method.from_utf8_lossy).

### Safe traits are not unchecked bounds proofs

`Read` is safe to implement. Generic unsafe code cannot assume its returned count
is within the supplied buffer or that it only writes to that buffer. Supply
initialized byte storage before forming the `&mut [u8]`; do not manufacture that
reference over uninitialized storage. The same bounds principle applies to safe
iterator length hints. Reject a violated count contract rather than silently
clamping it and accepting misleading data.
[Read's explicit safety warning](https://doc.rust-lang.org/std/io/trait.Read.html#method.read).

```rust
use std::io::{self, Read};

fn read_checked<'a>(reader: &mut impl Read, buf: &'a mut [u8]) -> io::Result<&'a [u8]> {
    let count = reader.read(buf)?;
    buf.get(..count)
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "reader exceeded buffer"))
}

struct BadCount;
impl Read for BadCount {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        Ok(buf.len() + 1) // A safe trait contract violation, not UB by itself.
    }
}

let mut bytes = [0; 4];
assert_eq!(read_checked(&mut &b"ok"[..], &mut bytes).unwrap(), b"ok");
assert_eq!(read_checked(&mut BadCount, &mut bytes).unwrap_err().kind(),
           io::ErrorKind::InvalidData);
```

This is a single-read contract example, not a sandbox for an arbitrary reader
implementation and not a full framing/read-exact implementation.

## Bounded input is not truncated success

`Read::take` ends when its limit is reached; that is not proof the underlying
input ended. For a standalone message, read at most the trusted quota plus one
byte, then reject excess. Apply limits at the decompressed/expanded consumer too.
A byte bound does not enforce a deadline, limit arbitrary reader computation,
or make `read_to_end` an allocation-failure-proof operation.
[Read::take](https://doc.rust-lang.org/std/io/trait.Read.html#method.take),
[read_to_end allocation/error contract](https://doc.rust-lang.org/std/io/trait.Read.html#method.read_to_end).

```rust
use std::io::{self, Read};

fn read_bounded(reader: impl Read, limit: usize) -> io::Result<Vec<u8>> {
    let probe_limit = limit.checked_add(1)
        .and_then(|n| u64::try_from(n).ok())
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "invalid byte quota"))?;
    let mut bytes = Vec::new();
    reader.take(probe_limit).read_to_end(&mut bytes)?;
    if bytes.len() > limit {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "message exceeds quota"));
    }
    Ok(bytes)
}

assert_eq!(read_bounded(&b""[..], 0).unwrap(), b"");
assert_eq!(read_bounded(&b"abc"[..], 3).unwrap(), b"abc");
assert_eq!(read_bounded(&b"abcd"[..], 3).unwrap_err().kind(), io::ErrorKind::InvalidData);
assert_eq!(read_bounded(&b"x"[..], 0).unwrap_err().kind(), io::ErrorKind::InvalidData);
assert_eq!(read_bounded(&b""[..], usize::MAX).unwrap_err().kind(), io::ErrorKind::InvalidInput);

struct FailedInput;
impl Read for FailedInput {
    fn read(&mut self, _: &mut [u8]) -> io::Result<usize> {
        Err(io::Error::new(io::ErrorKind::PermissionDenied, "input unavailable"))
    }
}
assert_eq!(read_bounded(FailedInput, 3).unwrap_err().kind(), io::ErrorKind::PermissionDenied);
```

The example consumes the probe byte. Use it on an owned message/frame input;
reusing a connection after rejection requires an explicit framing/resynchronization
policy. Do not accept an oversized prefix as a complete message. The `limit` is
application policy, not a value trusted merely because the peer supplied it.

## Raw descriptors are resources, not arbitrary integers

On Unix, prefer `OwnedFd` and `BorrowedFd`/`AsFd` for ownership and borrowed access.
`as_raw_fd` does not transfer ownership; `into_raw_fd` does. For `File`/`OwnedFd`,
unsafe `from_raw_fd` creates a closing owner and requires the corresponding owned,
open descriptor contract. Do not reconstruct an owner from a borrowed integer or
make two closing owners. Descriptor-number reuse can turn a later close into an
operation on an unrelated resource. Track success, early errors, and handoffs.
[OwnedFd](https://doc.rust-lang.org/std/os/fd/struct.OwnedFd.html),
[BorrowedFd](https://doc.rust-lang.org/std/os/fd/struct.BorrowedFd.html),
[FromRawFd](https://doc.rust-lang.org/std/os/fd/trait.FromRawFd.html).

Keep a typed owner until the actual foreign handoff. If `into_raw_fd` temporarily
leaves ownership in an unguarded integer, a `?`, unwind, or cancellation before
reconstruction/transfer can leak it: the integer has no closing destructor.
Establish the new owner or a cleanup guard before an intervening failure/suspension
point. At a foreign call, follow its success/failure ownership contract; reclaim
only when ownership was not consumed, and never also close after another owner
took responsibility. Repeated leaks can exhaust descriptors even without UB.

Ownership of one descriptor does not imply exclusive access to the underlying
file or open-file description: clones/other descriptors/processes can share it.
A live fd does not prove read permission, file type, immutability, or suitability
for an arbitrary syscall. A memory map's validity also depends on external
mutation/truncation; owning its fd is not the whole safe-mapping proof.
[std I/O safety](https://doc.rust-lang.org/std/os/unix/io/index.html),
[Dan Gohman's I/O safety RFC](https://rust-lang.github.io/rfcs/3128-io-safety.html).

This Unix-only example exercises a real socket pair and one ownership transfer,
without a dependency, arbitrary descriptor, or deliberate double-close:

```rust
# #[cfg(unix)]
# fn main() -> std::io::Result<()> {
use std::io::{Read, Write};
use std::os::fd::{FromRawFd, IntoRawFd};
use std::os::unix::net::UnixStream;

let (sender, mut receiver) = UnixStream::pair()?;
let descriptor = sender.into_raw_fd();
// SAFETY: into_raw_fd transferred this live socket; no other closing owner
// or intervening operation exists, and this is its only reconstruction.
let mut sender = unsafe { UnixStream::from_raw_fd(descriptor) };
sender.write_all(b"ok")?;
let mut bytes = [0; 2];
receiver.read_exact(&mut bytes)?;
assert_eq!(&bytes, b"ok");
drop(sender);
assert_eq!(receiver.read(&mut bytes)?, 0); // Peer closure is observable.
# Ok(())
# }
# #[cfg(not(unix))]
# fn main() {}
```

A non-Unix doctest skips this example, not verifies it. Windows distinguishes
kernel handles from sockets and uses different release operations; verify the
specific `OwnedHandle`/`OwnedSocket` or foreign API contract rather than porting
Unix fd assumptions. Do not retry native `close` blindly after an error: resource
state and retry semantics are OS/API-specific.

## Paths and confinement

A base directory plus `Path::join` is not a sandbox. Absolute components can
replace the base; `..`, platform prefixes, symlinks, mount traversal, and mutable
ancestors affect resolution. `Path::starts_with` is component-aware but still
lexical; a string prefix check is weaker. `canonicalize` followed by reopen is
not race-free when the attacker can change the tree.
[Path operations](https://doc.rust-lang.org/std/path/struct.Path.html).

Choose a policy first: allowed tree, symlink/mount rules, existing versus newly
created objects, and who may modify each ancestor. For hostile filesystem state,
use an established capability/directory-handle-relative API with the required
resolution restrictions. Keep validation tied to the operation/opened object,
not a second pathname lookup. On Linux, `openat2` provides resolution controls
such as `RESOLVE_BENEATH` and `RESOLVE_IN_ROOT`; the appropriate combination and
error/retry policy depend on the intended semantics. It is not a portable std
recipe. `O_NOFOLLOW` on the final component alone does not police all ancestors.
[openat2 contracts](https://man7.org/linux/man-pages/man2/openat2.2.html).

For exclusive creation, `create_new(true)` provides the documented atomic
existence check plus creation, including rejection of a dangling final symlink;
it does not by itself confine resolution to a trusted directory. Test ancestor
replacement, symlink escapes, absolute/prefixed paths, and creation as separate
cases. Avoid emitting a generic `safe_join` helper with stronger claims than its
actual filesystem guarantees.
[OpenOptions::create_new](https://doc.rust-lang.org/std/fs/struct.OpenOptions.html#method.create_new).

## Process execution and inherited authority

`Command::arg` normally passes a literal argument, not a shell expression. Keep
arguments separate; do not build an interpreter command string such as `sh -c`
from untrusted text. Still inspect the invoked program: option parsing, response
files, expressions, URLs, and config-file flags can turn an argument into authority.
Use `--` only if that program supports it; it does not neutralize all operand
semantics. Validate executable selection separately from its arguments.
[Command::arg](https://doc.rust-lang.org/std/process/struct.Command.html#method.arg).

On Windows, `cmd.exe` and batch files use nonstandard parsing. Neither Unix
shell-escaping nor blanket “arg is safe” claims are sufficient; `raw_arg` bypasses
the escaping performed by `arg`. Avoid untrusted batch arguments unless the
actual interpreter contract and an appropriately restricted input policy justify
them. Rust's special batch handling can reject an argument it cannot safely escape
with a spawn-time `InvalidInput` error; propagate that refusal, do not fall back
to `raw_arg`. The initial mitigation shipped in Rust 1.77.2; the trailing-space/
period filename bypass was addressed in 1.81.0. Keep supported versions patched:
these fixes do not make arbitrary shell command construction safe.
[Windows argument splitting](https://doc.rust-lang.org/std/process/index.html#windows-argument-splitting),
[initial batch mitigation](https://blog.rust-lang.org/2024/04/09/cve-2024-24576/),
[follow-up fix](https://blog.rust-lang.org/2024/09/04/cve-2024-43402/).

Review inherited working directory, environment, executable search, and stdio.
Use the required known executable and narrowly supplied environment where the
trust boundary calls for it; an empty environment is not automatically a complete
or portable sandbox. Check child exit status, bound captured output, and ensure
spawned children are terminated/reaped under the application's cancellation policy.
[Command defaults](https://doc.rust-lang.org/std/process/struct.Command.html#method.new),
[Child lifecycle](https://doc.rust-lang.org/std/process/struct.Child.html).

## Output and persistence

A successful write into a buffer is not delivery or durable persistence. Propagate
write/flush errors; `BufWriter` destruction cannot return flush failures. Durability
and atomic replacement need their own filesystem/platform contract, including
relevant file/directory synchronization. Do not report success after discarding
the error that says the output was never delivered.
[BufWriter](https://doc.rust-lang.org/std/io/struct.BufWriter.html),
[File::sync_all](https://doc.rust-lang.org/std/fs/struct.File.html#method.sync_all).

If an async write can be cancelled, inspect partial effects before interpreting
delivery: `write_all` is not a transaction that rolls back on cancellation.
Follow [concurrency and cancellation](availability-and-resources.md#concurrency-and-cancellation)
for operation-specific restart/progress and shutdown obligations.

`format!("{}", text)` and `log::info!("{}", text)` do not reparse a runtime string
as formatting directives. Review the real hazards instead: secret-bearing values,
control-character/log forging, unbounded formatting of recursive values, and
reinterpretation by a downstream consumer. Do not attach a format-string injection
label merely because a logged value came from an attacker.
[Formatting contract](https://doc.rust-lang.org/std/macro.format.html),
[log macro conventions](https://docs.rs/log/latest/log/).
