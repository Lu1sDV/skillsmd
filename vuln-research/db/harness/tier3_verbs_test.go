// tier3_verbs_test.go — smoke tests for the TIER-3 harness verbs that make the prose write-
// contract executable (DuckDB v1.1.3 has no triggers, so these verbs are the ONLY enforcement
// point). One sub-test per T3 item + its rejection paths:
//
//   - Promote (T3-01): happy path + each precondition rejection (wrong status / no refutation /
//     no critic-OK / invalid severity / invalid rigor) + the born-confirmed lockout (T3-02).
//   - CloseStep (T3-03): zero-observation rejection on a required DEEP lane + the happy path
//     (closing observation present, or 'skipped' exempt).
//   - content-checked dedup (T3-04): a hash-collision-with-different-content Put is REJECTED.
//   - Checkpoint/Snapshot (T3-06): round-trip — snapshot a populated DB, corrupt the main file,
//     and prove Open() auto-restores from the snapshot.
//   - Gate / Selftest (T3-09 / T3-10): smoke the single-verdict + data-quality readers.
//
// Each test owns its own TempDir DB (zero shared state), matching the existing suite style.
package vrdb_test

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"vrdb"
)

// seedPromotableFinding seeds a target + step + a 'candidate' gr_findings row and returns the
// finding id and step id. It does NOT seed the refutation/critic companions, so a test can add
// them selectively to exercise each promote precondition.
func seedPromotableFinding(t *testing.T, db *vrdb.DB, ctx context.Context, suffix string) (findingID, stepID, targetID any) {
	t.Helper()
	tid := seedTarget(t, db, ctx, "promote-"+suffix)
	sid := seedStep(t, db, ctx, tid, "forward_slice_lane", "success", nil, "promote-"+suffix)
	fnd := map[string]any{
		"target_id":           tid,
		"agent_step_id":       sid,
		"finding_kind":        "sqli",
		"confirmation_status": "candidate",
		"finding_hash":        "fnd-promote-" + suffix,
	}
	if err := db.Put(ctx, "gr_findings", []map[string]any{fnd}); err != nil {
		t.Fatalf("seedPromotableFinding(%s): put finding: %v", suffix, err)
	}
	return fnd["id"], sid, tid
}

// addRefutation inserts a refutations row for findingID (the refute-before-confirm trail).
func addRefutation(t *testing.T, db *vrdb.DB, ctx context.Context, findingID, stepID any, suffix string) {
	t.Helper()
	row := map[string]any{
		"finding_id":        findingID,
		"agent_step_id":     stepID,
		"refutation_reason": "other",
		"created_at":        "2026-06-01 00:03:00",
	}
	if err := db.Put(ctx, "refutations", []map[string]any{row}); err != nil {
		t.Fatalf("addRefutation(%s): %v", suffix, err)
	}
}

// addCriticOK inserts a critic_findings(check_kind='eligibility', severity='OK') row.
func addCriticOK(t *testing.T, db *vrdb.DB, ctx context.Context, findingID any, suffix string) {
	t.Helper()
	row := map[string]any{
		"finding_id": findingID,
		"check_kind": "eligibility",
		"severity":   "OK",
		"message":    "eligible: default-config consumer harmed",
		"created_at": "2026-06-01 00:04:00",
	}
	if err := db.Put(ctx, "critic_findings", []map[string]any{row}); err != nil {
		t.Fatalf("addCriticOK(%s): %v", suffix, err)
	}
}

func findingStatus(t *testing.T, db *vrdb.DB, ctx context.Context, findingID any) string {
	t.Helper()
	rows, err := db.Fetch(ctx, "SELECT confirmation_status FROM gr_findings WHERE id = ?", findingID)
	if err != nil || len(rows) != 1 {
		t.Fatalf("findingStatus: %v (rows=%d)", err, len(rows))
	}
	s, _ := rows[0]["confirmation_status"].(string)
	return s
}

// ─────────────────────────────────────────────────────────────────────────────
// T3-01 Promote — happy path
// ─────────────────────────────────────────────────────────────────────────────

func TestPromote_HappyPath(t *testing.T) {
	db, ctx := openTestDB(t)
	fid, sid, _ := seedPromotableFinding(t, db, ctx, "happy")
	addRefutation(t, db, ctx, fid, sid, "happy")
	addCriticOK(t, db, ctx, fid, "happy")
	// Gate-5 consumer-harm proof is a promote precondition (HIGH-1).
	if err := db.ImpactProof(ctx, asInt64Test(t, fid), vrdb.ImpactProofOpts{
		ConsumerSymbol: "Handler::dispatch", HarmClass: "rce", ProvenReachability: "proven",
	}); err != nil {
		t.Fatalf("ImpactProof: %v", err)
	}

	if err := db.Promote(ctx, asInt64Test(t, fid), vrdb.PromoteOpts{
		Severity: "HIGH", RigorTier: "independent",
	}); err != nil {
		t.Fatalf("Promote happy path: %v", err)
	}

	if got := findingStatus(t, db, ctx, fid); got != "confirmed" {
		t.Fatalf("after promote: confirmation_status=%q, want 'confirmed'", got)
	}

	// The promote must have stamped severity + rigor tier and written the in-band-flip provenance.
	rows, err := db.Fetch(ctx, "SELECT severity, confirmation_rigor_tier FROM gr_findings WHERE id = ?", fid)
	if err != nil || len(rows) != 1 {
		t.Fatalf("read promoted finding: %v", err)
	}
	if got, _ := rows[0]["severity"].(string); got != "HIGH" {
		t.Errorf("severity=%q, want HIGH", got)
	}
	if got, _ := rows[0]["confirmation_rigor_tier"].(string); got != "independent" {
		t.Errorf("confirmation_rigor_tier=%q, want independent", got)
	}
	mut, err := db.Fetch(ctx,
		"SELECT count(*) AS n FROM mutation_log WHERE table_name='gr_findings' AND op='status_transition'")
	if err != nil {
		t.Fatalf("read mutation_log: %v", err)
	}
	if mustN(t, mut) != 1 {
		t.Errorf("mutation_log status_transition rows = %d, want 1 (the promote-provenance row)", mustN(t, mut))
	}

	// v_promotion_coverage must now LIST this finding (it is confirmed) with the three promote-
	// enforced flags green: has_refutation / has_severity / has_critic_ok. (The 4th JUSTIFIED
	// factor — a backing SP with a passing oracle — is the orchestrator's responsibility, not
	// the promote verb's, so we assert the promote-owned flags, not the full JUSTIFIED verdict.)
	jrows, err := db.Fetch(ctx,
		"SELECT has_refutation, has_severity, has_critic_ok FROM v_promotion_coverage WHERE finding_id = ?", fid)
	if err != nil || len(jrows) != 1 {
		t.Fatalf("v_promotion_coverage: %v (rows=%d)", err, len(jrows))
	}
	for _, k := range []string{"has_refutation", "has_severity", "has_critic_ok"} {
		if !asBoolTest(jrows[0][k]) {
			t.Errorf("v_promotion_coverage.%s should be true after a clean promote, got %v", k, jrows[0][k])
		}
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// T3-01 Promote — each rejection path
// ─────────────────────────────────────────────────────────────────────────────

func TestPromote_RejectsNoRefutation(t *testing.T) {
	db, ctx := openTestDB(t)
	fid, _, _ := seedPromotableFinding(t, db, ctx, "no-refute")
	addCriticOK(t, db, ctx, fid, "no-refute") // critic OK present, refutation MISSING

	err := db.Promote(ctx, asInt64Test(t, fid), vrdb.PromoteOpts{Severity: "MEDIUM", RigorTier: "shallow"})
	if err == nil {
		t.Fatalf("expected rejection (no refutations row), got nil")
	}
	if !strings.Contains(err.Error(), "no refutations row") {
		t.Errorf("wrong rejection: %v", err)
	}
	if got := findingStatus(t, db, ctx, fid); got != "candidate" {
		t.Errorf("finding flipped despite failed promote: status=%q, want candidate (tx must roll back)", got)
	}
}

func TestPromote_RejectsNoCriticOK(t *testing.T) {
	db, ctx := openTestDB(t)
	fid, sid, _ := seedPromotableFinding(t, db, ctx, "no-critic")
	addRefutation(t, db, ctx, fid, sid, "no-critic") // refutation present, critic-OK MISSING

	err := db.Promote(ctx, asInt64Test(t, fid), vrdb.PromoteOpts{Severity: "LOW", RigorTier: "reproduced"})
	if err == nil {
		t.Fatalf("expected rejection (no critic eligibility OK), got nil")
	}
	if !strings.Contains(err.Error(), "critic_findings") {
		t.Errorf("wrong rejection: %v", err)
	}
	if got := findingStatus(t, db, ctx, fid); got != "candidate" {
		t.Errorf("finding flipped despite failed promote: status=%q, want candidate", got)
	}
}

func TestPromote_RejectsInvalidSeverityAndRigor(t *testing.T) {
	db, ctx := openTestDB(t)
	fid, sid, _ := seedPromotableFinding(t, db, ctx, "bad-args")
	addRefutation(t, db, ctx, fid, sid, "bad-args")
	addCriticOK(t, db, ctx, fid, "bad-args")
	id := asInt64Test(t, fid)

	if err := db.Promote(ctx, id, vrdb.PromoteOpts{Severity: "SUPER", RigorTier: "independent"}); err == nil ||
		!strings.Contains(err.Error(), "severity") {
		t.Errorf("expected invalid-severity rejection, got %v", err)
	}
	if err := db.Promote(ctx, id, vrdb.PromoteOpts{Severity: "HIGH", RigorTier: "guesswork"}); err == nil ||
		!strings.Contains(err.Error(), "rigor_tier") {
		t.Errorf("expected invalid-rigor rejection, got %v", err)
	}
	if got := findingStatus(t, db, ctx, fid); got != "candidate" {
		t.Errorf("finding flipped on invalid-arg promote: status=%q, want candidate", got)
	}
}

func TestPromote_RejectsAlreadyConfirmedAndMissing(t *testing.T) {
	db, ctx := openTestDB(t)
	fid, sid, _ := seedPromotableFinding(t, db, ctx, "double")
	addRefutation(t, db, ctx, fid, sid, "double")
	addCriticOK(t, db, ctx, fid, "double")
	id := asInt64Test(t, fid)
	// Gate-5 consumer-harm proof is a promote precondition (HIGH-1).
	if err := db.ImpactProof(ctx, id, vrdb.ImpactProofOpts{
		ConsumerSymbol: "Handler::dispatch", HarmClass: "rce", ProvenReachability: "proven",
	}); err != nil {
		t.Fatalf("ImpactProof: %v", err)
	}

	if err := db.Promote(ctx, id, vrdb.PromoteOpts{Severity: "HIGH", RigorTier: "independent"}); err != nil {
		t.Fatalf("first promote: %v", err)
	}
	// Second promote must reject (already confirmed — only 'candidate' may be promoted).
	if err := db.Promote(ctx, id, vrdb.PromoteOpts{Severity: "HIGH", RigorTier: "independent"}); err == nil ||
		!strings.Contains(err.Error(), "already confirmed") {
		t.Errorf("expected already-confirmed rejection, got %v", err)
	}
	// A nonexistent finding must reject cleanly.
	if err := db.Promote(ctx, 999999, vrdb.PromoteOpts{Severity: "LOW", RigorTier: "shallow"}); err == nil ||
		!strings.Contains(err.Error(), "not found") {
		t.Errorf("expected not-found rejection, got %v", err)
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// T3-02 born-confirmed lockout (Put-level)
// ─────────────────────────────────────────────────────────────────────────────

func TestPut_BornConfirmedLockout(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "lockout")
	sid := seedStep(t, db, ctx, tid, "forward_slice_lane", "success", nil, "lockout")

	for _, status := range []string{"confirmed", "refuted"} {
		row := map[string]any{
			"target_id":           tid,
			"agent_step_id":       sid,
			"finding_kind":        "sqli",
			"confirmation_status": status,
			"finding_hash":        "fnd-lockout-" + status,
		}
		err := db.Put(ctx, "gr_findings", []map[string]any{row})
		if err == nil {
			t.Errorf("born-%s: expected lockout rejection, got nil", status)
			continue
		}
		if !strings.Contains(err.Error(), "born-confirmed lockout") {
			t.Errorf("born-%s: wrong rejection: %v", status, err)
		}
	}

	// 'candidate' and 'unconfirmed' must still be accepted.
	for _, status := range []string{"candidate", "unconfirmed"} {
		row := map[string]any{
			"target_id":           tid,
			"agent_step_id":       sid,
			"finding_kind":        "sqli",
			"confirmation_status": status,
			"finding_hash":        "fnd-ok-" + status,
		}
		if err := db.Put(ctx, "gr_findings", []map[string]any{row}); err != nil {
			t.Errorf("status %q should be Put-able, got: %v", status, err)
		}
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// T3-03 CloseStep — zero-observation rejection + happy path
// ─────────────────────────────────────────────────────────────────────────────

func TestCloseStep_RejectsRequiredLaneZeroObservations(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "close-zero")
	// forward_slice_lane is a required DEEP lane (v_required_deep_lanes).
	sid := seedStep(t, db, ctx, tid, "forward_slice_lane", "running", nil, "close-zero")

	// Closing a required lane into a non-skip terminal with NO dead_end/invariant/blind_spot
	// observation must be REJECTED.
	err := db.CloseStep(ctx, asInt64Test(t, sid), "success", nil)
	if err == nil {
		t.Fatalf("expected rejection closing a required lane with zero observations, got nil")
	}
	if !strings.Contains(err.Error(), "under-documented") {
		t.Errorf("wrong rejection: %v", err)
	}

	// A 'note'-only observation does NOT satisfy the requirement either.
	err = db.CloseStep(ctx, asInt64Test(t, sid), "success", []map[string]any{
		{"obs_kind": "note", "body": "ran the lane", "obs_hash": "obs-note-only"},
	})
	if err == nil || !strings.Contains(err.Error(), "under-documented") {
		t.Errorf("note-only close should still be rejected, got %v", err)
	}
}

func TestCloseStep_HappyPathWithClosingObservation(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "close-ok")
	sid := seedStep(t, db, ctx, tid, "forward_slice_lane", "running", nil, "close-ok")

	err := db.CloseStep(ctx, asInt64Test(t, sid), "success", []map[string]any{
		{"obs_kind": "dead_end", "body": "ruled out the taint path", "obs_hash": "obs-dead-end-1",
			"created_at": "2026-06-01 00:05:00"},
	})
	if err != nil {
		t.Fatalf("close-step happy path: %v", err)
	}

	// Step flipped + observation landed.
	srows, err := db.Fetch(ctx, "SELECT status FROM agent_steps WHERE id = ?", sid)
	if err != nil || len(srows) != 1 {
		t.Fatalf("read step: %v", err)
	}
	if got, _ := srows[0]["status"].(string); got != "success" {
		t.Errorf("step status=%q, want success", got)
	}
	orows, err := db.Fetch(ctx, "SELECT count(*) AS n FROM agent_observations WHERE agent_step_id = ?", sid)
	if err != nil {
		t.Fatalf("read obs: %v", err)
	}
	if mustN(t, orows) != 1 {
		t.Errorf("observations flushed = %d, want 1", mustN(t, orows))
	}
}

func TestCloseStep_SkippedExempt(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "close-skip")
	sid := seedStep(t, db, ctx, tid, "forward_slice_lane", "running", nil, "close-skip")

	// 'skipped' is a documented skip — exempt from the closing-observation requirement.
	if err := db.CloseStep(ctx, asInt64Test(t, sid), "skipped", nil); err != nil {
		t.Fatalf("skipped close should be exempt from the observation requirement: %v", err)
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// T3-04 content-checked dedup — collision-with-different-content is REJECTED
// ─────────────────────────────────────────────────────────────────────────────

func TestPut_ContentFingerprintCollisionRejected(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "collision")
	sid := seedStep(t, db, ctx, tid, "forward_slice_lane", "success", nil, "collision")

	// Two genuinely DISTINCT findings the agent (mis)assigned the SAME finding_hash to — the
	// "3 crashes → 1 row" over-dedup. The first lands; the second, carrying the same dedup key
	// but a different body (finding_kind), must be REJECTED rather than silently dropped.
	first := map[string]any{
		"target_id": tid, "agent_step_id": sid, "finding_kind": "sqli",
		"confirmation_status": "candidate", "finding_hash": "fnd-collide",
	}
	if err := db.Put(ctx, "gr_findings", []map[string]any{first}); err != nil {
		t.Fatalf("first put: %v", err)
	}
	second := map[string]any{
		"target_id": tid, "agent_step_id": sid, "finding_kind": "xxe", // DIFFERENT body
		"confirmation_status": "candidate", "finding_hash": "fnd-collide", // SAME dedup key
	}
	err := db.Put(ctx, "gr_findings", []map[string]any{second})
	if err == nil {
		t.Fatalf("expected hash-collision rejection (distinct content, same finding_hash), got nil")
	}
	if !strings.Contains(err.Error(), "hash collision") {
		t.Errorf("wrong rejection: %v", err)
	}

	// A true idempotent REPLAY (identical body, same hash) must still be a no-op, not a reject.
	replay := map[string]any{
		"target_id": tid, "agent_step_id": sid, "finding_kind": "sqli",
		"confirmation_status": "candidate", "finding_hash": "fnd-collide",
	}
	if err := db.Put(ctx, "gr_findings", []map[string]any{replay}); err != nil {
		t.Errorf("idempotent replay should be a no-op, got: %v", err)
	}
}

// TestContentFingerprint_RecipeStable pins the pinned-recipe helper: order-independent,
// excludes the surrogate id, and a different semantic value changes the digest.
func TestContentFingerprint_RecipeStable(t *testing.T) {
	a := map[string]any{"id": 1, "finding_kind": "sqli", "finding_hash": "h"}
	b := map[string]any{"finding_hash": "h", "finding_kind": "sqli", "id": 999} // reordered, different id
	if vrdb.ContentFingerprint(a) != vrdb.ContentFingerprint(b) {
		t.Errorf("fingerprint should ignore id + column order: %s != %s",
			vrdb.ContentFingerprint(a), vrdb.ContentFingerprint(b))
	}
	c := map[string]any{"finding_kind": "xxe", "finding_hash": "h"} // different body
	if vrdb.ContentFingerprint(a) == vrdb.ContentFingerprint(c) {
		t.Errorf("fingerprint should differ when a semantic value differs")
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// T3-06 Checkpoint / Snapshot — round-trip + auto-restore on corruption
// ─────────────────────────────────────────────────────────────────────────────

func TestCheckpointAndSnapshot_RoundTrip(t *testing.T) {
	ctx := context.Background()
	dbPath := filepath.Join(t.TempDir(), "snap.duckdb")
	db, err := vrdb.Open(dbPath)
	if err != nil {
		t.Fatalf("Open: %v", err)
	}

	// Populate, checkpoint (durable WAL flush), and snapshot before a "HEAVY lane".
	tid := seedTarget(t, db, ctx, "snap-1")
	_ = tid
	if err := db.Checkpoint(ctx); err != nil {
		t.Fatalf("Checkpoint: %v", err)
	}
	snapPath, err := db.Snapshot(ctx, "round1-phase0")
	if err != nil {
		t.Fatalf("Snapshot: %v", err)
	}
	if _, err := os.Stat(snapPath); err != nil {
		t.Fatalf("snapshot file not written: %v", err)
	}
	_ = db.Close()

	// Corrupt the main file (simulate the "Failed to load metadata pointer" torn-page failure).
	if err := os.WriteFile(dbPath, []byte("CORRUPT NOT A DUCKDB FILE"), 0o644); err != nil {
		t.Fatalf("corrupt main file: %v", err)
	}

	// Re-Open must run the integrity probe, detect the corruption, and auto-restore from the
	// newest snapshot — surfacing a usable DB instead of a raw metadata-pointer error.
	db2, err := vrdb.Open(dbPath)
	if err != nil {
		t.Fatalf("Open after corruption should auto-restore from snapshot, got: %v", err)
	}
	defer db2.Close()
	rows, err := db2.Fetch(ctx, "SELECT count(*) AS n FROM targets")
	if err != nil {
		t.Fatalf("read restored DB: %v", err)
	}
	if mustN(t, rows) != 1 {
		t.Errorf("restored DB should carry the snapshotted target row, got n=%d", mustN(t, rows))
	}
}

func TestOpen_NoSnapshotSurfacesCorruption(t *testing.T) {
	dbPath := filepath.Join(t.TempDir(), "nosnap.duckdb")
	db, err := vrdb.Open(dbPath)
	if err != nil {
		t.Fatalf("Open: %v", err)
	}
	_ = db.Close()
	// Corrupt with NO snapshot available — Open must surface the failure, not silently empty-init.
	if err := os.WriteFile(dbPath, []byte("CORRUPT"), 0o644); err != nil {
		t.Fatalf("corrupt: %v", err)
	}
	if _, err := vrdb.Open(dbPath); err == nil {
		t.Errorf("Open of a corrupt file with no snapshot should error, got nil")
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// T3-09 Gate / T3-10 Selftest — single-verdict + data-quality readers
// ─────────────────────────────────────────────────────────────────────────────

func TestGate_EmptyDBReadsRedOrEmpty(t *testing.T) {
	db, ctx := openTestDB(t)
	gr, err := db.Gate(ctx)
	if err != nil {
		t.Fatalf("Gate: %v", err)
	}
	// An empty DB has required lanes MISSING, so the gate must NOT pass; the result is a
	// structured verdict the orchestrator reads as one boolean.
	if gr.Passed {
		t.Errorf("empty DB should not pass the gate (required lanes MISSING); reds=%v", gr.Reds)
	}
}

func TestSelftest_CleanDBNoFails(t *testing.T) {
	db, ctx := openTestDB(t)
	// A fresh DB has no confirmed findings, no orphan SP, no hash collisions → zero fails.
	r, err := db.Selftest(ctx, "", "")
	if err != nil {
		t.Fatalf("Selftest: %v", err)
	}
	if len(r.Fails) != 0 {
		t.Errorf("clean DB should have zero data-quality fails, got: %v", r.Fails)
	}
}

func TestSelftest_VendoredBehindWarns(t *testing.T) {
	db, ctx := openTestDB(t)
	r, err := db.Selftest(ctx, "0.39.0", "0.40.0") // loaded < min
	if err != nil {
		t.Fatalf("Selftest: %v", err)
	}
	if len(r.Warns) == 0 {
		t.Errorf("loaded SKILL.md version below min should WARN, got none")
	}
	// And the reverse (loaded >= min) must NOT warn.
	r2, err := db.Selftest(ctx, "0.40.0", "0.40.0")
	if err != nil {
		t.Fatalf("Selftest: %v", err)
	}
	if len(r2.Warns) != 0 {
		t.Errorf("loaded == min should not warn, got: %v", r2.Warns)
	}
}

// TestSelftest_OrphanSPUnreachableUnderFK documents WHY there is no positive orphan-SP fixture:
// suspicious_points.graduated_finding_id carries a DB-level `REFERENCES gr_findings(id)` FK that
// DuckDB enforces on INSERT and UPDATE alike, so a kept SP pointing at a NONEXISTENT finding
// cannot be planted at all (verified here). The Selftest orphan_sp query is therefore a defense-
// in-depth backstop against a future schema that drops the FK (e.g. a nullable ADD COLUMN on the
// upgrade path with no inline REFERENCES); it costs nothing and fires zero on a clean DB
// (asserted by TestSelftest_CleanDBNoFails). We assert the FK rejects the dangling reference so
// the unreachability is pinned by a test, not by assumption.
func TestSelftest_OrphanSPUnreachableUnderFK(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "orphan-sp")
	sid := seedStep(t, db, ctx, tid, "forward_slice_lane", "success", nil, "orphan-sp")
	var spID int64
	if err := db.SQL().QueryRowContext(ctx, "SELECT nextval('seq_suspicious_points')").Scan(&spID); err != nil {
		t.Fatalf("sp id: %v", err)
	}
	_, err := db.Exec(ctx,
		`INSERT INTO suspicious_points
		   (id, target_id, agent_step_id, symbol_path, region_hash, description, vuln_class, lane,
		    screening_verdict, graduated_finding_id, created_at)
		 VALUES (?, ?, ?, 'pkg/foo.go:bar', 'rh-orphan', 'control-flow landmark', 'sqli',
		         'forward_slice_lane', 'kept', 424242, '2026-06-01 00:06:00')`,
		spID, tid, sid)
	if err == nil {
		t.Fatalf("expected the DB FK to reject a dangling graduated_finding_id, got nil")
	}
	if !strings.Contains(err.Error(), "foreign key") {
		t.Errorf("expected a foreign-key rejection, got: %v", err)
	}
	// And the selftest still runs cleanly on the resulting (FK-consistent) DB.
	r, err := db.Selftest(ctx, "", "")
	if err != nil {
		t.Fatalf("Selftest: %v", err)
	}
	for _, f := range r.Fails {
		if strings.Contains(f, "orphan_sp") {
			t.Errorf("orphan_sp should not fire on an FK-consistent DB, got: %v", r.Fails)
		}
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// HIGH-1 / HIGH-2 acceptance — the documented promote→gate happy path reaches GREEN
// ─────────────────────────────────────────────────────────────────────────────

// seedFullyGreenProcessDB seeds the PROCESS gates green: every required DEEP lane runs with an
// attached observation (so v_lane_coverage has no MISSING and v_observation_coverage no
// NO_OBSERVATION), plus one regexes row (so regexes_unmapped does not fire once
// preliminary_enumeration_lane has run) and one fuzz_runs row with a coverage measurement for the
// boundary_fuzz_lane step (so fuzz_skips_unrecorded + fuzz_runs_without_coverage_measurement do
// not fire). It returns the target id and the boundary_fuzz_lane step id — the caller hangs the
// candidate finding off that already-observed step so it adds no new observation gap. No findings
// are seeded — the caller adds the justified confirmed finding on top.
func seedFullyGreenProcessDB(t *testing.T, db *vrdb.DB, ctx context.Context, suffix string) (targetID, fuzzStepID any) {
	t.Helper()
	tid := seedTarget(t, db, ctx, "green-"+suffix)
	var fuzzStep any
	for i, lane := range allRequiredLanes() {
		stepID := seedStep(t, db, ctx, tid, lane, "success", nil, fmt.Sprintf("%s-%d", suffix, i))
		seedObservation(t, db, ctx, tid, stepID, fmt.Sprintf("%s-%d", suffix, i))
		if lane == "boundary_fuzz_lane" {
			fuzzStep = stepID
		}
	}
	// One regexes row so regexes_unmapped does not fire (preliminary_enumeration_lane ran above).
	reg := map[string]any{
		"target_id":   tid,
		"pattern_src": "^[a-z]+$",
		"file":        "src/validate.go",
		"line":        10,
		"role":        "validator",
		"created_at":  "2026-06-01 00:02:30",
	}
	if err := db.Put(ctx, "regexes", []map[string]any{reg}); err != nil {
		t.Fatalf("seedFullyGreenProcessDB(%s): put regex: %v", suffix, err)
	}
	// One fuzz_runs row (with a coverage measurement) for the boundary_fuzz_lane step, so the two
	// fuzz hard-red metrics (fuzz_skips_unrecorded / fuzz_runs_without_coverage_measurement) clear.
	fr := map[string]any{
		"target_id":     tid,
		"agent_step_id": fuzzStep,
		"engine":        "libfuzzer",
		"coverage_json": `{"edges": 1234, "function_coverage": 0.61}`,
		"fuzz_run_hash": "fr-green-" + suffix,
		"created_at":    "2026-06-01 00:02:45",
	}
	if err := db.Put(ctx, "fuzz_runs", []map[string]any{fr}); err != nil {
		t.Fatalf("seedFullyGreenProcessDB(%s): put fuzz_run: %v", suffix, err)
	}
	return tid, fuzzStep
}

// TestGate_GreenPath_NonSPFinding is the HIGH-1 + HIGH-2 acceptance test. It drives the EXACT
// documented sequence on a NON-SP finding (finding_kind='fuzz_crash', no suspicious_points row):
//
//	Put candidate → refutation → critic-OK → vrdb impact-proof → vrdb promote → vrdb gate=GREEN
//
// and asserts the finding reaches JUSTIFIED (v_promotion_coverage + v_justification_coverage) and
// that vrdb gate returns Passed=true. Before HIGH-1/HIGH-2 this was UNREACHABLE: promote wrote no
// impact_proofs row (v_justification_coverage rejected) and v_promotion_coverage cond (d) demanded
// a backing SP a fuzz_crash cannot have.
func TestGate_GreenPath_NonSPFinding(t *testing.T) {
	db, ctx := openTestDB(t)
	tid, fuzzStep := seedFullyGreenProcessDB(t, db, ctx, "nonsp")

	// A NON-SP candidate finding (fuzz_crash) hung off the already-observed boundary_fuzz_lane
	// step — no suspicious_points row, and no NEW step (so no observation gap is introduced).
	fnd := map[string]any{
		"target_id":           tid,
		"agent_step_id":       fuzzStep,
		"finding_kind":        "fuzz_crash",
		"confirmation_status": "candidate",
		"finding_hash":        "fnd-green-nonsp",
	}
	if err := db.Put(ctx, "gr_findings", []map[string]any{fnd}); err != nil {
		t.Fatalf("put candidate finding: %v", err)
	}
	fid := asInt64Test(t, fnd["id"])

	// Steps 2-3: refutation overcome + critic eligibility OK.
	addRefutation(t, db, ctx, fid, fuzzStep, "nonsp")
	addCriticOK(t, db, ctx, fid, "nonsp")

	// Step 4: the Gate-5 CONSUMER-HARM write (impact_proofs). Promote refuses without it.
	if err := db.ImpactProof(ctx, fid, vrdb.ImpactProofOpts{
		ConsumerSymbol:      "Server::parseRequest",
		HarmClass:           "dos",
		ReachabilityEvidRef: "obs:nonsp-13",
		ProvenReachability:  "proven",
		MechanismCap:        "dos_only",
		SeverityBasis:       "dos_only cap ⇒ MEDIUM ceiling; proven reachability on default config",
	}); err != nil {
		t.Fatalf("impact-proof: %v", err)
	}

	// Step 5: promote (severity MEDIUM respects the dos_only ceiling).
	if err := db.Promote(ctx, fid, vrdb.PromoteOpts{Severity: "MEDIUM", RigorTier: "reproduced"}); err != nil {
		t.Fatalf("promote (non-SP green path): %v", err)
	}
	if got := findingStatus(t, db, ctx, fid); got != "confirmed" {
		t.Fatalf("after promote: status=%q, want confirmed", got)
	}

	// v_promotion_coverage JUSTIFIED (HIGH-2: cond (d) satisfied with no backing SP).
	prows, err := db.Fetch(ctx, "SELECT gate_status FROM v_promotion_coverage WHERE finding_id = ?", fid)
	if err != nil || len(prows) != 1 {
		t.Fatalf("v_promotion_coverage: %v (rows=%d)", err, len(prows))
	}
	if gs, _ := prows[0]["gate_status"].(string); gs != "JUSTIFIED" {
		t.Errorf("v_promotion_coverage.gate_status=%q, want JUSTIFIED (non-SP finding must clear cond (d))", gs)
	}
	// v_justification_coverage JUSTIFIED (Gate 5 consumer-harm proof present).
	jrows, err := db.Fetch(ctx, "SELECT justification_status FROM v_justification_coverage WHERE finding_id = ?", fid)
	if err != nil || len(jrows) != 1 {
		t.Fatalf("v_justification_coverage: %v (rows=%d)", err, len(jrows))
	}
	if js, _ := jrows[0]["justification_status"].(string); js != "JUSTIFIED" {
		t.Errorf("v_justification_coverage.justification_status=%q, want JUSTIFIED", js)
	}

	// Step 6: the single-boolean gate must be GREEN.
	gr, err := db.Gate(ctx)
	if err != nil {
		t.Fatalf("Gate: %v", err)
	}
	if !gr.Passed {
		t.Fatalf("HIGH-1 acceptance: documented Put→impact-proof→promote sequence must reach GREEN, "+
			"got Passed=false; reds=%v", gr.Reds)
	}
}

// TestPromote_RefusesWithoutImpactProof pins the HIGH-1 precondition directly: a finding with the
// refutation + critic-OK companions but NO impact_proofs row CANNOT be promoted (the Gate-5
// consumer-harm write is mandatory). It also proves the order matters: after impact-proof, the
// same promote succeeds.
func TestPromote_RefusesWithoutImpactProof(t *testing.T) {
	db, ctx := openTestDB(t)
	fid, sid, _ := seedPromotableFinding(t, db, ctx, "no-proof")
	addRefutation(t, db, ctx, fid, sid, "no-proof")
	addCriticOK(t, db, ctx, fid, "no-proof")
	id := asInt64Test(t, fid)

	err := db.Promote(ctx, id, vrdb.PromoteOpts{Severity: "HIGH", RigorTier: "independent"})
	if err == nil || !strings.Contains(err.Error(), "no impact_proofs row") {
		t.Fatalf("promote without impact_proofs must be refused, got: %v", err)
	}
	if got := findingStatus(t, db, ctx, fid); got != "candidate" {
		t.Errorf("finding flipped despite missing impact_proofs: status=%q, want candidate", got)
	}

	// Write the proof, then the same promote succeeds.
	if err := db.ImpactProof(ctx, id, vrdb.ImpactProofOpts{
		ConsumerSymbol: "Auth::checkRole", HarmClass: "authz_bypass", ProvenReachability: "proven",
	}); err != nil {
		t.Fatalf("impact-proof: %v", err)
	}
	if err := db.Promote(ctx, id, vrdb.PromoteOpts{Severity: "HIGH", RigorTier: "independent"}); err != nil {
		t.Fatalf("promote after impact-proof: %v", err)
	}
	if got := findingStatus(t, db, ctx, fid); got != "confirmed" {
		t.Errorf("after impact-proof + promote: status=%q, want confirmed", got)
	}
}

// TestPromote_RefusesSeverityAboveMechanismCap pins the MED-4 ceiling: a dos_only mechanism_cap
// caps severity at MEDIUM, so a HIGH promote on such a proof is refused; MEDIUM is accepted.
func TestPromote_RefusesSeverityAboveMechanismCap(t *testing.T) {
	db, ctx := openTestDB(t)
	fid, sid, _ := seedPromotableFinding(t, db, ctx, "cap")
	addRefutation(t, db, ctx, fid, sid, "cap")
	addCriticOK(t, db, ctx, fid, "cap")
	id := asInt64Test(t, fid)
	if err := db.ImpactProof(ctx, id, vrdb.ImpactProofOpts{
		ConsumerSymbol: "Parser::read", HarmClass: "dos", MechanismCap: "dos_only",
	}); err != nil {
		t.Fatalf("impact-proof: %v", err)
	}
	if err := db.Promote(ctx, id, vrdb.PromoteOpts{Severity: "HIGH", RigorTier: "independent"}); err == nil ||
		!strings.Contains(err.Error(), "mechanism_cap ceiling") {
		t.Fatalf("HIGH promote on a dos_only-capped proof must be refused, got: %v", err)
	}
	if got := findingStatus(t, db, ctx, fid); got != "candidate" {
		t.Errorf("finding flipped despite over-ceiling severity: status=%q, want candidate", got)
	}
	// MEDIUM is within the dos_only ceiling and succeeds.
	if err := db.Promote(ctx, id, vrdb.PromoteOpts{Severity: "MEDIUM", RigorTier: "independent"}); err != nil {
		t.Fatalf("MEDIUM promote (at the dos_only ceiling) should succeed: %v", err)
	}
}

// TestSelftest_BornRefutedWithoutProvenance pins MED-3: a 'refuted' row with no status_transition
// mutation_log row (an out-of-band flip) fires the symmetric born_refuted_without_provenance
// data-quality FAIL, mirroring the born_confirmed check.
func TestSelftest_BornRefutedWithoutProvenance(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "born-refuted")
	sid := seedStep(t, db, ctx, tid, "forward_slice_lane", "success", nil, "born-refuted")

	// Put the finding legally as 'candidate', then flip it to 'refuted' OUT-OF-BAND via raw SQL
	// (no mutation_log status_transition) — exactly what the symmetric check must catch.
	finding := map[string]any{
		"target_id": tid, "agent_step_id": sid, "finding_kind": "sqli",
		"confirmation_status": "candidate", "finding_hash": "fnd-born-refuted",
	}
	if err := db.Put(ctx, "gr_findings", []map[string]any{finding}); err != nil {
		t.Fatalf("put candidate: %v", err)
	}
	if _, err := db.Exec(ctx,
		"UPDATE gr_findings SET confirmation_status = 'refuted' WHERE finding_hash = ?",
		"fnd-born-refuted"); err != nil {
		t.Fatalf("out-of-band refute flip: %v", err)
	}

	r, err := db.Selftest(ctx, "", "")
	if err != nil {
		t.Fatalf("Selftest: %v", err)
	}
	found := false
	for _, f := range r.Fails {
		if strings.Contains(f, "born_refuted_without_provenance") {
			found = true
		}
	}
	if !found {
		t.Errorf("born_refuted_without_provenance should FAIL for an out-of-band refute, got fails: %v", r.Fails)
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// helpers
// ─────────────────────────────────────────────────────────────────────────────

// asInt64Test coerces a Put-assigned id (int64 from the sequence) to int64 for the verb calls.
func asInt64Test(t *testing.T, v any) int64 {
	t.Helper()
	switch n := v.(type) {
	case int64:
		return n
	case int32:
		return int64(n)
	case int:
		return int64(n)
	case float64:
		return int64(n)
	default:
		t.Fatalf("asInt64Test: unexpected id type %T (%v)", v, v)
		return 0
	}
}

// asBoolTest coerces a DuckDB-scanned boolean (the driver may return bool / int64 / string).
func asBoolTest(v any) bool {
	switch b := v.(type) {
	case bool:
		return b
	case int64:
		return b != 0
	case int32:
		return b != 0
	case string:
		return b == "true" || b == "TRUE" || b == "t"
	default:
		return false
	}
}

// mustN reads the single `n` count column from a one-row result.
func mustN(t *testing.T, rows []map[string]any) int64 {
	t.Helper()
	if len(rows) != 1 {
		t.Fatalf("mustN: expected 1 row, got %d", len(rows))
	}
	switch n := rows[0]["n"].(type) {
	case int64:
		return n
	case int32:
		return int64(n)
	case int:
		return int64(n)
	case float64:
		return int64(n)
	default:
		t.Fatalf("mustN: unexpected count type %T (%v)", rows[0]["n"], rows[0]["n"])
		return 0
	}
}
