-- vuln-research global catalogue — bypasses table
-- Separate DuckDB instance from per-target audit DBs.
-- Canonical runtime path: ${XDG_DATA_HOME:-~/.local/share}/vuln-research/catalogue.duckdb
-- Source of truth for data: vuln-research/db/catalogue/bypasses.json
-- Forward-only, idempotent. Safe to re-apply.

CREATE TABLE IF NOT EXISTS catalogue_version (
  version INTEGER PRIMARY KEY,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  description TEXT
);

INSERT INTO catalogue_version (version, description)
VALUES (1, 'initial bypasses catalogue'),
       (2, 'add logic_guard defense_type (complex-logic / authorization-escalation families)')
ON CONFLICT DO NOTHING;

-- `bypasses` is DROP+CREATE (not CREATE IF NOT EXISTS) because the v2 change widens
-- the defense_type CHECK to admit 'logic_guard', and DuckDB cannot alter a CHECK in
-- place. The table is fully derived from bypasses.json — load.sql repopulates it on
-- every build — so dropping is non-destructive (no precious rows, no FK dependents in
-- this standalone catalogue DB). The documented build is always schema.sql then
-- load.sql (references/v2/bypass-catalogue.md §4), so the rebuild is safe and idempotent.
DROP TABLE IF EXISTS bypasses;
CREATE TABLE bypasses (
  id TEXT PRIMARY KEY,
  defense_type TEXT NOT NULL
    CHECK (defense_type IN ('sanitizer_function', 'blacklist', 'allowlist', 'generic', 'logic_guard')),
  family TEXT NOT NULL,
  description TEXT NOT NULL,
  applies_when TEXT NOT NULL,
  applies_when_tags TEXT[] NOT NULL,
  examples TEXT[] NOT NULL,
  UNIQUE (defense_type, family)
);

CREATE INDEX IF NOT EXISTS idx_bypasses_defense_type ON bypasses(defense_type);
