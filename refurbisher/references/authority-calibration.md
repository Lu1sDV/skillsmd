# Authority calibration

Metrics give a starting tier. Authority is what experienced engineers recognize when the
metrics are wrong. This file turns that intuition into **anchors**: named evidence you can
link. The examples are for calibrating judgment, not a whitelist. Re-check current state
with the script, because projects change hands, relicense and die.

## Contents
1. Rules
2. Promotion anchors and how to verify them
3. Demotion evidence
4. Calibration examples where metrics miss authority
5. Calibration examples where metrics trust bad software
6. Young-field (AI/ML) calibration

## 1. Rules

1. **Intuition must become an anchor.** "Everyone uses it" is not evidence. Name who
   vendors it, who wrote it, which spec it implements, or where development really
   happens, with a link.
2. **Anchors move tiers; they never unlock hard gates.** License, malware signals,
   unpatched critical CVEs and vibe-coded verdicts stand.
3. **Demotions need named evidence too.**
4. **Show the work** in the report: `<name>: A (override from C: <anchor>, <anchor>)`.
5. **An unverifiable override is doubt,** and doubt means you ask the user.

## 2. Promotion anchors and how to verify them

| Anchor | What it means | How to verify |
|---|---|---|
| **Pedigree** | The authors wrote other Tier A software | Their other repos (`gh api users/<u>/repos --jq 'sort_by(-.stargazers_count)[:5][].full_name'`), talks, papers |
| **Downstream endorsement** | Vendored or depended on by Tier A projects, a distribution, or a language stdlib | `gh search code "<name>" --repo chromium/chromium`; packages.debian.org; dependents on deps.dev or ecosyste.ms; stdlib docs |
| **Canonical / reference** | Reference implementation of a spec, RFC or paper, or written by the spec authors | The spec or paper links it; authors overlap |
| **Done by design** | Narrow scope, stable API, low churn on purpose | Open issues are questions, not bugs; the maintainers say it is feature-complete; it is still used widely |
| **Lives elsewhere** | GitHub is a mirror; real development is on a mailing list, Gerrit, Fossil, SourceHut or GitLab | Repo description says "mirror", issues are off, the homepage points elsewhere |
| **Formal assurance** | Formally verified, publicly audited, or continuously fuzzed | Audit reports, verification papers, the OSS-Fuzz project list |
| **Inherited review** | The snippet lives inside a Tier A monorepo | A SHA-pinned permalink into CPython, Go, LLVM, Abseil or Chromium |
| **Stewardship** | Hosted by a foundation (Apache, Linux Foundation/CNCF, PSF, PyTorch Foundation, OpenJS, Eclipse) | Listed on the foundation's project page |

## 3. Demotion evidence

| Evidence | Precedent |
|---|---|
| Maintainer handover, then releases from the new person that you can't explain | xz-utils, 2024 (CVE-2024-3094): a patient social-engineering takeover of a burned-out sole maintainer. event-stream, 2018: a new maintainer added a malicious dependency targeting a crypto wallet |
| Account takeover history | ua-parser-js, 2021: hijacked releases shipped malware |
| The author has sabotaged their own package | colors.js and faker.js, 2022; node-ipc, 2022 (protestware) |
| Binary artifacts in source or package | serde_derive, 2023: shipped a precompiled binary and reverted after community pushback. Even authorities slip, so the gate stands |
| A big-org demo or sample | "This is not an officially supported product", `*-samples`, `*-demo`, archived experiments |
| Relicensed to source-available | Terraform (2023, forked as OpenTofu). Elasticsearch (2021) and Redis (2024) did the same and later added AGPL as an option; their community forks (OpenSearch, Valkey) remain permissive |
| Hype velocity | Stars far above dependents; fake-star campaigns |
| A popular snippet with a known bug | The most-copied Stack Overflow Java snippet (humanReadableByteCount) was flawed, as its own author wrote in 2019 |

## 4. Calibration examples where metrics miss authority

| Pattern | Examples | What metrics wrongly say | Anchor |
|---|---|---|---|
| Finished, not dead | zlib (years between releases), TeX (version converging on π), jq (no release 2018–2023), stb | "Inactive" | Done by design + downstream endorsement |
| Expert solo or small team | SQLite (open source, not open contribution), stb (Sean Barrett), serde/syn (dtolnay), LuaJIT (Mike Pall), QuickJS (Fabrice Bellard) | Bus factor 1, PRs ignored | Pedigree + endorsement |
| GitHub is a mirror | SQLite (Fossil), Linux (mailing lists), PostgreSQL, GNU (Savannah) | Issues off, no community | Lives elsewhere |
| Reference implementation of a paper | Ryu float printing (used by the MSVC STL), Eisel-Lemire parsing (Go `strconv`, fast_float in libstdc++), pdqsort (Go's `sort`; Rust's unstable sort derives from it) | Few stars, academic layout | Canonical + endorsement |
| Spec author's implementation | cmark and commonmark.js (by the CommonMark spec's author) | Modest stars | Canonical |
| Formally verified | HACL\* (CPython's hash implementations), fiat-crypto (BoringSSL) | Tiny community | Formal assurance + endorsement |
| New, from proven authors | uv (from the ruff team), Valkey (Linux Foundation fork of Redis) | Younger than 3 years | Pedigree / stewardship |
| Code inside a giant | A function from LLVM ADT, CPython `Lib/`, Go `src/`, Abseil | No per-file metrics | Inherited review |

Worked override: `sqlite/sqlite` comes out at metric tier C (no PRs, no CI, unrecognized
license). Anchors: lives elsewhere (Fossil; the GitHub repo describes itself as a mirror),
pedigree and review (D. Richard Hipp's team, extensive test suite), endorsement (ships in
Android, iOS and every major browser), and a public-domain dedication. Result: **A**.

## 5. Calibration examples where metrics trust bad software

- Old, ubiquitous and packaged everywhere, yet backdoored: **xz-utils**. Popularity is not proof of safety.
- 20k+ stars in weeks, a polished README, one huge commit, zero dependents: a hype or
  fake-star pattern. Check adoption and run the vibe protocol.
- An org name you trust on a repo that is a sample: check for "not officially supported"
  and look for a release history.
- Many contributors, all merging AI-generated bounty PRs with no review, and red CI:
  contributor count is not review culture.

## 6. Young-field (AI/ML) calibration

In young fields the best tools are 1–3 years old, so the age and adoption bars fail good
projects. The track swaps them for organization and engineering discipline, plus one
backing anchor for Tier A. Examples of the *kind* of anchor that counts, to re-verify
each time:

| Project | Anchor type |
|---|---|
| vLLM | Stewardship and origin: started at UC Berkeley; now a PyTorch Foundation project |
| SGLang | Lab: LMSYS |
| llama.cpp / ggml | Pedigree: the whisper.cpp author; the ggml-org organization |
| DSPy | Lab: Stanford NLP |
| Hugging Face transformers / PEFT / TRL | Company plus massive downstream use |
| Pydantic AI | Pedigree: the Pydantic team |
| Official protocol/provider SDKs (e.g. the `modelcontextprotocol` org) | Canonical: the spec owners |
| uv, ruff, ty | Pedigree: Astral (ty builds from the ruff repo) |

Patterns specific to AI:
- **Paper repos** are reference-grade. Prefer the maintained library implementation (PEFT
  over the original LoRA repo).
- **Thin wrappers**, where the core is one prompt plus one API call, are ideas, not
  dependencies.
- **Mega-frameworks** with high API churn: pin exact versions and isolate them behind an
  adapter. Check that you need the abstraction at all.
- **Separate licenses:** code, model weights and datasets each carry their own. A
  permissively licensed repo can download weights under a non-commercial license.
- **SOTA claims** need reproducible eval scripts. Leaderboard numbers alone are marketing.
