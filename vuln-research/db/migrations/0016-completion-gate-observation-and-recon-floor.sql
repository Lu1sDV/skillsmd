-- vuln-research migration 0016 — completion-gate context + recon-floor signals
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: closes two completion-gate blind spots that recurred as manual user
-- interventions:
--
--   (1) PER-PHASE OBSERVATION persistence. A phase can execute real work (>=1
--       executed agent_step) yet persist ZERO agent_observations — the "save
--       context into the DB" layer is skipped, so the round's hypotheses /
--       dead-ends / invariants are lost and later rounds re-walk them.
--       v_phase_status only sees a phase's own output tables; it cannot see a
--       context-logging blackout. Two coordinated read-time signals:
--         * v_observation_coverage (NEW VIEW) — per-phase gate. Phase is derived
--           the same way the DEEP gate derives it (agent_steps -> strategies ->
--           v_required_deep_lanes). gate_status NO_OBSERVATION = HARD RED.
--         * v_coverage metric 'executed_steps_without_observation' — step-level
--           mirror of the same blackout (append-only UNION branch).
--
--   (2) RECON DEFENSE UNDER-ENUMERATION FLOOR. Every distinct validator/sanitizer
--       critical_function IS a defense callsite, so the stored defenses inventory
--       can never legitimately be SMALLER than the count of distinct
--       validator/sanitizer CFs. v_coverage metric 'defenses_below_validator_cf_floor'
--       = GREATEST(distinct_validator_cfs - defenses_total, 0) is that shortfall.
--       Conservative absolute floor; DISTINCT from the 0014 linkage signals
--       (validator_cfs_without_defense_link etc.), which fire on UNLINKED defenses
--       — this fires on absolute under-count even when every stored defense is
--       fully linked. Uses THIS tree's cf_category enum value 'validator_sanitizer'
--       (verified against db/schema.sql critical_functions CHECK).
--
-- OUTPUT REUSES EXISTING TABLES (no new table): all three signals are pure
-- read-time views over agent_steps / agent_observations / critical_functions /
-- defenses (all created earlier: 0001/0002). v_coverage created by 0006;
-- v_required_deep_lanes by 0007 (last widened by 0014). CREATE OR REPLACE VIEW is
-- idempotent + FK-free (DuckDB replaces the whole view body). db/schema.sql carries
-- byte-identical defs for the fresh-DB path.
--
-- ORDERING: this migration touches no table DDL, no CHECK, no lane roster — only
-- two CREATE OR REPLACE VIEWs. Applied last in lexical order it resolves cleanly.

------------------------------------------------------------
-- v_coverage — append two new UNION ALL branches before the closing `) t`.
-- DuckDB replaces the whole view, so the full body is restated here. The branches
-- already present (through dangerous_sink_cfs_without_sink_row) are UNCHANGED;
-- db/schema.sql carries the identical body.
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
  -- Completeness contradiction signals (v0.20): detect UNDER-population of the
  -- Phase-0 inventories by contradiction — rows that prove a missing inventory
  -- entry must exist. Count-free, no magic-constant floor. > 0 => enumeration gap.
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
  -- Context-persistence + recon-floor signals (v0.23).
  -- (a) executed_steps_without_observation: step-level mirror of
  --     v_observation_coverage. Count of EXECUTED agent_steps
  --     (running/success/exhausted/failed/timed_out) that hung ZERO
  --     agent_observations — the per-step view of a context-logging blackout. >0 =>
  --     at least one step ran but saved no context into the DB.
  UNION ALL SELECT 'executed_steps_without_observation',
    (SELECT count(*) FROM agent_steps st
     WHERE st.status IN ('running','success','exhausted','failed','timed_out')
       AND NOT EXISTS (SELECT 1 FROM agent_observations o WHERE o.agent_step_id = st.id)),
    'executed agent_step with zero agent_observations — context-logging blackout (mirror of v_observation_coverage)'
  -- (b) defenses_below_validator_cf_floor: recon UNDER-ENUMERATION floor. Every
  --     distinct validator/sanitizer critical_function IS a defense callsite, so the
  --     stored defenses inventory can never legitimately be SMALLER than the count of
  --     distinct validator/sanitizer CFs. GREATEST(distinct_validator_cfs -
  --     defenses_total, 0) is the shortfall size; >0 => wholesale defense
  --     under-storage. Conservative absolute floor — distinct from the 0014 linkage
  --     signals (validator_cfs_without_defense_link etc.), which fire on UNLINKED
  --     defenses; THIS fires on absolute under-count even when every stored defense
  --     is fully linked.
  UNION ALL SELECT 'defenses_below_validator_cf_floor',
    GREATEST(
      (SELECT count(DISTINCT cf.symbol_path) FROM critical_functions cf
       WHERE cf.cf_category = 'validator_sanitizer')
      - (SELECT count(*) FROM defenses), 0),
    'stored defenses fewer than distinct validator/sanitizer CFs — recon defense under-enumeration floor (shortfall size; >0 = RED)'
) t
ORDER BY metric;

------------------------------------------------------------
-- v_observation_coverage (v0.23) — per-phase context-persistence gate. NEW VIEW.
-- gate_status NO_OBSERVATION (executed_steps > 0 AND observations_total = 0) is a
-- HARD RED: a phase ran but logged no context. Phase is derived via
-- agent_steps -> strategies -> v_required_deep_lanes (the DEEP roster IS the phase
-- map). Read-time, FK-free, idempotent. db/schema.sql carries the identical body.
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

INSERT INTO schema_version (version, description)
VALUES (16, 'completion-gate context + recon-floor signals: v_observation_coverage per-phase view + v_coverage metrics executed_steps_without_observation and defenses_below_validator_cf_floor')
ON CONFLICT DO NOTHING;
