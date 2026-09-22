-- vuln-research migration 0017 — slice-end CODEBASE slice-coverage
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: persist, WHEN THE HUNT'S SLICING LANES END, how much of the codebase the
-- UNION of all slices actually touched — the blind spot the existing coverage signals
-- miss (agent_steps.coverage_json = how thoroughly ONE slice was walked;
-- v_lane_coverage = WHICH lanes ran; neither = "what fraction of the codebase did the
-- slices collectively cover"). Three additive pieces:
--   (1) cpg_slice_coverage — NEW table, one row per (target_id, round_id), storing the
--       measured integer counts for TWO denominators: RAW (first-party methods) and
--       FRONTIER (attacker-reachable ∪ sink-bearing ∪ critical-function methods). The
--       percentages are NEVER stored — they are computed read-time by
--       v_cpg_slice_coverage (DB-native determinism, no magic constant).
--   (2) cpg_coverage strategy (id 16) — NON-MANDATORY (deliberately ABSENT from
--       v_required_deep_lanes, so the mandatory roster + LLMxCPG 'no new lane'
--       precedent are unchanged). It owns the slice-end measurement step; the
--       coverage row + the uncovered-frontier blind_spot observations attach to it.
--   (3) v_coverage gate branch 'slices_without_codebase_coverage' — count-free
--       EXISTS/NOT EXISTS: slices exist but no coverage row => 1 (RED). This is the
--       "SAVE coverage when slices end" enforcement; there is NO percentage floor
--       (slicing is selective by design — a low % is inspected, not auto-failed).
--
-- FRESH-TABLE NOTE (the 0010/0015 pattern): cpg_slice_coverage is a NEW table, so its
-- inline NOT NULL / CHECK / UNIQUE constraints are safe on this upgrade path and match
-- db/schema.sql byte-for-byte. No existing CHECK is widened: strategies.name is free
-- TEXT (the CHECK was removed in v0.14), so seeding strategy 16 is a plain idempotent
-- INSERT … ON CONFLICT (name) DO NOTHING — no constraint rebuild, no divergence.
--
-- ORDERING: targets (0001), round_ledger (0001/0002), agent_steps (0001) are all
-- created earlier, so the cpg_slice_coverage FKs resolve cleanly when this is applied
-- last. v_coverage was created by 0006 and last widened by 0016; CREATE OR REPLACE VIEW
-- is idempotent + FK-free (DuckDB replaces the whole view body), so the full body is
-- restated here (branches through defenses_below_validator_cf_floor are UNCHANGED from
-- 0016; only slices_without_codebase_coverage is appended). db/schema.sql carries the
-- identical definitions for the fresh-DB path.

------------------------------------------------------------
-- (1) cpg_slice_coverage (schema v17) — see db/schema.sql for the full column rationale.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpg_slice_coverage (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_id INTEGER REFERENCES round_ledger(id),       -- nullable: a single-shot audit need not open a round
  agent_step_id INTEGER REFERENCES agent_steps(id),   -- nullable: the 'cpg_coverage' step that measured this (provenance)
  methods_total INTEGER NOT NULL,                     -- RAW denominator: first-party CPG methods (cpg.method.isExternal(false).size)
  methods_covered INTEGER NOT NULL,                   -- RAW numerator: distinct first-party methods in the UNION of all slice nodes
  frontier_total INTEGER NOT NULL,                    -- FRONTIER denominator: attacker-reachable ∪ sink-bearing ∪ critical-function methods
  frontier_covered INTEGER NOT NULL,                  -- FRONTIER numerator: distinct frontier methods in the UNION of all slice nodes
  files_total INTEGER,
  files_covered INTEGER,
  nodes_total INTEGER,
  nodes_covered INTEGER,
  per_kind_json TEXT,
  coverage_basis TEXT NOT NULL DEFAULT 'raw=first_party_methods;frontier=reachable+sink+cf',
  measured_at TIMESTAMP NOT NULL,
  coverage_hash TEXT NOT NULL,
  CHECK (methods_covered  <= methods_total),
  CHECK (frontier_covered <= frontier_total),
  UNIQUE (coverage_hash),
  UNIQUE (target_id, round_id)
);

------------------------------------------------------------
-- (2) cpg_coverage strategy (id 16) — NON-MANDATORY. Idempotent; ids 1..16 are
-- occupied (next free >= 17). NOT added to v_required_deep_lanes by design.
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (16, 'cpg_coverage', 'Slice-end CODEBASE coverage measurement (NON-MANDATORY — deliberately not in v_required_deep_lanes). After the Hunt''s slicing lanes flush for a (target, round), measures in Joern — over the UNION of every input_slices node set — how much of the codebase the slices collectively touched: a RAW ratio (first-party methods, cpg.method.isExternal(false)) and a FRONTIER ratio (attacker-reachable ∪ sink-bearing ∪ critical-function methods). Writes one cpg_slice_coverage row (integer counts only; percentages are computed by v_cpg_slice_coverage, never stored), and emits each uncovered FRONTIER method as a reusable agent_observations(obs_kind=''blind_spot'') anchored on symbol_path so the NEXT round slices it first (round feed-forward). Enforcement is the count-free gate v_coverage.slices_without_codebase_coverage (slices exist but no coverage row => RED), never a percentage floor.', 1)
ON CONFLICT (name) DO NOTHING;

------------------------------------------------------------
-- (3) v_coverage — append the slices_without_codebase_coverage branch. Full body
-- restated (DuckDB replaces the whole view); branches through
-- defenses_below_validator_cf_floor are byte-identical to 0016 / db/schema.sql.
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
  -- Count-free EXISTS/NOT EXISTS — no %-floor, no magic constant; enforces only that
  -- the measurement is saved, never how high it must be (inspect via v_cpg_slice_coverage).
  UNION ALL SELECT 'slices_without_codebase_coverage',
    CASE WHEN EXISTS (SELECT 1 FROM input_slices)
          AND NOT EXISTS (SELECT 1 FROM cpg_slice_coverage)
         THEN 1 ELSE 0 END,
    'input_slices exist but no cpg_slice_coverage row — codebase slice-coverage was never measured/saved when slices ended (RED)'
) t
ORDER BY metric;

------------------------------------------------------------
-- (4) v_cpg_slice_coverage (v17) — read-time percentages (covered/total, NULLIF guard).
-- frontier_covered_pct is the bug-finding ratio; methods_covered_pct the raw baseline.
-- Identical to db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_cpg_slice_coverage AS
SELECT
  target_id,
  round_id,
  frontier_covered,
  frontier_total,
  ROUND(100.0 * frontier_covered / NULLIF(frontier_total, 0), 1) AS frontier_covered_pct,
  methods_covered,
  methods_total,
  ROUND(100.0 * methods_covered  / NULLIF(methods_total, 0), 1)  AS methods_covered_pct,
  files_covered,
  files_total,
  ROUND(100.0 * files_covered    / NULLIF(files_total, 0), 1)    AS files_covered_pct,
  nodes_covered,
  nodes_total,
  ROUND(100.0 * nodes_covered    / NULLIF(nodes_total, 0), 1)    AS nodes_covered_pct,
  per_kind_json,
  coverage_basis,
  measured_at
FROM cpg_slice_coverage
ORDER BY target_id, round_id;

INSERT INTO schema_version (version, description)
VALUES (17, 'slice-end codebase slice-coverage: cpg_slice_coverage table (raw + frontier denominators) + v_cpg_slice_coverage + non-mandatory cpg_coverage strategy (id 16) + v_coverage.slices_without_codebase_coverage gate')
ON CONFLICT DO NOTHING;
