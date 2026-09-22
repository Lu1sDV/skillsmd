// calibrate_test.go — smoke test for γ-style threshold calibration (thread a).
// Proves the full loop: calibrate on a tiny labeled fixture -> a threshold; persist it to a
// scoring.yml copy; the eval path reads it back via LoadGamma (a config value, not a constant).

package eval

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGammaCalibration_FitsPersistsAndReadsBack(t *testing.T) {
	// Tiny labeled validation split: HIGH/CRITICAL findings are real vulns, LOW
	// ones are noise. The F1-maximizing γ should be the one that keeps the real
	// vulns (severity rank >= 3) and drops the low-severity noise.
	split := []LabeledSample{
		{Finding: Finding{Hash: "a", Severity: "critical"}, IsVuln: true},
		{Finding: Finding{Hash: "b", Severity: "high"}, IsVuln: true},
		{Finding: Finding{Hash: "c", Severity: "low"}, IsVuln: false},
		{Finding: Finding{Hash: "d", Severity: "low"}, IsVuln: false},
		{Finding: Finding{Hash: "e", Severity: "medium"}, IsVuln: false},
	}

	gamma, f1 := CalibrateGamma(split)
	if gamma <= DefaultGamma {
		t.Fatalf("calibration did not raise γ above the default: got %g", gamma)
	}
	if gamma != 3 {
		t.Errorf("expected γ=3 (keep high/critical, drop low/medium), got %g", gamma)
	}
	if f1 != 1.0 {
		t.Errorf("expected perfect separation f1=1.0, got %g", f1)
	}

	// Persist into a copy of the real seed scoring.yml so we exercise the
	// node-tree-preserving writer against the actual file shape.
	src, err := os.ReadFile(filepath.FromSlash("../../seed/scoring.yml"))
	if err != nil {
		t.Fatalf("read seed scoring.yml: %v", err)
	}
	cfgPath := filepath.Join(t.TempDir(), "scoring.yml")
	if err := os.WriteFile(cfgPath, src, 0o644); err != nil {
		t.Fatalf("copy scoring.yml: %v", err)
	}
	if err := WriteGamma(cfgPath, gamma); err != nil {
		t.Fatalf("WriteGamma: %v", err)
	}

	// The eval path reads γ back from config — not a constant.
	got, err := LoadGamma(cfgPath)
	if err != nil {
		t.Fatalf("LoadGamma: %v", err)
	}
	if got != gamma {
		t.Fatalf("γ did not round-trip through config: wrote %g, read %g", gamma, got)
	}

	// Other config (scoring_config weights) must survive the write untouched.
	out, err := os.ReadFile(cfgPath)
	if err != nil {
		t.Fatalf("re-read cfg: %v", err)
	}
	if !strings.Contains(string(out), "w_reachability") || !strings.Contains(string(out), "scoring_config") {
		t.Fatal("WriteGamma clobbered unrelated scoring_config keys")
	}
}

func TestLoadGamma_ForgivingDefaults(t *testing.T) {
	// Empty path -> default.
	if g, err := LoadGamma(""); err != nil || g != DefaultGamma {
		t.Fatalf("empty path: got (%g,%v), want (%g,nil)", g, err, DefaultGamma)
	}
	// Missing file -> default (back-compat: config absent).
	missing := filepath.Join(t.TempDir(), "nope.yml")
	if g, err := LoadGamma(missing); err != nil || g != DefaultGamma {
		t.Fatalf("missing file: got (%g,%v), want (%g,nil)", g, err, DefaultGamma)
	}
	// File without an eval section -> default.
	noEval := filepath.Join(t.TempDir(), "noeval.yml")
	if err := os.WriteFile(noEval, []byte("scoring_config:\n  - scope: x\n    config_key: y\n    weight: 1.0\n"), 0o644); err != nil {
		t.Fatalf("write noeval: %v", err)
	}
	if g, err := LoadGamma(noEval); err != nil || g != DefaultGamma {
		t.Fatalf("no eval section: got (%g,%v), want (%g,nil)", g, err, DefaultGamma)
	}
}
