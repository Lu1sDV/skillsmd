-- vuln-research migration 0023 — audit hardening (v0.30.0)
--
-- Forward-only, idempotent. Safe to re-apply (CREATE OR REPLACE VIEW throughout).
--
-- SCOPE: five mechanical gate fixes identified in the 2026-06-01 skill audit:
--
--   (1) ROUND-SCOPING (P0; C03-B-F5, C04-A-F1, C06-A-F4, C03-A-F10, C05-A-F10)
--       The four gate views (v_phase_status, v_coverage, v_lane_coverage,
--       v_observation_coverage) previously aggregated over ALL rows for a target, so
--       on round 2+ a lane that ran once was permanently "satisfied". Fix:
--         • Add helper view v_current_round(target_id, round_id) = MAX(id) from
--           round_ledger per target_id; NULL for targets with no round_ledger rows.
--         • v_lane_coverage + v_observation_coverage now restrict to the CURRENT round.
--         • SINGLE-SHOT audits (round_id IS NULL everywhere) behave exactly as before.
--       NOTE: the roster materialization step_hash is documented as fixed
--       'plan-roster-<lane>' with a global UNIQUE. To be fully round-safe it should
--       be 'plan-roster-<lane>-r<round_id>'. This VIEW change is what the spec
--       requires; the step_hash round-keying is an app-side fix (out of scope here).
--
--   (2) lanes_stuck_running gate (P2; completeness critic)
--       v_lane_coverage previously counted status='running' as ok. Fixed: only
--       'success'/'exhausted' count as ok; 'failed'/'timed_out' surface as steps_failed;
--       a new steps_stuck_running column counts 'running' steps in the current round.
--       v_coverage gains a lanes_stuck_running metric (SUM of steps_stuck_running
--       across required lanes). RED when > 0.
--
--   (3) confirmed_without_refutation gate (P0; C08-A-F1)
--       Mirrors the existing confirmed_without_critic pattern. v_coverage gains a
--       confirmed_without_refutation metric = count of gr_findings with
--       confirmation_status='confirmed' that have NO refutations row. RED when > 0.
--       Mechanically enforces the refute-before-confirm mandate.
--
--   (4) Fix gameable fuzz-coverage gate (P0; C09-A-F1)
--       fuzz_runs_without_coverage_measurement previously used
--         coverage_json NOT LIKE '%edges%' AND ... '%blocks%' AND ... '%function_coverage%'
--       which is gameable (incidental word matches pass; NULL coverage_json with an
--       embedded keyword passes). Replaced with the same json_extract/TRY_CAST
--       value-presence check v_fuzz_coverage already uses: a run is unmeasured only
--       when ALL of json_extract '$.edges', '$.blocks', '$.function_coverage' are
--       NULL/absent. Do NOT rewrite migration 0022 (forward-only); applied here via
--       CREATE OR REPLACE VIEW.
--
--   (5) phase1_4_seed visibility + phase-vocab unify (P1; C01-A-F1, C03-A-F8)
--       v_phase_status previously had no phase1_4_seed row and used the token
--       'phase0_75_prebreak_and_recheck' while v_required_deep_lanes used
--       'phase0_75_prebreak'. Fixed:
--         • Unified token: 'phase0_75_prebreak' everywhere (v_phase_status,
--           v_required_deep_lanes, v_observation_coverage). The old token is gone.
--         • phase1_4_seed row added to v_phase_status, keyed on count of
--           fuzz_artifacts WHERE artifact_kind='seed_initial'.
--         • phase_seq numbers renumbered (phase1_4_seed is seq 4; fuzz is 5; etc.).
--
-- ORDERING: all referenced tables and views (round_ledger, agent_steps, strategies,
-- v_required_deep_lanes, gr_findings, refutations, critic_findings, fuzz_runs,
-- fuzz_artifacts, v_current_round) exist by migration 0022. The CREATE OR REPLACE
-- VIEW sequence below respects the dependency order: v_current_round first (no deps
-- on other new views), then v_phase_status + v_required_deep_lanes (no deps on each
-- other), then v_lane_coverage (depends on v_current_round + v_required_deep_lanes),
-- then v_observation_coverage (depends on v_current_round + v_required_deep_lanes),
-- then v_coverage (depends on v_lane_coverage).

------------------------------------------------------------
-- (1) v_current_round — helper for round-scoped gate evaluation.
-- For each target_id: MAX(id) from round_ledger = the active round.
-- Targets with no round_ledger rows return no row here (single-shot: NULL round_id
-- is handled in the consuming views via OR NOT EXISTS (SELECT 1 FROM round_ledger)).
------------------------------------------------------------
CREATE OR REPLACE VIEW v_current_round AS
SELECT
  target_id,
  MAX(id) AS round_id
FROM round_ledger
GROUP BY target_id;

------------------------------------------------------------
-- (5a) v_phase_status — unified phase vocab + phase1_4_seed row.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_phase_status AS
SELECT phase_seq, phase, rows_populated, (rows_populated > 0) AS ran
FROM (
  SELECT 0 AS phase_seq, 'phase0_decompose' AS phase,
         (SELECT count(*) FROM sources) + (SELECT count(*) FROM sinks)
       + (SELECT count(*) FROM defenses) + (SELECT count(*) FROM critical_functions) AS rows_populated
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

------------------------------------------------------------
-- (5b) v_required_deep_lanes — phase token already uses 'phase0_75_prebreak'
-- (was always correct here; restated for completeness and idempotency).
------------------------------------------------------------
CREATE OR REPLACE VIEW v_required_deep_lanes AS
SELECT * FROM (VALUES
  ('preliminary_enumeration_lane',      'phase0_decompose'),
  ('forward_slice_lane',                'phase1_hunt'),
  ('backward_sink_lane',                'phase1_hunt'),
  ('critical_function_dataflow_lane',   'phase1_hunt'),
  ('defense_base_lane',                 'phase0_75_prebreak'),
  ('defense_context_verification_lane', 'phase0_75_prebreak'),
  ('isolation_fuzz_lane',               'phase0_75_prebreak'),
  ('html_sanitizer_bypass_lane',        'phase0_75_prebreak'),
  ('concolic_bypass_lane',              'phase0_75_prebreak'),
  ('llm_seed_corpus_lane_a',            'phase1_4_seed'),
  ('llm_seed_corpus_lane_b',            'phase1_4_seed'),
  ('boundary_fuzz_lane',                'phase1_5_fuzz'),
  ('methodology_blindspot_lane_a',      'phase1_6_blindspot'),
  ('methodology_blindspot_lane_b',      'phase1_6_blindspot'),
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

------------------------------------------------------------
-- (1)+(2) v_lane_coverage — round-scoped + 'running' no longer counts as ok.
-- gate_status 'ok' requires status IN ('success','exhausted') in the current round.
-- steps_stuck_running = count of 'running' steps in the current round (feeds
-- lanes_stuck_running gate in v_coverage). Single-shot audits (no round_ledger rows)
-- include all steps (round_id IS NULL path).
------------------------------------------------------------
CREATE OR REPLACE VIEW v_lane_coverage AS
WITH current_steps AS (
  SELECT st.*
  FROM agent_steps st
  WHERE
    -- single-shot: no round_ledger rows in DB at all
    (st.round_id IS NULL AND NOT EXISTS (SELECT 1 FROM round_ledger))
    OR
    -- multi-round: step's round_id matches the current round for its target
    st.round_id IS NOT DISTINCT FROM (
      SELECT cr.round_id FROM v_current_round cr
      WHERE cr.target_id = (
        SELECT target_id FROM round_ledger WHERE id = st.round_id LIMIT 1
      )
      LIMIT 1
    )
)
SELECT
  r.lane_name,
  r.phase,
  s.id AS strategy_id,
  COUNT(st.id)                                                                        AS steps_total,
  COUNT(*) FILTER (WHERE st.status = 'scheduled')                                    AS steps_scheduled,
  COUNT(*) FILTER (WHERE st.status IN ('success','exhausted','failed','timed_out',
                                       'running'))                                    AS steps_executed,
  COUNT(*) FILTER (WHERE st.status IN ('success','exhausted'))                       AS steps_ok,
  COUNT(*) FILTER (WHERE st.status IN ('failed','timed_out'))                        AS steps_failed,
  COUNT(*) FILTER (WHERE st.status = 'running')                                      AS steps_stuck_running,
  COUNT(*) FILTER (WHERE st.status = 'skipped'
                   AND st.termination_reason IS NOT NULL
                   AND st.termination_reason <> '')                                  AS steps_skipped_documented,
  CASE
    WHEN COUNT(*) FILTER (WHERE st.status IN ('success','exhausted')) > 0
      THEN 'ok'
    WHEN COUNT(*) FILTER (WHERE st.status = 'skipped'
                          AND st.termination_reason IS NOT NULL
                          AND st.termination_reason <> '') > 0
      THEN 'skipped'
    ELSE 'MISSING'
  END AS gate_status
FROM v_required_deep_lanes r
LEFT JOIN strategies s ON s.name = r.lane_name
LEFT JOIN current_steps st ON st.strategy_id = s.id
GROUP BY r.lane_name, r.phase, s.id;

------------------------------------------------------------
-- (1) v_observation_coverage — round-scoped. Only steps in the current round count.
-- Single-shot audits (no round_ledger rows) include all steps.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_observation_coverage AS
WITH phase_steps AS (
  SELECT
    r.phase                                        AS phase,
    st.id                                          AS step_id
  FROM v_required_deep_lanes r
  JOIN strategies s   ON s.name = r.lane_name
  JOIN agent_steps st ON st.strategy_id = s.id
   AND st.status IN ('running','success','exhausted','failed','timed_out')
   AND (
     (st.round_id IS NULL AND NOT EXISTS (SELECT 1 FROM round_ledger))
     OR
     st.round_id IS NOT DISTINCT FROM (
       SELECT cr.round_id FROM v_current_round cr
       WHERE cr.target_id = (
         SELECT target_id FROM round_ledger WHERE id = st.round_id LIMIT 1
       )
       LIMIT 1
     )
   )
),
phase_list AS (
  SELECT DISTINCT phase FROM v_required_deep_lanes
)
SELECT
  pl.phase                                                   AS phase,
  COUNT(DISTINCT ps.step_id)                                 AS executed_steps,
  COUNT(o.id)                                                AS observations_total,
  CASE
    WHEN COUNT(DISTINCT ps.step_id) = 0 THEN 'not_run'
    WHEN COUNT(o.id) = 0               THEN 'NO_OBSERVATION'
    ELSE 'ok'
  END                                                        AS gate_status
FROM phase_list pl
LEFT JOIN phase_steps ps        ON ps.phase = pl.phase
LEFT JOIN agent_observations o  ON o.agent_step_id = ps.step_id
GROUP BY pl.phase
ORDER BY pl.phase;

------------------------------------------------------------
-- (2)+(3)+(4) v_coverage — full body restated (DuckDB replaces the whole view).
-- Changes vs 0022:
--   • confirmed_without_refutation added (mirrors confirmed_without_critic).
--   • lanes_stuck_running added (SUM of v_lane_coverage.steps_stuck_running).
--   • fuzz_runs_without_coverage_measurement: NOT LIKE substring → json_extract
--     value-presence (same check v_fuzz_coverage uses). A run is unmeasured only
--     when ALL three json_extract results are NULL.
-- All other branches are byte-identical to 0022 / db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_coverage AS
SELECT metric, value, note FROM (
  SELECT 'distinct_target_ids' AS metric, (SELECT count(DISTINCT target_id) FROM gr_findings) AS value,
         'expect exactly 1 per single-target audit; >1 means target_id drift across lanes' AS note
  UNION ALL SELECT 'findings_total', (SELECT count(*) FROM gr_findings),
         'all candidate+confirmed+refuted findings'
  UNION ALL SELECT 'findings_candidate_open', (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate'),
         'still unconfirmed; Confirm phase incomplete if >0 at report time'
  UNION ALL SELECT 'findings_confirmed', (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'confirmed'),
         'promoted findings (the registry)'
  UNION ALL SELECT 'confirmed_missing_severity', (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'confirmed' AND severity IS NULL),
         'confirmed finding with no severity set — Proof/critic gap'
  UNION ALL SELECT 'confirmed_without_critic', (SELECT count(*) FROM gr_findings f WHERE f.confirmation_status = 'confirmed' AND NOT EXISTS (SELECT 1 FROM critic_findings c WHERE c.finding_id = f.id)),
         'confirmed finding that never went through the REPORT critic'
  UNION ALL SELECT 'confirmed_without_refutation',
    (SELECT count(*) FROM gr_findings f
     WHERE f.confirmation_status = 'confirmed'
       AND NOT EXISTS (SELECT 1 FROM refutations r WHERE r.finding_id = f.id)),
    'confirmed finding with no refutations row — refute-before-confirm mandate violated (RED)'
  UNION ALL SELECT 'defenses_total', (SELECT count(*) FROM defenses),
         'defense inventory size'
  UNION ALL SELECT 'defenses_without_bypass_attempt', (SELECT count(*) FROM defenses d WHERE NOT EXISTS (SELECT 1 FROM defense_bypasses b WHERE b.defense_id = d.id)),
         'defense with zero bypass attempts — Phase 0.75 pre-break gap'
  UNION ALL SELECT 'fuzz_runs_total', (SELECT count(*) FROM fuzz_runs),
         'dynamic runs incl. documented skips'
  UNION ALL SELECT 'fuzz_runs_skipped', (SELECT count(*) FROM fuzz_runs WHERE skip_reason IS NOT NULL),
         'runs skipped — confirm each skip_reason is honest'
  UNION ALL SELECT 'slices_total', (SELECT count(*) FROM input_slices),
         'planned input slices'
  UNION ALL SELECT 'sources_total', (SELECT count(*) FROM sources),
         'attacker-controllable input vectors'
  UNION ALL SELECT 'sinks_total', (SELECT count(*) FROM sinks),
         'dangerous sink calls'
  UNION ALL SELECT 'guards_on_paths_without_defense_row',
    (SELECT count(*) FROM critical_fn_reach r
     WHERE r.guard_path_json IS NOT NULL AND r.guard_path_json <> '' AND r.guard_path_json <> '[]'
       AND NOT EXISTS (
         SELECT 1 FROM defenses d
         WHERE d.symbol_path <> '' AND r.guard_path_json LIKE '%' || d.symbol_path || '%')),
    'guard on a reach path has no defenses row — Phase 0 defense enumeration under-populated'
  UNION ALL SELECT 'validator_cfs_without_defense_link',
    (SELECT count(*) FROM critical_functions cf
     WHERE cf.cf_category = 'validator_sanitizer' AND cf.defense_id IS NULL),
    'validator/sanitizer critical-fn has no defenses row — defense enumeration gap'
  UNION ALL SELECT 'dangerous_sink_cfs_without_sink_row',
    (SELECT count(*) FROM critical_functions cf
     WHERE cf.cf_category = 'dangerous_sink' AND cf.sink_id IS NULL),
    'dangerous-sink critical-fn has no sinks row — sink enumeration gap'
  UNION ALL SELECT 'executed_steps_without_observation',
    (SELECT count(*) FROM agent_steps st
     WHERE st.status IN ('running','success','exhausted','failed','timed_out')
       AND NOT EXISTS (SELECT 1 FROM agent_observations o WHERE o.agent_step_id = st.id)),
    'executed agent_step with zero agent_observations — context-logging blackout (mirror of v_observation_coverage)'
  UNION ALL SELECT 'defenses_below_validator_cf_floor',
    GREATEST(
      (SELECT count(DISTINCT cf.symbol_path) FROM critical_functions cf
       WHERE cf.cf_category = 'validator_sanitizer')
      - (SELECT count(*) FROM defenses), 0),
    'stored defenses fewer than distinct validator/sanitizer CFs — recon defense under-enumeration floor (shortfall size; >0 = RED)'
  UNION ALL SELECT 'slices_without_codebase_coverage',
    CASE WHEN EXISTS (SELECT 1 FROM input_slices)
          AND NOT EXISTS (SELECT 1 FROM cpg_slice_coverage)
         THEN 1 ELSE 0 END,
    'input_slices exist but no cpg_slice_coverage row — codebase slice-coverage was never measured/saved when slices ended (RED)'
  UNION ALL SELECT 'methodology_blindspots_unpromoted',
    (SELECT count(*) FROM methodology_blind_spots WHERE promoted_to_round_id IS NULL),
    'merged methodology blind-spots not yet carried into a later round as a direction/lane — SIGNAL not auto-red (expected on the latest round); confirm each was considered as a next-round lane'
  -- lanes_stuck_running (v0.30): required DEEP lane steps stuck in status='running'
  -- in the current round — a crashed/OOM HEAVY lane never cleaned up. RED when > 0.
  -- Lane names inlined: v_required_deep_lanes + v_lane_coverage are defined after
  -- v_coverage in schema order, so they cannot be referenced here directly.
  UNION ALL SELECT 'lanes_stuck_running',
    (SELECT count(*) FROM agent_steps st
     JOIN strategies s ON s.id = st.strategy_id
     WHERE st.status = 'running'
       AND s.name IN (
         'preliminary_enumeration_lane','forward_slice_lane','backward_sink_lane',
         'critical_function_dataflow_lane','defense_base_lane',
         'defense_context_verification_lane','isolation_fuzz_lane',
         'html_sanitizer_bypass_lane','concolic_bypass_lane',
         'llm_seed_corpus_lane_a','llm_seed_corpus_lane_b','boundary_fuzz_lane',
         'methodology_blindspot_lane_a','methodology_blindspot_lane_b','report_critic'
       )
       AND (
         (st.round_id IS NULL AND NOT EXISTS (SELECT 1 FROM round_ledger))
         OR st.round_id IS NOT DISTINCT FROM (
           SELECT cr.round_id FROM v_current_round cr
           WHERE cr.target_id = (
             SELECT target_id FROM round_ledger WHERE id = st.round_id LIMIT 1
           )
           LIMIT 1
         )
       )),
    'required DEEP lane steps stuck in status=running in current round — a crashed/OOM lane that was never cleaned up (RED when > 0)'
  -- Fuzz-coverage gates (v0.29, gate fixed v0.30): the DYNAMIC mirror of
  -- slices_without_codebase_coverage. Count-free, no %-floor.
  -- v0.30 fix: NOT LIKE substring → json_extract value-presence (C09-A-F1).
  UNION ALL SELECT 'fuzz_runs_without_coverage_measurement',
    (SELECT count(*) FROM fuzz_runs
     WHERE skip_reason IS NULL
       AND TRY_CAST(json_extract_string(coverage_json, '$.edges')             AS BIGINT) IS NULL
       AND TRY_CAST(json_extract_string(coverage_json, '$.blocks')            AS BIGINT) IS NULL
       AND TRY_CAST(json_extract_string(coverage_json, '$.function_coverage') AS DOUBLE) IS NULL),
    'a fuzz_runs row that RAN (skip_reason IS NULL) records no coverage measurement in coverage_json (none of edges/blocks/function_coverage present as extractable values) — coverage was never measured for an executed fuzz run (RED; count-free, no %-floor)'
  UNION ALL SELECT 'fuzz_skips_unrecorded',
    (SELECT count(*) FROM agent_steps st
     JOIN strategies s ON s.id = st.strategy_id AND s.name = 'boundary_fuzz_lane'
     WHERE st.status IN ('success','exhausted','failed','timed_out','skipped')
       AND NOT EXISTS (SELECT 1 FROM fuzz_runs fr WHERE fr.agent_step_id = st.id)),
    'a boundary_fuzz_lane step that ran or was documented-skipped but emitted NO fuzz_runs row — Phase 1.5 mandatory-attempt accounting gap (RED): every run incl. a skip must record a fuzz_runs row'
) t
ORDER BY metric;

------------------------------------------------------------
-- Schema version row.
------------------------------------------------------------
INSERT INTO schema_version (version, description)
VALUES (23, 'audit hardening (v0.30.0): (1) v_current_round helper view + round-scoped v_lane_coverage + v_observation_coverage — gates evaluate only the CURRENT round so round 2+ cannot be permanently satisfied by round 1 work; (2) lanes_stuck_running gate in v_lane_coverage + v_coverage — a lane stuck in status=running (OOM/crash) surfaces as explicit failure, not ok; (3) confirmed_without_refutation gate in v_coverage — mirrors confirmed_without_critic, enforcing the refute-before-confirm mandate mechanically; (4) fuzz_runs_without_coverage_measurement fixed to use json_extract value-presence instead of gameable NOT LIKE substring; (5) v_phase_status phase1_4_seed row + phase vocab unified to phase0_75_prebreak across v_phase_status/v_required_deep_lanes/v_observation_coverage')
ON CONFLICT DO NOTHING;
