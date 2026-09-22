// put.go — DB.Put: idempotent bulk insert into the v2 audit schema, one transaction per call.
// Exists so the orchestrator's single-writer flushes can land row events without re-implementing ID assignment + ON CONFLICT idempotency per session.
// How: validates table/column identifiers against an allowlist + per-table write policy, opens a tx, assigns missing `id` via nextval('seq_<table>') (T3-08, no more COALESCE(MAX(id))+1), fills content_fingerprint, content-checks dedup on ON CONFLICT, builds parameterised INSERT … ON CONFLICT DO NOTHING; called from vrdb_test.go and cmd/vrdb.

package vrdb

import (
	"context"
	"database/sql"
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// allowedTables enumerates the audit tables the harness can write to.
// Anything outside this set is rejected; callers needing a new table must extend the set + schema.sql together.
// NOTE on exclusions: text-PK / no-`id` maintenance + config tables are
// DELIBERATELY excluded from this allowlist. `schema_version` (PK=version),
// `run_config` (PK=key), `sp_factor_config` (PK=factor_name) carry no `id`
// column, so the COALESCE(MAX(id),0)+1 auto-assign would inject a NULL/extra
// `id` and NOT-NULL- or column-fail at insert. They are seeded by schema.sql
// (INSERT … ON CONFLICT DO NOTHING) and must never be written through Put.
var allowedTables = map[string]struct{}{
	"targets":                         {},
	"sources":                         {},
	"sinks":                           {},
	"defenses":                        {},
	"strategies":                      {},
	"input_slices":                    {},
	"intended_feature_classification": {},
	"agent_steps":                     {},
	"phase0_priorities":               {},
	"gr_findings":                     {},
	"refutations":                     {},
	"audit_outcomes":                  {},
	"critic_findings":                 {},
	"defense_bypasses":                {},
	"knowledge_chunks":                {},
	"knowledge_seed_log":              {},
	"knowledge_acceptance":            {},
	// schema v2 — critical-function registry, forward data-flow, rich logging.
	"critical_functions": {},
	"critical_fn_reach":  {},
	"agent_observations": {},
	"round_ledger":       {},
	// Phase 1.5 fuzzing lane (Tier 3 dynamic discovery).
	"fuzz_runs": {},
	// Phase 1.5 fuzzing lane — per-artifact (seed/corpus/crash-reproducer) rows.
	// id-bearing (PK=id); real write target, previously missing from the allowlist.
	"fuzz_artifacts": {},
	// File-level vuln rating / attention ranking (migration 0012). id-bearing
	// (PK=id); real write target, previously missing from the allowlist.
	"file_vuln_ratings": {},
	// Phase 0.75 HTML sanitizer bypass lane (migration 0009) — per-sanitizer-run aggregate.
	"sanitizer_bypass_runs": {},
	// Suspicious Point screening tier (migration 0010). sp_factor_config is seeded by
	// the schema (no `id` column — its PK is factor_name), so it is NOT in the writable
	// allowlist; only the two id-bearing row-event tables are flushed by the orchestrator.
	"suspicious_points":       {},
	"suspicious_point_factor": {},
	// LLMxCPG CPGQL query-generation feedback loop (migration 0015) — one row per
	// bounded query attempt (generate->run->feedback->retry≤3->dead_end).
	"query_attempts": {},
	// Slice-end CODEBASE coverage (migration 0017) — one row per (target, round)
	// from the non-mandatory cpg_coverage step (union-of-slices vs raw + frontier
	// denominators). id-bearing real write target.
	"cpg_slice_coverage": {},
	// Phase 1.6 post-Hunt methodology blind-spot sweep (migration 0018) — the merged,
	// union-deduped output of methodology_blindspot_lane_a/_b (gap_class process|coverage).
	// id-bearing real write target; feeds the NEXT round.
	"methodology_blind_spots": {},
	// Promising-lane feed-forward (migration 0025) — opportunistic static-analysis lead
	// surfaced by any DuckDB-backed static lane; persists as a ranked candidate direction
	// the NEXT round picks up first. id-bearing real write target; ON CONFLICT (lane_hash).
	"promising_lanes": {},
	// Prior-art intake (migration 0026) — target-scoped CVE/advisory + writeup inventory
	// mined by prior_art_intake_lane (Phase L-1); distilled into promising_lanes via
	// derived_from_*. id-bearing real write targets. cves must flush before writeups /
	// promising_lanes in a Put batch (cross-table related_cve_id / derived_from_cve_id FKs).
	"cves":     {},
	"writeups": {},
	// Mandatory regex mapping (migration 0027) — whole-tree regex inventory (5th enumerated
	// category) emitted by preliminary_enumeration_lane; defense_id links a defense regex.
	"regexes": {},
	// Eval harness (Tier 1 measurement) — complementary benchmarking.
	"eval_corpus": {},
	"eval_run":    {},
	// eval_result — id-bearing (PK=id); scope_key/manifest_uid are TEXT (no
	// cross-table id-FK to pre-validate). Previously missing from the allowlist.
	"eval_result": {},
	// Knowledge architecture (migration 0005). recurrence_counter is inserted here
	// for new nodes; its confirmation-weighted accumulation runs as an orchestrator
	// ON CONFLICT DO UPDATE at flush, not through this insert-only path.
	"scoring_config":     {},
	"finding_sightings":  {},
	"call_edges":         {},
	"weakness_classes":   {},
	"recurrence_counter": {},
	"mutation_log":       {},
}

// identRe pins column identifiers to a conservative ASCII subset; rejects anything that
// would let a caller smuggle SQL via a map key.
var identRe = regexp.MustCompile(`^[a-zA-Z_][a-zA-Z0-9_]*$`)

// fkRef describes a single cross-table foreign-key column.
type fkRef struct{ col, parentTable, parentCol string }

// fkRefs maps each writable table to its cross-table foreign keys.
// Self-referential FKs (e.g. agent_steps.parent_step_id → agent_steps,
// defense_bypasses.carried_from_bypass_id → defense_bypasses,
// finding_sightings.changed_from_sighting_id → finding_sightings,
// round_ledger.parent_round_id → round_ledger) are intentionally excluded to
// avoid false positives when parents and children land in the same Put batch.
var fkRefs = map[string][]fkRef{
	"round_ledger": {
		{"target_id", "targets", "id"},
	},
	"sources": {
		{"target_id", "targets", "id"},
	},
	"sinks": {
		{"target_id", "targets", "id"},
	},
	"defenses": {
		{"target_id", "targets", "id"},
	},
	"critical_functions": {
		{"target_id", "targets", "id"},
		{"sink_id", "sinks", "id"},
		{"defense_id", "defenses", "id"},
	},
	"input_slices": {
		{"target_id", "targets", "id"},
		{"source_id", "sources", "id"},
		{"critical_fn_id", "critical_functions", "id"},
	},
	"critical_fn_reach": {
		{"critical_fn_id", "critical_functions", "id"},
		{"source_id", "sources", "id"},
		{"slice_id", "input_slices", "id"},
	},
	"intended_feature_classification": {
		{"sink_id", "sinks", "id"},
	},
	"agent_steps": {
		{"target_id", "targets", "id"},
		{"strategy_id", "strategies", "id"},
		{"slice_id", "input_slices", "id"},
		{"defense_id", "defenses", "id"},
		{"round_id", "round_ledger", "id"},
		// parent_step_id → agent_steps(id) is SELF-REF; excluded.
	},
	"agent_observations": {
		{"target_id", "targets", "id"},
		{"agent_step_id", "agent_steps", "id"},
	},
	"phase0_priorities": {
		{"target_id", "targets", "id"},
	},
	"gr_findings": {
		{"target_id", "targets", "id"},
		{"sink_id", "sinks", "id"},
		{"source_id", "sources", "id"},
		{"defense_id", "defenses", "id"},
		{"agent_step_id", "agent_steps", "id"},
	},
	"refutations": {
		{"finding_id", "gr_findings", "id"},
		{"agent_step_id", "agent_steps", "id"},
	},
	"audit_outcomes": {
		{"target_id", "targets", "id"},
		{"finding_id", "gr_findings", "id"},
	},
	"critic_findings": {
		{"finding_id", "gr_findings", "id"},
	},
	"defense_bypasses": {
		{"defense_id", "defenses", "id"},
		{"agent_step_id", "agent_steps", "id"},
		{"sink_reach_finding_id", "gr_findings", "id"},
		{"round_id", "round_ledger", "id"},
		// carried_from_bypass_id → defense_bypasses(id) is SELF-REF; excluded.
	},
	"fuzz_runs": {
		{"target_id", "targets", "id"},
		{"agent_step_id", "agent_steps", "id"},
		{"round_id", "round_ledger", "id"},
	},
	"sanitizer_bypass_runs": {
		{"target_id", "targets", "id"},
		{"defense_id", "defenses", "id"},
		{"agent_step_id", "agent_steps", "id"},
		{"round_id", "round_ledger", "id"},
	},
	"fuzz_artifacts": {
		{"target_id", "targets", "id"},
		{"fuzz_run_id", "fuzz_runs", "id"},
		{"agent_step_id", "agent_steps", "id"},
		{"round_id", "round_ledger", "id"},
	},
	"file_vuln_ratings": {
		{"target_id", "targets", "id"},
		{"round_id", "round_ledger", "id"},
		{"agent_step_id", "agent_steps", "id"},
	},
	"suspicious_points": {
		{"target_id", "targets", "id"},
		{"round_id", "round_ledger", "id"},
		{"agent_step_id", "agent_steps", "id"},
		{"graduated_finding_id", "gr_findings", "id"},
	},
	"suspicious_point_factor": {
		{"sp_id", "suspicious_points", "id"},
	},
	"query_attempts": {
		{"target_id", "targets", "id"},
		{"agent_step_id", "agent_steps", "id"},
		{"slice_id", "input_slices", "id"},
	},
	"cpg_slice_coverage": {
		{"target_id", "targets", "id"},
		{"round_id", "round_ledger", "id"},
		{"agent_step_id", "agent_steps", "id"},
	},
	"methodology_blind_spots": {
		{"target_id", "targets", "id"},
		{"round_id", "round_ledger", "id"},
		{"agent_step_id", "agent_steps", "id"},
		{"promoted_to_round_id", "round_ledger", "id"},
	},
	"promising_lanes": {
		{"target_id", "targets", "id"},
		{"round_id", "round_ledger", "id"},
		{"agent_step_id", "agent_steps", "id"},
		{"overlaps_sp_id", "suspicious_points", "id"},
		{"overlaps_finding_id", "gr_findings", "id"},
		{"promoted_to_round_id", "round_ledger", "id"},
		// prior-art provenance (migration 0026; nullable — sentinel-skip handles unset)
		{"derived_from_cve_id", "cves", "id"},
		{"derived_from_writeup_id", "writeups", "id"},
	},
	// Prior-art intake (migration 0026).
	"cves": {
		{"target_id", "targets", "id"},
	},
	"writeups": {
		{"target_id", "targets", "id"},
		{"related_cve_id", "cves", "id"},
	},
	// Mandatory regex mapping (migration 0027).
	"regexes": {
		{"target_id", "targets", "id"},
		{"defense_id", "defenses", "id"},
	},
	"knowledge_seed_log": {
		{"agent_step_id", "agent_steps", "id"},
		{"chunk_id", "knowledge_chunks", "id"},
	},
	"knowledge_acceptance": {
		{"chunk_id", "knowledge_chunks", "id"},
	},
	"eval_run": {
		{"corpus_id", "eval_corpus", "id"},
	},
	"finding_sightings": {
		{"finding_hash", "gr_findings", "finding_hash"},
		{"target_id", "targets", "id"},
		{"agent_step_id", "agent_steps", "id"},
		// changed_from_sighting_id → finding_sightings(id) is SELF-REF; excluded.
	},
	"call_edges": {
		{"target_id", "targets", "id"},
	},
	"weakness_classes": {
		{"target_id", "targets", "id"},
	},
	"recurrence_counter": {
		{"target_id", "targets", "id"},
	},
	"mutation_log": {
		{"target_id", "targets", "id"},
		{"round_id", "round_ledger", "id"},
		{"agent_step_id", "agent_steps", "id"},
	},
}

// PutResult reports the per-batch outcome of a counted Put.
//
// Output contract (the source of truth for the CLI summary line):
//   - Inserted: rows that landed as new rows (INSERT affected 1 row).
//   - Skipped:  rows that hit ON CONFLICT DO NOTHING (already present, 0 rows
//     affected). This is a SUCCESS, not an error — it is the idempotent replay path.
//   - Errors:   always 0 on a successful return. Any real row error aborts the
//     whole batch (tx rollback) and is returned as a non-nil error instead; the
//     caller must NOT emit a summary line in that case.
//
// Invariant: on success, Inserted + Skipped == len(input rows).
type PutResult struct {
	Inserted int64 `json:"inserted"`
	Skipped  int64 `json:"skipped"`
	Errors   int64 `json:"errors"`
}

// AllowedTables returns a copy of the write-target table names, sorted, for
// introspection (selftest). The returned slice is independent of the internal map.
func AllowedTables() []string {
	out := make([]string, 0, len(allowedTables))
	for t := range allowedTables {
		out = append(out, t)
	}
	sort.Strings(out)
	return out
}

// FKRef is the exported view of a single cross-table foreign key (col → parentTable.parentCol).
type FKRef struct{ Col, ParentTable, ParentCol string }

// FKRefsFor returns the cross-table foreign keys declared for table, for selftest introspection.
func FKRefsFor(table string) []FKRef {
	refs := fkRefs[table]
	out := make([]FKRef, 0, len(refs))
	for _, r := range refs {
		out = append(out, FKRef{r.col, r.parentTable, r.parentCol})
	}
	return out
}

// SchemaSQL returns the embedded canonical schema, for selftest assertions.
func SchemaSQL() string { return schemaSQL }

// Put inserts rows into a v2 schema table inside a single transaction.
// Thin wrapper over PutCounts that discards the counts; preserves the original
// signature for existing callers. New callers that need the inserted/skipped
// breakdown (e.g. the CLI summary line) should call PutCounts.
func (d *DB) Put(ctx context.Context, table string, rows []map[string]any) error {
	_, err := d.PutCounts(ctx, table, rows)
	return err
}

// PutCounts inserts rows into a v2 schema table inside a single transaction and
// returns a PutResult breakdown (see PutResult for the output contract).
//
// Each row is a column → value map; missing `id` is assigned via nextval('seq_<table>')
// (T3-08 / S-D04 — the old COALESCE(MAX(id),0)+1 read had a concurrent-reader race that
// silently DROPPED rows under ON CONFLICT DO NOTHING; the sequence assigns ids atomically
// and gives each table its own id-space). Idempotent: ON CONFLICT DO NOTHING means replaying
// the same row (same natural key) is a no-op (counted as Skipped) rather than a duplicate
// error. Any row error rolls back the entire batch.
//
// PutCounts also enforces the WRITE CONTRACT the schema cannot (no triggers in DuckDB v1.1.3):
//   - born-confirmed LOCKOUT (T3-02): a gr_findings row whose incoming confirmation_status is
//     'confirmed'/'refuted' is REJECTED — only 'candidate'/'unconfirmed' may be Put; promotion
//     is exclusively via the `vrdb promote` verb;
//   - per-table enum/required-column POLICY (T3-05);
//   - content-checked DEDUP (T3-04): each fingerprinted table's row gets a content_fingerprint;
//     on an ON CONFLICT against the dedup key, an incoming fingerprint that DIFFERS from the
//     stored one REJECTS the batch ("hash collision: weak discriminator") instead of silently
//     dropping a distinct bug.
func (d *DB) PutCounts(ctx context.Context, table string, rows []map[string]any) (PutResult, error) {
	var res PutResult
	if _, ok := allowedTables[table]; !ok {
		return res, fmt.Errorf("vrdb: Put: table %q not in allowlist", table)
	}
	if len(rows) == 0 {
		return res, nil
	}

	tx, err := d.sql.BeginTx(ctx, nil)
	if err != nil {
		return res, fmt.Errorf("vrdb: Put: begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	dedupCol := dedupKeyColumn[table]

	for i, row := range rows {
		// --- WRITE POLICY: enum allowlist + born-confirmed lockout (T3-02, T3-05) -----
		for col, val := range row {
			if ok, allowed := enumAllowed(table, col, val); !ok {
				if table == "gr_findings" && col == "confirmation_status" {
					return res, fmt.Errorf(
						"vrdb: Put: born-confirmed lockout: %s.%s=%v is forbidden via Put "+
							"(only %v may be Put; promote to 'confirmed' via the `vrdb promote` verb)",
						table, col, val, allowed)
				}
				return res, fmt.Errorf(
					"vrdb: Put: write policy: %s.%s=%v not in allowed values %v",
					table, col, val, allowed)
			}
		}
		for _, rc := range putRequiredColumns[table] {
			v, present := row[rc]
			if !present || v == nil || v == "" {
				return res, fmt.Errorf("vrdb: Put: write policy: %s requires non-empty column %q", table, rc)
			}
		}

		// --- content_fingerprint: fill it if this table carries the column and the
		// caller did not supply one, so the content-checked dedup path has something to
		// compare (T3-04 / T2-13). ---
		if dedupCol != "" {
			if _, has := row["content_fingerprint"]; !has {
				row["content_fingerprint"] = ContentFingerprint(row)
			}
		}

		// --- id assignment via the per-table sequence (T3-08) ---
		if _, hasID := row["id"]; !hasID {
			if !identRe.MatchString(table) {
				return res, fmt.Errorf("vrdb: Put: invalid table identifier %q", table)
			}
			var nextID int64
			if err := tx.QueryRowContext(ctx, fmt.Sprintf("SELECT nextval('seq_%s')", table)).Scan(&nextID); err != nil {
				return res, fmt.Errorf("vrdb: Put: assign id for row %d (nextval seq_%s): %w", i, table, err)
			}
			row["id"] = nextID
		}

		// --- content-checked dedup pre-flight (T3-04 / S-D07): if a row with the same
		// dedup key already exists, compare the SHARED semantic columns. A field that
		// CONTRADICTS the stored value means two genuinely-distinct rows collided on a
		// weak hash (the "3 crashes → 1 row" over-dedup) — REJECT the batch rather than
		// silently ON CONFLICT DO NOTHING. A partial idempotent REPLAY (a subset of the
		// stored columns, all matching) is NOT a contradiction and is allowed. ---
		if dedupCol != "" {
			if dkVal, ok := row[dedupCol]; ok && dkVal != nil {
				if !identRe.MatchString(dedupCol) {
					return res, fmt.Errorf("vrdb: Put: invalid dedup-key column %q", dedupCol)
				}
				if col, incoming, stored, conflict, err := dedupConflict(ctx, tx, table, dedupCol, dkVal, row); err != nil {
					return res, err
				} else if conflict {
					return res, fmt.Errorf(
						"vrdb: Put: hash collision: weak discriminator — row %d %s.%s=%v matches an "+
							"existing row with a DIFFERENT %s (incoming %v != stored %v); "+
							"the dedup key is too weak to distinguish these rows",
						i, table, dedupCol, dkVal, col, incoming, stored)
				}
			}
		}

		// FK pre-validation: fail fast with a clear message when a cross-table FK
		// value references a non-existent parent row, so the caller learns the
		// id-space mismatch at Put time rather than as a cryptic DuckDB FK error.
		if refs, ok := fkRefs[table]; ok {
			for _, fk := range refs {
				val, present := row[fk.col]
				if !present || val == nil {
					continue // column absent or SQL NULL — treat as unset
				}
				// Sentinel skip: integer 0 and empty string are "unset" markers;
				// real FK targets start at 1.
				switch v := val.(type) {
				case int:
					if v == 0 {
						continue
					}
				case int32:
					if v == 0 {
						continue
					}
				case int64:
					if v == 0 {
						continue
					}
				case float64:
					if v == 0 {
						continue
					}
				case string:
					if v == "" {
						continue
					}
				}
				// parentTable and parentCol come from the trusted static map; still
				// run them through identRe for belt-and-suspenders consistency.
				if !identRe.MatchString(fk.parentTable) || !identRe.MatchString(fk.parentCol) {
					return res, fmt.Errorf("vrdb: Put: fkRefs entry has invalid identifier (%s.%s)", fk.parentTable, fk.parentCol)
				}
				checkSQL := fmt.Sprintf("SELECT 1 FROM %s WHERE %s = ? LIMIT 1", fk.parentTable, fk.parentCol)
				var exists int
				scanErr := tx.QueryRowContext(ctx, checkSQL, val).Scan(&exists)
				if scanErr == sql.ErrNoRows {
					return res, fmt.Errorf("Put: %s.%s=%v references missing %s.%s (FK id-space mismatch)",
						table, fk.col, val, fk.parentTable, fk.parentCol)
				}
				if scanErr != nil {
					return res, fmt.Errorf("vrdb: Put: FK check %s.%s: %w", table, fk.col, scanErr)
				}
			}
		}

		cols := make([]string, 0, len(row))
		for k := range row {
			if !identRe.MatchString(k) {
				return res, fmt.Errorf("vrdb: Put: invalid column identifier %q", k)
			}
			cols = append(cols, k)
		}
		sort.Strings(cols)

		placeholders := make([]string, len(cols))
		values := make([]any, len(cols))
		for j, c := range cols {
			placeholders[j] = "?"
			values[j] = row[c]
		}

		stmt := fmt.Sprintf(
			"INSERT INTO %s (%s) VALUES (%s) ON CONFLICT DO NOTHING",
			table,
			strings.Join(cols, ", "),
			strings.Join(placeholders, ", "),
		)
		sqlRes, err := tx.ExecContext(ctx, stmt, values...)
		if err != nil {
			return res, fmt.Errorf("vrdb: Put: insert row %d into %s: %w", i, table, err)
		}
		// rows_affected distinguishes a real insert (1) from an ON CONFLICT
		// DO NOTHING no-op (0). The latter is an idempotent-replay SUCCESS,
		// counted as Skipped — never an error.
		affected, raErr := sqlRes.RowsAffected()
		if raErr != nil || affected > 0 {
			// If the driver can't report the count, assume the insert landed
			// rather than silently undercounting (the row error path already
			// aborted above on a genuine failure).
			res.Inserted++
		} else {
			res.Skipped++
		}
	}

	if err := tx.Commit(); err != nil {
		return res, fmt.Errorf("vrdb: Put: commit: %w", err)
	}
	return res, nil
}

// dedupConflict checks an incoming row against the row already stored under the same dedup key.
// It compares only the columns the incoming row CARRIES (excluding id, content_fingerprint, and
// the dedup key itself). A shared column whose stored value CONTRADICTS the incoming value is a
// weak-discriminator collision (conflict=true); a partial replay whose carried columns all match
// is not. Returns (column, incomingVal, storedVal, conflict, err). If no stored row exists,
// conflict is false.
func dedupConflict(ctx context.Context, tx *sql.Tx, table, dedupCol string, dkVal any, row map[string]any) (string, any, any, bool, error) {
	// Build the comparison column list (deterministic order).
	cmpCols := make([]string, 0, len(row))
	for k := range row {
		if k == "id" || k == "content_fingerprint" || k == dedupCol {
			continue
		}
		if _, skip := fingerprintExcludedColumns[k]; skip {
			continue // volatile bookkeeping (timestamps) — not a semantic contradiction
		}
		if !identRe.MatchString(k) {
			return "", nil, nil, false, fmt.Errorf("vrdb: Put: invalid column identifier %q", k)
		}
		cmpCols = append(cmpCols, k)
	}
	if len(cmpCols) == 0 {
		return "", nil, nil, false, nil
	}
	sort.Strings(cmpCols)

	sel := fmt.Sprintf("SELECT %s FROM %s WHERE %s = ? LIMIT 1",
		strings.Join(cmpCols, ", "), table, dedupCol)
	rowsResult, err := tx.QueryContext(ctx, sel, dkVal)
	if err != nil {
		return "", nil, nil, false, fmt.Errorf("vrdb: Put: dedup probe %s.%s: %w", table, dedupCol, err)
	}
	defer rowsResult.Close()
	if !rowsResult.Next() {
		if err := rowsResult.Err(); err != nil {
			return "", nil, nil, false, fmt.Errorf("vrdb: Put: dedup probe %s.%s: %w", table, dedupCol, err)
		}
		return "", nil, nil, false, nil // no stored row — fresh insert, no conflict
	}
	storedVals := make([]any, len(cmpCols))
	ptrs := make([]any, len(cmpCols))
	for i := range storedVals {
		ptrs[i] = &storedVals[i]
	}
	if err := rowsResult.Scan(ptrs...); err != nil {
		return "", nil, nil, false, fmt.Errorf("vrdb: Put: dedup scan %s: %w", table, err)
	}
	for i, c := range cmpCols {
		incoming := row[c]
		stored := storedVals[i]
		if !valuesEqual(incoming, stored) {
			return c, incoming, stored, true, nil
		}
	}
	return "", nil, nil, false, nil
}

// valuesEqual compares an incoming Go value against a DuckDB-scanned value, normalizing the
// numeric/textual representations the driver returns (int64/float64/[]byte/string/bool) so a
// replay that round-trips through the driver still equals its in-memory original. nil == nil.
func valuesEqual(incoming, stored any) bool {
	if incoming == nil && stored == nil {
		return true
	}
	if incoming == nil || stored == nil {
		return false
	}
	return normalizeScalar(incoming) == normalizeScalar(stored)
}

// normalizeScalar renders a scalar into a canonical comparable string. Numbers compare by
// float value (so int64(0) == float64(0) == "0"); everything else compares by its %v string.
func normalizeScalar(v any) string {
	switch n := v.(type) {
	case []byte:
		return string(n)
	case bool:
		if n {
			return "true"
		}
		return "false"
	case int:
		return strconv.FormatFloat(float64(n), 'g', -1, 64)
	case int32:
		return strconv.FormatFloat(float64(n), 'g', -1, 64)
	case int64:
		return strconv.FormatFloat(float64(n), 'g', -1, 64)
	case float32:
		return strconv.FormatFloat(float64(n), 'g', -1, 64)
	case float64:
		return strconv.FormatFloat(n, 'g', -1, 64)
	case string:
		// A numeric-looking string compares as its number so "0" == int64(0).
		if f, err := strconv.ParseFloat(n, 64); err == nil {
			return strconv.FormatFloat(f, 'g', -1, 64)
		}
		return n
	default:
		return fmt.Sprintf("%v", v)
	}
}
