// calibrate.go — γ-style decision-threshold calibration over a labeled validation split.
// Exists so the harness's decision threshold is fit to data rather than hardcoded: LLMxCPG
// (arXiv:2507.16585) tunes its decision threshold γ on a small (~20-sample) labeled validation
// set and recommends per-dataset calibration. We do the analogous thing here — sweep candidate γ
// over the severity-rank scale, pick the γ that maximizes the harness's F1 on the labeled split,
// and persist it to externalized config (db/seed/scoring.yml) via WriteGamma. The eval/score path
// then reads γ back through LoadGamma instead of any constant.

package eval

// severityRank maps a Finding's categorical severity to a numeric confidence
// score that γ gates against. Higher = more confident. Unknown/empty -> 0 so an
// uncalibrated default γ of 0 still accepts every finding (forgiving).
func severityRank(sev string) float64 {
	switch lower(sev) {
	case "critical":
		return 4
	case "high":
		return 3
	case "medium", "med":
		return 2
	case "low":
		return 1
	default:
		return 0
	}
}

// passesGamma reports whether finding f clears the decision threshold γ: its
// severity-rank score must be >= gamma. γ=0 (the default) accepts everything.
func passesGamma(f Finding, gamma float64) bool { return severityRank(f.Severity) >= gamma }

// applyGamma returns the subset of findings whose severity score clears γ. With
// γ=DefaultGamma this is identity, so the pre-calibration scoring path is
// unchanged when no calibrated value exists.
func applyGamma(findings []Finding, gamma float64) []Finding {
	if gamma <= DefaultGamma {
		return findings
	}
	out := findings[:0:0]
	for _, f := range findings {
		if passesGamma(f, gamma) {
			out = append(out, f)
		}
	}
	return out
}

// LabeledSample is one entry in a calibration validation split: a finding paired
// with whether it is a true positive (a real vuln that should be kept). This is
// the small labeled set γ is fit against — analogous to LLMxCPG's validation set.
type LabeledSample struct {
	Finding Finding `json:"finding"`
	IsVuln  bool    `json:"is_vuln"`
}

// gammaCandidates are the threshold breakpoints worth testing: one just below
// each severity rank plus the open floor. Derived from the rank scale, not magic
// constants — sweeping these covers every distinct accept/reject partition.
func gammaCandidates() []float64 { return []float64{0, 1, 2, 3, 4} }

// CalibrateGamma sweeps γ over the candidate thresholds and returns the value
// that maximizes F1 on the labeled validation split (ties broken toward the
// higher/stricter γ, which suppresses more false positives). A split with no
// positive (IsVuln) samples — including an empty split — is degenerate (F1 is
// undefined without true positives), so it yields DefaultGamma rather than
// silently fitting the strictest, recall-killing γ from a bad/mislabeled split.
// This is the calibration step; the caller persists the result with WriteGamma.
func CalibrateGamma(split []LabeledSample) (gamma, f1 float64) {
	positives := 0
	for _, s := range split {
		if s.IsVuln {
			positives++
		}
	}
	if positives == 0 {
		return DefaultGamma, 0
	}
	best, bestF1 := DefaultGamma, -1.0
	for _, g := range gammaCandidates() {
		score := f1AtGamma(split, g)
		if score >= bestF1 { // >= => prefer the stricter γ on ties
			best, bestF1 = g, score
		}
	}
	if bestF1 < 0 {
		return DefaultGamma, 0
	}
	return best, bestF1
}

// f1AtGamma computes the F1 of the keep/drop decision at threshold γ over the
// labeled split: a sample is "predicted vuln" when its finding clears γ.
func f1AtGamma(split []LabeledSample, gamma float64) float64 {
	var tp, fp, fn int
	for _, s := range split {
		kept := passesGamma(s.Finding, gamma)
		switch {
		case kept && s.IsVuln:
			tp++
		case kept && !s.IsVuln:
			fp++
		case !kept && s.IsVuln:
			fn++
		}
	}
	if tp == 0 {
		return 0
	}
	precision := float64(tp) / float64(tp+fp)
	recall := float64(tp) / float64(tp+fn)
	if precision+recall == 0 {
		return 0
	}
	return 2 * precision * recall / (precision + recall)
}
