---
name: refurbisher
description: >
  Use before scaffolding a project, platform, subsystem or non-trivial module; when a
  request names something that may already exist (an observability platform, a sandbox,
  an eval harness, a workflow or query engine, "extract an IR", "match Excel's results");
  when architecting a system whose parts others have built; or when an implementation of a
  problem others have solved keeps failing. Instead
  of coding passively, investigate who already did the hard part: products, standards,
  reference implementations, and modules or files inside mature projects. Test the fit on
  one real case, name the precise gap, and stop to give the user alternatives (adopt and
  adapt, extend, fork, port or copy, build). Vets every source with license and malware
  gates, A–D trust tiers and vibe-code detection; reuses by depending, forking or
  copy-paste with attribution. Also use for "does something for X exist" or "should I trust
  this repo". Not for small code, factual lookups, or habits any good agent already has.
---

# Refurbisher

Coding agents are passive. The user asks for a platform and the agent starts scaffolding
one. Good engineers first ask who already did the hard part. Often the requested product
mostly exists, the problem has a standard, or a mature project contains the exact code. The
project then becomes an adapter, a port or a fork instead of a new system. Old-school
copy-paste from a good source still works.

This skill makes the agent stop before scaffolding, investigate, and come back with
alternatives. Taking code from a bad source is worse than writing it yourself, so every
candidate is vetted first.

## When to run

Run it before the first scaffold, when any of these is true:

- **The request names a category that probably exists** as a product or platform:
  observability, error tracking, workflows, BI dashboards, search, chat UI, admin, wiki.
- **The request is too broad to fix the representation** ("extract an IR", "add a DSL", "a
  sync layer"). First establish what the result must answer.
- **It is security-critical infrastructure:** sandboxes, authentication, cryptography,
  parsers of untrusted input. Never improvise these; excellent implementations exist.
- **The task is new but popular**, as most AI tooling is. Ask whether it has already been
  standardized: OpenTelemetry GenAI conventions, MCP, SWE-bench's instance format, the edit
  format the model was tuned on.
- **Another product defines the behavior** ("same result as Excel", "Sentry-compatible",
  "works like git"). Someone has already matched it.
- **An old hard problem hides inside a new feature:** timers at scale, caching under scans,
  scheduling, query planning. Mature systems such as the Linux kernel, databases and
  compilers have the answer and the reasoning behind it.
- **An implementation keeps failing** on something that isn't specific to this project.

### What doesn't count

- Small code the agent writes correctly in minutes, the project's own business rules, and
  glue between things already in the project.
- Factual lookups such as a price, a version or a config key. Look them up; there is no
  decision to make.
- Habits every good agent already has: git for snapshots, the language server for
  diagnostics, the stdlib CSV parser.
- Tricks inside a design that is already settled.

## The investigation

Do this before writing any scaffolding. Keep it proportional: an hour of investigation
against weeks of building.

1. **Pin down the downstream questions.** What must the result answer or do? "IR" might mean
   locating declarations, resolving calls, following data or transforming code, and each
   points to a different representation. Ask the user when you can't tell.
2. **Find candidates at every scale:** whole products and platforms, standards and formats,
   reference implementations, and the modules or files in mature projects that solve the
   hard part. Start with the project's own dependencies and the platform. Read current docs
   and specs instead of working from memory. See the [search playbook](references/search-playbook.md).
3. **Test the fit on real material.** Map one representative case into the candidate's actual
   data model, or prototype the hardest required query on real source. Pick a case with the
   awkward parts: parallelism, retries, failures, edge inputs.
4. **Inspect what adoption costs:** deployment requirements, extension points, license,
   maintenance and lock-in.
5. **Vet the source** with the trust workflow below.
6. **Decide and name the gap.** If the model fits, the project may shrink to an adapter and a
   few specialized views. If it doesn't, name the exact missing capability before choosing
   to extend, fork, port or build a subsystem.

Then stop and report to the user before building anything.

The [worked examples](references/worked-examples.md) show the expected depth: an
observability platform, IR extraction, sandboxes, edit formats, benchmarks, MCP, timer
wheels, Excel parity, scripting, SQL engines, durable workflows and error tracking.

## Stop and give alternatives

The report to the user contains:
- **What exists**, and how much of the request it covers, with the evidence from the fit test.
- **The precise gap.**
- **Two to four alternatives:** adopt and adapt, extend, fork, port or copy the hard part,
  or build. Give each one's cost, license and lock-in, and recommend one.
- **An offer to go deeper on this case:** deploy the candidate and push a real run through it,
  prototype the hardest query, or read its extension API.

Write the report first (format under *Report*). Then, when the alternatives fit into four
options, ask with AskUserQuestion; otherwise end the turn with the report and its question.

Anything that changes *what is being built* always goes to the user: adopting a platform,
turning the project into an adapter, choosing a fork. Choosing a component inside a design
the user already chose can proceed without asking, under the autonomy rule in *Decide*.

## Quick reference

| Step | Do | Where |
|---|---|---|
| 1 Questions | What must the result answer or do? | ask when unclear |
| 2 Candidates | Products, standards, reference implementations, modules; docs, not memory | [search playbook](references/search-playbook.md) |
| 3 Fit | Map a real case, or prototype the hardest query | — |
| 4 Cost | Deployment, extension points, license, lock-in | — |
| 5 Vet | `python3 scripts/trust_signals.py <targets…>`, gates, vibe check, tier | below |
| 6 Gap | Name the missing capability | — |
| 7 Stop | Alternatives to the user; component-level autonomy rule | AskUserQuestion |
| 8 Integrate | Pin, attribute, isolate, test | below |

## Reuse ladder

Take the highest rung that fits:

1. **Already in the project:** an existing dependency or utility.
2. **Stdlib, platform or framework built-in.**
3. **Adopt a product or platform**, and build the adapter and the views it lacks.
4. **Depend** on a Tier A or B package, pinned.
5. **Fork, vendor, or start from a similar project** when you need changes, upstream is
   "done", or a mature project already has the shape you want. Keep the LICENSE and an
   upstream record.
6. **Port or copy-paste** files or functions from a trusted repo, with attribution, their
   tests and your adaptations. This is a first-class move, not a hack.
7. **Borrow the design.** Read it, then write your own. This is the only rung allowed for
   Tier C sources and for code whose license you can't take (for example GPL kernel code).
8. **Write from scratch**, only after the investigation found nothing, and say so.

The ladder orders the options in the report; it is not permission to act. Rungs 3 and 5
(adopting a platform, forking or starting from a project) always go to the user. The
autonomy rule under *Decide* covers only rungs 1, 2, 4 and 6 inside a design the user has
agreed to.

Authority is not the same as fit. Don't pull a framework for one function: copy the
function. Wrap fast-moving dependencies, such as AI SDKs and agent frameworks, behind a thin
adapter you own.

## Vetting sources

This is step 5 of the investigation. When the user only asks whether to trust a repo or
package, run it on its own.

**Signals.** The script path is relative to this skill's directory. Pass the package
whenever there is one, because adoption shows up in registry data, not in stars:

```bash
python3 scripts/trust_signals.py encode/httpx+pypi:httpx psf/requests+pypi:requests
python3 scripts/trust_signals.py npm:some-package               # repo resolved from registry
python3 scripts/trust_signals.py "https://github.com/o/r/blob/main/x.py#L10-L40"  # snippet: SHA permalink
python3 scripts/trust_signals.py --young-field org/new-ai-lib    # automatic for repos younger than 2 years
```

The output covers gates, flags, the vibe verdict, the mechanical tier with its unmet
criteria, and facts. A 4-candidate shortlist takes about 3 s. Tier `?` with `DATA
INCOMPLETE` means a source failed, so rerun. Non-GitHub hosts return partial data; verify
those by hand. The script needs `gh auth` or `GITHUB_TOKEN`.

**Hard gates.** Reject for any code reuse, with no override. Borrowing the idea is still allowed.

| Gate | Why |
|---|---|
| No license, or an unreadable custom one (a verified public-domain dedication, like SQLite's, passes) | All rights reserved; read for ideas at most |
| Package missing from the registry, or a typosquat | Hallucinated name or impostor (slopsquatting) |
| Unpatched CRITICAL advisory on the version you would use | Known, exploitable hole |
| Archived with no maintained successor | Follow the successor instead |
| Obfuscated code, install scripts fetching payloads, unexplained binaries | Supply-chain red flags |
| Likely vibe-coded (for depend, vendor or copy) | Unreviewed code; ideas only |
| Maintainer takeover followed by releases you can't explain | The xz-utils pattern |

Authority never unlocks a gate. Even serde_derive shipped a precompiled binary in 2023, and
the community made its author revert it.

**Copy-blocked licenses.** Source-available licenses (BUSL, SSPL, Elastic, FSL, Commons
Clause, non-commercial) are not a hard reject, because running the software, unmodified and
internally, may be allowed. Never copy, vendor or fork their code. Put "run it" in the
alternatives and let the user decide.

**Vibe check.** AI involvement is not the problem; *unreviewed* AI output is. Ask: *did a
human who understood this code decide each part of it?* The script scores the mechanical
tells (agent fingerprints, leftover `*_SUMMARY.md` files, `foo_fixed.py` next to `foo.py`,
code dumps, no tests, hype READMEs) against green signals (review culture, external
contributors, CI, releases). Then do the 5-minute read in the
[detection guide](references/vibe-code-detection.md).
- **LIKELY VIBE-CODED:** Tier D for any code reuse.
- **SUSPECT:** cap at Tier C until your read clears it.
- **No strong tells:** no cap.

**Tier.**

| Tier | Meaning | Reuse allowed |
|---|---|---|
| A | Adopt | Any rung |
| B | Adopt with care | Pinned dependency, vendor, or copy after reading the code you take |
| C | Reference only | Borrow the design; write your own |
| D | Reject | No code reuse; the idea at most. Record why |

The script picks one of two tracks:
- **Established:** age ≥ 3 years, active within a year, ≥ 10 contributors, strong adoption
  (≥ 1k dependent repos or ≥ 1M downloads/month; ≥ 5k stars only when no package was
  given), Scorecard ≥ 6, no vibe tells.
- **Young field** (AI/ML and new ecosystems; automatic under 2 years old): age and adoption
  can't separate good from bad yet, but engineering discipline can. It needs an
  organization or ≥ 3 real maintainers, review culture, green CI, tests, ≥ 3 versioned
  releases, activity within 60 days and external users filing issues. Tier A also needs a
  named backing anchor: a lab, company, foundation, author pedigree or paper.

The metric tier is where you start, not the verdict. Override it with named, linked
evidence: pedigree, downstream endorsement, canonical or reference status, done by design,
development that lives off GitHub, formal assurance, inherited review. Demote with named
evidence too: a maintainer takeover, an org demo repo, a relicense, hype velocity, a history
of sabotage. Put the reason in the report, for example `SQLite: A (override from C: Fossil
mirror, closed contribution by design; ships in Android, iOS and every major browser)`. If
you can't link the anchor, treat it as doubt. See the
[calibration examples](references/authority-calibration.md).

## Decide

Anything that changes what is being built goes to the user (see *Stop and give
alternatives*). For a component inside an agreed design (ladder rungs 1, 2, 4 and 6), adopt
**without asking** only when all of these hold:
- Tier A, either mechanical or by an override with a verified, linked anchor.
- No gate hit, and a license that is permissive or compatible with the project.
- A clear winner, with no other Tier A candidate whose trade-offs the user should weigh.
- No lock-in on architecture the user hasn't chosen (framework, database, runtime, hosting).

Then proceed and report it in one line. Otherwise ask with AskUserQuestion:
- Up to 4 options, with the recommended one first and marked "(Recommended)".
- Each description gives the tier, reuse mode, license and the single deciding piece of evidence.
- Include "Write it ourselves" when no candidate reaches A.

## Integrate

- **Adopt a platform:** keep your code in an adapter you own (exporters, API clients, views),
  so that the platform can be swapped. Record the version and the deployment requirements.
- **Depend:** install the exact registry name you vetted, copied from the project's README,
  not from memory. Pin it in the lockfile and record why in the commit or an ADR.
- **Vendor, fork or start from a project:** put vendored code in `third_party/<name>/` with
  its LICENSE and an `UPSTREAM.md` recording the URL, commit SHA, date, local patches and
  update procedure. Delete what you don't use.
- **Port or copy-paste:**
  1. Copy from a SHA-pinned permalink (the script prints one).
  2. Take the smallest closed set: the function plus the helpers it calls.
  3. Add a header comment with the permalink, the SPDX license and the original copyright.
  4. Rename things to the project's style, but keep the logic.
  5. Bring the upstream tests along, and add your own for your changes.
- **Design:** cite the source in a comment or ADR, and don't transcribe its code.

## License policy

| License | Action |
|---|---|
| MIT, BSD, Apache-2.0, ISC, Zlib, 0BSD, Unlicense, CC0, public domain | OK. Keep notices; Apache-2.0 also needs NOTICE |
| MPL-2.0, LGPL, EPL | Flag. Fine as a dependency; copied or modified files keep their copyleft |
| GPL | Flag. Must be compatible with the project's license once distributed; otherwise borrow the design only |
| AGPL | Flag strongly. Network use triggers source disclosure; running it unmodified as a separate service is usually fine |
| BUSL, SSPL, Elastic, FSL, Commons Clause, non-commercial | Copy-blocked (see *Vetting sources*). Running internally may be allowed; ask the user |
| Open-core repos (`ee/`, `enterprise/` directories) | OK outside those directories; never copy from inside them |
| None, or "all rights reserved" | Gate. Reading only |
| CC BY-SA (Stack Overflow) | Flag. Attribution and share-alike apply; prefer reimplementing the idea |
| Model and dataset licenses (Llama, Gemma, OpenRAIL, CC BY-NC) | Flag separately from the code license |

If the project has no license yet, choosing a GPL dependency effectively decides it, so ask.

## Report

```markdown
## Refurbish report: <project or component>
Request: <what the user asked for>, downstream questions: <what it must answer or do>
Exists: <candidate> covers <part>. Fit test: <the real case mapped or query prototyped, and the result>
Gap: <the precise missing capability>
Alternatives: <adopt and adapt | extend | fork | port | build>, each with cost, license, lock-in
Recommended: <one>, because <deciding evidence>
Deeper research on offer: <the next case-specific step>

| Capability | Pick | Mode | Tier | License | Evidence |
|---|---|---|---|---|---|
| <capability> | <name version> | platform/depend/vendor/port/design | A | MIT | <decisive facts or anchor> |
Rejected: <name> (<gate or vibe tells>)
```

## Gotchas

- **Read the docs before coding.** A protocol, SDK or format written from memory targets the
  version the model remembers, not the current one.
- **Stars are the weakest signal.** A 2024 study found about 4.5M suspected fake stars on
  GitHub. Prefer dependents, downloads, external issues, and *who* depends on the project.
- **Registry-to-repo links are self-declared.** Any package can claim
  `github.com/psf/requests` as its repository, so vet the package name, not the repo URL.
- **Repos move.** CEL moved from `google/` to `cel-expr/`, and Tink to `tink-crypto/`. A
  name remembered from an old blog post may now point to something else, so confirm it.
- **AI fingerprints work in one direction only.** No AI trailers doesn't mean human code, and
  `CLAUDE.md` or `AGENTS.md` doesn't mean vibe code: SQLite has an `AGENTS.md`.
- **Mirrors show no PRs, issues or CI by design** (SQLite, Linux, PostgreSQL); judge them by
  their upstream.
- **GitHub `NOASSERTION`** means an unrecognized license: dual, open-core or custom. Read the
  LICENSE file.
- **A big org is not an authority** ("not an officially supported product", samples, archived
  experiments). **A solo author is not untrustworthy** (stb, SQLite, serde).
- **Research repos are reference-grade.** Prefer the version absorbed into a maintained library.
