// manifest_pkco_test.go — smoke test for PKCO contamination-aware metadata (thread b).
// Proves a manifest carrying provenance/disclosure_date parses, and the post-cutoff preference
// filter selects/flags samples correctly. Adapted from LLMxCPG's PKCO-25 (arXiv:2507.16585).

package eval

import (
	"context"
	"encoding/json"
	"path/filepath"
	"strings"
	"testing"
)

func TestManifestItem_ProvenanceCutoffJSONRoundTrip(t *testing.T) {
	in := ManifestItem{
		CorpusID: 1, RepoURL: "https://github.com/x/a", Commit: "v1", Mode: "vuln", Seed: 0,
		Provenance: "primevul", DisclosureDate: "2026-03-01",
	}
	buf, err := json.Marshal(in)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	var out ManifestItem
	if err := json.Unmarshal(buf, &out); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if out.Provenance != "primevul" || out.DisclosureDate != "2026-03-01" {
		t.Fatalf("PKCO fields lost in round-trip: %+v", out)
	}

	// Back-compat: a legacy item with no PKCO fields must omit them (omitempty)
	// and still parse cleanly.
	legacy, _ := json.Marshal(ManifestItem{CorpusID: 2, Mode: "control", Seed: 1})
	if got := string(legacy); strings.Contains(got, "provenance") || strings.Contains(got, "disclosure_date") {
		t.Fatalf("empty PKCO fields should be omitted, got %s", got)
	}
	var legacyOut ManifestItem
	if err := json.Unmarshal(legacy, &legacyOut); err != nil {
		t.Fatalf("legacy item must still parse: %v", err)
	}
}

func TestSelectPostCutoff_FlagsAndFilters(t *testing.T) {
	items := []ManifestItem{
		{CorpusID: 1, DisclosureDate: "2026-04-01"}, // after cutoff -> keep
		{CorpusID: 2, DisclosureDate: "2024-01-01"}, // before cutoff -> drop
		{CorpusID: 3, DisclosureDate: ""},           // unknown -> drop when filtering
	}
	cutoff := "2025-12-31"

	// Per-item flag.
	if !items[0].IsPostCutoff(cutoff) {
		t.Error("2026-04-01 should be post-cutoff")
	}
	if items[1].IsPostCutoff(cutoff) {
		t.Error("2024-01-01 should not be post-cutoff")
	}
	if items[2].IsPostCutoff(cutoff) {
		t.Error("unknown date should not be flagged post-cutoff")
	}

	// Forgiving default (prefer=false) returns everything unchanged.
	if got := SelectPostCutoff(items, cutoff, false); len(got) != 3 {
		t.Fatalf("default mode should not filter: got %d, want 3", len(got))
	}
	// Preference on -> keep only the contamination-safe post-cutoff sample.
	got := SelectPostCutoff(items, cutoff, true)
	if len(got) != 1 || got[0].CorpusID != 1 {
		t.Fatalf("post-cutoff filter wrong: %+v", got)
	}
}

func TestEmitManifest_PopulatesProvenanceAndCutoffKnob(t *testing.T) {
	ctx := context.Background()
	db := openTempDB(t, "eval.duckdb")
	// source 'primevul' becomes the per-item provenance.
	mustPut(t, ctx, db, "eval_corpus", map[string]any{
		"id": 1, "source": "primevul", "cve_id": "CVE-Z", "repo_url": "https://github.com/x/z",
		"vuln_commit": "vz", "fix_commit": "fz", "primary_cwe": "CWE-89", "language": "go",
		"ground_truth_json": `[{"file":"z.go","line_start":1,"line_end":1,"cwe":"CWE-89","is_primary":true}]`,
		"added_at": "2026-05-21 00:00:00",
	})

	// Default knob (no cutoff preference): provenance populated, nothing filtered.
	out := filepath.Join(t.TempDir(), "m.json")
	_, items, err := EmitManifest(ctx, db, []int{1}, "deep", 1, out, "", false)
	if err != nil {
		t.Fatalf("EmitManifest: %v", err)
	}
	if len(items) != 2 { // 1 corpus x 2 modes x 1 seed
		t.Fatalf("expected 2 items, got %d", len(items))
	}
	for _, it := range items {
		if it.Provenance != "primevul" {
			t.Errorf("provenance not populated from corpus.source: %+v", it)
		}
	}

	// With a cutoff preference and no per-item disclosure dates, every sample is
	// unknown-date -> all dropped (contamination-conservative).
	out2 := filepath.Join(t.TempDir(), "m2.json")
	_, filtered, err := EmitManifest(ctx, db, []int{1}, "deep", 1, out2, "2025-01-01", true)
	if err != nil {
		t.Fatalf("EmitManifest filtered: %v", err)
	}
	if len(filtered) != 0 {
		t.Fatalf("unknown-date samples should be dropped under post-cutoff preference, got %d", len(filtered))
	}
}
