// migrations_test.go — applies db/migrations/*.sql in order to a fresh DuckDB and
// asserts the chain is FK-safe, syntactically valid, and records every version.
// Guards against the drift class we already hit once (a migration that adds a
// table to the canonical schema but never lands in the ordered migration set, or
// forgets its schema_version row). This walks the REAL migration files, not the
// embedded schema, so it tests the upgrade path an ephemeral audit DB would take.

package vrdb_test

import (
	"context"
	"database/sql"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	"vrdb"

	_ "github.com/marcboeker/go-duckdb"
)

func TestMigrations_ApplyInOrderFromEmpty(t *testing.T) {
	ctx := context.Background()

	files, err := filepath.Glob(filepath.Join("..", "migrations", "*.sql"))
	if err != nil {
		t.Fatalf("glob migrations: %v", err)
	}
	if len(files) < 5 {
		t.Fatalf("expected at least 5 migration files (0001..0005), got %d: %v", len(files), files)
	}
	sort.Strings(files) // 0001 < 0002 < 0003 < 0004 < 0005 lexically

	dbPath := filepath.Join(t.TempDir(), "migrated.duckdb")
	db, err := sql.Open("duckdb", dbPath)
	if err != nil {
		t.Fatalf("sql.Open: %v", err)
	}
	defer func() { _ = db.Close() }()

	for _, f := range files {
		body, err := os.ReadFile(f)
		if err != nil {
			t.Fatalf("read %s: %v", f, err)
		}
		// Apply statement-by-statement via the harness helper so the migration chain
		// tolerates the SAME benign DuckDB-v1.1.3 dependency error the embedded-schema path
		// does: migration 0029's `ALTER … SET DEFAULT nextval(…)` (T2-10/T3-08) is refused on
		// FK-referenced tables, and a raw whole-file Exec would abort the file at the first
		// such ALTER, leaving the v0.40 justification objects uncreated.
		if err := vrdb.ApplyScript(ctx, db, string(body)); err != nil {
			t.Fatalf("apply %s: %v", filepath.Base(f), err)
		}
		// Re-apply once: forward-only migrations must be idempotent.
		if err := vrdb.ApplyScript(ctx, db, string(body)); err != nil {
			t.Fatalf("re-apply %s (not idempotent): %v", filepath.Base(f), err)
		}
	}

	var maxVersion int
	if err := db.QueryRowContext(ctx, "SELECT COALESCE(MAX(version), 0) FROM schema_version").Scan(&maxVersion); err != nil {
		t.Fatalf("read schema_version: %v", err)
	}
	if maxVersion != len(files) {
		t.Fatalf("schema_version max = %d, want %d (one row per migration file)", maxVersion, len(files))
	}

	// Every table introduced by 0003/0004/0005 must be queryable after the chain.
	for _, tbl := range []string{
		"fuzz_runs", "eval_corpus", "eval_run", "eval_result",
		"scoring_config", "finding_sightings", "call_edges",
		"weakness_classes", "recurrence_counter", "mutation_log",
		"sanitizer_bypass_runs",
		// Suspicious Point screening tier (migration 0010).
		"suspicious_points", "suspicious_point_factor", "sp_factor_config",
	} {
		if _, err := db.ExecContext(ctx, "SELECT * FROM "+tbl+" LIMIT 0"); err != nil {
			t.Fatalf("table %q missing after migration chain: %v", tbl, err)
		}
	}

	// Migration 0010 read-time views must exist and the percentile-rank score view
	// must PARSE + execute on DuckDB 1.1.3 (the scalar MACRO + PERCENT_RANK + BOOL_AND
	// + degenerate-population guard all resolve at query time).
	for _, vw := range []string{"v_suspicious_points_ranked", "v_sp_factor_coverage"} {
		if _, err := db.ExecContext(ctx, "SELECT * FROM "+vw+" LIMIT 0"); err != nil {
			t.Fatalf("view %q missing/unparseable after migration chain: %v", vw, err)
		}
	}

	// sp_factor_config must be seeded with the full §5 catalog (26 factors); the three
	// gate factors and two penalty factors must carry the spec's flags.
	var factorCount, gateCount, penaltyCount int
	if err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM sp_factor_config").Scan(&factorCount); err != nil {
		t.Fatalf("count sp_factor_config: %v", err)
	}
	if factorCount != 26 {
		t.Fatalf("sp_factor_config seeded %d factors, want 26 (full §5 catalog)", factorCount)
	}
	if err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM sp_factor_config WHERE is_gate").Scan(&gateCount); err != nil {
		t.Fatalf("count gates: %v", err)
	}
	if gateCount != 3 {
		t.Fatalf("sp_factor_config has %d gates, want 3 (oracle_applicable/reachable_from_entry/taint_reach_G1)", gateCount)
	}
	if err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM sp_factor_config WHERE direction = -1").Scan(&penaltyCount); err != nil {
		t.Fatalf("count penalties: %v", err)
	}
	if penaltyCount != 2 {
		t.Fatalf("sp_factor_config has %d penalties, want 2 (intended_feature_G3/proven_invariant)", penaltyCount)
	}
}

// TestMigrations_MatchEmbeddedSchema is a coarse drift guard: every table the
// embedded schema (fresh-DB path) creates must also exist after the migration
// chain (upgrade path), so the two never silently diverge again.
func TestMigrations_MatchEmbeddedSchema(t *testing.T) {
	ctx := context.Background()

	// Fresh-DB path via the harness (applies embedded schema.sql).
	fresh, _ := openTestDB(t)
	freshTables := tableSet(t, ctx, fresh.SQL())

	// Upgrade path: apply the migration files to a separate empty DB.
	files, err := filepath.Glob(filepath.Join("..", "migrations", "*.sql"))
	if err != nil {
		t.Fatalf("glob migrations: %v", err)
	}
	sort.Strings(files)
	dbPath := filepath.Join(t.TempDir(), "upgraded.duckdb")
	mig, err := sql.Open("duckdb", dbPath)
	if err != nil {
		t.Fatalf("sql.Open: %v", err)
	}
	defer func() { _ = mig.Close() }()
	for _, f := range files {
		body, err := os.ReadFile(f)
		if err != nil {
			t.Fatalf("read %s: %v", f, err)
		}
		// Statement-aware apply (see TestMigrations_ApplyInOrderFromEmpty): tolerate the
		// benign `SET DEFAULT nextval` dependency error from migration 0029 so the chain
		// reconstructs the same table set the embedded schema declares.
		if err := vrdb.ApplyScript(ctx, mig, string(body)); err != nil {
			t.Fatalf("apply %s: %v", filepath.Base(f), err)
		}
	}
	migTables := tableSet(t, ctx, mig)

	for tbl := range freshTables {
		if _, ok := migTables[tbl]; !ok {
			t.Errorf("table %q exists in embedded schema but is never created by a migration", tbl)
		}
	}
}

func tableSet(t *testing.T, ctx context.Context, db *sql.DB) map[string]struct{} {
	t.Helper()
	rows, err := db.QueryContext(ctx, "SELECT table_name FROM information_schema.tables WHERE table_schema = 'main' AND table_type = 'BASE TABLE'")
	if err != nil {
		t.Fatalf("list tables: %v", err)
	}
	defer rows.Close()
	out := make(map[string]struct{})
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			t.Fatalf("scan table name: %v", err)
		}
		out[strings.ToLower(name)] = struct{}{}
	}
	return out
}
