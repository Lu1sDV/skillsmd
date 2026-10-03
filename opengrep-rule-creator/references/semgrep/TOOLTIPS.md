# Upstream tooltip definitions

Hover-component prose preserved for plain Markdown reading. Semgrep-specific definitions, not OpenGrep compatibility promises. Retrieved 2026-10-03.

- Page: [writing-rules/data-flow/constant-propagation.md](writing-rules/data-flow/constant-propagation.md). Analysis where known constant values are substituted into later uses so Semgrep can detect matches. Semgrep CE is limited to per-file propagation. [See full definition.](writing-rules/glossary.md#constant-propagation).

- Page: [writing-rules/data-flow/taint-mode/overview.md](writing-rules/data-flow/taint-mode/overview.md). Tracks the flow of untrusted data from sources to sinks and identifies paths where data is not sanitized. [See full definition.](writing-rules/glossary.md#taint-analysis).

- Page: [writing-rules/data-flow/taint-mode/overview.md](writing-rules/data-flow/taint-mode/overview.md). In taint analysis, code that introduces tainted data, typically user input. [See full definition.](writing-rules/glossary.md#source).

- Page: [writing-rules/experiments/join-mode/overview.md](writing-rules/experiments/join-mode/overview.md). Also known as interfile analysis. Accounts for information flowing between files, including cross-file taint analysis, constant propagation, and type inference. [See full definition.](writing-rules/glossary.md#cross-file-analysis).

- Page: [writing-rules/experiments/join-mode/overview.md](writing-rules/experiments/join-mode/overview.md). Unintentional flaw in a dependency that can be exploited. Vulnerabilities are typically assigned a CVE and categorized by GHSA severity. [See full definition.](https://docs.semgrep.dev/semgrep-supply-chain/glossary#vulnerability).

- Page: [writing-rules/experiments/r2c-internal-project-depends-on.md](writing-rules/experiments/r2c-internal-project-depends-on.md). Publicly available code used as part of your application. Dependencies are listed in registries such as npm for JavaScript and PyPI for Python. [See full definition.](https://docs.semgrep.dev/semgrep-supply-chain/glossary#dependency).

- Page: [writing-rules/experiments/r2c-internal-project-depends-on.md](writing-rules/experiments/r2c-internal-project-depends-on.md). Publicly available code used as part of your application. Dependencies are listed in registries such as npm for JavaScript and PyPI for Python. [See full definition.](https://docs.semgrep.dev/semgrep-supply-chain/glossary#dependency).

- Page: [writing-rules/generic-pattern-matching.md](writing-rules/generic-pattern-matching.md). Abstraction that matches unknown values. Metavariables begin with $ and can include uppercase letters, digits, and underscores. [See full definition.](writing-rules/glossary.md#metavariable).

- Page: [writing-rules/rule-syntax.md](writing-rules/rule-syntax.md). Abstraction that matches unknown values. Metavariables begin with $ and can include uppercase letters, digits, and underscores. [See full definition.](writing-rules/glossary.md#metavariable).

- Page: [writing-rules/rule-syntax.md](writing-rules/rule-syntax.md). Abstraction that matches unknown values. Metavariables begin with $ and can include uppercase letters, digits, and underscores. [See full definition.](writing-rules/glossary.md#metavariable).

- Page: [writing-rules/rule-syntax.md](writing-rules/rule-syntax.md). Abstraction that matches unknown values. Metavariables begin with $ and can include uppercase letters, digits, and underscores. [See full definition.](writing-rules/glossary.md#metavariable).

- Page: [writing-rules/rule-syntax.md](writing-rules/rule-syntax.md). Abstraction that matches unknown values. Metavariables begin with $ and can include uppercase letters, digits, and underscores. [See full definition.](writing-rules/glossary.md#metavariable).
