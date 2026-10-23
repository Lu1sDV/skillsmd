# Files, paths and time

## Contents

- [File operations and missing-versus-invalid data](#file-operations-are-not-existence-predicates)
- [Copy, move, archive and deletion](#copy-move-archive-and-deletion-contracts)
- [Timestamps, durations and calendars](#timestamps-durations-and-calendars)

## File operations are not existence predicates

Prefer `Path` for local filesystem paths and `PurePath` for lexical manipulation.
Joining an absolute right operand discards the preceding base. `is_relative_to`
does not resolve symlinks or `..`. Resolving and checking containment is useful in
a trusted, stable tree, not a race-free security boundary for an attacker-writable
one. Use appropriate OS directory-descriptor operations or isolation for that case.

| Operation | Default | Failure / ownership policy |
|---|---|---|
| Small complete text file | `read_text(encoding="utf-8")` | Decoding failure is not an empty file |
| Large text | `open(encoding="utf-8")` and iterate | Bound individual records as well as total input where untrusted |
| Exact binary content | `read_bytes` or binary stream | Do not decode arbitrary payloads or translate newlines |
| Create once | `open("x", encoding="utf-8")` | Fail rather than overwrite an existing name |
| Optional read | Read, then catch `FileNotFoundError` | Avoid exists-then-open races; do not hide other `OSError`s |
| Make parents | `mkdir(parents=True, exist_ok=True)` | Existing non-directory, permission and device errors still matter |
| Enumerate files | `iterdir`, `glob`, `rglob` | Order is not guaranteed; decide symlink policy and resource bounds |
| Replace existing file | Temporary sibling + `os.replace` | Same-filesystem atomic visibility is not crash durability |
| Remove absent-or-present file | `unlink(missing_ok=True)` | Missing is acceptable; permission and wrong-kind errors are not |

For atomic replacement, write and close a temporary file in the destination
directory, then replace it, cleaning up the temporary on failure. Decide whether
the application additionally needs file and directory `fsync`, metadata retention,
or concurrent-writer coordination. Do not label a direct `write_text` atomic.
Do not give a generic replacement recipe a security guarantee for untrusted paths.

```pycon
>>> from pathlib import Path
>>> from tempfile import TemporaryDirectory
>>> def read_optional(path: Path) -> str | None:
...     try:
...         return path.read_text(encoding="utf-8")
...     except FileNotFoundError:
...         return None
>>> with TemporaryDirectory() as directory:
...     path = Path(directory) / "record.txt"
...     assert read_optional(path) is None
...     _ = path.write_bytes("café\n".encode("utf-8"))
...     assert read_optional(path) == "café\n"
...     _ = path.write_bytes(b"\xff")
...     try:
...         read_optional(path)
...     except UnicodeDecodeError:
...         pass
...     else:
...         raise AssertionError("invalid encoding was hidden as absence")

```

Text streams normally normalize newlines. Use `newline=""` to preserve the line
endings when the parser owns that policy. Do not use `.strip()` to remove a line
terminator when leading/trailing spaces are payload. A single extremely long line
can defeat an otherwise streaming memory budget; use bounded reads if required.

## Copy, move, archive and deletion contracts

- `copyfile` copies content; `copy` also preserves permission mode; `copy2` attempts
  more metadata but cannot preserve all ownership/ACL/platform metadata. Choose
  whether symlinks are copied or followed; do not equate a copy with a backup.
- `copytree(..., dirs_exist_ok=True)` merges into an existing tree and may overwrite
  files. Neither copying a tree nor a cross-filesystem `shutil.move` is atomic.
- `rmtree(ignore_errors=True)` suppresses removal errors generally, not just a
  missing directory. Preserve unexpected errors and define the authorized root
  before destructive traversal. Symlink-attack resistance is platform-dependent.
- `rmtree(onexc=...)` was added in **3.12**, not 3.11. Its third callback argument is
  an exception object; deprecated `onerror` receives an `exc_info` tuple.
- `shutil.which` searches an environment-dependent executable path. Use a trusted
  absolute executable path when PATH manipulation is part of the threat model.
- Archive extraction needs a trusted destination, member/path policy, and bounds
  on member count and decompressed size. Never unpack untrusted content into a
  live code/configuration directory. `shutil.unpack_archive` supports a `filter`
  for tar, not ZIP; tar's `data` filter is default in 3.14 and is not a sandbox.
  Consult the deployed version for extraction-filter availability/backports.
- `make_archive`, `get_archive_formats`, `disk_usage` and `copyfileobj` avoid custom
  wrappers. With `copyfileobj`, use a bounded buffer and flush/close the destination
  before reading it; free-space observation does not reserve storage.

## Timestamps, durations and calendars

| Question | Representation |
|---|---|
| Which instant? | Aware `datetime`; explicit UTC at interchange |
| Which local calendar date? | `date` plus the applicable business/time-zone policy |
| Elapsed runtime or deadline? | `time.monotonic` or `time.perf_counter` differences |
| CPU used by this process? | `time.process_time` differences, excluding sleep |
| Human display in an IANA zone? | `zoneinfo.ZoneInfo`, with installed zone data |

Use `from datetime import UTC, datetime`; `UTC` is a module constant, not an
attribute of the imported `datetime` class. For older consumers use
`timezone.utc`. `datetime.fromtimestamp(value, UTC)` avoids implicit local time.
`fromisoformat` parses supported ISO forms, not every application's timestamp
contract; explicitly reject a missing offset if a timestamp must be aware.

`replace(tzinfo=zone)` attaches an interpretation to wall-clock fields without
conversion. `astimezone(zone)` converts an existing instant. Naive values have no
universal instant; do not guess the server's local zone on their behalf.

```pycon
>>> from datetime import UTC, datetime, timedelta, timezone
>>> def parse_instant(text: str) -> datetime:
...     value = datetime.fromisoformat(text)
...     if value.utcoffset() is None:
...         raise ValueError("timestamp requires an offset")
...     return value.astimezone(UTC)
>>> instant = parse_instant("2025-01-15T13:30:00+02:00")
>>> assert instant == datetime(2025, 1, 15, 11, 30, tzinfo=UTC)
>>> assert instant.astimezone(timezone(timedelta(hours=-5))).hour == 6
>>> parse_instant("2025-01-15T13:30:00")
Traceback (most recent call last):
    ...
ValueError: timestamp requires an offset
>>> duration = timedelta(days=2, hours=3)
>>> assert duration.seconds == 10800 and duration.total_seconds() == 183600

```

IANA rules need system zone data or the separately installed `tzdata` package;
Windows does not typically provide the same zone database as Unix. Do not hide
`ZoneInfoNotFoundError` with a fallback fixed offset. DST transitions can create
missing or repeated local wall times; attaching a zone does not itself validate
existence. Decide rejection/normalization and `fold` for ambiguous inputs.
For elapsed time between instants, convert to UTC before subtracting; subtraction
of datetimes sharing the same tzinfo uses wall-time arithmetic. Adding one local
calendar day is not necessarily adding 24 elapsed hours.

A business-day function needs a signed-day policy, inclusive/exclusive convention,
weekend calendar, and holidays represented as dates; build the holiday set once,
not on every loop. Do not silently return the input for unsupported negative days.
`timedelta.seconds` excludes the day component; use `total_seconds` for a duration.

## Authorities

[pathlib](https://docs.python.org/3.14/library/pathlib.html),
[shutil](https://docs.python.org/3.14/library/shutil.html),
[os.replace](https://docs.python.org/3.14/library/os.html#os.replace),
[tar extraction filters](https://docs.python.org/3.14/library/tarfile.html#tarfile-extraction-filter),
[datetime](https://docs.python.org/3.14/library/datetime.html),
[zoneinfo](https://docs.python.org/3.14/library/zoneinfo.html),
[time](https://docs.python.org/3.14/library/time.html).
