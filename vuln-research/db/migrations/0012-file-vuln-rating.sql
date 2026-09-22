-- vuln-research migration 0012 — C4 preliminary per-file vuln-probability rating
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: adds the Phase-0 preliminary per-FILE P(critical/high) rating that ORDERS
-- (never gates) the audit worklist and reranks automatically as analysis surfaces
-- signal. Mirrors the Suspicious-Point pattern: scores are stored as RAW factors;
-- the composite is computed read-time in v_file_vuln_ranked (no stored composite,
-- exactly like v_suspicious_points_ranked / v_critical_fn_ranked).
--
-- STORAGE-PATH DECISION (companion table, NOT phase0_priorities extension):
-- phase0_priorities.artifact_kind is a CLOSED CHECK
--   CHECK (artifact_kind IN ('source','sink','defense','slice','critical_function'))
-- and DuckDB cannot ADD/widen a CHECK in place (the table is also FK-referenced and
-- cannot be dropped+rebuilt mid-upgrade). Adding a 'file' artifact_kind is therefore
-- impossible on the upgrade path, so per the spec's "closed CHECK = unavoidable new
-- table" rule we use a dedicated companion table `file_vuln_ratings`. The unit is
-- the FILE (not an AST subtree); the file's AST is evidence the heuristic/LLM read.
--
-- DESIGN: a CHEAP heuristic P(crit/high) is computed for EVERY in-scope file
-- (reusing the existing attention-deficit signals — security-commit churn, fuzzing/
-- testing presence, code glamour, external exposure, code age — plus available CPG
-- signals). The heuristic decides clear-hot / clear-cold bands; LLM triage is spent
-- ONLY on the ambiguous MIDDLE band. Runs as the first step of Phase 0 to order the
-- whole worklist. ORDER-ONLY: no row is ever excluded; low scores just sort last,
-- and pre-filter-skipped / heuristic-baseline files still sit (low priority) in the
-- queue. Analysis-derived feedback factors (SP regions, findings, reachable sinks)
-- are stored as additional raw factors and the view reranks the remaining queue —
-- a cold file can escalate to hot.
--
-- CHECK-DIVERGENCE NOTE (mirrors 0009/0010): `band` is the one genuinely-closed
-- vocab, carried here as a plain TEXT with NO CHECK on the upgrade path (DuckDB
-- ADD COLUMN+CHECK / fresh-table-on-upgrade enforcement story is byte-aligned with
-- the prior migrations); db/schema.sql carries the NULL-permitting CHECK for fresh
-- DBs. raw factors are plain REAL — no CHECK either path.
--
-- ORDERING: targets, round_ledger are created by 0001; gr_findings by 0001. All FK
-- references resolve when this is applied last. db/schema.sql carries identical defs.

------------------------------------------------------------
-- file_vuln_ratings — one row per (target, round, file). Stores RAW factors only;
-- the ranked composite is read-time in v_file_vuln_ranked. Both the preliminary
-- heuristic_score AND the LLM-triage llm_score are raw inputs; the analysis-derived
-- feedback factors (factor_sp_region_density / factor_finding_proximity /
-- factor_reachable_sink_count) start NULL and are filled in as analysis runs, which
-- makes the view rerank automatically. `band` records which lane decided the file:
-- 'hot'/'cold' = settled by the cheap heuristic; 'ambiguous' = sent to LLM triage.
-- Fresh table, so inline NOT NULL / UNIQUE are fine.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS file_vuln_ratings (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_id INTEGER REFERENCES round_ledger(id),
  agent_step_id INTEGER REFERENCES agent_steps(id),
  file_path TEXT NOT NULL,
  -- band: NO CHECK on the upgrade path (CHECK-DIVERGENCE NOTE); db/schema.sql
  -- carries the NULL-permitting CHECK ('hot'/'cold'/'ambiguous').
  band TEXT,
  -- Preliminary scores (RAW factors; composite computed read-time).
  heuristic_score REAL,          -- cheap heuristic P(crit/high), every file
  llm_score REAL,                -- LLM-triage P(crit/high), ambiguous-middle band only
  -- Cheap-heuristic raw factors (reuse the attention-deficit signal family).
  factor_security_commit_churn REAL,  -- recent security-relevant commit density
  factor_test_coverage_inverse REAL,  -- inverse of fuzzing/testing presence
  factor_code_glamour REAL,           -- parser/crypto/auth/serialization "glamour"
  factor_external_exposure REAL,      -- attacker-reachable entry surface
  factor_code_age REAL,               -- staleness / un-revisited age signal
  factor_cpg_signal REAL,             -- available CPG/static signal (optional producer)
  -- Analysis-derived feedback factors (start NULL; filled as analysis surfaces
  -- signal -> the view reranks; a cold file can escalate to hot).
  factor_sp_region_density REAL,      -- suspicious_points anchored in this file
  factor_finding_proximity REAL,      -- gr_findings in / near this file
  factor_reachable_sink_count REAL,   -- reachable sinks located in this file
  created_at TIMESTAMP,
  UNIQUE (target_id, round_id, file_path)
);

------------------------------------------------------------
-- v_file_vuln_ranked — read-time hottest-first ordering. NEVER stores a composite
-- (mirrors v_suspicious_points_ranked). Within each (target_id, round_id) the raw
-- factors are PERCENT_RANK()'d and summed with fixed weights; the preliminary
-- heuristic/LLM scores AND the analysis-derived feedback factors all contribute, so
-- reranking is automatic as the feedback columns fill. ORDER-ONLY: every rated file
-- appears in the result (no WHERE that drops rows); low scores simply sort last.
-- llm_score COALESCEs over heuristic_score so files settled by the cheap heuristic
-- (llm_score NULL) still carry their preliminary signal.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_file_vuln_ranked AS
WITH ranked AS (
  SELECT
    fvr.id,
    fvr.target_id,
    fvr.round_id,
    fvr.file_path,
    fvr.band,
    COALESCE(fvr.llm_score, fvr.heuristic_score) AS prelim_score,
    PERCENT_RANK() OVER (PARTITION BY fvr.target_id, fvr.round_id ORDER BY COALESCE(fvr.llm_score, fvr.heuristic_score)) AS r_prelim,
    PERCENT_RANK() OVER (PARTITION BY fvr.target_id, fvr.round_id ORDER BY COALESCE(fvr.factor_sp_region_density, 0))    AS r_sp,
    PERCENT_RANK() OVER (PARTITION BY fvr.target_id, fvr.round_id ORDER BY COALESCE(fvr.factor_finding_proximity, 0))    AS r_find,
    PERCENT_RANK() OVER (PARTITION BY fvr.target_id, fvr.round_id ORDER BY COALESCE(fvr.factor_reachable_sink_count, 0)) AS r_sink,
    COUNT(*) OVER (PARTITION BY fvr.target_id, fvr.round_id) AS pop_n
  FROM file_vuln_ratings fvr
)
SELECT
  id,
  target_id,
  round_id,
  file_path,
  band,
  prelim_score,
  -- Degenerate single-file population -> deterministic neutral 0.5 (mirrors the SP
  -- view's degenerate guard) so a lone file is never spuriously floored/ceil'd.
  CASE WHEN pop_n <= 1 THEN 0.5 ELSE
    0.55 * r_prelim    -- preliminary heuristic/LLM signal dominates pre-analysis
  + 0.20 * r_sp        -- analysis feedback: suspicious-point density
  + 0.15 * r_find      -- analysis feedback: finding proximity
  + 0.10 * r_sink      -- analysis feedback: reachable-sink count
  END AS rank_score
FROM ranked;

INSERT INTO schema_version (version, description)
VALUES (12, 'per-file vuln-probability rating (Phase 0): file_vuln_ratings companion table (phase0_priorities CHECK is closed) + read-time v_file_vuln_ranked order-only view')
ON CONFLICT DO NOTHING;
