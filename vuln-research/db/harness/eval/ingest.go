// ingest.go — Ingest: snapshot a produced audit's gr_findings into one eval_run row.
// Exists to bridge the audit DB (which has no file/line/cwe on gr_findings) to the eval schema:
// it resolves file/line sink-first via the sinks/sources joins and derives a CWE from finding_kind.

package eval

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"vrdb"
)

// Ingest reads every gr_findings row from producedDB (resolving file/line and
// CWE), then Puts one eval_run row for the (corpus, mode, seed) keyed by
// manifestUID. tier "" is stored as NULL.
func Ingest(ctx context.Context, evalDB, producedDB *vrdb.DB, manifestUID string, corpusID, seed int, mode, tier string, kloc float64) error {
	rows, err := producedDB.Fetch(ctx, `
		SELECT f.finding_hash, f.finding_kind, f.severity, f.confirmation_status,
		       sk.evidence_path AS sink_path, sk.evidence_line AS sink_line, sk.sink_category,
		       so.evidence_path AS src_path,  so.evidence_line AS src_line
		FROM gr_findings f
		LEFT JOIN sinks   sk ON f.sink_id   = sk.id
		LEFT JOIN sources so ON f.source_id = so.id`)
	if err != nil {
		return fmt.Errorf("eval: Ingest: query gr_findings: %w", err)
	}

	findings := make([]Finding, 0, len(rows))
	for _, r := range rows {
		fk := asString(r["finding_kind"])
		sc := asString(r["sink_category"])
		file, line := resolveLoc(r)
		findings = append(findings, Finding{
			Hash:     asString(r["finding_hash"]),
			Kind:     fk,
			CWE:      cweFor(fk, sc),
			File:     file,
			Line:     line,
			Severity: asString(r["severity"]),
			Status:   asString(r["confirmation_status"]),
		})
	}

	buf, err := json.Marshal(findings)
	if err != nil {
		return fmt.Errorf("eval: Ingest: marshal findings: %w", err)
	}

	var tierVal any
	if tier != "" {
		tierVal = tier
	}
	row := map[string]any{
		"corpus_id":     corpusID,
		"manifest_uid":  manifestUID,
		"mode":          mode,
		"seed":          seed,
		"tier":          tierVal,
		"kloc_scanned":  kloc,
		"findings_json": string(buf),
		"ingested_at":   time.Now().UTC().Format("2006-01-02 15:04:05"),
	}
	if err := evalDB.Put(ctx, "eval_run", []map[string]any{row}); err != nil {
		return fmt.Errorf("eval: Ingest: put eval_run: %w", err)
	}
	return nil
}

// resolveLoc picks the finding's file/line sink-first: the sink join's
// evidence_path, else the source's, else "" / 0.
func resolveLoc(r map[string]any) (string, int) {
	if p := asString(r["sink_path"]); p != "" {
		return p, asInt(r["sink_line"])
	}
	if p := asString(r["src_path"]); p != "" {
		return p, asInt(r["src_line"])
	}
	return "", 0
}

// cweFor maps a finding_kind (preferred) or sink_category to a CWE id; "" when
// neither is known. Keys are lowercased exact matches.
func cweFor(findingKind, sinkCategory string) string {
	table := map[string]string{
		"sqli":              "CWE-89",
		"sql_injection":     "CWE-89",
		"xss":               "CWE-79",
		"command_injection": "CWE-78",
		"rce":               "CWE-78",
		"os_command":        "CWE-78",
		"path_traversal":    "CWE-22",
		"ssrf":              "CWE-918",
		"deserialization":   "CWE-502",
		"xxe":               "CWE-611",
		"open_redirect":     "CWE-601",
		"fuzz_crash":        "CWE-787",
		"auth_bypass":       "CWE-287",
		"idor":              "CWE-639",
	}
	if c, ok := table[lower(findingKind)]; ok {
		return c
	}
	if c, ok := table[lower(sinkCategory)]; ok {
		return c
	}
	return ""
}
