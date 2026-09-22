-- vuln-research migration 0020 — per-target memory & recall
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: read-side / derivation only. No new table, no new write-path, no new
-- insertable table. The storage layer (single-writer, append-only, content-hash
-- idempotency, parameterized reads) is unchanged. Net additions:
--   (1) scoring_config seed rows — five new rows under the EXISTING
--       scope='recurrence' (no CHECK widen). Keys: w_rec / w_outcome / w_reuse /
--       w_conf (hit-score weights) + approx_recall_floor (similarity gate).
--   (2) v_fact_hitscore — composite hit-score VIEW over agent_observations +
--       recurrence_counter + gr_findings + defense_bypasses. Fully derived.
--       Fetch (3) reads ORDER BY hit_score DESC so budget truncation keeps the
--       objectively-most-useful rows instead of arbitrary ones.
--   (3) v_fact_similar — trigram-Jaccard approximate-recall VIEW over the
--       per-target reusable fact set. Deterministic SQL only (list_distinct /
--       list_intersect / list_concat); no embeddings, no external model.
--       Threshold from scoring_config approx_recall_floor.
--
-- FRESH-TABLE NOTE: no new table is created; both objects are CREATE OR REPLACE
-- VIEW, which DuckDB replaces idempotently. The scoring_config INSERT uses
-- ON CONFLICT DO NOTHING (scope, config_key UNIQUE — no collisions with existing
-- recurrence row w_nbr, id=11). IDs 12–16 are the new rows.
--
-- ORDERING: scoring_config (0005), agent_observations (0001), recurrence_counter
-- (0005), gr_findings (0001), defense_bypasses (0001) all exist prior, so the
-- new VIEWs' table references resolve cleanly. db/schema.sql carries identical
-- definitions for the fresh-DB path.

------------------------------------------------------------
-- (1) scoring_config seed — hit-score weights + approx_recall_floor.
-- All under scope='recurrence' (the existing scope; no CHECK widen needed).
-- w_rec is dominant (0.50); sum of signal weights = 1.00 as convention.
-- Weights documented individually — see also db/seed/scoring.yml.
------------------------------------------------------------
INSERT INTO scoring_config (id, scope, config_key, weight, description) VALUES
  (12, 'recurrence', 'w_rec',               0.50, 'v_fact_hitscore: recurrence_norm weight (dominant — within-target percentile of corroboration count + recurrence_counter)'),
  (13, 'recurrence', 'w_outcome',           0.25, 'v_fact_hitscore: led_to_outcome weight — fact symbol_path lies on lineage of a confirmed gr_findings or reproduced defense_bypasses'),
  (14, 'recurrence', 'w_reuse',             0.15, 'v_fact_hitscore: reuse_effectiveness weight — dead_end seeded into a round whose symbol_path was NOT re-walked that round (absence of re-walk rows)'),
  (15, 'recurrence', 'w_conf',              0.10, 'v_fact_hitscore: confidence_decayed weight — agent_observations.confidence decayed by rounds since last corroboration'),
  (16, 'recurrence', 'approx_recall_floor', 0.40, 'v_fact_similar: minimum Jaccard similarity floor for approximate-recall inclusion (0.0=off, 1.0=exact-only); tunable per target via UPDATE')
ON CONFLICT DO NOTHING;

------------------------------------------------------------
-- (2) v_fact_hitscore — composite hit-score ranking over reusable facts.
-- Weights from scoring_config scope='recurrence' (same CTE pattern as
-- v_critical_fn_ranked). See db/schema.sql for full column rationale.
-- Identical to db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_fact_hitscore AS
WITH
-- Weight vector from scoring_config scope='recurrence' (same pattern as v_critical_fn_ranked).
w AS (
  SELECT
    MAX(weight) FILTER (WHERE config_key = 'w_rec')     AS w_rec,
    MAX(weight) FILTER (WHERE config_key = 'w_outcome') AS w_outcome,
    MAX(weight) FILTER (WHERE config_key = 'w_reuse')   AS w_reuse,
    MAX(weight) FILTER (WHERE config_key = 'w_conf')    AS w_conf
  FROM scoring_config WHERE scope = 'recurrence'
),
-- Base: one row per (target_id, symbol_path) for reusable observations.
-- corroboration_count = distinct agent_steps that independently logged the same symbol_path.
-- rc_counter = recurrence_counter.counter for the same symbol_path (0 if absent).
base AS (
  SELECT
    ao.target_id,
    ao.symbol_path,
    ao.obs_kind,
    COUNT(DISTINCT ao.agent_step_id)        AS corroboration_count,
    MAX(ao.confidence)                       AS max_confidence,
    MAX(st.round_id)                         AS last_round_id,
    COALESCE(MAX(rc.counter), 0)             AS rc_counter
  FROM agent_observations ao
  JOIN agent_steps st  ON st.id = ao.agent_step_id
  LEFT JOIN recurrence_counter rc
         ON rc.target_id = ao.target_id AND rc.symbol_path = ao.symbol_path
  WHERE ao.reusable = TRUE
    AND ao.symbol_path IS NOT NULL
    AND ao.obs_kind IN ('dead_end', 'invariant', 'blind_spot', 'assumption')
  GROUP BY ao.target_id, ao.symbol_path, ao.obs_kind
),
-- Current max round_id per target (for staleness decay denominator).
max_round AS (
  SELECT target_id, MAX(id) AS max_round_id FROM round_ledger GROUP BY target_id
),
-- recurrence_norm: PERCENT_RANK of (corroboration_count + rc_counter) within target.
normed AS (
  SELECT
    b.*,
    PERCENT_RANK() OVER (
      PARTITION BY b.target_id
      ORDER BY (b.corroboration_count + b.rc_counter)
    ) AS recurrence_norm
  FROM base b
),
-- led_to_outcome: 1 if symbol_path is on any confirmed finding or reproduced bypass
-- for this target; 0 otherwise.
outcome AS (
  SELECT DISTINCT target_id, symbol_path FROM (
    SELECT f.target_id, s.symbol_path
    FROM gr_findings f
    JOIN sinks s ON s.id = f.sink_id
    WHERE f.confirmation_status = 'confirmed'
    UNION ALL
    SELECT f.target_id, src.symbol_path
    FROM gr_findings f
    JOIN sources src ON src.id = f.source_id
    WHERE f.confirmation_status = 'confirmed'
    UNION ALL
    SELECT st.target_id, d.symbol_path
    FROM defense_bypasses db2
    JOIN agent_steps st ON st.id = db2.agent_step_id
    JOIN defenses d     ON d.id  = db2.defense_id
    WHERE db2.reproduced = TRUE
  ) t
),
-- reuse_effectiveness: for dead_end rows, 1 if the symbol_path has NO re-walk
-- (no new dead_end or partial_trace) in the same round it was seeded into.
-- A dead_end is "seeded" = its agent_step has a round_id set. Re-walk = a DIFFERENT
-- agent_step in the same round also produced a dead_end/partial_trace on that path.
reuse AS (
  SELECT DISTINCT
    ao.target_id,
    ao.symbol_path,
    1 AS reuse_effective
  FROM agent_observations ao
  JOIN agent_steps st ON st.id = ao.agent_step_id
  WHERE ao.obs_kind = 'dead_end'
    AND ao.reusable = TRUE
    AND ao.symbol_path IS NOT NULL
    AND st.round_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM agent_observations ao2
      JOIN agent_steps st2 ON st2.id = ao2.agent_step_id
      WHERE ao2.target_id   = ao.target_id
        AND ao2.symbol_path = ao.symbol_path
        AND ao2.obs_kind   IN ('dead_end', 'partial_trace')
        AND st2.round_id    = st.round_id
        AND ao2.id         <> ao.id
    )
)
SELECT
  n.target_id,
  n.symbol_path,
  n.obs_kind,
  n.corroboration_count,
  n.rc_counter,
  n.recurrence_norm,
  CASE WHEN o.symbol_path IS NOT NULL THEN 1.0 ELSE 0.0 END          AS led_to_outcome,
  COALESCE(CAST(r.reuse_effective AS REAL), 0.0)                      AS reuse_effectiveness,
  -- confidence_decayed: max_confidence * (1/2)^rounds_since_last
  COALESCE(n.max_confidence, 0.5) *
    POWER(0.5, GREATEST(0,
      COALESCE(mr.max_round_id, n.last_round_id) - COALESCE(n.last_round_id, 0)
    ))                                                                AS confidence_decayed,
  -- hit_score: weighted sum (mirrors v_critical_fn_ranked arithmetic)
  COALESCE(w.w_rec,     0.50) * n.recurrence_norm
  + COALESCE(w.w_outcome, 0.25) * CASE WHEN o.symbol_path IS NOT NULL THEN 1.0 ELSE 0.0 END
  + COALESCE(w.w_reuse,   0.15) * COALESCE(CAST(r.reuse_effective AS REAL), 0.0)
  + COALESCE(w.w_conf,    0.10) *
    ( COALESCE(n.max_confidence, 0.5) *
      POWER(0.5, GREATEST(0,
        COALESCE(mr.max_round_id, n.last_round_id) - COALESCE(n.last_round_id, 0)
      ))
    )                                                                 AS hit_score
FROM normed n
LEFT JOIN outcome o    ON o.target_id = n.target_id AND o.symbol_path = n.symbol_path
LEFT JOIN reuse r      ON r.target_id = n.target_id AND r.symbol_path = n.symbol_path
LEFT JOIN max_round mr ON mr.target_id = n.target_id
CROSS JOIN w;

------------------------------------------------------------
-- (3) v_fact_similar — DB-native trigram-Jaccard approximate recall.
-- Threshold from scoring_config approx_recall_floor (default 0.40).
-- See db/schema.sql for full column rationale. Identical to db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_fact_similar AS
WITH
-- Floor knob from scoring_config.
floor AS (
  SELECT COALESCE(MAX(weight), 0.40) AS approx_recall_floor
  FROM scoring_config WHERE scope = 'recurrence' AND config_key = 'approx_recall_floor'
),
-- Distinct reusable facts with their token list (split on '.').
facts AS (
  SELECT DISTINCT
    ao.target_id,
    ao.symbol_path,
    string_split(ao.symbol_path, '.') AS tokens
  FROM agent_observations ao
  WHERE ao.reusable = TRUE
    AND ao.symbol_path IS NOT NULL
    AND ao.obs_kind IN ('dead_end', 'invariant', 'blind_spot', 'assumption')
),
-- Most recent slice_fingerprint per (target_id, symbol_path) from finding_sightings.
fp AS (
  SELECT
    fs.target_id,
    f.sink_id,
    -- Anchor on the gr_finding's source/sink path; approximate via symbol_path match
    -- through agent_steps -> agent_observations join.
    ao.symbol_path,
    fs.slice_fingerprint
  FROM finding_sightings fs
  JOIN gr_findings f  ON f.finding_hash = fs.finding_hash
  JOIN agent_steps st ON st.id = fs.agent_step_id
  JOIN agent_observations ao
       ON ao.agent_step_id = st.id
      AND ao.symbol_path IS NOT NULL
  WHERE fs.slice_fingerprint IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY fs.target_id, ao.symbol_path
    ORDER BY fs.observed_at DESC
  ) = 1
),
-- Cartesian self-join within target for candidate pairs.
pairs AS (
  SELECT
    a.target_id,
    a.symbol_path  AS symbol_path_a,
    b.symbol_path  AS symbol_path_b,
    a.tokens       AS tokens_a,
    b.tokens       AS tokens_b
  FROM facts a
  JOIN facts b ON b.target_id = a.target_id AND b.symbol_path > a.symbol_path
),
-- Compute path Jaccard and fingerprint match.
scored AS (
  SELECT
    p.target_id,
    p.symbol_path_a,
    p.symbol_path_b,
    -- Path Jaccard: |intersect| / |distinct union|
    CASE
      WHEN len(list_distinct(list_concat(p.tokens_a, p.tokens_b))) = 0 THEN 0.0
      ELSE CAST(len(list_intersect(p.tokens_a, p.tokens_b)) AS REAL) /
           CAST(len(list_distinct(list_concat(p.tokens_a, p.tokens_b))) AS REAL)
    END AS path_jaccard,
    -- Fingerprint match: 1.0 if both facts share the same non-null slice_fingerprint.
    CASE
      WHEN fpa.slice_fingerprint IS NOT NULL
       AND fpa.slice_fingerprint = fpb.slice_fingerprint THEN 1.0
      ELSE 0.0
    END AS fp_match
  FROM pairs p
  LEFT JOIN fp fpa ON fpa.target_id = p.target_id AND fpa.symbol_path = p.symbol_path_a
  LEFT JOIN fp fpb ON fpb.target_id = p.target_id AND fpb.symbol_path = p.symbol_path_b
)
SELECT
  s.target_id,
  s.symbol_path_a,
  s.symbol_path_b,
  s.path_jaccard,
  s.fp_match,
  -- Combined similarity (path dominates 0.7, fingerprint tie-breaks 0.3).
  0.7 * s.path_jaccard + 0.3 * s.fp_match AS similarity
FROM scored s
CROSS JOIN floor fl
WHERE (0.7 * s.path_jaccard + 0.3 * s.fp_match) >= fl.approx_recall_floor
ORDER BY s.target_id, similarity DESC;

INSERT INTO schema_version (version, description)
VALUES (20, 'per-target memory & recall (v0.27.0): v_fact_hitscore composite hit-score ranking over agent_observations+recurrence_counter+gr_findings+defense_bypasses + v_fact_similar trigram-Jaccard approximate-recall view + scoring_config recurrence-scope weight rows (w_rec/w_outcome/w_reuse/w_conf/approx_recall_floor) + fetch(9) refutations feed-forward')
ON CONFLICT DO NOTHING;
