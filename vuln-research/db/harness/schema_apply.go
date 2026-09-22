// schema_apply.go — statement-by-statement schema application that tolerates the
// benign DuckDB-v1.1.3 limitation around `ALTER TABLE … ALTER COLUMN id SET DEFAULT
// nextval(…)` on FK-referenced parent tables.
//
// Why this exists: the Tier-2 schema (migration 0029) adds a per-table sequence and an
// `ALTER … SET DEFAULT nextval('seq_<table>')` for every id PK so the harness can drop the
// old `COALESCE(MAX(id),0)+1` id read (T3-08 / S-D04). DuckDB v1.1.3 refuses to ALTER a
// table that other tables reference with a foreign key:
//
//	Dependency Error: Cannot alter entry "targets" because there are entries that depend on it.
//
// A single `Exec(wholeSchema)` therefore aborts at the FIRST such ALTER, leaving every object
// declared AFTER it (the v0.40 justification views v_promotion_coverage, v_sp_oracle_coverage,
// …) uncreated — Open() would silently apply only the first ~⅔ of the schema. The sequences
// themselves are created successfully (CREATE SEQUENCE has no dependency edge), so the harness
// can still assign ids via an explicit `nextval('seq_<table>')` (see put.go); only the column
// DEFAULT fails to wire for FK-referenced tables, which the harness does not rely on.
//
// applySchema() splits the schema into statements (respecting single-quoted string literals
// with `''` escaping and `--` line comments) and execs each one, swallowing ONLY the specific
// "because there are entries that depend on it" dependency error on a `SET DEFAULT nextval`
// statement. Any other error aborts Open() loudly, exactly as a whole-Exec would.

package vrdb

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
)

// splitSQLStatements splits a SQL script into individual statements on top-level `;`.
// It is deliberately small but correct for this schema's surface:
//   - single-quoted string literals are tracked; a `;` inside a string is NOT a separator,
//     and a doubled `''` inside a string is an escaped quote (not a string terminator);
//   - `-- …` line comments are stripped (a `;` inside a comment is not a separator);
//   - `$$`-style dollar quoting is not used by the schema and is intentionally unsupported.
//
// Trailing-whitespace-only fragments are dropped. The returned statements have no trailing `;`.
func splitSQLStatements(script string) []string {
	var stmts []string
	var b strings.Builder
	inString := false

	for i := 0; i < len(script); i++ {
		c := script[i]

		// `--` line comment (only outside a string).
		if !inString && c == '-' && i+1 < len(script) && script[i+1] == '-' {
			for i < len(script) && script[i] != '\n' {
				i++
			}
			b.WriteByte('\n') // preserve token separation across the elided comment
			continue
		}

		if c == '\'' {
			if inString && i+1 < len(script) && script[i+1] == '\'' {
				// escaped quote inside a string literal — emit both, stay in-string.
				b.WriteByte(c)
				b.WriteByte(script[i+1])
				i++
				continue
			}
			inString = !inString
			b.WriteByte(c)
			continue
		}

		if c == ';' && !inString {
			if stmt := strings.TrimSpace(b.String()); stmt != "" {
				stmts = append(stmts, stmt)
			}
			b.Reset()
			continue
		}

		b.WriteByte(c)
	}
	if last := strings.TrimSpace(b.String()); last != "" {
		stmts = append(stmts, last)
	}
	return stmts
}

// isBenignSetDefaultDepError reports whether err is the tolerable DuckDB dependency error
// raised by `ALTER … SET DEFAULT nextval(…)` on a FK-referenced table. It is benign because
// the sequence still exists and the harness assigns ids explicitly via nextval().
func isBenignSetDefaultDepError(stmt string, err error) bool {
	if err == nil {
		return false
	}
	up := strings.ToUpper(stmt)
	if !strings.Contains(up, "SET DEFAULT NEXTVAL") {
		return false
	}
	return strings.Contains(err.Error(), "because there are entries that depend on it")
}

// applySchema applies the embedded schema one statement at a time, tolerating only the
// benign SET-DEFAULT dependency error. Any other statement error aborts and is returned with
// the offending statement's prefix for diagnosis.
func applySchema(ctx context.Context, db *sql.DB, script string) error {
	for _, stmt := range splitSQLStatements(script) {
		if _, err := db.ExecContext(ctx, stmt); err != nil {
			if isBenignSetDefaultDepError(stmt, err) {
				continue
			}
			prefix := stmt
			if len(prefix) > 120 {
				prefix = prefix[:120]
			}
			prefix = strings.ReplaceAll(prefix, "\n", " ")
			return fmt.Errorf("apply schema statement %q…: %w", prefix, err)
		}
	}
	return nil
}

// ApplyScript is the exported entry point for applying an arbitrary SQL script (the embedded
// schema OR an on-disk migration file) statement-by-statement with the SAME benign-error
// tolerance Open() uses. The migration chain (migrations_test.go) MUST go through this rather
// than a raw whole-file Exec: migration 0029 carries the `ALTER … SET DEFAULT nextval(…)` DDL
// (T2-10 / T3-08), which DuckDB v1.1.3 refuses on FK-referenced tables ("Cannot alter entry …
// because there are entries that depend on it"). A whole-file Exec aborts at the first such
// ALTER, leaving every object declared after it uncreated; this helper swallows ONLY that
// specific benign error so the chain reaches the v0.40 justification objects, exactly as the
// applied schema.sql path does on a fresh Open().
func ApplyScript(ctx context.Context, db *sql.DB, script string) error {
	return applySchema(ctx, db, script)
}
