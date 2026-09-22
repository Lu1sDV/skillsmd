// db_test.go — integration tests for the DB-backed flows: ImportCorpus, EmitManifest, Ingest,
// ScoreManifest. Each test builds its own DuckDB(s) in t.TempDir() with synthetic fixtures — no real
// benchmark — and asserts the eval_* rows the flow produces round-trip and score as hand-computed.

package eval

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"vrdb"
)

func openTempDB(t *testing.T, name string) *vrdb.DB {
	t.Helper()
	db, err := vrdb.Open(filepath.Join(t.TempDir(), name))
	if err != nil {
		t.Fatalf("Open %s: %v", name, err)
	}
	t.Cleanup(func() { _ = db.Close() })
	return db
}

func TestImportCorpus_RoundTrip(t *testing.T) {
	ctx := context.Background()
	db := openTempDB(t, "eval.duckdb")

	jsonl := `{"source":"cvefixes","cve_id":"CVE-2021-0001","repo_url":"https://github.com/x/a","vuln_commit":"v1","fix_commit":"f1","primary_cwe":"CWE-89","language":"go","ground_truth":[{"file":"a.go","line_start":10,"line_end":20,"cwe":"CWE-89","is_primary":true}]}

{"source":"vul4j","cve_id":"CVE-2021-0002","repo_url":"https://github.com/x/b","vuln_commit":"v2","fix_commit":"f2","primary_cwe":"CWE-79","language":"java","ground_truth":[{"file":"B.java","line_start":5,"line_end":5,"cwe":"CWE-79","is_primary":true}]}
`
	path := filepath.Join(t.TempDir(), "corpus.jsonl")
	if err := os.WriteFile(path, []byte(jsonl), 0o644); err != nil {
		t.Fatalf("write jsonl: %v", err)
	}

	n, err := ImportCorpus(ctx, db, path)
	if err != nil {
		t.Fatalf("ImportCorpus: %v", err)
	}
	if n != 2 {
		t.Fatalf("imported %d, want 2 (blank line must be skipped)", n)
	}

	rows, err := db.Fetch(ctx, "SELECT cve_id, ground_truth_json FROM eval_corpus WHERE cve_id = ?", "CVE-2021-0001")
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	if len(rows) != 1 {
		t.Fatalf("expected 1 row, got %d", len(rows))
	}
	var gts []GroundTruth
	if err := json.Unmarshal([]byte(asString(rows[0]["ground_truth_json"])), &gts); err != nil {
		t.Fatalf("ground_truth_json did not round-trip: %v", err)
	}
	if len(gts) != 1 || gts[0].File != "a.go" || gts[0].LineStart != 10 || !gts[0].IsPrimary {
		t.Fatalf("ground truth round-trip mismatch: %+v", gts)
	}
}

func TestEmitManifest_Deterministic(t *testing.T) {
	ctx := context.Background()
	db := openTempDB(t, "eval.duckdb")
	seedCorpus(t, ctx, db, 1, "CVE-A", "https://github.com/x/a", "va", "fa", "CWE-89", `[{"file":"a.go","line_start":10,"line_end":20,"cwe":"CWE-89","is_primary":true}]`)
	seedCorpus(t, ctx, db, 2, "CVE-B", "https://github.com/x/b", "vb", "fb", "CWE-79", `[{"file":"b.go","line_start":5,"line_end":5,"cwe":"CWE-79","is_primary":true}]`)

	out1 := filepath.Join(t.TempDir(), "m1.json")
	uid1, items1, err := EmitManifest(ctx, db, []int{2, 1}, "deep", 2, out1, "", false)
	if err != nil {
		t.Fatalf("EmitManifest: %v", err)
	}
	// 2 corpora x 2 modes x 2 seeds = 8 items.
	if len(items1) != 8 {
		t.Fatalf("expected 8 items, got %d", len(items1))
	}

	// Re-emit with reordered ids + same args -> same uid (sorted canonicalization).
	out2 := filepath.Join(t.TempDir(), "m2.json")
	uid2, _, err := EmitManifest(ctx, db, []int{1, 2}, "deep", 2, out2, "", false)
	if err != nil {
		t.Fatalf("EmitManifest re-emit: %v", err)
	}
	if uid1 != uid2 {
		t.Fatalf("uid not deterministic: %s vs %s", uid1, uid2)
	}

	// Different args -> different uid.
	uid3, _, err := EmitManifest(ctx, db, []int{1, 2}, "low", 2, filepath.Join(t.TempDir(), "m3.json"), "", false)
	if err != nil {
		t.Fatalf("EmitManifest tier change: %v", err)
	}
	if uid3 == uid1 {
		t.Fatal("uid should change when tier changes")
	}

	// Commit picks vuln_commit vs fix_commit by mode.
	for _, it := range items1 {
		var wantCommit string
		switch {
		case it.CorpusID == 1 && it.Mode == "vuln":
			wantCommit = "va"
		case it.CorpusID == 1 && it.Mode == "control":
			wantCommit = "fa"
		case it.CorpusID == 2 && it.Mode == "vuln":
			wantCommit = "vb"
		case it.CorpusID == 2 && it.Mode == "control":
			wantCommit = "fb"
		}
		if it.Commit != wantCommit {
			t.Errorf("corpus %d mode %s: commit %q, want %q", it.CorpusID, it.Mode, it.Commit, wantCommit)
		}
	}

	// Manifest file is valid JSON with the uid embedded.
	buf, err := os.ReadFile(out1)
	if err != nil {
		t.Fatalf("read manifest: %v", err)
	}
	var parsed struct {
		ManifestUID string         `json:"manifest_uid"`
		Items       []ManifestItem `json:"items"`
	}
	if err := json.Unmarshal(buf, &parsed); err != nil {
		t.Fatalf("manifest not valid JSON: %v", err)
	}
	if parsed.ManifestUID != uid1 || len(parsed.Items) != 8 {
		t.Fatalf("manifest file mismatch: uid=%s items=%d", parsed.ManifestUID, len(parsed.Items))
	}
}

func TestIngest_ResolvesSinkFirstAndCWE(t *testing.T) {
	ctx := context.Background()
	evalDB := openTempDB(t, "eval.duckdb")
	produced := openTempDB(t, "produced.duckdb")

	// eval_run.corpus_id FK requires the corpus row to exist in evalDB first.
	seedCorpus(t, ctx, evalDB, 7, "CVE-7", "https://github.com/x/a", "va", "fa", "CWE-89", `[{"file":"src/dao.go","line_start":140,"line_end":145,"cwe":"CWE-89","is_primary":true}]`)

	// Build a synthetic produced audit: target -> source + sink -> agent_step -> finding.
	tgtID := putReturningID(t, ctx, produced, "targets", map[string]any{
		"repo_url": "https://github.com/x/a", "commit_sha": "va", "language": "go", "scanned_at": "2026-05-21 00:00:00",
	})
	sinkID := putReturningID(t, ctx, produced, "sinks", map[string]any{
		"target_id": tgtID, "sink_category": "sqli", "symbol_path": "db.Query",
		"evidence_path": "src/dao.go", "evidence_line": 142,
	})
	srcID := putReturningID(t, ctx, produced, "sources", map[string]any{
		"target_id": tgtID, "source_kind": "http_param", "symbol_path": "r.FormValue",
		"evidence_path": "src/handler.go", "evidence_line": 30,
	})
	stepID := putReturningID(t, ctx, produced, "agent_steps", map[string]any{
		"target_id": tgtID, "strategy_id": 1, "started_at": "2026-05-21 00:00:01",
		"status": "success", "step_hash": "step-1",
	})
	// Finding with both sink + source: must resolve SINK-first (src/dao.go:142).
	// NOTE: status is 'candidate' (not 'confirmed') because the born-confirmed lockout
	// (T3-02) forbids Put-ing a 'confirmed' row — promotion is via the `vrdb promote`
	// verb. Ingest reads confirmation_status verbatim; this test asserts SINK-first
	// LOCATION resolution, which is independent of the status value.
	mustPut(t, ctx, produced, "gr_findings", map[string]any{
		"target_id": tgtID, "sink_id": sinkID, "source_id": srcID, "agent_step_id": stepID,
		"finding_kind": "sqli", "confirmation_status": "candidate", "severity": "HIGH",
		"finding_hash": "fh-sink",
	})
	// Finding with only a source: must fall back to the source location.
	mustPut(t, ctx, produced, "gr_findings", map[string]any{
		"target_id": tgtID, "source_id": srcID, "agent_step_id": stepID,
		"finding_kind": "xss", "confirmation_status": "candidate",
		"finding_hash": "fh-src",
	})

	if err := Ingest(ctx, evalDB, produced, "uid-1", 7, 0, "vuln", "deep", 1.5); err != nil {
		t.Fatalf("Ingest: %v", err)
	}

	rows, err := evalDB.Fetch(ctx, "SELECT findings_json, tier, kloc_scanned FROM eval_run WHERE manifest_uid = ?", "uid-1")
	if err != nil {
		t.Fatalf("Fetch eval_run: %v", err)
	}
	if len(rows) != 1 {
		t.Fatalf("expected 1 eval_run, got %d", len(rows))
	}
	var findings []Finding
	if err := json.Unmarshal([]byte(asString(rows[0]["findings_json"])), &findings); err != nil {
		t.Fatalf("findings_json parse: %v", err)
	}
	if len(findings) != 2 {
		t.Fatalf("expected 2 findings, got %d", len(findings))
	}
	byHash := map[string]Finding{}
	for _, f := range findings {
		byHash[f.Hash] = f
	}
	sink := byHash["fh-sink"]
	if sink.File != "src/dao.go" || sink.Line != 142 || sink.CWE != "CWE-89" {
		t.Errorf("sink-first finding wrong: %+v (want src/dao.go:142 CWE-89)", sink)
	}
	src := byHash["fh-src"]
	if src.File != "src/handler.go" || src.Line != 30 || src.CWE != "CWE-79" {
		t.Errorf("source-fallback finding wrong: %+v (want src/handler.go:30 CWE-79)", src)
	}
}

// TestScoreManifest_EndToEnd builds a 2-vuln-target + control fixture and asserts
// the hand-computed metrics, including EXTRA quarantine and adjudicator consult.
func TestScoreManifest_EndToEnd(t *testing.T) {
	ctx := context.Background()
	db := openTempDB(t, "eval.duckdb")

	// Corpus 1: a STRONG-matchable hunk. Corpus 2: a hunk that will be missed.
	seedCorpus(t, ctx, db, 1, "CVE-1", "https://github.com/x/a", "v1", "f1", "CWE-89", `[{"file":"a.go","line_start":100,"line_end":110,"cwe":"CWE-89","is_primary":true}]`)
	seedCorpus(t, ctx, db, 2, "CVE-2", "https://github.com/x/b", "v2", "f2", "CWE-79", `[{"file":"b.go","line_start":50,"line_end":60,"cwe":"CWE-79","is_primary":true}]`)

	uid := "score-uid"

	// Corpus 1 vuln seed 0: one STRONG finding + one EXTRA (must be quarantined).
	putRun(t, ctx, db, uid, 1, "vuln", 0, 2.0, []Finding{
		{Hash: "c1-strong", File: "a.go", Line: 105, CWE: "CWE-89", Status: "confirmed"},
		{Hash: "c1-extra", File: "noise.go", Line: 999, CWE: "CWE-22", Status: "candidate"},
	})
	// Corpus 2 vuln seed 0: a finding that does NOT match (wrong file) -> miss.
	putRun(t, ctx, db, uid, 2, "vuln", 0, 2.0, []Finding{
		{Hash: "c2-nomatch", File: "elsewhere.go", Line: 1, CWE: "CWE-79", Status: "candidate"},
	})
	// Corpus 1 control seed 0: one finding -> a false positive (FP).
	putRun(t, ctx, db, uid, 1, "control", 0, 4.0, []Finding{
		{Hash: "c1-ctl-fp", File: "somewhere.go", Line: 10, CWE: "CWE-89", Status: "candidate"},
	})

	if err := ScoreManifest(ctx, db, uid, nil, GradeStrong, 0, 10, DefaultGamma); err != nil {
		t.Fatalf("ScoreManifest: %v", err)
	}

	// --- per-target corpus 1: recall_at_1 = 1.0 (1 hunk caught / 1 hunk, 1 seed) ---
	c1 := fetchResult(t, ctx, db, uid, "target", "1")
	if got := asFloat(c1["recall_at_1"]); got != 1.0 {
		t.Errorf("corpus1 recall_at_1 = %v, want 1.0", got)
	}
	if got := asFloat(c1["recall_at_k"]); got != 1.0 {
		t.Errorf("corpus1 recall_at_k = %v, want 1.0", got)
	}
	// corpus 1 has NO control rows -> fp_per_kloc 0 here (control is on the same
	// corpus_id but counted under that corpus). Verify EXTRA quarantined: matches
	// has an EXTRA entry but it did not affect recall (still 1.0 above).
	var c1Matches []Match
	if err := json.Unmarshal([]byte(asString(c1["matches_json"])), &c1Matches); err != nil {
		t.Fatalf("corpus1 matches_json: %v", err)
	}
	var sawExtra, sawStrong bool
	for _, m := range c1Matches {
		if m.Grade == GradeExtra && m.FindingHash == "c1-extra" {
			sawExtra = true
		}
		if m.Grade == GradeStrong && m.FindingHash == "c1-strong" {
			sawStrong = true
		}
	}
	if !sawExtra || !sawStrong {
		t.Errorf("corpus1 matches missing STRONG/EXTRA: %+v", c1Matches)
	}
	// corpus 1 fp_per_kloc: 1 control finding / 4 kloc = 0.25.
	if got := asFloat(c1["fp_per_kloc"]); got != 0.25 {
		t.Errorf("corpus1 fp_per_kloc = %v, want 0.25", got)
	}

	// --- per-target corpus 2: recall = 0 (missed) ---
	c2 := fetchResult(t, ctx, db, uid, "target", "2")
	if got := asFloat(c2["recall_at_1"]); got != 0.0 {
		t.Errorf("corpus2 recall_at_1 = %v, want 0.0", got)
	}

	// --- overall: recall_at_1 = mean(1.0, 0.0) = 0.5 ---
	ov := fetchResult(t, ctx, db, uid, "overall", "all")
	if got := asFloat(ov["recall_at_1"]); got != 0.5 {
		t.Errorf("overall recall_at_1 = %v, want 0.5", got)
	}
	if got := asFloat(ov["recall_at_k"]); got != 0.5 {
		t.Errorf("overall recall_at_k = %v, want 0.5", got)
	}
	// overall fp_per_kloc = sum(control findings)/sum(control kloc) = 1/4 = 0.25.
	if got := asFloat(ov["fp_per_kloc"]); got != 0.25 {
		t.Errorf("overall fp_per_kloc = %v, want 0.25", got)
	}

	// --- adjudicator is consulted: build a PARTIAL-only fixture on a fresh manifest ---
	uid2 := "score-adj"
	putRun(t, ctx, db, uid2, 1, "vuln", 0, 1.0, []Finding{
		// same file + line-in-window but incompatible CWE => PARTIAL.
		{Hash: "partial-1", File: "a.go", Line: 105, CWE: "CWE-79", Status: "candidate"},
	})
	adj := &partialOnlyAdj{}
	if err := ScoreManifest(ctx, db, uid2, adj, GradePartial, 0, 10, DefaultGamma); err != nil {
		t.Fatalf("ScoreManifest adj: %v", err)
	}
	if adj.consulted == 0 {
		t.Error("adjudicator was not consulted during scoring of a PARTIAL pair")
	}
	// With PARTIAL floor and a judge-confirmed PARTIAL, recall should be 1.0.
	c1adj := fetchResult(t, ctx, db, uid2, "target", "1")
	if got := asFloat(c1adj["recall_at_1"]); got != 1.0 {
		t.Errorf("adj corpus1 recall_at_1 = %v, want 1.0 (PARTIAL floor + judge)", got)
	}
}

// --- fixture helpers ---

func seedCorpus(t *testing.T, ctx context.Context, db *vrdb.DB, id int, cve, repo, vuln, fix, cwe, gtJSON string) {
	t.Helper()
	mustPut(t, ctx, db, "eval_corpus", map[string]any{
		"id": id, "source": "custom", "cve_id": cve, "repo_url": repo,
		"vuln_commit": vuln, "fix_commit": fix, "primary_cwe": cwe, "language": "go",
		"ground_truth_json": gtJSON, "added_at": "2026-05-21 00:00:00",
	})
}

func putRun(t *testing.T, ctx context.Context, db *vrdb.DB, uid string, corpusID int, mode string, seed int, kloc float64, findings []Finding) {
	t.Helper()
	buf, err := json.Marshal(findings)
	if err != nil {
		t.Fatalf("marshal findings: %v", err)
	}
	mustPut(t, ctx, db, "eval_run", map[string]any{
		"corpus_id": corpusID, "manifest_uid": uid, "mode": mode, "seed": seed,
		"tier": "deep", "kloc_scanned": kloc, "findings_json": string(buf),
		"ingested_at": "2026-05-21 00:00:00",
	})
}

func mustPut(t *testing.T, ctx context.Context, db *vrdb.DB, table string, row map[string]any) {
	t.Helper()
	if err := db.Put(ctx, table, []map[string]any{row}); err != nil {
		t.Fatalf("Put %s: %v", table, err)
	}
}

func putReturningID(t *testing.T, ctx context.Context, db *vrdb.DB, table string, row map[string]any) any {
	t.Helper()
	if err := db.Put(ctx, table, []map[string]any{row}); err != nil {
		t.Fatalf("Put %s: %v", table, err)
	}
	return row["id"] // Put assigns id in place.
}

func fetchResult(t *testing.T, ctx context.Context, db *vrdb.DB, uid, scope, key string) map[string]any {
	t.Helper()
	rows, err := db.Fetch(ctx, "SELECT * FROM eval_result WHERE manifest_uid = ? AND scope = ? AND scope_key = ?", uid, scope, key)
	if err != nil {
		t.Fatalf("Fetch eval_result: %v", err)
	}
	if len(rows) != 1 {
		t.Fatalf("expected 1 eval_result for %s/%s/%s, got %d", uid, scope, key, len(rows))
	}
	return rows[0]
}
