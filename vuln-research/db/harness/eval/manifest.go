// manifest.go — EmitManifest: expand a set of corpus rows into a deterministic run plan
// (vuln+control x seeds) and write it as JSON for an external audit runner to execute.
// Exists because the harness never runs the audit itself; it only emits the manifest whose
// stable manifest_uid later keys the eval_run / eval_result rows the runner feeds back.

package eval

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"sort"

	"vrdb"
)

// ManifestItem is one (target, mode, seed) the external runner should audit.
//
// Provenance and DisclosureDate are PKCO (post-knowledge-cutoff) metadata adapted
// from LLMxCPG (arXiv:2507.16585), which built a post-cutoff dataset (PKCO-25) so
// benchmark scores aren't inflated by LLM training contamination. Both are
// optional (omitempty): manifests/corpora that predate them still parse and emit
// unchanged. Provenance records where the sample came from (e.g. the corpus
// source: cvefixes/vul4j/primevul/custom); DisclosureDate is the sample's public
// disclosure / knowledge-cutoff date (YYYY-MM-DD), used by SelectPostCutoff to
// prefer or flag contamination-safe (post-cutoff) samples.
type ManifestItem struct {
	CorpusID       int    `json:"corpus_id"`
	RepoURL        string `json:"repo_url"`
	Commit         string `json:"commit"`
	Mode           string `json:"mode"`
	Seed           int    `json:"seed"`
	Provenance     string `json:"provenance,omitempty"`
	DisclosureDate string `json:"disclosure_date,omitempty"`
}

// IsPostCutoff reports whether this item's disclosure date is strictly after the
// given knowledge-cutoff date (both YYYY-MM-DD, lexicographically comparable).
// An item with no DisclosureDate is treated as NOT post-cutoff (unknown ->
// conservative): callers decide whether to keep or drop unknowns.
func (it ManifestItem) IsPostCutoff(cutoff string) bool {
	if it.DisclosureDate == "" || cutoff == "" {
		return false
	}
	return it.DisclosureDate > cutoff
}

// SelectPostCutoff applies a PKCO contamination preference over items. When
// prefer is false (the default/forgiving mode) it returns items unchanged, so
// existing corpora are unaffected. When prefer is true it keeps only items whose
// DisclosureDate is strictly after cutoff (contamination-safe), dropping
// pre-cutoff and unknown-date samples. cutoff is YYYY-MM-DD.
func SelectPostCutoff(items []ManifestItem, cutoff string, prefer bool) []ManifestItem {
	if !prefer || cutoff == "" {
		return items
	}
	out := make([]ManifestItem, 0, len(items))
	for _, it := range items {
		if it.IsPostCutoff(cutoff) {
			out = append(out, it)
		}
	}
	return out
}

// EmitManifest expands corpusIDs into vuln+control runs across seeds 0..seeds-1,
// writes them to outPath as {manifest_uid, tier, items}, and returns the uid +
// items. manifestUID is the first 16 hex of sha256 over a canonical
// (sorted corpusIDs + tier + seeds) string, so re-emitting with the same args is
// stable. Commit is vuln_commit for mode 'vuln', else fix_commit.
//
// Each item carries the corpus's source as PKCO Provenance. When preferPostCutoff
// is true, items are filtered to those disclosed strictly after cutoff
// (YYYY-MM-DD) via SelectPostCutoff before write; with the default
// (preferPostCutoff=false) every item is emitted, so existing corpora are
// unaffected. cutoff/preference do NOT enter manifestUID, so toggling the
// contamination filter does not collide with an unfiltered run's uid.
func EmitManifest(ctx context.Context, db *vrdb.DB, corpusIDs []int, tier string, seeds int, outPath, cutoff string, preferPostCutoff bool) (string, []ManifestItem, error) {
	ids := append([]int(nil), corpusIDs...)
	sort.Ints(ids)

	canon := fmt.Sprintf("%v|%s|%d", ids, tier, seeds)
	sum := sha256.Sum256([]byte(canon))
	manifestUID := hex.EncodeToString(sum[:])[:16]

	items := make([]ManifestItem, 0, len(ids)*2*seeds)
	for _, id := range ids {
		rows, err := db.Fetch(ctx, "SELECT repo_url, vuln_commit, fix_commit, source FROM eval_corpus WHERE id = ?", id)
		if err != nil {
			return "", nil, fmt.Errorf("eval: EmitManifest: fetch corpus %d: %w", id, err)
		}
		if len(rows) == 0 {
			return "", nil, fmt.Errorf("eval: EmitManifest: corpus %d not found", id)
		}
		repoURL := fmt.Sprintf("%v", rows[0]["repo_url"])
		vulnCommit := fmt.Sprintf("%v", rows[0]["vuln_commit"])
		fixCommit := fmt.Sprintf("%v", rows[0]["fix_commit"])
		provenance := asString(rows[0]["source"]) // PKCO provenance: corpus origin.
		for _, mode := range []string{"vuln", "control"} {
			commit := fixCommit
			if mode == "vuln" {
				commit = vulnCommit
			}
			for seed := 0; seed < seeds; seed++ {
				items = append(items, ManifestItem{
					CorpusID:   id,
					RepoURL:    repoURL,
					Commit:     commit,
					Mode:       mode,
					Seed:       seed,
					Provenance: provenance,
				})
			}
		}
	}

	items = SelectPostCutoff(items, cutoff, preferPostCutoff)

	out := struct {
		ManifestUID string         `json:"manifest_uid"`
		Tier        string         `json:"tier"`
		Items       []ManifestItem `json:"items"`
	}{manifestUID, tier, items}
	buf, err := json.MarshalIndent(out, "", "  ")
	if err != nil {
		return "", nil, fmt.Errorf("eval: EmitManifest: marshal: %w", err)
	}
	if err := os.WriteFile(outPath, buf, 0o644); err != nil {
		return "", nil, fmt.Errorf("eval: EmitManifest: write %s: %w", outPath, err)
	}
	return manifestUID, items, nil
}
