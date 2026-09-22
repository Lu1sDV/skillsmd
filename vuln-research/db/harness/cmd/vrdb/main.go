// main.go — thin CLI shim over the vrdb library: `vrdb put TABLE --db PATH` reads JSONL rows from stdin,
// `vrdb fetch SQL --db PATH` writes result rows as JSONL to stdout, `vrdb gate --db PATH` runs the
// completion-gate queries and exits non-zero if any hard-red gate fires.
// Exists so the vuln-research orchestrator (and shell scripts / ad-hoc debugging) can flush row events,
// re-read findings, and mechanically enforce completion gates without linking the Go library.
// How: dispatch on os.Args[1], decode JSONL with json.Decoder, call vrdb.Put / vrdb.Fetch, emit JSONL;
// invoked from the v2 orchestrator pipeline and from the harness/temp scratch scripts.

package main

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"vrdb"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "vrdb:", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) == 0 {
		return usage()
	}
	switch args[0] {
	case "put":
		return runPut(args[1:])
	case "exec":
		return runExec(args[1:])
	case "fetch":
		return runFetch(args[1:])
	case "gate":
		return runGate(args[1:])
	case "impact-proof":
		return runImpactProof(args[1:])
	case "promote":
		return runPromote(args[1:])
	case "close-step":
		return runCloseStep(args[1:])
	case "checkpoint":
		return runCheckpoint(args[1:])
	case "snapshot":
		return runSnapshot(args[1:])
	case "hash":
		return runHash(args[1:])
	case "run-tool":
		return runRunTool(args[1:])
	case "history":
		return runHistory(args[1:])
	case "diff":
		return runDiff(args[1:])
	case "log":
		return runLog(args[1:])
	case "selftest", "doctor":
		return runSelftest(args[1:])
	case "-h", "--help", "help":
		return usage()
	default:
		return fmt.Errorf("unknown subcommand %q (try `vrdb help`)", args[0])
	}
}

func usage() error {
	fmt.Fprint(os.Stderr, `vrdb — put/fetch/inspect/gate CLI over the vuln-research DuckDB harness.

usage:
  vrdb put TABLE --db PATH         # read JSONL rows from stdin, insert into TABLE (idempotent)
  vrdb exec "SQL" --db PATH        # run a DML/DDL statement; prints {"rows_affected":N}
  vrdb fetch SQL  --db PATH        # run SQL, write each row as one JSONL line to stdout
  vrdb gate --db PATH [--tier deep]     # ONE completion verdict (all gate views ANDed); exits non-zero on any red
  vrdb impact-proof FINDING_ID --db PATH --consumer-symbol SYM --harm-class CLASS [--reachability-evidence REF] [--proven-reachability proven|conditional|unproven] [--mechanism-cap dos_only|leak|write_what_where|none] [--severity-basis NOTE]  # Gate-5 consumer-harm write (promote precondition)
  vrdb promote FINDING_ID --db PATH --severity SEV --rigor-tier TIER  # the ONLY path to confirmed (requires an impact-proof row first; one tx)
  vrdb close-step STEP_ID --db PATH --status TERMINAL --observations FILE.jsonl  # flush obs + flip step (one tx)
  vrdb checkpoint --db PATH              # FORCE CHECKPOINT (durable WAL flush at a phase boundary)
  vrdb snapshot  --db PATH --label NAME  # copy the DB file before a HEAVY lane (auto-restore source)
  vrdb hash TABLE --db PATH              # read JSONL rows from stdin, emit the pinned content_fingerprint per row
  vrdb run-tool --mem CAP [--lock NAME] -- CMD ARGS…  # run a heavy tool under a memory cap + flock + concurrency=1
  vrdb history FINDING_HASH --db PATH   # per-finding timeline (sightings + mutations), oldest first
  vrdb diff --db PATH [--round N]       # per-round mutation rollup (v_round_diff)
  vrdb log  --db PATH [--table T] [--limit N]  # raw mutation_log, newest first (default --limit 50)
  vrdb selftest [--db PATH] [--skill-version V] [--min-skill-version V]  # write-contract + data-quality asserts (alias: doctor)

The history/diff/log subcommands read the migration-0005 inspection views, so the
query logic lives in SQL (db/schema.sql) and the CLI stays a thin wrapper.

examples:
  echo '{"repo_url":"...","commit_sha":"...","language":"go","scanned_at":"2026-05-17 00:00:00"}' \
    | vrdb put targets --db audit.duckdb
  vrdb fetch 'SELECT * FROM targets' --db audit.duckdb
  vrdb gate --db audit.duckdb --tier deep
  vrdb history fnd-abc123 --db audit.duckdb
  vrdb diff --round 4 --db audit.duckdb
  vrdb log --table gr_findings --limit 20 --db audit.duckdb
`)
	return nil
}

// emitRows writes each result row as one JSONL line to stdout, line-buffered so
// callers (jq, the orchestrator) can stream. Shared by the read subcommands.
func emitRows(rows []map[string]any) error {
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	enc := json.NewEncoder(out)
	for _, r := range rows {
		if err := enc.Encode(r); err != nil {
			return fmt.Errorf("encode row: %w", err)
		}
	}
	return nil
}

// runGate (T3-09 / S-P08) reads ONE completion verdict from the DB via vrdb.Gate, which ANDs
// every hard-red gate view/metric — the pre-existing PROCESS gates (v_coverage hard-red metrics,
// v_lane_coverage MISSING, v_observation_coverage NO_OBSERVATION, v_phase_status incomplete) AND
// the v0.40 OUTCOME-justification gates (v_promotion_coverage UNJUSTIFIED, v_justification_coverage
// UNJUSTIFIED_NO_CONSUMER, v_sp_oracle_coverage RED, v_invariant_promotion_coverage RED). It prints
// a JSON summary {"tier","passed","empty_result","red_gates":[...]} and exits non-zero on any red,
// so the orchestrator can wire `vrdb gate --db PATH || fail` and never hold 25 metrics in context.
func runGate(args []string) error {
	flagArgs, _ := splitArgs(args)
	fs := flag.NewFlagSet("gate", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	tier := fs.String("tier", "deep", "audit tier to gate against (currently: deep)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if *dbPath == "" {
		return errors.New("gate: --db is required")
	}

	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()

	gr, err := db.Gate(context.Background())
	if err != nil {
		return fmt.Errorf("gate: %w", err)
	}
	reds := gr.Reds
	if reds == nil {
		reds = []string{}
	}
	summary := struct {
		Tier        string   `json:"tier"`
		Passed      bool     `json:"passed"`
		EmptyResult bool     `json:"empty_result"`
		RedGates    []string `json:"red_gates"`
	}{*tier, gr.Passed, gr.EmptyResult, reds}

	out := bufio.NewWriter(os.Stdout)
	enc := json.NewEncoder(out)
	enc.SetIndent("", "  ")
	if err := enc.Encode(summary); err != nil {
		out.Flush()
		return fmt.Errorf("gate: encode output: %w", err)
	}
	out.Flush()

	if !gr.Passed {
		return fmt.Errorf("gate: %d hard-red gate(s) fired — audit is NOT complete", len(gr.Reds))
	}
	return nil
}

// runImpactProof is the CLI for the Gate-5 CONSUMER-HARM write (T2-07): it records the
// impact_proofs row naming the harmed default-config consumer + harm_class + reachability/
// mechanism_cap factors. This is a PROMOTE PRECONDITION — promote refuses a finding with no
// impact_proofs row (a sink reached is NOT a consumer harmed). Idempotent on the proof_hash NK.
func runImpactProof(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("impact-proof", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	consumer := fs.String("consumer-symbol", "", "the default-config component harmed (required)")
	harm := fs.String("harm-class", "", "harm class: rce|info_leak|dos|authz_bypass|ssrf|... (required)")
	reachRef := fs.String("reachability-evidence", "", "pointer proving the consumer is reachable under default config (optional)")
	provenReach := fs.String("proven-reachability", "", "proven|conditional|unproven (optional)")
	mechCap := fs.String("mechanism-cap", "", "dos_only|leak|write_what_where|none (optional)")
	sevBasis := fs.String("severity-basis", "", "free-text note: how severity was derived from the rubric (optional)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) != 1 {
		return errors.New("impact-proof: expected exactly one FINDING_ID argument")
	}
	if *dbPath == "" {
		return errors.New("impact-proof: --db is required")
	}
	var fid int64
	if _, err := fmt.Sscan(positional[0], &fid); err != nil {
		return fmt.Errorf("impact-proof: FINDING_ID %q is not an integer: %w", positional[0], err)
	}

	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()

	if err := db.ImpactProof(context.Background(), fid, vrdb.ImpactProofOpts{
		ConsumerSymbol:      *consumer,
		HarmClass:           *harm,
		ReachabilityEvidRef: *reachRef,
		ProvenReachability:  *provenReach,
		MechanismCap:        *mechCap,
		SeverityBasis:       *sevBasis,
	}); err != nil {
		return err
	}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	return json.NewEncoder(out).Encode(struct {
		Finding       int64  `json:"impact_proof_for_finding_id"`
		ConsumerSymbol string `json:"consumer_symbol"`
		HarmClass     string `json:"harm_class"`
	}{fid, *consumer, *harm})
}

// runPromote is the CLI for the ONLY path to confirmed (T3-01): in one tx it verifies the
// refutation was overcome + critic eligibility=OK + an impact_proofs row exists, stamps severity +
// rigor tier, writes the mutation_log status_transition row, and flips the finding to confirmed.
func runPromote(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("promote", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	severity := fs.String("severity", "", "computed severity: LOW|MEDIUM|HIGH|CRITICAL (required)")
	rigor := fs.String("rigor-tier", "", "confirmation rigor: shallow|independent|reproduced (required)")
	roundID := fs.Int64("round", -1, "round_id provenance (optional)")
	stepID := fs.Int64("step", -1, "agent_step_id provenance (optional)")
	phase := fs.String("phase", "", "phase provenance (optional)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) != 1 {
		return errors.New("promote: expected exactly one FINDING_ID argument")
	}
	if *dbPath == "" {
		return errors.New("promote: --db is required")
	}
	var fid int64
	if _, err := fmt.Sscan(positional[0], &fid); err != nil {
		return fmt.Errorf("promote: FINDING_ID %q is not an integer: %w", positional[0], err)
	}

	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()

	opts := vrdb.PromoteOpts{Severity: *severity, RigorTier: *rigor, Phase: *phase}
	if *roundID >= 0 {
		r := *roundID
		opts.RoundID = &r
	}
	if *stepID >= 0 {
		s := *stepID
		opts.AgentStepID = &s
	}
	if err := db.Promote(context.Background(), fid, opts); err != nil {
		return err
	}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	return json.NewEncoder(out).Encode(struct {
		Promoted  int64  `json:"promoted_finding_id"`
		Severity  string `json:"severity"`
		RigorTier string `json:"rigor_tier"`
	}{fid, *severity, *rigor})
}

// runCloseStep is the CLI for the transactional step-close (T3-03): it flushes the observations
// in --observations (a JSONL file) and flips the step to --status, rejecting the close of a
// required DEEP lane carrying zero dead_end/invariant/blind_spot observations.
func runCloseStep(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("close-step", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	status := fs.String("status", "", "terminal status: success|exhausted|failed|timed_out|skipped (required)")
	obsPath := fs.String("observations", "", "path to a JSONL file of agent_observations rows (optional)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) != 1 {
		return errors.New("close-step: expected exactly one STEP_ID argument")
	}
	if *dbPath == "" {
		return errors.New("close-step: --db is required")
	}
	if *status == "" {
		return errors.New("close-step: --status is required")
	}
	var sid int64
	if _, err := fmt.Sscan(positional[0], &sid); err != nil {
		return fmt.Errorf("close-step: STEP_ID %q is not an integer: %w", positional[0], err)
	}

	var observations []map[string]any
	if *obsPath != "" {
		f, err := os.Open(*obsPath)
		if err != nil {
			return fmt.Errorf("close-step: open observations: %w", err)
		}
		observations, err = decodeJSONL(f)
		_ = f.Close()
		if err != nil {
			return fmt.Errorf("close-step: decode observations: %w", err)
		}
	}

	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()

	if err := db.CloseStep(context.Background(), sid, *status, observations); err != nil {
		return err
	}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	return json.NewEncoder(out).Encode(struct {
		Step         int64  `json:"closed_step_id"`
		Status       string `json:"status"`
		Observations int    `json:"observations_flushed"`
	}{sid, *status, len(observations)})
}

// runCheckpoint forces a durable WAL flush (T3-06).
func runCheckpoint(args []string) error {
	flagArgs, _ := splitArgs(args)
	fs := flag.NewFlagSet("checkpoint", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if *dbPath == "" {
		return errors.New("checkpoint: --db is required")
	}
	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()
	if err := db.Checkpoint(context.Background()); err != nil {
		return err
	}
	fmt.Fprintln(os.Stdout, `{"checkpoint":"ok"}`)
	return nil
}

// runSnapshot copies the DB file (after a checkpoint) before a HEAVY lane (T3-06).
func runSnapshot(args []string) error {
	flagArgs, _ := splitArgs(args)
	fs := flag.NewFlagSet("snapshot", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	label := fs.String("label", "", "snapshot label (required)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if *dbPath == "" {
		return errors.New("snapshot: --db is required")
	}
	if *label == "" {
		return errors.New("snapshot: --label is required")
	}
	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()
	path, err := db.Snapshot(context.Background(), *label)
	if err != nil {
		return err
	}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	return json.NewEncoder(out).Encode(struct {
		Snapshot string `json:"snapshot_path"`
	}{path})
}

// runHash reads JSONL rows from stdin and emits, per row, the pinned content_fingerprint so a
// caller can pin the recipe (T3-04). The TABLE positional is accepted for symmetry/documentation
// (the fingerprint recipe is table-agnostic — it hashes the row's semantic columns).
func runHash(args []string) error {
	_, positional := splitArgs(args)
	if len(positional) != 1 {
		return errors.New("hash: expected exactly one TABLE argument")
	}
	rows, err := decodeJSONL(os.Stdin)
	if err != nil {
		return fmt.Errorf("hash: decode stdin: %w", err)
	}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	enc := json.NewEncoder(out)
	for _, r := range rows {
		if err := enc.Encode(struct {
			Table       string `json:"table"`
			Fingerprint string `json:"content_fingerprint"`
		}{positional[0], vrdb.ContentFingerprint(r)}); err != nil {
			return fmt.Errorf("hash: encode: %w", err)
		}
	}
	return nil
}

// runRunTool runs everything after `--` under a memory cap + flock + concurrency=1 (T3-07).
// Usage: vrdb run-tool --mem 20G [--lock NAME] -- prog arg1 arg2…
func runRunTool(args []string) error {
	// Manual parse: everything after the first standalone "--" is the command.
	var mem, lock string
	var cmd []string
	i := 0
	for ; i < len(args); i++ {
		a := args[i]
		if a == "--" {
			cmd = args[i+1:]
			break
		}
		switch a {
		case "--mem", "--memory", "--memorymax":
			if i+1 >= len(args) {
				return errors.New("run-tool: --mem needs a value")
			}
			mem = args[i+1]
			i++
		case "--lock":
			if i+1 >= len(args) {
				return errors.New("run-tool: --lock needs a value")
			}
			lock = args[i+1]
			i++
		default:
			return fmt.Errorf("run-tool: unexpected arg %q before `--` (usage: vrdb run-tool --mem CAP [--lock NAME] -- CMD ARGS…)", a)
		}
	}
	if len(cmd) == 0 {
		return errors.New("run-tool: no command after `--`")
	}
	if mem == "" {
		return errors.New("run-tool: --mem CAP is required (the cap is the point of the wrapper)")
	}
	return vrdb.RunTool(context.Background(), cmd, vrdb.RunToolOpts{MemoryMax: mem, LockName: lock})
}

// runHistory reconstructs one finding's timeline from v_finding_history: every
// sighting (with its change_scope) interleaved with every gr_findings mutation,
// oldest first — the #6 "what happened to this finding, and why" view.
func runHistory(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("history", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) != 1 {
		return errors.New("history: expected exactly one FINDING_HASH argument")
	}
	if *dbPath == "" {
		return errors.New("history: --db is required")
	}

	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()

	rows, err := db.Fetch(context.Background(),
		"SELECT * FROM v_finding_history WHERE finding_hash = ? ORDER BY event_at",
		positional[0])
	if err != nil {
		return err
	}
	return emitRows(rows)
}

// runDiff prints the per-round mutation rollup from v_round_diff. With --round it
// scopes to a single round; without, it returns every round, newest first.
func runDiff(args []string) error {
	flagArgs, _ := splitArgs(args)
	fs := flag.NewFlagSet("diff", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	round := fs.Int("round", -1, "scope to a single round_id (optional)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if *dbPath == "" {
		return errors.New("diff: --db is required")
	}

	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()

	var rows []map[string]any
	if *round >= 0 {
		rows, err = db.Fetch(context.Background(),
			"SELECT * FROM v_round_diff WHERE round_id = ? ORDER BY table_name, op", *round)
	} else {
		rows, err = db.Fetch(context.Background(),
			"SELECT * FROM v_round_diff ORDER BY round_id DESC, table_name, op")
	}
	if err != nil {
		return err
	}
	return emitRows(rows)
}

// runLog prints raw mutation_log rows, newest first, optionally filtered to one
// table. --limit caps the output (default 50) so an interactive call stays bounded.
func runLog(args []string) error {
	flagArgs, _ := splitArgs(args)
	fs := flag.NewFlagSet("log", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	table := fs.String("table", "", "filter to one table_name (optional)")
	limit := fs.Int("limit", 50, "max rows to return")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if *dbPath == "" {
		return errors.New("log: --db is required")
	}

	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()

	var rows []map[string]any
	if *table != "" {
		rows, err = db.Fetch(context.Background(),
			"SELECT * FROM mutation_log WHERE table_name = ? ORDER BY mutated_at DESC LIMIT ?",
			*table, *limit)
	} else {
		rows, err = db.Fetch(context.Background(),
			"SELECT * FROM mutation_log ORDER BY mutated_at DESC LIMIT ?", *limit)
	}
	if err != nil {
		return err
	}
	return emitRows(rows)
}

// runSelftest (alias `doctor`) asserts the harness's write contract against the
// embedded schema and exits non-zero on any FAIL. It checks:
//  (a) every allowlist table exists in the schema;
//  (b) every fkRefs target (table, col) exists as a real column;
//  (c) every write-target's NOT NULL id/PK is covered by the id auto-assign
//      (i.e. the table actually HAS an `id` column, so COALESCE(MAX(id),0)+1 applies);
//  (d) the put summary round-trips: a fresh insert reports inserted=1, and an
//      immediate re-insert of the same row reports skipped=1.
// It runs against a throwaway temp DB so it never touches a real audit file.
func runSelftest(args []string) error {
	flagArgs, _ := splitArgs(args)
	fs := flag.NewFlagSet("selftest", flag.ContinueOnError)
	livePath := fs.String("db", "", "optional: a live audit DB to run the data-quality asserts (T3-10) against")
	skillVersion := fs.String("skill-version", "", "optional: the loaded SKILL.md version (vendored-≥ preflight)")
	minSkillVersion := fs.String("min-skill-version", "", "optional: the minimum SKILL.md version required")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}

	tmp, err := os.MkdirTemp("", "vrdb-selftest-")
	if err != nil {
		return fmt.Errorf("selftest: temp dir: %w", err)
	}
	defer os.RemoveAll(tmp)

	db, err := vrdb.Open(filepath.Join(tmp, "selftest.duckdb"))
	if err != nil {
		return fmt.Errorf("selftest: open: %w", err)
	}
	defer db.Close()
	ctx := context.Background()

	// Snapshot column metadata once: table -> col -> isNullable.
	type colMeta struct{ nullable bool }
	cols := map[string]map[string]colMeta{}
	metaRows, err := db.Fetch(ctx,
		"SELECT table_name, column_name, is_nullable FROM information_schema.columns")
	if err != nil {
		return fmt.Errorf("selftest: read information_schema: %w", err)
	}
	for _, r := range metaRows {
		tn, _ := r["table_name"].(string)
		cn, _ := r["column_name"].(string)
		nullable := true
		switch v := r["is_nullable"].(type) {
		case string:
			nullable = v != "NO"
		case bool:
			nullable = v
		}
		if cols[tn] == nil {
			cols[tn] = map[string]colMeta{}
		}
		cols[tn][cn] = colMeta{nullable: nullable}
	}

	var fails []string
	pass := func(msg string) { fmt.Printf("PASS  %s\n", msg) }
	fail := func(msg string) { fmt.Printf("FAIL  %s\n", msg); fails = append(fails, msg) }

	// (a) every allowlist table exists in the schema.
	for _, t := range vrdb.AllowedTables() {
		if _, ok := cols[t]; ok {
			pass("(a) allowlist table exists: " + t)
		} else {
			fail("(a) allowlist table MISSING from schema: " + t)
		}
	}

	// (b) every fkRefs target (parentTable, parentCol) exists.
	for _, t := range vrdb.AllowedTables() {
		for _, fk := range vrdb.FKRefsFor(t) {
			if pc, ok := cols[fk.ParentTable]; ok {
				if _, ok := pc[fk.ParentCol]; ok {
					pass(fmt.Sprintf("(b) fkRef target exists: %s.%s -> %s.%s", t, fk.Col, fk.ParentTable, fk.ParentCol))
					continue
				}
			}
			fail(fmt.Sprintf("(b) fkRef target MISSING: %s.%s -> %s.%s", t, fk.Col, fk.ParentTable, fk.ParentCol))
		}
	}

	// (c) every write-target's NOT NULL id is covered by id auto-assign. The
	// auto-assign only fires for an `id` column; a NOT NULL id with no auto-assign
	// would fail at insert, and a write-target table with NO `id` column should
	// never have been allowlisted (text-PK config tables are deliberately excluded).
	for _, t := range vrdb.AllowedTables() {
		tc := cols[t]
		if _, ok := tc["id"]; !ok {
			fail("(c) allowlist table has NO `id` column (auto-assign cannot cover it): " + t)
			continue
		}
		pass("(c) id auto-assign covers NOT NULL id: " + t)
	}

	// (d) put summary round-trips: insert -> inserted=1, re-insert -> skipped=1.
	tgt := map[string]any{
		"repo_url":   "selftest://roundtrip",
		"commit_sha": "0000000000000000000000000000000000000000",
		"language":   "go",
		"scanned_at": "2026-01-01 00:00:00",
	}
	first, err := db.PutCounts(ctx, "targets", []map[string]any{cloneRow(tgt)})
	if err != nil {
		fail("(d) round-trip insert errored: " + err.Error())
	} else if first.Inserted == 1 && first.Skipped == 0 {
		pass("(d) fresh insert -> inserted=1")
	} else {
		fail(fmt.Sprintf("(d) fresh insert expected inserted=1 skipped=0, got inserted=%d skipped=%d", first.Inserted, first.Skipped))
	}
	second, err := db.PutCounts(ctx, "targets", []map[string]any{cloneRow(tgt)})
	if err != nil {
		fail("(d) round-trip re-insert errored: " + err.Error())
	} else if second.Skipped == 1 && second.Inserted == 0 {
		pass("(d) duplicate re-insert -> skipped=1")
	} else {
		fail(fmt.Sprintf("(d) re-insert expected skipped=1 inserted=0, got inserted=%d skipped=%d", second.Inserted, second.Skipped))
	}

	// (e) DATA-QUALITY asserts (T3-10) against a LIVE audit DB, when --db is supplied:
	// no born-confirmed-without-provenance, no orphan SP, no hash-collision; plus the
	// vendored-≥ SKILL.md version preflight (warn-only). The schema-contract checks above
	// always run against the throwaway DB; these run against the real campaign DB.
	if *livePath != "" || *skillVersion != "" || *minSkillVersion != "" {
		target := db
		if *livePath != "" {
			live, err := vrdb.Open(*livePath)
			if err != nil {
				fail("(e) open live --db: " + err.Error())
			} else {
				defer live.Close()
				target = live
			}
		}
		if target != nil {
			dq, err := target.Selftest(ctx, *skillVersion, *minSkillVersion)
			if err != nil {
				fail("(e) data-quality selftest errored: " + err.Error())
			} else {
				for _, f := range dq.Fails {
					fail("(e) data-quality: " + f)
				}
				for _, w := range dq.Warns {
					fmt.Printf("WARN  (e) %s\n", w)
				}
				if len(dq.Fails) == 0 {
					pass("(e) data-quality asserts (no born-confirmed-without-provenance/orphan-SP/hash-collision)")
				}
			}
		}
	}

	if len(fails) > 0 {
		return fmt.Errorf("selftest: %d check(s) FAILED", len(fails))
	}
	fmt.Println("selftest: all checks PASS")
	return nil
}

// cloneRow copies a row map so the caller's template isn't mutated by Put's
// in-place `id` auto-assign (which would make the second insert non-idempotent).
func cloneRow(r map[string]any) map[string]any {
	c := make(map[string]any, len(r))
	for k, v := range r {
		c[k] = v
	}
	return c
}

// runPut decodes JSONL rows from stdin and batches them into a single Put call.
// One transaction per invocation keeps the single-writer invariant explicit at the CLI boundary.
func runPut(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("put", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) != 1 {
		return errors.New("put: expected exactly one TABLE argument")
	}
	if *dbPath == "" {
		return errors.New("put: --db is required")
	}
	table := positional[0]

	rows, err := decodeJSONL(os.Stdin)
	if err != nil {
		return fmt.Errorf("put: decode stdin: %w", err)
	}
	if len(rows) == 0 {
		return nil
	}

	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()

	// OUTPUT CONTRACT: on success, emit exactly ONE machine-readable JSON summary
	// line to stdout:  {"table":"<t>","inserted":N,"skipped":M,"errors":K}
	//   - inserted = rows newly written
	//   - skipped  = ON CONFLICT DO NOTHING no-ops (already present) — a SUCCESS
	//   - errors   = always 0 on success; inserted+skipped == len(input rows)
	// On ANY row error the whole batch is rolled back (PutCounts returns an error),
	// the process exits non-zero, the error goes to stderr, and NO summary line is
	// printed. This kills the old false "inserted 0/N" success reporting.
	counts, err := db.PutCounts(context.Background(), table, rows)
	if err != nil {
		return err
	}

	summary := struct {
		Table    string `json:"table"`
		Inserted int64  `json:"inserted"`
		Skipped  int64  `json:"skipped"`
		Errors   int64  `json:"errors"`
	}{table, counts.Inserted, counts.Skipped, counts.Errors}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	return json.NewEncoder(out).Encode(summary)
}

// runExec runs a DML/DDL statement and prints {"rows_affected":N} to stdout.
// Mirrors runFetch's positional-arg + --db flag parsing; use for UPDATE/DELETE/INSERT
// statements where the caller needs to know how many rows were touched.
func runExec(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("exec", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) != 1 {
		return errors.New("exec: expected exactly one SQL argument")
	}
	if *dbPath == "" {
		return errors.New("exec: --db is required")
	}
	query := positional[0]

	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()

	n, err := db.Exec(context.Background(), query)
	if err != nil {
		return err
	}

	result := struct {
		RowsAffected int64 `json:"rows_affected"`
	}{RowsAffected: n}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	enc := json.NewEncoder(out)
	return enc.Encode(result)
}

// runFetch executes the SQL given as a positional arg and emits each result row as a JSONL line.
// Output is line-buffered so callers (jq, the orchestrator) can stream incrementally.
func runFetch(args []string) error {
	flagArgs, positional := splitArgs(args)
	fs := flag.NewFlagSet("fetch", flag.ContinueOnError)
	dbPath := fs.String("db", "", "path to the DuckDB file (required)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if len(positional) != 1 {
		return errors.New("fetch: expected exactly one SQL argument")
	}
	if *dbPath == "" {
		return errors.New("fetch: --db is required")
	}
	query := positional[0]

	db, err := vrdb.Open(*dbPath)
	if err != nil {
		return err
	}
	defer db.Close()

	rows, err := db.Fetch(context.Background(), query)
	if err != nil {
		return err
	}

	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	enc := json.NewEncoder(out)
	for _, r := range rows {
		if err := enc.Encode(r); err != nil {
			return fmt.Errorf("fetch: encode row: %w", err)
		}
	}
	return nil
}

// splitArgs separates flag tokens (anything starting with `-`, plus the value after a non-`=` flag)
// from positional tokens. Lets callers write `vrdb put targets --db PATH` interchangeably with the
// stdlib `vrdb put --db PATH targets` form — Go's flag package alone only accepts the latter.
func splitArgs(args []string) (flagArgs, positional []string) {
	for i := 0; i < len(args); i++ {
		a := args[i]
		if len(a) > 0 && a[0] == '-' {
			flagArgs = append(flagArgs, a)
			// non-bool flags use a separate value token unless they used `--flag=value`.
			if i+1 < len(args) && !contains(a, '=') {
				flagArgs = append(flagArgs, args[i+1])
				i++
			}
			continue
		}
		positional = append(positional, a)
	}
	return flagArgs, positional
}

func contains(s string, c byte) bool {
	for i := 0; i < len(s); i++ {
		if s[i] == c {
			return true
		}
	}
	return false
}

// decodeJSONL reads one JSON object per line from r. Blank lines are skipped so callers
// can pretty-format their inputs without breaking the parser.
func decodeJSONL(r io.Reader) ([]map[string]any, error) {
	out := make([]map[string]any, 0, 16)
	dec := json.NewDecoder(r)
	for {
		var row map[string]any
		if err := dec.Decode(&row); err != nil {
			if errors.Is(err, io.EOF) {
				return out, nil
			}
			return nil, err
		}
		if len(row) == 0 {
			continue
		}
		out = append(out, row)
	}
}
