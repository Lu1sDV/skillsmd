-- vuln-research migration 0015 — LLMxCPG execution-path slice_kind + query_attempts
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: lands the CODE-stream half of the LLMxCPG integration (arXiv:2507.16585):
--   (1) a new source-anchored slice_kind 'execution_path' — the execution-path-first
--       slice the LLMxCPG-Q query-generation loop isolates from attacker input to a
--       candidate sink; and
--   (2) a new query_attempts table — the bounded CPGQL query-generation feedback loop
--       (generate -> run -> feedback -> retry≤3 -> dead_end), one row per attempt.
--
-- CHECK-DIVERGENCE NOTE (mirrors the 0002 / 0009 / 0010 precedent): the
-- 'execution_path' value is added to the input_slices.slice_kind CHECK in
-- db/schema.sql (the fresh-DB path) ONLY. This migration deliberately does NOT
-- widen that CHECK: DuckDB cannot ALTER a CHECK constraint in place, and
-- input_slices is FK-referenced (agent_steps.slice_id, critical_fn_reach.slice_id,
-- and now query_attempts.slice_id), so an in-place rebuild is not safe. Fresh DBs
-- created by the harness get the widened enum directly from db/schema.sql.
-- 'execution_path' is source-anchored, so it rides the existing slice_anchor ELSE
-- branch (source_id NOT NULL, critical_fn_id NULL) — the slice_anchor CHECK is
-- unchanged on both paths. vuln-research audit DBs are ephemeral (one per
-- target/commit), so the supported upgrade path for a pre-existing file is: delete
-- it and re-scan; until then 'execution_path' slices can only be written to a fresh DB.
--
-- query_attempts is a FRESH table, so full inline NOT NULL / CHECK / UNIQUE
-- constraints are fine on this upgrade path (the 0010 pattern) — they match the
-- canonical db/schema.sql definition byte-for-byte.
--
-- ORDERING: targets (0001), agent_steps (0001), input_slices (0001) are all created
-- earlier, so the query_attempts FK references resolve cleanly when this is applied
-- last. This migration touches no view, no lane roster, no v_required_deep_lanes.

------------------------------------------------------------
-- query_attempts (schema v15) — backs the LLMxCPG-Q-style bounded CPGQL
-- query-generation feedback loop (arXiv:2507.16585): generate -> run -> feedback ->
-- retry (≤3) -> dead_end. One row per attempt; slice_id is nullable because an
-- attempt may PRECEDE a successful slice. query_text holds the CPGQL inline; >16 KB
-- offloads to query_sidecar_path (agent_observations.body_sidecar_path convention).
-- Idempotency: attempt_hash UNIQUE; natural (target_id, agent_step_id, attempt_no).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS query_attempts (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  slice_id INTEGER REFERENCES input_slices(id),   -- nullable; an attempt may precede a successful slice
  attempt_no INTEGER NOT NULL,
  query_text TEXT,                                 -- the CPGQL; sidecar when >16 KB
  query_sidecar_path TEXT,                         -- mirrors agent_observations.body_sidecar_path convention
  status TEXT NOT NULL
    CHECK (status IN ('valid', 'syntax_error', 'empty')),
  joern_error TEXT,
  created_at TIMESTAMP NOT NULL,
  attempt_hash TEXT NOT NULL,                      -- idempotency
  UNIQUE (attempt_hash),
  UNIQUE (target_id, agent_step_id, attempt_no)
);

INSERT INTO schema_version (version, description)
VALUES (15, 'LLMxCPG: execution_path slice_kind (schema.sql) + query_attempts table for CPGQL query-gen feedback loop')
ON CONFLICT DO NOTHING;
