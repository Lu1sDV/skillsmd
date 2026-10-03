> **Upstream Semgrep documentation snapshot — NOT an OpenGrep compatibility promise.** Retrieved and locally modified 2026-10-03 (offline links, presentation wrappers, resolved playground examples). Semgrep and upstream contributors; LGPL-2.1, provided without warranty. [License](../../LICENSE); [offline index](../../INDEX.md). Source: https://docs.semgrep.dev/writing-rules/data-flow/status.md

> ## Documentation Index
> Local adaptation: read the [downloaded documentation index](../../discovery/llms.txt) rather than fetching https://docs.semgrep.dev/llms.txt.
> Use this file to discover all available pages before exploring further.

# Dataflow status

In principle, the dataflow analysis engine, which provides taint tracking, constant propagation, and symbolic propagation, can run on any language [supported by Semgrep](https://docs.semgrep.dev/supported-languages). However, the level of support is lower than for the regular Semgrep matching engine.

When Semgrep performs an analysis of the code, it creates an **abstract syntax tree** (AST), which is then translated into an analysis-friendly **intermediate language** (IL). Subsequently, Semgrep runs mostly language-agnostic analysis on IL. However, this translation is not fully complete.



  **CAUTION**

  There can be features of some languages that Semgrep does not analyze correctly while using dataflow analysis. Consequently, Semgrep does not fail even if it finds an unsupported construct. The analysis continues while the construct is ignored. This can result in Semgrep not matching some code that should be matched (false negatives) or matching a code that should not be matched (false positives).



Please help Semgrep improve by [reporting any issues you encounter](https://github.com/semgrep/semgrep/issues/new/choose).
