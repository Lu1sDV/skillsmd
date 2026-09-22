-- vuln-research migration 0006 — coverage views
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: two read-only inspection views the orchestrator consults before it is
-- allowed to declare a DEEP audit complete. NO table change, NO breaking change
-- to any prior schema — purely additive CREATE OR REPLACE VIEW statements.
--   v_phase_status : one row per pipeline phase + how many rows it produced +
--                    whether it ran at all (the DEEP completion gate refuses
--                    "done" while a phase that should have fired is empty).
--   v_coverage     : named gap-finder metrics (target_id drift, unconfirmed
--                    findings, defenses with no bypass attempt, fuzz skips, …).
--                    Signals, not hard failures — but the orchestrator MUST look.
--
-- ORDERING: every referenced table (sources/sinks/defenses/critical_functions/
-- input_slices/critical_fn_reach/defense_bypasses/gr_findings/fuzz_runs/
-- refutations/audit_outcomes/critic_findings) is created by migrations 0001–0005,
-- so these views resolve cleanly when applied last. Views use CREATE OR REPLACE
-- so re-apply is clean. db/schema.sql carries the identical definitions for fresh DBs.

------------------------------------------------------------
-- v_phase_status (v0.14): one row per pipeline phase with how many rows it has
-- produced and whether it ran at all. The orchestrator's DEEP completion gate
-- reads this to refuse "done" while a phase that should have fired is empty.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_phase_status AS
SELECT phase_seq, phase, rows_populated, (rows_populated > 0) AS ran
FROM (
  SELECT 0 AS phase_seq, 'phase0_decompose' AS phase,
         (SELECT count(*) FROM sources) + (SELECT count(*) FROM sinks)
       + (SELECT count(*) FROM defenses) + (SELECT count(*) FROM critical_functions) AS rows_populated
  UNION ALL SELECT 1, 'phase0_5_plan',
         (SELECT count(*) FROM input_slices) + (SELECT count(*) FROM critical_fn_reach)
  UNION ALL SELECT 2, 'phase0_75_prebreak_and_recheck',
         (SELECT count(*) FROM defense_bypasses)
  UNION ALL SELECT 3, 'phase1_hunt',
         (SELECT count(*) FROM gr_findings)
  UNION ALL SELECT 4, 'phase1_5_fuzz',
         (SELECT count(*) FROM fuzz_runs)
  UNION ALL SELECT 5, 'phase2_confirm',
         (SELECT count(*) FROM refutations)
  UNION ALL SELECT 6, 'phase4_proof',
         (SELECT count(*) FROM audit_outcomes)
  UNION ALL SELECT 7, 'phase5_report',
         (SELECT count(*) FROM critic_findings)
) t
ORDER BY phase_seq;

------------------------------------------------------------
-- v_coverage (v0.14): gap finder. Each row is a named coverage metric the
-- orchestrator inspects before declaring a DEEP audit complete. `note` explains
-- how to read an anomalous value. Signals, not hard failures — but the
-- orchestrator MUST look.
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
) t
ORDER BY metric;

INSERT INTO schema_version (version, description) VALUES (6, 'coverage views: v_phase_status + v_coverage') ON CONFLICT DO NOTHING;
