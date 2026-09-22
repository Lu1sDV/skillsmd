// gate_semantics_test.go — golden-state tests for the four DEEP completion gate views.
//
// Each sub-test builds a fixture DuckDB (via openTestDB, same as vrdb_test.go),
// seeds crafted rows, and asserts the gate views return the documented signals.
// Tests are deliberately table-driven and isolated (each owns its own TempDir DB).
//
// Spec: ENGINE CHANGE-SET in the task description (findings C03-B-F5, C04-A-F1,
// C06-A-F4, C03-A-F10, C05-A-F10, C08-A-F1, C09-A-F1, C01-A-F1, C03-A-F8).
//
// Run: cd db/harness && go test ./... -run TestGateSemantics
package vrdb_test

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"vrdb"
)

// ─────────────────────────────────────────────────────────────────────────────
// helpers
// ─────────────────────────────────────────────────────────────────────────────

// seedTarget inserts a target row and returns its Put-assigned id.
func seedTarget(t *testing.T, db *vrdb.DB, ctx context.Context, suffix string) any {
	t.Helper()
	row := map[string]any{
		"repo_url":   "https://github.com/gate-test/" + suffix,
		"commit_sha": "c0-" + suffix,
		"language":   "go",
		"scanned_at": "2026-06-01 00:00:00",
	}
	if err := db.Put(ctx, "targets", []map[string]any{row}); err != nil {
		t.Fatalf("seedTarget(%s): %v", suffix, err)
	}
	return row["id"]
}

// seedRound inserts a round_ledger row for targetID and returns its Put-assigned id.
func seedRound(t *testing.T, db *vrdb.DB, ctx context.Context, targetID any, roundNo int) any {
	t.Helper()
	row := map[string]any{
		"target_id":   targetID,
		"round_no":    roundNo,
		"audit_run_id": fmt.Sprintf("run-%v-r%d", targetID, roundNo),
		"started_at":  "2026-06-01 00:00:00",
	}
	if err := db.Put(ctx, "round_ledger", []map[string]any{row}); err != nil {
		t.Fatalf("seedRound(target=%v round=%d): %v", targetID, roundNo, err)
	}
	return row["id"]
}

// seedStep inserts an agent_steps row for the named strategy and returns its id.
// strategyName must be one of the seeded strategy names (e.g. "forward_slice_lane").
// roundID may be nil for single-shot audits.
func seedStep(t *testing.T, db *vrdb.DB, ctx context.Context,
	targetID any, strategyName string, status string, roundID any, hashSuffix string) any {
	t.Helper()

	// Look up the strategy id by name.
	rows, err := db.Fetch(ctx, "SELECT id FROM strategies WHERE name = ?", strategyName)
	if err != nil || len(rows) == 0 {
		t.Fatalf("seedStep: strategy %q not found: %v", strategyName, err)
	}
	strategyID := rows[0]["id"]

	row := map[string]any{
		"target_id":   targetID,
		"strategy_id": strategyID,
		"started_at":  "2026-06-01 00:01:00",
		"status":      status,
		"step_hash":   strategyName + "-" + hashSuffix,
	}
	if roundID != nil {
		row["round_id"] = roundID
	}
	if err := db.Put(ctx, "agent_steps", []map[string]any{row}); err != nil {
		t.Fatalf("seedStep(%s, %s): %v", strategyName, status, err)
	}
	return row["id"]
}

// allRequiredLanes returns the 18 mandatory DEEP lane names (mirrors v_required_deep_lanes).
func allRequiredLanes() []string {
	return []string{
		"prior_art_intake_lane", // migration 0026 (C1; documented-skip allowed when no scope)
		"preliminary_enumeration_lane",
		"forward_slice_lane",
		"backward_sink_lane",
		"critical_function_dataflow_lane",
		"defense_base_lane",
		"defense_context_verification_lane",
		"isolation_fuzz_lane",
		"html_sanitizer_bypass_lane",
		"concolic_bypass_lane",
		"llm_seed_corpus_lane_a",
		"llm_seed_corpus_lane_b",
		"fuzzgpt_history_lane",
		"boundary_fuzz_lane",
		"methodology_blindspot_lane_a",
		"methodology_blindspot_lane_b",
		"overlooked_lane_audit_lane", // migration 0028 (C2; runs after phase1_6_blindspot)
		"report_critic",
	}
}

// fetchLaneCoverage returns a map lane_name -> gate_status from v_lane_coverage.
func fetchLaneCoverage(t *testing.T, db *vrdb.DB, ctx context.Context) map[string]string {
	t.Helper()
	rows, err := db.Fetch(ctx, "SELECT lane_name, gate_status FROM v_lane_coverage")
	if err != nil {
		t.Fatalf("fetchLaneCoverage: %v", err)
	}
	m := make(map[string]string, len(rows))
	for _, r := range rows {
		m[fmt.Sprintf("%v", r["lane_name"])] = fmt.Sprintf("%v", r["gate_status"])
	}
	return m
}

// fetchObsCoverage returns a map phase -> gate_status from v_observation_coverage.
func fetchObsCoverage(t *testing.T, db *vrdb.DB, ctx context.Context) map[string]string {
	t.Helper()
	rows, err := db.Fetch(ctx, "SELECT phase, gate_status FROM v_observation_coverage")
	if err != nil {
		t.Fatalf("fetchObsCoverage: %v", err)
	}
	m := make(map[string]string, len(rows))
	for _, r := range rows {
		m[fmt.Sprintf("%v", r["phase"])] = fmt.Sprintf("%v", r["gate_status"])
	}
	return m
}

// fetchCoverageMetric returns the numeric value of a named metric from v_coverage.
func fetchCoverageMetric(t *testing.T, db *vrdb.DB, ctx context.Context, metric string) int64 {
	t.Helper()
	rows, err := db.Fetch(ctx, "SELECT value FROM v_coverage WHERE metric = ?", metric)
	if err != nil || len(rows) == 0 {
		t.Fatalf("fetchCoverageMetric(%s): %v (rows=%d)", metric, err, len(rows))
	}
	switch v := rows[0]["value"].(type) {
	case int64:
		return v
	case int32:
		return int64(v)
	case float64:
		return int64(v)
	default:
		// DuckDB sometimes returns numeric as string via the sql driver.
		var n int64
		if _, scanErr := fmt.Sscan(fmt.Sprintf("%v", v), &n); scanErr != nil {
			t.Fatalf("fetchCoverageMetric(%s): cannot parse %T %v: %v", metric, v, v, scanErr)
		}
		return n
	}
}

// seedObservation inserts an agent_observations row attached to stepID.
func seedObservation(t *testing.T, db *vrdb.DB, ctx context.Context,
	targetID, stepID any, hashSuffix string) {
	t.Helper()
	row := map[string]any{
		"target_id":    targetID,
		"agent_step_id": stepID,
		"obs_kind":     "note",
		"body":         "gate semantics test observation",
		"obs_hash":     "obs-" + hashSuffix,
		"created_at":   "2026-06-01 00:02:00",
	}
	if err := db.Put(ctx, "agent_observations", []map[string]any{row}); err != nil {
		t.Fatalf("seedObservation(%s): %v", hashSuffix, err)
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// (a) clean DEEP-complete single-shot run → all gates green
// ─────────────────────────────────────────────────────────────────────────────

func TestGateSemantics_A_AllGreen_SingleShot(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "a-all-green")

	// Execute every required lane with status='success' and attach an observation.
	for i, lane := range allRequiredLanes() {
		stepID := seedStep(t, db, ctx, tid, lane, "success", nil,
			fmt.Sprintf("a-%d", i))
		seedObservation(t, db, ctx, tid, stepID, fmt.Sprintf("a-%d", i))
	}

	// v_lane_coverage: no MISSING rows.
	coverage := fetchLaneCoverage(t, db, ctx)
	for _, lane := range allRequiredLanes() {
		if coverage[lane] != "ok" {
			t.Errorf("lane %q: want gate_status='ok', got %q", lane, coverage[lane])
		}
	}

	// v_observation_coverage: no NO_OBSERVATION rows.
	obsCov := fetchObsCoverage(t, db, ctx)
	for phase, status := range obsCov {
		if status == "NO_OBSERVATION" {
			t.Errorf("phase %q: unexpected NO_OBSERVATION after all lanes ran with observations", phase)
		}
	}

	// v_coverage red columns: lanes_stuck_running = 0, confirmed_without_refutation = 0.
	if v := fetchCoverageMetric(t, db, ctx, "lanes_stuck_running"); v != 0 {
		t.Errorf("lanes_stuck_running: want 0, got %d", v)
	}
	if v := fetchCoverageMetric(t, db, ctx, "confirmed_without_refutation"); v != 0 {
		t.Errorf("confirmed_without_refutation: want 0, got %d", v)
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// (b) one required lane never materialized → v_lane_coverage MISSING for it
// ─────────────────────────────────────────────────────────────────────────────

func TestGateSemantics_B_OneLaneMissing(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "b-one-missing")

	absentLane := "backward_sink_lane"

	for i, lane := range allRequiredLanes() {
		if lane == absentLane {
			continue // deliberately skip this one
		}
		seedStep(t, db, ctx, tid, lane, "success", nil, fmt.Sprintf("b-%d", i))
	}

	coverage := fetchLaneCoverage(t, db, ctx)
	if coverage[absentLane] != "MISSING" {
		t.Errorf("lane %q: want gate_status='MISSING', got %q", absentLane, coverage[absentLane])
	}
	// All others must still be ok.
	for _, lane := range allRequiredLanes() {
		if lane == absentLane {
			continue
		}
		if coverage[lane] != "ok" {
			t.Errorf("lane %q: want 'ok', got %q (should not be affected by absent lane)", lane, coverage[lane])
		}
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// (c) ROUND-SCOPING: round 1 ran lane X; round 2 opens WITHOUT running X
//     → v_lane_coverage reports X as MISSING for round 2
//     (FAILS if the view is target-global rather than round-scoped — the bug being fixed)
// ─────────────────────────────────────────────────────────────────────────────

func TestGateSemantics_C_RoundScoping_MissingInRound2(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "c-round-scope")

	// Round 1: all lanes run (including the probe lane).
	r1id := seedRound(t, db, ctx, tid, 1)
	probeLane := "forward_slice_lane"
	for i, lane := range allRequiredLanes() {
		seedStep(t, db, ctx, tid, lane, "success", r1id, fmt.Sprintf("c-r1-%d", i))
	}
	_ = probeLane

	// Round 2: open a new round but do NOT execute the probe lane.
	r2id := seedRound(t, db, ctx, tid, 2)
	otherLane := "backward_sink_lane"
	// Only run one lane in round 2 (not the probe lane).
	seedStep(t, db, ctx, tid, otherLane, "success", r2id, "c-r2-0")

	// v_current_round should now point to round 2.
	crRows, err := db.Fetch(ctx, "SELECT round_id FROM v_current_round WHERE target_id = ?", tid)
	if err != nil || len(crRows) == 0 {
		t.Fatalf("v_current_round: %v (rows=%d)", err, len(crRows))
	}
	if fmt.Sprintf("%v", crRows[0]["round_id"]) != fmt.Sprintf("%v", r2id) {
		t.Errorf("v_current_round.round_id: want %v (r2id), got %v", r2id, crRows[0]["round_id"])
	}

	// v_lane_coverage must show MISSING for probe lane (ran only in round 1).
	coverage := fetchLaneCoverage(t, db, ctx)
	if coverage[probeLane] != "MISSING" {
		t.Errorf("ROUND-SCOPING BUG: lane %q ran in round 1 but NOT round 2; "+
			"v_lane_coverage should show 'MISSING' for round 2, got %q. "+
			"This means the view is target-global rather than round-scoped.",
			probeLane, coverage[probeLane])
	}
	// The lane that DID run in round 2 must be ok.
	if coverage[otherLane] != "ok" {
		t.Errorf("lane %q ran in round 2; want 'ok', got %q", otherLane, coverage[otherLane])
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// (d) agent_steps row stuck status='running' in current round
//     → v_coverage.lanes_stuck_running > 0 and that lane NOT counted 'ok'
// ─────────────────────────────────────────────────────────────────────────────

func TestGateSemantics_D_StuckRunning(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "d-stuck-running")

	stuckLane := "critical_function_dataflow_lane"

	// Seed all other lanes as success; seed the stuck lane as 'running'.
	for i, lane := range allRequiredLanes() {
		status := "success"
		if lane == stuckLane {
			status = "running"
		}
		seedStep(t, db, ctx, tid, lane, status, nil, fmt.Sprintf("d-%d", i))
	}

	// v_coverage.lanes_stuck_running must be > 0.
	stuck := fetchCoverageMetric(t, db, ctx, "lanes_stuck_running")
	if stuck == 0 {
		t.Errorf("lanes_stuck_running: want >0 (stuck lane %q in status=running), got 0", stuckLane)
	}

	// v_lane_coverage: the stuck lane must NOT be 'ok'.
	coverage := fetchLaneCoverage(t, db, ctx)
	if coverage[stuckLane] == "ok" {
		t.Errorf("lane %q has status='running' (not success/exhausted); "+
			"gate_status must not be 'ok', got %q", stuckLane, coverage[stuckLane])
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// (e) confirmed gr_findings row with no refutation
//     → v_coverage.confirmed_without_refutation > 0
// ─────────────────────────────────────────────────────────────────────────────

// TestGateSemantics_E_ConfirmedWithoutRefutation pins TWO contracts at once after the v0.40
// born-confirmed lockout (T3-02):
//
//  1. A born-'confirmed' gr_findings row can NO LONGER be Put — the lockout rejects it (the
//     ONLY path to 'confirmed' is the `vrdb promote` verb). This is the write-side guarantee.
//  2. The pre-existing `v_coverage.confirmed_without_refutation` metric remains the
//     defense-in-depth BACKSTOP for an OUT-OF-BAND flip: if some writer bypasses the harness
//     and sets confirmation_status='confirmed' via raw SQL without a refutations row, the
//     metric still fires >0. (Such a flip is exactly what the lockout makes impossible through
//     Put; the metric catches the residual raw-Exec path.)
func TestGateSemantics_E_ConfirmedWithoutRefutation(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "e-no-refute")

	// Need an agent_step to hang the finding off.
	stepID := seedStep(t, db, ctx, tid, "forward_slice_lane", "success", nil, "e-step")

	// (1) born-confirmed LOCKOUT: a direct Put of a 'confirmed' row must be REJECTED.
	born := map[string]any{
		"target_id":           tid,
		"agent_step_id":       stepID,
		"finding_kind":        "sqli",
		"confirmation_status": "confirmed",
		"finding_hash":        "fnd-e-born-confirmed",
	}
	if err := db.Put(ctx, "gr_findings", []map[string]any{born}); err == nil {
		t.Fatalf("born-confirmed lockout: expected Put of a 'confirmed' finding to be REJECTED, got nil error")
	} else if !strings.Contains(err.Error(), "born-confirmed lockout") {
		t.Fatalf("born-confirmed lockout: expected a lockout error, got: %v", err)
	}

	// (2) The metric still backstops an out-of-band flip. Put the finding legally as
	// 'candidate', then simulate a harness-bypassing writer flipping it to 'confirmed' via
	// raw SQL with NO refutations row — the failure mode the metric exists to catch.
	finding := map[string]any{
		"target_id":           tid,
		"agent_step_id":       stepID,
		"finding_kind":        "sqli",
		"confirmation_status": "candidate",
		"finding_hash":        "fnd-e-no-refute",
	}
	if err := db.Put(ctx, "gr_findings", []map[string]any{finding}); err != nil {
		t.Fatalf("Put candidate gr_findings: %v", err)
	}
	if _, err := db.Exec(ctx,
		"UPDATE gr_findings SET confirmation_status = 'confirmed' WHERE finding_hash = ?",
		"fnd-e-no-refute"); err != nil {
		t.Fatalf("out-of-band flip: %v", err)
	}

	val := fetchCoverageMetric(t, db, ctx, "confirmed_without_refutation")
	if val == 0 {
		t.Errorf("confirmed_without_refutation: want >0 (confirmed finding has no refutations row), got 0")
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// (f) executed phase that flushed zero agent_observations
//     → v_observation_coverage gate_status='NO_OBSERVATION'
// ─────────────────────────────────────────────────────────────────────────────

func TestGateSemantics_F_NoObservation(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "f-no-obs")

	// Execute all required lanes but attach NO observations to any step.
	for i, lane := range allRequiredLanes() {
		seedStep(t, db, ctx, tid, lane, "success", nil, fmt.Sprintf("f-%d", i))
	}

	// v_observation_coverage: every phase that ran (executed_steps > 0) must
	// have gate_status='NO_OBSERVATION' because zero observations were flushed.
	obsCov := fetchObsCoverage(t, db, ctx)
	foundNoObs := false
	for _, status := range obsCov {
		if status == "NO_OBSERVATION" {
			foundNoObs = true
			break
		}
	}
	if !foundNoObs {
		t.Errorf("v_observation_coverage: expected at least one phase with "+
			"gate_status='NO_OBSERVATION' (all steps ran but no observations flushed). "+
			"Got statuses: %v", obsCov)
	}

	// No phase should be 'ok' because no observations exist.
	for phase, status := range obsCov {
		if status == "ok" {
			t.Errorf("phase %q: got 'ok' but no observations were seeded — "+
				"should be NO_OBSERVATION", phase)
		}
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// Bonus: single-shot regression — round_id IS NULL everywhere behaves as before
// ─────────────────────────────────────────────────────────────────────────────

func TestGateSemantics_SingleShotRegression(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "ss-regression")

	// No round_ledger rows at all (single-shot).
	for i, lane := range allRequiredLanes() {
		stepID := seedStep(t, db, ctx, tid, lane, "success", nil, fmt.Sprintf("ss-%d", i))
		seedObservation(t, db, ctx, tid, stepID, fmt.Sprintf("ss-%d", i))
	}

	// v_current_round should have no rows for this target (no round_ledger).
	crRows, err := db.Fetch(ctx, "SELECT round_id FROM v_current_round WHERE target_id = ?", tid)
	if err != nil {
		t.Fatalf("v_current_round: %v", err)
	}
	if len(crRows) != 0 {
		t.Errorf("single-shot: v_current_round should have 0 rows (no round_ledger), got %d", len(crRows))
	}

	// All lanes must be ok even without round_ledger rows.
	coverage := fetchLaneCoverage(t, db, ctx)
	for _, lane := range allRequiredLanes() {
		if coverage[lane] != "ok" {
			t.Errorf("single-shot regression: lane %q want 'ok', got %q", lane, coverage[lane])
		}
	}

	// No observation gap.
	obsCov := fetchObsCoverage(t, db, ctx)
	for phase, status := range obsCov {
		if status == "NO_OBSERVATION" {
			t.Errorf("single-shot regression: phase %q unexpected NO_OBSERVATION", phase)
		}
	}
}
