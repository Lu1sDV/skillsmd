# Offline Semgrep writing-rules documentation

> **Historical/upstream Semgrep documentation, NOT OpenGrep compatibility promises.** Semgrep branding and engine/product claims are intentionally retained. Use the skill’s OpenGrep adaptation reference before relying on any advanced feature.

Retrieved **2026-10-03**. Scope: **28 writing-rules pages** plus **1 supplementary troubleshooting page**. The live `llms.txt` lists 27 writing-rules pages; the sitemap adds `overview-1`. GitHub source at commit `ae5d563568a18368b7cf2706b9aa95c7dc6b9e26` independently contains those 28 page files, plus a shared overview snippet expanded by the published Markdown endpoint.

## Progressive reading

1. Start with overview, rule structure, pattern syntax, then testing and troubleshooting.
2. Load focused references for metavariables, generic matching, fixes, or dataflow only when needed.
3. Load taint advanced techniques for exactness, sanitization, side effects, labels, and propagators.
4. Experiments and join mode are archived for completeness, **not** endorsed as OpenGrep features. Private rules describe Semgrep platform functionality.
5. Use [offline playground snapshots](playground/cheatsheet.md) when a page delegates its example to an embedded editor. [Tooltip definitions](TOOLTIPS.md) preserve hover-only explanatory text.

## Pages

### Core syntax and workflow

- [Generic pattern matching](writing-rules/generic-pattern-matching.md) — `writing-rules/generic-pattern-matching.md`
- [Static analysis and rule-writing glossary](writing-rules/glossary.md) — `writing-rules/glossary.md`
- [Metavariable analysis](writing-rules/metavariable-analysis.md) — `writing-rules/metavariable-analysis.md`
- [Write rules](writing-rules/overview-1.md) — `writing-rules/overview-1.md`
- [Write rules](writing-rules/overview.md) — `writing-rules/overview.md`
- [Rule pattern syntax examples](writing-rules/pattern-examples.md) — `writing-rules/pattern-examples.md`
- [Rule pattern syntax](writing-rules/pattern-syntax.md) — `writing-rules/pattern-syntax.md`
- [Private rules](writing-rules/private-rules.md) — `writing-rules/private-rules.md`
- [Rule-defined fix](writing-rules/rule-defined-fix.md) — `writing-rules/rule-defined-fix.md`
- [Rule structure syntax examples](writing-rules/rule-ideas.md) — `writing-rules/rule-ideas.md`
- [Rule structure syntax](writing-rules/rule-syntax.md) — `writing-rules/rule-syntax.md`
- [Test rules](writing-rules/testing-rules.md) — `writing-rules/testing-rules.md`

### Dataflow and taint

- [Constant propagation](writing-rules/data-flow/constant-propagation.md) — `writing-rules/data-flow/constant-propagation.md`
- [Dataflow analysis engine overview](writing-rules/data-flow/data-flow-overview.md) — `writing-rules/data-flow/data-flow-overview.md`
- [Dataflow status](writing-rules/data-flow/status.md) — `writing-rules/data-flow/status.md`
- [Advanced taint analysis techniques](writing-rules/data-flow/taint-mode/advanced.md) — `writing-rules/data-flow/taint-mode/advanced.md`
- [Taint analysis overview](writing-rules/data-flow/taint-mode/overview.md) — `writing-rules/data-flow/taint-mode/overview.md`

### Experiments (upstream compatibility only)

- [Aliengrep](writing-rules/experiments/aliengrep.md) — `writing-rules/experiments/aliengrep.md`
- [Deprecated experiments](writing-rules/experiments/deprecated-experiments.md) — `writing-rules/experiments/deprecated-experiments.md`
- [Display propagated value of metavariables](writing-rules/experiments/display-propagated-metavariable.md) — `writing-rules/experiments/display-propagated-metavariable.md`
- [Introduction to Semgrep experiments](writing-rules/experiments/introduction.md) — `writing-rules/experiments/introduction.md`
- [Match captured metavariables with specific types](writing-rules/experiments/metavariable-type.md) — `writing-rules/experiments/metavariable-type.md`
- [Include multiple focus metavariables using set union semantics](writing-rules/experiments/multiple-focus-metavariables.md) — `writing-rules/experiments/multiple-focus-metavariables.md`
- [Pattern syntax (experimental)](writing-rules/experiments/pattern-syntax.md) — `writing-rules/experiments/pattern-syntax.md`
- [r2c-internal-project-depends-on](writing-rules/experiments/r2c-internal-project-depends-on.md) — `writing-rules/experiments/r2c-internal-project-depends-on.md`
- [Symbolic propagation](writing-rules/experiments/symbolic-propagation.md) — `writing-rules/experiments/symbolic-propagation.md`

### Join mode (upstream compatibility only)

- [Join mode overview](writing-rules/experiments/join-mode/overview.md) — `writing-rules/experiments/join-mode/overview.md`
- [Recursive joins](writing-rules/experiments/join-mode/recursive-joins.md) — `writing-rules/experiments/join-mode/recursive-joins.md`

### Supplementary troubleshooting

- [Troubleshooting rules](troubleshooting/rules.md) — `troubleshooting/rules.md`

## Offline assets and limitations

- All **54 unique embedded editor snippets** resolved through the public registry API; each has `playground/<snippet>.json` (complete response) and `playground/<snippet>.md` (rule definition and every test case). JSON rule definitions are also valid YAML. Links beside each example preserve the original interactive location.
- The cheatsheet’s **30 language/data keys** are preserved in `playground/cheatsheet.json` and readable `playground/cheatsheet.md`, including match coordinates, original source paths, and upstream null entries. No execution/UI is reproduced.
- Both referenced images are in `assets/` (join-mode diagram PNG and Semgrep CI animation GIF). The CDN denied retrieval (HTTP 403); originals were fetched from the pinned GitHub commit instead.
- Three YouTube videos remain external: `6MxMhFPkZlU` (taint overview), `lAbJdzMUR4k` (taint advanced), and `8jfjWixmtvo` (rule-defined fix). Video/audio/transcripts are not included. All surrounding page prose and embedded rule examples are included.
- Tutorials, registry execution, hosted platform screens, and external articles remain explicitly absolute external URLs. They are not part of the writing-rules subtree. The local docs require no network to read; executing upstream playgrounds still does.
- Presentation components are flattened to Markdown while retaining prose; hover text is preserved in [TOOLTIPS.md](TOOLTIPS.md). Decorative icons are not essential rule content. No examples or engine compatibility claims were tested here.

## Provenance, changes, and licensing

Upstream authors: **Semgrep and contributors to semgrep/semgrep-docs**. Source repository: <https://github.com/semgrep/semgrep-docs>. The repository’s [LICENSE](LICENSE) is **GNU Lesser General Public License version 2.1**, reproduced verbatim; this vendored documentation remains under that upstream license, without warranty. No broader repository license is replaced by this vendored license. Preserve upstream notices and this license when redistributing.

Local changes dated 2026-10-03: compatibility/provenance banners; internal links rewritten to local paths; outside links qualified as absolute URLs; presentation wrappers flattened; embedded editor/cheatsheet data expanded into static references; image paths localized. Semgrep’s technical wording and branding are not rewritten as OpenGrep claims.

The playground API provides no explicit license field. Its responses are archived as the examples directly embedded by these upstream documentation pages; no separate license grant for unrelated registry rules is asserted. Cheatsheet data is extracted from the publicly served application bundle used by the embedded documentation component; no separate application-bundle license grant is asserted and the executable application bundle is not redistributed. This distinction should be considered before publishing the snapshots independently of the documentation.

[provenance.json](provenance.json) records every downloaded/generated resource’s source URL, local path, SHA-256, and resource kind. Hashes cover the stored, locally adapted bytes, not untouched origin responses (except raw API JSON and license). Discovery inputs are preserved in [llms.txt](discovery/llms.txt) and [sitemap.xml](discovery/sitemap.xml). The live website and source repository can evolve independently; the commit identifies the completeness/license cross-check and image sources, not a claim that every live page exactly matches that commit.
