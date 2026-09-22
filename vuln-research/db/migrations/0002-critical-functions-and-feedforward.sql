-- vuln-research migration 0002 — critical functions, forward data-flow, rich logging, bypass feed-forward
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE / LIMITATION (read before applying to a pre-existing v1 DB):
--   This migration adds new tables and additive columns only. It deliberately
--   does NOT widen the three CHECK-enum columns:
--     - input_slices.slice_kind        (schema v2 adds 'critical_fn_forward')
--     - strategies.name                (schema v2 adds 'critical_function_dataflow_lane', seed id 9)
--     - phase0_priorities.artifact_kind (schema v2 adds 'critical_function')
--   DuckDB cannot ALTER a CHECK constraint in place, and the affected parent
--   tables are FK-referenced (agent_steps -> strategies / input_slices), so an
--   in-place rebuild is not safe. Fresh DBs created by the v2 harness get the
--   widened enums + the new strategy seed directly from db/schema.sql.
--   Schema v2 also relaxes input_slices.source_id from NOT NULL to nullable and
--   adds a slice_anchor CHECK (exactly one of source_id / critical_fn_id, keyed
--   by slice_kind) so a pure 'critical_fn_forward' slice can be CF-anchored with
--   source_id NULL. DuckDB can ALTER neither NOT NULL nor a CHECK in place, so
--   this too lives only in db/schema.sql for fresh DBs — and it is moot on a
--   migrated v1 file anyway, since 'critical_fn_forward' is itself a new
--   slice_kind enum value that such a DB cannot store.
--   vuln-research audit DBs are ephemeral (one per target/commit), so the
--   supported upgrade path for a pre-existing v1 file is: delete it and re-scan.
--   Until then every additive table/column below is available, but rows using
--   the three new enum values can only be written to a fresh v2 DB.
--
-- Added columns are declared WITHOUT their FK/CHECK constraints (DuckDB
-- ALTER TABLE ADD COLUMN supports neither); db/schema.sql carries the enforced
-- constraints for fresh DBs. The orchestrator is the single writer and
-- validates these soft references at flush time.

------------------------------------------------------------
-- New tables. Every FK below points to a table that exists in v1 or is created
-- earlier in this migration, so creation order is FK-safe.
------------------------------------------------------------

-- round_ledger first: agent_steps.round_id and defense_bypasses.round_id
-- soft-reference it, and critical_fn_reach / agent_observations are unaffected.
CREATE TABLE IF NOT EXISTS round_ledger (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_no INTEGER NOT NULL,
  audit_run_id TEXT NOT NULL,
  effort_tier TEXT
    CHECK (effort_tier IS NULL OR effort_tier IN ('low', 'medium', 'deep')),
  parent_round_id INTEGER REFERENCES round_ledger(id),
  started_at TIMESTAMP NOT NULL,
  ended_at TIMESTAMP,
  priors_fetched_json TEXT,
  seed_summary_json TEXT,
  coverage_carry_json TEXT,
  UNIQUE (target_id, round_no, audit_run_id)
);

CREATE TABLE IF NOT EXISTS critical_functions (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  symbol_path TEXT NOT NULL,
  cf_category TEXT NOT NULL
    CHECK (cf_category IN (
      'auth_check',
      'access_control',
      'crypto_op',
      'deserializer',
      'validator_sanitizer',
      'parser_decoder',
      'privileged_op',
      'state_transition',
      'dangerous_sink',
      'trust_boundary_transfer'
    )),
  evidence_path TEXT,
  evidence_line INTEGER,
  sink_id INTEGER REFERENCES sinks(id),
  defense_id INTEGER REFERENCES defenses(id),
  source_reachable BOOLEAN,
  factor_reachability REAL,
  factor_blast_radius REAL,
  factor_attention_deficit REAL,
  factor_privilege_delta REAL,
  factor_bypass_prior REAL,
  rank_score REAL,
  rank_tier TEXT
    CHECK (rank_tier IS NULL OR rank_tier IN ('tier1', 'tier2', 'tier3')),
  classification_evidence_json TEXT,
  cf_hash TEXT NOT NULL,
  UNIQUE (cf_hash)
);

CREATE TABLE IF NOT EXISTS critical_fn_reach (
  id INTEGER PRIMARY KEY,
  critical_fn_id INTEGER NOT NULL REFERENCES critical_functions(id),
  source_id INTEGER NOT NULL REFERENCES sources(id),
  slice_id INTEGER REFERENCES input_slices(id),
  reach_status TEXT NOT NULL
    CHECK (reach_status IN ('reaches', 'blocked', 'unproven')),
  hop_count INTEGER,
  guard_path_json TEXT,
  reach_hash TEXT NOT NULL,
  UNIQUE (reach_hash)
);

CREATE TABLE IF NOT EXISTS agent_observations (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  obs_kind TEXT NOT NULL
    CHECK (obs_kind IN (
      'hypothesis',
      'dead_end',
      'assumption',
      'invariant',
      'partial_trace',
      'guard_observed',
      'tool_output',
      'note',
      'blind_spot'
    )),
  symbol_path TEXT,
  evidence_path TEXT,
  evidence_line INTEGER,
  body TEXT NOT NULL,
  body_sidecar_path TEXT,
  confidence REAL,
  reusable BOOLEAN NOT NULL DEFAULT TRUE,
  obs_hash TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  UNIQUE (obs_hash)
);

------------------------------------------------------------
-- Additive columns on existing tables (no FK/CHECK — see header). Idempotent
-- via ADD COLUMN IF NOT EXISTS.
------------------------------------------------------------
ALTER TABLE input_slices     ADD COLUMN IF NOT EXISTS critical_fn_id INTEGER;
ALTER TABLE agent_steps      ADD COLUMN IF NOT EXISTS round_id INTEGER;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS bypass_family TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS parsed_logic_json TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS exhaustion_log TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS stage_reached TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS cascade_emitted_finding_ids TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS cascade_emitted_source_ids TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS carried_from_bypass_id INTEGER;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS round_id INTEGER;

INSERT INTO schema_version (version, description)
VALUES (2, 'critical-function registry, forward data-flow, rich logging, bypass feed-forward')
ON CONFLICT DO NOTHING;
