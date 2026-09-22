-- vuln-research migration 0008 — fuzz artifacts + boundary_fuzz_lane v2 seed
--
-- Forward-only, idempotent. Safe to re-apply on current schemas where
-- strategies.name is free TEXT. Obsolete pre-v0.14 audit DBs with a
-- strategies.name CHECK cannot be widened in place by DuckDB; recreate them.
--
-- SCOPE:
--   1. Adds fuzz_artifacts, a content-addressed persistence table for resumable
--      fuzzing corpora/checkpoints/frontiers. It stores retained/resumable
--      artifacts, not every attempted mutation by default.
--   2. Inserts/updates boundary_fuzz_lane to version 2 so existing DBs do not
--      silently keep the v1 strategy description under ON CONFLICT DO NOTHING.

------------------------------------------------------------
-- Resumable fuzz artifacts
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fuzz_artifacts (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  fuzz_run_id INTEGER REFERENCES fuzz_runs(id),
  agent_step_id INTEGER REFERENCES agent_steps(id),
  round_id INTEGER REFERENCES round_ledger(id),
  artifact_kind TEXT NOT NULL,
  label TEXT,
  content_hash TEXT NOT NULL,
  payload TEXT,
  payload_sidecar_path TEXT,
  metadata_json TEXT,
  parent_content_hash TEXT,
  created_at TIMESTAMP,
  UNIQUE (target_id, artifact_kind, content_hash)
);

------------------------------------------------------------
-- Strategy seed/upsert. INSERT handles DBs missing the row; UPDATE handles DBs
-- that already have the old version because earlier seeds used DO NOTHING.
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (9, 'critical_function_dataflow_lane',   'Forward data-flow from ranked critical functions AND from attacker-controllable sources toward them; records critical_fn_reach + critical_fn_forward slices.', 1),
  (10, 'boundary_fuzz_lane',               'Phase 1.5 (DEEP) mandatory boundary fuzzing: harness selected parser/FFI/decoder/protocol boundaries for crashes or divergences; records fuzz_runs + emits fuzz_crash/fuzz_divergence findings.', 2)
ON CONFLICT (name) DO NOTHING;

UPDATE strategies
SET description = 'Phase 1.5 (DEEP) mandatory boundary fuzzing: harness selected parser/FFI/decoder/protocol boundaries for crashes or divergences; records fuzz_runs + emits fuzz_crash/fuzz_divergence findings.',
    version = 2
WHERE name = 'boundary_fuzz_lane'
  AND version < 2;

INSERT INTO schema_version (version, description)
VALUES (8, 'fuzz artifacts: resumable seed/corpus/checkpoint storage + boundary_fuzz_lane v2 strategy seed')
ON CONFLICT DO NOTHING;
