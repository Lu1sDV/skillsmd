-- vuln-research migration 0011 — C2 dual LLM seed-corpus lanes
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: adds the preliminary Phase-1.4 dual-redundant LLM seed-corpus stage that
-- feeds the existing boundary_fuzz_lane (Phase 1.5). Two NEW seeded strategies
-- (ids 12, 13 — next free after the 1..11 seed block):
--   * llm_seed_corpus_lane_a
--   * llm_seed_corpus_lane_b
-- They are IDENTICAL by design (same prompt/strategy), run independently; corpus
-- diversity arises from LLM stochasticity, and the content-hash-deduped UNION of
-- the two lanes' outputs feeds boundary_fuzz_lane. Each lane emits
-- fuzz_artifacts(artifact_kind='seed_initial') rows (existing table, no new
-- artifact_kind needed — seed_initial is already a canonical value). Both are added
-- to v_required_deep_lanes as mandatory DEEP lanes at phase '1.4' (preliminary,
-- before 1.5 consumes the merged corpus).
--
-- CONFIG-KNOB-IN-DB NOTE: the C2 seed budget lives in the DB (DB-native
-- determinism), NOT in fetch-budgets.yml and NOT in scoring_config (whose `scope`
-- is a closed CHECK DuckDB cannot widen). This migration introduces a minimal
-- generic open key-value config table `run_config` (no closed CHECK; the key space
-- is open) as the DB home for such operational knobs, and seeds two rows: the
-- per-lane seed token budget (mirrors phase1_5_fuzz's 12000 magnitude) and the
-- input-format-family coverage target. Per-lane STOP CONDITION: coverage target
-- reached OR per-lane token budget spent, whichever comes first. The budget is
-- tier-scaled by the existing LOW/MED/DEEP effort multipliers at read time.
--
-- ORDERING: strategies, agent_steps, targets, round_ledger are created by 0001;
-- v_required_deep_lanes by 0007; fuzz_artifacts by 0008. All resolve cleanly when
-- this is applied last. db/schema.sql carries the identical defs for fresh DBs.

------------------------------------------------------------
-- run_config — generic open key-value operational-config home. No closed CHECK
-- (the key space is open, unlike scoring_config.scope), so future DB-native knobs
-- land here without a DuckDB constraint rebuild. Fresh table, so inline NOT NULL
-- is fine.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS run_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT
);

-- C2 seed-budget knobs. seed_token_budget_per_lane mirrors phase1_5_fuzz's 12000.
-- seed_format_family_coverage_target is the input-format-family coverage goal; the
-- per-lane stop condition is: coverage_target reached OR token_budget spent,
-- whichever first. Both are tier-scaled by the existing LOW/MED/DEEP multipliers.
INSERT INTO run_config (key, value, description) VALUES
  ('seed_token_budget_per_lane',        '12000', 'C2: per-lane LLM seed-corpus token budget (mirrors phase1_5_fuzz 12000); tier-scaled by LOW/MED/DEEP. Stop condition: coverage target OR this budget, whichever first.'),
  ('seed_format_family_coverage_target','0.80',  'C2: input-format-family coverage target for the dual seed-corpus lanes (fraction of identified format families seeded). Stop condition: this target OR the per-lane token budget, whichever first.')
ON CONFLICT (key) DO NOTHING;

------------------------------------------------------------
-- Strategy registration (ids 12, 13 — next free after the 1..11 seed block).
-- Identical-by-design dual lanes; diversity from LLM stochasticity; union
-- content-hash-deduped into the boundary_fuzz_lane corpus.
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (12, 'llm_seed_corpus_lane_a', 'Phase 1.4 (DEEP) preliminary LLM seed-corpus generator (instance A of an identical-by-design dual pair with llm_seed_corpus_lane_b). Independently synthesizes initial fuzz seeds from the target''s input-format families; emits fuzz_artifacts(artifact_kind=''seed_initial''). The content-hash-deduped UNION of lane A + lane B feeds boundary_fuzz_lane (Phase 1.5); diversity arises purely from LLM stochasticity (the two lanes share one prompt/strategy). Per-lane stop condition: input-format-family coverage target OR per-lane seed token budget (run_config), whichever first.', 1),
  (13, 'llm_seed_corpus_lane_b', 'Phase 1.4 (DEEP) preliminary LLM seed-corpus generator (instance B of an identical-by-design dual pair with llm_seed_corpus_lane_a). Independently synthesizes initial fuzz seeds from the target''s input-format families; emits fuzz_artifacts(artifact_kind=''seed_initial''). The content-hash-deduped UNION of lane A + lane B feeds boundary_fuzz_lane (Phase 1.5); diversity arises purely from LLM stochasticity (the two lanes share one prompt/strategy). Per-lane stop condition: input-format-family coverage target OR per-lane seed token budget (run_config), whichever first.', 1)
ON CONFLICT (name) DO NOTHING;

------------------------------------------------------------
-- DEEP gate roster — add BOTH dual seed-corpus lanes as mandatory DEEP lanes at
-- phase '1.4' (preliminary, before phase1_5_fuzz). CREATE OR REPLACE VIEW is
-- idempotent + FK-free. db/schema.sql carries the identical 11-row definition.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_required_deep_lanes AS
SELECT * FROM (VALUES
  ('forward_slice_lane',                'phase1_hunt'),
  ('backward_sink_lane',                'phase1_hunt'),
  ('critical_function_dataflow_lane',   'phase1_hunt'),
  ('defense_base_lane',                 'phase0_75_prebreak'),
  ('defense_context_verification_lane', 'phase0_75_prebreak'),
  ('isolation_fuzz_lane',               'phase0_75_prebreak'),
  ('html_sanitizer_bypass_lane',        'phase0_75_prebreak'),
  ('llm_seed_corpus_lane_a',            'phase1_4_seed'),
  ('llm_seed_corpus_lane_b',            'phase1_4_seed'),
  ('boundary_fuzz_lane',                'phase1_5_fuzz'),
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

INSERT INTO schema_version (version, description)
VALUES (11, 'dual LLM seed-corpus lanes (Phase 1.4): strategies 12/13 + run_config knob table + v_required_deep_lanes roster')
ON CONFLICT DO NOTHING;
