# Python Sink Research — Source Domain Analysis

## Data Limitation

This analysis is reconstructed from the merged methodology metadata in `vuln-research/references/sinks/python.md`.

- The original archived source files (~91 files) are no longer present on disk.
- I therefore cannot verify exact per-URL counts from the archive set itself.
- All counts below are **estimated** from the methodology notes, lane/source-type pairings, and the handful of named examples that remain in the merged file.
- The crawl summary still provides strong signals: **92 unique URLs**, **91 archived successfully**, **1 permanently offline** (`bittripping.com`), and **95 niche findings** extracted overall.

## Source Type Classification (Advanced NER)

### Categories Defined

The methodology naturally clusters sources into the following website-type classes:

1. **IT-security specialist blogs** — focused writeups from researchers or security practitioners; typically the most common source type.
2. **Writeup collections / CTF writeups** — challenge retrospectives, writeup aggregators, and competition-specific exploit notes.
3. **GitHub issues / bug trackers** — issue threads, maintainer discussions, bug reports, and repro cases.
4. **CVE references** — public advisories, NVD entries, vendor bulletins, and referenced exploit notes.
5. **Tool docs / library docs** — official docs, API docs, and behavioral references for standard libraries and frameworks.
6. **Academic / research papers** — sparse but high-value deep dives, usually used for obscure internals or foundational behavior.

### Estimated Distribution

| Website type | Estimated source count | Methodology basis |
|---|---:|---|
| IT-security specialist blogs | 38 | Dominant in class confusion, file ops, SSRF, SQLi, SSTI, numeric/string, and several protocol/infrastructure lanes |
| GitHub issues / bug trackers | 24 | Explicitly named for prototype pollution, async/generator, stdlib hidden sinks, type confusion, serialization, and obscure internals |
| CTF writeup collections / writeups | 14 | Concentrated in the CTF tricks lane and adjacent class-confusion style sandbox/jail notes |
| CVE references | 8 | Strongly represented in race conditions, serialization, file ops, SSTI-adjacent, and numeric/string bug classes |
| Tool docs / library docs | 6 | Most visible in stdlib hidden sink research and API behavior confirmation |
| Academic / research papers | 2 | Sparse, but explicitly mentioned for obscure internals |

**Interpretation:** the corpus is blog-heavy, but the highest-confidence technical validation comes from GitHub issues, CVEs, and tool docs whenever behavior needs to be pinned down.

## Known Domains (from Methodology)

The merged methodology preserves a small number of explicit domains and several broader platform families. Because the underlying archive is missing, the counts below are best read as **analysis buckets**, not a literal crawl ledger.

| Domain / family | Website type | Estimated source count | Status | Notes |
|---|---|---:|---|---|
| `blog.abdulrah33m.com` | IT-security specialist blog | 1 | Archived | Prototype pollution in Python example |
| `maplebacon.org` | CTF writeup collection | 1 | Archived | `dicectf2024` collection |
| `blog.antoine.rocks` | CTF writeup / IT-security blog | 1 | Archived | `ictf-2024` pyjails material |
| `wachter-space.de` | IT-security specialist blog | 1 | Archived | CSAW23 Python jail notes |
| `bittripping.com` | IT-security specialist blog | 1 | Permanently offline | The one known dead source |
| GitHub issue trackers (multiple repos) | Issue tracker / bug tracker | ~24 | Archived snapshots | Biggest platform family for behavior-confirmation threads |
| CPython bug tracker | Bug tracker | ~8 | Archived snapshots | Obscure internals, interpreter behavior, edge-case semantics |
| Tool docs / library docs | Documentation | ~6 | Archived snapshots | Stdlib and framework behavior checks |
| CVE references / advisories | Security advisory | ~8 | Archived snapshots | Public vulnerability confirmation and exploit context |
| Academic / research papers | Research paper | ~2 | Archived snapshots | Rare, used for deep internals and conceptual support |

## Per-Category Source Breakdown

The methodology summary exposes **15 named finding buckets** plus one residual row for completeness. The percentages below are estimated source-type mixes reconstructed from the lane metadata.

| Sink category | Est. findings | Dominant source mix | Reconstruction notes |
|---|---:|---|---|
| CLASS | 14 | Blogs 60%, CTF writeups 40% | Class confusion research leans toward exploit writeups and narrative blog proof-of-concepts |
| CPYTHON | 16 | GitHub issues / bug tracker 85%, papers 10%, blogs 5% | Interpreter internals and edge semantics usually need maintainer discussion or bug tracker context |
| STDLIB | 14 | Tool docs 35%, GitHub issues 35%, blogs 30% | Hidden-sink behavior is confirmed by official docs plus issue threads |
| CTF | 12 | Writeup collections 70%, individual writeups 30% | Sandbox/jail work is heavily concentrated in CTF retrospectives |
| FILE | 8 | Blogs 75%, CVEs 25% | File-path / archive extraction behavior is usually documented in practitioner posts, then grounded by advisories |
| ASYNC | 6 | GitHub issues 60%, blogs 40% | Async/generator edge cases are often surfaced as reproducible issue reports |
| RCE | 4 | Blogs 50%, GitHub issues 25%, tool docs 25% | Direct code-execution sinks need both exploit examples and API semantics |
| DESER | 4 | CVEs 40%, blogs 35%, GitHub issues 25% | Deserialization research repeatedly cross-checks public advisories and repros |
| PROTO | 4 | Blogs 55%, GitHub issues 45% | Prototype pollution research is blog-led but frequently validated through issue threads |
| PROTOCOL | 4 | Blogs 50%, tool docs 25%, GitHub issues 25% | Protocol/infrastructure issues rely on docs for parser behavior and blogs for exploitation narratives |
| RACE | 3 | Blogs 60%, CVEs 40% | Race-condition findings are split between exploitation writeups and public vulnerability references |
| SSTI | 3 | Blogs 80%, CVEs 20% | SSTI in Python is mostly practitioner-driven research with occasional CVE anchoring |
| SSRF | 1 | Blogs 100% | Single-point source-of-truth style research; mostly practitioner posts |
| SQLI | 1 | Blogs 100% | Minimal distribution because the lane is straightforward and source-light |
| NUMERIC | 1 | Blogs 70%, CVEs 30% | Numeric/string edge-case behavior is usually explained in blog form, then cross-checked against advisories |
| Residual / uncategorized | 0 | N/A | No extra category was exposed in the merged stats; this row is included only to make the bucket map explicit |

## Frequency Analysis

### Estimated website-type frequency

| Website type | Est. occurrence among 92 URLs | Relative frequency | What it contributed |
|---|---:|---:|---|
| IT-security specialist blogs | 38 | High | Primary discovery layer across most non-CTF lanes |
| GitHub issues / bug trackers | 24 | High | Best source for reproducible interpreter/library edge cases |
| CTF writeup collections / writeups | 14 | Medium | Concentrated exploitation patterns for jails, confusion bugs, and sandbox escapes |
| CVE references | 8 | Medium-low | Strong anchor for race/deserialization/file-safety claims |
| Tool docs / library docs | 6 | Medium-low | Semantic validation of stdlib and framework behavior |
| Academic / research papers | 2 | Low | Rare, but useful for obscure internals |

### Recurrence observations

- **Blogs recur the most broadly.** They appear across almost every major lane except the most maintainer-centric ones.
- **GitHub issues are the most valuable “hard evidence” layer.** They recur in CPython, stdlib, async, serialization, and prototype-pollution-adjacent work.
- **CVE references are selective but high-signal.** They cluster around race conditions, serialization, and file handling.
- **CTF writeup collections dominate only one lane, but that lane is dense.** The CTF bucket is smaller in count, yet disproportionately important for sandbox/jail techniques.
- **Tool docs matter where behavior is subtle.** They mainly support stdlib hidden sink claims and API-default assumptions.
- **Academic papers are rare, not absent.** They are reserved for interpreter internals and conceptual validation rather than routine sink discovery.

## Methodology Notes

### Reconstruction approach

1. **Start from the merged sink file, not the missing archive.** The missing 91-file archive cannot be re-read, so the analysis uses the preserved methodology summary as the source of truth.
2. **Map lane → source-type hints.** The methodology explicitly names which source types were used per lane; those hints provide the strongest evidence for category-level distribution.
3. **Use category totals as weight anchors.** The 95-finding breakdown gives a rough proportion signal for how often each lane was represented.
4. **Treat named domains as exemplars, not a complete inventory.** The methodology only preserves a handful of explicit domains, so the rest are grouped into platform families.
5. **Mark every numeric as estimated.** No claim here is presented as a literal archived count unless it was explicitly stated in the methodology notes.

### Confidence level

- **High confidence:** overall totals, named example domains, dominant website-type families, and the fact that the archive is missing from disk.
- **Medium confidence:** per-category source-type mixes and domain-family recurrence.
- **Low confidence:** exact per-domain counts beyond the named examples, because the original files are gone.

### Practical takeaway

The source corpus is best understood as a **blog-first research set with a strong GitHub-issues validation layer**, supplemented by CVEs and docs for semantic precision. The CTF lane is smaller but unusually dense, while academic references are sparse and targeted.
