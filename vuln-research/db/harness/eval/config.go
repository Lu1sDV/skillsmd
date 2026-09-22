// config.go — externalized eval knobs read from db/seed/scoring.yml.
// Exists so the decision threshold γ is a tunable CONFIG VALUE, not a magic constant baked into
// the scorer: LLMxCPG (arXiv:2507.16585) calibrates its decision threshold γ on a small labeled
// validation set rather than hardcoding it and recommends per-dataset calibration; we mirror that
// by sourcing γ from config (calibrated by `vreval calibrate`) and defaulting forgivingly when the
// file or key is absent so existing setups keep their current behavior.

package eval

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// DefaultGamma is the decision threshold used when scoring.yml is missing or has
// no calibrated value. 0 accepts every finding (severity rank >= 0), preserving
// the pre-calibration behavior — calibration only ever tightens the gate.
const DefaultGamma = 0.0

// GammaScope / GammaKey locate the calibrated threshold inside scoring.yml's
// eval section. Mirrors scoring.yml's scope/config_key convention.
const (
	GammaScope = "eval"
	GammaKey   = "gamma_threshold"
)

// scoringFile is the partial shape of db/seed/scoring.yml we read/write. Only the
// eval section is modelled; scoring_config and any other keys are preserved
// verbatim on write because we patch the YAML node tree, not this struct.
type scoringFile struct {
	Eval struct {
		GammaThreshold float64 `yaml:"gamma_threshold"`
	} `yaml:"eval"`
}

// LoadGamma reads the calibrated decision threshold γ from scoring.yml at path.
// Forgiving by design: a missing file, an absent eval section, or an absent key
// all yield (DefaultGamma, nil) so existing corpora/configs still load. A genuine
// parse error is returned.
func LoadGamma(path string) (float64, error) {
	if path == "" {
		return DefaultGamma, nil
	}
	buf, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return DefaultGamma, nil
		}
		return DefaultGamma, fmt.Errorf("eval: LoadGamma: read %s: %w", path, err)
	}
	var sf scoringFile
	if err := yaml.Unmarshal(buf, &sf); err != nil {
		return DefaultGamma, fmt.Errorf("eval: LoadGamma: parse %s: %w", path, err)
	}
	return sf.Eval.GammaThreshold, nil
}

// WriteGamma persists the calibrated γ into the eval.gamma_threshold key of
// scoring.yml at path, preserving every other key, comment, and ordering by
// editing the YAML node tree in place. The eval section (and its key) is created
// if absent. The file must already exist (it ships in db/seed/).
func WriteGamma(path string, gamma float64) error {
	buf, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("eval: WriteGamma: read %s: %w", path, err)
	}
	var root yaml.Node
	if err := yaml.Unmarshal(buf, &root); err != nil {
		return fmt.Errorf("eval: WriteGamma: parse %s: %w", path, err)
	}
	if root.Kind != yaml.DocumentNode || len(root.Content) == 0 {
		return fmt.Errorf("eval: WriteGamma: %s is not a YAML mapping document", path)
	}
	doc := root.Content[0]
	if doc.Kind != yaml.MappingNode {
		return fmt.Errorf("eval: WriteGamma: %s top level is not a mapping", path)
	}

	gammaVal := fmt.Sprintf("%g", gamma)
	if evalMap := mappingValue(doc, GammaScope); evalMap != nil {
		setMappingScalar(evalMap, GammaKey, gammaVal)
	} else {
		doc.Content = append(doc.Content,
			&yaml.Node{Kind: yaml.ScalarNode, Tag: "!!str", Value: GammaScope},
			&yaml.Node{Kind: yaml.MappingNode, Content: []*yaml.Node{
				{Kind: yaml.ScalarNode, Tag: "!!str", Value: GammaKey},
				{Kind: yaml.ScalarNode, Tag: "!!float", Value: gammaVal},
			}},
		)
	}

	out, err := yaml.Marshal(&root)
	if err != nil {
		return fmt.Errorf("eval: WriteGamma: marshal: %w", err)
	}
	if err := os.WriteFile(path, out, 0o644); err != nil {
		return fmt.Errorf("eval: WriteGamma: write %s: %w", path, err)
	}
	return nil
}

// mappingValue returns the value node for key in a mapping node, or nil.
func mappingValue(m *yaml.Node, key string) *yaml.Node {
	for i := 0; i+1 < len(m.Content); i += 2 {
		if m.Content[i].Value == key {
			return m.Content[i+1]
		}
	}
	return nil
}

// setMappingScalar sets (or appends) key=val as a float scalar in mapping m.
func setMappingScalar(m *yaml.Node, key, val string) {
	for i := 0; i+1 < len(m.Content); i += 2 {
		if m.Content[i].Value == key {
			m.Content[i+1].Kind = yaml.ScalarNode
			m.Content[i+1].Tag = "!!float"
			m.Content[i+1].Value = val
			return
		}
	}
	m.Content = append(m.Content,
		&yaml.Node{Kind: yaml.ScalarNode, Tag: "!!str", Value: key},
		&yaml.Node{Kind: yaml.ScalarNode, Tag: "!!float", Value: val},
	)
}
