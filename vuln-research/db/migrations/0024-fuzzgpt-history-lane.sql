-- vuln-research migration 0024 — FuzzGPT history-driven lane (v0.36.0)
--
-- Forward-only, idempotent. Safe to re-apply (INSERT … ON CONFLICT DO NOTHING +
-- CREATE OR REPLACE VIEW throughout).
--
-- SCOPE: registers a NEW first-class, DEEP-mandatory Phase-1.4 lane —
-- `fuzzgpt_history_lane` (strategy id 24) — history-driven LLM fuzzing (FuzzGPT,
-- Deng et al., arXiv:2304.02014). It COEXISTS with the dual `llm_seed_corpus_lane_a/b`
-- (ids 12/13, migration 0011) — it does NOT replace them. Distinct technique:
-- instead of synthesizing seeds from input-format families, it mines the TARGET's
-- own historical bug-triggering code (gh issues/PRs/commits), auto-labels each
-- snippet's buggy "fuzz target" (the unit generation is steered toward — API /
-- compiler flag / SQL feature / syscall / opcode / protocol field; NOT a libFuzzer
-- harness), then generates unusual edge-case programs via few-shot CoT / zero-shot /
-- retrieval (RT) generation.
--
-- TWO MODES:
--   (1) GENERATOR (default) — emits edge-case programs as
--       fuzz_artifacts(artifact_kind='seed_initial') that feed boundary_fuzz_lane
--       (Phase 1.5) + the existing crash/sanitizer oracles + five-gate Confirm.
--       NO schema change is required on this path: seed_initial is already a
--       canonical artifact_kind (migration 0008), exactly like the dual seed lanes.
--   (2) DIFFERENTIAL ORACLE (in-lane sub-mode, TARGET-AGNOSTIC — NOT DL-specific) —
--       compares any pair of supposedly-equivalent execution contexts (impl A vs B,
--       version N vs N+1, optimization level, config flag, reference implementation).
--       A divergence is a candidate finding but is QUARANTINED (see below).
--
-- DIFFERENTIAL QUARANTINE — the "N/A" classification (decision 3):
--   A differential divergence is recorded as a gr_findings row with
--     finding_kind        = 'differential_divergence'   (open free-TEXT vocab, alongside
--                                                         fuzz_crash / fuzz_divergence)
--     severity            = NULL                         (the "N/A" classification)
--     confirmation_status = 'unconfirmed'                (the quarantine status)
--   It therefore stays OUT of the HIGH/MED/LOW severity rankings, the confirmed_vulns
--   view, and the findings_candidate_open / confirmed_* gates until triage shows a
--   security-impact path. Promotion moves it to 'candidate' and into the standard
--   five-gate Confirm (references/v2/confirmation-rigor-doctrine.md), reusing the
--   existing exploitability gate — no new confirm path is built.
--
-- WHERE THE "N/A" VALUE LIVES (per the CHECK-enum-vs-free-TEXT doctrine at the top of
-- db/schema.sql):
--   * severity is the SECURITY-rating vocabulary and is deliberately CLOSED — it feeds
--     the ranking/report views — so it stays {LOW,MEDIUM,HIGH,CRITICAL} and is NOT
--     widened with an "N/A" member. The "N/A" classification is instead the DOCUMENTED
--     FREE-TEXT/NULL state: finding_kind='differential_divergence' (open vocab) with
--     severity = NULL. severity becomes a real rating only when triage promotes the
--     finding and Confirm/Proof assigns one. NO new severity enum value is introduced.
--   * confirmation_status IS a closed, low-cardinality vocabulary (the doctrine's
--     CHECK-enum criterion), so 'unconfirmed' is added as a fourth enum member:
--     {candidate, confirmed, refuted, unconfirmed}.
--
-- CHECK-DIVERGENCE NOTE (mirrors the 0019 / 0009 precedent — read those blocks first):
-- adding 'unconfirmed' WIDENS the EXISTING inline CHECK on gr_findings.confirmation_status
-- (3-way -> 4-way). DuckDB cannot ALTER / ADD / DROP a CHECK after the fact, and there is
-- no FK-safe DROP+CREATE for gr_findings on the upgrade path. So there is NO DDL the
-- upgrade path can run to widen the constraint. The canonical fresh-DB path in
-- db/schema.sql carries the widened 4-way CHECK directly (CREATE TABLE IF NOT EXISTS),
-- and the Go harness applies that canonical schema idempotently on Open — every real
-- audit DB is created fresh from db/schema.sql, so it gets the widened CHECK. On a
-- pre-0024 DB upgraded in place (rather than recreated), the old 3-way CHECK persists;
-- the 'unconfirmed' status is therefore enforced/admitted app-side on that upgrade path,
-- exactly as 0019 documents for logic_guard and 0009 for the sanitizer categoricals.
-- This migration inserts NO 'unconfirmed' row itself, so it never trips a legacy CHECK.
--
-- ROSTER: `fuzzgpt_history_lane` is added to v_required_deep_lanes as a mandatory DEEP
-- lane at phase token 'phase1_4_seed' (beside llm_seed_corpus_lane_a/b). Mandatory-attempt
-- discipline mirrors boundary_fuzz_lane: it must be attempted; "skipped — no minable bug
-- history" (e.g. a fresh closed-source binary with no issue tracker) is a legitimate
-- documented-skip end state (agent_steps.status='skipped' + non-empty termination_reason).
--
-- V_COVERAGE: the lanes_stuck_running metric inlines its required-lane list (because
-- v_required_deep_lanes is defined AFTER v_coverage in schema order and cannot be
-- referenced there). That inlined list gains 'fuzzgpt_history_lane' so a stuck
-- (OOM/crash) fuzzgpt step surfaces as RED, consistent with every other required lane.
--
-- ORDERING: strategies + gr_findings are created by 0001; v_required_deep_lanes by 0007
-- (extended 0011/0013/0023); v_coverage by 0006 (replaced 0016/0022/0023); fuzz_artifacts
-- by 0008. The CREATE OR REPLACE VIEW statements below depend only on already-created
-- tables/views and are FK-free + idempotent. db/schema.sql carries the identical defs for
-- fresh DBs (incl. the widened confirmation_status CHECK + the gr_findings doctrine comments).

------------------------------------------------------------
-- Strategy registration (id 24 — next free after the 1..23 block). Free-TEXT
-- strategies.name (no CHECK since v0.14), so a plain INSERT … ON CONFLICT is safe.
-- Coexists with llm_seed_corpus_lane_a/b; generator mode feeds boundary_fuzz_lane.
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (24, 'fuzzgpt_history_lane',              'Phase 1.4 (DEEP) history-driven LLM fuzzing lane (FuzzGPT, Deng et al., arXiv:2304.02014; coexists with — does NOT replace — the dual llm_seed_corpus_lane_a/b). Mines the target''s own historical bug-triggering code (gh issues/PRs/commits), auto-labels each snippet''s buggy "fuzz target" (the unit generation is steered toward — API / compiler flag / SQL feature / syscall / opcode / protocol field; NOT a libFuzzer harness), then generates unusual edge-case programs via few-shot CoT / zero-shot / retrieval (RT) generation. Two modes: (1) GENERATOR (default) emits edge-case programs as fuzz_artifacts(artifact_kind=''seed_initial'') that feed boundary_fuzz_lane (Phase 1.5) + the existing crash/sanitizer oracles + five-gate Confirm; no schema change on this path. (2) DIFFERENTIAL ORACLE (in-lane sub-mode, target-agnostic — NOT DL-specific) compares any pair of supposedly-equivalent execution contexts (impl A vs B, version N vs N+1, optimization level, config flag, reference implementation); a divergence is QUARANTINED as gr_findings(finding_kind=''differential_divergence'', severity=NULL, confirmation_status=''unconfirmed'') — the N/A classification — and stays OUT of the HIGH/MED/LOW severity rankings until triage shows a security-impact path that promotes it to ''candidate'' (reusing the existing exploitability gate / five-gate Confirm). Mandatory-attempt at DEEP: "skipped — no minable bug history" (e.g. a fresh closed-source binary) is a legitimate documented-skip end state. See references/v2/fuzzgpt-history-lane.md + references/methodology/fuzzgpt-history-driven-lane.md + references/fuzzgpt/ + engines/fuzzgpt-retrieval/.', 1)
ON CONFLICT (name) DO UPDATE SET
  description = excluded.description,
  version = excluded.version,
  updated_at = now();

------------------------------------------------------------
-- DEEP gate roster — add `fuzzgpt_history_lane` as a mandatory DEEP lane at
-- phase token 'phase1_4_seed' (beside the dual seed-corpus lanes, before
-- phase1_5_fuzz consumes the merged corpus). CREATE OR REPLACE VIEW is idempotent +
-- FK-free. db/schema.sql carries the identical 16-row definition. Body is the 0023
-- roster + the one new row.
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
  ('fuzzgpt_history_lane',              'phase1_4_seed'),       -- migration 0024 (history-driven LLM fuzzing; coexists with the dual seed-corpus lanes)
  ('boundary_fuzz_lane',                'phase1_5_fuzz'),
  ('methodology_blindspot_lane_a',      'phase1_6_blindspot'),
  ('methodology_blindspot_lane_b',      'phase1_6_blindspot'),
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

------------------------------------------------------------
-- v_coverage — full body restated (DuckDB replaces the whole view; FK-free + idempotent).
-- Change vs 0023: the lanes_stuck_running metric's INLINED required-lane list gains
-- 'fuzzgpt_history_lane' (v_required_deep_lanes is defined after v_coverage in schema
-- order, so the list cannot be referenced; it is inlined). All other branches are
-- byte-identical to 0023 / db/schema.sql.
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
  -- v0.36 (migration 0024): list += 'fuzzgpt_history_lane'.
  UNION ALL SELECT 'lanes_stuck_running',
    (SELECT count(*) FROM agent_steps st
     JOIN strategies s ON s.id = st.strategy_id
     WHERE st.status = 'running'
       AND s.name IN (
         'preliminary_enumeration_lane','forward_slice_lane','backward_sink_lane',
         'critical_function_dataflow_lane','defense_base_lane',
         'defense_context_verification_lane','isolation_fuzz_lane',
         'html_sanitizer_bypass_lane','concolic_bypass_lane',
         'llm_seed_corpus_lane_a','llm_seed_corpus_lane_b','fuzzgpt_history_lane','boundary_fuzz_lane',
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
VALUES (24, 'FuzzGPT history-driven lane (v0.36.0): new MANDATORY DEEP strategy fuzzgpt_history_lane (id 24) at phase1_4_seed in v_required_deep_lanes — history-driven LLM fuzzing (FuzzGPT, Deng et al., arXiv:2304.02014) that COEXISTS with the dual llm_seed_corpus_lane_a/b (does not replace them). Generator mode emits fuzz_artifacts(seed_initial) feeding boundary_fuzz_lane; a target-agnostic differential-oracle sub-mode emits QUARANTINED gr_findings(finding_kind=''differential_divergence'', severity NULL, confirmation_status=''unconfirmed'') kept OUT of the HIGH/MED/LOW severity rankings until triage promotes them to ''candidate''. confirmation_status CHECK widened to add ''unconfirmed'' (closed-vocab enum member; canonical fresh-DB schema carries the 4-value CHECK; DuckDB cannot widen the inline CHECK on the upgrade path so the migration enforces it app-side per the 0019 precedent and inserts no unconfirmed row). The N/A rankings-classification is the documented free-TEXT/NULL state (finding_kind free-TEXT + severity NULL), NOT a new severity enum value. v_coverage.lanes_stuck_running inlined lane list += fuzzgpt_history_lane.')
ON CONFLICT DO NOTHING;
