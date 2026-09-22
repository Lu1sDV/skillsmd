// vrdb_test.go — black-box tests pinning the put/fetch contract before any production code is written.
// Exists so the orchestrator's single-writer + idempotency invariants are enforced by tests, not by prompt prose.
// Run with `go test ./...` from this dir; each test owns its own DuckDB in t.TempDir() — zero shared state, runnable in parallel.

package vrdb_test

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"
	"testing"

	"vrdb"
)

func openTestDB(t *testing.T) (*vrdb.DB, context.Context) {
	t.Helper()
	dbPath := filepath.Join(t.TempDir(), "audit.duckdb")
	db, err := vrdb.Open(dbPath)
	if err != nil {
		t.Fatalf("Open: %v", err)
	}
	t.Cleanup(func() { _ = db.Close() })
	return db, context.Background()
}

func TestOpen_AppliesSchema(t *testing.T) {
	db, ctx := openTestDB(t)

	rows, err := db.Fetch(ctx, "SELECT version FROM schema_version WHERE version = 1")
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	if len(rows) != 1 {
		t.Fatalf("schema_version not applied: expected 1 row, got %d", len(rows))
	}
}

func TestPut_Targets_InsertOne(t *testing.T) {
	db, ctx := openTestDB(t)

	if err := db.Put(ctx, "targets", []map[string]any{
		{
			"repo_url":   "https://github.com/example/repo",
			"commit_sha": "abc123",
			"language":   "go",
			"scanned_at": "2026-05-17 17:30:00",
		},
	}); err != nil {
		t.Fatalf("Put: %v", err)
	}

	rows, err := db.Fetch(ctx, "SELECT repo_url, commit_sha, language FROM targets")
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	if len(rows) != 1 {
		t.Fatalf("expected 1 row, got %d", len(rows))
	}
	if got, want := rows[0]["repo_url"], "https://github.com/example/repo"; got != want {
		t.Fatalf("repo_url: got %v, want %v", got, want)
	}
}

// TestPut_Targets_IdempotentOnNaturalKey replays the same (repo_url, commit_sha) twice and
// asserts the second Put is a no-op — proving the harness honours the UNIQUE natural key
// via ON CONFLICT DO NOTHING. This is the single-writer + replay-safe invariant the
// orchestrator depends on when re-flushing a row event after a crash.
func TestPut_Targets_IdempotentOnNaturalKey(t *testing.T) {
	db, ctx := openTestDB(t)

	for i := 0; i < 2; i++ {
		// fresh map each iteration — Put assigns `id` in place, and a stale id would force
		// a PK conflict (not the NK conflict we want to exercise).
		row := map[string]any{
			"repo_url":   "https://github.com/example/repo",
			"commit_sha": "abc123",
			"language":   "go",
			"scanned_at": "2026-05-17 17:30:00",
		}
		if err := db.Put(ctx, "targets", []map[string]any{row}); err != nil {
			t.Fatalf("Put attempt %d: %v", i+1, err)
		}
	}

	rows, err := db.Fetch(ctx, "SELECT COUNT(*) AS n FROM targets")
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	if got := fmt.Sprintf("%v", rows[0]["n"]); got != "1" {
		t.Fatalf("expected exactly 1 row after replay, got %s", got)
	}
}

// TestPut_CriticalFunctions_IdempotentOnHash exercises the schema-v2 critical_functions
// table end to end: it must be in the Put allowlist, the cf_category / rank_tier CHECK
// enums must accept the seeded values, and replaying the same cf_hash must be a no-op.
// This pins the harness side of the critical-function registry (Ask 3 / Ask 4).
func TestPut_CriticalFunctions_IdempotentOnHash(t *testing.T) {
	db, ctx := openTestDB(t)

	tgt := map[string]any{
		"repo_url":   "https://github.com/example/cf",
		"commit_sha": "deadbeef",
		"language":   "go",
		"scanned_at": "2026-05-21 21:00:00",
	}
	if err := db.Put(ctx, "targets", []map[string]any{tgt}); err != nil {
		t.Fatalf("Put target: %v", err)
	}
	targetID := tgt["id"] // Put assigns id in place.

	for i := 0; i < 2; i++ {
		row := map[string]any{
			"target_id":   targetID,
			"symbol_path": "pkg/auth.CheckToken",
			"cf_category": "auth_check",
			"rank_tier":   "tier1",
			"cf_hash":     "cf-abc123",
		}
		if err := db.Put(ctx, "critical_functions", []map[string]any{row}); err != nil {
			t.Fatalf("Put critical_functions attempt %d: %v", i+1, err)
		}
	}

	rows, err := db.Fetch(ctx, "SELECT cf_category, rank_tier FROM critical_functions WHERE cf_hash = ?", "cf-abc123")
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	if len(rows) != 1 {
		t.Fatalf("expected exactly 1 critical_functions row after replay, got %d", len(rows))
	}
	if got, want := rows[0]["cf_category"], "auth_check"; got != want {
		t.Fatalf("cf_category: got %v, want %v", got, want)
	}
}

// TestPut_FuzzRuns_LaneAccounting exercises the Phase 1.5 fuzzing lane table
// (Tier 3 dynamic discovery): it must be in the Put allowlist, accept both a
// real run (engine + sanitizers + coverage) and a skip-with-reason run
// (engine='none', entry_point NULL), and replaying the same fuzz_run_hash must
// be a no-op. This pins the harness side of the mandatory-attempt accounting.
// The lane logs under strategy 'boundary_fuzz_lane' (id 10), kept DISTINCT from
// the defense-isolation 'isolation_fuzz_lane' (id 5) so the two fuzzing purposes
// never conflate — this test asserts that separation (references/v2/fuzzing-lane.md).
func TestPut_FuzzRuns_LaneAccounting(t *testing.T) {
	db, ctx := openTestDB(t)

	tgt := map[string]any{
		"repo_url":   "https://github.com/example/fuzz",
		"commit_sha": "f00dcafe",
		"language":   "c",
		"scanned_at": "2026-05-21 23:00:00",
	}
	if err := db.Put(ctx, "targets", []map[string]any{tgt}); err != nil {
		t.Fatalf("Put target: %v", err)
	}

	step := map[string]any{
		"target_id":   tgt["id"],
		"strategy_id": 10, // boundary_fuzz_lane — Phase 1.5, distinct from isolation_fuzz_lane (id 5)
		"started_at":  "2026-05-21 23:00:01",
		"status":      "success",
		"step_hash":   "step-fuzz-1",
	}
	if err := db.Put(ctx, "agent_steps", []map[string]any{step}); err != nil {
		t.Fatalf("Put agent_step: %v", err)
	}

	real := map[string]any{
		"target_id":                tgt["id"],
		"agent_step_id":            step["id"],
		"entry_point":              "png_read_chunk",
		"engine":                   "libfuzzer",
		"sanitizers":               `["asan","ubsan"]`,
		"reused_existing_pipeline": false,
		"coverage_json":            `{"surface":"png parser","attempted":["IHDR","IDAT"],"edges":1842,"runtime_s":300}`,
		"crash_count":              0,
		"fuzz_run_hash":            "fr-real-1",
	}
	skip := map[string]any{
		"target_id":     tgt["id"],
		"agent_step_id": step["id"],
		"engine":        "none",
		"sanitizers":    "[]",
		"skip_reason":   "interpreted_only",
		"coverage_json": `{"surface":"pure-python service","reason":"no native code or FFI"}`,
		"fuzz_run_hash": "fr-skip-1",
	}
	if err := db.Put(ctx, "fuzz_runs", []map[string]any{real, skip}); err != nil {
		t.Fatalf("Put fuzz_runs: %v", err)
	}

	// Replay the real run via a fresh map (no id) so ON CONFLICT (fuzz_run_hash)
	// — not a PK conflict — is what makes it a no-op.
	replay := map[string]any{
		"target_id":     tgt["id"],
		"agent_step_id": step["id"],
		"entry_point":   "png_read_chunk",
		"engine":        "libfuzzer",
		"fuzz_run_hash": "fr-real-1",
	}
	if err := db.Put(ctx, "fuzz_runs", []map[string]any{replay}); err != nil {
		t.Fatalf("Put fuzz_runs replay: %v", err)
	}

	rows, err := db.Fetch(ctx, "SELECT COUNT(*) AS n FROM fuzz_runs")
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	if got := fmt.Sprintf("%v", rows[0]["n"]); got != "2" {
		t.Fatalf("expected exactly 2 fuzz_runs rows after replay, got %s", got)
	}

	skipRows, err := db.Fetch(ctx, "SELECT engine, skip_reason FROM fuzz_runs WHERE fuzz_run_hash = ?", "fr-skip-1")
	if err != nil {
		t.Fatalf("Fetch skip: %v", err)
	}
	if got, want := skipRows[0]["engine"], "none"; got != want {
		t.Fatalf("skip engine: got %v, want %v", got, want)
	}

	// Non-conflation: the run's agent_step resolves to boundary_fuzz_lane, never
	// the defense-isolation isolation_fuzz_lane. This is the schema-level guarantee
	// behind "Phase 1.5 is a distinct lane" (references/v2/fuzzing-lane.md § lane identity).
	laneRows, err := db.Fetch(ctx, `
		SELECT s.name FROM fuzz_runs f
		JOIN agent_steps a ON a.id = f.agent_step_id
		JOIN strategies  s ON s.id = a.strategy_id
		WHERE f.fuzz_run_hash = ?`, "fr-real-1")
	if err != nil {
		t.Fatalf("Fetch lane: %v", err)
	}
	if got, want := laneRows[0]["name"], "boundary_fuzz_lane"; got != want {
		t.Fatalf("fuzz run logged under wrong strategy: got %v, want %v", got, want)
	}
}

// TestExec verifies that DB.Exec runs DML and reports rows affected correctly.
func TestExec(t *testing.T) {
	db, ctx := openTestDB(t)

	// Insert a target via Put so we have a row to UPDATE.
	row := map[string]any{
		"repo_url":   "https://github.com/example/exec-test",
		"commit_sha": "exec001",
		"language":   "go",
		"scanned_at": "2026-05-22 10:00:00",
	}
	if err := db.Put(ctx, "targets", []map[string]any{row}); err != nil {
		t.Fatalf("Put: %v", err)
	}

	// UPDATE the language field; should affect exactly 1 row.
	n, err := db.Exec(ctx, "UPDATE targets SET language = ? WHERE commit_sha = ?", "rust", "exec001")
	if err != nil {
		t.Fatalf("Exec UPDATE: %v", err)
	}
	if n != 1 {
		t.Fatalf("rows affected: got %d, want 1", n)
	}

	// Confirm the change took effect.
	rows, err := db.Fetch(ctx, "SELECT language FROM targets WHERE commit_sha = ?", "exec001")
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	if len(rows) != 1 {
		t.Fatalf("expected 1 row, got %d", len(rows))
	}
	if got, want := rows[0]["language"], "rust"; got != want {
		t.Fatalf("language after UPDATE: got %v, want %v", got, want)
	}
}

// TestPutFKValidation verifies that Put rejects rows with non-existent FK values
// (FK id-space mismatch) and accepts rows with valid parent ids or sentinel 0/NULL.
func TestPutFKValidation(t *testing.T) {
	db, ctx := openTestDB(t)

	// --- Set up a valid target so we can build the chain ---
	tgt := map[string]any{
		"repo_url":   "https://github.com/example/fk-val",
		"commit_sha": "fkval001",
		"language":   "go",
		"scanned_at": "2026-05-22 11:00:00",
	}
	if err := db.Put(ctx, "targets", []map[string]any{tgt}); err != nil {
		t.Fatalf("Put target: %v", err)
	}
	targetID := tgt["id"]

	// --- Set up a valid strategy for agent_steps ---
	// Strategy id=1 (forward_slice_lane) is seeded by schema; use it directly.

	// 1. Put with a non-existent target_id must fail with FK id-space mismatch.
	badStep := map[string]any{
		"target_id":   int64(999999),
		"strategy_id": 1,
		"started_at":  "2026-05-22 11:00:01",
		"status":      "success",
		"step_hash":   "step-bad-fk",
	}
	err := db.Put(ctx, "agent_steps", []map[string]any{badStep})
	if err == nil {
		t.Fatal("Put with non-existent target_id: expected error, got nil")
	}
	if !strings.Contains(err.Error(), "FK id-space mismatch") {
		t.Fatalf("error should contain 'FK id-space mismatch', got: %v", err)
	}

	// 2. Put with a valid target_id must succeed.
	goodStep := map[string]any{
		"target_id":   targetID,
		"strategy_id": 1,
		"started_at":  "2026-05-22 11:00:02",
		"status":      "success",
		"step_hash":   "step-good-fk",
	}
	if err := db.Put(ctx, "agent_steps", []map[string]any{goodStep}); err != nil {
		t.Fatalf("Put with valid target_id: %v", err)
	}

	// 3. Put with target_id = 0 (sentinel) must NOT be rejected.
	// We use sources which has target_id FK; target_id=0 should pass the sentinel skip.
	sentinelRow := map[string]any{
		"target_id":   int64(0),
		"source_kind": "http_param",
		"symbol_path": "handler.Query",
	}
	// This will fail at the DB level (FK constraint) if it reaches the INSERT,
	// but must NOT be rejected by our FK pre-validation (sentinel skip applies).
	// We only care that the error is NOT the "FK id-space mismatch" error.
	err = db.Put(ctx, "sources", []map[string]any{sentinelRow})
	if err != nil && strings.Contains(err.Error(), "FK id-space mismatch") {
		t.Fatalf("sentinel 0 should not trigger FK id-space mismatch, got: %v", err)
	}

	// 4. Put with target_id = nil (SQL NULL) must NOT be rejected by pre-validation.
	nullRow := map[string]any{
		"target_id":   nil,
		"source_kind": "http_param",
		"symbol_path": "handler.Query2",
	}
	err = db.Put(ctx, "sources", []map[string]any{nullRow})
	if err != nil && strings.Contains(err.Error(), "FK id-space mismatch") {
		t.Fatalf("nil/NULL FK should not trigger FK id-space mismatch, got: %v", err)
	}
}

// seedFinding inserts the target -> agent_step -> gr_findings chain that a
// finding_sightings row needs (the sighting FKs gr_findings.finding_hash),
// returning the target id Put assigned in place.
func seedFinding(t *testing.T, db *vrdb.DB, ctx context.Context, findingHash string) any {
	t.Helper()
	tgt := map[string]any{
		"repo_url": "https://github.com/example/" + findingHash, "commit_sha": "c0",
		"language": "go", "scanned_at": "2026-05-22 08:00:00",
	}
	if err := db.Put(ctx, "targets", []map[string]any{tgt}); err != nil {
		t.Fatalf("Put target: %v", err)
	}
	step := map[string]any{
		"target_id": tgt["id"], "strategy_id": 1, "started_at": "2026-05-22 08:00:01",
		"status": "success", "step_hash": "step-" + findingHash,
	}
	if err := db.Put(ctx, "agent_steps", []map[string]any{step}); err != nil {
		t.Fatalf("Put agent_step: %v", err)
	}
	fnd := map[string]any{
		"target_id": tgt["id"], "agent_step_id": step["id"], "finding_kind": "sqli",
		"confirmation_status": "candidate", "finding_hash": findingHash,
	}
	if err := db.Put(ctx, "gr_findings", []map[string]any{fnd}); err != nil {
		t.Fatalf("Put gr_findings: %v", err)
	}
	return tgt["id"]
}

// TestPut_FindingSightings_MultiCommitOneHash pins #1 (finding-identity): one
// commit-independent finding_hash accrues one append-only sighting per commit, a
// moved-body sighting carries change_scope (surfaced by v_finding_changes), and
// replaying a sighting_hash via a fresh map is a no-op (ON CONFLICT on the NK).
func TestPut_FindingSightings_MultiCommitOneHash(t *testing.T) {
	db, ctx := openTestDB(t)
	tgtID := seedFinding(t, db, ctx, "fnd-1")

	initial := map[string]any{
		"finding_hash": "fnd-1", "target_id": tgtID, "commit_sha": "aaaa",
		"body_hash": "b1", "slice_fingerprint": "s1", "verdict": "confirmed",
		"change_scope": "initial", "sighting_hash": "sg-1",
	}
	moved := map[string]any{
		"finding_hash": "fnd-1", "target_id": tgtID, "commit_sha": "bbbb",
		"body_hash": "b2", "slice_fingerprint": "s1", "verdict": "needs_attention",
		"change_scope": "body_hash", "from_commit_sha": "aaaa", "from_body_hash": "b1",
		"from_slice_fingerprint": "s1", "sighting_hash": "sg-2",
	}
	if err := db.Put(ctx, "finding_sightings", []map[string]any{initial, moved}); err != nil {
		t.Fatalf("Put finding_sightings: %v", err)
	}
	replay := map[string]any{
		"finding_hash": "fnd-1", "target_id": tgtID, "commit_sha": "aaaa",
		"verdict": "confirmed", "change_scope": "initial", "sighting_hash": "sg-1",
	}
	if err := db.Put(ctx, "finding_sightings", []map[string]any{replay}); err != nil {
		t.Fatalf("Put finding_sightings replay: %v", err)
	}

	rows, err := db.Fetch(ctx, "SELECT COUNT(*) AS n FROM finding_sightings WHERE finding_hash = ?", "fnd-1")
	if err != nil {
		t.Fatalf("Fetch count: %v", err)
	}
	if got := fmt.Sprintf("%v", rows[0]["n"]); got != "2" {
		t.Fatalf("expected 2 sightings for one finding_hash after replay, got %s", got)
	}

	chg, err := db.Fetch(ctx, "SELECT change_scope FROM v_finding_changes WHERE finding_hash = ?", "fnd-1")
	if err != nil {
		t.Fatalf("Fetch v_finding_changes: %v", err)
	}
	if len(chg) != 1 {
		t.Fatalf("v_finding_changes: expected 1 moved sighting (initial excluded), got %d", len(chg))
	}
	if got, want := chg[0]["change_scope"], "body_hash"; got != want {
		t.Fatalf("change_scope: got %v, want %v", got, want)
	}
}

// TestView_CriticalFnRanked_ExternalizedWeights pins #4: rank_score is recomputed
// read-time from the six factors x scoring_config weights, so changing a weight in
// the config table reorders results with NO code change (determinism by
// construction, no inline magic constant).
func TestView_CriticalFnRanked_ExternalizedWeights(t *testing.T) {
	db, ctx := openTestDB(t)
	tgt := map[string]any{
		"repo_url": "https://github.com/example/rank", "commit_sha": "r0",
		"language": "go", "scanned_at": "2026-05-22 08:00:00",
	}
	if err := db.Put(ctx, "targets", []map[string]any{tgt}); err != nil {
		t.Fatalf("Put target: %v", err)
	}
	// cfReach scores only on reachability; cfRecur only on recurrence. Default
	// weights (w_reachability 0.25 > w_recurrence_prior 0.12) rank cfReach top.
	cfReach := map[string]any{
		"target_id": tgt["id"], "symbol_path": "pkg.Reach", "cf_category": "auth_check",
		"factor_reachability": 1.0, "factor_recurrence_prior": 0.0, "cf_hash": "cf-reach",
	}
	cfRecur := map[string]any{
		"target_id": tgt["id"], "symbol_path": "pkg.Recur", "cf_category": "auth_check",
		"factor_reachability": 0.0, "factor_recurrence_prior": 1.0, "cf_hash": "cf-recur",
	}
	if err := db.Put(ctx, "critical_functions", []map[string]any{cfReach, cfRecur}); err != nil {
		t.Fatalf("Put critical_functions: %v", err)
	}

	top, err := db.Fetch(ctx, "SELECT symbol_path FROM v_critical_fn_ranked ORDER BY rank_score_computed DESC LIMIT 1")
	if err != nil {
		t.Fatalf("Fetch ranked (default): %v", err)
	}
	if got, want := top[0]["symbol_path"], "pkg.Reach"; got != want {
		t.Fatalf("default weights: top CF got %v, want %v", got, want)
	}

	// Externalize the knob: make recurrence dominate. The view must reorder, no recompile.
	if _, err := db.SQL().ExecContext(ctx,
		"UPDATE scoring_config SET weight = 0.90 WHERE scope = 'rank_score' AND config_key = 'w_recurrence_prior'"); err != nil {
		t.Fatalf("bump w_recurrence_prior: %v", err)
	}
	top, err = db.Fetch(ctx, "SELECT symbol_path FROM v_critical_fn_ranked ORDER BY rank_score_computed DESC LIMIT 1")
	if err != nil {
		t.Fatalf("Fetch ranked (reweighted): %v", err)
	}
	if got, want := top[0]["symbol_path"], "pkg.Recur"; got != want {
		t.Fatalf("after reweight: top CF got %v, want %v (weight change did not reorder)", got, want)
	}
}

// TestPut_WeaknessClasses_SystemicGeneratedFlag pins #3 (3a): `systemic` is a
// same-row GENERATED column flipping at seen_count >= 3 — a passive descriptive
// flag computed by the DB, never written by a caller.
func TestPut_WeaknessClasses_SystemicGeneratedFlag(t *testing.T) {
	db, ctx := openTestDB(t)
	tgt := map[string]any{
		"repo_url": "https://github.com/example/wc", "commit_sha": "w0",
		"language": "go", "scanned_at": "2026-05-22 08:00:00",
	}
	if err := db.Put(ctx, "targets", []map[string]any{tgt}); err != nil {
		t.Fatalf("Put target: %v", err)
	}
	below := map[string]any{
		"target_id": tgt["id"], "bug_class": "sqli", "sink_category": "db_query",
		"seen_count": 2, "wc_hash": "wc-below",
	}
	systemic := map[string]any{
		"target_id": tgt["id"], "bug_class": "xss", "sink_category": "html_sink",
		"seen_count": 3, "wc_hash": "wc-systemic",
	}
	if err := db.Put(ctx, "weakness_classes", []map[string]any{below, systemic}); err != nil {
		t.Fatalf("Put weakness_classes: %v", err)
	}
	rows, err := db.Fetch(ctx, "SELECT wc_hash, systemic FROM weakness_classes ORDER BY wc_hash")
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	got := map[string]string{}
	for _, r := range rows {
		got[fmt.Sprintf("%v", r["wc_hash"])] = fmt.Sprintf("%v", r["systemic"])
	}
	if got["wc-below"] != "false" {
		t.Fatalf("seen_count=2 should not be systemic, got %s", got["wc-below"])
	}
	if got["wc-systemic"] != "true" {
		t.Fatalf("seen_count=3 should be systemic, got %s", got["wc-systemic"])
	}
}

// TestView_FindingHistory_UnifiesSightingsAndMutations pins #6: v_finding_history
// interleaves a finding's sightings with its gr_findings mutation_log rows into one
// per-finding timeline (the surface `vrdb history` reads).
func TestView_FindingHistory_UnifiesSightingsAndMutations(t *testing.T) {
	db, ctx := openTestDB(t)
	tgtID := seedFinding(t, db, ctx, "fnd-h")

	sight := map[string]any{
		"finding_hash": "fnd-h", "target_id": tgtID, "commit_sha": "aaaa",
		"verdict": "candidate", "change_scope": "initial", "sighting_hash": "sgh-1",
	}
	if err := db.Put(ctx, "finding_sightings", []map[string]any{sight}); err != nil {
		t.Fatalf("Put sighting: %v", err)
	}
	mut := map[string]any{
		"target_id": tgtID, "table_name": "gr_findings", "row_key": "fnd-h",
		"op":         "status_transition",
		"delta_json": `{"col":"confirmation_status","before":"candidate","after":"confirmed"}`,
		"mutation_hash": "mut-1",
	}
	if err := db.Put(ctx, "mutation_log", []map[string]any{mut}); err != nil {
		t.Fatalf("Put mutation_log: %v", err)
	}

	rows, err := db.Fetch(ctx, "SELECT event_kind FROM v_finding_history WHERE finding_hash = ? ORDER BY event_kind", "fnd-h")
	if err != nil {
		t.Fatalf("Fetch v_finding_history: %v", err)
	}
	if len(rows) != 2 {
		t.Fatalf("expected 2 timeline events (1 sighting + 1 mutation), got %d", len(rows))
	}
	if got, want := rows[0]["event_kind"], "mutation"; got != want {
		t.Fatalf("first event_kind: got %v, want %v", got, want)
	}
	if got, want := rows[1]["event_kind"], "sighting"; got != want {
		t.Fatalf("second event_kind: got %v, want %v", got, want)
	}
}

// TestPut_QueryAttempts_RoundTripAndIdempotent exercises the LLMxCPG CPGQL
// query-generation feedback loop table (migration 0015) end to end: it must be in
// the Put allowlist, accept a valid FK chain target -> agent_step -> input_slices
// (the execution_path slice the loop isolates), round-trip status/attempt_no, and
// replaying the same natural key (target_id, agent_step_id, attempt_no) via a fresh
// map must be a no-op (ON CONFLICT, not a PK conflict). This pins the harness side
// of the bounded generate->run->feedback->retry≤3->dead_end loop (arXiv:2507.16585).
func TestPut_QueryAttempts_RoundTripAndIdempotent(t *testing.T) {
	db, ctx := openTestDB(t)

	tgt := map[string]any{
		"repo_url":   "https://github.com/example/llmxcpg",
		"commit_sha": "cpg0001",
		"language":   "java",
		"scanned_at": "2026-05-29 13:00:00",
	}
	if err := db.Put(ctx, "targets", []map[string]any{tgt}); err != nil {
		t.Fatalf("Put target: %v", err)
	}

	// A source to anchor the execution_path slice on (source-anchored slice_kind).
	src := map[string]any{
		"target_id":   tgt["id"],
		"source_kind": "http_param",
		"symbol_path": "Controller.handle",
	}
	if err := db.Put(ctx, "sources", []map[string]any{src}); err != nil {
		t.Fatalf("Put source: %v", err)
	}

	step := map[string]any{
		"target_id":   tgt["id"],
		"strategy_id": 1, // forward_slice_lane — seeded by schema
		"started_at":  "2026-05-29 13:00:01",
		"status":      "success",
		"step_hash":   "step-cpg-1",
	}
	if err := db.Put(ctx, "agent_steps", []map[string]any{step}); err != nil {
		t.Fatalf("Put agent_step: %v", err)
	}

	// The execution_path slice the successful attempt mints (schema v15 slice_kind).
	slice := map[string]any{
		"target_id":       tgt["id"],
		"source_id":       src["id"],
		"callee_set_hash": "callees-cpg-1",
		"slice_kind":      "execution_path",
		"callee_count":    3,
	}
	if err := db.Put(ctx, "input_slices", []map[string]any{slice}); err != nil {
		t.Fatalf("Put input_slices (execution_path): %v", err)
	}

	// A syntax_error attempt with no slice (precedes a successful slice), then the
	// valid attempt that minted the slice above.
	bad := map[string]any{
		"target_id":     tgt["id"],
		"agent_step_id": step["id"],
		"attempt_no":    1,
		"query_text":    "cpg.method(name=\"handle\".reachableBy(", // malformed CPGQL
		"status":        "syntax_error",
		"joern_error":   "unexpected EOF: unbalanced parenthesis",
		"created_at":    "2026-05-29 13:00:02",
		"attempt_hash":  "qa-bad-1",
	}
	good := map[string]any{
		"target_id":     tgt["id"],
		"agent_step_id": step["id"],
		"slice_id":      slice["id"],
		"attempt_no":    2,
		"query_text":    "cpg.parameter.reachableBy(cpg.call(\"exec\"))",
		"status":        "valid",
		"created_at":    "2026-05-29 13:00:03",
		"attempt_hash":  "qa-good-1",
	}
	if err := db.Put(ctx, "query_attempts", []map[string]any{bad, good}); err != nil {
		t.Fatalf("Put query_attempts: %v", err)
	}

	// Round-trip: fetch the valid attempt back and assert status + attempt_no.
	rows, err := db.Fetch(ctx, "SELECT status, attempt_no FROM query_attempts WHERE attempt_hash = ?", "qa-good-1")
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	if len(rows) != 1 {
		t.Fatalf("expected 1 query_attempts row, got %d", len(rows))
	}
	if got, want := rows[0]["status"], "valid"; got != want {
		t.Fatalf("status: got %v, want %v", got, want)
	}
	if got := fmt.Sprintf("%v", rows[0]["attempt_no"]); got != "2" {
		t.Fatalf("attempt_no: got %s, want 2", got)
	}

	// Idempotency on the natural key (target_id, agent_step_id, attempt_no): replay
	// the valid attempt via a fresh map (no id, distinct attempt_hash so the NK — not
	// attempt_hash — is what makes it a no-op) and assert the row count is unchanged.
	replay := map[string]any{
		"target_id":     tgt["id"],
		"agent_step_id": step["id"],
		"attempt_no":    2,
		"query_text":    "cpg.parameter.reachableBy(cpg.call(\"exec\"))",
		"status":        "valid",
		"created_at":    "2026-05-29 13:00:04",
		"attempt_hash":  "qa-good-1-replay",
	}
	if err := db.Put(ctx, "query_attempts", []map[string]any{replay}); err != nil {
		t.Fatalf("Put query_attempts replay: %v", err)
	}
	countRows, err := db.Fetch(ctx, "SELECT COUNT(*) AS n FROM query_attempts")
	if err != nil {
		t.Fatalf("Fetch count: %v", err)
	}
	if got := fmt.Sprintf("%v", countRows[0]["n"]); got != "2" {
		t.Fatalf("expected exactly 2 query_attempts rows after NK replay, got %s", got)
	}
}
