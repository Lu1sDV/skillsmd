-- vuln-research migration 0021 — Perpetual Loop mode
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: a new top-level MODE — a self-firing, unbounded vulnerability-discovery loop
-- modeled on the triple-network (DMN → Salience → Central-Executive) brain model, added as a
-- THIN orchestration layer over the existing engine. One round =
--   DMN generate (divergent)  →  Salience promote (top-K by promise)  →  Executive pursue
--   →  Confirm  →  Learn (round_ledger).
-- Maximal reuse, ZERO new tables: Executive REUSES the existing Phase 2 five-gate Confirm
-- + L5 PoC constraints; the learning ledger IS round_ledger + recurrence_counter + round
-- feed-forward; promise is a READ-TIME view over existing columns. Three additive pieces:
--   (1) strategies.created_at + strategies.updated_at — provenance timestamps. DuckDB v1.1.3
--       has NO triggers and NO `ON UPDATE CURRENT_TIMESTAMP`, so updated_at is moved by a
--       GUARDED UPSERT on the strategies seed (DO UPDATE … updated_at=CURRENT_TIMESTAMP WHERE
--       description/version actually changed), preserving created_at. strategies has NO FK
--       columns, so this UPDATE path avoids the DuckDB v1.1.3 ART-index FK-UPDATE bug.
--   (2) v_promise_ranked — read-time SALIENCE GATE ranking the round's divergent candidates by
--       promise = novelty × est_severity × reachability_prior × ledger_history_factor. NO stored
--       score, NO new table (the v_suspicious_points_ranked / v_critical_fn_ranked precedent);
--       the four factors are derived from existing suspicious_points / suspicious_point_factor
--       columns (mapping documented inline in the view + db/schema.sql).
--   (3) four NON-MANDATORY strategy rows (ids 19–22): perpetual_dmn_generate /
--       perpetual_salience_promote / perpetual_executive_pursue / perpetual_ledger_learn.
--       Deliberately ABSENT from v_required_deep_lanes (the cpg_coverage id-16 precedent) so
--       normal DEEP audits never block on them. Mandatory-ness is pure view membership — there
--       is no `mandatory` column — so registering them does NOT touch v_required_deep_lanes.
--
-- FK-FREE NOTE: v_promise_ranked is CREATE OR REPLACE VIEW (idempotent, FK-free); the two
-- strategies columns add via ADD COLUMN IF NOT EXISTS (the 0002 pattern). strategies.name is
-- free TEXT (CHECK removed v0.14). No existing CHECK is widened. Historical 0001-initial.sql is
-- NOT rewritten; it keeps its ON CONFLICT DO NOTHING seed form. db/schema.sql carries the
-- identical definitions (timestamps, view, guarded-upsert seed).

------------------------------------------------------------
-- (1) strategies provenance timestamps. DuckDB v1.1.3 does NOT support ADD COLUMN with a
-- constraint ("Adding columns with constraints not yet supported"), so on the upgrade path the
-- columns are added PLAIN (nullable, no default) and existing rows are backfilled to now() —
-- the 0002 precedent (ADD COLUMN IF NOT EXISTS, app-side enforcement). The canonical fresh
-- schema in db/schema.sql carries the inline NOT NULL DEFAULT CURRENT_TIMESTAMP on CREATE TABLE.
------------------------------------------------------------
ALTER TABLE strategies ADD COLUMN IF NOT EXISTS created_at TIMESTAMP;
ALTER TABLE strategies ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
UPDATE strategies SET created_at = now() WHERE created_at IS NULL;
UPDATE strategies SET updated_at = now() WHERE updated_at IS NULL;

------------------------------------------------------------
-- (2) perpetual_* strategies (ids 19–22). NON-MANDATORY (absent from v_required_deep_lanes).
-- Seeded via the v0.28 GUARDED UPSERT: a re-seed of an unchanged row is a no-op (created_at +
-- updated_at preserved); a real description/version change moves updated_at only.
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (19, 'perpetual_dmn_generate',     'Perpetual Loop generation register (NON-MANDATORY — deliberately NOT in v_required_deep_lanes). Runs the existing Agent Sweep S2 / Phase 1 Hunt agents in an explicit DIVERGENT register: mandatory divergence, cross-domain analogy, surface unproven hunches, and FREE re-litigation of previously-refuted leads when a new angle/analogy/ledger signal justifies another look. "A round emitting only safe, already-known candidates has malfunctioned." This is the ONLY place the divergent flavor lives; Salience + Executive stay strictly sober. Emits suspicious_points / gr_findings(candidate) candidates for the round. See references/methodology/perpetual-loop-mode.md.', 1),
  (20, 'perpetual_salience_promote', 'Perpetual Loop salience gate (NON-MANDATORY, sober). Ranks the round''s divergent candidates by promise = novelty × est_severity × reachability_prior × ledger_history_factor and promotes the top-K. Implemented as the READ-TIME view v_promise_ranked derived from existing suspicious_point_factor / gr_findings columns — NO new tables, mirroring the v_suspicious_points_ranked / v_critical_fn_ranked never-store rule. See references/methodology/perpetual-loop-mode.md.', 1),
  (21, 'perpetual_executive_pursue', 'Perpetual Loop executive lane (NON-MANDATORY, sober). Pursues each promoted candidate to a verdict by REUSING the existing Phase 2 five-gate Confirm (refute-by-default, references/v2/confirmation-rigor-doctrine.md) + L5 PoC constraints (zero-mocking, vanilla real PoC). NO new confirm path is built — a HIGH/CRIT confirmation here counts toward the loop''s N target. See references/methodology/perpetual-loop-mode.md.', 1),
  (22, 'perpetual_ledger_learn',     'Perpetual Loop learning ledger (NON-MANDATORY, sober). IS the existing round_ledger + round feed-forward + recurrence_counter — no new ledger table. Per-attack-class/region hit-miss biases the NEXT Core round (down-weight exhausted families, surface under-explored regions); this ledger down-weighting is the loop''s only damper. The loop self-fires across turns via ScheduleWakeup and is unbounded until N HIGH/CRIT confirmed (default 20, overridable) or user interrupt; dry rounds are reported, not halting. See references/methodology/perpetual-loop-mode.md.', 1)
ON CONFLICT (name) DO UPDATE SET
  description = excluded.description,
  version = excluded.version,
  updated_at = now()  -- DuckDB v1.1.3 parses a bare CURRENT_TIMESTAMP in DO UPDATE SET as a column ref; now() is the function form
WHERE strategies.description IS DISTINCT FROM excluded.description
   OR strategies.version IS DISTINCT FROM excluded.version;

------------------------------------------------------------
-- (3) v_promise_ranked — Perpetual Loop SALIENCE GATE. Read-time within-round percentile
-- ranking of the round's divergent candidates by promise. NO stored score, NO new table.
-- The four promise factors are derived from existing columns:
--   • novelty            ← suspicious_points: NOT yet graduated AND low merge count
--                          (1/dedup_cluster_size; graduated => 0 — the loop wants new ground).
--   • est_severity       ← suspicious_point_factor.raw_value WHERE factor_name='dangerous_sink_class'
--                          (the only pre-Confirm severity proxy stored; true severity is set
--                          later by Confirm/Proof on gr_findings).
--   • reachability_prior ← suspicious_point_factor.raw_value WHERE factor_name='reachable_from_entry'.
--   • ledger_history_factor ← suspicious_point_factor.raw_value WHERE factor_name='factor_recurrence_prior'
--                          (the round-feed-forward / round_ledger recurrence signal — the
--                          ledger-bias input; no new ledger column).
-- Each factor is percentile-ranked within (target_id, round_id); degenerate population
-- (n<=1) → neutral 0.5; a missing factor row → neutral 0.5 (never silently floored to 0).
-- Identical to db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_promise_ranked AS
WITH base AS (
  SELECT
    sp.id AS sp_id,
    sp.target_id,
    sp.round_id,
    sp.symbol_path,
    sp.vuln_class,
    sp.lane,
    sp.graduated_finding_id,
    CASE WHEN sp.graduated_finding_id IS NOT NULL THEN 0.0
         ELSE 1.0 / GREATEST(COALESCE(sp.dedup_cluster_size, 1), 1) END AS novelty_raw,
    MAX(CASE WHEN spf.factor_name = 'dangerous_sink_class'    THEN spf.raw_value END) AS est_severity_raw,
    MAX(CASE WHEN spf.factor_name = 'reachable_from_entry'    THEN spf.raw_value END) AS reachability_raw,
    MAX(CASE WHEN spf.factor_name = 'factor_recurrence_prior' THEN spf.raw_value END) AS ledger_raw
  FROM suspicious_points sp
  LEFT JOIN suspicious_point_factor spf ON spf.sp_id = sp.id
  GROUP BY sp.id, sp.target_id, sp.round_id, sp.symbol_path, sp.vuln_class,
           sp.lane, sp.graduated_finding_id, sp.dedup_cluster_size
),
ranked AS (
  SELECT
    *,
    PERCENT_RANK() OVER (PARTITION BY target_id, round_id ORDER BY novelty_raw)                  AS novelty_pr,
    PERCENT_RANK() OVER (PARTITION BY target_id, round_id ORDER BY COALESCE(est_severity_raw, 0)) AS severity_pr,
    PERCENT_RANK() OVER (PARTITION BY target_id, round_id ORDER BY COALESCE(reachability_raw, 0)) AS reach_pr,
    PERCENT_RANK() OVER (PARTITION BY target_id, round_id ORDER BY COALESCE(ledger_raw, 0))       AS ledger_pr,
    COUNT(*) OVER (PARTITION BY target_id, round_id) AS pop_n
  FROM base
)
SELECT
  sp_id,
  target_id,
  round_id,
  symbol_path,
  vuln_class,
  lane,
  graduated_finding_id,
  (CASE WHEN pop_n <= 1 THEN 0.5 ELSE novelty_pr  END) AS novelty,
  (CASE WHEN pop_n <= 1 THEN 0.5 ELSE severity_pr END) AS est_severity,
  (CASE WHEN pop_n <= 1 THEN 0.5 ELSE reach_pr    END) AS reachability_prior,
  (CASE WHEN pop_n <= 1 THEN 0.5 ELSE ledger_pr   END) AS ledger_history_factor,
  (CASE WHEN pop_n <= 1 THEN 0.5 ELSE novelty_pr  END)
    * (CASE WHEN pop_n <= 1 THEN 0.5 ELSE severity_pr END)
    * (CASE WHEN pop_n <= 1 THEN 0.5 ELSE reach_pr    END)
    * (CASE WHEN pop_n <= 1 THEN 0.5 ELSE ledger_pr   END) AS promise
FROM ranked
ORDER BY promise DESC, sp_id;

INSERT INTO schema_version (version, description)
VALUES (21, 'Perpetual Loop mode: self-firing unbounded discovery loop (DMN generate → Salience promote → Executive pursue → Confirm → Learn) as a thin reuse layer — strategies.created_at/updated_at (guarded-upsert seed; DuckDB v1.1.3 has no triggers) + v_promise_ranked read-time salience view (promise = novelty × est_severity × reachability_prior × ledger_history_factor, derived from existing columns, no new table) + four NON-MANDATORY strategy rows (ids 19–22, absent from v_required_deep_lanes per the cpg_coverage precedent). Executive REUSES Phase 2 Confirm + L5; Learn IS round_ledger + recurrence_counter.')
ON CONFLICT DO NOTHING;
