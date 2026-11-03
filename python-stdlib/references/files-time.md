# Files, paths and time

## Contents

- [File operations and missing-versus-invalid data](#file-operations-are-not-existence-predicates)
- [Temporary-file ownership](#temporary-files-and-publication)
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

## Temporary files and publication

| Need | API / ownership |
|---|---|
| Private scratch stream | `TemporaryFile`; do not assume a usable filesystem name. |
| Scratch directory tree | `TemporaryDirectory`; close owned child handles before cleanup. |
| File another program reopens by path | `NamedTemporaryFile(delete_on_close=False)` inside `with`; close extra handles before context exit, especially on Windows. |
| Explicit publication/cleanup control | `mkstemp(dir=destination.parent)` returns an owned descriptor and path; close and unlink them on every non-publication path. |

Use secure creation APIs, not `mktemp` or a guessed unique pathname. `mkstemp`
creates a file accessible only to the creating user where the platform supports
that permission model; decide publication permissions and metadata explicitly.
`delete=False` transfers unlink responsibility to the caller. Context managers do
not promise cleanup after a crash or `SIGKILL`.

For replacement, stage on the destination filesystem, finish writing, close any
handles that would block replacement, then call `os.replace`. An atomic rename
does not preserve the old file's permissions or promise persistence after power
loss. Keep file/directory synchronization and concurrent-writer policy explicit;
do not add a cross-device copy fallback while still claiming atomic visibility.

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
| Recurring local appointment? | Local date/time plus IANA zone and gap/fold policy; resolve each occurrence afresh |
| Elapsed runtime or deadline? | `time.monotonic` or `time.perf_counter` differences |
| CPU used by this process? | `time.process_time` differences, excluding sleep |
| Human display in an IANA zone? | `zoneinfo.ZoneInfo`, with installed zone data |

Use `from datetime import UTC, datetime`; `UTC` is a module constant, not an
attribute of the imported `datetime` class. For older consumers use
`timezone.utc`. `datetime.fromtimestamp(value, UTC)` avoids implicit local time.
`fromisoformat` parses supported ISO forms, not every application's timestamp
contract; explicitly reject a missing offset if a timestamp must be aware.
`utcnow()` and `utcfromtimestamp()` are deprecated since 3.12 and return naive
values; use `datetime.now(UTC)` and `datetime.fromtimestamp(value, UTC)`.

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

Resolve each local wall time by trying both `fold` values, converting to UTC and
round-tripping back to the same wall fields. Deduplicate equal UTC instants:
zero candidates is a gap, one is ordinary, two is ambiguous. Reject or select
according to the caller's policy; `fold=1` alone does not validate existence.
Compare UTC instants for timeline identity: two fold variants with the same zone
object can compare equal despite representing different instants.

For a local-day query, resolve the start of the date and the start of the next
date separately, then use the half-open UTC interval `[start, end)` if that is the
contract. Do not compute the end as `start_utc + timedelta(hours=24)`. Midnight can
itself be ambiguous or nonexistent in some zones; the resolver's policy still
applies. Generate civil recurrences in local calendar space and resolve each date.

The following transition checks require the system IANA database or `tzdata`.
They use fixed dates, not the machine's clock or local timezone.

```pycon
>>> from zoneinfo import ZoneInfo
>>> def wall_instants(wall: datetime, zone) -> list[datetime]:
...     if wall.tzinfo is not None:
...         raise ValueError("expected naive local wall fields")
...     candidates = set()
...     for fold in (0, 1):
...         instant = wall.replace(tzinfo=zone, fold=fold).astimezone(UTC)
...         if instant.astimezone(zone).replace(tzinfo=None) == wall:
...             candidates.add(instant)
...     return sorted(candidates)
>>> ny = ZoneInfo("America/New_York")
>>> assert wall_instants(datetime(2025, 3, 9, 2, 30), ny) == []
>>> repeated = wall_instants(datetime(2025, 11, 2, 1, 30), ny)
>>> assert len(repeated) == 2 and repeated[1] - repeated[0] == timedelta(hours=1)
>>> assert len(wall_instants(datetime(2025, 1, 15, 12), ny)) == 1
>>> start, = wall_instants(datetime(2025, 3, 9), ny)
>>> end, = wall_instants(datetime(2025, 3, 10), ny)
>>> assert end - start == timedelta(hours=23)
>>> assert start <= start < end and not start <= end < end

```

A business-day function needs a signed-day policy, inclusive/exclusive convention,
weekend calendar, and holidays represented as dates; build the holiday set once,
not on every loop. Do not silently return the input for unsupported negative days.
`timedelta.seconds` excludes the day component; use `total_seconds` for a duration.

## Authorities

[pathlib](https://docs.python.org/3.15/library/pathlib.html),
[shutil](https://docs.python.org/3.15/library/shutil.html),
[os.replace](https://docs.python.org/3.15/library/os.html#os.replace),
[tempfile](https://docs.python.org/3.15/library/tempfile.html),
[tar extraction filters](https://docs.python.org/3.15/library/tarfile.html#tarfile-extraction-filter),
[datetime](https://docs.python.org/3.15/library/datetime.html),
[zoneinfo](https://docs.python.org/3.15/library/zoneinfo.html),
[fold and gap rules](https://peps.python.org/pep-0495/),
[time](https://docs.python.org/3.15/library/time.html).
