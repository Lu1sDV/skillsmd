---
name: python-stdlib
description: >
  Use when choosing or debugging Python standard-library APIs for iteration,
  caching, files, timestamps, JSON/CSV/TOML, regex, logging, dataclasses,
  resource cleanup, or subprocesses, especially boundary and data-loss bugs.
---

# Python Standard Library

## Quick reference: routing

| Task / symptom | Read |
|---|---|
| Counting, grouping, lazy pipelines, memoization, copying, numeric utilities | [Collections and iteration](references/collections-iteration.md) |
| Paths, text encoding, copying/deleting files, archives, UTC and durations | [Files and time](references/files-time.md) |
| JSON/CSV/TOML, Unicode regex, text transformations and diffs | [Serialization and text](references/serialization-text.md) |
| Dataclasses/enums, resource lifetimes, logging, environment and child processes | [Records and processes](references/records-processes.md) |

Load only the relevant reference. Each is bundled locally; sibling skills are
optional. Runnable examples use Python 3.11+; newer APIs have explicit gates.

## Workflow

1. Inspect the consumer's Python/OS versions, encoding, input size, dependencies
   and callers; preserve its support policy. Newer APIs are gated in the references.
2. Define absence versus invalid data, mutation, resource ownership and partial
   effects. Ask only when project context leaves destructive authority or a
   loss/overwrite policy unresolved.
3. Prefer a built-in or stdlib operation to a wrapper. Bound untrusted bytes,
   records, nesting, expansion and retained state; parsers do not supply your quota.
4. Give resources a lexical owner. Catch only recoverable failures; never turn
   malformed data, permission errors or failed child exits into success defaults.
5. Exercise the real boundary: exhausted input, duplicates, Unicode, missing
   versus invalid files, failed exits and cleanup as relevant. Fix failing checks
   before completion; report the interpreter/platform and untested assumptions.

## Failure modes worth stopping for

- **Consumption and retention:** iterators are one-shot; `tee`/`cycle` can buffer.
  Caches retain inputs/results, share mutable results, and are not single-flight.
  Do not cache coroutine or generator objects.
- **Filesystem safety:** lexical containment and resolve-then-check are not
  race-free symlink defenses. Copy/move/overwrite operations need an explicit
  metadata, atomicity and deletion policy; broad error suppression hides failures.
- **Time semantics:** `replace(tzinfo=...)` labels wall time; `astimezone` converts
  an instant. Define DST ambiguity; use a monotonic clock for elapsed deadlines.
- **Parsing is not validation:** JSON accepts duplicate keys/nonfinite constants;
  `strict=True` does not reject them. CSV quoting does not neutralize spreadsheet
  formulas. Never unpickle untrusted data.
- **Records and logs:** frozen fields do not freeze their children; `asdict` does
  not redact secrets. Logging arguments and f-strings are evaluated before the call.
- **Child processes:** `shell=False` does not prevent target-option injection or
  an attacker-selected executable. Bound output, propagate exit failures, reap
  children, and distinguish one-child timeouts from process-tree cleanup.

## Completion criteria and handoffs

The chosen API must preserve required bytes, ordering, errors and ownership.
Do not claim cross-version/platform compatibility from one local run.
Runnable examples and commands: [README](README.md#runnable-examples).

Optional handoffs: **python-algorithms** for algorithm selection,
**python-api-design** for public typing, **python-concurrency** for task lifetime,
and **python-system-design** for service/transaction architecture.

Adapted from StructWeave 05/16: [source and correction map](README.md#sources-and-adaptation),
[upstream MIT notice](LICENSE.upstream).
