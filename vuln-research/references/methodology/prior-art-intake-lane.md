# Prior-Art Intake Lane (`prior_art_intake_lane`)

> **Load when:** opening a bug-bounty run where a target scope (vendor / product / version /
> CPE) has been provided, or when the orchestrator needs to understand how prior CVEs and
> public writeups are distilled into ranked, provenance-tagged `promising_lanes` rows before
> Phase 0.
>
> **Strategy:** `prior_art_intake_lane` (id 25, seeded in `db/seed/strategies.yml`)
> **Phase:** L-1 — Prior-Art Intake (phase token `phase_l1_prior_art`; runs **before** Phase 0
> Decompose, before any codebase sweep)
> **Tiers:** Required at **DEEP** when a target scope is provided (blocking via
> `v_required_deep_lanes`); documented-skip fallback when scope is absent or a CVE source is
> unreachable

---

## Purpose

The lane mines public prior art — CVEs and community writeups — for the user-supplied target
scope and distils high-yield leads into the existing `promising_lanes` feed-forward system
**before Phase 0 even opens the tree.** Round 1 therefore starts with ranked, provenance-tagged
candidate lanes sourced from real exploit history, not just from pattern-sweep intuition.

This is *scope-provided* target identity only. No code-derived component detection, no
black-box recon, no fingerprinting. The user or bug-bounty brief supplies the vendor, product,
version, and/or CPE identifiers; the lane keys every query on those literals.

---

## Activation Gate

The lane is **mandatory DEEP** when a target scope is provided. When no scope is given (pure
offline codebase audit) **or** a CVE source is unreachable (no network), the lane records
`agent_steps.status = 'skipped'` plus a `termination_reason` and halts cleanly —
`v_lane_coverage` treats a documented skip as satisfying the roster gate. This mirrors the
Phase L0 (no-`.git`) documented-skip precedent exactly.

---

## Sources

| Source | Query anchor |
|---|---|
| NVD | product name / CPE |
| GitHub Security Advisories (GHSA) | vendor / package name |
| OSV | package + ecosystem |
| exploit-db | product keyword |
| Web writeups | scope identifiers via WebSearch / parallel-web-search / tavily — blogs, HackerOne, GitHub issues, Twitter/X |

Subagents reach network sources through the available web tools (`WebSearch`, `WebFetch`,
`parallel-web-search`, `tavily`). The lane is **distillation-first** — it does not attempt to
download the complete CVE corpus for the product. The verifiable success gate is the
*per-source provenance record*, not a CVE count.

---

## Persistent Storage

### `cves` table

Persists one row per CVE-source pair (same CVE from two sources → two provenance rows):

| Column | Notes |
|---|---|
| `id` | surrogate PK |
| `target_id` | FK → `targets` |
| `cve_id` | TEXT — e.g. `'CVE-2024-1234'` or `'GHSA-xxxx-yyyy-zzzz'` |
| `product` | free text product name |
| `cpe` | CPE 2.3 string (nullable) |
| `version_range` | affected version expression (nullable) |
| `cvss` | REAL score (nullable) |
| `summary` | short description |
| `source` | TEXT CHECK IN (`'nvd'`, `'ghsa'`, `'osv'`, `'exploit-db'`) |
| `published_at` | TIMESTAMP (nullable) |
| `raw_ref` | URL or identifier; truncated when source payload >16 KB |
| `raw_sidecar_path` | filesystem path to full payload when `raw_ref` > 16 KB (nullable) |
| `created_at` | TIMESTAMP DEFAULT now() |

**Natural key:** `UNIQUE(target_id, cve_id, source)` — intentionally allows the same CVE from
two sources as distinct rows so provenance is lossless.

### `writeups` table

| Column | Notes |
|---|---|
| `id` | surrogate PK |
| `target_id` | FK → `targets` |
| `url` | canonical writeup URL |
| `title` | page title or slug |
| `source` | OPEN free TEXT (blog name, `'hackerone'`, `'github'`, `'twitter'`, …) |
| `summary` | extracted or LLM-condensed summary |
| `bug_class` | OPEN free TEXT — mirrors `promising_lanes.vuln_class` vocabulary |
| `related_cve_id` | nullable FK → `cves.id` |
| `created_at` | TIMESTAMP DEFAULT now() |

**Natural key:** `UNIQUE(target_id, url)`.

### Put-batch ordering

In any `Put` batch: **`cves` must flush before `writeups` and before `promising_lanes`.**
The cross-table FKs `related_cve_id` (writeups → cves) and `derived_from_cve_id`
(promising_lanes → cves) are validated app-side in `db/harness/put.go` `fkRefs` — a row
referencing an un-flushed cve will fail FK validation.

---

## Distillation into `promising_lanes`

The lane does **not** bulk-import CVEs as findings. It reads the harvested `cves` and
`writeups` rows, identifies high-yield attack directions (recurring bug classes, chained
exploit patterns, version-range overlaps with the target build), and emits a `promising_lanes`
row per confirmed lead. Each emitted row carries:

- `derived_from_cve_id` — nullable FK → `cves.id` (set when a CVE is the primary source)
- `derived_from_writeup_id` — nullable FK → `writeups.id` (set when a writeup is the primary
  source)
- `region_hash = '__TARGET_WIDE__'` — for leads that are not yet anchored to a specific file
  or symbol (already supported by the `promising_lanes` NK)

These provenance columns are **new additions** to the existing `promising_lanes` table
(`db/migrations/0026-prior-art-intake.sql`). All other `promising_lanes` mechanics —
`lane_hash` dedup, `v_promising_lanes_ranked` read-time `promise` scoring, round-entry
**fetch (10)** consumption, `promoted_to_round_id` closure — are unchanged.

**Single-writer rule applies:** subagents emit row-shaped events; the orchestrator alone
flushes to the DB.

---

## Round-1 Consumption

Distilled lanes surface in `v_promising_lanes_ranked` alongside any lanes emitted by Phase
0.38.0's Phase-1-end feed-forward. The round-1 entry fetch (10) picks them up exactly as it
does any other unpromoted lane. Acting on a lead stamps `promoted_to_round_id = 1`.

No new feed-forward plumbing is introduced. This lane plugs into the existing machinery at
the *emit* end.

---

## `coverage_json` Self-Attestation

The lane stamps `agent_steps.coverage_json` with the per-source provenance record:

| Key | Meaning |
|---|---|
| `sources_queried[]` | list of sources actually queried (e.g. `["nvd","ghsa","osv","writeups"]`) |
| `nvd_count` / `ghsa_count` / … | rows stored per source |
| `writeups_count` | writeup rows stored |
| `promising_lanes_emitted` | count of `promising_lanes` rows distilled this run |

The completeness proof is this per-source record — "we asked NVD and stored what NVD gave,"
not an unfalsifiable "all CVEs." A source that was unreachable is logged in
`sources_queried[]` with count `0` and a note; it does not block the lane from completing on
the remaining sources.

---

## Lane-Done Gate

The lane is complete when:

1. `coverage_json` records every attempted source with a count (zero is acceptable with a note), **and**
2. At least one `promising_lanes` row has been emitted with a provenance link, **or** the lane
   records a documented skip (`status = 'skipped'`, `termination_reason` set) because no scope
   was provided or all sources were unreachable.

`v_required_deep_lanes` surfaces the lane as `MISSING` (HARD-RED) when the current round has
neither a completed nor a skipped `agent_step` for `phase_l1_prior_art`.

---

## Relationship to Downstream

- **Phase 0 Decompose** — runs *after* this lane; the `promising_lanes` rows emitted here are
  already in the DB when Phase 0's whole-tree sweep begins, so round-1 fetch (10) has a warm
  prior-art seed to rank alongside pattern-sweep candidates.
- **Round-entry fetch (10)** — the existing `v_promising_lanes_ranked` path picks up
  distilled lanes by `promoted_to_round_id IS NULL`; no structural change to the view or
  fetch logic.
- **C2 `overlooked_lane_audit_lane`** — runs last; it can read the `promising_lanes` rows
  emitted here (via `derived_from_cve_id` / `derived_from_writeup_id`) as part of its
  emitted-but-unpromoted signal, giving the self-audit full provenance visibility.

---

## References

- Schema migration: `db/migrations/0026-prior-art-intake.sql`
- Strategy seed: `db/seed/strategies.yml` — `prior_art_intake_lane` (id 25)
- Gate view: `v_required_deep_lanes` in `db/schema.sql` (phase token `phase_l1_prior_art`)
- Feed-forward wiring: `references/v2/round-feedforward.md` — fetch (10), `v_promising_lanes_ranked`
- Promising-lanes mechanics: `db/migrations/0025-promising-lanes.sql`
- Phase L0 documented-skip precedent: `SKILL.md` § Phase L0
- Put-batch FK validation: `db/harness/put.go` `fkRefs`
- Spec: `.omc/specs/deep-interview-vuln-research-three-enhancements.md` — C1 (AC-1.x)
