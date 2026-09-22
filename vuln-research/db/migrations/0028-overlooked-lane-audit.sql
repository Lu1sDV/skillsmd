-- vuln-research migration 0028 — overlooked-lane self-audit meta-lane
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: a NEW DEEP-only MANDATORY meta-lane, overlooked_lane_audit_lane, runs LAST — after
-- Phase 1.6 (methodology_blind_spots) has flushed — and self-questions whether the run left
-- high-yield lanes on the table. Two self-questions:
--   (a) GENERATIVE — are there MORE high-yield lanes we never considered?
--   (b) AUDIT — did we ERRONEOUSLY IGNORE a lane that should have spawned (a skipped/unpromoted
--       lane whose documented skip reason no longer holds)?
-- Detection is a DB-GROUNDED TRIPLE REFERENCE (SQL diffs, not free-form intuition):
--   (1) strategies / roster (v_required_deep_lanes) vs the covering agent_steps;
--   (2) emitted-but-unpromoted promising_lanes (v_promising_lanes_ranked open_direction);
--   (3) v_coverage / enumeration uncovered signals (+ optional open methodology_blind_spots).
-- The lane ALWAYS emits a promising_lanes row per confirmed overlooked/ignored lane, then
-- cap-gated SPAWNS the top-N-by-promise IN-RUN up to cap = the existing promising_lanes row_cap
-- (db/seed/fetch-budgets.yml) × tier multiplier — NO new magic constant. Overflow beyond the cap
-- FEEDS FORWARD (the standard promising_lanes feed-forward path); acting on a lead stamps
-- promoted_to_round_id. The in-run spawn is the deliberate, bounded exception to the otherwise
-- feed-forward-only promising_lanes doctrine.
--
-- NO DDL: this lane REUSES promising_lanes (0025), agent_steps, strategies, v_coverage,
-- v_required_deep_lanes — it needs NO new table or column. Its only DB footprint is one strategy
-- seed row (id 26) + one v_required_deep_lanes roster row + one v_phase_status phase row, exactly
-- the view-only / seed-only shape of migration 0018's roster additions.
--
-- ORDERING: applies AFTER 0026 (which added prior_art_intake_lane to v_required_deep_lanes and the
-- phase_l1_prior_art row to v_phase_status). Both views are restated IN FULL here carrying the
-- 0026 rows forward plus the new self-audit rows. CREATE OR REPLACE VIEW is idempotent + FK-free.
-- db/schema.sql carries the identical definitions (schema_mirror parity).

------------------------------------------------------------
-- (1) overlooked_lane_audit_lane strategy (id 26). DEEP-only MANDATORY meta-lane.
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (26, 'overlooked_lane_audit_lane', 'DEEP-only MANDATORY meta-lane, runs LAST after Phase 1.6 methodology_blind_spots has flushed. Two self-questions: (a) GENERATIVE — are there MORE high-yield lanes never considered? (b) AUDIT — did we ERRONEOUSLY IGNORE a lane that should have spawned (a skipped/unpromoted lane whose documented skip reason no longer holds)? Detection is a DB-GROUNDED TRIPLE REFERENCE (SQL diffs, not free-form): (1) strategies/roster (v_required_deep_lanes) vs covering agent_steps; (2) emitted-but-unpromoted promising_lanes (v_promising_lanes_ranked open_direction); (3) v_coverage/enumeration uncovered signals (+ optional open methodology_blind_spots). ALWAYS emits a promising_lanes row per confirmed overlooked/ignored lane; then cap-gated SPAWNS the top-N-by-promise IN-RUN up to cap = the promising_lanes row_cap (db/seed/fetch-budgets.yml) × tier multiplier (NO magic constant); overflow FEEDS FORWARD; acting stamps promoted_to_round_id. The in-run spawn is the bounded exception to the feed-forward-only promising_lanes doctrine. See references/methodology/overlooked-lane-audit-lane.md.', 1)
ON CONFLICT (name) DO UPDATE SET description = excluded.description, version = excluded.version;

------------------------------------------------------------
-- (2) v_required_deep_lanes — append overlooked_lane_audit_lane under the NEW phase
-- 'phase1_7_self_audit' (after phase1_6_blindspot). Full body restated carrying the 0026
-- prior_art_intake_lane row.
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
  ('overlooked_lane_audit_lane',        'phase1_7_self_audit'), -- migration 0028 (C2; runs after phase1_6_blindspot)
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

------------------------------------------------------------
-- (3) v_phase_status — restate; add the phase1_7_self_audit row (rows_populated = count of
-- EXECUTED overlooked_lane_audit_lane agent_steps — the lane has no own table, it reuses
-- promising_lanes) at phase_seq 6.5 so it sorts between phase1_6_blindspot (6) and
-- phase2_confirm (7). Carries the 0026 phase_l1_prior_art row at phase_seq -1.
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
  UNION ALL SELECT 6.5, 'phase1_7_self_audit',
         (SELECT count(*) FROM agent_steps st
          JOIN strategies s ON s.id = st.strategy_id AND s.name = 'overlooked_lane_audit_lane'
          WHERE st.status IN ('success','exhausted'))
  UNION ALL SELECT 7, 'phase2_confirm',
         (SELECT count(*) FROM refutations)
  UNION ALL SELECT 8, 'phase4_proof',
         (SELECT count(*) FROM audit_outcomes)
  UNION ALL SELECT 9, 'phase5_report',
         (SELECT count(*) FROM critic_findings)
) t
ORDER BY phase_seq;

INSERT INTO schema_version (version, description)
VALUES (28, 'overlooked-lane self-audit (v0.39.0): NEW DEEP-only MANDATORY meta-lane overlooked_lane_audit_lane (strategy 26) runs LAST after Phase 1.6. NO DDL — reuses promising_lanes/agent_steps/strategies/v_coverage/v_required_deep_lanes. Two self-questions (generative "more high-yield lanes?" + audit "erroneously ignored a lane?") answered via a DB-grounded TRIPLE REFERENCE (roster-vs-agent_steps diff; emitted-but-unpromoted promising_lanes; v_coverage/enumeration signals + optional open methodology_blind_spots). ALWAYS emits a promising_lanes row per confirmed overlooked/ignored lane; cap-gated SPAWNS top-N-by-promise IN-RUN up to cap = the existing fetch-budgets.yml promising_lanes row_cap × tier multiplier (NO new constant); overflow feeds forward; acting stamps promoted_to_round_id (the in-run spawn is the bounded exception to feed-forward-only). Appended to v_required_deep_lanes under NEW phase phase1_7_self_audit; v_phase_status gains the phase1_7_self_audit row (rows_populated = executed overlooked_lane_audit_lane steps) at phase_seq 6.5 (between blindspot and confirm).')
ON CONFLICT DO NOTHING;
