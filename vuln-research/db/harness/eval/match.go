// match.go — grade a single (finding, hunk) pair and match a finding set against ground truth.
// Exists as the scorer's decision core: GradeOne is the deterministic rule, CWECompatible the
// CWE family check, and MatchFindings the assignment that emits STRONG/PARTIAL/MISS/EXTRA matches.

package eval

import (
	"path/filepath"
	"strings"
)

// Adjudicator is an optional tie-breaker for ambiguous (PARTIAL) pairs — e.g. a
// live LLM judge. This tier passes nil; matching falls back to rules only.
type Adjudicator interface {
	Adjudicate(f Finding, gt GroundTruth) (matched bool, rationale string)
}

// cweFamily groups CWE ids that should be treated as compatible. Each id maps to
// a canonical family key; two ids are compatible when they share a family.
// Deliberately tiny and static — this is unit-tested, not a live taxonomy.
var cweFamily = map[string]string{
	"CWE-79":  "xss",
	"CWE-80":  "xss",
	"CWE-89":  "sqli",
	"CWE-78":  "cmdi",
	"CWE-77":  "cmdi",
	"CWE-22":  "pathtrav",
	"CWE-23":  "pathtrav",
	"CWE-36":  "pathtrav",
	"CWE-787": "memory",
	"CWE-125": "memory",
	"CWE-119": "memory",
	"CWE-502": "deser",
	"CWE-918": "ssrf",
	"CWE-611": "xxe",
	"CWE-601": "openredirect",
	"CWE-287": "auth",
	"CWE-639": "idor",
}

// CWECompatible is true when a and b are equal (case-insensitive, trimmed) or
// share a family in cweFamily. Symmetric; false if either is "".
func CWECompatible(a, b string) bool {
	a, b = strings.ToUpper(strings.TrimSpace(a)), strings.ToUpper(strings.TrimSpace(b))
	if a == "" || b == "" {
		return false
	}
	if a == b {
		return true
	}
	fa, oka := cweFamily[a]
	fb, okb := cweFamily[b]
	return oka && okb && fa == fb
}

// sameFile compares two paths by basename so an audit's repo-relative path
// matches the corpus's file regardless of prefix.
func sameFile(a, b string) bool {
	if a == "" || b == "" {
		return false
	}
	return filepath.Base(a) == filepath.Base(b)
}

func lineWithin(line, start, end, win int) bool {
	return line >= start-win && line <= end+win
}

// GradeOne grades one (finding, hunk) pair. STRONG = same file AND line within
// [start-w, end+w] AND CWECompatible. PARTIAL = same file AND exactly one of
// {line within [start-w2, end+w2], CWECompatible}. Otherwise "" (no grade).
func GradeOne(f Finding, gt GroundTruth, w, w2 int) Grade {
	if !sameFile(f.File, gt.File) {
		return ""
	}
	cwe := CWECompatible(f.CWE, gt.CWE)
	if lineWithin(f.Line, gt.LineStart, gt.LineEnd, w) && cwe {
		return GradeStrong
	}
	lineLoose := lineWithin(f.Line, gt.LineStart, gt.LineEnd, w2)
	if lineLoose != cwe { // exactly one of the two holds
		return GradePartial
	}
	return ""
}

// MatchFindings assigns findings to ground-truth hunks. For each hunk it takes
// the best unused finding (STRONG beats PARTIAL); a PARTIAL pair may be confirmed
// by adj (DecidedBy="judge") else dropped. Rule matches get DecidedBy="rule".
// Unmatched hunks emit MISS; findings matching no hunk emit EXTRA.
func MatchFindings(findings []Finding, gts []GroundTruth, adj Adjudicator, w, w2 int) []Match {
	usedF := make([]bool, len(findings))
	matched := make([]Match, 0, len(gts))

	for i, gt := range gts {
		bestIdx, bestGrade := -1, Grade("")
		bestRationale, bestBy := "", ""
		for j, f := range findings {
			if usedF[j] {
				continue
			}
			g := GradeOne(f, gt, w, w2)
			if g == "" {
				continue
			}
			by, rationale := "rule", ""
			if g == GradePartial && adj != nil {
				ok, why := adj.Adjudicate(f, gt)
				if !ok {
					continue
				}
				by, rationale = "judge", why
			}
			if better(g, bestGrade) {
				bestIdx, bestGrade, bestBy, bestRationale = j, g, by, rationale
			}
		}
		if bestIdx < 0 {
			matched = append(matched, Match{FindingHash: "", GTIdx: i, Grade: GradeMiss})
			continue
		}
		usedF[bestIdx] = true
		matched = append(matched, Match{
			FindingHash: findings[bestIdx].Hash,
			GTIdx:       i,
			Grade:       bestGrade,
			DecidedBy:   bestBy,
			Rationale:   bestRationale,
		})
	}

	for j, f := range findings {
		if !usedF[j] {
			matched = append(matched, Match{FindingHash: f.Hash, GTIdx: -1, Grade: GradeExtra})
		}
	}
	return matched
}

// better reports whether grade a outranks the current best b for hunk assignment.
func better(a, b Grade) bool { return gradeRank(a) > gradeRank(b) }
