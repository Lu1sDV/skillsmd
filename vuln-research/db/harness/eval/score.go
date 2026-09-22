// score.go — ScoreManifest: compute recall / fp-per-kloc for one manifest and write eval_result rows.
// Exists as the two-track scorer: recall on vuln runs, false-positive rate on clean controls, rolled
// up per-corpus (scope='target') and once overall (scope='overall'), idempotent via Put.

package eval

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"vrdb"
)

// gradeRank orders grades so STRONG outranks PARTIAL; MISS/EXTRA/"" are 0.
func gradeRank(g Grade) int {
	switch g {
	case GradeStrong:
		return 3
	case GradePartial:
		return 2
	default:
		return 0
	}
}

// caughtAtFloor reports whether grade g meets the recall floor (e.g. STRONG floor
// rejects a PARTIAL match).
func caughtAtFloor(g, floor Grade) bool { return gradeRank(g) >= gradeRank(floor) }

// evalRun is one eval_run row plus its corpus ground truth, as fetched for scoring.
type evalRun struct {
	corpusID  int
	mode      string
	seed      int
	kloc      float64
	findings  []Finding
	gts       []GroundTruth
	primaryGT *GroundTruth
}

// ScoreManifest fetches every eval_run for manifestUID (joined to its corpus),
// computes per-corpus and overall metrics, and Puts eval_result rows. recallFloor
// defaults to GradeStrong; w/w2 are the line windows passed to matching. gamma is
// the calibrated decision threshold (see calibrate.go / config.go): findings whose
// severity score falls below it are dropped before matching. Pass DefaultGamma (0)
// for the uncalibrated, accept-everything behavior; callers driving the CLI source
// it from scoring.yml via LoadGamma rather than a constant.
func ScoreManifest(ctx context.Context, evalDB *vrdb.DB, manifestUID string, adj Adjudicator, recallFloor Grade, w, w2 int, gamma float64) error {
	if recallFloor == "" {
		recallFloor = GradeStrong
	}
	rows, err := evalDB.Fetch(ctx, `
		SELECT r.corpus_id, r.mode, r.seed, r.kloc_scanned, r.findings_json,
		       c.ground_truth_json
		FROM eval_run r
		JOIN eval_corpus c ON r.corpus_id = c.id
		WHERE r.manifest_uid = ?`, manifestUID)
	if err != nil {
		return fmt.Errorf("eval: ScoreManifest: fetch runs: %w", err)
	}

	byCorpus := map[int][]evalRun{}
	order := []int{}
	for _, row := range rows {
		var findings []Finding
		if err := json.Unmarshal([]byte(asString(row["findings_json"])), &findings); err != nil {
			return fmt.Errorf("eval: ScoreManifest: parse findings_json: %w", err)
		}
		var gts []GroundTruth
		if err := json.Unmarshal([]byte(asString(row["ground_truth_json"])), &gts); err != nil {
			return fmt.Errorf("eval: ScoreManifest: parse ground_truth_json: %w", err)
		}
		cid := asInt(row["corpus_id"])
		if _, seen := byCorpus[cid]; !seen {
			order = append(order, cid)
		}
		byCorpus[cid] = append(byCorpus[cid], evalRun{
			corpusID:  cid,
			mode:      asString(row["mode"]),
			seed:      asInt(row["seed"]),
			kloc:      asFloat(row["kloc_scanned"]),
			findings:  findings,
			gts:       gts,
			primaryGT: primaryOf(gts),
		})
	}

	now := time.Now().UTC().Format("2006-01-02 15:04:05")
	var sumR1, sumRK, sumRefound float64
	var sumCtrlFindings, corpusCount int
	var sumCtrlKloc float64

	for _, cid := range order {
		runs := byCorpus[cid]
		m := scoreCorpus(runs, adj, recallFloor, w, w2, gamma)
		corpusCount++
		sumR1 += m.recall1
		sumRK += m.recallK
		sumRefound += m.refound
		sumCtrlFindings += m.ctrlFindings
		sumCtrlKloc += m.ctrlKloc

		matchesJSON, err := json.Marshal(m.matches)
		if err != nil {
			return fmt.Errorf("eval: ScoreManifest: marshal matches: %w", err)
		}
		row := map[string]any{
			"manifest_uid":       manifestUID,
			"scope":              "target",
			"scope_key":          strconv.Itoa(cid),
			"recall_at_1":        m.recall1,
			"recall_at_k":        m.recallK,
			"fp_per_kloc":        safeDiv(float64(m.ctrlFindings), m.ctrlKloc),
			"refound_fixed_rate": m.refound,
			"matches_json":       string(matchesJSON),
			"computed_at":        now,
		}
		if err := evalDB.Put(ctx, "eval_result", []map[string]any{row}); err != nil {
			return fmt.Errorf("eval: ScoreManifest: put target result: %w", err)
		}
	}

	overall := map[string]any{
		"manifest_uid":       manifestUID,
		"scope":              "overall",
		"scope_key":          "all",
		"recall_at_1":        meanOver(sumR1, corpusCount),
		"recall_at_k":        meanOver(sumRK, corpusCount),
		"fp_per_kloc":        safeDiv(float64(sumCtrlFindings), sumCtrlKloc),
		"refound_fixed_rate": meanOver(sumRefound, corpusCount),
		"matches_json":       nil,
		"computed_at":        now,
	}
	if err := evalDB.Put(ctx, "eval_result", []map[string]any{overall}); err != nil {
		return fmt.Errorf("eval: ScoreManifest: put overall result: %w", err)
	}
	return nil
}

// corpusMetrics is the per-corpus rollup ScoreManifest aggregates into overall.
type corpusMetrics struct {
	recall1      float64
	recallK      float64
	refound      float64
	ctrlFindings int
	ctrlKloc     float64
	matches      []Match
}

// scoreCorpus computes recall over vuln seeds and FP accounting over control
// seeds for one corpus. EXTRA findings on vuln targets are quarantined: kept in
// matches_json but counted in neither recall nor FP.
func scoreCorpus(runs []evalRun, adj Adjudicator, floor Grade, w, w2 int, gamma float64) corpusMetrics {
	var m corpusMetrics
	var vulnSeeds int
	var caughtFractionSum float64
	caughtAny := map[int]bool{} // gt index -> caught in any vuln seed

	totalHunks := 0
	for _, r := range runs {
		if r.mode == "vuln" {
			totalHunks = len(r.gts)
			break
		}
	}

	for _, r := range runs {
		// Drop findings below the calibrated decision threshold γ before scoring
		// (identity when γ=DefaultGamma). Applied to both modes so a tightened γ
		// raises recall miss risk on vuln runs while cutting FPs on controls.
		findings := applyGamma(r.findings, gamma)
		switch r.mode {
		case "vuln":
			vulnSeeds++
			matches := MatchFindings(findings, r.gts, adj, w, w2)
			m.matches = append(m.matches, matches...)
			caughtThisSeed := 0
			for _, mt := range matches {
				if mt.Grade == GradeMiss || mt.Grade == GradeExtra {
					continue
				}
				if caughtAtFloor(mt.Grade, floor) {
					caughtThisSeed++
					caughtAny[mt.GTIdx] = true
				}
			}
			if totalHunks > 0 {
				caughtFractionSum += float64(caughtThisSeed) / float64(totalHunks)
			}
		case "control":
			m.ctrlFindings += len(findings)
			m.ctrlKloc += r.kloc
			if r.primaryGT != nil && controlRefound(findings, *r.primaryGT, w2) {
				m.refound += 1
			}
		}
	}

	if vulnSeeds > 0 {
		m.recall1 = caughtFractionSum / float64(vulnSeeds)
	}
	if totalHunks > 0 {
		m.recallK = float64(len(caughtAny)) / float64(totalHunks)
	}
	if ctrlSeeds := countMode(runs, "control"); ctrlSeeds > 0 {
		m.refound = m.refound / float64(ctrlSeeds)
	} else {
		m.refound = 0
	}
	return m
}

// controlRefound reports whether any control finding re-flags the fixed primary
// location: same file basename and line within [start-w2, end+w2] (CWE ignored).
func controlRefound(findings []Finding, primary GroundTruth, w2 int) bool {
	for _, f := range findings {
		if sameFile(f.File, primary.File) && lineWithin(f.Line, primary.LineStart, primary.LineEnd, w2) {
			return true
		}
	}
	return false
}

func primaryOf(gts []GroundTruth) *GroundTruth {
	for i := range gts {
		if gts[i].IsPrimary {
			return &gts[i]
		}
	}
	return nil
}

func countMode(runs []evalRun, mode string) int {
	n := 0
	for _, r := range runs {
		if r.mode == mode {
			n++
		}
	}
	return n
}

func safeDiv(num, den float64) float64 {
	if den == 0 {
		return 0
	}
	return num / den
}

func meanOver(sum float64, n int) float64 {
	if n == 0 {
		return 0
	}
	return sum / float64(n)
}
