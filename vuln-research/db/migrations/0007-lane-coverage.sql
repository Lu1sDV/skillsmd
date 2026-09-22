-- vuln-research migration 0007 — lane-coverage gate
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: two read-only views that turn "a DEEP lane was defined but never
-- spawned" into a queryable, BLOCKING delta. Purely additive — both are
-- CREATE OR REPLACE VIEW statements with NO table change, so re-applying this
-- file is clean.
--   v_required_deep_lanes : the mandatory lane roster (one row per strategy that
--                           a DEEP audit MUST run) + the phase each belongs to.
--   v_lane_coverage       : joins that roster to strategies -> agent_steps and
--                           classifies each lane ok / skipped / MISSING. The DEEP
--                           completion gate BLOCKS on any 'MISSING' row.
--
-- ENUM NOTE: this migration does NOT touch the agent_steps.status CHECK. The
-- enum extension (+'scheduled', +'skipped') rides in 0001-initial.sql IN PLACE,
-- not here, because DuckDB cannot DROP/ALTER a CHECK nor DROP an FK-referenced
-- table — so the status enum cannot be loosened by a forward migration. See the
-- NOTE block in 0001-initial.sql (alongside the strategies.name / severity
-- loosenings) for the byte-alignment rationale.
--
-- ORDERING: strategies + agent_steps are created by 0001, so these views resolve
-- cleanly when applied last. Views use CREATE OR REPLACE so re-apply is clean.
-- db/schema.sql carries the identical definitions for fresh DBs.

------------------------------------------------------------
-- v_required_deep_lanes (v0.15): the mandatory lane roster for a DEEP audit.
-- Each of these strategies MUST either execute >=1 agent_step OR record a
-- documented skip (status='skipped' + termination_reason) — see the DEEP
-- Completion Gate in SKILL.md. autoload_seed/expand (knowledge plumbing) and the
-- confirm/proof phases are intentionally NOT here: the former are infrastructure,
-- the latter are gated by v_phase_status + v_coverage instead.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_required_deep_lanes AS
SELECT * FROM (VALUES
  ('forward_slice_lane',                'phase1_hunt'),
  ('backward_sink_lane',                'phase1_hunt'),
  ('critical_function_dataflow_lane',   'phase1_hunt'),
  ('defense_base_lane',                 'phase0_75_prebreak'),
  ('defense_context_verification_lane', 'phase0_75_prebreak'),
  ('isolation_fuzz_lane',               'phase0_75_prebreak'),
  ('boundary_fuzz_lane',                'phase1_5_fuzz'),
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

------------------------------------------------------------
-- v_lane_coverage (v0.15): per-required-lane execution ledger for the DEEP gate.
-- Joins the mandatory roster to strategies -> agent_steps and classifies each lane:
--   'ok'      >=1 executed step (running/success/exhausted/failed/timed_out)
--   'skipped' 0 executed but a documented skip (status='skipped' + termination_reason)
--   'MISSING' neither — a required lane defined but never spawned. The DEEP
--             completion gate BLOCKS on any 'MISSING' row. This is what makes a
--             never-spawned lane a queryable, blocking delta instead of silent.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_lane_coverage AS
SELECT
  r.lane_name,
  r.phase,
  s.id AS strategy_id,
  COUNT(st.id)                                                                 AS steps_total,
  COUNT(*) FILTER (WHERE st.status = 'scheduled')                              AS steps_scheduled,
  COUNT(*) FILTER (WHERE st.status IN ('running','success','exhausted','failed','timed_out')) AS steps_executed,
  COUNT(*) FILTER (WHERE st.status = 'skipped'
                   AND st.termination_reason IS NOT NULL
                   AND st.termination_reason <> '')                            AS steps_skipped_documented,
  CASE
    WHEN COUNT(*) FILTER (WHERE st.status IN ('running','success','exhausted','failed','timed_out')) > 0
      THEN 'ok'
    WHEN COUNT(*) FILTER (WHERE st.status = 'skipped'
                          AND st.termination_reason IS NOT NULL
                          AND st.termination_reason <> '') > 0
      THEN 'skipped'
    ELSE 'MISSING'
  END AS gate_status
FROM v_required_deep_lanes r
LEFT JOIN strategies s ON s.name = r.lane_name
LEFT JOIN agent_steps st ON st.strategy_id = s.id
GROUP BY r.lane_name, r.phase, s.id;

INSERT INTO schema_version (version, description) VALUES (7, 'lane-coverage gate: v_required_deep_lanes + v_lane_coverage; agent_steps.status += scheduled,skipped') ON CONFLICT DO NOTHING;
