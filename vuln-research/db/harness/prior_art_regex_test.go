// prior_art_regex_test.go — round-trip + gate tests for the v0.39.0 enhancements:
//   C1 prior-art intake (cves, writeups, promising_lanes.derived_from_*),
//   C3 mandatory regex mapping (regexes table + v_coverage.regexes_unmapped HARD-RED gate).
//
// Run: cd db/harness && go test ./... -run 'TestPut_Cves|TestPut_Writeups|TestPut_Regexes|TestGateSemantics_RegexesUnmapped|TestPut_PromisingLanes_Provenance'
package vrdb_test

import (
	"fmt"
	"testing"
)

// TestPut_Cves_RoundTripAndIdempotent exercises the cves allowlist entry, the source CHECK
// vocab, and the (target_id, cve_id, source) natural-key dedup.
func TestPut_Cves_RoundTripAndIdempotent(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "cve-rt")

	for i := 0; i < 2; i++ {
		row := map[string]any{
			"target_id":  tid,
			"cve_id":     "CVE-2024-1234",
			"product":    "acme/widget",
			"source":     "nvd",
			"cvss":       9.8,
			"summary":    "RCE in widget parser",
			"created_at": "2026-06-04 00:00:00",
		}
		if err := db.Put(ctx, "cves", []map[string]any{row}); err != nil {
			t.Fatalf("Put cves attempt %d: %v", i+1, err)
		}
	}

	rows, err := db.Fetch(ctx, "SELECT count(*) AS n FROM cves WHERE cve_id = ?", "CVE-2024-1234")
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	if got := fmt.Sprintf("%v", rows[0]["n"]); got != "1" {
		t.Fatalf("expected exactly 1 cves row after replay, got %s", got)
	}

	// Same CVE from a DIFFERENT source is a distinct provenance row (NK includes source).
	row2 := map[string]any{
		"target_id":  tid,
		"cve_id":     "CVE-2024-1234",
		"source":     "ghsa",
		"created_at": "2026-06-04 00:00:00",
	}
	if err := db.Put(ctx, "cves", []map[string]any{row2}); err != nil {
		t.Fatalf("Put cves second source: %v", err)
	}
	rows, _ = db.Fetch(ctx, "SELECT count(*) AS n FROM cves WHERE cve_id = ?", "CVE-2024-1234")
	if got := fmt.Sprintf("%v", rows[0]["n"]); got != "2" {
		t.Fatalf("expected 2 cves rows (nvd + ghsa), got %s", got)
	}
}

// TestPut_Cves_RejectsBadSource pins the CLOSED source CHECK vocab.
func TestPut_Cves_RejectsBadSource(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "cve-badsrc")
	err := db.Put(ctx, "cves", []map[string]any{{
		"target_id":  tid,
		"cve_id":     "CVE-2024-9999",
		"source":     "randomblog", // not in (nvd,ghsa,osv,exploit-db)
		"created_at": "2026-06-04 00:00:00",
	}})
	if err == nil {
		t.Fatalf("expected CHECK violation for invalid cves.source, got nil")
	}
}

// TestPut_Writeups_RoundTripWithCveLink exercises writeups + the nullable related_cve_id FK
// (cves flushed before writeups) and the (target_id, url) natural key.
func TestPut_Writeups_RoundTripWithCveLink(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "wu-rt")

	cve := map[string]any{
		"target_id": tid, "cve_id": "CVE-2024-5555", "source": "osv",
		"created_at": "2026-06-04 00:00:00",
	}
	if err := db.Put(ctx, "cves", []map[string]any{cve}); err != nil {
		t.Fatalf("Put cve: %v", err)
	}

	for i := 0; i < 2; i++ {
		row := map[string]any{
			"target_id":      tid,
			"url":            "https://blog.example/ssti-in-widget",
			"title":          "SSTI in widget",
			"source":         "blog",
			"bug_class":      "ssti",
			"related_cve_id": cve["id"],
			"created_at":     "2026-06-04 00:00:00",
		}
		if err := db.Put(ctx, "writeups", []map[string]any{row}); err != nil {
			t.Fatalf("Put writeups attempt %d: %v", i+1, err)
		}
	}
	rows, _ := db.Fetch(ctx, "SELECT count(*) AS n FROM writeups WHERE url = ?", "https://blog.example/ssti-in-widget")
	if got := fmt.Sprintf("%v", rows[0]["n"]); got != "1" {
		t.Fatalf("expected exactly 1 writeups row after replay, got %s", got)
	}
}

// TestPut_Regexes_RoundTripAndRoleCheck exercises the regexes allowlist entry, the role
// CHECK vocab, the nullable defense_id FK, and the (target_id, file, line, pattern_src) NK.
func TestPut_Regexes_RoundTripAndRoleCheck(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "rx-rt")

	for i := 0; i < 2; i++ {
		row := map[string]any{
			"target_id":   tid,
			"pattern_src": `^[a-z0-9_]+$`,
			"flags":       "i",
			"file":        "src/validate.go",
			"symbol_path": "validate.Username",
			"line":        42,
			"language":    "go",
			"role":        "validator",
			"created_at":  "2026-06-04 00:00:00",
		}
		if err := db.Put(ctx, "regexes", []map[string]any{row}); err != nil {
			t.Fatalf("Put regexes attempt %d: %v", i+1, err)
		}
	}
	rows, _ := db.Fetch(ctx, "SELECT count(*) AS n FROM regexes WHERE file = ?", "src/validate.go")
	if got := fmt.Sprintf("%v", rows[0]["n"]); got != "1" {
		t.Fatalf("expected exactly 1 regexes row after replay, got %s", got)
	}

	// Bad role must be rejected by the CHECK.
	err := db.Put(ctx, "regexes", []map[string]any{{
		"target_id": tid, "pattern_src": "x", "file": "f", "line": 1,
		"role": "sanitizerish", "created_at": "2026-06-04 00:00:00",
	}})
	if err == nil {
		t.Fatalf("expected CHECK violation for invalid regexes.role, got nil")
	}
}

// TestPut_PromisingLanes_Provenance proves a promising_lanes row can carry the new
// derived_from_cve_id / derived_from_writeup_id provenance FKs (cves flushed first).
func TestPut_PromisingLanes_Provenance(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "pl-prov")

	cve := map[string]any{
		"target_id": tid, "cve_id": "CVE-2024-7777", "source": "exploit-db",
		"created_at": "2026-06-04 00:00:00",
	}
	if err := db.Put(ctx, "cves", []map[string]any{cve}); err != nil {
		t.Fatalf("Put cve: %v", err)
	}

	lane := map[string]any{
		"target_id":           tid,
		"proposed_lane_kind":  "ssti_fuzz",
		"region_hash":         "__TARGET_WIDE__",
		"title":               "Prior-art: SSTI lane from CVE-2024-7777",
		"body":                "CVE-2024-7777 shows SSTI in the template render path; spawn an SSTI-fuzz lane.",
		"lane_hash":           "lane-prov-1",
		"derived_from_cve_id": cve["id"],
		"created_at":          "2026-06-04 00:00:00",
	}
	if err := db.Put(ctx, "promising_lanes", []map[string]any{lane}); err != nil {
		t.Fatalf("Put promising_lanes with provenance: %v", err)
	}
	rows, _ := db.Fetch(ctx, "SELECT derived_from_cve_id FROM promising_lanes WHERE lane_hash = ?", "lane-prov-1")
	if len(rows) != 1 {
		t.Fatalf("expected 1 promising_lanes row, got %d", len(rows))
	}
	if fmt.Sprintf("%v", rows[0]["derived_from_cve_id"]) != fmt.Sprintf("%v", cve["id"]) {
		t.Fatalf("derived_from_cve_id: got %v, want %v", rows[0]["derived_from_cve_id"], cve["id"])
	}
}

// TestGateSemantics_RegexesUnmapped is the C3 HARD-RED gate test: when
// preliminary_enumeration_lane RAN but zero regexes rows exist, regexes_unmapped == 1 (RED);
// after a regex is mapped, it drops to 0. Before the enumeration lane runs it must be 0
// (the gate cannot fire pre-enumeration).
func TestGateSemantics_RegexesUnmapped(t *testing.T) {
	db, ctx := openTestDB(t)
	tid := seedTarget(t, db, ctx, "rx-gate")

	// Pre-enumeration: gate must be 0 (no enumeration step yet).
	if v := fetchCoverageMetric(t, db, ctx, "regexes_unmapped"); v != 0 {
		t.Fatalf("regexes_unmapped before enumeration: want 0, got %d", v)
	}

	// Enumeration lane RAN but mapped no regexes → RED (1).
	seedStep(t, db, ctx, tid, "preliminary_enumeration_lane", "success", nil, "rx-gate")
	if v := fetchCoverageMetric(t, db, ctx, "regexes_unmapped"); v != 1 {
		t.Fatalf("regexes_unmapped after enumeration with zero regexes: want 1 (RED), got %d", v)
	}

	// Map a regex → gate clears to 0.
	if err := db.Put(ctx, "regexes", []map[string]any{{
		"target_id": tid, "pattern_src": "^x$", "file": "a.go", "line": 1,
		"role": "guard", "created_at": "2026-06-04 00:00:00",
	}}); err != nil {
		t.Fatalf("Put regexes: %v", err)
	}
	if v := fetchCoverageMetric(t, db, ctx, "regexes_unmapped"); v != 0 {
		t.Fatalf("regexes_unmapped after mapping a regex: want 0, got %d", v)
	}
}
