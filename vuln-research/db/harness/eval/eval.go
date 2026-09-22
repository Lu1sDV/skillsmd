// eval.go — shared types for the eval harness (Tier 1 measurement): the Finding/GroundTruth/Match
// shapes that corpus, manifest, ingest, match, and score all marshal to/from the eval_* JSON columns.
// Exists so the scorer and the audit-result ingest agree on one struct layout instead of re-deriving
// the findings_json / ground_truth_json / matches_json schemas at each call site.

// Package eval scores a prose vulnerability audit against a labeled CVE corpus.
// It is complementary benchmarking infrastructure: the methodology finds bugs;
// this package only measures whether a change moved recall / FP-per-KLOC. It
// reads/writes the eval_corpus / eval_run / eval_result tables via the vrdb
// harness and never spawns an audit itself.
package eval

// Finding is one audit result resolved to file/line + derived CWE; the element
// type of eval_run.findings_json.
type Finding struct {
	Hash     string `json:"hash"`
	Kind     string `json:"kind"`
	CWE      string `json:"cwe"`
	File     string `json:"file"`
	Line     int    `json:"line"`
	Severity string `json:"severity"`
	Status   string `json:"status"`
}

// GroundTruth is one labeled fix hunk; the element type of
// eval_corpus.ground_truth_json. Exactly one entry per corpus row is IsPrimary.
type GroundTruth struct {
	File      string `json:"file"`
	LineStart int    `json:"line_start"`
	LineEnd   int    `json:"line_end"`
	CWE       string `json:"cwe"`
	IsPrimary bool   `json:"is_primary"`
}

// Grade ranks how well a finding matches a ground-truth hunk.
type Grade string

const (
	GradeStrong  Grade = "STRONG"
	GradePartial Grade = "PARTIAL"
	GradeMiss    Grade = "MISS"
	GradeExtra   Grade = "EXTRA"
)

// Match is one adjudicated (finding, hunk) pairing; the element type of
// eval_result.matches_json. GTIdx is -1 for EXTRA; FindingHash is "" for MISS.
type Match struct {
	FindingHash string `json:"finding_hash"`
	GTIdx       int    `json:"gt_idx"`
	Grade       Grade  `json:"grade"`
	DecidedBy   string `json:"decided_by"`
	Rationale   string `json:"rationale"`
}
