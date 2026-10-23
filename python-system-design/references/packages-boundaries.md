# Packages, installation and service boundaries

## Contents

- [Choose a shape by coupling, not size](#choose-a-shape-by-coupling-not-size)
- [Dependency direction and composition](#dependency-direction-and-composition)
- [Installing the application is a boundary](#installing-the-application-is-a-boundary)
- [When a service boundary is justified](#when-a-service-boundary-is-justified)
- [Make tests follow the boundary](#make-tests-follow-the-boundary)

## Choose a shape by coupling, not size

| Shape | Useful when | Keep out |
|---|---|---|
| One script/module | One operation, little reuse | Empty architectural folders |
| Flat import package | CLI/library with a few cohesive modules | A miscellaneous `utils` dumping ground |
| Feature packages | Related business operations evolve together | Cross-feature imports of adapter internals |
| Shared application functions | CLI, HTTP and worker need the same operation | HTTP response objects in domain rules |
| Separate service | Independent ownership, isolation or scaling justifies it | Distributed transactions hidden behind local-looking methods |

The default for an application is one deployable modular monolith. Feature-based
and layered organization are alternatives, not maturity levels. Use layers inside
a feature only when they make dependency direction and ownership clearer.

Illustrative layout for a packaged application, not files to create automatically:

```text
pyproject.toml
src/stockroom/
    __init__.py
    cli.py                 # parse/render CLI input and output
    web.py                 # optional HTTP adapter and app construction
    settings.py            # parse/validate startup configuration
    inventory/
        operations.py      # reserve/release use cases
        queries.py         # meaningful database operations, if needed
        rules.py           # framework-independent calculations/invariants
    jobs.py                # optional worker entry points calling operations
migrations/                # only when using a migrated database schema
tests/
```

A smaller tool can put `operations.py` directly in `stockroom/`. Django projects
can use Django apps and its conventional settings/URL modules instead. Do not
force an existing project into this particular tree.

## Dependency direction and composition

Adapters call application operations; rules should not import adapters. Keep
transport validation at the boundary and business invariants in a shared operation
so a worker or CLI cannot bypass them. A web framework's schema model may be
translated to ordinary typed arguments without creating a second hierarchy of
identical DTO classes.

Construct settings and resources in the entry point/application factory. Pass
concrete collaborators to the operation. A function argument is dependency
injection; a container, repository interface and factory are not prerequisites.
Use a small Protocol only when its contract represents actual variation or a
useful test seam; a concrete session is often the clearest dependency.

For an import cycle, first draw the two responsibilities: move shared policy/data
to the lower-level module or let an orchestration function depend on both. Local
imports can defer genuine optional dependencies, but hiding every cycle behind a
function does not repair the architecture. `TYPE_CHECKING` affects annotations;
it does not supply missing runtime names used by actual code or reflection.

Keep `__init__.py` light. Re-export an intentional stable API explicitly; do not
start servers, read mandatory secrets, mutate global logging configuration or
open network connections on import. Imports should permit tooling and isolated
unit tests without a live deployment environment.

## Installing the application is a boundary

The distribution name used by pip may differ from the import package name.
`src/` separates importable code from the checkout root. Development normally
requires installation; do not routinely patch `sys.path` or `PYTHONPATH` to make
broken package discovery disappear.

An editable install points back to development sources. It does **not** test the
same artifact layout as a regular wheel installation. Both flat and `src/`
layouts can be packaged correctly; choose the established project convention.
See [PyPA's layout comparison](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/).

Optional recipe for a *new* setuptools-based project; prerequisites are a build
environment with setuptools and the matching `src/stockroom/` package. Preserve
an existing backend rather than adding a second one. This metadata is a compact
packaging example, not a lockfile or application implementation:

```toml
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[project]
name = "stockroom-tool"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[project.scripts]
stockroom = "stockroom.cli:main"

[tool.setuptools.packages.find]
where = ["src"]
```

The `stockroom.cli:main` entry point must exist, take no required arguments and
return an exit status or `None`. Parse arguments there, not while importing the
module. If supporting `python -m stockroom`, add a thin `__main__.py` delegating
to that same function. Package templates/data explicitly through the selected
backend and access read-only resources with `importlib.resources`, not paths
relative to the working directory. Writable state belongs outside the installed
package in a configured data directory.

Development recipe, run from the consumer project's checkout, not this skill:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -e .
```

Use the project's existing dependency lock workflow. Declared library dependency
ranges express compatibility; resolved application dependencies record an exact
environment. `pip freeze` records installed distributions, not original dependency
intent, platform universality or a complete reproducible build policy. Record the
interpreter, platform and build requirements too. Avoid global/sudo pip installs.

Release smoke procedure (optional build tooling, not executed documentation):

1. Build with the existing backend, e.g. `python -m build` when the `build` frontend
   is available. Pin/resolve build tooling under the project's own policy.
2. Create a fresh environment and install the **exact** resulting wheel with its
   resolved runtime dependencies, not `-e .` and not an ambiguous `dist/*.whl`.
3. From a temporary directory outside the checkout, invoke the installed command
   and import package, verify help/error exit codes and read a packaged resource.
4. Run the relevant contract tests against that installed artifact. Do not add
   `src/` to the path. This catches omitted modules/resources and entry points.

Primary packaging references: [pyproject metadata](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/)
and [pip editable versus regular installs](https://pip.pypa.io/en/stable/topics/local-project-installs/).

## When a service boundary is justified

Document the independent need: a security trust boundary, independently operated
capability, distinct scaling constraint, or release ownership. A different team
name or large module is not alone a reason to add network hops. A job worker can
be a separate process using the same package and database without becoming an
independently owned microservice.

Before splitting, name:

- Data ownership: which service writes each invariant-bearing record? Avoid two
  services silently sharing write ownership of the same tables.
- Protocol: request/message schema, authentication, authorization, versioning,
  timeouts, payload bounds, duplicate handling and correlation identifiers.
- Failure: how a caller represents unknown outcomes and partial completion;
  which effects are retried, reconciled or explicitly compensated.
- Operations: deployments, migrations, credentials, health signals, queue limits,
  recovery and who is paged when the remote dependency is unavailable.

A local transaction does not cross an HTTP boundary. If two changes must remain
atomic, keeping them inside one database transaction is often the simpler design.
Only introduce outboxes, sagas or compensating operations for an actual required
distributed workflow, not as a checklist for a modular monolith.

## Make tests follow the boundary

Test pure rules with plain values. Test operation orchestration through its real
session/store where constraints and transactions matter. HTTP adapter tests check
status, schema, authentication and authorization without duplicating every rule
case. Installed-package tests check deployment artifacts separately from source
unit tests. Test seams can be ordinary arguments and temporary resources; do not
create production layers solely to make every assertion a mock call count.

Name what a substitute cannot establish: a fake repository cannot prove SQL
uniqueness, a direct function call cannot prove worker importability, and a wheel
import cannot prove live service compatibility. See the two companion references
for concrete runtime and persistence contracts.
