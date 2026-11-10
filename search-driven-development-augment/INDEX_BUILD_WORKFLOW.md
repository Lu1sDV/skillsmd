# Building a repository index: orchestrated workflow

Companion to `SKILL.md` (entry format, writing rules, per-repository analysis). `SKILL.md`
defines one entry; this file defines the pipeline that produces a whole index for a
project: which problems to search by, which repositories to include, how entries are
written in parallel, merged and tested. It is independent of domain, language and tooling
vendor; angle-bracket names are placeholders. Figures marked *(reference run)* come from
one run that produced 120 entries from 35 problems and are given as scale markers, not
targets.

## Roles

| Role | Reference run | Task |
|---|---|---|
| Orchestrator | 1 | Plans, dispatches, merges, verifies; edits only mechanical fixes |
| Council | 2 | Converge on the project's engineering problems before any search |
| Discovery scouts | 4, one per problem group | Find repositories absent from existing sources |
| Gap scout | 1 | Check which known or notable repositories are missing from existing analysis |
| Capture scouts | 4, 8–13 repositories each | Save third-party documentation captures for the core list (optional) |
| Index scouts | 18, 5–7 repositories each | Write entries per `SKILL.md`, one shard file each |
| Routing tester | 1, fresh context | Route probe tasks using the index alone |
| Derived-extraction scouts | 1 | Extract another artefact (patterns, ideas) from repositories chosen out of the index |

Scouts are read-only except for their own output file. Each brief is self-contained:
scouts share no context with the orchestrator or each other.

## Phase 0: inputs

1. Read the project's spec entry points and every existing survey or catalogue. Build a
   normalised `owner/repo` list of everything already covered (lowercase; a noisy superset
   is acceptable because it is used only to exclude).
2. Fix the output directory and its documentation rule (for example: every folder has a
   README listing its contents). Check that the requested path exists; if it does not, use
   the sibling directory that holds the earlier survey and say so.
3. Check tooling before dispatch: forge CLI authentication and rate limits, whether
   third-party documentation sites are readable by the available fetch tool (some sit behind
   bot checks and need a rendered-browser fallback), free space in the scratch directory.
4. Record the owner's seed list, if any (the "core list"), with current canonical names.

## Phase 1: problem council

Goal: a search frame that adds dimensions instead of repeating the owner's seed list.

- Two scouts. Each names its peer, drafts independently into its own file, messages the
  peer a short pointer, reads the peer's file, and converges in one round. One scout is the
  final author of `research_problems.md`; the other sends objections and additions only.
  The final author reads the peer's file before finishing.
- Brief supplies: the owner's decomposition, the project's entry documents, the theme table
  of any earlier survey (so problems add dimensions rather than repeat).
- Row format: ID (`P01..`), area (owner's areas plus `E-new` for areas the owner did not
  name), problem name, structure (resource, invariant, failure mode), names the same
  problem has in neighbouring domains, 3–6 search keywords.
- Expect problems outside the owner's own domain: measurement and statistics, cost and
  budget control, provenance and audit, isolation, access control, retrieval, authoring UI.
  *(reference run: 35 problems; the council also covered the owner's four areas.)*

## Phase 2: discovery, gap check, captures (parallel, one dispatch)

### Discovery scouts
- Split by problem group (about 8–10 problems each).
- Brief supplies: `research_problems.md`, the covered list, the core list, tool notes.
- Rules: a candidate is absent from the covered and core lists; verify with the forge API
  (stars, SPDX licence, last push, archived, fork, language) and by reading the README plus
  one source file; reject toys, forks, archived and unmaintained repositories (no push in
  18 months) unless historically important; state in one sentence what it has that the core
  list and earlier surveys lack; give a start path and an evidence column.
- Output: a table (repo, stars, licence, language, last push, problem IDs, unique feature,
  start path, evidence); target 15–25 rows per scout.
- Search APIs are rate-limited and parallel scouts exhaust them within minutes. Scouts then
  fall back to candidate lists from prior knowledge verified through the non-search API and
  must say so. Stagger scouts or pre-collect candidate lists when exhaustiveness matters.
- Apply a star floor (reference run: fewer than 10 stars excluded) before indexing.
  Problem groups served mostly by small or academic repositories come back thin; record that.

### Gap scout
- Part 1: for each repository of the core list, report presence in every existing source
  with where it was found (section id or line), plus renames and redirects of repositories
  and stale names that resolve to unrelated projects.
- Part 2: up to 30 notable repositories absent from every source, tied to problem IDs.
  Features not read in the repository are marked `[K]` (general knowledge) and are not
  carried into entries.

### Capture scouts (optional)
- Per repository: fetch the third-party documentation site's overview, architecture page
  and 4–8 pages relevant to the problems; write `<capture-dir>/<owner>__<repo>.md`.
- File header: source URL, indexing date of the captured version, page URLs fetched,
  relevant problem IDs. Body: navigation and generated source lists removed; headings,
  tables, code, diagram labels and source citations kept. Not available: a file stating
  that, plus the repository URL.
- Captures are generated text about the repository at an older commit; they are a claim
  source, not evidence. Index scouts record where the code contradicted a capture.
- Give index scouts a side task: for repositories above a popularity threshold with no
  capture, fetch one.

## Phase 3: master list and shards

1. Merge the core list (current canonical names), discovery rows above the floor, and gap
   extras; de-duplicate by canonical name (the same repository appears in several sources).
2. Shard by theme, not alphabetically, so sibling repositories sit in one scout's context
   and paragraph 5 ("differs from siblings") is written against real neighbours.
3. Shard size 5–7. Wall time per shard in the reference run was 8–26 minutes, longest where
   repositories are large monorepos. Do not go above 7.
4. Stage inputs: candidate tables under `/tmp/<run>/candidates/`, a verbatim copy of
   `SKILL.md` as the spec, a private clone root per scout.

## Phase 4: index scouts (parallel)

The shared brief supplies: the spec path, per-repository inputs (candidate notes as leads,
capture as orientation, the source), and task rules. Each task brief supplies the shard
number, the repository list and any scope restriction (for example "only the sandbox
crate", "only the permission module").

Rules that held:
- Candidate notes and captures are leads; claims are re-verified in code. A mechanism that
  could not be traced is described as not verified, inside the paragraph where it matters.
- Datasets and corpora: trace one record from the raw file through the schema and labelling
  procedure; methodology and verification evidence go in paragraphs 2–3.
- Paragraph 5 states licence (SPDX plus file-level caveat), latest release or push date and
  stars as neutral facts, plus the difference from sibling entries and from named core
  entries.
- Output: one file per shard containing only entries in list order, then a line `---` and a
  `META` block, one line per repository:
  `owner/repo | stars | licence | last push | problem IDs | verified` where `verified` is
  `yes`, `partial` or `readme-only`; partial entries name the untraced parts.
- Shallow or sparse clones, private to the scout, deleted afterwards; forge API for issues,
  releases and file contents.

Discovery and capture notes contain errors at a rate that rules out copying: scouts
corrected claims about analysis scope (a tool described as taint-capable had no taint code),
derived-versus-stored state, which clock a limiter uses, whether a sandbox still relies on
a legacy mechanism, whether a round-trip preserves unrelated text, whether a default
applies always or only when a setting is absent, and whether a documented termination
guarantee exists in code.

Failure modes and fixes:

| Failure | Cause | Fix |
|---|---|---|
| Clones under wrong names, other scouts' clones deleted | Shared clone directory, shell loop race, broad cleanup | Private clone directory per scout; delete only own files |
| Disk quota errors, partial checkouts | Many scouts on a small scratch filesystem | Blobless or sparse clones, tarballs, forge API reads; entry marked `partial` |
| Clones inside the project repository | Scout started in the project working directory | Brief states the clone root; orchestrator checks the project's `git status` afterwards |
| Entries longer than the length rule | Detail kept over length | Accept a modest overrun for dense repositories; trim only if routing suffers |
| Short names in entry titles | Scout used the short form | Merge step renames the i-th entry from the i-th META line (counts must match) |
| Template placeholders in META | Brief's format line copied | Merge step drops them |

## Phase 5: merge

One mechanical script run by the orchestrator:
1. Per shard: split entries on bold title lines; split META on `|`; assert entry count equals
   META count; replace titles with META names (strip parentheticals).
2. Build the problem-to-repository table from META problem IDs, joining problem names from
   `research_problems.md` so the index is readable without that file.
3. Write: header (scope, date, meaning of `verified`), entry-format note, problem table,
   entries in shard order, metadata table. Normalise dates to `YYYY-MM-DD`.
4. Check: entry count equals metadata rows; every shard parsed; READMEs updated.

## Phase 6: routing test

A fresh scout whose context is the index file only; it opens no other file or repository.
Probe set of about 20, covering the cases `SKILL.md` step 7 requires:
- tasks a repository solves as a whole;
- tasks that need one part of a repository;
- edge-case or invariant questions;
- "which mistakes should we avoid" questions;
- testing and practices questions;
- near-miss tasks that must yield NONE or a clearly partial answer (about three).

Write each probe so it joins two or more requirements; single-keyword probes only test
search. Output per probe: up to 3 ranked picks, a quoted phrase and paragraph number as the
reason, and whether the index alone decided. Then: confusing entries, index-level issues.

Interpretation:
- A "could not decide" answer is an entry defect only if the missing fact exists in the
  repository. If the corpus lacks the fact, record a research gap and feed it into the next
  discovery round. In the reference run, 15 of 20 probes were undecidable from the index
  alone, mostly because of corpus gaps.
- Typical index defects found: an entry with the wrong number of paragraphs; a problem tag
  unsupported by the body; mixed date formats; problem IDs not defined inside the index
  (the tester cannot map probes to them); sibling families told apart only by "Unlike X"
  sentences.
- Keep probe IDs and any derived artefact IDs (patterns, ideas) in different prefixes from
  problem IDs.
- Write expected answers before the test and score picks against them.

## Phase 7: derived extractions

With the index in hand, other extractions run from it by choosing repositories from its
entries. Pattern for any extraction (UX patterns, test strategies, schema designs, error
models):
- the orchestrator chooses repositories and groups them by the project surface they inform;
  the choice is judgement, because index entries are written for mechanisms and may not
  mention the extraction's topic;
- per item: name, what it does, how it is built, which project surface or document section
  it fits (a concrete id), caveat (licence, scale, accessibility or similar);
- evidence rule: source file read (repo-relative path), or marked capture-only, or marked
  name-only; nothing executed unless stated; licences checked only if the brief says so;
- output with a summary table, per-repository sections, cross-cutting items seen in three
  or more repositories, and skipped or thin repositories with reasons.

## Acceptance checks for the run

- Entry count equals metadata rows; every repository in the master list has an entry or a
  stated reason for exclusion.
- Every output directory has a README that lists its contents.
- The project repository's `git status` shows no files created by scouts.
- No scout ran tests, formatters or builds; nothing was committed unless requested.
- Routing results are recorded together with the corpus gaps they exposed.

## Tuning for the next run

- Discovery: stagger scouts or pre-collect candidates to avoid search rate limits; add a
  keyword sweep per problem.
- Verification depth: in the reference run 85 of 120 entries ended `partial`. For
  high-priority repositories, assign a second scout to the untraced parts named in META.
- Maintenance (`SKILL.md` step 8): re-run only shards whose repositories changed mechanism,
  then the routing test over the whole index.
