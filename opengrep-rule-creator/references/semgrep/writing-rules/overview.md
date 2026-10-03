> **Upstream Semgrep documentation snapshot — NOT an OpenGrep compatibility promise.** Retrieved and locally modified 2026-10-03 (offline links, presentation wrappers, resolved playground examples). Semgrep and upstream contributors; LGPL-2.1, provided without warranty. [License](../LICENSE); [offline index](../INDEX.md). Source: https://docs.semgrep.dev/writing-rules/overview.md

> ## Documentation Index
> Local adaptation: read the [downloaded documentation index](../discovery/llms.txt) rather than fetching https://docs.semgrep.dev/llms.txt.
> Use this file to discover all available pages before exploring further.

# Write rules

> Semgrep uses rules, which encapsulate pattern matching logic and data flow analysis, to scan your code for security issues, style violations, bugs, and more. In addition to rules available to you in the Semgrep Registry, you can write custom rules to determine what Semgrep detects in your repositories. You can write rules that:

* Automate code review comments.
* Identify secure coding violations.
* Scan configuration files.

See more use cases in [Rule ideas](rule-ideas.md).

## Get started

For an introduction to writing Semgrep rules, use the interactive, example-based [Semgrep rule tutorial](https://semgrep.dev/learn).

You can write rules in your terminal and run them with the Semgrep command line tool, or you can write and test using the [Semgrep Editor](https://semgrep.dev/editor).

For example, the following sample rule detects the use of `is` when comparing Python strings. `is` checks reference equality, not value equality, and can exhibit nondeterministic behavior.



  
[Offline playground rule and complete test cases](../playground/Ppde.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=Ppde](https://semgrep.dev/embed/editor?snippet=Ppde) (external).




## Next steps

The following articles guide you through rule-writing basics and act as references:

* [Pattern syntax](pattern-syntax.md) describes what Semgrep patterns can do in detail and provides sample use cases.
* [Rule syntax](rule-syntax.md) describes Semgrep YAML rule files, which can have multiple patterns, detailed output messages, and Rule-defined fixes. The syntax allows the composition of individual patterns with Boolean operators.
* [Contributing rules](https://docs.semgrep.dev/contributing/contributing-to-semgrep-rules-repository) gives you an overview of how you can contribute to Semgrep Registry rules. This document also provides information about tests and metadata fields that you can use for your rules.

Need rule ideas? See [Rule ideas](rule-ideas.md) for everyday use cases and prompts to help you start writing rules from scratch.
