// verbs.go — transactional harness verbs that make the prose write-contract executable
// (DuckDB v1.1.3 has no triggers, so these are the ONLY enforcement point):
//
//   - Promote   (T3-01 / S-D02, S-D12, C21): the ONLY path to confirmation_status='confirmed'.
//   - CloseStep (T3-03 / S-D06, C26): flush observations + flip a step terminal in one tx,
//                rejecting the close of a required DEEP lane that carries zero
//                dead_end/invariant/blind_spot observations.
//   - Gate      (T3-09 / S-P08): one boolean read from the DB (all gate views ANDed).
//   - Selftest  (T3-10 / S-D12, F36): data-quality asserts + vendored-≥-min_skill_version warn.

package vrdb

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"fmt"
	"sort"
	"strings"
	"time"
)

// PromoteOpts carries the promotion inputs the verb stamps onto the confirmed row.
type PromoteOpts struct {
	// Severity is the computed security rating set at promotion. Required, one of
	// LOW/MEDIUM/HIGH/CRITICAL (the closed gr_findings.severity vocab).
	Severity string
	// RigorTier stamps how strongly the confirmation was tested (T2-12 / S-P12):
	// shallow | independent | reproduced. Required.
	RigorTier string
	// RoundID/AgentStepID/Phase are optional provenance written into the mutation_log row.
	RoundID     *int64
	AgentStepID *int64
	Phase       string
}

// validSeverities / validRigorTiers mirror the gr_findings CHECK enums the promote verb sets.
var validSeverities = map[string]struct{}{"LOW": {}, "MEDIUM": {}, "HIGH": {}, "CRITICAL": {}}
var validRigorTiers = map[string]struct{}{"shallow": {}, "independent": {}, "reproduced": {}}

// validProvenReachability / validMechanismCap mirror the impact_proofs CHECK enums (NULL allowed).
var validProvenReachability = map[string]struct{}{"proven": {}, "conditional": {}, "unproven": {}}
var validMechanismCap = map[string]struct{}{"dos_only": {}, "leak": {}, "write_what_where": {}, "none": {}}

// severityRank orders the closed severity vocab so promote can enforce the mechanism_cap ceiling.
var severityRank = map[string]int{"LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}

// mechanismCapCeiling is the MAX severity a given mechanism_cap permits (MED-4: the cap only
// LOWERS — a hardened-allocator/bounds-checked memory-unsafety primitive cannot exceed DoS, so
// its severity ceiling is MEDIUM). 'leak'/'write_what_where'/'none' impose no harness ceiling
// (the Confirm agent derives the exact rating from the rubric). dos_only caps at MEDIUM because a
// pure availability primitive on the deployed surface is not a HIGH/CRITICAL by mechanism alone.
var mechanismCapCeiling = map[string]string{"dos_only": "MEDIUM"}

// ImpactProofOpts carries the CONSUMER-HARM proof the Gate-5 write-twin records for a finding.
// This is the impact_proofs row (T2-07): the named default-config component that reads/dispatches/
// trusts the tainted value + the harm it suffers, plus the reachability + mechanism_cap factors
// the Confirm agent derives severity from. ConsumerSymbol and HarmClass are required; the rest are
// optional but ProvenReachability/MechanismCap, when set, must be in the closed CHECK vocab.
type ImpactProofOpts struct {
	ConsumerSymbol      string // the default-config component harmed (required)
	HarmClass           string // open vocab: rce|info_leak|dos|authz_bypass|ssrf|... (required)
	ReachabilityEvidRef string // pointer proving the consumer is reachable under default config
	ProvenReachability  string // closed: proven|conditional|unproven ("" => NULL)
	MechanismCap        string // closed: dos_only|leak|write_what_where|none ("" => NULL)
	SeverityBasis       string // free-TEXT: how severity was derived from the rubric
}

// ImpactProof writes the impact_proofs row for a finding — the Gate-5 CONSUMER-HARM write (T2-07 /
// S-P02/S-P04). It is the write-twin of v_justification_coverage (UNJUSTIFIED_NO_CONSUMER) and the
// SP-CONDITIONAL v_promotion_coverage: a finding cannot be promoted until this row exists, because
// a sink reached is NOT a consumer harmed (Gate 5 doctrine, T1-02). The row records the named
// default-config consumer + harm_class + the proven_reachability/mechanism_cap factors the Confirm
// agent derives severity from (recorded in severity_basis). Idempotent on proof_hash (one proof per
// finding by default; a re-write with the same content is a no-op).
//
// It does NOT require the finding to be 'confirmed' yet — the documented order is
// impact-proof THEN promote (the proof is a promote precondition), so the row lands while the
// finding is still 'candidate'.
func (d *DB) ImpactProof(ctx context.Context, findingID int64, opts ImpactProofOpts) error {
	if strings.TrimSpace(opts.ConsumerSymbol) == "" {
		return fmt.Errorf("vrdb: impact-proof: --consumer-symbol is required (the default-config component harmed)")
	}
	if strings.TrimSpace(opts.HarmClass) == "" {
		return fmt.Errorf("vrdb: impact-proof: --harm-class is required (rce|info_leak|dos|authz_bypass|ssrf|...)")
	}
	if opts.ProvenReachability != "" {
		if _, ok := validProvenReachability[opts.ProvenReachability]; !ok {
			return fmt.Errorf("vrdb: impact-proof: proven_reachability %q invalid (want proven|conditional|unproven)", opts.ProvenReachability)
		}
	}
	if opts.MechanismCap != "" {
		if _, ok := validMechanismCap[opts.MechanismCap]; !ok {
			return fmt.Errorf("vrdb: impact-proof: mechanism_cap %q invalid (want dos_only|leak|write_what_where|none)", opts.MechanismCap)
		}
	}

	tx, err := d.sql.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("vrdb: impact-proof: begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	// The finding must exist (the proof FK-references it).
	var findingHash string
	err = tx.QueryRowContext(ctx, "SELECT finding_hash FROM gr_findings WHERE id = ?", findingID).Scan(&findingHash)
	if err == sql.ErrNoRows {
		return fmt.Errorf("vrdb: impact-proof: finding id=%d not found", findingID)
	}
	if err != nil {
		return fmt.Errorf("vrdb: impact-proof: read finding: %w", err)
	}

	// Deterministic proof_hash: one proof per (finding, consumer, harm_class). A re-write with the
	// same content is an idempotent no-op (ON CONFLICT DO NOTHING on the proof_hash NK).
	proofHash := sha256Hex(strings.Join([]string{
		"impact_proof", findingHash, opts.ConsumerSymbol, opts.HarmClass,
	}, "\x1f"))

	row := map[string]any{
		"finding_id":      findingID,
		"consumer_symbol": opts.ConsumerSymbol,
		"harm_class":      opts.HarmClass,
		"proof_hash":      proofHash,
	}
	if opts.ReachabilityEvidRef != "" {
		row["reachability_evidence_ref"] = opts.ReachabilityEvidRef
	}
	if opts.ProvenReachability != "" {
		row["proven_reachability"] = opts.ProvenReachability
	}
	if opts.MechanismCap != "" {
		row["mechanism_cap"] = opts.MechanismCap
	}
	if opts.SeverityBasis != "" {
		row["severity_basis"] = opts.SeverityBasis
	}
	row["content_fingerprint"] = ContentFingerprint(row)

	var pid int64
	if err := tx.QueryRowContext(ctx, "SELECT nextval('seq_impact_proofs')").Scan(&pid); err != nil {
		return fmt.Errorf("vrdb: impact-proof: id: %w", err)
	}
	row["id"] = pid

	cols, ph, vals, err := columnsPlaceholders(row)
	if err != nil {
		return fmt.Errorf("vrdb: impact-proof: %w", err)
	}
	if _, err := tx.ExecContext(ctx,
		fmt.Sprintf("INSERT INTO impact_proofs (%s) VALUES (%s) ON CONFLICT DO NOTHING",
			strings.Join(cols, ", "), strings.Join(ph, ", ")), vals...); err != nil {
		return fmt.Errorf("vrdb: impact-proof: insert: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("vrdb: impact-proof: commit: %w", err)
	}
	return nil
}

// Promote is the ONLY path to confirmation_status='confirmed' (T3-01). In one transaction it:
//
//	(1) verifies the finding exists and is currently 'candidate' (the only legal predecessor);
//	(2) verifies ≥1 refutations row exists for it (the refute-before-confirm trail was overcome
//	    — a refutations row pins that an adversarial pass ran and the finding is still standing);
//	(3) verifies a critic_findings(check_kind='eligibility', severity='OK') row exists;
//	(3b) verifies an impact_proofs row exists for it — the Gate-5 CONSUMER-HARM write-twin
//	    (T2-07): a sink reached is NOT a consumer harmed, so promote refuses without the proof
//	    (write it first via the `vrdb impact-proof` verb). If that proof carries a mechanism_cap
//	    with a severity ceiling (dos_only ⇒ MEDIUM), the supplied --severity may not exceed it;
//	(4) sets severity + confirmation_rigor_tier;
//	(5) writes the mutation_log op='status_transition' row (candidate→confirmed) so
//	    v_coverage.confirmed_without_promotion_provenance can prove the flip was in-band;
//	(6) flips confirmation_status to 'confirmed'.
//
// Any failed precondition aborts the whole transaction (the row stays 'candidate'). This is the
// write-side twin of v_promotion_coverage (T2-01) + v_justification_coverage (T2-07): those views
// red-flag an UNJUSTIFIED / consumer-less confirmed row; this verb makes producing one impossible
// through the harness for the conditions it owns (status / refutation / critic / impact_proof).
// The remaining v_promotion_coverage factor (a backing SP's passing oracle) is required ONLY when
// the finding HAS a backing suspicious_point — a non-SP finding (fuzz_crash / L0 / direct Hunt)
// is JUSTIFIED on these conditions alone, so the documented Put→impact-proof→promote→gate
// sequence reaches GREEN.
func (d *DB) Promote(ctx context.Context, findingID int64, opts PromoteOpts) error {
	if _, ok := validSeverities[opts.Severity]; !ok {
		return fmt.Errorf("vrdb: promote: severity %q invalid (want LOW|MEDIUM|HIGH|CRITICAL)", opts.Severity)
	}
	if _, ok := validRigorTiers[opts.RigorTier]; !ok {
		return fmt.Errorf("vrdb: promote: rigor_tier %q invalid (want shallow|independent|reproduced)", opts.RigorTier)
	}

	tx, err := d.sql.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("vrdb: promote: begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	// (1) finding exists and is 'candidate'.
	var status, findingHash string
	var targetID sql.NullInt64
	err = tx.QueryRowContext(ctx,
		"SELECT confirmation_status, finding_hash, target_id FROM gr_findings WHERE id = ?",
		findingID).Scan(&status, &findingHash, &targetID)
	if err == sql.ErrNoRows {
		return fmt.Errorf("vrdb: promote: finding id=%d not found", findingID)
	}
	if err != nil {
		return fmt.Errorf("vrdb: promote: read finding: %w", err)
	}
	if status == "confirmed" {
		return fmt.Errorf("vrdb: promote: finding id=%d is already confirmed", findingID)
	}
	if status != "candidate" {
		return fmt.Errorf("vrdb: promote: finding id=%d has status %q; only 'candidate' may be promoted", findingID, status)
	}

	// (2) refutation overcome.
	var refCount int
	if err := tx.QueryRowContext(ctx,
		"SELECT count(*) FROM refutations WHERE finding_id = ?", findingID).Scan(&refCount); err != nil {
		return fmt.Errorf("vrdb: promote: count refutations: %w", err)
	}
	if refCount == 0 {
		return fmt.Errorf("vrdb: promote: finding id=%d has no refutations row — "+
			"refute-before-confirm mandate: a confirmed finding must have survived ≥1 adversarial refutation pass", findingID)
	}

	// (3) critic eligibility OK.
	var critOK int
	if err := tx.QueryRowContext(ctx,
		"SELECT count(*) FROM critic_findings WHERE finding_id = ? AND check_kind = 'eligibility' AND severity = 'OK'",
		findingID).Scan(&critOK); err != nil {
		return fmt.Errorf("vrdb: promote: count critic eligibility: %w", err)
	}
	if critOK == 0 {
		return fmt.Errorf("vrdb: promote: finding id=%d has no critic_findings(check_kind='eligibility', severity='OK') row — "+
			"the REPORT eligibility critic must pass before promotion", findingID)
	}

	// (3b) CONSUMER-HARM proof present (Gate 5). A sink reached is NOT a consumer harmed, so a
	// finding cannot be promoted until an impact_proofs row names the harmed default-config
	// consumer. Also read the proof's mechanism_cap so the supplied --severity can be ceiling-
	// checked (a cap only LOWERS — e.g. dos_only ⇒ MEDIUM max).
	var proofCount int
	var mechCap sql.NullString
	if err := tx.QueryRowContext(ctx,
		"SELECT count(*), MAX(mechanism_cap) FROM impact_proofs WHERE finding_id = ?",
		findingID).Scan(&proofCount, &mechCap); err != nil {
		return fmt.Errorf("vrdb: promote: read impact_proofs: %w", err)
	}
	if proofCount == 0 {
		return fmt.Errorf("vrdb: promote: finding id=%d has no impact_proofs row — "+
			"Gate 5 consumer-harm mandate: a sink reached is NOT a consumer harmed; "+
			"write the proof first via the `vrdb impact-proof` verb, then promote", findingID)
	}
	if mechCap.Valid {
		if ceil, capped := mechanismCapCeiling[mechCap.String]; capped {
			if severityRank[opts.Severity] > severityRank[ceil] {
				return fmt.Errorf("vrdb: promote: finding id=%d severity %q exceeds the %q mechanism_cap ceiling (%s) "+
					"recorded in its impact_proofs row — the mechanism caps severity; lower --severity or revise the proof",
					findingID, opts.Severity, mechCap.String, ceil)
			}
		}
	}

	// (4)+(6) set severity/rigor + flip status.
	if _, err := tx.ExecContext(ctx,
		"UPDATE gr_findings SET confirmation_status = 'confirmed', severity = ?, confirmation_rigor_tier = ? WHERE id = ?",
		opts.Severity, opts.RigorTier, findingID); err != nil {
		return fmt.Errorf("vrdb: promote: flip status: %w", err)
	}

	// (5) mutation_log status_transition row (the in-band-flip provenance).
	delta := fmt.Sprintf(
		`{"from":"%s","to":"confirmed","severity":"%s","rigor_tier":"%s"}`,
		status, opts.Severity, opts.RigorTier)
	mutHash := sha256Hex(strings.Join([]string{
		"status_transition", "gr_findings", findingHash, "candidate", "confirmed", time.Now().UTC().Format(time.RFC3339Nano),
	}, "\x1f"))
	cols := []string{"table_name", "row_key", "op", "delta_json", "mutation_hash"}
	vals := []any{"gr_findings", findingHash, "status_transition", delta, mutHash}
	if targetID.Valid {
		cols = append(cols, "target_id")
		vals = append(vals, targetID.Int64)
	}
	if opts.RoundID != nil {
		cols = append(cols, "round_id")
		vals = append(vals, *opts.RoundID)
	}
	if opts.AgentStepID != nil {
		cols = append(cols, "agent_step_id")
		vals = append(vals, *opts.AgentStepID)
	}
	if opts.Phase != "" {
		cols = append(cols, "phase")
		vals = append(vals, opts.Phase)
	}
	// id via the sequence (T3-08).
	var mlID int64
	if err := tx.QueryRowContext(ctx, "SELECT nextval('seq_mutation_log')").Scan(&mlID); err != nil {
		return fmt.Errorf("vrdb: promote: mutation_log id: %w", err)
	}
	cols = append(cols, "id")
	vals = append(vals, mlID)
	ph := make([]string, len(cols))
	for i := range ph {
		ph[i] = "?"
	}
	if _, err := tx.ExecContext(ctx,
		fmt.Sprintf("INSERT INTO mutation_log (%s) VALUES (%s)", strings.Join(cols, ", "), strings.Join(ph, ", ")),
		vals...); err != nil {
		return fmt.Errorf("vrdb: promote: write mutation_log: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("vrdb: promote: commit: %w", err)
	}
	return nil
}

// closingObsKinds are the observation kinds that satisfy the close-step "documented something"
// requirement for a required DEEP lane (S-D06): a dead end ruled out, an invariant discovered,
// or a blind spot flagged. A required lane that closes carrying none of these "almost certainly
// under-documented" (db-logging §2) — the verb turns that prose into a write-time refusal.
var closingObsKinds = map[string]struct{}{"dead_end": {}, "invariant": {}, "blind_spot": {}}

// terminalStepStatuses are the legal terminal states a step may be closed into.
var terminalStepStatuses = map[string]struct{}{
	"success": {}, "exhausted": {}, "failed": {}, "timed_out": {}, "skipped": {},
}

// CloseStep flushes observations and flips a step to a terminal status in ONE transaction
// (T3-03 / S-D06). It REJECTS the close of a required DEEP-lane step (a step whose strategy is in
// v_required_deep_lanes) into a non-skipped terminal state when zero accompanying observations
// are dead_end/invariant/blind_spot — moving the "under-documented" detection from post-phase
// (v_observation_coverage, too late) to the point of close. `skipped` is exempt (a documented
// skip legitimately has nothing to observe).
//
// observations is a slice of agent_observations column→value maps (without agent_step_id /
// target_id, which the verb fills from the step). status is the terminal state to flip into.
func (d *DB) CloseStep(ctx context.Context, stepID int64, status string, observations []map[string]any) error {
	if _, ok := terminalStepStatuses[status]; !ok {
		return fmt.Errorf("vrdb: close-step: status %q not terminal (want success|exhausted|failed|timed_out|skipped)", status)
	}

	tx, err := d.sql.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("vrdb: close-step: begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	// Resolve the step: target_id + whether it belongs to a required DEEP lane.
	var targetID int64
	var isRequired bool
	err = tx.QueryRowContext(ctx, `
		SELECT st.target_id,
		       EXISTS (SELECT 1 FROM v_required_deep_lanes r
		               JOIN strategies s ON s.name = r.lane_name
		               WHERE s.id = st.strategy_id) AS is_required
		FROM agent_steps st WHERE st.id = ?`, stepID).Scan(&targetID, &isRequired)
	if err == sql.ErrNoRows {
		return fmt.Errorf("vrdb: close-step: agent_step id=%d not found", stepID)
	}
	if err != nil {
		return fmt.Errorf("vrdb: close-step: read step: %w", err)
	}

	// Count closing observations among the incoming batch.
	closing := 0
	for _, o := range observations {
		if kind, _ := o["obs_kind"].(string); kind != "" {
			if _, ok := closingObsKinds[kind]; ok {
				closing++
			}
		}
	}

	// Reject under-documented close of a required lane (non-skip terminal).
	if isRequired && status != "skipped" && closing == 0 {
		return fmt.Errorf("vrdb: close-step: required DEEP lane step id=%d cannot close with zero "+
			"dead_end/invariant/blind_spot observations — a required lane that documents nothing is "+
			"almost certainly under-documented (flush ≥1 closing observation, or close as 'skipped' with a reason)", stepID)
	}

	// Insert the observations (filling target_id / agent_step_id) via the same write path
	// invariants. We insert directly here (inside the tx) rather than calling Put so the whole
	// close is atomic; columns are still identifier-checked.
	for j, o := range observations {
		row := make(map[string]any, len(o)+4)
		for k, v := range o {
			row[k] = v
		}
		row["agent_step_id"] = stepID
		if _, ok := row["target_id"]; !ok {
			row["target_id"] = targetID
		}
		if _, ok := row["content_fingerprint"]; !ok {
			row["content_fingerprint"] = ContentFingerprint(row)
		}
		if _, ok := row["id"]; !ok {
			var nextID int64
			if err := tx.QueryRowContext(ctx, "SELECT nextval('seq_agent_observations')").Scan(&nextID); err != nil {
				return fmt.Errorf("vrdb: close-step: obs id row %d: %w", j, err)
			}
			row["id"] = nextID
		}
		cols, ph, vals, err := columnsPlaceholders(row)
		if err != nil {
			return fmt.Errorf("vrdb: close-step: obs row %d: %w", j, err)
		}
		if _, err := tx.ExecContext(ctx,
			fmt.Sprintf("INSERT INTO agent_observations (%s) VALUES (%s) ON CONFLICT DO NOTHING",
				strings.Join(cols, ", "), strings.Join(ph, ", ")), vals...); err != nil {
			return fmt.Errorf("vrdb: close-step: insert obs row %d: %w", j, err)
		}
	}

	// Flip the step to its terminal status (+ ended_at if not already set).
	if _, err := tx.ExecContext(ctx,
		"UPDATE agent_steps SET status = ?, ended_at = COALESCE(ended_at, CURRENT_TIMESTAMP) WHERE id = ?",
		status, stepID); err != nil {
		return fmt.Errorf("vrdb: close-step: flip status: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("vrdb: close-step: commit: %w", err)
	}
	return nil
}

// GateResult is the single-boolean completion verdict (T3-09 / S-P08). Passed is the AND of
// every hard-red gate; Reds names each fired gate so the operator sees WHY without holding 25
// metrics in a compacting context. EmptyResult surfaces the named EMPTY_RESULT terminal
// (T2-15): a fully-searched-nothing-there campaign is a verdict, not an indistinguishable green.
type GateResult struct {
	Passed      bool     `json:"passed"`
	Reds        []string `json:"red_gates"`
	EmptyResult bool     `json:"empty_result"`
}

// Gate reads ONE verdict from the DB: the AND of all hard-red gate views/metrics (T3-09). It
// folds the pre-existing process gates (v_coverage hard-red metrics, v_lane_coverage MISSING,
// v_observation_coverage NO_OBSERVATION, v_phase_status) together with the v0.40 OUTCOME-
// justification gates (v_promotion_coverage UNJUSTIFIED, v_justification_coverage
// UNJUSTIFIED_NO_CONSUMER, v_sp_oracle_coverage RED, v_invariant_promotion_coverage RED). The
// orchestrator's "declare done" is then a single `Gate().Passed`, not a 25-metric eyeball.
func (d *DB) Gate(ctx context.Context) (GateResult, error) {
	var gr GateResult

	// 1. v_coverage hard-red metrics (> 0 ⇒ red). Includes the v0.40 metrics
	//    confirmed_without_promotion_provenance / ranked_sps_never_consumed /
	//    roster_steps_missing_for_current_round, which already live in v_coverage.
	hardRed := map[string]bool{
		"findings_candidate_open": true, "confirmed_without_critic": true,
		"confirmed_without_refutation": true, "lanes_stuck_running": true,
		"slices_without_codebase_coverage": true, "fuzz_runs_without_coverage_measurement": true,
		"fuzz_skips_unrecorded": true, "executed_steps_without_observation": true,
		"defenses_below_validator_cf_floor": true, "guards_on_paths_without_defense_row": true,
		"validator_cfs_without_defense_link": true, "dangerous_sink_cfs_without_sink_row": true,
		"regexes_unmapped": true, "confirmed_without_promotion_provenance": true,
		"ranked_sps_never_consumed": true, "roster_steps_missing_for_current_round": true,
	}
	covRows, err := d.Fetch(ctx, "SELECT metric, value FROM v_coverage")
	if err != nil {
		return gr, fmt.Errorf("vrdb: gate: v_coverage: %w", err)
	}
	for _, r := range covRows {
		m, _ := r["metric"].(string)
		if !hardRed[m] {
			continue
		}
		if asInt64(r["value"]) > 0 {
			gr.Reds = append(gr.Reds, fmt.Sprintf("v_coverage.%s=%d", m, asInt64(r["value"])))
		}
	}

	// 2..N. Single-count red views — each query returns one count; > 0 ⇒ red.
	redCountChecks := []struct{ name, sql string }{
		{"v_lane_coverage.MISSING", "SELECT count(*) AS n FROM v_lane_coverage WHERE gate_status = 'MISSING'"},
		{"v_observation_coverage.NO_OBSERVATION", "SELECT count(*) AS n FROM v_observation_coverage WHERE gate_status = 'NO_OBSERVATION'"},
		{"v_phase_status.incomplete", "SELECT count(*) AS n FROM v_phase_status WHERE phase_status = 'incomplete'"},
		{"v_promotion_coverage.UNJUSTIFIED", "SELECT count(*) AS n FROM v_promotion_coverage WHERE gate_status = 'UNJUSTIFIED'"},
		{"v_justification_coverage.UNJUSTIFIED_NO_CONSUMER", "SELECT count(*) AS n FROM v_justification_coverage WHERE justification_status = 'UNJUSTIFIED_NO_CONSUMER'"},
		{"v_sp_oracle_coverage.RED_oracle_unrun", "SELECT count(*) AS n FROM v_sp_oracle_coverage WHERE adjudication_status = 'RED_oracle_unrun'"},
		{"v_invariant_promotion_coverage.RED_unpromoted_unexplained", "SELECT count(*) AS n FROM v_invariant_promotion_coverage WHERE promotion_status = 'RED_unpromoted_unexplained'"},
	}
	for _, c := range redCountChecks {
		rows, err := d.Fetch(ctx, c.sql)
		if err != nil {
			return gr, fmt.Errorf("vrdb: gate: %s: %w", c.name, err)
		}
		if len(rows) > 0 && asInt64(rows[0]["n"]) > 0 {
			gr.Reds = append(gr.Reds, fmt.Sprintf("%s=%d", c.name, asInt64(rows[0]["n"])))
		}
	}

	// EMPTY_RESULT terminal (informational, not red).
	if er, err := d.Fetch(ctx, "SELECT is_empty_result FROM v_empty_result"); err == nil && len(er) == 1 {
		gr.EmptyResult = asBool(er[0]["is_empty_result"])
	}

	gr.Passed = len(gr.Reds) == 0
	return gr, nil
}

// SelftestResult reports the data-quality assertions Selftest ran.
type SelftestResult struct {
	Fails []string `json:"fails"`
	Warns []string `json:"warns"`
}

// Selftest asserts the data-quality contract against a LIVE audit DB (T3-10 / S-D12, F36):
//   - no born-confirmed-without-provenance (a confirmed row lacking the mutation_log
//     status_transition the promote verb writes);
//   - no born-refuted-without-provenance (the symmetric check: a refuted row lacking the
//     status_transition mutation_log row — Put rejects born-'refuted' just as it rejects
//     born-'confirmed', so a refuted row MUST carry an in-band-flip provenance row too);
//   - no orphan SP (a kept SP whose graduated_finding_id points nowhere);
//   - no hash-collision (a dedup key carrying ≥2 distinct content_fingerprints);
//   - warns if the loaded SKILL.md version (passed by the caller) < minSkillVersion.
//
// It runs read-only, so it is safe on a real campaign DB. The vendored-≥ preflight is the
// loadedSkillVersion/minSkillVersion comparison (the caller reads the version from SKILL.md).
func (d *DB) Selftest(ctx context.Context, loadedSkillVersion, minSkillVersion string) (SelftestResult, error) {
	var r SelftestResult

	type chk struct{ name, sql string }
	checks := []chk{
		{"born_confirmed_without_provenance",
			`SELECT count(*) AS n FROM gr_findings f
			 WHERE f.confirmation_status = 'confirmed'
			   AND NOT EXISTS (SELECT 1 FROM mutation_log ml
			       WHERE ml.table_name='gr_findings' AND ml.op='status_transition' AND ml.row_key=f.finding_hash)`},
		// Symmetric to the above: Put rejects born-'refuted' just as it rejects born-'confirmed'
		// (policy.go: only candidate/unconfirmed may be Put), so a 'refuted' row MUST also carry a
		// status_transition mutation_log row written by a verb. A refuted row lacking it was flipped
		// OUT-OF-BAND — the same false-provenance failure mode, on the refuted leg.
		{"born_refuted_without_provenance",
			`SELECT count(*) AS n FROM gr_findings f
			 WHERE f.confirmation_status = 'refuted'
			   AND NOT EXISTS (SELECT 1 FROM mutation_log ml
			       WHERE ml.table_name='gr_findings' AND ml.op='status_transition' AND ml.row_key=f.finding_hash)`},
		{"orphan_sp",
			`SELECT count(*) AS n FROM suspicious_points sp
			 WHERE sp.graduated_finding_id IS NOT NULL
			   AND NOT EXISTS (SELECT 1 FROM gr_findings f WHERE f.id = sp.graduated_finding_id)`},
	}
	for _, c := range checks {
		rows, err := d.Fetch(ctx, c.sql)
		if err != nil {
			return r, fmt.Errorf("vrdb: selftest: %s: %w", c.name, err)
		}
		if len(rows) > 0 && asInt64(rows[0]["n"]) > 0 {
			r.Fails = append(r.Fails, fmt.Sprintf("%s=%d", c.name, asInt64(rows[0]["n"])))
		}
	}

	// hash-collision: any (table, dedup-key) with ≥2 distinct non-null content_fingerprints.
	for table, col := range dedupKeyColumn {
		if !identRe.MatchString(table) || !identRe.MatchString(col) {
			continue
		}
		q := fmt.Sprintf(
			`SELECT count(*) AS n FROM (
			   SELECT %s FROM %s WHERE content_fingerprint IS NOT NULL
			   GROUP BY %s HAVING count(DISTINCT content_fingerprint) > 1
			 ) t`, col, table, col)
		rows, err := d.Fetch(ctx, q)
		if err != nil {
			// A table without a content_fingerprint column (shouldn't happen for keys in the
			// map) is a hard error, not a silent skip.
			return r, fmt.Errorf("vrdb: selftest: hash_collision %s: %w", table, err)
		}
		if len(rows) > 0 && asInt64(rows[0]["n"]) > 0 {
			r.Fails = append(r.Fails, fmt.Sprintf("hash_collision.%s=%d", table, asInt64(rows[0]["n"])))
		}
	}

	if loadedSkillVersion != "" && minSkillVersion != "" {
		if compareVersions(loadedSkillVersion, minSkillVersion) < 0 {
			r.Warns = append(r.Warns, fmt.Sprintf(
				"loaded SKILL.md version %s < min_skill_version %s — the vendored skill is behind; re-sync before relying on its guardrails",
				loadedSkillVersion, minSkillVersion))
		}
	}
	return r, nil
}

// asInt64 coerces a DuckDB-scanned numeric to int64.
func asInt64(v any) int64 {
	switch n := v.(type) {
	case int64:
		return n
	case int32:
		return int64(n)
	case int:
		return int64(n)
	case float64:
		return int64(n)
	case float32:
		return int64(n)
	default:
		return 0
	}
}

// asBool coerces a DuckDB-scanned boolean.
func asBool(v any) bool {
	switch b := v.(type) {
	case bool:
		return b
	case int64:
		return b != 0
	case string:
		return b == "true" || b == "TRUE" || b == "t"
	default:
		return false
	}
}

// compareVersions compares dotted numeric version strings (optionally with a leading 'v').
// Returns -1, 0, or +1. Non-numeric components compare lexically as a fallback.
func compareVersions(a, b string) int {
	clean := func(s string) []string {
		s = strings.TrimPrefix(strings.TrimSpace(s), "v")
		return strings.Split(s, ".")
	}
	as, bs := clean(a), clean(b)
	n := len(as)
	if len(bs) > n {
		n = len(bs)
	}
	for i := 0; i < n; i++ {
		var ai, bi string
		if i < len(as) {
			ai = as[i]
		}
		if i < len(bs) {
			bi = bs[i]
		}
		an, aerr := parseIntSafe(ai)
		bn, berr := parseIntSafe(bi)
		if aerr == nil && berr == nil {
			if an != bn {
				if an < bn {
					return -1
				}
				return 1
			}
			continue
		}
		if ai != bi {
			if ai < bi {
				return -1
			}
			return 1
		}
	}
	return 0
}

// parseIntSafe parses a base-10 int, treating empty as 0.
func parseIntSafe(s string) (int, error) {
	if s == "" {
		return 0, nil
	}
	n := 0
	for _, c := range s {
		if c < '0' || c > '9' {
			return 0, fmt.Errorf("non-numeric")
		}
		n = n*10 + int(c-'0')
	}
	return n, nil
}

// sha256Hex returns the lowercase hex sha256 of s.
func sha256Hex(s string) string {
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])
}

// columnsPlaceholders renders a row map into sorted (cols, placeholders, values), validating
// each column identifier — the shared INSERT-shape helper used by the verbs.
func columnsPlaceholders(row map[string]any) (cols, placeholders []string, values []any, err error) {
	cols = make([]string, 0, len(row))
	for k := range row {
		if !identRe.MatchString(k) {
			return nil, nil, nil, fmt.Errorf("invalid column identifier %q", k)
		}
		cols = append(cols, k)
	}
	sort.Strings(cols)
	placeholders = make([]string, len(cols))
	values = make([]any, len(cols))
	for i, c := range cols {
		placeholders[i] = "?"
		values[i] = row[c]
	}
	return cols, placeholders, values, nil
}
