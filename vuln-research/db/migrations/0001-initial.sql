-- vuln-research migration 0001 — initial v2-consolidated schema
-- Canonical source: references/v2/pipeline-architecture.md
-- Forward-only, idempotent. Safe to re-apply.
-- Mirrors vuln-research/db/schema.sql; the only added side effect is the
-- schema_version row INSERT ... ON CONFLICT DO NOTHING.

------------------------------------------------------------
-- Schema version (B1)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schema_version (
  version INTEGER PRIMARY KEY,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  description TEXT
);

INSERT INTO schema_version (version, description)
VALUES (1, 'initial v2-consolidated schema')
ON CONFLICT DO NOTHING;

------------------------------------------------------------
-- Targets / sources / sinks (§2.1)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS targets (
  id INTEGER PRIMARY KEY,
  repo_url TEXT NOT NULL,
  commit_sha TEXT NOT NULL,
  language TEXT NOT NULL,
  scanned_at TIMESTAMP NOT NULL,
  UNIQUE (repo_url, commit_sha)
);

CREATE TABLE IF NOT EXISTS sources (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  source_kind TEXT NOT NULL,
  symbol_path TEXT NOT NULL,
  evidence_path TEXT,
  evidence_line INTEGER,
  rank_score REAL,
  UNIQUE (target_id, symbol_path, source_kind)
);

CREATE TABLE IF NOT EXISTS sinks (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  sink_category TEXT NOT NULL,
  symbol_path TEXT NOT NULL,
  evidence_path TEXT,
  evidence_line INTEGER,
  rank_score REAL,
  UNIQUE (target_id, symbol_path, sink_category)
);

------------------------------------------------------------
-- Defenses (§2.7, S1)
------------------------------------------------------------
-- defense_type intentionally excludes 'generic'. 'generic' is a
-- bypass-catalogue classification (see db/catalogue/bypasses.json) for
-- cross-cutting techniques (type juggling, length manipulation, charset
-- confusion); it is unioned into Stage-A lane queries via
-- `OR defense_type = 'generic'` against the catalogue, never stored as a
-- defenses row. Per-target defenses are always one of the 3 concrete types.
CREATE TABLE IF NOT EXISTS defenses (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  defense_type TEXT NOT NULL
    CHECK (defense_type IN ('sanitizer_function', 'blacklist', 'allowlist')),
  tier TEXT NOT NULL
    CHECK (tier IN ('tier1', 'tier2')),
  symbol_path TEXT NOT NULL,
  parsed_logic_json TEXT,
  callsite_count INTEGER,
  sink_proximity REAL,
  source_count_gated INTEGER,
  rank_score REAL,
  isolation_cost_json TEXT,
  isolation_eligible BOOLEAN,
  UNIQUE (target_id, symbol_path, defense_type)
);

------------------------------------------------------------
-- Strategies (§2.3, B4)
------------------------------------------------------------
-- NOTE: the CHECK relaxations below (strategies.name, critic_findings.severity,
-- defense_bypasses.severity, agent_steps.status (+scheduled,+skipped)) were
-- loosened in place rather than via a forward migration because DuckDB cannot
-- DROP/ALTER a CHECK, nor DROP an FK-referenced table. Editing 0001 in place is
-- what keeps this migration chain byte-aligned with db/schema.sql (the harness
-- applies schema.sql, not these migrations; the chain exists for the test suite,
-- which rebuilds from empty each run).
CREATE TABLE IF NOT EXISTS strategies (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE, -- free TEXT: the lane vocabulary is open/extensible; seed rows define the canonical set (CHECK removed v0.14 — see doctrine note at top of file)
  description TEXT NOT NULL,
  version INTEGER NOT NULL
);

-- Strategy seed. agent_steps.strategy_id FK requires these rows to exist; seed
-- is idempotent (ON CONFLICT (name) DO NOTHING — UNIQUE on name). IDs 1..8 are
-- reserved for seed rows; DuckDB does not auto-increment INTEGER PRIMARY KEY,
-- so any future non-seed strategy must pick an id >= 9. Source of truth for
-- the description / version values: db/seed/strategies.yml.
INSERT INTO strategies (id, name, description, version) VALUES
  (1, 'forward_slice_lane',                'Trace taint forward from a source through its callee set toward declared sinks.',                                     1),
  (2, 'backward_sink_lane',                'Trace controllability backward from a sink to find which sources reach it.',                                          1),
  (3, 'defense_base_lane',                 'Run the three-stage bypass-hunting protocol against a ranked defense (consumes the global DuckDB bypass catalogue).', 1),
  (4, 'defense_context_verification_lane', 'Confirm whether a flagged bypass actually flows from a real source to a real sink through this slice.',               1),
  (5, 'isolation_fuzz_lane',               'Stage 3 of bypass-hunting: cost-gated isolation harness fuzzing.',                                                    1),
  (6, 'autoload_seed_lane',                'Phase-entry seed of top-K=10 knowledge chunks into the agent prompt context.',                                        1),
  (7, 'autoload_expand_lane',              'Lazy on-demand expand of additional knowledge chunks (cap 50 per agent_step).',                                       1),
  (8, 'report_critic',                     'Phase 5 critic. Runs comprehension / eligibility / attack-scenario checks over each confirmed finding.',              1)
ON CONFLICT (name) DO NOTHING;

------------------------------------------------------------
-- Input slices (§2.3, R5)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS input_slices (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  source_id INTEGER NOT NULL REFERENCES sources(id),
  callee_set_hash TEXT NOT NULL,
  slice_kind TEXT NOT NULL
    CHECK (slice_kind IN ('forward_taint', 'backward_sink', 'defense_callsite')),
  callee_count INTEGER NOT NULL,
  representative_callees TEXT,
  UNIQUE (target_id, callee_set_hash, slice_kind)
);

------------------------------------------------------------
-- Intended-feature classification (§2.8, R3, R6)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intended_feature_classification (
  id INTEGER PRIMARY KEY,
  sink_id INTEGER NOT NULL REFERENCES sinks(id),
  is_documented_behavior BOOLEAN,
  precondition_strictness TEXT NOT NULL
    CHECK (precondition_strictness IN ('trivial', 'authed', 'privileged', 'admin_only')),
  observed_role_at_sink TEXT NOT NULL
    CHECK (observed_role_at_sink IN ('anonymous', 'user', 'admin', 'service')),
  classification_evidence_json TEXT,
  classified_at TIMESTAMP NOT NULL,
  UNIQUE (sink_id)
);

------------------------------------------------------------
-- Agent steps (§2.3)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agent_steps (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  strategy_id INTEGER NOT NULL REFERENCES strategies(id),
  slice_id INTEGER REFERENCES input_slices(id),
  defense_id INTEGER REFERENCES defenses(id),
  parent_step_id INTEGER REFERENCES agent_steps(id),
  started_at TIMESTAMP NOT NULL,
  ended_at TIMESTAMP,
  status TEXT NOT NULL
    CHECK (status IN ('scheduled', 'running', 'success', 'exhausted', 'failed', 'timed_out', 'skipped')),
  termination_reason TEXT,
  coverage_json TEXT,
  step_hash TEXT NOT NULL,
  UNIQUE (step_hash)
);

------------------------------------------------------------
-- Phase-0 priorities (§2.2, B2)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS phase0_priorities (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  artifact_kind TEXT NOT NULL
    CHECK (artifact_kind IN ('source', 'sink', 'defense', 'slice')),
  artifact_id INTEGER NOT NULL,
  tier TEXT NOT NULL
    CHECK (tier IN ('tier1', 'tier2', 'tier3')),
  factor_callsite_count REAL,
  factor_taint_reach REAL,
  factor_sink_proximity REAL,
  factor_source_count REAL,
  factor_severity_potential REAL,
  factor_tier_weight REAL,
  factor_recent_change_velocity REAL,
  factor_test_coverage_inverse REAL,
  factor_external_exposure REAL,
  composite_score REAL,
  UNIQUE (target_id, artifact_kind, artifact_id)
);

------------------------------------------------------------
-- Findings (§2.4, R1)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gr_findings (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  sink_id INTEGER REFERENCES sinks(id),
  source_id INTEGER REFERENCES sources(id),
  defense_id INTEGER REFERENCES defenses(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  finding_kind TEXT NOT NULL,
  payload TEXT,
  payload_sidecar_path TEXT,
  confirmation_status TEXT NOT NULL
    CHECK (confirmation_status IN ('candidate', 'confirmed', 'refuted')),
  severity TEXT
    CHECK (severity IS NULL OR severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  -- Deployment-configuration provenance for the proof attached to this finding.
  -- Gate 4 (Reproduction artifact, references/confirmation-rigor-doctrine.md)
  -- requires this to be set before promotion to confirmed. Phase 5 eligibility
  -- check turns 'non_vanilla' into WARNING + required_config_delta and 'unknown'
  -- (or NULL) into CRITICAL.
  config_state TEXT
    CHECK (config_state IS NULL OR config_state IN ('vanilla', 'non_vanilla', 'unknown')),
  finding_hash TEXT NOT NULL,
  UNIQUE (finding_hash)
);

CREATE OR REPLACE VIEW confirmed_vulns AS
  SELECT * FROM gr_findings WHERE confirmation_status = 'confirmed';

------------------------------------------------------------
-- Refutations (§2.4)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS refutations (
  id INTEGER PRIMARY KEY,
  finding_id INTEGER NOT NULL REFERENCES gr_findings(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  refutation_reason TEXT NOT NULL
    CHECK (refutation_reason IN (
      'not_reachable',
      'sanitized',
      'intended_feature',
      'wrong_role',
      'preconditions_unmet',
      'env_required',
      'other'
    )),
  evidence_json TEXT,
  created_at TIMESTAMP NOT NULL,
  UNIQUE (finding_id, agent_step_id, refutation_reason)
);

------------------------------------------------------------
-- Audit outcomes (§2.4, A3a, R7)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_outcomes (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  audit_run_id TEXT NOT NULL,
  outcome TEXT NOT NULL
    CHECK (outcome IN ('TP', 'FP', 'DUP', 'INTENDED', 'UNREACHABLE', 'INCONCLUSIVE')),
  finding_id INTEGER REFERENCES gr_findings(id),
  notes_json TEXT,
  created_at TIMESTAMP NOT NULL,
  UNIQUE (audit_run_id, finding_id)
);

------------------------------------------------------------
-- Critic findings (§2.5, C4, R2)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS critic_findings (
  id INTEGER PRIMARY KEY,
  finding_id INTEGER NOT NULL REFERENCES gr_findings(id),
  check_kind TEXT NOT NULL
    CHECK (check_kind IN ('comprehension', 'eligibility', 'attack_scenario')),
  severity TEXT NOT NULL
    CHECK (severity IN ('OK', 'INFO', 'WARNING', 'CRITICAL')),
  message TEXT NOT NULL,
  evidence_json TEXT,
  created_at TIMESTAMP NOT NULL,
  UNIQUE (finding_id, check_kind)
);

------------------------------------------------------------
-- Defense bypasses (§2.7, S2/S3)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS defense_bypasses (
  id INTEGER PRIMARY KEY,
  defense_id INTEGER NOT NULL REFERENCES defenses(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  technique TEXT NOT NULL,
  payload TEXT,
  payload_sidecar_path TEXT,
  severity TEXT NOT NULL
    CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  reproduced BOOLEAN NOT NULL,
  sink_reach_finding_id INTEGER REFERENCES gr_findings(id),
  isolation_harness_ran BOOLEAN NOT NULL,
  isolation_findings_json TEXT,
  bypass_hash TEXT NOT NULL,
  UNIQUE (bypass_hash)
);

------------------------------------------------------------
-- Autoloading knowledge layer (§2.6, C3)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS knowledge_chunks (
  id INTEGER PRIMARY KEY,
  source TEXT NOT NULL,
  chunk_key TEXT NOT NULL,
  body TEXT NOT NULL,
  version INTEGER NOT NULL,
  UNIQUE (source, chunk_key, version)
);

CREATE TABLE IF NOT EXISTS knowledge_seed_log (
  id INTEGER PRIMARY KEY,
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  chunk_id INTEGER NOT NULL REFERENCES knowledge_chunks(id),
  loaded_at TIMESTAMP NOT NULL,
  load_mode TEXT NOT NULL
    CHECK (load_mode IN ('seed', 'expand'))
);

CREATE TABLE IF NOT EXISTS knowledge_acceptance (
  id INTEGER PRIMARY KEY,
  chunk_id INTEGER NOT NULL REFERENCES knowledge_chunks(id),
  ref_count INTEGER NOT NULL,
  repeat_suppressions INTEGER NOT NULL,
  staleness_days INTEGER NOT NULL,
  growth_rate REAL,
  accepted BOOLEAN NOT NULL,
  decided_at TIMESTAMP NOT NULL
);
