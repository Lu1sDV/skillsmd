# python-system-design

A self-contained Claude Code skill for Python project/package organization and
service boundaries: modular monoliths, framework/runtime choice, background-job
lifetime, transaction ownership, configuration, secrets and integration seams.
It favors existing framework conventions and concrete application functions over
mandatory repositories, DI containers or microservices. No production app is
bundled, and no sibling skill is required.

## Install from a checkout

From the repository root:

```sh
mkdir -p ~/.claude/skills
cp -r python-system-design ~/.claude/skills/
```

Before replacing an installed copy, preserve its local changes; do not merge an
old bundle blindly with this one. Keep `SKILL.md`, `references/`, this README and
`LICENSE.upstream` together. This installs guidance, not a Python package or web
server. Optional handoffs name other skills only when installed.

## Example prompts

- “Structure this Python CLI and API as a modular monolith without generic repositories.”
- “Choose WSGI or ASGI for our existing drivers, middleware and streaming requirements.”
- “Decide which after-response tasks need a durable queue and an idempotency contract.”
- “Fix this unit of work so a later database failure rolls back the earlier writes.”
- “Review startup configuration, secret handling and installed-wheel test boundaries.”

## Reference index

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Quick routing, workflow, high-risk gotchas and completion/evidence contract |
| [Packages and boundaries](references/packages-boundaries.md) | Flat/features/layers, imports, modular monolith versus services, pyproject/entry points, editable versus wheel installation and test seams |
| [Web and jobs](references/web-jobs.md) | Django/Flask/FastAPI, WSGI/ASGI, middleware, startup/shutdown, worker budgets, Celery/RQ/Dramatiq, transient versus durable jobs, outbox and delivery contracts |
| [Persistence and configuration](references/persistence-config.md) | Session/unit-of-work ownership, pooling/constraints/migrations, real SQLite rollback, TOML/environment parsing, secret/trust boundaries and integration evidence |

## Runnable examples and limits

From this bundle directory:

```sh
python3 -m doctest references/*.md
```

The `pycon` examples require Python **3.11+**, `tomllib`, and an interpreter built
with `sqlite3`. They use only the standard library, bounded local data and a
context-managed temporary directory. They assert actual disk-database rollback
and committed state through a second connection, plus configuration precedence,
boolean parsing and rejected invalid values. SQLite connection setup explicitly
selects legacy transaction behavior on Python 3.12+; it does not rely on the
future `autocommit` default. Example assertions are test checks, not production
validation. There are no network or framework prerequisites for these examples.

All `python`, `toml`, `text` and `sh` fences are explanatory recipes or commands,
not doctest claims. Framework and package recipes require the named dependency,
an existing application/schema where stated, and supported versions selected by
the consuming project. The SQLAlchemy recipe targets **2.x**. The specific Django
async transaction limitation is pinned to **5.2**; Flask's async-view caveat applies
to normal WSGI operation with the async extra (introduced in **2.0**). Follow the
project's actual Python/framework compatibility range rather than upgrading to
these baselines automatically. Queue features and server protocol support vary
by installed release/configuration.

No examples or optional recipes have been executed as part of authoring this
bundle. The command above is the recommended integration smoke, not a passed
result. Optional broader checks for a consuming application: install its exact
wheel outside the checkout, run its transaction tests against the production
engine, exercise framework lifespan/auth/error handling, and use a real broker
and worker for crash/redelivery claims. Do not infer those from SQLite or eager
job execution.

## Consolidation and correction decisions

- **Keep the entrypoint as routing and boundary policy.** Detailed selection
  tables, failure caveats and examples remain in the three directly linked
  references, each with a contents list. Owner escalation and migration tracking
  stay conditional workflow steps rather than a separate process.
- **Keep a modular monolith as the default.** The source's line-count/team-size
  thresholds and architectural “evolution” ladder are not requirements. Structure
  follows cohesion and ownership, not an inevitable progression to clean
  architecture or microservices.
- **Reuse frameworks rather than wrap every operation.** Cover flat, feature and
  layered layouts, app factories and thin adapters without mandatory service
  classes, generic repositories or a DI container. Type/GoF mechanics are an
  optional python-api-design handoff, not duplicated here.
- **Correct packaging evidence.** `src/` prevents common checkout-import mistakes;
  an editable install still uses development sources and does not prove wheel
  contents. Installed-wheel checks must run outside the source tree. `pip freeze`
  is an environment snapshot, not a complete portable reproducibility policy.
- **Correct runtime generalizations.** WSGI does not force deployment-wide serial
  execution; ASGI does not guarantee HTTP/2, durability or CPU speedups. Flask has
  native optional async-view support, Django has version-specific async limits,
  and ordinary helpers called inside async handlers still block unless offloaded.
  No universal framework performance ranking is retained.
- **Make transaction ownership coherent.** Replace the source's repository-level
  commits under a nominal unit of work with one use-case transaction owner.
  Closing a session does not imply commit, and an after-commit callback does not
  close the database-to-broker crash gap. SQLAlchemy engine disposal is not the
  source's unqualified `engine.disconnect()` call.
- **Do not imply exactly-once jobs.** A status check followed by work/save is not
  atomic idempotency. Cover unique keys, unknown external outcomes, outboxes,
  acknowledgement settings, bounded retries and worker-loss evidence. RQ support
  is release-specific; the old blanket “Redis only” matrix is not retained.
- **Keep configuration testable.** Parse once with explicit precedence and invalid
  value handling; distinguish strings from booleans and annotations from runtime
  checks. Do not require Pydantic Settings, cache secrets forever, or perform
  production I/O at import time. Framework settings APIs are version-matched.
- **Replace pseudo-production scaffolds with real small boundaries.** SQLite
  rollback and TOML parsing are concrete stdlib examples; broker, web and ORM
  recipes remain explicitly optional. Generic TDD/concurrency implementation can
  hand off to python-tdd/python-concurrency without a runtime dependency on them.

## Sources and attribution

Original synthesis adapted from StructWeave-Algorithms Python-content revision
`0b88a786ef09681717a805d9f7e0b195ab610f6c`:

| Pinned source | Coverage here |
|---|---|
| [15 System design](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/15-system-design.md) | Entire chapter: philosophy/layout/packages; framework and gateway protocols/middleware; background tasks; database/UoW/pooling; settings/secrets; testing; anti-patterns; practical/interview/quick-reference decisions, consolidated into three local references |
| [08 Tooling and testing](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/08-tooling-testing.md) | Environment and package metadata/installation sections; generic linting/testing remains outside this skill |
| [13 Anti-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/13-anti-patterns-best-practices.md) | Import-cycle and production-configuration boundary selections |
| [16 Standard library essentials](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/16-standard-library-essentials.md) | TOML settings parsing selection; general stdlib catalog remains outside this skill |

Sensitive runtime claims link primary docs in the corresponding references:
PEP 3333, ASGI specification, PyPA/pip, Python sqlite3, Django 5.2, Flask,
FastAPI, SQLAlchemy 2.x and the queue maintainers. These sources qualify/correct
upstream teaching examples; they are not execution evidence for this bundle.
Upstream material is MIT-licensed; retain the exact [LICENSE.upstream](LICENSE.upstream).
