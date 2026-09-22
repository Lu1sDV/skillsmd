-- vuln-research migration 0003 — fuzzing lane (Phase 1.5, DEEP-only)
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: purely additive. Creates one new table, fuzz_runs, recording per-run
-- fuzzing config + coverage + mandatory-attempt accounting for the Phase 1.5
-- lane. Crashes/divergences themselves are gr_findings rows (finding_kind='fuzz_crash'
-- or 'fuzz_divergence'); because finding_kind is free TEXT (gr_findings.finding_kind has
-- no CHECK enum), no enum widening is required FOR THE TABLE — its creation
-- applies cleanly to a v2 DB.
--
-- STRATEGY NOTE:
--   The Phase 1.5 lane logs its agent_steps under a dedicated strategy,
--   strategies.name = 'boundary_fuzz_lane' (seed id 10), kept DISTINCT from
--   'isolation_fuzz_lane' (the defense-isolation fuzzing lane, driven primarily
--   in the Phase 0.75 Defense Pre-Break) so the two fuzzing purposes never
--   conflate in queries. Current db/schema.sql / 0001-initial.sql use free TEXT
--   for strategies.name, and migration 0008 inserts/updates the seed row to
--   version 2. Obsolete audit DBs that still have a pre-v0.14 strategies.name
--   CHECK cannot be widened in place by DuckDB; because audit DBs are ephemeral,
--   the supported upgrade path for those files is: delete and re-scan. fuzz_runs
--   itself is unaffected — it FKs agent_steps(id), not a strategy. See
--   references/v2/fuzzing-lane.md § lane identity.
--
-- ORDERING: fuzz_runs.round_id references round_ledger(id), which is created by
-- migration 0002. Apply 0002 before 0003. targets(id) and agent_steps(id) exist
-- since v1. All FKs below therefore resolve against tables that already exist.
--
-- The orchestrator remains the single writer and validates these references at
-- flush time; db/schema.sql carries the identical definition for fresh DBs.

------------------------------------------------------------
-- Fuzzing lane (Phase 1.5, DEEP-only). Each row is one fuzz run against one
-- entry point: the engine + sanitizer config, whether a pre-existing pipeline
-- was reused, coverage/skip accounting, and the crashes it emitted. Crashes
-- themselves are gr_findings rows (finding_kind='fuzz_crash' or 'fuzz_divergence'); this table is the
-- per-run metadata + mandatory-attempt accounting. See references/v2/fuzzing-lane.md.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fuzz_runs (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  -- entry_point: the harnessed boundary fuzzed (parser fn, FFI shim, decoder,
  -- protocol/session handler).
  -- NULL only on a skipped run (skip_reason set, coverage_json explains why).
  entry_point TEXT,
  -- engine: fuzzer/driver used — 'afl++', 'libfuzzer', 'honggfuzz', 'cargo-fuzz',
  -- 'go-test-fuzz', 'jazzer', 'klee', 'symcc', 'miri', or 'none' on a skip.
  engine TEXT NOT NULL,
  -- sanitizers: JSON array of sanitizers enabled — e.g. '["asan","ubsan"]',
  -- '["msan"]', '["jazzer"]'. JSON-in-TEXT to match the schema's other array
  -- columns (cascade_emitted_*); '[]' on a skip.
  sanitizers TEXT,
  -- reused_existing_pipeline: TRUE when recon found prior fuzzing infra
  -- (OSS-Fuzz target, in-tree fuzz harness, seed corpus) and this run reused it
  -- rather than building fresh. The lane MUST check for this first.
  reused_existing_pipeline BOOLEAN NOT NULL DEFAULT FALSE,
  -- existing_pipeline: JSON snapshot of the recon — what fuzzing infra already
  -- existed (oss_fuzz, in_tree_targets[], corpora_paths[], build_integration).
  existing_pipeline TEXT,
  -- coverage_json: the fuzz_coverage_json contract — {surface, attempted[],
  -- reason, edges, runtime_s}. On a skip it records the non-fuzzable surface and
  -- why (mirrors defense_bypasses.exhaustion_log). The orchestrator verifies this
  -- log before accepting the lane as exhausted.
  coverage_json TEXT,
  -- skip_reason: set when the mandatory lane was skipped on a non-fuzzable target.
  -- Canonical values: 'no_native_code', 'no_parsers_or_ffi', 'interpreted_only',
  -- 'no_harnessable_entrypoint', 'no_stateful_protocol_surface',
  -- 'no_harnessable_state_oracle', 'env_unavailable', 'other'. Free TEXT (no CHECK)
  -- so the value set can grow without a DuckDB constraint rebuild.
  skip_reason TEXT,
  crash_count INTEGER NOT NULL DEFAULT 0,
  -- emitted_finding_ids: JSON array of gr_findings.id rows this run produced
  -- (finding_kind='fuzz_crash' or 'fuzz_divergence'), so a result traces back to its run. Parallels
  -- defense_bypasses.cascade_emitted_finding_ids.
  emitted_finding_ids TEXT,
  round_id INTEGER REFERENCES round_ledger(id),
  created_at TIMESTAMP,
  fuzz_run_hash TEXT NOT NULL,
  UNIQUE (fuzz_run_hash)
);

INSERT INTO schema_version (version, description)
VALUES (3, 'fuzzing lane (Phase 1.5): fuzz_runs per-run config, coverage, mandatory-attempt accounting')
ON CONFLICT DO NOTHING;
