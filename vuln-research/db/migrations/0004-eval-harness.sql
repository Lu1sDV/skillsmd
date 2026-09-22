-- vuln-research migration 0004 — eval harness (Tier 1 measurement)
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: purely additive. Creates three new tables — eval_corpus, eval_run,
-- eval_result — that score the prose methodology against a labeled CVE corpus
-- (recall on vuln targets, FP-per-KLOC on clean controls). This is COMPLEMENTARY
-- benchmarking infrastructure, not the product: the prose pipeline finds bugs;
-- these tables only measure whether a methodology change helped.
-- Design: docs/superpowers/specs/2026-05-21-eval-harness-design.md
--
-- No enum widening and no FK into the audit tables beyond a read of gr_findings
-- at ingest time, so — like 0003 — this migration has NO fresh-DB-only caveat and
-- applies cleanly to any v2/v3 DB. db/schema.sql carries the identical
-- definitions for fresh DBs; the orchestrator remains the single writer.
--
-- ORDERING: eval_run.corpus_id references eval_corpus(id), so eval_corpus is
-- created first. eval_result has no FK (it keys on manifest_uid TEXT).

------------------------------------------------------------
-- One labeled target + its clean control + ground-truth fix hunks (inline JSON).
-- Vulnerable target = vuln_commit (fix_commit~1); clean control = fix_commit.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS eval_corpus (
  id INTEGER PRIMARY KEY,
  source TEXT NOT NULL
    CHECK (source IN ('cvefixes', 'vul4j', 'primevul', 'custom')),
  cve_id TEXT NOT NULL,
  repo_url TEXT NOT NULL,
  vuln_commit TEXT NOT NULL,           -- fix_commit~1: the bug is present here
  fix_commit TEXT NOT NULL,            -- the clean control: bug provably gone
  primary_cwe TEXT,
  language TEXT,
  -- ground_truth_json: [{file,line_start,line_end,cwe,is_primary}] — the fix
  -- hunk(s); exactly one entry flagged is_primary for the target-level rollup.
  ground_truth_json TEXT NOT NULL,
  added_at TIMESTAMP NOT NULL,
  UNIQUE (source, cve_id, repo_url)
);

------------------------------------------------------------
-- One ingested audit result for a (corpus, mode, seed). findings_json is a
-- snapshot of the audit's gr_findings resolved to file/line + derived CWE.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS eval_run (
  id INTEGER PRIMARY KEY,
  corpus_id INTEGER NOT NULL REFERENCES eval_corpus(id),
  manifest_uid TEXT NOT NULL,          -- groups the runs emitted by one manifest
  mode TEXT NOT NULL
    CHECK (mode IN ('vuln', 'control')),
  seed INTEGER NOT NULL,
  tier TEXT
    CHECK (tier IS NULL OR tier IN ('low', 'medium', 'deep')),
  kloc_scanned REAL,
  -- findings_json: [{hash,kind,cwe,file,line,severity,status}]
  findings_json TEXT NOT NULL,
  ingested_at TIMESTAMP NOT NULL,
  UNIQUE (manifest_uid, corpus_id, mode, seed)
);

------------------------------------------------------------
-- Computed metrics + match decisions for one manifest (overall + per-target).
-- Two-track: recall on vuln targets, fp_per_kloc on clean controls only.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS eval_result (
  id INTEGER PRIMARY KEY,
  manifest_uid TEXT NOT NULL,
  scope TEXT NOT NULL
    CHECK (scope IN ('overall', 'target')),
  scope_key TEXT NOT NULL,             -- 'all' for overall, else corpus_id
  recall_at_1 REAL,
  recall_at_k REAL,
  fp_per_kloc REAL,
  refound_fixed_rate REAL,             -- controls that re-flag the fixed location
  -- matches_json: [{finding_hash,gt_idx,grade,decided_by,rationale}]
  matches_json TEXT,
  computed_at TIMESTAMP NOT NULL,
  UNIQUE (manifest_uid, scope, scope_key)
);

INSERT INTO schema_version (version, description)
VALUES (4, 'eval harness (Tier 1): eval_corpus / eval_run / eval_result')
ON CONFLICT DO NOTHING;
