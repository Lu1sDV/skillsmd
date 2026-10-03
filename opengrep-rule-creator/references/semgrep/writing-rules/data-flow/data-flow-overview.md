> **Upstream Semgrep documentation snapshot — NOT an OpenGrep compatibility promise.** Retrieved and locally modified 2026-10-03 (offline links, presentation wrappers, resolved playground examples). Semgrep and upstream contributors; LGPL-2.1, provided without warranty. [License](../../LICENSE); [offline index](../../INDEX.md). Source: https://docs.semgrep.dev/writing-rules/data-flow/data-flow-overview.md

> ## Documentation Index
> Local adaptation: read the [downloaded documentation index](../../discovery/llms.txt) rather than fetching https://docs.semgrep.dev/llms.txt.
> Use this file to discover all available pages before exploring further.

# Dataflow analysis engine overview

> Semgrep provides an intraprocedural data-flow analysis engine that opens various Semgrep capabilities. Semgrep provides the following data-flow analyses:

* [Constant propagation](constant-propagation.md) allows Semgrep to, for example, match `return 42` against `return x` when `x` can be reduced to `42` by constant folding. There is also a specific experimental feature of [Constant propagation](constant-propagation.md), called [Symbolic propagation](../experiments/symbolic-propagation.md).
* [Taint tracking (known also as taint analysis)](taint-mode/overview.md) enables you to write simple rules that catch complex [injection bugs](https://owasp.org/www-community/Injection_Flaws), such as those that can result in [cross-site scripting (XSS)](https://owasp.org/www-community/attacks/xss/).

All dataflow-related features are available for Semgrep's [supported languages](https://docs.semgrep.dev/supported-languages). Interfile (cross-file) analysis also supports dataflow analysis. For more details, see [<Icon icon="file-lines" iconType="regular" /> Perform cross-file analysis](https://docs.semgrep.dev/semgrep-code/semgrep-pro-engine-intro).



  **INFO**

  Ensure that you understand the [design trade-offs](#design-trade-offs) and limitations of the dataflow engine. For further details, see [dataflow status](#data-flow-status).



If you are interested in requesting a new dataflow analysis, please [let us know](https://github.com/semgrep/semgrep/issues/new/choose). If you can code in OCaml, your contribution is welcome. See [Contributing](https://docs.semgrep.dev/contributing/contributing) for more details.

## Design trade-offs

Semgrep strives for simplicity and offers lightweight and fast static analyses. In addition to being intraprocedural, here are some other trade-offs:

* No path sensitivity: All *potential* execution paths are considered, even though some may not be feasible.
* No pointer or shape analysis: *Aliasing* that happens in non-trivial ways may not be detected, such as through arrays or pointers. Individual elements in arrays or other data structures are not tracked. The dataflow engine supports limited field sensitivity for taint tracking, but not for constant propagation.
* No soundness guarantees: Semgrep ignores the effects of `eval`-like functions on the program state. It doesn’t make worst-case sound assumptions, but rather "reasonable" ones.

Expect both false positives and false negatives. You can remove false positives in different ways, such as using [pattern-not](../rule-syntax.md#pattern-not) and [pattern-not-inside](../rule-syntax.md#pattern-not-inside). If you encounter any problems, [create an issue](https://github.com/semgrep/semgrep/issues/new/choose) to open a feature request if Semgrep misses a difficult bug you want to catch.

## Dataflow status

In principle, the dataflow analysis engine, which provides taint tracking, constant propagation, and symbolic propagation, can run on any language [supported by Semgrep](https://docs.semgrep.dev/supported-languages). However, the level of support is lower than for the regular Semgrep matching engine.

When Semgrep performs an analysis of the code, it creates an **abstract syntax tree** (AST), which is then translated into an analysis-friendly **intermediate language** (IL). Subsequently, Semgrep runs mostly language-agnostic analysis on IL. However, this translation is not fully complete.



  **CAUTION**

  There can be features of some languages that Semgrep does not analyze correctly while using dataflow analysis. Consequently, Semgrep does not fail even if it finds an unsupported construct. The analysis continues while the construct is ignored. This can result in Semgrep not matching some code that should be matched (false negatives) or matching a code that should not be matched (false positives).



Please help Semgrep improve by [reporting any issues you encounter](https://github.com/semgrep/semgrep/issues/new/choose).
