// corpus.go — ImportCorpus: load a labeled CVE corpus from JSONL into eval_corpus.
// Exists so the benchmark's ground-truth set is populated through the same idempotent Put path
// as the rest of the harness, with ground_truth re-marshalled into the eval_corpus.ground_truth_json column.

package eval

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"

	"vrdb"
)

// corpusLine is one JSONL entry; ground_truth is re-marshalled into ground_truth_json on insert.
type corpusLine struct {
	Source      string        `json:"source"`
	CVEID       string        `json:"cve_id"`
	RepoURL     string        `json:"repo_url"`
	VulnCommit  string        `json:"vuln_commit"`
	FixCommit   string        `json:"fix_commit"`
	PrimaryCWE  string        `json:"primary_cwe"`
	Language    string        `json:"language"`
	GroundTruth []GroundTruth `json:"ground_truth"`
}

// ImportCorpus reads one corpus entry per line from jsonlPath and Puts each into
// eval_corpus, returning the number of rows imported. Blank lines are skipped.
func ImportCorpus(ctx context.Context, db *vrdb.DB, jsonlPath string) (int, error) {
	f, err := os.Open(jsonlPath)
	if err != nil {
		return 0, fmt.Errorf("eval: ImportCorpus: open: %w", err)
	}
	defer f.Close()

	now := time.Now().UTC().Format("2006-01-02 15:04:05")
	count := 0
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 0, 64*1024), 4*1024*1024)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" {
			continue
		}
		var cl corpusLine
		if err := json.Unmarshal([]byte(line), &cl); err != nil {
			return count, fmt.Errorf("eval: ImportCorpus: line %d: %w", count+1, err)
		}
		gt, err := json.Marshal(cl.GroundTruth)
		if err != nil {
			return count, fmt.Errorf("eval: ImportCorpus: marshal ground_truth: %w", err)
		}
		row := map[string]any{
			"source":            cl.Source,
			"cve_id":            cl.CVEID,
			"repo_url":          cl.RepoURL,
			"vuln_commit":       cl.VulnCommit,
			"fix_commit":        cl.FixCommit,
			"primary_cwe":       cl.PrimaryCWE,
			"language":          cl.Language,
			"ground_truth_json": string(gt),
			"added_at":          now,
		}
		if err := db.Put(ctx, "eval_corpus", []map[string]any{row}); err != nil {
			return count, fmt.Errorf("eval: ImportCorpus: put: %w", err)
		}
		count++
	}
	if err := sc.Err(); err != nil {
		return count, fmt.Errorf("eval: ImportCorpus: scan: %w", err)
	}
	return count, nil
}
