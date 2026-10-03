> **Upstream Semgrep documentation snapshot — NOT an OpenGrep compatibility promise.** Retrieved and locally modified 2026-10-03 (offline links, presentation wrappers, resolved playground examples). Semgrep and upstream contributors; LGPL-2.1, provided without warranty. [License](../../LICENSE); [offline index](../../INDEX.md). Source: https://docs.semgrep.dev/writing-rules/experiments/multiple-focus-metavariables.md

> ## Documentation Index
> Local adaptation: read the [downloaded documentation index](../../discovery/llms.txt) rather than fetching https://docs.semgrep.dev/llms.txt.
> Use this file to discover all available pages before exploring further.

# Include multiple focus metavariables using set union semantics

> Semgrep matches all pieces of code captured by focus metavariables when you specify them in a rule. Specify the metavariables you want to focus on in a YAML list format.



  **INFO**

  This feature is using `focus-metavariable`, see [`focus-metavariable`](../rule-syntax.md#focus-metavariable) documentation for more information.



There are two ways in which you can include multiple focus metavariables:

* **Set union**: Experimental feature described below in the section [Set union](#set-union). This feature returns the union of all matches of the specified metavariables.
* **Set intersection**: Only matches the overlapping region of all the focused code. For more information, see [Including more focus metavariables using set intersection semantics](../rule-syntax.md#including-multiple-focus-metavariables-using-set-intersection-semantics).

## Set union

For example, there is a pattern that binds several metavariables. You want to produce matches focused on two or more of these metavariables. If you specify a list of metavariables under `focus-metavariable`, each focused metavariable matches code independently of the others.

```yaml
    patterns:
      - pattern: foo($X, ..., $Y)
      - focus-metavariable: 
        - $X
        - $Y
```

This syntax enables Semgrep to match these metavariables regardless of their position in code. See the following example:



  
[Offline playground rule and complete test cases](../../playground/D602.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=D602](https://semgrep.dev/embed/editor?snippet=D602) (external).






  **TIP**

  Among many use cases, the **set union** syntax allows you to simplify taint analysis rule writing. For example, see the following rule:

  

    
[Offline playground rule and complete test cases](../../playground/w6Qx.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=w6Qx](https://semgrep.dev/embed/editor?snippet=w6Qx) (external).

  



