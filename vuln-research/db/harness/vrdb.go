// vrdb.go — DuckDB put/fetch harness: Open(path) applies the embedded schema; Fetch(ctx, sql, args…) returns rows as []map[string]any.
// Exists so the v2 orchestrator can read/write rows through a single tested entry point instead of re-implementing schema application + result marshalling per session.
// How: opens a `duckdb` driver connection, execs the embedded schema (idempotent — every CREATE uses IF NOT EXISTS), then exposes minimal Fetch; called by cmd/vrdb (CLI) and by tests; Put lives in put.go.

package vrdb

import (
	"context"
	"database/sql"
	_ "embed"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	_ "github.com/marcboeker/go-duckdb"
)

//go:generate sh -c "{ sed -n '1,4p' schema.sql; cat ../schema.sql; } > schema.sql.gen && mv schema.sql.gen schema.sql"
//go:embed schema.sql
var schemaSQL string

// DB is a thin wrapper around *sql.DB pinned to a DuckDB file with the v2 schema applied.
type DB struct {
	sql  *sql.DB
	path string
}

// Open opens (or creates) a DuckDB file at path and applies the embedded schema idempotently.
// The schema's `CREATE … IF NOT EXISTS` + `INSERT … ON CONFLICT DO NOTHING` make re-open safe.
//
// Open also (T3-06 / S-D10, C31):
//   - pins the pool to a single connection (SetMaxOpenConns(1)) so the single-writer
//     guarantee is a configured invariant, not a convention;
//   - applies the schema statement-by-statement (applySchema), tolerating only the benign
//     DuckDB-v1.1.3 `SET DEFAULT nextval` dependency error on FK-referenced tables;
//   - runs a cheap integrity probe on an EXISTING file and, on failure, auto-restores from the
//     newest snapshot under <db>.snapshots/ before surfacing a raw "metadata pointer" error.
func Open(path string) (*DB, error) {
	// Integrity probe + auto-restore must run BEFORE we open for schema application: a
	// corrupt file ("Failed to load metadata pointer") can fail at open or at first query.
	if fileExists(path) {
		if err := probeAndMaybeRestore(path); err != nil {
			return nil, err
		}
	}

	sqlDB, err := sql.Open("duckdb", path)
	if err != nil {
		return nil, fmt.Errorf("vrdb: sql.Open: %w", err)
	}
	// Single-writer invariant as configuration (S-D10 fix #4): one connection only.
	sqlDB.SetMaxOpenConns(1)

	if err := applySchema(context.Background(), sqlDB, schemaSQL); err != nil {
		_ = sqlDB.Close()
		return nil, fmt.Errorf("vrdb: apply schema: %w", err)
	}
	return &DB{sql: sqlDB, path: path}, nil
}

// fileExists reports whether path names an existing regular file (not a directory).
func fileExists(path string) bool {
	fi, err := os.Stat(path)
	return err == nil && !fi.IsDir()
}

// probeAndMaybeRestore opens path read-only-ish, runs a cheap SELECT against a schema table,
// and — on failure — copies the newest snapshot over the corrupt file before returning. If no
// snapshot exists, the original open error is surfaced so the caller learns the file is dead.
func probeAndMaybeRestore(path string) error {
	if probeReadable(path) == nil {
		return nil // healthy
	}
	// Corrupt (or unreadable). Try the newest snapshot.
	snap, err := newestSnapshot(path)
	if err != nil || snap == "" {
		return fmt.Errorf("vrdb: integrity probe failed for %q and no snapshot to restore from "+
			"(run `vrdb snapshot` before HEAVY lanes to enable auto-restore)", path)
	}
	if err := copyFile(snap, path); err != nil {
		return fmt.Errorf("vrdb: integrity probe failed; restore from snapshot %q failed: %w", snap, err)
	}
	if perr := probeReadable(path); perr != nil {
		return fmt.Errorf("vrdb: integrity probe failed; restored snapshot %q is also unreadable: %w", snap, perr)
	}
	return nil
}

// probeReadable opens path and runs the cheap integrity SELECT; nil means the file is readable.
func probeReadable(path string) error {
	db, err := sql.Open("duckdb", path)
	if err != nil {
		return err
	}
	defer db.Close()
	db.SetMaxOpenConns(1)
	var n int
	if err := db.QueryRowContext(context.Background(), "SELECT count(*) FROM schema_version").Scan(&n); err != nil {
		return err
	}
	return nil
}

// snapshotDir returns the directory that holds point-in-time snapshots of path.
func snapshotDir(path string) string { return path + ".snapshots" }

// newestSnapshot returns the most recently modified snapshot file for path, or "" if none.
func newestSnapshot(path string) (string, error) {
	dir := snapshotDir(path)
	entries, err := os.ReadDir(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return "", nil
		}
		return "", err
	}
	type cand struct {
		name string
		mod  int64
	}
	var cands []cand
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		if !strings.HasSuffix(e.Name(), ".duckdb") {
			continue
		}
		info, err := e.Info()
		if err != nil {
			continue
		}
		cands = append(cands, cand{name: e.Name(), mod: info.ModTime().UnixNano()})
	}
	if len(cands) == 0 {
		return "", nil
	}
	sort.Slice(cands, func(i, j int) bool { return cands[i].mod > cands[j].mod })
	return filepath.Join(dir, cands[0].name), nil
}

// copyFile copies src to dst, creating parent dirs as needed.
func copyFile(src, dst string) error {
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		_ = out.Close()
		return err
	}
	return out.Close()
}

// Close releases the underlying connection pool.
func (d *DB) Close() error { return d.sql.Close() }

// Path returns the on-disk DuckDB file path. Used by Put to resolve the sidecar dir.
func (d *DB) Path() string { return d.path }

// SQL exposes the underlying *sql.DB for callers that need transactions or extension calls
// not covered by Put/Fetch. Most callers should not touch this.
func (d *DB) SQL() *sql.DB { return d.sql }

// Checkpoint forces a durable WAL flush (T3-06 / S-D10). The orchestrator calls this at every
// phase boundary and before any HEAVY lane, turning the unflushed-WAL corruption window from
// "the whole campaign" into "one phase". DuckDB's `FORCE CHECKPOINT` flushes the WAL into the
// main file and truncates it; on the rare driver/version that rejects FORCE we fall back to a
// plain `CHECKPOINT`.
func (d *DB) Checkpoint(ctx context.Context) error {
	if _, err := d.sql.ExecContext(ctx, "FORCE CHECKPOINT"); err != nil {
		if _, ferr := d.sql.ExecContext(ctx, "CHECKPOINT"); ferr != nil {
			return fmt.Errorf("vrdb: checkpoint: %w", err)
		}
	}
	return nil
}

// Snapshot copies the live DB file to <db>.snapshots/<label>.duckdb after a checkpoint, so a
// later corrupt main file rolls back to this point rather than to empty (T3-06 / S-D10). It
// checkpoints first so the snapshot is a durable, self-consistent file (the WAL is folded in).
// Returns the snapshot path written.
func (d *DB) Snapshot(ctx context.Context, label string) (string, error) {
	if label == "" {
		return "", fmt.Errorf("vrdb: snapshot: empty label")
	}
	// Sanitize the label into a safe filename fragment.
	safe := sanitizeLabel(label)
	if err := d.Checkpoint(ctx); err != nil {
		return "", err
	}
	dir := snapshotDir(d.path)
	dst := filepath.Join(dir, safe+".duckdb")
	if err := copyFile(d.path, dst); err != nil {
		return "", fmt.Errorf("vrdb: snapshot: copy: %w", err)
	}
	return dst, nil
}

// sanitizeLabel maps an arbitrary label to a filesystem-safe fragment ([A-Za-z0-9._-]).
func sanitizeLabel(s string) string {
	var b strings.Builder
	for _, r := range s {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '.', r == '_', r == '-':
			b.WriteRune(r)
		default:
			b.WriteByte('-')
		}
	}
	out := b.String()
	if out == "" {
		out = "snapshot"
	}
	return out
}

// Exec runs a DML/DDL statement (UPDATE/DELETE/INSERT/DDL) and returns rows
// affected. Use this for finding status transitions and payload-enrichment
// UPDATEs — Fetch is for SELECT. (Previously flush scripts abused Fetch to run
// UPDATEs; Exec is the correct verb.)
func (d *DB) Exec(ctx context.Context, query string, args ...any) (int64, error) {
	res, err := d.sql.ExecContext(ctx, query, args...)
	if err != nil {
		return 0, err
	}
	n, raErr := res.RowsAffected()
	if raErr != nil {
		return 0, nil // statement ran; driver just couldn't report the count
	}
	return n, nil
}

// Fetch runs an arbitrary query and returns the result as a slice of column-name → value maps.
// Designed for the orchestrator's reporting reads (e.g., `SELECT * FROM confirmed_vulns`) and for
// the CLI's JSONL stdout emission; not for hot paths inside the swarm.
func (d *DB) Fetch(ctx context.Context, query string, args ...any) ([]map[string]any, error) {
	rows, err := d.sql.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("vrdb: query: %w", err)
	}
	defer rows.Close()

	cols, err := rows.Columns()
	if err != nil {
		return nil, fmt.Errorf("vrdb: columns: %w", err)
	}

	out := make([]map[string]any, 0, 16)
	for rows.Next() {
		vals := make([]any, len(cols))
		ptrs := make([]any, len(cols))
		for i := range vals {
			ptrs[i] = &vals[i]
		}
		if err := rows.Scan(ptrs...); err != nil {
			return nil, fmt.Errorf("vrdb: scan: %w", err)
		}
		m := make(map[string]any, len(cols))
		for i, c := range cols {
			m[c] = vals[i]
		}
		out = append(out, m)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("vrdb: rows.Err: %w", err)
	}
	return out, nil
}
