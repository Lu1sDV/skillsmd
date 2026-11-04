# Search playbook

How to find who already built it. Search for code, products and standards, not advice.
Work outward, from cheapest and most trusted to broadest. Read the current documentation
and specification of every candidate instead of relying on what you remember about it.

## Contents
1. Own house
2. Who already built it?
3. Registries (adoption-ranked)
4. GitHub search
5. Web and practitioner verdicts
6. Copy-paste sources: files, functions, well-eyed lines
7. AI/ML field sources
8. Query templates
9. Timebox and fan-out

## 1. Own house

- Read the project's manifests and lockfiles. A library already in the tree beats a
  better one outside it, because it adds no new dependency or supply-chain surface.
- Check the stdlib and the framework's built-ins (Django, Rails, Spring, Next.js).
  Batteries are usually included for HTTP, auth sessions, migrations, caching and validation.
- Check the user's other repositories if they have a house style.

## 2. Who already built it?

Run these searches in parallel (one subagent per row is fine). Every one of them returns something you can test against a real case.

| Look for | How | Example |
|---|---|---|
| The product the request describes | `"open source" <category> self-hosted`, the category's awesome-list for discovery only, then compare data models | "observability platform for agent harnesses" leads to Langfuse; map one real run into its traces and observations |
| A standard for the category | `<category> specification`, `<category> semantic conventions`, `<task> benchmark format` | OpenTelemetry GenAI conventions, MCP, SWE-bench instances, a model's native edit format |
| The old system that solved the hard core | Name the underlying problem, then search how the kernel, a database or a compiler does it | a million connection timeouts leads to the Linux timer wheel, then to a permissive port |
| A library that does it | Registries (section 3); `gh search repos --topic <topic>` | `--topic rate-limiter --language=python` |
| A project that already contains it | `gh search repos "<kind of app> <stack>"`, then open its tree and find the module | building an invoicing app: open mature open-source invoicing apps and read their PDF and tax modules |
| Integration code for the same service | Code search on a distinctive import, endpoint or API call | `gh search code "stripe.subscriptions.create" --language typescript` surfaces freeCodeCamp's real subscription route |
| Official samples and templates | The vendor's samples org, or the framework's own template | `stripe-samples`, `microsoft/vscode-extension-samples`, `modelcontextprotocol/servers`, `vercel/examples`, `fastapi/full-stack-fastapi-template` |
| How serious projects structure the same shape | Pick 2–3 Tier A projects of the same kind and read their trees and module boundaries | `gh api "repos/<o>/<r>/git/trees/HEAD?recursive=1" --jq '.tree[].path' \| head -200` |
| What the giants depend on | Read the manifests and lockfiles of 2–3 well-known projects in the domain | `gh api repos/<o>/<r>/contents/pyproject.toml --jq .content \| base64 -d` |

Code search returns plenty of junk alongside the good hits. Searching `api.telegram.org/bot`
gives PoCs and toy bots first. Vet every hit with the script before copying anything.

Samples are teaching code: good for structure and integration calls, but check their error
handling before it reaches production. Code from AGPL apps can be read for design, but
copying it imposes AGPL (see the license policy).

## 3. Registries (adoption-ranked)

Registries measure use, not attention.

| Ecosystem | Search | Notes |
|---|---|---|
| npm | `curl -s "https://registry.npmjs.org/-/v1/search?text=<q>&size=20"` | Has `downloads.monthly`; its quality/maintenance scores are flat and not useful |
| crates.io | `curl -s -A "refurbisher" "https://crates.io/api/v1/crates?q=<q>&sort=downloads"` | Requires a User-Agent; `recent_downloads` exposes abandoned crates |
| PyPI | No search API: use web search `site:pypi.org <q>`, or GitHub search with `--language=python` | Then confirm with `pypi:<name>` in the script |
| Go | `https://pkg.go.dev/search?q=<q>` (web) | The "Imported by" count is the adoption signal |
| Any | `https://packages.ecosyste.ms/api/v1/registries/<registry>/packages/<name>` | Dependents and downloads; the script uses it |

## 4. GitHub search

Use GitHub search for discovery and the script for judgment. Plain `--sort=stars` with a
loose query surfaces popular, irrelevant repos ("rate limit" returns a Claude account
switcher first). Prefer topics or scoped matches:

```bash
gh search repos --topic rate-limiter --language=python --sort=stars --limit 15 \
  --json fullName,description,stargazersCount,pushedAt,license,isArchived
gh search repos "token bucket" --match name,description --language=go --stars=">200" \
  --updated=">2026-01-01" --archived=false --sort=stars --limit 15 --json fullName,stargazersCount,pushedAt
```

Filters worth using are `--archived=false`, `--updated=">YYYY-MM-DD"`, `--license mit`,
`--owner <org>` and `--topic`. Repo search hides projects that are not hosted on GitHub
(SourceHut, Codeberg, GitLab, Fossil, Savannah), so run a web search for those domains.

## 5. Web and practitioner verdicts

Use these to learn why people chose, or abandoned, something:

- `"<lib A> vs <lib B>" <year>` and `alternatives to <lib>`
- `site:news.ycombinator.com <lib>` and `site:reddit.com/r/<language> <lib>`. Look for
  "we migrated off X because…" threads; those carry the most information.
- Framework docs pages on integrations or recommended libraries; these are endorsement anchors.
- awesome-lists: discovery only. Being listed is not evidence of quality.

## 6. Copy-paste sources: files, functions, well-eyed lines

For a file- or function-sized need, search inside codebases with strong review cultures and
pin the source. Copy the smallest closed set (the function plus its helpers) together with
its tests:

```bash
gh search code "def bisect" --repo python/cpython
gh search code "token_bucket" --repo envoyproxy/envoy
gh search code "fn levenshtein" --language rust --owner rust-lang
```

| Source | Trust | License note |
|---|---|---|
| Stdlib and large mature monorepos (CPython Lib, Go src, LLVM ADT, Abseil, Chromium base) | High: inherited review | Keep the copyright line and SPDX |
| Reference implementations of papers or specs (Ryu, PCG, cmark) | High for the algorithm | Usually permissive |
| Official docs examples | Medium–high | Often permissive; check |
| Classic books and articles (Hacker's Delight, Russ Cox's regex series, Crafting Interpreters) | High as design | Code license varies; text often not reusable |
| Stack Overflow | Medium. The most-copied answer had a bug | CC BY-SA: attribution plus share-alike; prefer reimplementing |
| Rosetta Code | Low–medium | GFDL, awkward for code; use as design only |
| Gists, random blogs, LLM-generated tutorials | Low | Usually no license, so reading only |

Always run the script on the blob URL. It resolves a SHA-pinned permalink for attribution and
shows how recently, and by how many people, the file was touched.

## 7. AI/ML field sources

- Hugging Face papers pages link code. Model and dataset cards carry their own licenses,
  separate from the code license.
- A lab or company organization (vLLM, SGLang, DSPy, Hugging Face libraries, official SDKs
  of model providers and protocols) is a backing anchor for the young-field track.
- Research repos are usually reference-grade: pinned to old dependencies, no tests. Prefer
  the implementation absorbed into a maintained library, such as the PEFT version of LoRA
  rather than the paper repo.
- Thin wrappers whose core is one prompt plus one API call are not dependencies. Borrow
  the idea and write the 50 lines yourself on the provider SDK.

## 8. Query templates

```
open source <kind of app> built with <stack>
<service> integration <language> site:github.com
<feature> example <framework>
<capability> library <language> <current year>
best <capability> <language> production
<capability> reference implementation <spec/RFC number>
how does <tier-A project> implement <capability>
"<candidate>" deprecated OR abandoned OR unmaintained OR "moved to"
"<candidate>" vulnerability OR CVE OR malicious
```

The last two catch successors and incidents before you adopt.

## 9. Timebox and fan-out

- Look at 3–5 candidates per capability. For a component inside an agreed design, you may
  stop at the first Tier A fit. For anything that changes what is being built, collect the
  alternatives the report needs.
- At kickoff, with 3 or more capabilities, dispatch one subagent per capability. Each one
  returns candidate rows plus script output; you apply gates, overrides and the autonomy rule.
- If two searches return nothing above Tier C, stop searching and report to the user anyway:
  what you looked at, the best design you saw, and the recommendation to build.
