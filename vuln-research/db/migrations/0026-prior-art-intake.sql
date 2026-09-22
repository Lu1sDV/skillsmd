-- vuln-research migration 0026 — prior-art intake (Phase L-1, bug-bounty mode)
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: a NEW mandatory-when-scope-provided DEEP lane, prior_art_intake_lane, runs in
-- Phase L-1 (BEFORE Phase 0 decompose) whenever a bug-bounty target SCOPE is provided. It
-- mines public prior art keyed on the scope identifiers (vendor/product/version/CPE) from
-- NVD / GHSA / OSV / exploit-db (CVEs) plus web writeups, PERSISTS what it finds, and
-- DISTILS the high-yield leads into promising_lanes rows the FIRST round consumes via the
-- existing round-entry fetch (10). It is distillation-first (NOT "store every CVE"): the
-- lane's coverage_json records sources_queried[] + per-source counts as the honest
-- completeness self-attestation. When no scope is provided or a source is unreachable the
-- lane records a DOCUMENTED SKIP (agent_steps.status='skipped' + termination_reason) — the
-- Phase L0 documented-skip precedent — so the roster gate is satisfied without network.
-- Five additive pieces:
--   (1) cves — NEW table. One row per (target, cve_id, source) prior-art CVE. source is the
--       CLOSED provenance vocab (nvd|ghsa|osv|exploit-db) → CHECK; the same CVE seen from two
--       sources is two provenance rows (NK target_id+cve_id+source). cve_id is OPEN free TEXT
--       (multi-source ids: CVE-/GHSA-). Large raw payloads sidecar (raw_sidecar_path, the A1 rule).
--   (2) writeups — NEW table. One row per (target, url) web writeup. source/bug_class are OPEN
--       free TEXT (open vocab). related_cve_id is a NULLABLE FK to cves (a writeup may pin a CVE).
--   (3) promising_lanes — ALTER: two NULLABLE provenance columns derived_from_cve_id /
--       derived_from_writeup_id. On THIS upgrade path they are added as plain
--       ADD COLUMN IF NOT EXISTS ... INTEGER with NO inline FK — DuckDB cannot ADD a column
--       with an inline FK / ADD CONSTRAINT after the fact (the 0009/0013 precedent). The
--       enforced REFERENCES live in the canonical db/schema.sql fresh-create and are
--       pre-validated app-side in db/harness/put.go (fkRefs). No existing column changes.
--   (4) prior_art_intake_lane strategy (id 25) — MANDATORY-when-scope-provided DEEP lane,
--       appended to v_required_deep_lanes under the NEW phase 'phase_l1_prior_art'. The
--       documented-skip path satisfies the gate when no scope (Phase L0 precedent).
--   (5) v_phase_status — restate (CREATE OR REPLACE; idempotent, FK-free): add the
--       phase_l1_prior_art row (rows_populated = cves + writeups count) at phase_seq -1 so it
--       sorts BEFORE phase0_decompose. phase_seq becomes DOUBLE (only consumed by ORDER BY in
--       cmd/vrdb/main.go — never scanned as an int).
--
-- FRESH-TABLE NOTE (the 0010/0015/0017/0018/0025 pattern): cves + writeups are NEW tables, so
-- their inline NOT NULL / CHECK / UNIQUE / FK constraints are safe on this upgrade path and
-- match db/schema.sql byte-for-byte. cves is declared BEFORE writeups so writeups.related_cve_id
-- resolves within the migration.
--
-- ORDERING: targets (0001) exists earlier, so cves.target_id / writeups.target_id resolve. cves
-- is created before writeups (related_cve_id FK). promising_lanes (0025) exists earlier so the
-- ALTER applies. v_required_deep_lanes / v_phase_status were created earlier (0006/0007) and last
-- restated by 0024/0025; CREATE OR REPLACE VIEW is idempotent + FK-free (DuckDB replaces the whole
-- body), so the full bodies are restated here. db/schema.sql carries the identical definitions
-- (schema_mirror parity).

------------------------------------------------------------
-- (1) cves (schema v26) — target-scoped prior-art CVE inventory. See db/schema.sql.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cves (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  cve_id TEXT NOT NULL,                                     -- 'CVE-2024-1234' / 'GHSA-xxxx'; OPEN free TEXT (multi-source ids)
  product TEXT,                                             -- vendor/product label from scope
  cpe TEXT,                                                 -- optional CPE 2.3 string
  version_range TEXT,
  cvss REAL,
  summary TEXT,
  source TEXT NOT NULL                                      -- CLOSED provenance vocab
    CHECK (source IN ('nvd', 'ghsa', 'osv', 'exploit-db')),
  published_at TIMESTAMP,
  raw_ref TEXT,                                             -- url / advisory id / raw-json pointer
  raw_sidecar_path TEXT,                                    -- set when raw_ref payload > 16 KB (A1)
  created_at TIMESTAMP NOT NULL,
  UNIQUE (target_id, cve_id, source)                        -- NK: same CVE from two sources = two provenance rows
);

------------------------------------------------------------
-- (2) writeups (schema v26) — target-scoped web writeup inventory. See db/schema.sql.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS writeups (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  url TEXT NOT NULL,
  title TEXT,
  source TEXT,                                              -- OPEN free TEXT: blog/hackerone/gh/twitter
  summary TEXT,
  bug_class TEXT,                                           -- OPEN vocab descriptive (ssti/sqli/...) — mirrors promising_lanes.vuln_class
  related_cve_id INTEGER REFERENCES cves(id),              -- nullable: a writeup may pin a CVE
  created_at TIMESTAMP NOT NULL,
  UNIQUE (target_id, url)                                   -- NK: one row per (target, url)
);

------------------------------------------------------------
-- (3) promising_lanes — ALTER: nullable prior-art provenance columns. NO inline FK on the
-- upgrade path (DuckDB cannot ADD COLUMN+FK / ADD CONSTRAINT after the fact — the 0009/0013
-- precedent); the enforced REFERENCES live in the canonical db/schema.sql fresh-create and are
-- pre-validated in db/harness/put.go fkRefs.
------------------------------------------------------------
ALTER TABLE promising_lanes ADD COLUMN IF NOT EXISTS derived_from_cve_id INTEGER;
ALTER TABLE promising_lanes ADD COLUMN IF NOT EXISTS derived_from_writeup_id INTEGER;

------------------------------------------------------------
-- (4) prior_art_intake_lane strategy (id 25). MANDATORY DEEP when scope provided.
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (25, 'prior_art_intake_lane', 'Phase L-1 (DEEP, bug-bounty-mode MANDATORY when a target scope is provided) prior-art intake lane. Runs BEFORE Phase 0 decompose. Mines public prior art keyed on the scope identifiers (vendor/product/version/CPE): CVEs from NVD/GHSA/OSV/exploit-db + web writeups, persists cves + writeups rows, and DISTILS the high-yield leads into promising_lanes (derived_from_cve_id/derived_from_writeup_id provenance; region_hash=''__TARGET_WIDE__'' for unanchored leads) consumed by round 1 via round-entry fetch (10). Distillation-first per-source provenance gate: coverage_json records sources_queried[] + per-source counts (NOT "all CVEs"). DOCUMENTED-SKIP end state (agent_steps.status=''skipped'' + termination_reason) when no scope is provided or a source is unreachable — the Phase L0 fallback precedent — so the roster gate is satisfied without network. See references/methodology/prior-art-intake-lane.md.', 1)
ON CONFLICT (name) DO UPDATE SET description = excluded.description, version = excluded.version;

------------------------------------------------------------
-- (4b) v_required_deep_lanes — append prior_art_intake_lane under phase_l1_prior_art. Full
-- body restated (idempotent CREATE OR REPLACE); all prior rows byte-identical to 0024/db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_required_deep_lanes AS
SELECT * FROM (VALUES
  ('prior_art_intake_lane',             'phase_l1_prior_art'),  -- migration 0026 (C1; documented-skip when no scope/network — Phase L0 precedent)
  ('preliminary_enumeration_lane',      'phase0_decompose'),  -- migration 0014 (enumeration completeness)
  ('forward_slice_lane',                'phase1_hunt'),
  ('backward_sink_lane',                'phase1_hunt'),
  ('critical_function_dataflow_lane',   'phase1_hunt'),
  ('defense_base_lane',                 'phase0_75_prebreak'),  -- unified token (was phase0_75_prebreak_and_recheck in v_phase_status pre-v0.30)
  ('defense_context_verification_lane', 'phase0_75_prebreak'),
  ('isolation_fuzz_lane',               'phase0_75_prebreak'),
  ('html_sanitizer_bypass_lane',        'phase0_75_prebreak'),
  ('concolic_bypass_lane',              'phase0_75_prebreak'),  -- migration 0013 (C5)
  ('llm_seed_corpus_lane_a',            'phase1_4_seed'),       -- migration 0011 (C2)
  ('llm_seed_corpus_lane_b',            'phase1_4_seed'),       -- migration 0011 (C2)
  ('fuzzgpt_history_lane',              'phase1_4_seed'),       -- migration 0024 (history-driven LLM fuzzing; coexists with the dual seed-corpus lanes)
  ('boundary_fuzz_lane',                'phase1_5_fuzz'),
  ('methodology_blindspot_lane_a',      'phase1_6_blindspot'),  -- migration 0018 (post-Hunt meta pass)
  ('methodology_blindspot_lane_b',      'phase1_6_blindspot'),  -- migration 0018 (post-Hunt meta pass)
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

------------------------------------------------------------
-- (5) v_phase_status — restate; add the phase_l1_prior_art row (rows_populated = cves +
-- writeups) at phase_seq -1 so it sorts BEFORE phase0_decompose. Full body restated; all other
-- rows byte-identical to 0023/db/schema.sql. phase_seq becomes DOUBLE (only ORDER BY consumes it).
------------------------------------------------------------
CREATE OR REPLACE VIEW v_phase_status AS
SELECT phase_seq, phase, rows_populated, (rows_populated > 0) AS ran
FROM (
  SELECT -1 AS phase_seq, 'phase_l1_prior_art' AS phase,
         (SELECT count(*) FROM cves) + (SELECT count(*) FROM writeups) AS rows_populated
  UNION ALL SELECT 0, 'phase0_decompose',
         (SELECT count(*) FROM sources) + (SELECT count(*) FROM sinks)
       + (SELECT count(*) FROM defenses) + (SELECT count(*) FROM critical_functions)
  UNION ALL SELECT 1, 'phase0_5_plan',
         (SELECT count(*) FROM input_slices) + (SELECT count(*) FROM critical_fn_reach)
  UNION ALL SELECT 2, 'phase0_75_prebreak',
         (SELECT count(*) FROM defense_bypasses)
  UNION ALL SELECT 3, 'phase1_hunt',
         (SELECT count(*) FROM gr_findings)
  UNION ALL SELECT 4, 'phase1_4_seed',
         (SELECT count(*) FROM fuzz_artifacts WHERE artifact_kind = 'seed_initial')
  UNION ALL SELECT 5, 'phase1_5_fuzz',
         (SELECT count(*) FROM fuzz_runs)
  UNION ALL SELECT 6, 'phase1_6_blindspot',
         (SELECT count(*) FROM methodology_blind_spots)
  UNION ALL SELECT 7, 'phase2_confirm',
         (SELECT count(*) FROM refutations)
  UNION ALL SELECT 8, 'phase4_proof',
         (SELECT count(*) FROM audit_outcomes)
  UNION ALL SELECT 9, 'phase5_report',
         (SELECT count(*) FROM critic_findings)
) t
ORDER BY phase_seq;

INSERT INTO schema_version (version, description)
VALUES (26, 'prior-art intake (v0.39.0): cves + writeups tables (target-scoped CVE/advisory + writeup inventory for the bug-bounty-mode Phase L-1 prior_art_intake_lane, strategy 25, MANDATORY when a scope is provided) + promising_lanes.derived_from_cve_id/derived_from_writeup_id nullable provenance FK columns (ADD COLUMN ... INTEGER on the upgrade path with NO inline FK per the 0009/0013 precedent; canonical schema.sql carries the enforced REFERENCES, pre-validated in put.go fkRefs). cves.source CLOSED vocab (nvd|ghsa|osv|exploit-db) CHECK, NK (target_id,cve_id,source); writeups NK (target_id,url), nullable related_cve_id FK. The lane DISTILS prior art into promising_lanes consumed by round 1 via round-entry fetch (10); distillation-first per-source provenance (coverage_json sources_queried[]+counts), NOT "store every CVE". prior_art_intake_lane appended to v_required_deep_lanes under NEW phase_l1_prior_art; v_phase_status gains the phase_l1_prior_art row (rows_populated = cves+writeups) at phase_seq -1. Documented-skip fallback (agent_steps.status=skipped + termination_reason) when no scope/network — the Phase L0 precedent — satisfies the roster gate. No new v_coverage gate (distillation-first proof lives in coverage_json, not a blocking metric).')
ON CONFLICT DO NOTHING;
