-- vuln-research migration 0005 — knowledge architecture
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: the six DB-native mechanisms crystallized by the 2026-05-22 deep
-- interview (.omc/specs/deep-interview-vr-knowledge-arch.md), layered onto the
-- existing schema with NO breaking change to any prior table:
--   #1 finding-identity   : finding_sightings (commit-independent identity + change trail)
--   #2 recurrence-rank    : recurrence_counter + critical_functions.factor_recurrence_prior
--   #3 codebase-knowledge : weakness_classes + call_edges + v_code_map
--   #4 intelligent-fetch  : scoring_config + v_critical_fn_ranked (rank_score weights externalized)
--   #5 external-knowledge : v_chunk_acceptance (acceptance = sort key, never a gate)
--   #6 db-metalogging     : mutation_log + v_finding_history / v_finding_changes / v_round_diff
--
-- Cross-cutting (per spec): determinism by construction (SQL-computed derivations,
-- weights externalized to scoring_config — operational knobs, never inline magic
-- constants); append-only history (sightings + mutation_log express staleness via
-- newer rows, never delete); content-addressed sidecars reused for >=16 KB fields
-- (mutation_log stores before_sha/after_sha, never the body); single writer (the
-- orchestrator derives every *_hash and flushes per phase under one transaction).
--
-- ORDERING: tables before the views that read them; ALTER on critical_functions
-- is additive. Views use CREATE OR REPLACE so re-apply is clean. db/schema.sql
-- carries the identical definitions for fresh DBs.

------------------------------------------------------------
-- #4/#5/#2 — scoring_config: the single shared weight surface.
-- Externalized operational knobs (NOT semantic constants). Every read-time score
-- (rank_score, acceptance, recurrence neighbor weight) joins these rows, so a
-- weight change reorders results with zero code change. Seeded from db/seed/scoring.yml.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scoring_config (
  id INTEGER PRIMARY KEY,
  scope TEXT NOT NULL
    CHECK (scope IN ('rank_score', 'acceptance', 'recurrence')),
  config_key TEXT NOT NULL,
  weight REAL NOT NULL,
  description TEXT,
  UNIQUE (scope, config_key)
);

INSERT INTO scoring_config (id, scope, config_key, weight, description) VALUES
  -- #4 rank_score: six factors (recurrence is the new 6th); sum = 1.00.
  (1,  'rank_score', 'w_reachability',       0.25, 'critical_functions.factor_reachability'),
  (2,  'rank_score', 'w_blast_radius',       0.22, 'critical_functions.factor_blast_radius'),
  (3,  'rank_score', 'w_privilege_delta',    0.18, 'critical_functions.factor_privilege_delta'),
  (4,  'rank_score', 'w_attention_deficit',  0.13, 'critical_functions.factor_attention_deficit'),
  (5,  'rank_score', 'w_bypass_prior',       0.10, 'critical_functions.factor_bypass_prior'),
  (6,  'rank_score', 'w_recurrence_prior',   0.12, 'critical_functions.factor_recurrence_prior (#2)'),
  -- #5 acceptance: positive signals add, negative signals subtract (signs applied in v_chunk_acceptance); sum = 1.00.
  (7,  'acceptance', 'w_ref_count',          0.40, 'knowledge_acceptance.ref_count (+)'),
  (8,  'acceptance', 'w_growth_rate',        0.20, 'knowledge_acceptance.growth_rate (+)'),
  (9,  'acceptance', 'w_staleness_days',     0.25, 'knowledge_acceptance.staleness_days (-)'),
  (10, 'acceptance', 'w_repeat_suppressions',0.15, 'knowledge_acceptance.repeat_suppressions (-)'),
  -- #2 recurrence: weight applied to a confirmed finding's 1-hop call-neighbors.
  (11, 'recurrence', 'w_nbr',                0.50, 'one-hop call-neighbor propagation weight')
ON CONFLICT DO NOTHING;

------------------------------------------------------------
-- #1 finding-identity — finding_sightings: one append-only row per observation of
-- a finding. finding_hash is commit-independent (derived from the Joern-fullName
-- natural key on gr_findings), so the same vulnerability across commits shares one
-- finding_hash and accrues many sightings. change_scope + changed_from_sighting_id
-- + the from->to triple make "what changed" trivially inspectable (R24).
-- verdict 'needs_attention' = code moved under a confirmed finding and did not
-- cleanly re-confirm; it does NOT move gr_findings.confirmation_status (no flap)
-- and produces no recurrence-counter delta (#2).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS finding_sightings (
  id INTEGER PRIMARY KEY,
  finding_hash TEXT NOT NULL REFERENCES gr_findings(finding_hash),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  agent_step_id INTEGER REFERENCES agent_steps(id),
  commit_sha TEXT NOT NULL,
  body_hash TEXT,                 -- normalized enclosing-fn body hash (local change scope)
  slice_fingerprint TEXT,         -- source->sink function-path fingerprint (non-local change scope)
  verdict TEXT NOT NULL
    CHECK (verdict IN ('candidate', 'confirmed', 'refuted', 'needs_attention')),
  change_scope TEXT
    CHECK (change_scope IS NULL OR change_scope IN ('initial', 'body_hash', 'slice_path', 'both')),
  changed_from_sighting_id INTEGER REFERENCES finding_sightings(id),
  -- from->to provenance triple: the prior sighting's identity, copied in so a
  -- single row tells the whole "moved from X to Y" story without a self-join.
  from_commit_sha TEXT,
  from_body_hash TEXT,
  from_slice_fingerprint TEXT,
  observed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  sighting_hash TEXT NOT NULL,    -- orchestrator-derived; idempotent replay via ON CONFLICT
  UNIQUE (sighting_hash)
);

------------------------------------------------------------
-- #3 codebase-knowledge (3b substrate) — call_edges: the single resolved call /
-- data-flow edge set, reused from Joern's CPG (the same CALL/callIn/callee edges
-- critical-function-hunt walks for factor_blast_radius). Shared substrate for both
-- the v_code_map projection (#3) and recurrence propagation (#2).
-- SOUND UNDER-APPROXIMATION: only RESOLVED edges are ever inserted. An unresolvable
-- call site (cross-repo other half, dynamic/reflective dispatch) emits a blind_spot
-- agent_observation instead of an edge — propagation never crosses a missing edge,
-- so a prior cannot be inflated by a fabricated neighbor.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS call_edges (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  caller_symbol TEXT NOT NULL,    -- Joern fullName
  callee_symbol TEXT NOT NULL,    -- Joern fullName
  edge_kind TEXT NOT NULL
    CHECK (edge_kind IN ('call', 'dataflow')),
  edge_hash TEXT NOT NULL,
  UNIQUE (edge_hash)
);

------------------------------------------------------------
-- #3 codebase-knowledge (3a) — weakness_classes: a systemic-weakness rollup one hop
-- UP from finding_hash. NK = hash(bug_class, sink_category). seen_count = distinct
-- finding sites; `systemic` is a GENERATED (same-row, deterministic) PASSIVE flag
-- at seen_count >= 3 — it is descriptive/reporting only and does NOT drive ranking
-- (ranking influence comes solely from #2's call-graph propagation).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS weakness_classes (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  bug_class TEXT NOT NULL,
  sink_category TEXT NOT NULL,
  seen_count INTEGER NOT NULL DEFAULT 0,    -- distinct finding sites sharing (bug_class, sink_category)
  systemic BOOLEAN GENERATED ALWAYS AS (seen_count >= 3) VIRTUAL,
  wc_hash TEXT NOT NULL,
  UNIQUE (wc_hash)
);

------------------------------------------------------------
-- #2 recurrence-rank — recurrence_counter: the one genuinely materialized accumulator.
-- Confirmation-weighted LIFETIME tally (confirmed +1, candidate +0.3, refuted -1;
-- needs_attention => no delta). No time-decay (kept honest by #1's body-hash freeze).
-- neighbor_boost accrues the one-hop call-graph propagation. Both move via the
-- orchestrator's ON CONFLICT (counter_key) DO UPDATE at flush — never the generic
-- Put path. factor_recurrence_prior on critical_functions is derived from these.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recurrence_counter (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  finding_hash TEXT,              -- the finding this node tracks (NULL for a pure call-neighbor node)
  symbol_path TEXT NOT NULL,      -- Joern fullName anchor (enclosing fn / neighbor)
  counter REAL NOT NULL DEFAULT 0,        -- confirmation-weighted lifetime tally
  neighbor_boost REAL NOT NULL DEFAULT 0, -- accumulated 1-hop propagation from hot neighbors
  last_status TEXT,               -- last status transition applied (audit trail)
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  counter_key TEXT NOT NULL,      -- canonical (target_id | finding_hash | symbol_path)
  UNIQUE (counter_key)
);

------------------------------------------------------------
-- #1 — factor_recurrence_prior: the 6th critical_functions ranking factor, derived
-- from recurrence_counter (norm(self counter) + hot-neighbor boost). Additive column.
------------------------------------------------------------
ALTER TABLE critical_functions ADD COLUMN IF NOT EXISTS factor_recurrence_prior REAL;

------------------------------------------------------------
-- #6 db-metalogging — mutation_log: per-mutation append-only audit row, written in
-- the SAME flush transaction as the mutation it records. SCOPE = in-place UPDATEs +
-- status transitions only (plain inserts are skipped; VIRTUAL generated columns are
-- never logged — only input-factor UPDATEs). delta_json is LITERAL for small fields
-- ({"col","before","after"}) and HASH-REF for >=16 KB sidecar-backed fields
-- ({"col","before_sha","after_sha"}), so rows stay small. Append-only, NO auto-prune.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mutation_log (
  id INTEGER PRIMARY KEY,
  target_id INTEGER REFERENCES targets(id),
  table_name TEXT NOT NULL,
  row_key TEXT NOT NULL,          -- natural-key hash / PK of the mutated row (e.g. finding_hash)
  op TEXT NOT NULL
    CHECK (op IN ('update', 'status_transition')),
  delta_json TEXT NOT NULL,       -- literal small fields, before_sha/after_sha for sidecar-backed
  round_id INTEGER REFERENCES round_ledger(id),
  phase TEXT,
  agent_step_id INTEGER REFERENCES agent_steps(id),
  tx_id TEXT,
  mutated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mutation_hash TEXT NOT NULL,    -- orchestrator-derived; idempotent replay via ON CONFLICT
  UNIQUE (mutation_hash)
);

------------------------------------------------------------
-- #4 intelligent-fetch — v_critical_fn_ranked: rank_score recomputed read-time from
-- the six factors x externalized scoring_config weights (R13 / R23). Replaces the
-- inline magic-constant formula; the stored critical_functions.rank_score column is
-- retained for feed-forward compatibility, but this view is the canonical ranking.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_critical_fn_ranked AS
WITH w AS (
  SELECT
    MAX(weight) FILTER (WHERE config_key = 'w_reachability')      AS w_reach,
    MAX(weight) FILTER (WHERE config_key = 'w_blast_radius')      AS w_blast,
    MAX(weight) FILTER (WHERE config_key = 'w_privilege_delta')   AS w_priv,
    MAX(weight) FILTER (WHERE config_key = 'w_attention_deficit') AS w_attn,
    MAX(weight) FILTER (WHERE config_key = 'w_bypass_prior')      AS w_bypass,
    MAX(weight) FILTER (WHERE config_key = 'w_recurrence_prior')  AS w_recur
  FROM scoring_config WHERE scope = 'rank_score'
)
SELECT
  cf.*,
  COALESCE(cf.factor_reachability, 0)      * w.w_reach
  + COALESCE(cf.factor_blast_radius, 0)     * w.w_blast
  + COALESCE(cf.factor_privilege_delta, 0)  * w.w_priv
  + COALESCE(cf.factor_attention_deficit, 0)* w.w_attn
  + COALESCE(cf.factor_bypass_prior, 0)     * w.w_bypass
  + COALESCE(cf.factor_recurrence_prior, 0) * w.w_recur AS rank_score_computed
FROM critical_functions cf CROSS JOIN w;

------------------------------------------------------------
-- #5 external-knowledge — v_chunk_acceptance: acceptance as a read-time SORT KEY
-- (never a gate). Each signal min-max-normalized against its column max, then blended
-- by externalized weights (positives add, negatives subtract). Uses the newest
-- acceptance row per chunk (append-only; staleness expressed by newer rows).
------------------------------------------------------------
CREATE OR REPLACE VIEW v_chunk_acceptance AS
WITH w AS (
  SELECT
    MAX(weight) FILTER (WHERE config_key = 'w_ref_count')           AS w_ref,
    MAX(weight) FILTER (WHERE config_key = 'w_growth_rate')         AS w_growth,
    MAX(weight) FILTER (WHERE config_key = 'w_staleness_days')      AS w_stale,
    MAX(weight) FILTER (WHERE config_key = 'w_repeat_suppressions') AS w_supp
  FROM scoring_config WHERE scope = 'acceptance'
),
m AS (
  SELECT
    MAX(ref_count)           AS max_ref,
    MAX(growth_rate)         AS max_growth,
    MAX(staleness_days)      AS max_stale,
    MAX(repeat_suppressions) AS max_supp
  FROM knowledge_acceptance
),
latest AS (
  SELECT ka.*
  FROM knowledge_acceptance ka
  JOIN (
    SELECT chunk_id, MAX(decided_at) AS mx FROM knowledge_acceptance GROUP BY chunk_id
  ) t ON t.chunk_id = ka.chunk_id AND t.mx = ka.decided_at
)
SELECT
  c.id AS chunk_id, c.source, c.chunk_key, c.version,
  ( w.w_ref    * COALESCE(la.ref_count, 0)           / NULLIF(m.max_ref, 0)
  + w.w_growth * COALESCE(la.growth_rate, 0)         / NULLIF(m.max_growth, 0)
  - w.w_stale  * COALESCE(la.staleness_days, 0)      / NULLIF(m.max_stale, 0)
  - w.w_supp   * COALESCE(la.repeat_suppressions, 0) / NULLIF(m.max_supp, 0)
  ) AS acceptance_score
FROM knowledge_chunks c
LEFT JOIN latest la ON la.chunk_id = c.id
CROSS JOIN w CROSS JOIN m;

------------------------------------------------------------
-- #3 codebase-knowledge — v_code_map: the structural code map as a byproduct
-- projection. Critical functions joined to their outgoing resolved call edges.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_code_map AS
SELECT
  cf.target_id,
  cf.symbol_path,
  cf.cf_category,
  cf.rank_tier,
  ce.callee_symbol,
  ce.edge_kind
FROM critical_functions cf
LEFT JOIN call_edges ce
  ON ce.target_id = cf.target_id AND ce.caller_symbol = cf.symbol_path;

------------------------------------------------------------
-- #6 db-metalogging — inspection views. v_finding_history unifies #1's sighting
-- change-timeline with #6's gr_findings mutations into one per-finding stream;
-- v_finding_changes surfaces only sightings where the code moved; v_round_diff
-- rolls mutations up per round for a coarse "what did this round change" diff.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_finding_history AS
SELECT
  fs.finding_hash,
  'sighting'                 AS event_kind,
  fs.observed_at             AS event_at,
  fs.commit_sha,
  fs.verdict,
  fs.change_scope,
  fs.changed_from_sighting_id,
  CAST(NULL AS TEXT)         AS op,
  CAST(NULL AS TEXT)         AS delta_json
FROM finding_sightings fs
UNION ALL
SELECT
  ml.row_key                 AS finding_hash,
  'mutation'                 AS event_kind,
  ml.mutated_at              AS event_at,
  CAST(NULL AS TEXT)         AS commit_sha,
  CAST(NULL AS TEXT)         AS verdict,
  CAST(NULL AS TEXT)         AS change_scope,
  CAST(NULL AS INTEGER)      AS changed_from_sighting_id,
  ml.op,
  ml.delta_json
FROM mutation_log ml
WHERE ml.table_name = 'gr_findings';

CREATE OR REPLACE VIEW v_finding_changes AS
SELECT
  finding_hash,
  commit_sha,
  change_scope,
  changed_from_sighting_id,
  from_commit_sha, from_body_hash, from_slice_fingerprint,
  body_hash, slice_fingerprint,
  observed_at
FROM finding_sightings
WHERE change_scope IS NOT NULL AND change_scope <> 'initial';

CREATE OR REPLACE VIEW v_round_diff AS
SELECT
  round_id,
  table_name,
  op,
  COUNT(*)        AS n_mutations,
  MIN(mutated_at) AS first_at,
  MAX(mutated_at) AS last_at
FROM mutation_log
GROUP BY round_id, table_name, op;

INSERT INTO schema_version (version, description)
VALUES (5, 'knowledge architecture: finding_sightings / recurrence_counter / weakness_classes / call_edges / scoring_config / mutation_log + ranking/acceptance/history views')
ON CONFLICT DO NOTHING;
