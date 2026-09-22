-- vuln-research migration 0029 — justification gate + DB hardening (v0.40.0, TIER 2 T2-01..T2-16)
--
-- Forward-only, idempotent. Safe to re-apply (CREATE … IF NOT EXISTS / ADD COLUMN IF NOT
-- EXISTS / CREATE OR REPLACE VIEW + INSERT … ON CONFLICT DO NOTHING throughout). schema_version
-- 28 -> 29.
--
-- PURPOSE: the pre-v0.40 DEEP completion gate encoded PROCESS-coverage only (a required lane
-- ran, a phase logged >=1 row, defenses enumerated). A campaign that executed every lane and
-- confirmed ZERO justified findings was GREEN, and any lane could Put a born-'confirmed' row the
-- gate counted without re-deriving (the Zuul false-green + the 10->33 inflation). This migration
-- adds the OUTCOME-justification layer: a justification gate, a consumer-harm ledger, a hard
-- closure barrier, a consumed-ranking record, plus the id-integrity / content-dedup hardening
-- the data-layer critique (S-D01..S-D12) called for. It expresses the SAME 16 objects the
-- canonical db/schema.sql carries (the applied artifact) as forward DDL for the test chain.
--
-- OBJECTS (TIER 2 IDs):
--   T2-01  v_promotion_coverage            view  JUSTIFIED|UNJUSTIFIED per confirmed finding
--   T2-02  v_phase_status (REDEFINED)       view  tri-state not_run|incomplete|complete
--   T2-03  confirmed_without_promotion_provenance  v_coverage metric (RED >0)
--   T2-04  ranked_sps_never_consumed                v_coverage metric (RED >0)
--   T2-05  roster_steps_missing_for_current_round   v_coverage metric (RED >0)
--   T2-06  v_sp_oracle_coverage             view (HARD-RED)  kept SP w/ oracle, no execution => RED
--   T2-07  impact_proofs + v_justification_coverage  table + view (consumer-harm gate)
--   T2-08  closures                         table  hard pre-spawn barrier
--   T2-09  sp_spawn_decisions               table  the ranking becomes a CONSUMED artifact
--   T2-10  per-table sequences              DDL    CREATE SEQUENCE + id DEFAULT nextval(...)
--   T2-11  round-keyed roster sentinel      policy step_hash='plan-roster-<lane>-r<round_id>'
--   T2-12  gr_findings.confirmation_rigor_tier  column  shallow|independent|reproduced
--   T2-13  content_fingerprint              column  on every hash-keyed/NK-deduped table
--   T2-14  v_invariant_promotion_coverage   view (HARD-RED)  the learning-loop gate
--   T2-15  v_empty_result (EMPTY_RESULT)    view   the named empty-campaign terminal
--   T2-16  CHECK(id>0) / CHECK(col IS NULL OR col>0)  constraints  kill the magic-zero FK sentinel
--
-- DuckDB v1.1.3 has NO triggers/procedures (schema.sql top). These objects are views / tables /
-- columns / sequences ONLY; the WRITE-side enforcement (the `vrdb promote` / `close-step` /
-- content-checked-dedup verbs that make 'confirmed' reachable ONLY through the five-gate promote
-- path) is the Go harness's job (TIER 3) — a view cannot reject a write on DuckDB 1.1.3.
--
-- DuckDB-ALTER CAVEATS (what "only applies to a fresh v2 DB" vs the upgrade path):
--   • CHECK(id>0) / CHECK(col>0) (T2-16): DuckDB v1.1.3 CANNOT add a CHECK to an EXISTING column
--     in place (the 0009/0019 FK-CHECK-widening precedent). The NEW tables created here
--     (impact_proofs, closures, sp_spawn_decisions) carry the inline CHECK(id>0)/CHECK(col>0)
--     directly because their CREATE is fresh. The PRE-EXISTING tables (built by migrations
--     0001..0028) keep their original id columns; their CHECK(id>0) lives ONLY in the canonical
--     fresh-DB schema.sql — it is NOT retro-added here (it cannot be). On a fresh v2 build from
--     schema.sql every PK/FK carries the CHECK; on the migration upgrade path only the new
--     tables do, and the harness pre-validates the rest (put.go fkRefs).
--   • DEFAULT nextval(...) (T2-10): ALTER TABLE … ALTER COLUMN id SET DEFAULT is ADDITIVE and
--     works on the upgrade path; the DEFAULT only fires for inserts that OMIT id (the harness MAY
--     still pass an explicit id, so this is back-compat).
--   • confirmation_rigor_tier (T2-12): ADDED here with NO inline CHECK (DuckDB cannot widen the
--     inline CHECK on the upgrade path — the 0024 precedent). The CHECK
--     (IN ('shallow','independent','reproduced')) lives in the fresh-DB schema.sql and is enforced
--     app-side / by the `vrdb promote` verb on the upgrade path. This migration inserts no row.
--   • content_fingerprint (T2-13): pure ADD COLUMN IF NOT EXISTS TEXT (NULL-permitting, non-
--     unique) — additive on both paths.
--
-- ORDERING: applies AFTER 0028. The new tables FK gr_findings / targets / round_ledger /
-- suspicious_points (all created by 0001..0010), so the chain order is FK-safe. v_phase_status and
-- v_coverage are RESTATED IN FULL here (carrying every prior metric forward plus the new ones) so
-- CREATE OR REPLACE is idempotent and matches schema.sql byte-for-byte. db/schema.sql carries the
-- identical definitions (schema_mirror parity).

------------------------------------------------------------
-- (1) NEW TABLES + per-table SEQUENCES + content_fingerprint retrofit (T2-07/08/09/10/13/16).
-- Lifted verbatim from db/schema.sql so the two stay byte-aligned.
------------------------------------------------------------

------------------------------------------------------------
-- impact_proofs (v0.40.0, migration 0029, T2-07 / S-P02/S-P04/S-V11). The
-- CONSUMER-HARM ledger: one row per confirmed finding naming the default-config
-- component that READS / DISPATCHES / TRUSTS the tainted value and the harm it
-- suffers. A sink reached is NOT a consumer harmed (Gate 5 doctrine, T1-02): a
-- confirmed finding with NO impact_proofs row is UNJUSTIFIED (v_justification_coverage,
-- v_promotion_coverage). severity is a CONTRACT, not an automatic function: the Confirm agent
-- MUST DERIVE severity from the exploitability-gate rubric over this proof's
-- harm_class × proven_reachability × mechanism_cap and RECORD that derivation in severity_basis
-- (the harness does not compute severity — it records the agent-derived rating + its basis).
--   • consumer_symbol      — the default-config component harmed (sink-less authz/IDOR
--                            classes name the privileged operation reached past the guard).
--   • harm_class           — open vocab (rce|info_leak|dos|authz_bypass|ssrf|data_tamper|…);
--                            free TEXT because the harm taxonomy evolves per attack domain.
--   • reachability_evidence_ref — pointer (observation/slice/critical_fn_reach/PoC id) proving
--                            the consumer is reachable under default config.
--   • proven_reachability  — closed tri-state: how strong the reachability evidence is.
--   • mechanism_cap        — closed vocab: the build-hardening ceiling on the primitive
--                            (dos_only = hardened-allocator/bounds-checked container/sanitizer
--                            abort caps memory-unsafety at DoS; leak = raw-pointer/memcpy/linear
--                            write retains info-leak; write_what_where = proven arbitrary write;
--                            none = no mechanism cap applies, e.g. logic/authz classes).
--   • severity_basis       — free-TEXT note recording how severity was derived from the rubric.
-- DuckDB cannot widen the inline CHECKs on the upgrade path, so migration 0029 creates the
-- table with the same inline CHECKs ONLY on a fresh v2 DB (the table is NEW, so the fresh
-- CREATE carries them in both schema.sql and the migration).
------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_impact_proofs START 1;
CREATE TABLE IF NOT EXISTS impact_proofs (
  id INTEGER PRIMARY KEY DEFAULT nextval('seq_impact_proofs') CHECK (id > 0),
  finding_id INTEGER NOT NULL REFERENCES gr_findings(id) CHECK (finding_id > 0),
  consumer_symbol TEXT NOT NULL,             -- default-config component that reads/dispatches/trusts the value
  harm_class TEXT NOT NULL,                  -- OPEN vocab: rce|info_leak|dos|authz_bypass|ssrf|data_tamper|...
  reachability_evidence_ref TEXT,            -- pointer proving the consumer is reachable under default config
  proven_reachability TEXT
    CHECK (proven_reachability IS NULL OR proven_reachability IN ('proven', 'conditional', 'unproven')),
  mechanism_cap TEXT
    CHECK (mechanism_cap IS NULL OR mechanism_cap IN ('dos_only', 'leak', 'write_what_where', 'none')),
  severity_basis TEXT,                       -- free-TEXT note: how severity was derived from the rubric
  content_fingerprint TEXT,                  -- sha256 of the semantic row (non-unique; content-checked dedup, T2-13)
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  proof_hash TEXT NOT NULL,                  -- idempotency / dedup natural key
  UNIQUE (proof_hash)
);

------------------------------------------------------------
-- closures (v0.40.0, migration 0029, T2-08 / S-P09, NEW-4). The hard pre-spawn
-- BARRIER: a typed, durable record that a surface is closed, consulted by Phase 0.5
-- roster materialization (T1-06). A lane targeting an open closure whose reopen_condition
-- has NOT fired is scheduled 'skipped', not run — closure is a scheduling constraint, not
-- advice. Re-opening requires the reopen_condition to FIRE (e.g. the code under the slice
-- moved), never an LLM's discretion. The negative-result stopping rule (T1-13) writes a
-- closures row after N clean attempts on a channel so sunk-cost escalation stops.
--   • surface_hash    — stable hash of the closed surface (symbol/region/strategy-family).
--   • closure_kind    — closed tri-vocab: dead_end | exhausted | refuted_class.
--   • closed_in_round — the round_ledger row that closed it (feed-forward provenance).
--   • reopen_condition — free TEXT: the concrete fact that must fire to reopen (e.g.
--                        'code under src/x moved since <sha>'); NULL = permanently closed.
------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_closures START 1;
CREATE TABLE IF NOT EXISTS closures (
  id INTEGER PRIMARY KEY DEFAULT nextval('seq_closures') CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id) CHECK (target_id > 0),
  surface_hash TEXT NOT NULL,                -- stable hash of the closed surface
  closure_kind TEXT NOT NULL
    CHECK (closure_kind IN ('dead_end', 'exhausted', 'refuted_class')),
  closed_in_round INTEGER REFERENCES round_ledger(id) CHECK (closed_in_round IS NULL OR closed_in_round > 0),
  reopen_condition TEXT,                      -- free TEXT: fact that must fire to reopen; NULL = permanent
  evidence_ref TEXT,                          -- pointer to the attempts/observations that justified closure
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (target_id, surface_hash, closure_kind)   -- NK: one closure per (target, surface, kind)
);

------------------------------------------------------------
-- sp_spawn_decisions (v0.40.0, migration 0029, T2-09 / S-D03). Makes the SP ranking a
-- CONSUMED artifact: the orchestrator MUST write one row each time it picks (or declines)
-- a lane for a suspicious_point in a round. Without this, v_suspicious_points_ranked is a
-- read-time sort key wired to no spawn decision — the ranking has zero effect unless some
-- agent voluntarily queries it. The v_coverage.ranked_sps_never_consumed metric (T2-04)
-- goes RED when a gate_ok top-K SP in a round has no decision row, surfacing an unconsumed
-- ranking. rank_at_decision snapshots the composite rank at pick time (the score is never
-- stored on suspicious_points; this is the only persisted rank trace).
------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_sp_spawn_decisions START 1;
CREATE TABLE IF NOT EXISTS sp_spawn_decisions (
  id INTEGER PRIMARY KEY DEFAULT nextval('seq_sp_spawn_decisions') CHECK (id > 0),
  sp_id INTEGER NOT NULL REFERENCES suspicious_points(id) CHECK (sp_id > 0),
  round_id INTEGER REFERENCES round_ledger(id) CHECK (round_id IS NULL OR round_id > 0),
  rank_at_decision INTEGER,                   -- composite rank snapshot at pick time (1 = top)
  spawned BOOLEAN NOT NULL,                   -- TRUE = a lane was spawned for this SP; FALSE = declined
  decided_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (sp_id, round_id)                    -- NK: one decision per (SP, round)
);

------------------------------------------------------------
-- Per-table sequences (v0.40.0, migration 0029, T2-10 / S-D04, S-D08) + content_fingerprint
-- (T2-13 / S-D07). Two ADDITIVE retrofits to the existing tables, applied after every
-- CREATE TABLE above so the targets exist:
--
--   (1) SEQUENCES. Each id PK gets its own DuckDB sequence and a DEFAULT nextval(...), so
--       the harness no longer needs the app-side COALESCE(MAX(id),0)+1 read (Tier 3 T3-08)
--       whose concurrent-reader race silently DROPS rows under ON CONFLICT DO NOTHING. Each
--       table gets its OWN id-space, so a transposed id from another table is far more likely
--       out-of-range and caught by FK pre-validation. The DEFAULT only fires for inserts that
--       OMIT id; the harness still MAY pass an explicit id (back-compat), so this is purely
--       additive. DuckDB ≥0.9 supports CREATE SEQUENCE + ALTER COLUMN … SET DEFAULT; both are
--       additive DDL that works on a fresh build AND (per migration 0029) on the upgrade path.
--   (2) content_fingerprint. sha256 of the full SEMANTIC row (NON-unique), so the harness can,
--       on an ON CONFLICT against a *_hash / NK, COMPARE bodies and REJECT a hash-collision
--       whose content differs (Tier 3 T3-04) instead of silently DROPPING a distinct bug
--       (the "3 crashes → 1 row" over-dedup). Added to every hash-keyed table. NULL-permitting
--       (the harness fills it; legacy rows stay NULL). Purely additive ADD COLUMN.
--
-- NK-only tables without a *_hash column (suspicious_points uses a composite NK) still get a
-- fingerprint so the content-checked-dedup path is uniform.
------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_targets START 1;
ALTER TABLE targets ALTER COLUMN id SET DEFAULT nextval('seq_targets');
CREATE SEQUENCE IF NOT EXISTS seq_round_ledger START 1;
ALTER TABLE round_ledger ALTER COLUMN id SET DEFAULT nextval('seq_round_ledger');
CREATE SEQUENCE IF NOT EXISTS seq_sources START 1;
ALTER TABLE sources ALTER COLUMN id SET DEFAULT nextval('seq_sources');
CREATE SEQUENCE IF NOT EXISTS seq_sinks START 1;
ALTER TABLE sinks ALTER COLUMN id SET DEFAULT nextval('seq_sinks');
CREATE SEQUENCE IF NOT EXISTS seq_defenses START 1;
ALTER TABLE defenses ALTER COLUMN id SET DEFAULT nextval('seq_defenses');
CREATE SEQUENCE IF NOT EXISTS seq_regexes START 1;
ALTER TABLE regexes ALTER COLUMN id SET DEFAULT nextval('seq_regexes');
CREATE SEQUENCE IF NOT EXISTS seq_critical_functions START 1;
ALTER TABLE critical_functions ALTER COLUMN id SET DEFAULT nextval('seq_critical_functions');
CREATE SEQUENCE IF NOT EXISTS seq_strategies START 1;
ALTER TABLE strategies ALTER COLUMN id SET DEFAULT nextval('seq_strategies');
CREATE SEQUENCE IF NOT EXISTS seq_input_slices START 1;
ALTER TABLE input_slices ALTER COLUMN id SET DEFAULT nextval('seq_input_slices');
CREATE SEQUENCE IF NOT EXISTS seq_critical_fn_reach START 1;
ALTER TABLE critical_fn_reach ALTER COLUMN id SET DEFAULT nextval('seq_critical_fn_reach');
CREATE SEQUENCE IF NOT EXISTS seq_intended_feature_classification START 1;
ALTER TABLE intended_feature_classification ALTER COLUMN id SET DEFAULT nextval('seq_intended_feature_classification');
CREATE SEQUENCE IF NOT EXISTS seq_agent_steps START 1;
ALTER TABLE agent_steps ALTER COLUMN id SET DEFAULT nextval('seq_agent_steps');
CREATE SEQUENCE IF NOT EXISTS seq_agent_observations START 1;
ALTER TABLE agent_observations ALTER COLUMN id SET DEFAULT nextval('seq_agent_observations');
CREATE SEQUENCE IF NOT EXISTS seq_query_attempts START 1;
ALTER TABLE query_attempts ALTER COLUMN id SET DEFAULT nextval('seq_query_attempts');
CREATE SEQUENCE IF NOT EXISTS seq_cpg_slice_coverage START 1;
ALTER TABLE cpg_slice_coverage ALTER COLUMN id SET DEFAULT nextval('seq_cpg_slice_coverage');
CREATE SEQUENCE IF NOT EXISTS seq_methodology_blind_spots START 1;
ALTER TABLE methodology_blind_spots ALTER COLUMN id SET DEFAULT nextval('seq_methodology_blind_spots');
CREATE SEQUENCE IF NOT EXISTS seq_phase0_priorities START 1;
ALTER TABLE phase0_priorities ALTER COLUMN id SET DEFAULT nextval('seq_phase0_priorities');
CREATE SEQUENCE IF NOT EXISTS seq_gr_findings START 1;
ALTER TABLE gr_findings ALTER COLUMN id SET DEFAULT nextval('seq_gr_findings');
CREATE SEQUENCE IF NOT EXISTS seq_suspicious_points START 1;
ALTER TABLE suspicious_points ALTER COLUMN id SET DEFAULT nextval('seq_suspicious_points');
CREATE SEQUENCE IF NOT EXISTS seq_suspicious_point_factor START 1;
ALTER TABLE suspicious_point_factor ALTER COLUMN id SET DEFAULT nextval('seq_suspicious_point_factor');
CREATE SEQUENCE IF NOT EXISTS seq_cves START 1;
ALTER TABLE cves ALTER COLUMN id SET DEFAULT nextval('seq_cves');
CREATE SEQUENCE IF NOT EXISTS seq_writeups START 1;
ALTER TABLE writeups ALTER COLUMN id SET DEFAULT nextval('seq_writeups');
CREATE SEQUENCE IF NOT EXISTS seq_promising_lanes START 1;
ALTER TABLE promising_lanes ALTER COLUMN id SET DEFAULT nextval('seq_promising_lanes');
CREATE SEQUENCE IF NOT EXISTS seq_file_vuln_ratings START 1;
ALTER TABLE file_vuln_ratings ALTER COLUMN id SET DEFAULT nextval('seq_file_vuln_ratings');
CREATE SEQUENCE IF NOT EXISTS seq_refutations START 1;
ALTER TABLE refutations ALTER COLUMN id SET DEFAULT nextval('seq_refutations');
CREATE SEQUENCE IF NOT EXISTS seq_audit_outcomes START 1;
ALTER TABLE audit_outcomes ALTER COLUMN id SET DEFAULT nextval('seq_audit_outcomes');
CREATE SEQUENCE IF NOT EXISTS seq_critic_findings START 1;
ALTER TABLE critic_findings ALTER COLUMN id SET DEFAULT nextval('seq_critic_findings');
CREATE SEQUENCE IF NOT EXISTS seq_defense_bypasses START 1;
ALTER TABLE defense_bypasses ALTER COLUMN id SET DEFAULT nextval('seq_defense_bypasses');
CREATE SEQUENCE IF NOT EXISTS seq_sanitizer_bypass_runs START 1;
ALTER TABLE sanitizer_bypass_runs ALTER COLUMN id SET DEFAULT nextval('seq_sanitizer_bypass_runs');
CREATE SEQUENCE IF NOT EXISTS seq_fuzz_runs START 1;
ALTER TABLE fuzz_runs ALTER COLUMN id SET DEFAULT nextval('seq_fuzz_runs');
CREATE SEQUENCE IF NOT EXISTS seq_fuzz_artifacts START 1;
ALTER TABLE fuzz_artifacts ALTER COLUMN id SET DEFAULT nextval('seq_fuzz_artifacts');
CREATE SEQUENCE IF NOT EXISTS seq_knowledge_chunks START 1;
ALTER TABLE knowledge_chunks ALTER COLUMN id SET DEFAULT nextval('seq_knowledge_chunks');
CREATE SEQUENCE IF NOT EXISTS seq_knowledge_seed_log START 1;
ALTER TABLE knowledge_seed_log ALTER COLUMN id SET DEFAULT nextval('seq_knowledge_seed_log');
CREATE SEQUENCE IF NOT EXISTS seq_knowledge_acceptance START 1;
ALTER TABLE knowledge_acceptance ALTER COLUMN id SET DEFAULT nextval('seq_knowledge_acceptance');
CREATE SEQUENCE IF NOT EXISTS seq_eval_corpus START 1;
ALTER TABLE eval_corpus ALTER COLUMN id SET DEFAULT nextval('seq_eval_corpus');
CREATE SEQUENCE IF NOT EXISTS seq_eval_run START 1;
ALTER TABLE eval_run ALTER COLUMN id SET DEFAULT nextval('seq_eval_run');
CREATE SEQUENCE IF NOT EXISTS seq_eval_result START 1;
ALTER TABLE eval_result ALTER COLUMN id SET DEFAULT nextval('seq_eval_result');
CREATE SEQUENCE IF NOT EXISTS seq_scoring_config START 1;
ALTER TABLE scoring_config ALTER COLUMN id SET DEFAULT nextval('seq_scoring_config');
CREATE SEQUENCE IF NOT EXISTS seq_finding_sightings START 1;
ALTER TABLE finding_sightings ALTER COLUMN id SET DEFAULT nextval('seq_finding_sightings');
CREATE SEQUENCE IF NOT EXISTS seq_call_edges START 1;
ALTER TABLE call_edges ALTER COLUMN id SET DEFAULT nextval('seq_call_edges');
CREATE SEQUENCE IF NOT EXISTS seq_weakness_classes START 1;
ALTER TABLE weakness_classes ALTER COLUMN id SET DEFAULT nextval('seq_weakness_classes');
CREATE SEQUENCE IF NOT EXISTS seq_recurrence_counter START 1;
ALTER TABLE recurrence_counter ALTER COLUMN id SET DEFAULT nextval('seq_recurrence_counter');
CREATE SEQUENCE IF NOT EXISTS seq_mutation_log START 1;
ALTER TABLE mutation_log ALTER COLUMN id SET DEFAULT nextval('seq_mutation_log');

-- content_fingerprint on every hash-keyed / NK-deduped table (T2-13). NULL-permitting,
-- non-unique; the harness fills it and uses it for the content-checked dedup reject path.
ALTER TABLE critical_functions   ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE critical_fn_reach    ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE agent_steps          ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE agent_observations   ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE query_attempts       ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE cpg_slice_coverage   ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE methodology_blind_spots ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE gr_findings          ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE suspicious_points    ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE promising_lanes      ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE defense_bypasses     ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE sanitizer_bypass_runs ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE fuzz_runs            ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE fuzz_artifacts       ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE finding_sightings    ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE call_edges           ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE weakness_classes     ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE recurrence_counter   ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE mutation_log         ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;

------------------------------------------------------------
-- (2) gr_findings.confirmation_rigor_tier (T2-12 / S-P12). The fresh-DB schema.sql carries this
-- column INLINE in the gr_findings CREATE with its CHECK; on the upgrade path it is ADD COLUMN
-- with NO CHECK (DuckDB cannot widen the inline CHECK in place — the 0024 precedent). Enforced
-- app-side / by the `vrdb promote` verb. NULL for candidate/refuted/unconfirmed rows.
------------------------------------------------------------
ALTER TABLE gr_findings ADD COLUMN IF NOT EXISTS confirmation_rigor_tier TEXT;

------------------------------------------------------------
-- (3) v_phase_status REDEFINED to a tri-state (T2-02) + v_coverage with the three new metrics
-- (T2-03/04/05). Both restated IN FULL (carrying every prior row/metric forward) so CREATE OR
-- REPLACE is idempotent and byte-identical to db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_phase_status AS
SELECT
  phase_seq,
  phase,
  rows_populated,
  (rows_populated > 0) AS ran,        -- back-compat boolean (= rows_populated > 0)
  gap,                                 -- the phase's own shortfall count (0 = no gap)
  CASE
    WHEN rows_populated = 0 THEN 'not_run'
    WHEN gap > 0            THEN 'incomplete'
    ELSE                        'complete'
  END AS phase_status
FROM (
  SELECT -1 AS phase_seq, 'phase_l1_prior_art' AS phase,
         (SELECT count(*) FROM cves) + (SELECT count(*) FROM writeups) AS rows_populated,
         0 AS gap
  UNION ALL SELECT 0, 'phase0_decompose',
         (SELECT count(*) FROM sources) + (SELECT count(*) FROM sinks)
       + (SELECT count(*) FROM defenses) + (SELECT count(*) FROM critical_functions),
         -- gap: recon defense under-enumeration floor (defenses_below_validator_cf_floor).
         GREATEST(
           (SELECT count(DISTINCT cf.symbol_path) FROM critical_functions cf
            WHERE cf.cf_category = 'validator_sanitizer')
           - (SELECT count(*) FROM defenses), 0)
  UNION ALL SELECT 1, 'phase0_5_plan',
         (SELECT count(*) FROM input_slices) + (SELECT count(*) FROM critical_fn_reach),
         0
  UNION ALL SELECT 2, 'phase0_75_prebreak',
         (SELECT count(*) FROM defense_bypasses),
         -- gap: defenses with zero bypass attempt (defenses_without_bypass_attempt).
         (SELECT count(*) FROM defenses d
          WHERE NOT EXISTS (SELECT 1 FROM defense_bypasses b WHERE b.defense_id = d.id))
  UNION ALL SELECT 3, 'phase1_hunt',
         (SELECT count(*) FROM gr_findings),
         -- gap: open candidates not yet confirmed/refuted (Hunt feeds Confirm).
         (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate')
  UNION ALL SELECT 4, 'phase1_4_seed',
         (SELECT count(*) FROM fuzz_artifacts WHERE artifact_kind = 'seed_initial'),
         0
  UNION ALL SELECT 5, 'phase1_5_fuzz',
         (SELECT count(*) FROM fuzz_runs),
         0
  UNION ALL SELECT 6, 'phase1_6_blindspot',
         (SELECT count(*) FROM methodology_blind_spots),
         0
  UNION ALL SELECT 6.5, 'phase1_7_self_audit',
         (SELECT count(*) FROM agent_steps st
          JOIN strategies s ON s.id = st.strategy_id AND s.name = 'overlooked_lane_audit_lane'
          WHERE st.status IN ('success','exhausted')),
         0
  UNION ALL SELECT 7, 'phase2_confirm',
         (SELECT count(*) FROM refutations),
         -- gap: candidates still open (unconfirmed) when Confirm is supposed to have drained.
         (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate')
  UNION ALL SELECT 8, 'phase4_proof',
         (SELECT count(*) FROM audit_outcomes),
         0
  UNION ALL SELECT 9, 'phase5_report',
         (SELECT count(*) FROM critic_findings),
         -- gap: confirmed findings that never went through the REPORT critic.
         (SELECT count(*) FROM gr_findings f
          WHERE f.confirmation_status = 'confirmed'
            AND NOT EXISTS (SELECT 1 FROM critic_findings c WHERE c.finding_id = f.id))
) t
ORDER BY phase_seq;

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
  -- confirmed_without_refutation (v0.30, C08-A-F1): mechanical enforcement of the
  -- refute-before-confirm mandate. Mirrors confirmed_without_critic. A finding is
  -- "refuted" when at least one refutations row exists for it whose agent_step
  -- ran and FAILED to refute (i.e. the refutation attempt was made — the row
  -- existing proves an adversarial pass ran). Count-free. > 0 => RED.
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
  -- (a) executed_steps_without_observation: step-level mirror of
  --     v_observation_coverage. Count of EXECUTED agent_steps
  --     (running/success/exhausted/failed/timed_out) that hung ZERO
  --     agent_observations — the per-step view of a context-logging blackout. >0 =>
  --     at least one step ran but saved no context into the DB.
  UNION ALL SELECT 'executed_steps_without_observation',
    (SELECT count(*) FROM agent_steps st
     WHERE st.status IN ('running','success','exhausted','failed','timed_out')
       AND NOT EXISTS (SELECT 1 FROM agent_observations o WHERE o.agent_step_id = st.id)),
    'executed agent_step with zero agent_observations — context-logging blackout (mirror of v_observation_coverage)'
  -- (b) defenses_below_validator_cf_floor: recon UNDER-ENUMERATION floor. Every
  --     distinct validator/sanitizer critical_function IS a defense callsite, so the
  --     stored defenses inventory can never legitimately be SMALLER than the count of
  --     distinct validator/sanitizer CFs. GREATEST(distinct_validator_cfs -
  --     defenses_total, 0) is the shortfall size; >0 => wholesale defense
  --     under-storage. Conservative absolute floor — distinct from the 0014 linkage
  --     signals (validator_cfs_without_defense_link etc.), which fire on UNLINKED
  --     defenses; THIS fires on absolute under-count even when every stored defense
  --     is fully linked.
  UNION ALL SELECT 'defenses_below_validator_cf_floor',
    GREATEST(
      (SELECT count(DISTINCT cf.symbol_path) FROM critical_functions cf
       WHERE cf.cf_category = 'validator_sanitizer')
      - (SELECT count(*) FROM defenses), 0),
    'stored defenses fewer than distinct validator/sanitizer CFs — recon defense under-enumeration floor (shortfall size; >0 = RED)'
  -- (c) slices_without_codebase_coverage (v0.24): the "SAVE coverage when slices
  --     end" gate. If any input_slices row exists for the audit but NO
  --     cpg_slice_coverage row was ever written, the union-of-slices codebase
  --     coverage was never measured/saved => 1 (RED). Count-free EXISTS/NOT EXISTS —
  --     no %-floor, no magic constant; it enforces only that the measurement is
  --     saved, never how high it must be (slicing is selective by design, so a low
  --     % is inspected via v_cpg_slice_coverage, not auto-failed).
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
  -- lanes_stuck_running (v0.30, P2 completeness critic): count of agent_steps in
  -- status='running' that belong to a required DEEP lane in the current round.
  -- A non-zero value means a HEAVY lane (e.g. cpg_coverage / JVM) OOM'd or crashed
  -- and was never cleaned up. RED when > 0.
  -- Lane names are inlined (v_required_deep_lanes and v_lane_coverage are defined
  -- after v_coverage in schema order, so they cannot be referenced here directly).
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
  -- Fuzz-coverage gates (v0.29, gate fixed v0.30): the DYNAMIC mirror of slices_without_codebase_coverage.
  -- Both are count-free and carry NO %-floor (engine coverage is selective by design — a
  -- low % is inspected via v_fuzz_coverage, never auto-failed). They enforce only that
  -- (1) every EXECUTED fuzz run actually MEASURED coverage, and (2) every executed/skipped
  -- boundary_fuzz_lane step is ACCOUNTED by a fuzz_runs row (mandatory-attempt discipline).
  -- v0.30 fix (C09-A-F1): replaced gameable NOT LIKE '%edges%' substring test with
  -- json_extract value-presence check — identical to the check v_fuzz_coverage uses.
  -- A run is unmeasured only when ALL three json_extract results are NULL/absent.
  UNION ALL SELECT 'fuzz_runs_without_coverage_measurement',
    (SELECT count(*) FROM fuzz_runs
     WHERE skip_reason IS NULL
       AND TRY_CAST(json_extract_string(coverage_json, '$.edges')             AS BIGINT) IS NULL
       AND TRY_CAST(json_extract_string(coverage_json, '$.blocks')            AS BIGINT) IS NULL
       AND TRY_CAST(json_extract_string(coverage_json, '$.function_coverage') AS DOUBLE) IS NULL),
    'a fuzz_runs row that RAN (skip_reason IS NULL) records no coverage measurement in coverage_json (none of edges/blocks/function_coverage present as extractable values) — coverage was never measured for an executed fuzz run (RED; the dynamic mirror of slices_without_codebase_coverage — count-free, no %-floor)'
  UNION ALL SELECT 'fuzz_skips_unrecorded',
    (SELECT count(*) FROM agent_steps st
     JOIN strategies s ON s.id = st.strategy_id AND s.name = 'boundary_fuzz_lane'
     WHERE st.status IN ('success','exhausted','failed','timed_out','skipped')
       AND NOT EXISTS (SELECT 1 FROM fuzz_runs fr WHERE fr.agent_step_id = st.id)),
    'a boundary_fuzz_lane step that ran or was documented-skipped but emitted NO fuzz_runs row — Phase 1.5 mandatory-attempt accounting gap (RED): every run incl. a skip must record a fuzz_runs row'
  -- Promising-lane feed-forward signal (v0.25 / migration 0025): static-analysis leads not
  -- yet carried into a later round as a lane. SIGNAL, not auto-red — the latest round always
  -- has unconsumed directions by construction; inspect via v_promising_lanes_ranked.
  UNION ALL SELECT 'promising_lanes_unpromoted',
    (SELECT count(*) FROM promising_lanes WHERE promoted_to_round_id IS NULL),
    'static-analysis leads not yet carried into a later round as a lane — SIGNAL not auto-red (expected on the latest round); inspect via v_promising_lanes_ranked'
  -- regexes_unmapped (v0.39.0 / migration 0027): C3 mandatory whole-tree regex-mapping gate.
  -- HARD-RED (NOT a SIGNAL like promising_lanes_unpromoted): if preliminary_enumeration_lane RAN
  -- (>=1 success/exhausted step) but ZERO regexes rows exist for the target, the mandatory
  -- whole-tree regex inventory was skipped => 1 (RED). Count-free EXISTS/NOT-EXISTS — no %-floor,
  -- no magic constant — mirroring slices_without_codebase_coverage's SHAPE but RED-on-absence
  -- (mandatory) not SIGNAL. The gate cannot fire before the enumeration lane runs.
  UNION ALL SELECT 'regexes_unmapped',
    CASE WHEN EXISTS (
           SELECT 1 FROM agent_steps st
           JOIN strategies s ON s.id = st.strategy_id AND s.name = 'preliminary_enumeration_lane'
           WHERE st.status IN ('success','exhausted'))
          AND NOT EXISTS (SELECT 1 FROM regexes)
         THEN 1 ELSE 0 END,
    'preliminary_enumeration_lane ran but no regexes rows — mandatory whole-tree regex inventory skipped (RED; the C3 completeness gate, count-free, no %-floor; unlike the promising_lanes_unpromoted SIGNAL this is mandatory)'
  -- confirmed_without_promotion_provenance (v0.40 / migration 0029 / T2-03 / S-D02, C21):
  -- a confirmed gr_findings row that has NO mutation_log op='status_transition' row recording
  -- the candidate→confirmed flip. The ONLY legitimate path to 'confirmed' is the `vrdb promote`
  -- verb (Tier 3 T3-01), which writes that status_transition row in the same tx. A confirmed
  -- finding lacking it was flipped OUT-OF-BAND (a born-confirmed Put, the 10→33 inflation) and
  -- is unjustified at the provenance level. mutation_log.row_key is the finding_hash (per
  -- v_finding_history). Count-free; > 0 => RED.
  UNION ALL SELECT 'confirmed_without_promotion_provenance',
    (SELECT count(*) FROM gr_findings f
     WHERE f.confirmation_status = 'confirmed'
       AND NOT EXISTS (
         SELECT 1 FROM mutation_log ml
         WHERE ml.table_name = 'gr_findings'
           AND ml.op = 'status_transition'
           AND ml.row_key = f.finding_hash)),
    'confirmed finding with no mutation_log status_transition row — flipped to confirmed OUT-OF-BAND (not via the vrdb promote verb); born-confirmed inflation (RED when > 0)'
  -- ranked_sps_never_consumed (v0.40 / migration 0029 / T2-04 / S-D03): a suspicious_point
  -- that is gate_ok=TRUE and in the TOP-K composite_score for its (target, round) but has NO
  -- sp_spawn_decisions row — i.e. the ranking that named it a top lead was never CONSUMED by a
  -- spawn decision. Without this the four ranked views are read-time sort keys wired to no
  -- spawn step; the ranking has zero effect unless an agent voluntarily queries it. K is the
  -- per-(target,round) decile (top 10%, min 1) of gate_ok SPs — a relative cut, no magic
  -- constant. Count-free; > 0 => RED (the orchestrator must record a decision for each ranked
  -- top SP, even if the decision is spawned=FALSE/declined).
  UNION ALL SELECT 'ranked_sps_never_consumed',
    (SELECT count(*) FROM (
       SELECT r.id, r.target_id, r.round_id,
              ROW_NUMBER() OVER (
                PARTITION BY r.target_id, r.round_id ORDER BY r.composite_score DESC
              ) AS rk,
              CEIL(0.10 * COUNT(*) OVER (PARTITION BY r.target_id, r.round_id)) AS topk
       FROM v_suspicious_points_ranked r
       WHERE r.gate_ok = TRUE
     ) ranked
     WHERE ranked.rk <= GREATEST(ranked.topk, 1)
       AND NOT EXISTS (
         SELECT 1 FROM sp_spawn_decisions d
         WHERE d.sp_id = ranked.id
           AND d.round_id IS NOT DISTINCT FROM ranked.round_id)),
    'a gate_ok top-K (per target/round) ranked suspicious_point with no sp_spawn_decisions row — the ranking was never consumed by a spawn decision (RED when > 0)'
  -- roster_steps_missing_for_current_round (v0.40 / migration 0029 / T2-05, T2-11 / S-D09):
  -- a required DEEP lane (v_required_deep_lanes) with NO agent_steps row in the CURRENT round.
  -- The round-keyed roster sentinel convention (T2-11): the orchestrator materializes one
  -- agent_steps sentinel per required lane per round with step_hash='plan-roster-<lane>-r<round_id>'
  -- (round_id IN the hashed natural key) so a round-2 materialization cannot ON CONFLICT DO
  -- NOTHING against round-1's globally-UNIQUE sentinel. A swallowed round-2 roster insert then
  -- surfaces HERE as a missing current-round step rather than masquerading as a documented
  -- skip. "Current round" = v_current_round (NULL=NULL match for single-shot audits). Count-free;
  -- > 0 => RED.
  -- Lane names are inlined (v_required_deep_lanes is defined AFTER v_coverage in schema
  -- order, so it cannot be referenced here — the lanes_stuck_running precedent). Kept in
  -- sync with the v_required_deep_lanes roster (report_critic excluded — it is the confirm/
  -- report critic, not a hunt-roster lane materialized at Plan).
  UNION ALL SELECT 'roster_steps_missing_for_current_round',
    (SELECT count(*) FROM (VALUES
       ('prior_art_intake_lane'),('preliminary_enumeration_lane'),('forward_slice_lane'),
       ('backward_sink_lane'),('critical_function_dataflow_lane'),('defense_base_lane'),
       ('defense_context_verification_lane'),('isolation_fuzz_lane'),('html_sanitizer_bypass_lane'),
       ('concolic_bypass_lane'),('llm_seed_corpus_lane_a'),('llm_seed_corpus_lane_b'),
       ('fuzzgpt_history_lane'),('boundary_fuzz_lane'),('methodology_blindspot_lane_a'),
       ('methodology_blindspot_lane_b'),('overlooked_lane_audit_lane')
     ) AS req(lane_name)
     JOIN strategies s ON s.name = req.lane_name
     WHERE NOT EXISTS (
       SELECT 1 FROM agent_steps st
       WHERE st.strategy_id = s.id
         AND (
           (st.round_id IS NULL AND NOT EXISTS (SELECT 1 FROM round_ledger))
           OR st.round_id IS NOT DISTINCT FROM (
             SELECT cr.round_id FROM v_current_round cr
             WHERE cr.target_id = (
               SELECT target_id FROM round_ledger WHERE id = st.round_id LIMIT 1
             )
             LIMIT 1
           )
         ))),
    'a required DEEP lane with no agent_steps row in the CURRENT round — a swallowed round-keyed roster sentinel (step_hash plan-roster-<lane>-r<round_id>); the lane was never materialized this round (RED when > 0)'
) t
ORDER BY metric;

------------------------------------------------------------
-- (4) JUSTIFICATION GATE views (T2-01/06/07/14/15). Placed last so they may reference
-- gr_findings, refutations, critic_findings, impact_proofs, suspicious_points,
-- v_suspicious_points_ranked, v_lane_coverage, agent_observations and mutation_log.
------------------------------------------------------------
-- JUSTIFICATION GATE views (v0.40.0, migration 0029, TIER 2 T2-01/06/07/14/15).
--
-- The pre-v0.40 DEEP gate encoded PROCESS-coverage only (a required lane ran, a phase
-- logged ≥1 row, defenses enumerated) — a campaign that executed every lane and confirmed
-- ZERO justified findings was GREEN, and any lane could Put a born-'confirmed' row that the
-- gate counted without re-deriving (the Zuul false-green + the 10→33 inflation). These views
-- add the missing OUTCOME-justification layer. DuckDB v1.1.3 has NO triggers, so they are the
-- read-side gate; the WRITE-side invariant (only `vrdb promote` may set 'confirmed', in one tx
-- with refutation-overcome + critic-OK + severity + mutation_log) is the Go harness's job
-- (TIER 3 T3-01/T3-02). The two layers reinforce: the prose rubric is enforced by these views,
-- which are written only through the harness verb.
--
-- These views are placed LAST so they may freely reference gr_findings, refutations,
-- critic_findings, impact_proofs, suspicious_points, v_suspicious_points_ranked,
-- v_lane_coverage, agent_observations and mutation_log (all defined above).
------------------------------------------------------------

-- v_promotion_coverage (T2-01 / S-D01, S-P02, C18). The JUSTIFICATION gate. For each
-- confirmed gr_findings row, emit gate_status = JUSTIFIED only when ALL of (a)-(d) hold:
--   (a) ≥1 refutations row exists that was OVERCOME — the refute-before-confirm trail (a
--       refutations row pins that an adversarial pass ran; the finding is still 'confirmed',
--       so the refutation did not stick = overcome);
--   (b) severity IS NOT NULL;
--   (c) a critic_findings row with check_kind='eligibility' AND severity='OK';
--   (d) SP-CONDITIONAL backing-oracle: the SP tier is a SIDE-OUTPUT, not a mandatory origin
--       (findings are also born from Phase 1 Hunt, Phase 1.5 fuzz crashes
--       finding_kind='fuzz_crash', and Phase L0 commit review — with NO suspicious_points row).
--       So (d) is required ONLY WHEN the finding HAS a backing SP: a finding with NO backing
--       suspicious_point (graduated_finding_id = this finding) is judged on (a)-(c) alone; a
--       finding that DOES have a backing SP must additionally show that SP carries a non-null
--       oracle whose v_suspicious_points_ranked.gate_ok = TRUE. Formally:
--         NOT EXISTS(sp WHERE sp.graduated_finding_id=f.id)
--         OR EXISTS(sp WHERE sp.graduated_finding_id=f.id AND sp.oracle IS NOT NULL AND gate_ok).
-- else UNJUSTIFIED. Each missing-reason is surfaced so the orchestrator sees WHY. The "done"
-- predicate is `0 UNJUSTIFIED among confirmed` (a confirmed row that is UNJUSTIFIED is the
-- false-green this view exists to catch). Findings that are NOT 'confirmed' are excluded
-- (only the registry-bound rows must be justified).
CREATE OR REPLACE VIEW v_promotion_coverage AS
SELECT
  f.id            AS finding_id,
  f.target_id,
  f.finding_hash,
  f.severity,
  f.confirmation_rigor_tier,
  -- (a) refute-before-confirm trail overcome
  EXISTS (SELECT 1 FROM refutations r WHERE r.finding_id = f.id)                 AS has_refutation,
  -- (b) severity present
  (f.severity IS NOT NULL)                                                       AS has_severity,
  -- (c) critic eligibility = OK
  EXISTS (SELECT 1 FROM critic_findings c
          WHERE c.finding_id = f.id AND c.check_kind = 'eligibility'
            AND c.severity = 'OK')                                               AS has_critic_ok,
  -- (d) SP-CONDITIONAL backing oracle: satisfied either when the finding has NO backing SP at
  --     all, OR when its backing SP carries a non-null oracle that passed the SP gate.
  (NOT EXISTS (SELECT 1 FROM suspicious_points sp WHERE sp.graduated_finding_id = f.id)
   OR EXISTS (SELECT 1 FROM suspicious_points sp
              JOIN v_suspicious_points_ranked spr ON spr.id = sp.id
              WHERE sp.graduated_finding_id = f.id
                AND sp.oracle IS NOT NULL
                AND spr.gate_ok = TRUE))                                         AS has_backing_sp,
  CASE
    WHEN EXISTS (SELECT 1 FROM refutations r WHERE r.finding_id = f.id)
     AND f.severity IS NOT NULL
     AND EXISTS (SELECT 1 FROM critic_findings c
                 WHERE c.finding_id = f.id AND c.check_kind = 'eligibility'
                   AND c.severity = 'OK')
     AND (NOT EXISTS (SELECT 1 FROM suspicious_points sp WHERE sp.graduated_finding_id = f.id)
          OR EXISTS (SELECT 1 FROM suspicious_points sp
                     JOIN v_suspicious_points_ranked spr ON spr.id = sp.id
                     WHERE sp.graduated_finding_id = f.id
                       AND sp.oracle IS NOT NULL
                       AND spr.gate_ok = TRUE))
    THEN 'JUSTIFIED'
    ELSE 'UNJUSTIFIED'
  END AS gate_status
FROM gr_findings f
WHERE f.confirmation_status = 'confirmed';

-- v_justification_coverage (T2-07 / S-P02, S-P04, S-V11). The CONSUMER-HARM gate (Gate 5
-- doctrine, T1-02): a sink reached is NOT a consumer harmed. Red-flags any confirmed finding
-- lacking an impact_proofs row (the named default-config component that reads/dispatches/trusts
-- the tainted value + its harm). When the proof exists, severity is a CONTRACT, not an automatic
-- function: the Confirm agent MUST DERIVE severity from the exploitability-gate rubric over the
-- proof's harm_class × proven_reachability × mechanism_cap and record that derivation in
-- severity_basis (not a typed label); the proof's proven_reachability + mechanism_cap are
-- surfaced so a consumer of this view can recompute the read-time severity rubric (T1-03).
-- justification_status = JUSTIFIED only when a proof row
-- exists; else UNJUSTIFIED_NO_CONSUMER. Done predicate: 0 UNJUSTIFIED_NO_CONSUMER among confirmed.
CREATE OR REPLACE VIEW v_justification_coverage AS
SELECT
  f.id        AS finding_id,
  f.target_id,
  f.finding_hash,
  f.severity,
  ip.consumer_symbol,
  ip.harm_class,
  ip.proven_reachability,
  ip.mechanism_cap,
  (ip.id IS NOT NULL) AS has_impact_proof,
  CASE WHEN ip.id IS NOT NULL THEN 'JUSTIFIED' ELSE 'UNJUSTIFIED_NO_CONSUMER' END AS justification_status
FROM gr_findings f
LEFT JOIN impact_proofs ip ON ip.finding_id = f.id
WHERE f.confirmation_status = 'confirmed';

-- v_sp_oracle_coverage (T2-06 / S-P06, C19). HARD-RED SP-adjudication gate. Every KEPT
-- suspicious_point (screening_verdict='kept') that carries an APPLICABLE oracle (oracle IS NOT
-- NULL) must reach an adjudication exit: either it GRADUATED into a finding
-- (graduated_finding_id IS NOT NULL) OR an oracle-execution agent_step recorded a result for it
-- (an agent_observations row anchored on the SP's symbol_path whose obs_kind names a verdict-
-- bearing outcome: dead_end | invariant | partial_trace). A kept SP with an applicable oracle
-- and NEITHER exit is RED (oracle_unrun) — recall without a closing oracle is noise accumulation,
-- not a processed queue. Done predicate: 0 RED rows.
CREATE OR REPLACE VIEW v_sp_oracle_coverage AS
SELECT
  sp.id        AS sp_id,
  sp.target_id,
  sp.round_id,
  sp.symbol_path,
  sp.vuln_class,
  sp.oracle,
  (sp.graduated_finding_id IS NOT NULL) AS graduated,
  EXISTS (
    SELECT 1 FROM agent_observations o
    WHERE o.target_id = sp.target_id
      AND o.symbol_path = sp.symbol_path
      AND o.obs_kind IN ('dead_end', 'invariant', 'partial_trace')
  ) AS oracle_executed,
  CASE
    WHEN sp.graduated_finding_id IS NOT NULL THEN 'graduated'
    WHEN EXISTS (
      SELECT 1 FROM agent_observations o
      WHERE o.target_id = sp.target_id
        AND o.symbol_path = sp.symbol_path
        AND o.obs_kind IN ('dead_end', 'invariant', 'partial_trace')
    ) THEN 'adjudicated'
    ELSE 'RED_oracle_unrun'
  END AS adjudication_status
FROM suspicious_points sp
WHERE sp.screening_verdict = 'kept'
  AND sp.oracle IS NOT NULL;

-- v_invariant_promotion_coverage (T2-14 / F34/F35, Phase 6). HARD-RED learning-loop gate.
-- The 12-orphan disease: a campaign LEARNS a reusable, high-confidence invariant but it dies
-- in agent_observations and is never PROMOTED into the durable cross-target registry
-- (references/methodology/triage-invariants.md). This view is RED while any
-- agent_observations(obs_kind='invariant', reusable=TRUE, confidence high) has NEITHER a
-- promotion entry NOR a recorded promotion_skipped reason. DuckDB-side this view cannot read
-- the markdown file or the skip ledger directly; both signals are carried in
-- agent_observations as sibling rows on the SAME symbol_path:
--   • PROMOTED  — an obs_kind='note' row whose body starts 'invariant_promoted:' (written by
--                 the Phase 6 promotion step when it appends to triage-invariants.md);
--   • SKIPPED   — an obs_kind='note' row whose body starts 'promotion_skipped:' (the recorded
--                 reason a learned invariant was deliberately NOT promoted).
-- confidence is a REAL in agent_observations; "high" = confidence >= 0.75 (NULL excluded). An
-- invariant with neither sibling is RED (unpromoted_unexplained). Done predicate: 0 RED rows.
CREATE OR REPLACE VIEW v_invariant_promotion_coverage AS
SELECT
  inv.id        AS observation_id,
  inv.target_id,
  inv.symbol_path,
  inv.confidence,
  EXISTS (
    SELECT 1 FROM agent_observations p
    WHERE p.target_id = inv.target_id
      AND p.symbol_path IS NOT DISTINCT FROM inv.symbol_path
      AND p.obs_kind = 'note'
      AND p.body LIKE 'invariant_promoted:%'
  ) AS promoted,
  EXISTS (
    SELECT 1 FROM agent_observations s
    WHERE s.target_id = inv.target_id
      AND s.symbol_path IS NOT DISTINCT FROM inv.symbol_path
      AND s.obs_kind = 'note'
      AND s.body LIKE 'promotion_skipped:%'
  ) AS promotion_skipped,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM agent_observations p
      WHERE p.target_id = inv.target_id
        AND p.symbol_path IS NOT DISTINCT FROM inv.symbol_path
        AND p.obs_kind = 'note'
        AND p.body LIKE 'invariant_promoted:%'
    ) OR EXISTS (
      SELECT 1 FROM agent_observations s
      WHERE s.target_id = inv.target_id
        AND s.symbol_path IS NOT DISTINCT FROM inv.symbol_path
        AND s.obs_kind = 'note'
        AND s.body LIKE 'promotion_skipped:%'
    ) THEN 'resolved'
    ELSE 'RED_unpromoted_unexplained'
  END AS promotion_status
FROM agent_observations inv
WHERE inv.obs_kind = 'invariant'
  AND inv.reusable = TRUE
  AND inv.confidence IS NOT NULL
  AND inv.confidence >= 0.75;

-- v_empty_result (T2-15 / S-D01). The EMPTY_RESULT terminal — a NAMED verdict, NOT red.
-- An empty campaign (thoroughly searched, nothing justified) must be DISTINGUISHABLE from a
-- green run that found and justified a bug; both pass the process gates, so a separate terminal
-- is needed. One row, one boolean: is_empty_result is TRUE when:
--   • confirmed_count   = 0  (no confirmed findings)
--   • candidate_count   = 0  (no open candidates — the Confirm queue is drained, not abandoned)
--   • high_recall_lanes_all_ran  (no required DEEP lane is MISSING in v_lane_coverage — every
--     mandatory lane ran or was documented-skipped; an EMPTY_RESULT is only credible if the
--     high-recall sweep actually completed).
-- The orchestrator reports EMPTY_RESULT as a distinct outcome rather than an indistinguishable
-- green. This is NOT a gate failure — it is a legitimate, fully-searched-nothing-there verdict.
CREATE OR REPLACE VIEW v_empty_result AS
SELECT
  (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'confirmed') AS confirmed_count,
  (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate') AS candidate_count,
  NOT EXISTS (SELECT 1 FROM v_lane_coverage WHERE gate_status = 'MISSING')   AS high_recall_lanes_all_ran,
  CASE
    WHEN (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'confirmed') = 0
     AND (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate') = 0
     AND NOT EXISTS (SELECT 1 FROM v_lane_coverage WHERE gate_status = 'MISSING')
    THEN TRUE ELSE FALSE
  END AS is_empty_result,
  CASE
    WHEN (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'confirmed') = 0
     AND (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate') = 0
     AND NOT EXISTS (SELECT 1 FROM v_lane_coverage WHERE gate_status = 'MISSING')
    THEN 'EMPTY_RESULT' ELSE 'NON_EMPTY'
  END AS terminal_state;

INSERT INTO schema_version (version, description)
VALUES (29, 'justification gate + DB hardening (v0.40.0, migration 0029 / TIER 2 T2-01..T2-16): the completion gate moves from PROCESS-coverage to OUTCOME-justification. NEW TABLES (each its own CREATE SEQUENCE + DEFAULT nextval + CHECK(id>0)): impact_proofs (T2-07 consumer-harm ledger), closures (T2-08 hard pre-spawn barrier), sp_spawn_decisions (T2-09 the SP ranking becomes a CONSUMED artifact). NEW VIEWS: v_promotion_coverage (T2-01 JUSTIFIED|UNJUSTIFIED per confirmed finding), v_phase_status REDEFINED tri-state not_run|incomplete|complete (T2-02), v_justification_coverage (T2-07), v_sp_oracle_coverage (T2-06 HARD-RED), v_invariant_promotion_coverage (T2-14 HARD-RED), v_empty_result EMPTY_RESULT terminal (T2-15). NEW v_coverage METRICS: confirmed_without_promotion_provenance (T2-03), ranked_sps_never_consumed (T2-04), roster_steps_missing_for_current_round (T2-05). NEW COLUMNS: gr_findings.confirmation_rigor_tier (T2-12) + content_fingerprint on every hash-keyed table (T2-13). DDL: per-table CREATE SEQUENCE + id DEFAULT nextval (T2-10) + CHECK(id>0)/CHECK(col>0) on new tables (T2-16; pre-existing tables carry the CHECK only on a fresh schema.sql build — DuckDB v1.1.3 cannot retro-add a CHECK). Round-keyed roster sentinel convention step_hash=plan-roster-<lane>-r<round_id> (T2-11). DuckDB v1.1.3 has NO triggers; the WRITE-side enforcement (vrdb promote/close-step/content-checked-dedup) is the Go harness job (TIER 3). The migration adds new-table inline CHECKs on a fresh chain build; the upgrade path adds columns/sequences additively and enforces the new CHECKs app-side per the 0009/0019/0024 precedent.')
ON CONFLICT DO NOTHING;
