-- vuln-research migration 0010 — Suspicious Point (SP) screening tier
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: adds the domain-agnostic, high-recall SP screening tier that sits BEFORE
-- the gr_findings confirmation tier (spec
-- .omc/specs/deep-interview-suspicious-point-pipeline.md §4–§5). Three new tables:
--   * suspicious_points       — the region-level vulnerability hypothesis (§4.1)
--   * suspicious_point_factor — EAV factor store, one row per (sp, factor) (§4.2)
--   * sp_factor_config        — the criteria catalog + weight/direction/gate knobs (§4.3)
-- Two read-time views (score is NEVER stored — mirrors v_critical_fn_ranked):
--   * v_suspicious_points_ranked — within-round percentile-rank composite (§4.4)
--   * v_sp_factor_coverage       — per-factor producer coverage gate (§4.5; mirrors v_lane_coverage)
-- One scalar MACRO (the "formula lives once" requirement, §4.4):
--   * sp_signed_rank(direction, rank) — the per-factor signed-rank transform.
--
-- CHECK-DIVERGENCE NOTE (mirrors the 0009 / 0007 precedent): these are FRESH
-- tables, so inline NOT NULL / DEFAULT / UNIQUE are fine here, but the categorical
-- vocabularies (screening_verdict, and the open vocabs vuln_class / oracle / lane /
-- factor_name) carry NO CHECK on this upgrade path — DuckDB cannot ADD a CHECK to a
-- column post-hoc and we keep the migration byte-aligned with the fresh-DB path's
-- enforcement story. The canonical db/schema.sql carries the NULL-permitting CHECK
-- on the one genuinely-closed vocab (screening_verdict, effort_tier precedent);
-- open vocabularies stay free TEXT on both paths and are seeded in sp_factor_config.
--
-- ORDERING: targets, round_ledger, agent_steps, gr_findings are all created by
-- 0001, so the FK references resolve cleanly when this is applied last.
-- DuckDB 1.1.3 constraints honored: no triggers, no procs, no STORED generated
-- columns — all SP scoring is a read-time view + scalar macro.

------------------------------------------------------------
-- suspicious_points (§4.1) — the screening tier. NO confirmation_status, NO PoC
-- columns, NO stored score (all by design — gr_findings owns confirmation).
-- Dedup is DB-native: the UNIQUE natural key + ON CONFLICT increments
-- dedup_cluster_size (no LLM deduplicator agent).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS suspicious_points (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_id INTEGER REFERENCES round_ledger(id),
  agent_step_id INTEGER REFERENCES agent_steps(id),
  symbol_path TEXT NOT NULL,        -- function/region anchor
  region_hash TEXT NOT NULL,        -- stable hash of normalized control-flow description
  description TEXT NOT NULL,        -- control-flow LANDMARKS, not line numbers
  vuln_class TEXT NOT NULL,         -- open vocab: heap_overflow | sqli | ssrf | xss | sanitizer_bypass | ...
  oracle TEXT,                      -- open vocab: sanitizer_crash | differential | assertion | response_diff | invariant
  lane TEXT,                        -- emitting strategy/lane name (by-name link to strategies)
  screening_verdict TEXT,           -- kept | screened_out (NO CHECK on upgrade path; app-side enforced)
  graduated_finding_id INTEGER REFERENCES gr_findings(id),  -- set on graduation; NULL while pre-candidate
  dedup_cluster_size INTEGER DEFAULT 1,                     -- idempotent merge-hit count
  created_at TIMESTAMP,
  UNIQUE (target_id, symbol_path, vuln_class, lane, region_hash)
);

------------------------------------------------------------
-- suspicious_point_factor (§4.2) — EAV factor store. raw_value is producer-emitted
-- (gates use 0/1). The normalized/percentile value is NOT stored — computed
-- read-time in v_suspicious_points_ranked.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS suspicious_point_factor (
  id INTEGER PRIMARY KEY,
  sp_id INTEGER NOT NULL REFERENCES suspicious_points(id),
  factor_name TEXT NOT NULL,        -- open vocab, seeded in sp_factor_config
  raw_value REAL,                   -- producer-emitted raw value (gates use 0/1)
  evidence_ref TEXT,                -- provenance pointer (observation/slice/cf/git/etc.)
  producer_lane TEXT,               -- which lane/step produced it (coverage tracking)
  created_at TIMESTAMP,
  UNIQUE (sp_id, factor_name)
);

------------------------------------------------------------
-- sp_factor_config (§4.3) — the catalog + knobs. Dedicated table (NOT
-- scoring_config, whose scope is a closed CHECK that DuckDB cannot widen).
-- weight=0 = registered but inert (lets a criterion be added before its producer
-- exists). direction +1 boost | -1 penalty. is_gate = hard 0/1 floor condition.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sp_factor_config (
  factor_name TEXT PRIMARY KEY,     -- open vocab
  weight REAL NOT NULL DEFAULT 0,   -- 0 = registered but inert
  direction INTEGER NOT NULL DEFAULT 1,  -- +1 boost | -1 penalty
  is_gate BOOLEAN NOT NULL DEFAULT FALSE,-- hard 0/1 condition, not percentile-ranked
  expected_producer TEXT,           -- lane/phase that should populate it (coverage gate)
  description TEXT
);

------------------------------------------------------------
-- sp_signed_rank (§4.4) — the per-factor signed-rank transform, the one place the
-- formula lives (the "stored-procedure substitute"). A boost (+1) keeps the
-- within-round percentile rank; a penalty (-1) inverts it to (1 - rank).
------------------------------------------------------------
CREATE OR REPLACE MACRO sp_signed_rank(direction, rank) AS
  CASE WHEN direction = -1 THEN 1.0 - rank ELSE rank END;

------------------------------------------------------------
-- sp_factor_config seed (§5 criteria catalog).
-- Source-1 + Source-2 factors launch active (nonzero weight, open-item #1);
-- Source-3 (NEW) factors register at weight=0 (inert until producers land).
-- Gates: oracle_applicable, reachable_from_entry, taint_reach_G1.
-- Penalties (direction=-1): intended_feature_G3, proven_invariant.
------------------------------------------------------------
INSERT INTO sp_factor_config (factor_name, weight, direction, is_gate, expected_producer, description) VALUES
  -- Source 1 — FuzzingBrain criteria (de-crash-ified)
  ('dangerous_sink_class',     0.12, 1, FALSE, 'sinks (Phase 0)',                         'Source-1: sink belongs to a dangerous sink class'),
  ('attacker_input_influence', 0.12, 1, FALSE, 'sources + taint (Phase 0-1)',             'Source-1: degree of attacker control over the region input'),
  ('uncertain_protection',     0.10, 1, FALSE, 'defenses gap analysis (Phase 0.75)',      'Source-1: protection presence is uncertain / gappy'),
  -- Gate weights are nonzero (1.00) so v_sp_factor_coverage tracks their producers
  -- (a missing oracle-catalog / reachability producer must surface as MISSING). The
  -- score view excludes is_gate factors from the weighted sum regardless of weight —
  -- gates contribute only via the hard floor, never the composite.
  ('oracle_applicable',        1.00, 1, TRUE,  'oracle catalog per vuln_class (new)',     'Source-1 GATE: a usable oracle exists for this vuln_class'),
  ('reachable_from_entry',     1.00, 1, TRUE,  'call graph / critical_fn_reach (Phase 0-1)','Source-1 GATE: region is reachable from an entry point'),
  ('recall_band',              0.08, 1, FALSE, 'emitting lane verdict',                   'Source-1: emitting lane recall-band confidence'),
  -- Source 2 — already in the skill (reused as factors)
  ('factor_recurrence_prior',  0.14, 1, FALSE, 'round feed-forward',                      'Source-2: cross-round recurrence prior (hi)'),
  ('factor_bypass_prior',      0.14, 1, FALSE, 'defense_bypasses cross-round',            'Source-2: prior reproduced bypass prior (hi)'),
  ('critical_fn_rank',         0.10, 1, FALSE, 'v_critical_fn_ranked',                    'Source-2: critical-function rank score'),
  ('taint_reach_G1',           1.00, 1, TRUE,  'Confirm gate 1',                          'Source-2 GATE: taint reaches the sink (Confirm G1)'),
  ('defense_gap_G2',           0.08, 1, FALSE, 'Confirm gate 2',                          'Source-2: defense-gap signal (Confirm G2)'),
  ('intended_feature_G3',      0.10, -1, FALSE,'intended_feature_classification',         'Source-2 PENALTY: region is an intended feature (Confirm G3)'),
  ('blind_spot',               0.06, 1, FALSE, 'agent_observations / coverage carry',     'Source-2: flagged blind spot / deferred edge'),
  ('sink_severity',            0.08, 1, FALSE, 'sinks',                                   'Source-2: sink severity'),
  ('config_reachable',         0.06, 1, FALSE, 'config_state',                            'Source-2: reachable under a plausible config'),
  -- Source 3 — NEW (brainstorm; registered inert at weight=0 until producers land)
  ('change_churn',             0.00, 1, FALSE, 'git (Phase L0 recency)',                  'Source-3: recent change churn'),
  ('call_depth',               0.00, 1, FALSE, 'call graph (Phase 0)',                    'Source-3: call depth'),
  ('guard_distance',           0.00, 1, FALSE, 'static analysis (new producer)',          'Source-3: distance to nearest guard'),
  ('complexity',               0.00, 1, FALSE, 'static metric (new producer)',            'Source-3: cyclomatic / cognitive complexity'),
  ('taint_fanin',              0.00, 1, FALSE, 'taint graph',                             'Source-3: taint fan-in count'),
  ('oracle_count',             0.00, 1, FALSE, 'oracle catalog',                          'Source-3: number of applicable oracles'),
  ('dedup_cluster_size',       0.00, 1, FALSE, 'suspicious_points (DB-native)',           'Source-3: idempotent merge-hit count'),
  ('failed_poc_attempts',      0.00, 1, FALSE, 'PoC/fuzz loop',                           'Source-3: failed PoC/fuzz attempt count'),
  ('proximity_to_confirmed',   0.00, 1, FALSE, 'call-graph distance to confirmed_vulns',  'Source-3: proximity to a confirmed vuln'),
  ('sink_class_base_rate',     0.00, 1, FALSE, 'eval_corpus history',                     'Source-3: historical base rate for this sink class'),
  ('proven_invariant',         0.00, -1, FALSE,'agent_observations(obs_kind=invariant)',  'Source-3 PENALTY: a proven invariant blocks the bug')
ON CONFLICT (factor_name) DO NOTHING;

------------------------------------------------------------
-- v_suspicious_points_ranked (§4.4) — read-time within-round percentile-rank
-- composite. NEVER stored (mirrors v_critical_fn_ranked).
--   * Gate factors (is_gate): hard 0/1. Any unsatisfied gate (raw_value not > 0)
--     floors the SP to gate_ok=FALSE and composite_score=0.
--   * Non-gate factors: PERCENT_RANK() within (target_id, round_id, factor_name).
--     Degenerate population (n<=1 OR zero-variance min=max) -> deterministic
--     neutral 0.5. Penalties invert via sp_signed_rank(direction, rank).
--   * composite = SUM(weight * signed_rank) over non-gate factors, gated.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_suspicious_points_ranked AS
WITH factor_rows AS (
  SELECT
    sp.id AS sp_id,
    sp.target_id,
    sp.round_id,
    spf.factor_name,
    spf.raw_value,
    cfg.weight,
    cfg.direction,
    cfg.is_gate,
    PERCENT_RANK() OVER (
      PARTITION BY sp.target_id, sp.round_id, spf.factor_name
      ORDER BY spf.raw_value
    ) AS pct_rank,
    COUNT(*) OVER (
      PARTITION BY sp.target_id, sp.round_id, spf.factor_name
    ) AS pop_n,
    MIN(spf.raw_value) OVER (
      PARTITION BY sp.target_id, sp.round_id, spf.factor_name
    ) AS pop_min,
    MAX(spf.raw_value) OVER (
      PARTITION BY sp.target_id, sp.round_id, spf.factor_name
    ) AS pop_max
  FROM suspicious_points sp
  JOIN suspicious_point_factor spf ON spf.sp_id = sp.id
  JOIN sp_factor_config cfg        ON cfg.factor_name = spf.factor_name
),
scored AS (
  SELECT
    sp_id,
    target_id,
    round_id,
    is_gate,
    weight,
    direction,
    raw_value,
    -- degenerate population (n<=1 or zero-variance) -> deterministic neutral 0.5
    CASE WHEN pop_n <= 1 OR pop_min = pop_max THEN 0.5 ELSE pct_rank END AS norm_rank
  FROM factor_rows
)
SELECT
  sp.id,
  sp.target_id,
  sp.round_id,
  sp.symbol_path,
  sp.vuln_class,
  sp.lane,
  sp.screening_verdict,
  sp.graduated_finding_id,
  -- gate_ok: TRUE iff every gate factor present for this SP is satisfied (raw_value > 0).
  -- An SP with no gate factors at all is treated as gate-satisfied (no gate to fail).
  COALESCE(
    BOOL_AND(CASE WHEN s.is_gate THEN COALESCE(s.raw_value, 0) > 0 ELSE TRUE END),
    TRUE
  ) AS gate_ok,
  -- composite = SUM(weight * signed_rank) over NON-gate factors, floored to 0 if any gate fails.
  CASE
    WHEN COALESCE(
      BOOL_AND(CASE WHEN s.is_gate THEN COALESCE(s.raw_value, 0) > 0 ELSE TRUE END),
      TRUE
    )
    THEN COALESCE(
      SUM(CASE WHEN NOT s.is_gate THEN s.weight * sp_signed_rank(s.direction, s.norm_rank) ELSE 0 END),
      0
    )
    ELSE 0
  END AS composite_score
FROM suspicious_points sp
LEFT JOIN scored s ON s.sp_id = sp.id
GROUP BY
  sp.id, sp.target_id, sp.round_id, sp.symbol_path, sp.vuln_class,
  sp.lane, sp.screening_verdict, sp.graduated_finding_id;

------------------------------------------------------------
-- v_sp_factor_coverage (§4.5) — per-factor producer coverage gate. For each
-- sp_factor_config row with weight <> 0, report whether ANY suspicious_point_factor
-- row populated it. 'ok' = populated, 'MISSING' = expected-but-absent producer.
-- Mirrors v_lane_coverage: makes a never-populated active factor a queryable delta
-- rather than a silently-neutral 0.5. Inert (weight=0) factors are excluded.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_sp_factor_coverage AS
SELECT
  cfg.factor_name,
  cfg.weight,
  cfg.is_gate,
  cfg.expected_producer,
  COUNT(spf.id) AS rows_populated,
  CASE WHEN COUNT(spf.id) > 0 THEN 'ok' ELSE 'MISSING' END AS coverage_status
FROM sp_factor_config cfg
LEFT JOIN suspicious_point_factor spf ON spf.factor_name = cfg.factor_name
WHERE cfg.weight <> 0
GROUP BY cfg.factor_name, cfg.weight, cfg.is_gate, cfg.expected_producer;

INSERT INTO schema_version (version, description)
VALUES (10, 'suspicious point screening tier: SP tables + EAV factors + sp_factor_config + read-time percentile-rank score view + factor-coverage view')
ON CONFLICT DO NOTHING;
