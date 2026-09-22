// grade_test.go — pure-logic tests for the scorer's deterministic core: cweFor, CWECompatible,
// GradeOne, MatchFindings. No DuckDB here — these pin the rules independently of the DB plumbing.

package eval

import "testing"

func TestCweFor(t *testing.T) {
	cases := []struct {
		kind, cat, want string
	}{
		{"sqli", "", "CWE-89"},
		{"sql_injection", "", "CWE-89"},
		{"xss", "", "CWE-79"},
		{"command_injection", "", "CWE-78"},
		{"rce", "", "CWE-78"},
		{"path_traversal", "", "CWE-22"},
		{"ssrf", "", "CWE-918"},
		{"deserialization", "", "CWE-502"},
		{"fuzz_crash", "", "CWE-787"},
		{"auth_bypass", "", "CWE-287"},
		{"idor", "", "CWE-639"},
		{"SQLI", "", "CWE-89"},              // case-insensitive
		{"unknown_kind", "sqli", "CWE-89"},  // falls back to sink_category
		{"unknown_kind", "unknown_cat", ""}, // neither known -> ""
		{"", "", ""},
	}
	for _, c := range cases {
		if got := cweFor(c.kind, c.cat); got != c.want {
			t.Errorf("cweFor(%q,%q) = %q, want %q", c.kind, c.cat, got, c.want)
		}
	}
}

func TestCWECompatible(t *testing.T) {
	cases := []struct {
		a, b string
		want bool
	}{
		{"CWE-89", "CWE-89", true},   // exact
		{"cwe-89", "CWE-89", true},   // case-insensitive
		{" CWE-79 ", "CWE-79", true}, // trimmed
		{"CWE-79", "CWE-80", true},   // xss family alias
		{"CWE-78", "CWE-77", true},   // command-injection related
		{"CWE-22", "CWE-23", true},   // path-traversal family
		{"CWE-22", "CWE-36", true},   // path-traversal family
		{"CWE-787", "CWE-125", true}, // memory family
		{"CWE-787", "CWE-119", true}, // memory family
		{"CWE-89", "CWE-79", false},  // unrelated
		{"CWE-502", "CWE-89", false}, // deser stands alone
		{"", "CWE-89", false},        // empty
		{"CWE-89", "", false},        // empty
		{"", "", false},              // both empty
	}
	for _, c := range cases {
		if got := CWECompatible(c.a, c.b); got != c.want {
			t.Errorf("CWECompatible(%q,%q) = %v, want %v", c.a, c.b, got, c.want)
		}
		// symmetric
		if got := CWECompatible(c.b, c.a); got != c.want {
			t.Errorf("CWECompatible(%q,%q) [swapped] = %v, want %v", c.b, c.a, got, c.want)
		}
	}
}

func TestGradeOne(t *testing.T) {
	gt := GroundTruth{File: "src/auth.go", LineStart: 100, LineEnd: 110, CWE: "CWE-89"}

	cases := []struct {
		name string
		f    Finding
		w    int
		w2   int
		want Grade
	}{
		{"strong exact", Finding{File: "src/auth.go", Line: 105, CWE: "CWE-89"}, 0, 10, GradeStrong},
		{"strong basename match", Finding{File: "/abs/repo/auth.go", Line: 100, CWE: "CWE-89"}, 0, 10, GradeStrong},
		{"strong within w", Finding{File: "src/auth.go", Line: 112, CWE: "CWE-89"}, 5, 10, GradeStrong},
		{"partial: line only", Finding{File: "src/auth.go", Line: 105, CWE: "CWE-79"}, 0, 10, GradePartial},
		{"partial: cwe only", Finding{File: "src/auth.go", Line: 500, CWE: "CWE-89"}, 0, 10, GradePartial},
		{"partial: cwe-compat only via family", Finding{File: "src/auth.go", Line: 500, CWE: "CWE-89"}, 0, 10, GradePartial},
		{"no grade: wrong file", Finding{File: "src/other.go", Line: 105, CWE: "CWE-89"}, 0, 10, ""},
		{"no grade: far line + wrong cwe", Finding{File: "src/auth.go", Line: 5000, CWE: "CWE-79"}, 0, 10, ""},
		{"strong needs cwe: line ok but cwe wrong -> partial", Finding{File: "src/auth.go", Line: 105, CWE: "CWE-79"}, 0, 10, GradePartial},
		{"w2 boundary in: line 120 with w2=10", Finding{File: "src/auth.go", Line: 120, CWE: "CWE-79"}, 0, 10, GradePartial},
		{"w2 boundary out: line 121 with w2=10 wrong cwe -> none", Finding{File: "src/auth.go", Line: 121, CWE: "CWE-79"}, 0, 10, ""},
	}
	for _, c := range cases {
		if got := GradeOne(c.f, gt, c.w, c.w2); got != c.want {
			t.Errorf("%s: GradeOne = %q, want %q", c.name, got, c.want)
		}
	}
}

// partialOnlyAdj is an Adjudicator fake that confirms only PARTIAL pairs; it
// records that it was consulted so MatchFindings can assert delegation.
type partialOnlyAdj struct{ consulted int }

func (a *partialOnlyAdj) Adjudicate(f Finding, gt GroundTruth) (bool, string) {
	a.consulted++
	return true, "judge-confirmed"
}

func TestMatchFindings_StrongMissExtra(t *testing.T) {
	gts := []GroundTruth{
		{File: "a.go", LineStart: 10, LineEnd: 20, CWE: "CWE-89", IsPrimary: true},
		{File: "b.go", LineStart: 30, LineEnd: 40, CWE: "CWE-79"},
	}
	findings := []Finding{
		{Hash: "h1", File: "a.go", Line: 15, CWE: "CWE-89"}, // STRONG -> gt0
		{Hash: "h2", File: "z.go", Line: 99, CWE: "CWE-22"}, // matches nothing -> EXTRA
	}
	got := MatchFindings(findings, gts, nil, 0, 10)

	var strong, miss, extra int
	for _, m := range got {
		switch m.Grade {
		case GradeStrong:
			strong++
			if m.FindingHash != "h1" || m.GTIdx != 0 || m.DecidedBy != "rule" {
				t.Errorf("strong match wrong: %+v", m)
			}
		case GradeMiss:
			miss++
			if m.GTIdx != 1 || m.FindingHash != "" {
				t.Errorf("miss wrong: %+v", m)
			}
		case GradeExtra:
			extra++
			if m.FindingHash != "h2" || m.GTIdx != -1 {
				t.Errorf("extra wrong: %+v", m)
			}
		}
	}
	if strong != 1 || miss != 1 || extra != 1 {
		t.Fatalf("counts: strong=%d miss=%d extra=%d, want 1/1/1 (got %+v)", strong, miss, extra, got)
	}
}

func TestMatchFindings_AdjudicatorConsultedOnPartial(t *testing.T) {
	gts := []GroundTruth{{File: "a.go", LineStart: 10, LineEnd: 20, CWE: "CWE-89"}}
	// PARTIAL: same file + line-in-window but incompatible CWE.
	findings := []Finding{{Hash: "p1", File: "a.go", Line: 15, CWE: "CWE-79"}}

	adj := &partialOnlyAdj{}
	got := MatchFindings(findings, gts, adj, 0, 10)
	if adj.consulted == 0 {
		t.Fatal("adjudicator was not consulted on a PARTIAL pair")
	}
	if len(got) != 1 || got[0].Grade != GradePartial || got[0].DecidedBy != "judge" {
		t.Fatalf("expected judge-decided PARTIAL, got %+v", got)
	}

	// With nil adjudicator the PARTIAL still stands by rule.
	got2 := MatchFindings(findings, gts, nil, 0, 10)
	if len(got2) != 1 || got2[0].Grade != GradePartial || got2[0].DecidedBy != "rule" {
		t.Fatalf("expected rule-decided PARTIAL, got %+v", got2)
	}
}

func TestCaughtAtFloor(t *testing.T) {
	if !caughtAtFloor(GradeStrong, GradeStrong) {
		t.Error("STRONG should meet STRONG floor")
	}
	if caughtAtFloor(GradePartial, GradeStrong) {
		t.Error("PARTIAL should not meet STRONG floor")
	}
	if !caughtAtFloor(GradePartial, GradePartial) {
		t.Error("PARTIAL should meet PARTIAL floor")
	}
	if !caughtAtFloor(GradeStrong, GradePartial) {
		t.Error("STRONG should meet PARTIAL floor")
	}
}
