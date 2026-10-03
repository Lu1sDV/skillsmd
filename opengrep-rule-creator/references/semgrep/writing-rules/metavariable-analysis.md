> **Upstream Semgrep documentation snapshot — NOT an OpenGrep compatibility promise.** Retrieved and locally modified 2026-10-03 (offline links, presentation wrappers, resolved playground examples). Semgrep and upstream contributors; LGPL-2.1, provided without warranty. [License](../LICENSE); [offline index](../INDEX.md). Source: https://docs.semgrep.dev/writing-rules/metavariable-analysis.md

> ## Documentation Index
> Local adaptation: read the [downloaded documentation index](../discovery/llms.txt) rather than fetching https://docs.semgrep.dev/llms.txt.
> Use this file to discover all available pages before exploring further.

# Metavariable analysis

Semgrep developed metavariable analysis to support several metavariable inspection techniques that are difficult to express with existing rules, but have "simple" binary classifier behavior. Currently, this syntax supports two analyzers: `redos` and `entropy`.

## ReDoS

```yaml
metavariable-analysis:
    analyzer: redos
    metavariable: $VARIABLE
```

Poorly constructed regular expressions that exhibit exponential runtime when fed specifically crafted inputs can cause RegEx denial of service. The `redos` analyzer uses known RegEx anti-patterns to determine if the target expression is potentially vulnerable to catastrophic backtracking.



  
[Offline playground rule and complete test cases](../playground/2Aoj.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=2Aoj](https://semgrep.dev/embed/editor?snippet=2Aoj) (external).




## Entropy

```yaml
metavariable-analysis:
    analyzer: entropy
    metavariable: $VARIABLE
```

Entropy is a common approach for detecting secret strings. Many existing tools utilize a combination of entropy calculations and regular expressions (RegEx) for secret detection. This analyzer returns `true` if a metavariable has high entropy, or randomness, relative to the English language.



  
[Offline playground rule and complete test cases](../playground/GgZG.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=GgZG](https://semgrep.dev/embed/editor?snippet=GgZG) (external).



