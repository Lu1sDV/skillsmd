# Ruby Rule MegaDB — Architecture (v1 draft)

Goal: build a **1000+ entry** Ruby detection-rule library (~800 Semgrep `.yaml` +
~200 CodeQL `.ql`), each rule **original-wording with source citation** (publishable
on a public marketplace), **execute-validated** (parses/compiles AND fires on a real
corpus / oracle without obvious FPs), indexed by a generated `manifest.json`, and
linked from `references/sinks/ruby.md`.

A GitLab-focused CodeQL precision oracle (targeted databases at known-vulnerable
commits) backs the CodeQL queries: a query should HIT at the vulnerable commit and
go MISS at the fix commit.

## Model routing (per request)

| Role | Model | Work |
|------|-------|------|
| Architect / hardest analysis | **Fable** (main loop) | this doc, schema, backlog dedup adjudication, critic synthesis |
| Synthesis / adjudication | **Opus** | inventory→backlog dedup, oracle commit mapping, completeness critic |
| Research / authoring / validation | **Sonnet** | SOTA source inventory, rule authoring, validation runs |

## Directory layout

```
vuln-research/rules/ruby/
  ARCHITECTURE.md        # this file
  README.md              # human docs + how to run rules
  taxonomy.yml           # canonical categories (mirrors ruby.md's 21 sink types + CWE)
  backlog.json           # master de-duped rule specs (drives authoring)  [generated]
  manifest.json          # index over authored+validated rules           [generated]
  semgrep/<category>/*.yaml
  codeql/
    qlpack.yml           # depends on codeql/ruby-all
    lib/                 # shared flow configs / predicates
    <category>/*.ql
  oracle/
    cve-commits.json     # CVE/GHSA -> {repo, vuln_sha, fix_sha, category}
  corpus/                # .gitignored — cloned gitlab + sampled gems (validation input)
  dbs/                   # .gitignored — built CodeQL databases (oracle)
  tools/
    validate_semgrep.sh  # semgrep --validate + scan corpus, record hits
    validate_codeql.sh   # codeql query compile + run vs oracle DBs
    build_oracle_db.sh    # checkout vuln_sha, codeql database create
    gen_manifest.rb       # walk rule files -> manifest.json
```

`corpus/` and `dbs/` are git-ignored (large, reproducible). Rule files, taxonomy,
backlog, manifest, and oracle map are committed.

## Rule metadata contract (THE fixed schema — all rules MUST conform)

### Semgrep (`.yaml`)
```yaml
rules:
  - id: ruby-<category>-<slug>          # kebab; unique
    languages: [ruby]
    severity: ERROR | WARNING | INFO
    message: >                          # original wording, explains sink + impact + fix
      ...
    metadata:
      vr-id: RB-SG-0001                 # stable namespaced id (RB-SG-#### / RB-QL-####)
      category: command-injection       # MUST be a taxonomy.yml key
      cwe: ["CWE-78"]
      owasp: "A03:2021"
      confidence: HIGH | MEDIUM | LOW
      source-citation: "GHSA-xxxx; gitlab-commit <sha>; inspired-by semgrep ruby.lang.security.x"
      license: derived-original         # never verbatim from a licensed pack
      references: ["https://..."]
      validated:
        parses: true
        fired_on_corpus: true|false     # set by validate_semgrep.sh
        corpus_hits: <int>
    patterns: | pattern-sources/-sinks/-sanitizers ...
```

### CodeQL (`.ql`)
```ql
/**
 * @name Ruby <category> via <sink>
 * @description Original-wording description of the flow + impact.
 * @kind path-problem | problem
 * @problem.severity error | warning
 * @precision high | medium
 * @id rb/<category>-<slug>
 * @tags security external/cwe/cwe-078
 * @vr-id RB-QL-0001
 * @source-citation GHSA-xxxx; gitlab-commit <sha>
 * @license derived-original
 */
import ruby
import codeql.ruby.DataFlow
import codeql.ruby.taint.TaintTracking
// ...
```

## Phase plan (each phase = one Workflow run; we stay in the loop between them)

- **P0 Scaffolding (Fable, now):** dirs, schema (this doc), taxonomy, `.gitignore`,
  validation script stubs, rule templates. Kick off background: GitLab blobless clone
  + `codeql pack download`.
- **P1 Inventory + corpus (Sonnet swarm, ~10 lanes):** each lane maps one SOTA source
  to structured rule-spec JSON (category, pattern summary, citation, CWE, tool-fit,
  license). Lanes: GitLab sast-rules, Semgrep registry p/ruby+p/rails, CodeQL
  ruby-queries, Brakeman checks, GHSA Ruby/RubyGems, GitLab Security-Release→commit map,
  community semgrep repos, Rails core CVEs, popular-gem CVEs, Tavily/parallel broad sweep.
- **P2 Backlog synthesis (Opus):** merge inventories, dedupe by (category, sink,
  pattern-hash), assign vr-ids + tool + priority -> `backlog.json` (target ≥1000 specs).
  Also emit `oracle/cve-commits.json` for pinnable CVEs.
- **P3 Authoring + validation (Sonnet pipeline):** batched over backlog. Per spec:
  author file -> `semgrep --validate` / `codeql query compile` -> (sampled) scan corpus /
  run oracle -> record `validated.*`. Disjoint path ranges per agent (no worktree needed).
- **P4 Manifest + integration + critic (Opus/Fable):** `gen_manifest.rb`, update
  `references/sinks/ruby.md` to link rules, adversarial completeness critic, version bump,
  commit.

## Validation contract

- **Semgrep:** `semgrep --validate --config <rule>` (must pass) then
  `semgrep --config <rule> corpus/` — record hit count. Zero-hit rules are flagged
  `fired_on_corpus:false` (kept but de-prioritized; obvious-FP rules dropped).
- **CodeQL:** `codeql query compile` (must pass) then `codeql database analyze`/`query run`
  against the matching oracle DB — HIT at vuln_sha, MISS at fix_sha = validated.

## Performance principles

1. Pipeline, not barrier, for author→validate (item-level, no global sync).
2. Background heavy infra (corpus, CodeQL packs) during P1 research.
3. Dedupe in P2 BEFORE authoring — never author the same pattern twice.
4. Build each oracle DB once; many queries reuse one DB.
5. Batch authoring to respect the workflow concurrency cap (min(16, cores-2)); 24 cores here -> cap 16.

---

# v2 revisions (Fable) — supersede the above where they conflict

Empirical fact forcing change: the `gitlab-org/gitlab` blobless clone FAILED
(`curl 28 ... less than 1000 bytes/sec ... expected flush after ref listing`).
The monorepo is too big/fragile over this link. CodeQL ruby packs DID install.

## Six key improvements

**1. Make the GitLab CVE oracle the SPINE, not the caboose.**
The CVE->fix-commit corpus is simultaneously our highest-signal *source* of novel
rules (real vulns + ground-truth fix) AND the validation *oracle*. So the
security-release->commit mining lane runs FIRST. The moment it yields commits, two
things start in parallel in the background: (a) minimal oracle-DB extraction, and
(b) diff-derived rule authoring. A fix diff literally encodes the pattern and is
self-validating (the diff IS the test case). Oracle stops being a downstream tail.

**2. Don't clone the monorepo — fetch surgically (forced by the clone failure).**
- *Oracle:* per CVE, fetch ONLY the touched files at `vuln_sha` and `fix_sha`
  (GitLab raw-blob API / `git archive`), extract a minimal Ruby CodeQL DB from that
  subtree (Ruby needs no build, so a file subtree extracts fine). No monorepo clone.
- *Semgrep corpus:* a basket of `--depth 1` shallow clones of mid-size popular
  Ruby/Rails repos (devise, discourse, mastodon, redmine, spree, ...) — more pattern
  diversity, each small + resumable, cached once.

**3. Two-tier rule provenance — author them differently.**
- *Tier A — diff-derived (~150-250):* mined from real CVE fix commits; validated
  against the oracle DB (HIT@vuln_sha / MISS@fix_sha). The crown jewels + the genuine
  novelty vs. re-deriving public packs.
- *Tier B — catalog-derived (~750-850):* original re-expressions of known sink
  patterns from the inventories; validated by synthetic tests + corpus scan.

**4. Ship synthetic test pairs WITH every rule — the portable, deterministic oracle.**
Every rule ships `tests/ruby-<slug>.rb` with Semgrep `# ruleid:` / `# ok:`
annotations (native `semgrep --test`) — a should-match and a should-NOT-match case.
This is the PRIMARY validation gate (fast, deterministic, per-rule, CI-able) and
fixes the "auto-drop zero-hit on a sampled corpus" footgun. Corpus scan becomes a
secondary "fires on real code" signal, not the gate. CodeQL queries get
`codeql test run` query tests likewise.

**5. Category-owned authoring agents, not random slices.**
Each authoring agent owns ONE taxonomy category end-to-end (24 categories; big ones
split in 2). Better intra-family consistency, natural dedup, full sink-family context.
24-32 agents fits under both the 16-concurrent (2 waves) and 1000-lifetime caps.
NEVER one-agent-per-rule (would approach the lifetime cap).

**6. Validation is a deterministic SCRIPT lane, not an LLM phase.**
Because every rule carries tests, Tier-B validation is `semgrep --test rules/ruby/`
and `codeql test run` — no agent needed, CI-able (extend
`.github/workflows/validate-skills.yml`). Agents are spent only on authoring and on
adjudicating genuine oracle failures (Tier A).

## Revised layout deltas
- add `semgrep/<category>/tests/ruby-<slug>.rb` (annotated test files)
- add `codeql/<category>/tests/<slug>/` (query test: `.ql` + `.expected` + fixture)
- `corpus/` now holds a basket of shallow clones (git-ignored), not one monorepo
- `oracle/dbs/<cve>/{vuln,fix}/` minimal per-commit subtree DBs (git-ignored)

## Revised phasing (oracle-first, overlapping)
- **P1a (first, fast):** security-release->commit mining -> `oracle/cve-commits.json`.
- **P1b (overlaps P1a tail):** the other ~9 inventory lanes -> rule-spec JSON; AND a
  background non-agent `parallel()` that surgically fetches + extracts oracle DBs as
  CVE rows land.
- **P2 (Opus):** merge + dedup on external IDs (CVE/GHSA/sha) THEN pattern-hash ->
  `backlog.json` split into Tier A / Tier B.
- **P3 (Sonnet, category-owned, pipeline):** author rule + synthetic tests ->
  `semgrep --test` / `codeql test run` -> record. Tier A also runs oracle HIT/MISS.
- **P4 (Opus/Fable):** incremental `manifest.json`, link from `references/sinks/ruby.md`,
  completeness critic, version bump, commit.
