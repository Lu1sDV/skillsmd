-- vuln-research migration 0022 — fuzz-coverage aim & tracking (v0.29.0)
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: make MAX code coverage a first-class, MEASURED, ENFORCED objective for the
-- Phase-1.5 boundary fuzz lane — closing the asymmetry where the STATIC slice-coverage
-- side had a count-free hard gate (v_coverage.slices_without_codebase_coverage) but the
-- DYNAMIC fuzz side had none. Three additive pieces, NO new table, NO new mandatory lane:
--   (1) v_coverage += two gates (the dynamic mirror of slices_without_codebase_coverage):
--         • fuzz_runs_without_coverage_measurement — a fuzz_runs row that RAN (skip_reason
--           IS NULL) but whose coverage_json records NO coverage signal (none of
--           edges/blocks/function_coverage) => coverage was never measured (RED).
--         • fuzz_skips_unrecorded — a boundary_fuzz_lane agent_step that ran or was
--           documented-skipped but emitted NO fuzz_runs row => Phase-1.5 mandatory-attempt
--           accounting gap (RED). (This is the signal already DOCUMENTED in
--           db-logging-and-context.md §12 but previously absent from the view — drift fixed.)
--       Both are count-free EXISTS/COUNT signals with NO percentage floor: engine coverage
--       is selective by design, so a low % is INSPECTED via v_fuzz_coverage, never auto-failed
--       (the cpg_slice_coverage precedent).
--   (2) v_fuzz_coverage — NEW read-time view, the dynamic analogue of v_cpg_slice_coverage:
--       one row per EXECUTED fuzz_runs row, with edges/function_coverage_pct/functions_covered/
--       uncovered_frontier_n EXTRACTED read-time from coverage_json (json_extract — never a
--       stored/duplicated column). Ordering by (target_id, round_id, entry_point) makes the
--       round-over-round coverage trend directly queryable.
--   (3) the §8 fuzzing-lane coverage contract (prose, in references/v2/fuzzing-lane.md)
--       promotes a coverage measurement + uncovered_frontier[] to REQUIRED on a ran row and
--       adds a plateau+escalation-exhausted saturation criterion. (Doc-only; no DDL here.)
--
-- ORDERING: fuzz_runs (0003), agent_steps + strategies (0001), and all tables referenced by
-- the restated v_coverage body (gr_findings, defenses, defense_bypasses, critical_fn_reach,
-- critical_functions, agent_observations, input_slices, cpg_slice_coverage,
-- methodology_blind_spots, sources, sinks) are created by earlier migrations, so this applies
-- cleanly last. v_coverage was created by 0006 and last widened by 0018; CREATE OR REPLACE
-- VIEW is idempotent + FK-free (DuckDB replaces the whole view body), so the full body is
-- restated here (branches through methodology_blindspots_unpromoted are UNCHANGED from 0018;
-- only the two fuzz_* branches are appended). db/schema.sql carries identical definitions for
-- the fresh-DB path; the schema-mirror + migration-chain tests guard the two against drift.

------------------------------------------------------------
-- (1) v_coverage — append the two fuzz-coverage branches. Full body restated (DuckDB
-- replaces the whole view); branches through methodology_blindspots_unpromoted are
-- byte-identical to 0018 / db/schema.sql.
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
  -- Fuzz-coverage gates (v0.29): the DYNAMIC mirror of slices_without_codebase_coverage.
  -- Both are count-free and carry NO %-floor (engine coverage is selective by design — a
  -- low % is inspected via v_fuzz_coverage, never auto-failed). They enforce only that
  -- (1) every EXECUTED fuzz run actually MEASURED coverage, and (2) every executed/skipped
  -- boundary_fuzz_lane step is ACCOUNTED by a fuzz_runs row (mandatory-attempt discipline).
  UNION ALL SELECT 'fuzz_runs_without_coverage_measurement',
    (SELECT count(*) FROM fuzz_runs
     WHERE skip_reason IS NULL
       AND (coverage_json IS NULL
            OR (coverage_json NOT LIKE '%edges%'
                AND coverage_json NOT LIKE '%blocks%'
                AND coverage_json NOT LIKE '%function_coverage%'))),
    'a fuzz_runs row that RAN (skip_reason IS NULL) records no coverage measurement in coverage_json (none of edges/blocks/function_coverage) — coverage was never measured for an executed fuzz run (RED; the dynamic mirror of slices_without_codebase_coverage — count-free, no %-floor)'
  UNION ALL SELECT 'fuzz_skips_unrecorded',
    (SELECT count(*) FROM agent_steps st
     JOIN strategies s ON s.id = st.strategy_id AND s.name = 'boundary_fuzz_lane'
     WHERE st.status IN ('success','exhausted','failed','timed_out','skipped')
       AND NOT EXISTS (SELECT 1 FROM fuzz_runs fr WHERE fr.agent_step_id = st.id)),
    'a boundary_fuzz_lane step that ran or was documented-skipped but emitted NO fuzz_runs row — Phase 1.5 mandatory-attempt accounting gap (RED): every run incl. a skip must record a fuzz_runs row'
) t
ORDER BY metric;

------------------------------------------------------------
-- (2) v_fuzz_coverage (v22) — read-time per-run fuzz code-coverage rollup, the DYNAMIC
-- analogue of v_cpg_slice_coverage. Identical to db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_fuzz_coverage AS
SELECT
  fr.target_id,
  fr.round_id,
  fr.entry_point,
  fr.engine,
  fr.reused_existing_pipeline,
  TRY_CAST(json_extract_string(fr.coverage_json, '$.edges')  AS BIGINT) AS edges,
  TRY_CAST(json_extract_string(fr.coverage_json, '$.blocks') AS BIGINT) AS blocks,
  TRY_CAST(json_extract_string(fr.coverage_json, '$.function_coverage_pct') AS DOUBLE) AS function_coverage_pct,
  TRY_CAST(json_extract_string(fr.coverage_json, '$.functions_covered')     AS BIGINT) AS functions_covered,
  json_array_length(json_extract(fr.coverage_json, '$.uncovered_frontier')) AS uncovered_frontier_n,
  json_extract_string(fr.coverage_json, '$.seed_source') AS seed_source,
  json_extract_string(fr.coverage_json, '$.hybrid_mode') AS hybrid_mode,
  TRY_CAST(json_extract_string(fr.coverage_json, '$.runtime_s') AS BIGINT) AS runtime_s,
  fr.crash_count,
  fr.created_at
FROM fuzz_runs fr
WHERE fr.skip_reason IS NULL
ORDER BY fr.target_id, fr.round_id, fr.entry_point;

INSERT INTO schema_version (version, description)
VALUES (22, 'fuzz-coverage aim & tracking (v0.29.0): v_coverage gates fuzz_runs_without_coverage_measurement (a ran fuzz_runs row whose coverage_json records no edges/blocks/function_coverage — the dynamic mirror of slices_without_codebase_coverage) and fuzz_skips_unrecorded (a boundary_fuzz_lane step that ran or was documented-skipped but emitted no fuzz_runs row) + v_fuzz_coverage read-time per-run code-coverage rollup (edges/function_coverage_pct/uncovered-frontier extracted from coverage_json across round_id, never stored) + fuzzing-lane §8 promotes a coverage measurement and uncovered_frontier[] to REQUIRED on a ran row, with a plateau+escalation-exhausted saturation criterion (no magic %-floor, mirroring cpg_slice_coverage)')
ON CONFLICT DO NOTHING;
