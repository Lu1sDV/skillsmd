-- vuln-research migration 0018 — post-Hunt methodology blind-spot sweep (Phase 1.6)
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: after ALL discovery sweeps finish for a (target, round) — Phase 1 Hunt and
-- (DEEP) Phase 1.5 Fuzzing — run two IDENTICAL, INDEPENDENT agents whose single goal is
-- "find any blind spot in our codebase-analysis methodology", then MERGE their output
-- (content-hash union-dedup) into ranked candidate directions/lanes that FEED FORWARD
-- into the NEXT round (they do not spawn work this run). Mirrors the dual seed-corpus
-- lane pair (ids 12/13): one prompt, two instances, diversity from LLM stochasticity,
-- agreement (both lanes flag the same gap) is the confidence signal. Five additive pieces:
--   (1) methodology_blind_spots — NEW table. One row per merged blind-spot direction.
--       gap_class CHECK ('process','coverage') is the "clearly separated" axis the user
--       asked for: 'process' = HOW we analyzed (bug classes never checked, missing lanes,
--       untested assumptions); 'coverage' = WHAT this run never reached. This keeps the
--       meta-pass output distinct from the existing frontier-coverage
--       agent_observations(obs_kind='blind_spot') rows emitted by cpg_coverage (id 16),
--       which stay where they are. Merge/dedup is DB-native: blindspot_hash UNIQUE; the
--       second lane's identical row hits ON CONFLICT, and the orchestrator flips
--       agreement -> 'both' and bumps dedup_cluster_size (the union-dedup merge).
--   (2) two strategies (ids 17, 18) — methodology_blindspot_lane_a / _b. Identical-by-
--       design dual pair (the id-12/13 precedent). MANDATORY DEEP lanes.
--   (3) v_required_deep_lanes — append both lanes under the NEW phase 'phase1_6_blindspot'.
--       This auto-wires BOTH gates: v_lane_coverage (MISSING if neither runs nor documents
--       a skip) and v_observation_coverage (which derives its phase list from this view, so
--       the every-phase observation-flush rule now covers Phase 1.6 too).
--   (4) v_methodology_blindspots_ranked — read-time ranking (no stored score; the
--       v_critical_fn_ranked / v_suspicious_points_ranked precedent): unconsumed directions
--       first, both-lane agreement above single, recurrence (dedup_cluster_size) next.
--   (5) v_phase_status + v_coverage — restate (CREATE OR REPLACE; idempotent, FK-free):
--       v_phase_status gains the phase1_6_blindspot row (rows_populated = methodology_blind_spots
--       count); v_coverage gains the SIGNAL metric 'methodology_blindspots_unpromoted'
--       (count-free inspect-signal like fuzz_runs_skipped — NOT an auto-red: the latest
--       round always has unconsumed directions by construction).
--
-- FRESH-TABLE NOTE (the 0010/0015/0017 pattern): methodology_blind_spots is a NEW table,
-- so its inline NOT NULL / CHECK / UNIQUE constraints are safe on this upgrade path and
-- match db/schema.sql byte-for-byte. No existing CHECK is widened — agent_observations.obs_kind
-- is deliberately UNCHANGED (the meta-pass companion observations reuse the existing
-- 'blind_spot' kind; separation lives in the new table's gap_class, not in a new enum value,
-- so there is no constraint rebuild). strategies.name is free TEXT (CHECK removed in v0.14),
-- so seeding ids 17/18 is a plain idempotent INSERT … ON CONFLICT (name) DO NOTHING.
--
-- ORDERING: targets (0001), round_ledger (0001/0002), agent_steps (0001) exist earlier, so
-- the methodology_blind_spots FKs (incl. the promoted_to_round_id self-reference to
-- round_ledger) resolve cleanly when this is applied last. v_phase_status / v_coverage /
-- v_required_deep_lanes were created earlier (0006/0007) and last widened by 0017;
-- CREATE OR REPLACE VIEW is idempotent + FK-free (DuckDB replaces the whole body), so the
-- full bodies are restated here. db/schema.sql carries the identical definitions.

------------------------------------------------------------
-- (1) methodology_blind_spots (schema v18) — see db/schema.sql for the full column rationale.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS methodology_blind_spots (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_id INTEGER REFERENCES round_ledger(id),          -- nullable: a single-shot audit need not open a round
  agent_step_id INTEGER REFERENCES agent_steps(id),      -- the merge step / emitting lane (provenance)
  gap_class TEXT NOT NULL                                -- the "clearly separated" axis
    CHECK (gap_class IN ('process', 'coverage')),
  title TEXT NOT NULL,                                   -- one-line direction name
  body TEXT NOT NULL,                                    -- the blind spot + why it matters as a next-round lane
  body_sidecar_path TEXT,                                -- set when body > 16 KB (A1)
  proposed_lane TEXT,                                    -- candidate strategies.name this direction would become (nullable)
  symbol_path TEXT,                                      -- optional anchor (a coverage gap often names a method/region)
  evidence_path TEXT,
  evidence_line INTEGER,
  agreement TEXT NOT NULL DEFAULT 'single'               -- 'both' = both lanes independently flagged it (merge signal)
    CHECK (agreement IN ('single', 'both')),
  dedup_cluster_size INTEGER NOT NULL DEFAULT 1,         -- idempotent merge-hit count (lanes + rounds)
  promoted_to_round_id INTEGER REFERENCES round_ledger(id),  -- set when a LATER round consumes this as a direction/lane (feed-forward closure)
  blindspot_hash TEXT NOT NULL,                          -- stable hash over (target_id, gap_class, normalized identity) — the union-dedup/merge key
  created_at TIMESTAMP NOT NULL,
  UNIQUE (blindspot_hash)
);

------------------------------------------------------------
-- (2) methodology_blindspot_lane_a / _b strategies (ids 17, 18). MANDATORY DEEP.
-- Idempotent; ids 1..16 are occupied (next free >= 19 after these).
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (17, 'methodology_blindspot_lane_a', 'Phase 1.6 (DEEP) post-Hunt methodology blind-spot sweep (instance A of an identical-by-design dual pair with methodology_blindspot_lane_b). Runs AFTER all discovery sweeps (Phase 1 Hunt + Phase 1.5 Fuzzing) for a (target, round). Single goal: "find any blind spot in our codebase-analysis methodology" — critiquing BOTH process gaps (HOW we analyzed: bug classes never checked, lanes that should exist but do not, assumptions left untested, source/sink/defense types not enumerated) AND coverage gaps (WHAT this run never reached). Emits methodology_blind_spots rows (gap_class in process|coverage) + one companion reusable agent_observations(obs_kind=''blind_spot''). The content-hash-deduped UNION of lane A + lane B is the merge; agreement=''both'' marks gaps both lanes independently flagged. Diversity arises purely from LLM stochasticity (the two lanes share one prompt/strategy). The merged, ranked directions FEED FORWARD into the next round (v_methodology_blindspots_ranked); they do NOT spawn work this run.', 1),
  (18, 'methodology_blindspot_lane_b', 'Phase 1.6 (DEEP) post-Hunt methodology blind-spot sweep (instance B of an identical-by-design dual pair with methodology_blindspot_lane_a). Runs AFTER all discovery sweeps (Phase 1 Hunt + Phase 1.5 Fuzzing) for a (target, round). Single goal: "find any blind spot in our codebase-analysis methodology" — critiquing BOTH process gaps (HOW we analyzed: bug classes never checked, lanes that should exist but do not, assumptions left untested, source/sink/defense types not enumerated) AND coverage gaps (WHAT this run never reached). Emits methodology_blind_spots rows (gap_class in process|coverage) + one companion reusable agent_observations(obs_kind=''blind_spot''). The content-hash-deduped UNION of lane A + lane B is the merge; agreement=''both'' marks gaps both lanes independently flagged. Diversity arises purely from LLM stochasticity (the two lanes share one prompt/strategy). The merged, ranked directions FEED FORWARD into the next round (v_methodology_blindspots_ranked); they do NOT spawn work this run.', 1)
ON CONFLICT (name) DO NOTHING;

------------------------------------------------------------
-- (3) v_required_deep_lanes — append the two Phase 1.6 lanes. Full body restated
-- (DuckDB replaces the whole view); all prior rows are byte-identical to 0017 / db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_required_deep_lanes AS
SELECT * FROM (VALUES
  ('preliminary_enumeration_lane',      'phase0_decompose'),  -- migration 0014 (enumeration completeness)
  ('forward_slice_lane',                'phase1_hunt'),
  ('backward_sink_lane',                'phase1_hunt'),
  ('critical_function_dataflow_lane',   'phase1_hunt'),
  ('defense_base_lane',                 'phase0_75_prebreak'),
  ('defense_context_verification_lane', 'phase0_75_prebreak'),
  ('isolation_fuzz_lane',               'phase0_75_prebreak'),
  ('html_sanitizer_bypass_lane',        'phase0_75_prebreak'),
  ('concolic_bypass_lane',              'phase0_75_prebreak'),  -- migration 0013 (C5)
  ('llm_seed_corpus_lane_a',            'phase1_4_seed'),       -- migration 0011 (C2)
  ('llm_seed_corpus_lane_b',            'phase1_4_seed'),       -- migration 0011 (C2)
  ('boundary_fuzz_lane',                'phase1_5_fuzz'),
  ('methodology_blindspot_lane_a',      'phase1_6_blindspot'),  -- migration 0018 (post-Hunt meta pass)
  ('methodology_blindspot_lane_b',      'phase1_6_blindspot'),  -- migration 0018 (post-Hunt meta pass)
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

------------------------------------------------------------
-- (4) v_methodology_blindspots_ranked (v18) — read-time ranking, NO stored score
-- (the v_critical_fn_ranked / v_suspicious_points_ranked precedent). Ordering is purely
-- ordinal — no magic constant: unconsumed directions first, both-lane agreement above
-- single, then recurrence (dedup_cluster_size), then gap_class, then created_at.
-- Identical to db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_methodology_blindspots_ranked AS
SELECT
  id,
  target_id,
  round_id,
  gap_class,
  title,
  proposed_lane,
  symbol_path,
  agreement,
  dedup_cluster_size,
  promoted_to_round_id,
  (promoted_to_round_id IS NULL) AS open_direction,
  created_at
FROM methodology_blind_spots
ORDER BY
  (promoted_to_round_id IS NULL) DESC,             -- unconsumed directions first (the next-round worklist)
  CASE agreement WHEN 'both' THEN 0 ELSE 1 END,    -- both-lane agreement outranks single-lane
  dedup_cluster_size DESC,                         -- recurrence across lanes/rounds
  gap_class,
  created_at;

------------------------------------------------------------
-- (5a) v_phase_status — append the phase1_6_blindspot row (post-fuzz). Full body restated;
-- phase_seq renumbered so confirm/proof/report shift +1 to slot blindspot after fuzz.
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
  UNION ALL SELECT 5, 'phase1_6_blindspot',
         (SELECT count(*) FROM methodology_blind_spots)
  UNION ALL SELECT 6, 'phase2_confirm',
         (SELECT count(*) FROM refutations)
  UNION ALL SELECT 7, 'phase4_proof',
         (SELECT count(*) FROM audit_outcomes)
  UNION ALL SELECT 8, 'phase5_report',
         (SELECT count(*) FROM critic_findings)
) t
ORDER BY phase_seq;

------------------------------------------------------------
-- (5b) v_coverage — append the methodology_blindspots_unpromoted SIGNAL metric. Full body
-- restated; all branches through slices_without_codebase_coverage are byte-identical to
-- 0017 / db/schema.sql. The new metric is an inspect-SIGNAL (like fuzz_runs_skipped), NOT
-- an auto-red: the latest round always has unconsumed directions by construction.
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
  -- Slice-end codebase-coverage signal (v0.24): the "SAVE coverage when slices end"
  -- gate. If any input_slices row exists but NO cpg_slice_coverage row was ever
  -- written, the union-of-slices codebase coverage was never measured => 1 (RED).
  UNION ALL SELECT 'slices_without_codebase_coverage',
    CASE WHEN EXISTS (SELECT 1 FROM input_slices)
          AND NOT EXISTS (SELECT 1 FROM cpg_slice_coverage)
         THEN 1 ELSE 0 END,
    'input_slices exist but no cpg_slice_coverage row — codebase slice-coverage was never measured/saved when slices ended (RED)'
  -- Methodology blind-spot feed-forward signal (v0.25): merged Phase-1.6 directions not
  -- yet consumed by a later round as a lane. SIGNAL, not auto-red — the latest round always
  -- has unconsumed directions by construction; inspect via v_methodology_blindspots_ranked.
  UNION ALL SELECT 'methodology_blindspots_unpromoted',
    (SELECT count(*) FROM methodology_blind_spots WHERE promoted_to_round_id IS NULL),
    'merged methodology blind-spots not yet carried into a later round as a direction/lane — SIGNAL not auto-red (expected on the latest round); confirm each was considered as a next-round lane'
) t
ORDER BY metric;

INSERT INTO schema_version (version, description)
VALUES (18, 'post-Hunt methodology blind-spot sweep (Phase 1.6): methodology_blind_spots table (gap_class process|coverage, content-hash union-dedup merge, promoted_to_round_id feed-forward) + v_methodology_blindspots_ranked + two mandatory DEEP lanes (ids 17/18, identical-by-design pair) under phase1_6_blindspot in v_required_deep_lanes + v_phase_status row + v_coverage.methodology_blindspots_unpromoted signal')
ON CONFLICT DO NOTHING;
