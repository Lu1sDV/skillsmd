// main.go — thin CLI over the eval library: import-corpus / emit-manifest / ingest / score.
// Exists so the benchmark can be driven from shell scripts without linking the Go package — one
// binary, four subcommands; mirrors cmd/vrdb's dispatch-on-os.Args[1] + flag.FlagSet style.

package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"

	"vrdb"
	"vrdb/eval"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "vreval:", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) == 0 {
		return usage()
	}
	switch args[0] {
	case "import-corpus":
		return runImportCorpus(args[1:])
	case "emit-manifest":
		return runEmitManifest(args[1:])
	case "ingest":
		return runIngest(args[1:])
	case "score":
		return runScore(args[1:])
	case "calibrate":
		return runCalibrate(args[1:])
	case "-h", "--help", "help":
		return usage()
	default:
		return fmt.Errorf("unknown subcommand %q (try `vreval help`)", args[0])
	}
}

func usage() error {
	fmt.Fprint(os.Stderr, `vreval — eval harness CLI over the vuln-research DuckDB benchmark.

usage:
  vreval import-corpus <eval.duckdb> <corpus.jsonl>
  vreval emit-manifest <eval.duckdb> -tier <t> -seeds <n> -out <file> [-cutoff YYYY-MM-DD] [-prefer-post-cutoff] <corpusID...>
  vreval ingest <eval.duckdb> <produced.duckdb> -manifest <uid> -corpus <id> -mode <m> -seed <n> [-tier <t>] [-kloc <f>]
  vreval score <eval.duckdb> -manifest <uid> [-floor STRONG] [-scoring <scoring.yml>]
  vreval calibrate <split.json> -scoring <scoring.yml>
`)
	return nil
}

func runImportCorpus(args []string) error {
	if len(args) != 2 {
		return errors.New("import-corpus: expected <eval.duckdb> <corpus.jsonl>")
	}
	db, err := vrdb.Open(args[0])
	if err != nil {
		return err
	}
	defer db.Close()
	n, err := eval.ImportCorpus(context.Background(), db, args[1])
	if err != nil {
		return err
	}
	fmt.Printf("imported %d corpus rows\n", n)
	return nil
}

func runEmitManifest(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("emit-manifest", flag.ContinueOnError)
	tier := fs.String("tier", "", "effort tier (low|medium|deep)")
	seeds := fs.Int("seeds", 1, "seeds per (corpus, mode)")
	out := fs.String("out", "", "output manifest path (required)")
	cutoff := fs.String("cutoff", "", "PKCO knowledge-cutoff date YYYY-MM-DD")
	preferPostCutoff := fs.Bool("prefer-post-cutoff", false, "keep only samples disclosed after -cutoff (default off)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) < 2 {
		return errors.New("emit-manifest: expected <eval.duckdb> <corpusID...>")
	}
	if *out == "" {
		return errors.New("emit-manifest: -out is required")
	}
	ids := make([]int, 0, len(positional)-1)
	for _, s := range positional[1:] {
		id, err := strconv.Atoi(s)
		if err != nil {
			return fmt.Errorf("emit-manifest: bad corpus id %q: %w", s, err)
		}
		ids = append(ids, id)
	}

	db, err := vrdb.Open(positional[0])
	if err != nil {
		return err
	}
	defer db.Close()
	uid, items, err := eval.EmitManifest(context.Background(), db, ids, *tier, *seeds, *out, *cutoff, *preferPostCutoff)
	if err != nil {
		return err
	}
	fmt.Printf("manifest %s: %d items -> %s\n", uid, len(items), *out)
	return nil
}

func runIngest(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("ingest", flag.ContinueOnError)
	manifest := fs.String("manifest", "", "manifest uid (required)")
	corpus := fs.Int("corpus", 0, "corpus id (required)")
	mode := fs.String("mode", "", "vuln|control (required)")
	seed := fs.Int("seed", 0, "seed")
	tier := fs.String("tier", "", "effort tier")
	kloc := fs.Float64("kloc", 0, "kloc scanned")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) != 2 {
		return errors.New("ingest: expected <eval.duckdb> <produced.duckdb>")
	}
	if *manifest == "" || *mode == "" {
		return errors.New("ingest: -manifest and -mode are required")
	}

	evalDB, err := vrdb.Open(positional[0])
	if err != nil {
		return err
	}
	defer evalDB.Close()
	producedDB, err := vrdb.Open(positional[1])
	if err != nil {
		return err
	}
	defer producedDB.Close()

	if err := eval.Ingest(context.Background(), evalDB, producedDB, *manifest, *corpus, *seed, *mode, *tier, *kloc); err != nil {
		return err
	}
	fmt.Printf("ingested corpus=%d mode=%s seed=%d\n", *corpus, *mode, *seed)
	return nil
}

func runScore(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("score", flag.ContinueOnError)
	manifest := fs.String("manifest", "", "manifest uid (required)")
	floor := fs.String("floor", "STRONG", "recall floor grade (STRONG|PARTIAL)")
	scoring := fs.String("scoring", "", "path to scoring.yml for the calibrated γ threshold (optional)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) != 1 {
		return errors.New("score: expected <eval.duckdb>")
	}
	if *manifest == "" {
		return errors.New("score: -manifest is required")
	}

	// γ is sourced from externalized config, never a constant. Absent file/key ->
	// eval.DefaultGamma (accept-all), preserving the uncalibrated behavior.
	gamma, err := eval.LoadGamma(*scoring)
	if err != nil {
		return err
	}

	db, err := vrdb.Open(positional[0])
	if err != nil {
		return err
	}
	defer db.Close()

	if err := eval.ScoreManifest(context.Background(), db, *manifest, nil, eval.Grade(*floor), 0, 10, gamma); err != nil {
		return err
	}
	rows, err := db.Fetch(context.Background(), "SELECT scope, scope_key, recall_at_1, recall_at_k, fp_per_kloc FROM eval_result WHERE manifest_uid = ?", *manifest)
	if err != nil {
		return err
	}
	enc := json.NewEncoder(os.Stdout)
	for _, r := range rows {
		if err := enc.Encode(r); err != nil {
			return err
		}
	}
	return nil
}

// runCalibrate fits the decision threshold γ on a small labeled validation split
// (JSON []eval.LabeledSample), then persists the F1-maximizing value into
// scoring.yml so the score path reads it back via LoadGamma — no magic constant.
// Mirrors LLMxCPG's per-dataset γ calibration (arXiv:2507.16585).
func runCalibrate(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("calibrate", flag.ContinueOnError)
	scoring := fs.String("scoring", "", "path to scoring.yml to update (required)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) != 1 {
		return errors.New("calibrate: expected <split.json>")
	}
	if *scoring == "" {
		return errors.New("calibrate: -scoring is required")
	}

	buf, err := os.ReadFile(positional[0])
	if err != nil {
		return err
	}
	var split []eval.LabeledSample
	if err := json.Unmarshal(buf, &split); err != nil {
		return fmt.Errorf("calibrate: parse split: %w", err)
	}

	gamma, f1 := eval.CalibrateGamma(split)
	if err := eval.WriteGamma(*scoring, gamma); err != nil {
		return err
	}
	fmt.Printf("calibrated gamma=%g (f1=%.4f over %d samples) -> %s\n", gamma, f1, len(split), *scoring)
	return nil
}

// splitArgs separates flag tokens from positional tokens so callers can write the
// db/produced paths and corpus ids interchangeably around the flags. Mirrors
// cmd/vrdb.splitArgs.
func splitArgs(args []string) (flagArgs, positional []string) {
	for i := 0; i < len(args); i++ {
		a := args[i]
		if len(a) > 0 && a[0] == '-' {
			flagArgs = append(flagArgs, a)
			if i+1 < len(args) && !strings.Contains(a, "=") {
				flagArgs = append(flagArgs, args[i+1])
				i++
			}
			continue
		}
		positional = append(positional, a)
	}
	return flagArgs, positional
}
