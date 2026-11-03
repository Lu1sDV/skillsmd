# python-system-design

A self-contained Claude Code skill for Python project/package organization and
service boundaries: modular monoliths, package/workspace correctness,
framework/runtime choice, durable work, transaction ownership, configuration,
containers and operational evidence.
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
- “Check this uv workspace and container build for undeclared dependencies and missing artifacts.”
- “Design readiness, shutdown and bounded telemetry for this web/worker deployment.”

## Reference index

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Quick routing, workflow, high-risk gotchas and completion/evidence contract |
| [Packages and boundaries](references/packages-boundaries.md) | Import contracts, package/workspace choices, metadata/groups/backends, artifacts, namespace packages and service extraction |
| [Web and jobs](references/web-jobs.md) | Frameworks, WSGI/ASGI, resource lifetime, transient/durable jobs, outbox, retry budgets and Celery broker/pool qualifications |
| [Persistence and configuration](references/persistence-config.md) | Transaction/savepoint ownership, database waiting, migrations, SQLite rollback, settings sources and trust boundaries |
| [Deployment and operations](references/deployment-operations.md) | Container install boundaries, release/process lifecycle, probes/drain, bounded metrics, trace propagation and deployed-artifact evidence |

## Version policy and runnable examples

The current stable baseline was checked on **2026-11-03: CPython 3.15.2**
([official release](https://www.python.org/downloads/release/python-3152/)). New
project examples use Python **3.15**; this does not raise an existing application's
supported minimum without a migration decision. Check dependency/native-wheel,
framework and platform support before changing an interpreter. Pre-release and
free-threaded builds are separate choices, not implied defaults.

From this bundle directory:

```sh
python3 -I -W error -m doctest references/*.md
```

The `pycon` examples require Python **3.12+**, `tomllib`, and an interpreter built
with `sqlite3`. They use only the standard library, bounded local data and a
context-managed temporary directory. They assert actual disk-database rollback
and committed state through a second connection, plus configuration precedence,
boolean parsing and rejected invalid values. SQLite connection setup explicitly
uses `autocommit=False`, added in 3.12; each operation owns its connection and
transaction. Example assertions are test checks, not production
validation. There are no network or framework prerequisites for these examples.

All `python`, `toml`, `text` and `sh` fences are explanatory recipes or commands,
not doctest claims. Framework and package recipes require the named dependency,
an existing application/schema where stated, and supported versions selected by
the consuming project. The SQLAlchemy recipe targets **2.x**. The specific Django
async transaction limitation is checked against **6.0**; Flask's async-view caveat applies
to normal WSGI operation with the async extra (introduced in **2.0**). Follow the
project's actual Python/framework compatibility range. Celery controls were
checked against **5.6.3** documentation; Redis and worker-pool limitations are
stated where they matter. uv workspace/build guidance was checked against current
**0.13** documentation, including explicit member conflicts. PostgreSQL references
use the current **18** documentation. Recheck moving documentation before relying
on a feature in a different installed release.

The 15 doctest examples passed on **CPython 3.12.14 and 3.15.2**, in isolated mode
with warnings treated as errors. This executes the local SQLite/settings
assertions; it does not execute framework, broker, container or cloud recipes.
Optional broader checks for a consuming application: install its exact
wheel outside the checkout, run its transaction tests against the production
engine, exercise framework lifespan/auth/error handling, and use a real broker
and worker for crash/redelivery claims. Do not infer those from SQLite or eager
job execution.

## Consolidation and correction decisions

- **Keep the entrypoint short.** The workflow routes to four local references
  with contents lists; optional sibling handoffs are not prerequisites.
- **Earn structural boundaries.** Preserve the modular-monolith default,
  framework conventions and concrete operations. Line counts, team sizes and
  pattern names do not require layers, repositories, gateways or service splits.
- **Keep installation evidence strong.** Editable installs and checkout imports
  cannot prove wheel contents; `pip freeze` alone is not a portable build policy.
- **Retain explicit ownership.** One use case owns its transaction. Closing is
  not committing; after-commit hooks leave a publish gap; status checks are not
  atomic idempotency. Unknown external outcomes require recovery by identity.
- **Qualify runtime promises.** ASGI does not guarantee CPU parallelism, HTTP/2
  or durability. Framework, driver, broker and pool behavior must match the
  installed version and real deployment tests.
- **Keep examples small and executable.** SQLite rollback and TOML parsing remain
  the local stdlib evidence. Infrastructure recipes are conditional; startup
  configuration, secret rotation, validation and cancellation remain explicit.

## Community review and selective additions — 2026-11-03

The supplied candidate review was used for discovery, not accepted as an authority.
Retained technical claims were checked against the linked primary documentation;
community scripts were not executed or vendored. The following records the useful
selection rather than importing whole skills or their preferred stacks. Linked
community inputs are pinned to inspected repository revisions; their file contents
were checked against the reviewed Git blobs. Unlinked names identify discovery or
screening inputs, not an assertion that their implementations were fully audited.

| Proposal cluster / review input | Decision and resulting boundary |
|---|---|
| [paldom packaging](https://github.com/paldom/python-skills/blob/70aa0cf9926285dbef6ac39bc36990ece230cd09/skills/python-packaging/SKILL.md) | **Adapt:** backend capability, local dependency groups and artifact-content checks. Preserve the stronger outside-checkout wheel smoke; uv environment isolation alone does not remove cwd from Python imports. Do not ban working backends or existing dev extras. |
| [bm629 monorepos](https://github.com/bm629/agent-skills/blob/7f3a7ecc18621deac40b5c366bcceeb84089d912/skills/python-monorepo-architecture/SKILL.md), [martinffx monorepos](https://github.com/martinffx/python-skills/blob/4d2ccb744db9c90bf786a8c261e7be0cd4c8c57e/skills/python-monorepo/SKILL.md) | **Adapt:** per-consumer source wiring, declared member dependencies, clean artifact installs and namespace ownership. Compatible Python ranges may overlap; current uv also supports explicitly conflicting members that cannot be installed together. Avoid needless package splits. |
| [azzam modular monolith](https://github.com/azzam-almatrafi/skills/blob/6b38bde134edf928d8d29680fbbb14c247327aae/modular-monolith-architecture-FastAPI/SKILL.md), athola modular-monolith, keez97 architecture-review, ECC hexagonal-architecture | **Adapt narrowly:** intentional public surfaces, enforceable import rules and reversible boundary migration. Reject compulsory layers/gateways/ports, numeric coupling thresholds, blanket removal of cross-module FKs and per-module migration histories. Existing service-cutover/transaction guidance remains authoritative here. |
| [baggiponte Dockerfiles](https://github.com/baggiponte/skills/blob/3ddeabd7cda12871cbe20e414b043039b3d28ff0/build-python-dockerfiles/SKILL.md), [wdm web architecture](https://github.com/wdm0006/python-skills/blob/456ad29b98671a310dcb56165c6f0d7c63ca2c19/skills/python/web-app-architecture/SKILL.md) | **Adapt:** dependency/source layers, noneditable runtime install, optional shared image and explicit migration command. Add final lock validation, runtime ABI/path compatibility and tested signal handling. Reject fixed framework/hosting/auth/billing stacks, universal proxy-hop positions and blanket limiter-outage policy. |
| [julianobarbosa infrastructure](https://github.com/julianobarbosa/claude-code-skills/blob/c8aec74590186f68a8a333248328cf76737785e4/skills/python-infrastructure/SKILL.md), bobmatnyc Celery, ECC django-celery, [wshobson background jobs](https://github.com/wshobson/agents/blob/7e2fb559cf4b824b27f1fec49fe88f7511066d26/plugins/python-development/skills/python-background-jobs/SKILL.md) | **Adapt:** concrete acknowledgement, prefetch, visibility and pool/time-limit contracts. Keep crash/duplicate tests with real workers; early acknowledgement is a loss window, prefetch is workload-dependent, and eager mode cannot verify delivery. |
| [Temporal developer](https://github.com/temporalio/skill-temporal-developer/blob/5f5a94d448d53e0d535a7369bf9cb7248620a0bf/references/core/job-queue.md) | **Adapt only retry accounting:** distinguish retries from attempts and bound nested retry budgets. Leave SDK-specific standalone Activity APIs, identity policies and workflow-engine migration outside this guide; scheduling identity cannot guarantee unique external effects. |
| [ECC PostgreSQL](https://github.com/affaan-m/ECC/blob/b38be6a7f6350964d59328b52f0624e1d1d552d1/skills/postgres-patterns/SKILL.md), agusabas Django clean DRF | **Adapt:** lock/statement/idle-transaction budgets and explicit savepoint semantics. A `SKIP LOCKED` claim needs a recovery protocol; a failed return does not roll back; reload cannot apply restart-only server settings. Omit generic tuning SQL and ORM scaffolds. |
| [wshobson configuration](https://github.com/wshobson/agents/blob/7e2fb559cf4b824b27f1fec49fe88f7511066d26/plugins/python-development/skills/python-configuration/SKILL.md) | **Adapt:** optional secret files/nested settings, source precedence, alias/case and JSON-decoding qualifications. Keep startup construction and sanitized failures; reject import-time exit and secret-bearing dumps. |
| [wshobson observability](https://github.com/wshobson/agents/blob/7e2fb559cf4b824b27f1fec49fe88f7511066d26/plugins/python-development/skills/python-observability/references/details.md), julianobarbosa infrastructure | **Adapt:** bounded route/error dimensions, service identity, logging integration, queue trace propagation and provider lifecycle. Do not copy custom middleware with uninitialized cancellation status or assume every logger uses the application renderer. |
| [szybnev resource lifetimes](https://github.com/szybnev/dev-skills/blob/0b4c9102d417338f402e7e5dff0dcff5e4c6a9ad/.agents/skills/python-resource-lifetimes/SKILL.md) | **Adopt the constraint:** state owner/last use/exit paths; test cancellation independently and do not rely on finalizers. |
| iktakahiro DDD, wshobson FastAPI templates, laurigates packaging | **No scaffold import:** money/DTO/API details belong to the relevant contract, not a new system layer. Existing artifact/entry-point guidance suffices; publishing workflows and invented dynamic-version settings are not added. |
| wshobson packaging/project-structure; chalk clean architecture; ECC backend-patterns; rknall/rafaelkamimura architecture; szybnev ORM; ancoleman queues | **Decline:** duplicate guidance, mandatory structure, unsafe or incomplete examples, or insufficient net-new value. No claim is made that every declined implementation was exhaustively executed or audited. |

Review corrections are deliberately narrower than the pasted verdicts: the
Docker candidate already sets `STOPSIGNAL SIGINT`, and the current monolith
[example's two commits](https://github.com/azzam-almatrafi/skills/blob/6b38bde134edf928d8d29680fbbb14c247327aae/modular-monolith-architecture-FastAPI/references/module-design.md)
occur in separate use cases. Neither observation replaces
testing the actual signal/transaction contract. The web candidate's
[password verification proposal](https://github.com/wdm0006/python-skills/blob/456ad29b98671a310dcb56165c6f0d7c63ca2c19/skills/python/web-app-architecture/AUTH.md)
also needs version-specific legacy handling: the inspected
[pyca/bcrypt implementation](https://github.com/pyca/bcrypt/blob/35b3dbec3a5a6102889772c2c46c8ee493564572/src/_bcrypt/src/lib.rs)
rejects inputs over 72 bytes through `checkpw` as well as `hashpw`. Auth templates
are outside this bundle; the claim of defect-free transfer was not retained.

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
PEP 3333, ASGI specification, PyPA/pip/uv, Python sqlite3, Django 6.0, Flask,
FastAPI, SQLAlchemy 2.x, PostgreSQL, Docker, Kubernetes, OpenTelemetry and the queue
maintainers. These sources qualify/correct
upstream teaching examples; they are not execution evidence for this bundle.
Upstream material is MIT-licensed; retain the exact [LICENSE.upstream](LICENSE.upstream).
