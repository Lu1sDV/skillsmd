# python-stdlib

Python standard-library selection and boundary contracts: iteration/caching,
files/time, serialization/text, AST source analysis, records, cleanup,
logging and child processes.
The baseline is **CPython 3.15.2**, the latest stable release checked on
**2026-11-03**; refresh that fact against Python.org before a later revision.

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
- “Review this AST analyzer for Python 3.15 syntax and constructor compatibility.”

## Reference index

| File | Coverage |
|---|---|
| [SKILL.md](SKILL.md) | Compact routing, workflow and essential guardrails |
| [Collections and iteration](references/collections-iteration.md) | Containers, lazy consumption, caches, copying, functional/numeric utilities |
| [Files and time](references/files-time.md) | Paths, temporary-file ownership, atomic visibility, DST gaps/folds and calendar intervals |
| [Serialization and text](references/serialization-text.md) | JSON, CSV, TOML, pickle trust, Unicode regex, formatting/diffs |
| [Records and processes](references/records-processes.md) | Dataclasses/enums, contextlib, SQLite transaction/closing boundaries, logging, CLI dispatch and subprocesses |
| [AST and source analysis](references/ast-source-analysis.md) | Parse without imports, 3.15 constructor fields, source fidelity, scanner semantic/version gates |
| [Runtime compatibility](references/runtime-compatibility.md) | Current stable baseline, removed APIs, UTF-8 defaults and module availability |
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
use temporary files, a real child interpreter, SQLite and deterministic data;
no network or persistent user-file writes are needed. The example baseline is
CPython 3.15.2. The DST checks require an IANA timezone database supplied by the OS
or the `tzdata` package, and SQLite must be enabled in the interpreter build.
Report an absent prerequisite rather than silently skipping those checks.

These commands do not certify platform-specific permissions, symlink-attack
resistance, archive confinement, crash durability, Windows batch execution,
process-tree cleanup, or every timezone/version rule. Those need environment-specific
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

- Merge the two stdlib chapters into topical on-demand references with contents lists.
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

### Community curation, 2026-11-03

Inspect promising sources as leads, then verify each proposed rule independently.
The sources below were directly read; links identify the retrieved mutable files,
not verified immutable commits. Added examples are original contract checks.

| Inspected source | Integration decision |
|---|---|
| [schattenspiegel datetime/zoneinfo](https://github.com/schattenspiegel/skill-foundry-skills/blob/main/skills/datetime-zoneinfo-python/SKILL.md) | Add UTC round-trip resolution, ordinary/gap/fold distinctions, civil recurrences and local-day boundaries; test a 23-hour day instead of assuming 24 hours. |
| [bedkillerspacex-boop temporary files](https://github.com/bedkillerspacex-boop/codex-skill-library/blob/main/python-tempfile-safe/SKILL.md) | Adapt creation/cleanup and same-filesystem staging. Keep Windows reopen rules, metadata, durability and hostile-path limits explicit; do not copy an unqualified atomic/security recipe. |
| [modbender CSV](https://github.com/modbender/skill-library-mcp/blob/main/data/csv/SKILL.md) | Adopt BOM/dialect awareness after correction: default Python CSV does not distinguish quoted empties, a final newline creates no extra record, and quoting does not force spreadsheet types. |
| [reysree sqlite3 guide](https://github.com/reysree/RealPage/blob/main/.claude/skills/sqlite3-guide/SKILL.md) | Correct its claim that the connection context manager closes the connection. Add independent rollback and explicit-close assertions, with deliberate transaction mode. |
| [agentmemoir subprocess/concurrency](https://github.com/agentmemoir/skills/blob/main/skills/code/python-subprocess-and-concurrency/SKILL.md) | Adopt child input/pipe/process-group questions; reject universal shell bans, platform-independent tree-kill claims and direct-child-only escalation logic. |
| [Tyler-R-Kendrick Python CLI](https://github.com/Tyler-R-Kendrick/agent-skills/blob/main/skills/python/cli/SKILL.md) | Retain only argparse's subcommand-to-handler pattern; framework recommendations and UI policies stay project choices. |

Existing iteration and cache coverage already addressed many listed candidates;
add only the missing dispatch/security distinctions. Do not import broad module
catalogues, version-feature inventories or framework-specific recipes. The new
runtime reference selects actual migration failure points and routes language,
typing and concurrency details to their owning skills.

### Modern-Python stdlib gaps (2026-11-03)

The supplied 3.13–3.15 review was used as a candidate list, then the selected
rules were checked against the [3.15 pathlib](https://docs.python.org/3.15/library/pathlib.html)
and [AST](https://docs.python.org/3.15/library/ast.html) documentation. Added:

- A distinction between `Path.exists()` / type predicates that can suppress
  inaccessible-path errors, error-preserving `stat()` or `lstat()`, and cached
  `Path.info` observations; absence of findings is not traversal completion.
- A directly routed AST guide for source-only scanning, required 3.15
  constructor fields, optimized-tree hazards and separate grammar, symbol,
  semantic-model and data-flow compatibility gates.

The AST examples require Python 3.15 for their constructor rejection and
`ast.compare` checks. Existing doctest run counts are historical until
reverified on the updated bundle.
