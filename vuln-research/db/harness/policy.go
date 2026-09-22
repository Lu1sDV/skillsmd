// policy.go — per-table WRITE POLICY (T3-05 / S-D12, C23) and the content-dedup key map
// (T3-04 / S-D07).
//
// The old access control was a single table-level allowlist (put.go `allowedTables`): coarse
// allow/deny with no column- or value-awareness. DuckDB v1.1.3 has no triggers, so the harness
// is the ONLY layer that can enforce the column/value/companion-row contract the schema's prose
// describes. This file makes that contract executable:
//
//   - enumPolicy: per-table, per-column closed value sets the harness rejects out-of-vocab
//     writes against BEFORE they reach the DB CHECK (a clearer error, and the only guard for
//     the values DuckDB cannot widen-CHECK on the upgrade path). It also carries the
//     born-confirmed LOCKOUT (T3-02): an incoming gr_findings.confirmation_status may only be
//     'candidate' or 'unconfirmed' — 'confirmed'/'refuted' are reachable ONLY via `vrdb promote`.
//
//   - dedupKeyColumn: the single hash column that backs each content-fingerprinted table's
//     UNIQUE natural key, so the content-checked-dedup path (put.go) can locate the conflicting
//     stored row and compare fingerprints.

package vrdb

// putEnumPolicy maps table → column → the closed set of values Put accepts for that column.
// A column absent from the inner map is unconstrained by the harness (the DB CHECK, if any,
// still applies). Only columns where the harness adds value beyond the DB CHECK are listed:
// principally the born-confirmed lockout on gr_findings.confirmation_status.
//
// NOTE: this is deliberately a SUBSET of the schema CHECK enums — it is a write-time POLICY
// (what a Put may carry), not a mirror of every CHECK. The born-confirmed lockout is the load-
// bearing entry: it is STRICTER than the DB CHECK (the CHECK allows 'confirmed', the policy
// does not) because 'confirmed' must flow exclusively through the promote verb.
var putEnumPolicy = map[string]map[string][]string{
	"gr_findings": {
		// LOCKOUT: only candidate/unconfirmed may be Put. confirmed/refuted are set
		// exclusively by the promote/refute transactional verbs (T3-01/T3-02).
		"confirmation_status": {"candidate", "unconfirmed"},
	},
}

// putRequiredColumns maps table → columns that MUST be present and non-empty in every Put row
// (a required-companion / NOT-NULL-business-key check beyond the schema's structural NOT NULL).
// Empty for now; the verbs (promote/close-step) carry the companion-row requirements that are
// transactional rather than per-row.
var putRequiredColumns = map[string][]string{}

// dedupKeyColumn maps each content-fingerprinted table to the single hash column that backs its
// UNIQUE dedup natural key. On an ON CONFLICT, the harness looks up the stored row by this
// column and compares content_fingerprint values (T3-04). Tables whose only NK is composite
// (no single hash column) are omitted — their dedup remains plain ON CONFLICT DO NOTHING.
var dedupKeyColumn = map[string]string{
	"gr_findings":             "finding_hash",
	"agent_observations":      "obs_hash",
	"critical_functions":      "cf_hash",
	"promising_lanes":         "lane_hash",
	"fuzz_runs":               "fuzz_run_hash",
	"defense_bypasses":        "bypass_hash",
	"methodology_blind_spots": "blindspot_hash",
	"query_attempts":          "attempt_hash",
	"cpg_slice_coverage":      "coverage_hash",
	"agent_steps":             "step_hash",
	"finding_sightings":       "sighting_hash",
	"call_edges":              "edge_hash",
	"weakness_classes":        "wc_hash",
	"sanitizer_bypass_runs":   "sanitizer_run_hash",
	"critical_fn_reach":       "reach_hash",
	"impact_proofs":           "proof_hash",
	"mutation_log":            "mutation_hash",
	"suspicious_points":       "region_hash",
}

// enumAllowed reports whether value v is permitted for (table, col) under putEnumPolicy.
// A column with no policy entry is always allowed. Non-string values are allowed (the policy
// only constrains string enums); a nil value is allowed (NULL).
func enumAllowed(table, col string, v any) (ok bool, allowed []string) {
	tp, hasTable := putEnumPolicy[table]
	if !hasTable {
		return true, nil
	}
	vals, hasCol := tp[col]
	if !hasCol {
		return true, nil
	}
	s, isStr := v.(string)
	if !isStr {
		// non-string (incl. nil) is not an enum violation the policy can judge.
		return true, vals
	}
	for _, a := range vals {
		if a == s {
			return true, vals
		}
	}
	return false, vals
}
