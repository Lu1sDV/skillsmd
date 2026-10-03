# Offline OpenGrep reference index

Load only the page needed. These are **full upstream source files**, not rewritten summaries. Start with the authored [compatibility guide](../compatibility.md) for version boundaries.

## Provenance and rights

Retrieved 2026-10-03. Every file's original URL, commit, SHA-256 and license note is in [PROVENANCE.json](PROVENANCE.json).

| Snapshot | Exact revision | Scope |
|---|---|---|
| Release `v1.30.0` | `acf67b45c97c4b63626536605c77064ef536806d` (2026-09-07) | Released implementation and feature documentation |
| Wiki | `77adea7dc411aa686c9c4ecd001b6063393319f2` (2026-07-02) | All eight Markdown pages discovered by cloning the complete wiki working tree |
| Main interfile docs | `8bb8e37f5249ab2d101c3cef5e056e571f503311` (2026-10-02) | **Post-release development documentation; not evidence of v1.30.0 support** |

Repository snapshots retain [LGPL-2.1 LICENSE](v1.30.0/LICENSE), [COPYRIGHT](v1.30.0/COPYRIGHT), and individual source notices. The separate wiki repository has **no license file or explicit licensing statement** in its snapshot. Its rights are unresolved; do not represent those pages as LGPL-licensed or as authored under this skill's license. Review/obtain redistribution permission before republishing the wiki. Source attribution is not a license grant.

Upstream prose and code are preserved in full. Navigation-only modifications replace links to vendored pages with relative local links, and qualify unvendored repository file/image links with commit-pinned upstream URLs. Main interfile links to its unvendored intrafile implementation retain the main commit rather than silently substituting the older release version. The provenance manifest records original-source and redistributed-file hashes plus modification notes. External images and unvendored linked articles/files remain online; Markdown prose and bundled code examples are available offline. Neither wiki benchmark numbers nor comparisons with Semgrep Pro are independently verified here.

## Complete wiki

Original entry point: <https://github.com/opengrep/opengrep/wiki/>. Clone source: <https://github.com/opengrep/opengrep.wiki.git>.

| Local page | Load for |
|---|---|
| [Home](wiki/Home.md) | Original navigation and scope |
| [Intrafile tainting tutorial](wiki/Intrafile-tainting-tutorial.md) | Cross-function, constructors, field writes, methods, variadics, inheritance limitation |
| [Higher-order functions tutorial](wiki/Higher-order-functions-tutorial.md) | Callback/lambda flows and language examples |
| [Methods that taint](wiki/Methods-that-taint.md) | Built-in receiver-mutator and accessor models |
| [Guarded taint signatures](wiki/Guarded-taint-signatures.md) | Experimental argument-condition filtering |
| [C# support](wiki/Support-for-C%23.md) | Parser and taint translation specifics |
| [PHP support](wiki/Support-for-Php.md) | Modern PHP syntax and parser behavior |
| [Visual Basic support](wiki/Support-for-Visual-Basic.md) | Language configuration and limitations |

## Release documentation and source evidence

Original release tree: <https://github.com/opengrep/opengrep/tree/v1.30.0>.

- [OPENGREP.md](v1.30.0/OPENGREP.md): fork baseline, improvements, rule options and CLI changes.
- [README.md](v1.30.0/README.md): binary installation, scan and output examples.
- [INSTALL.md](v1.30.0/INSTALL.md): source-building instructions, **not** the quick binary installer.
- [Intrafile implementation](v1.30.0/docs/INTRA_FUNCTION_IMPLEMENTATION.md): signature extraction, dispatch and cyclic-call limits.
- [Scan_CLI.ml](v1.30.0/src/osemgrep/cli_scan/Scan_CLI.ml): exact scan flags, config sources, ignore behavior and limits.
- [Test_CLI.ml](v1.30.0/src/osemgrep/cli_test/Test_CLI.ml): exact test flags and target/config requirements.
- [CLI.ml](v1.30.0/src/osemgrep/cli/CLI.ml): native dispatch and automatic experimental-mode argument insertion helper.
- [Parse_rule.ml](v1.30.0/src/parsing/Parse_rule.ml): accepted modes and taint source/sink/propagator defaults.
- [Core_runner.ml](v1.30.0/src/osemgrep/core_runner/Core_runner.ml): partial dependency/lockfile targeting implementation.
- [Matches_report.ml](v1.30.0/src/osemgrep/reporting/Matches_report.ml): secret findings without validators.
- [Language-server Session.ml](v1.30.0/src/osemgrep/language_server/server/Session.ml): explicit SCA/Secrets exclusion in language-server rule selection.
- [Autofix.ml](v1.30.0/src/fixing/Autofix.ml), [Range_with_metavars.ml](v1.30.0/src/engine/Range_with_metavars.ml), and [Xpattern_matcher.ml](v1.30.0/src/engine/Xpattern_matcher.ml): why `fix-regex` can parse and match but silently produce no native edit on synthetic matches.

## Main-only interfile documentation

**Do not apply these flags/options to v1.30.0 on the basis of these pages.** Original directory: <https://github.com/opengrep/opengrep/tree/8bb8e37f5249ab2d101c3cef5e056e571f503311/docs/interfile>.

1. [README](main-interfile/README.md)
2. [Architecture](main-interfile/01-architecture.md)
3. [Call graph](main-interfile/02-call-graph.md)
4. [Dispatch](main-interfile/03-dispatch.md)
5. [Language quirks](main-interfile/04-language-quirks.md)
6. [CLI and tools](main-interfile/05-cli-and-tools.md)
7. [Subtleties](main-interfile/06-subtleties.md)
