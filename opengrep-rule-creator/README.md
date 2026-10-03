# OpenGrep Rule Creator

An OpenGrep-first adaptation of [Trail of Bits' Semgrep Rule Creator](https://www.skills.sh/trailofbits/skills/semgrep-rule-creator): test-first authoring, local reference documentation, and four compact, commented experiments rather than a large rule catalogue.

## Install

```bash
npx skills add Lu1sDV/skillsmd --skill opengrep-rule-creator
```

Or, from this repository:

```bash
mkdir -p ~/.claude/skills
cp -r opengrep-rule-creator ~/.claude/skills/
```

Copy the **whole directory**, not just `SKILL.md`: the reference library and fixtures are part of the skill. Verify that your agent lists `opengrep-rule-creator` among its available skills.

The OpenGrep executable is a separate prerequisite. This package targets **1.30.0**, using the native binary from the [official release](https://github.com/opengrep/opengrep/releases/tag/v1.30.0). Select the binary for your platform, verify its published digest/signature, and put it on `PATH` as `opengrep`. No executable is bundled or installed by this skill. Installation needs internet; reading the included references and scanning with local rules does not require registry configuration.

## Use

Example requests:

- “Use opengrep-rule-creator to detect request data reaching our shell wrapper. Include safe cases.”
- “Port this Semgrep rule to OpenGrep; prove the behavior on the installed version.”
- “Run the four examples and explain their less obvious operators using the bundled docs.”

Start with [SKILL.md](SKILL.md): all four commented rules and full fixtures are inline, together with the workflow, publication gates, and core OpenGrep caveats. The downloaded documentation is supplementary for details not covered by the corpus.

## What's included

| Path | Purpose |
|---|---|
| [SKILL.md](SKILL.md) | Self-contained corpus: four complete commented rules and fixtures, quick commands, workflow, publication gates, and OpenGrep essentials |
| [Compatibility](references/compatibility.md) | What transfers unchanged, CLI differences, release-specific engine limits |
| [Semgrep offline index](references/semgrep/INDEX.md) | All 28 `writing-rules/` pages, 1 troubleshooting page, 54 embedded playground examples, and the static cheatsheet; full content rather than summaries |
| [OpenGrep offline index](references/opengrep/INDEX.md) | Wiki and relevant repository documentation, with source revisions and provenance |
| [Runnable example assets](examples/README.md) | Scanner-ready files mirroring the four inline examples, execution commands, and the configuration autofix golden |
| [Authoring policy and decisions](references/authoring-policy.md) | All requested publication gates, anti-patterns, performance/precision practices, and reasons for refinements |
| [Attribution](ATTRIBUTION.md) | Upstream credit, modifications, license boundaries |

The examples are **scanner inputs**, not programs to execute. Their comments explain subtle features such as matching ranges, focus, exact taint sources, propagation, and analysis-mode changes. Use them as editable experiments, not as a claim that a toy rule is production-ready.

## Important adaptations

- **No mandatory web fetching.** The upstream skill requires loading seven online documents before authoring. This version selects bundled pages by task.
- **Rule YAML is largely shared; engine behavior is not assumed identical.** Classic pattern and taint rules remain the default. Test with the actual OpenGrep version and flags.
- **Intrafile is not interfile.** OpenGrep 1.30.0 exposes `--taint-intrafile` for supported languages; documentation from newer `main` revisions must not be treated as a released capability.
- **Cloud and experimental features are labelled, not silently removed.** The complete Semgrep section includes join mode, dependency rules, private rules and experimental syntax. Read the compatibility guide before trying those features.
- **Offline authoring, explicit publication gate.** Local tests/scans need no registry configuration; mandatory pre-commit `opengrep validate` fetches lint rules in 1.30.0. Add `semgrep --validate` only when Semgrep compatibility is also claimed.
- **Autofix acceptance is not autofix execution.** Native 1.30.0 can silently lose `fix-regex` edits on synthetic matches. The configuration example uses a tested focused `fix`; the KDF example intentionally omits an unsafe one-token migration.
- **Evidence-based authoring policy.** Every rule needs 2 genuine TP + 2 genuine TN, WHAT/WHY/HOW messaging, technology metadata, and structural primary matching. HIGH confidence needs reviewed real-codebase evidence. All acceptance/refinement decisions are recorded locally.

## Verification

On native OpenGrep **1.30.0**, Linux x86-64:

- All **4 rules** passed annotated tests; the configuration `.fixed` golden passed.
- Network-isolated real scans produced exactly **17 expected findings** and excluded all **26 `ok` cases**; zero scan errors. Scope-boundary cases are not mislabelled as genuinely safe negatives.
- Intrafile comparison: **0 findings without the flag, 2 with it**; four negative sites stayed clear. Constructor-mutation and inline-callback sanitizer limitations are documented.
- Configuration dry run preserved the copied target; applied autofix matched the golden byte-for-byte.
- Network-enabled `opengrep validate examples/`: **4 rules, 0 fatal errors, 0 skippable errors**.
- The 28-page offline documentation inventory and provenance remain unchanged; local documentation links and skill frontmatter are checked. No real-codebase confidence calibration or scale benchmark is claimed.

## Snapshot and licensing

References were retrieved on **2026-10-03**. Each archive has its own inventory/provenance; original URLs are retained for attribution and deliberate updates, not required reading during authoring. The snapshot boundary is the **entire Semgrep `writing-rules/` subtree**, not the whole Semgrep website. Embedded online services are not runnable offline; consult the inventory for archived code and any remaining external dependencies.

The adapted skill is **CC BY-SA 4.0**; see [LICENSE](LICENSE). Third-party snapshots retain their own notices. The separately published OpenGrep wiki has no explicit license declaration; Semgrep's playground API and application cheatsheet data expose no separate license grant. **Review redistribution permission before public publication**; do not assume either project's repository license automatically covers those separate sources.
