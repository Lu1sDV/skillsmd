-- vuln-research migration 0014 — preliminary-inventory completeness
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: closes the progressive-disclosure gap where the Phase-0 preliminary
-- inventories (sources / sinks / defenses / critical_functions) can be silently
-- UNDER-populated — a finding-led sweep records only what a smell pointed at,
-- never the complete in-scope set. Two coordinated changes:
--
--   (1) Three COUNT-FREE contradiction signals added to v_coverage. Each detects
--       under-population by CONTRADICTION — a row that already exists and PROVES a
--       missing inventory entry must also exist. No magic-constant floor, no
--       expected-count threshold: > 0 => a real enumeration gap. They reuse the
--       verified schema facts (cf_category includes 'validator_sanitizer' and
--       'dangerous_sink'; critical_functions has sink_id + defense_id;
--       critical_fn_reach.guard_path_json exists).
--
--   (2) A new mandatory DEEP lane `preliminary_enumeration_lane` (strategy id 15 —
--       next free after 1..14) gated at phase0_decompose in v_required_deep_lanes.
--       Finding-agnostic whole-tree sweep that populates the inventories COMPLETELY
--       before any finding is chased, and records what it swept in coverage_json so
--       the contradiction signals above have a denominator.
--
-- OUTPUT REUSES EXISTING TABLES (no new table): the lane writes sources / sinks /
-- defenses / critical_functions rows (existing) and its sweep accounting into the
-- existing agent_steps.coverage_json. The three signals are pure read-time views.
--
-- ORDERING: critical_functions, critical_fn_reach, defenses, sinks, strategies are
-- created by 0001/0002; v_coverage by 0006; v_required_deep_lanes by 0007. All
-- resolve cleanly when this is applied last. CREATE OR REPLACE VIEW is idempotent +
-- FK-free (DuckDB replaces the whole view body). db/schema.sql carries identical
-- defs for fresh DBs.

------------------------------------------------------------
-- v_coverage — add three count-free completeness contradiction signals (v0.20)
-- as new UNION ALL branches before the closing `) t`. DuckDB replaces the whole
-- view, so the full body is restated here. db/schema.sql carries the identical body.
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
) t
ORDER BY metric;

------------------------------------------------------------
-- Strategy registration (id 15 — next free after the 1..14 block).
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (15, 'preliminary_enumeration_lane',     'Phase 0 (Decompose) exhaustive, finding-agnostic enumeration lane. Whole-tree sweep that populates sources, sinks, defenses, and critical_functions COMPLETELY before any finding is chased — every attacker-controllable input, every dangerous callee, every sanitizer/blacklist/allowlist callsite, every security-critical function — recorded because it exists in scope, never because a smell led to it. Records what it swept in coverage_json (files_swept, patterns_run, semgrep_callsites_seen, sources_found/sinks_found/defenses_found counts) so the v_coverage completeness contradiction signals (guards_on_paths_without_defense_row, validator_cfs_without_defense_link, dangerous_sink_cfs_without_sink_row) have a denominator. Ranking (v_critical_fn_ranked, phase0_priorities) orders this complete set; it never narrows what is enumerated.', 1)
ON CONFLICT (name) DO NOTHING;

------------------------------------------------------------
-- DEEP gate roster — add preliminary_enumeration_lane to the mandatory roster at
-- phase0_decompose. CREATE OR REPLACE VIEW is idempotent + FK-free. db/schema.sql
-- carries the identical 13-row definition.
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
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

INSERT INTO schema_version (version, description)
VALUES (14, 'preliminary-inventory completeness: v_coverage contradiction signals (guards/validator/dangerous-sink) + preliminary_enumeration_lane strategy 15 at phase0_decompose in v_required_deep_lanes')
ON CONFLICT DO NOTHING;
