# python-stdlib

Python standard-library selection and boundary contracts: iteration/caching,
files/time, serialization/text, records, cleanup, logging and child processes.

## Install

From this repository checkout:

```sh
mkdir -p ~/.claude/skills && cp -r python-stdlib ~/.claude/skills/
```

Preserve local changes before replacing an existing installation. This directory
includes all required references and attribution; no sibling skill is required.

## Usage prompts

- “Use python-stdlib to review this iterator pipeline for consumption and buffering.”
- “Replace this custom cache with the stdlib if its invalidation contract permits.”
- “Review our JSON/CSV import for duplicate fields, Unicode, NaN and data loss.”
- “Check this file/time handling for missing-versus-invalid data and timezone bugs.”
- “Make this subprocess wrapper preserve failures and own its child lifecycle.”

## Reference index

| File | Coverage |
|---|---|
| [SKILL.md](SKILL.md) | Compact routing, workflow and essential guardrails |
| [Collections and iteration](references/collections-iteration.md) | Containers, lazy consumption, caches, copying, functional/numeric utilities |
| [Files and time](references/files-time.md) | Paths, encoding, copies/archives/deletion, timestamps/calendars/durations |
| [Serialization and text](references/serialization-text.md) | JSON, CSV, TOML, pickle trust, Unicode regex, formatting/diffs |
| [Records and processes](references/records-processes.md) | Dataclasses/enums, contextlib, logging, environment and subprocesses |
| [LICENSE.upstream](LICENSE.upstream) | Preserved upstream MIT notice |

Algorithm implementation goes to **python-algorithms**; ordinary language/tooling
to **python-idiomatic**; public typing/design to **python-api-design**; structured
concurrency to **python-concurrency**; service/configuration architecture to
**python-system-design**; test-first work to **python-tdd**, when installed.

## Runnable examples

From the repository root:

```sh
python3 -m doctest python-stdlib/SKILL.md python-stdlib/references/*.md
```

Or from an independently copied bundle:

```sh
python3 -m doctest SKILL.md references/*.md
```

The `pycon` fences are complete stdlib examples with meaningful assertions. They
use temporary files, a real child interpreter, and deterministic data; no network,
third-party package, timezone database or persistent user-file writes are needed.
The example baseline is Python 3.11+; run checks on the consumer's actual versions.
Newer APIs are described with version gates, not assumed available by every example.

These commands do not certify platform-specific permissions, symlink-attack
resistance, archive confinement, crash durability, Windows batch execution,
process-tree cleanup, or real time-zone transitions. Those need environment-specific
checks when used. No external program, shell or benchmark recipe is silently
executed by doctest.

## Sources and adaptation

Original synthesis/adaptation of
[nirajkvinit / StructWeave-Algorithms](https://github.com/nirajkvinit/StructWeave-Algorithms),
pinned at Python-content commit `0b88a786ef09681717a805d9f7e0b195ab610f6c`:

| Upstream guide | Destination |
|---|---|
| [05 — Standard library](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/05-standard-library.md) | Collections/iteration/functions/numeric helpers/copying; detailed algorithms handed off |
| [16 — Standard library essentials](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/16-standard-library-essentials.md) | Production files/time/formats/records/cleanup/process APIs; syntax/typing/concurrency routed to dedicated skills |

### Consolidation and correction decisions

- Merge the two stdlib chapters into four on-demand references with contents lists.
  Keep only routing/workflow/essential guardrails in the entrypoint, not a duplicate
  API catalogue. Algorithms and public type design remain separate skills.
- Replace list-key memoization with explicit hashability/lifetime guidance;
  distinguish run grouping, signed Counter subtraction, buffering and shallow copies.
- Correct the JSON claim: `json.dumps` permits nonfinite values by default, rather
  than raising. Decode policy must separately address constants, duplicate keys,
  overflow and schema validation.
- Do not reproduce a pickle example containing an unserializable lambda or suggest
  that authentication turns untrusted code-bearing data into a safe format.
- Correct `datetime.UTC` import usage, timezone labeling versus conversion, and
  whole-duration arithmetic. Avoid environment-dependent clock/zone examples.
- Correct `rmtree(onexc=...)` to 3.12, broad error-suppression claims, metadata
  preservation guarantees and unqualified archive extraction advice.
- Correct dataclass field ordering, shallow freezing/hashability and implicit
  validation claims. Record replacement is not deep copying or secret redaction.
- Correct eager f-string logging (including 3.12+) and Unicode regex classes.
  Do not inherit broken generic email/date regex validation.
- Replace abandoned-process streaming with lifecycle guidance and a real bounded
  child example. Distinguish shell interpretation from target-option injection.
- Preserve version gates, qualified guarantees and first-party references instead
  of upstream speed percentages and “safe by default” generalizations.

Upstream attribution is retained in [LICENSE.upstream](LICENSE.upstream).
