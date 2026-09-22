# vrdb harness — operational notes

Reliability notes for the `vrdb` Go harness (single-writer DuckDB put/fetch layer).
These document contracts that recent runs proved load-bearing after real data-loss
incidents (false "inserted 0/N" success reporting, allowlist rejections, NOT-NULL-on-id
insert failures, and DuckDB FK-UPDATE breakage).

## Pinned DuckDB engine version

This tree pins **DuckDB v1.1.3** (via `github.com/marcboeker/go-duckdb v1.8.5`).
Confirmed at runtime with `SELECT version()` → `v1.1.3`. The FK-UPDATE bug below is
specific to this engine line.

## `vrdb put` OUTPUT CONTRACT

On **success**, `vrdb put TABLE --db PATH` emits **exactly one** machine-readable JSON
summary line to stdout:

```json
{"table":"<t>","inserted":N,"skipped":M,"errors":K}
```

- `inserted` — rows that landed as **new** rows (INSERT affected 1 row).
- `skipped`  — rows that hit `ON CONFLICT DO NOTHING` (already present, 0 rows
  affected). **This is a SUCCESS**, the idempotent-replay path — not an error.
- `errors`   — **always 0** on a successful return.
- **Invariant:** `inserted + skipped == len(input rows)`.

On **any row error**, the **whole batch is rolled back** (single transaction),
the process **exits non-zero**, the error is written to **stderr**, and **NO summary
line is printed**. Callers must treat the absence of a summary line (or non-zero exit)
as a hard failure, never as "inserted 0".

This kills the previous false "inserted 0/N" success reporting: a batch that was
entirely skipped now reports `skipped=M` (success), and a batch that errored now
prints nothing on stdout and exits non-zero.

### Go API

- `DB.PutCounts(ctx, table, rows) (PutResult, error)` — counted variant; returns the
  `{Inserted, Skipped, Errors}` breakdown that backs the CLI summary line.
- `DB.Put(ctx, table, rows) error` — thin wrapper over `PutCounts` that discards the
  counts; preserves the original signature for existing callers.

## Allowlist / fkRefs invariants

- Every write-target table must be in `allowedTables` **and** must have an `id`
  column (the `COALESCE(MAX(id),0)+1` auto-assign only covers an `id`).
- **Deliberately excluded:** text-PK / no-`id` maintenance + config tables that the
  schema seeds itself and an agent must never insert through `Put`:
  - `schema_version` (PK = `version`) — would NOT-NULL/extra-column-fail on id auto-assign.
  - `run_config` (PK = `key`), `sp_factor_config` (PK = `factor_name`) — schema-seeded config.
- Tables added in this pass (id-bearing real write targets that were missing):
  `fuzz_artifacts`, `file_vuln_ratings` (plus matching `fkRefs`). `eval_result` was
  already present and is documented inline.

## `vrdb selftest` (alias `vrdb doctor`)

Asserts PASS/FAIL against the **embedded** schema and exits non-zero on any FAIL.
Runs against a throwaway temp DB (never touches a real audit file). Checks:

- **(a)** every allowlist table exists in the schema.
- **(b)** every `fkRefs` target `(parentTable, parentCol)` exists as a real column.
- **(c)** every write-target has an `id` column, so the NOT-NULL id is covered by
  the id auto-assign (a text-PK table would have failed allowlisting).
- **(d)** the put summary round-trips: fresh insert → `inserted=1`; immediate
  re-insert of the same row → `skipped=1`.

Run it in CI / before a swarm to catch allowlist↔schema drift early.

## DuckDB v1.1.3 ART-index FK-UPDATE bug + workaround

**Bug:** On DuckDB **v1.1.3**, an `UPDATE` that touches a column participating in a
foreign-key relationship (either a referencing FK column or a referenced PK/UNIQUE
column backed by an ART index) can fail or corrupt the ART index — manifesting as
spurious constraint violations or "Conflict on tuple" / index errors during status
transitions that rewrite FK columns. This bit status-transition UPDATEs that re-point
FK columns.

**Workarounds (in order of preference):**

1. **Don't UPDATE FK columns at all.** Status transitions in this harness are modeled
   as UPDATEs of **non-FK** columns (e.g. a `status` text column) returning
   `rows_affected`, never as a re-point of an `id`/FK column. Keep it that way — never
   re-insert and never rewrite an FK column to "move" a row.
2. **Use a newer DuckDB.** The ART/FK update path is fixed in later engines — use the
   **Python `duckdb` package ≥ 1.5.2** for any out-of-band maintenance script that must
   update FK columns.
3. **Delete-and-reinsert** for an unavoidable FK-column change: within one transaction
   (`vrdb exec` is single-statement, so script the two statements via the Python driver
   or two sequential `exec` calls guarded by the single-writer), `DELETE` the row then
   `INSERT` the new version with the corrected FK value, rather than `UPDATE`-ing the
   FK column in place.

**Rule of thumb:** treat FK/PK columns as immutable after insert. New state = new row
(idempotent via `ON CONFLICT DO NOTHING`) or a non-FK-column UPDATE; never an in-place
FK rewrite on v1.1.3.
