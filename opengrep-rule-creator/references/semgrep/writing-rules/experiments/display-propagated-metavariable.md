> **Upstream Semgrep documentation snapshot — NOT an OpenGrep compatibility promise.** Retrieved and locally modified 2026-10-03 (offline links, presentation wrappers, resolved playground examples). Semgrep and upstream contributors; LGPL-2.1, provided without warranty. [License](../../LICENSE); [offline index](../../INDEX.md). Source: https://docs.semgrep.dev/writing-rules/experiments/display-propagated-metavariable.md

> ## Documentation Index
> Local adaptation: read the [downloaded documentation index](../../discovery/llms.txt) rather than fetching https://docs.semgrep.dev/llms.txt.
> Use this file to discover all available pages before exploring further.

# Display propagated value of metavariables

This document provides information about experimental syntax supplement to [Display matched metavariables in rule messages](../pattern-syntax.md#display-matched-metavariables-in-rule-messages). Semgrep enables you to display values of matched metavariables in rule messages. However, in some cases, the matched value of the metavariable is not the real value you were looking for.

See the following rule message and part of a Semgrep rule (formula):

```yaml
- message: >-
  Creating a buffer using $X
- patterns:
   - pattern: byte[] buf = new byte[$X];
   - metavariable-comparison:
        metavariable: $X
        comparison: $X < 2048
```

Testing code:

```java
int size = 512;
byte[] buf = new byte[size];
```

Semgrep matches this code because it performs constant propagation. Therefore, Semgrep recognizes that the value of `size` is `512`. Consequently, Semgrep evaluates that the buffer size is less than `2048`. But what is the value of `$X`?

If the rule message states `Creating a buffer using $X`, the resulting message output is not helpful in this particular case:

```
Creating a buffer using size
```

This is caused by the value of `$X` within the code, which is `size`. However, the underlying value of `size` is `512`. The goal of the rule message is to access this underlying value in our message.

To retrieve the correct value in the case described above, use `value($X)` in the rule message (for example, `Creating a buffer using value($X)`). Semgrep replaces the `value($X)` with the underlying propagated value of the metavariable `$X` if it computes one (otherwise, Semgrep uses the matched value).



  **INFO**

  Regular Semgrep syntax for displaying matched metavariables in rule messages is for example `$X`. For specific propagated values, use experimental syntax `value($X)` instead. For more information about the standard syntax, see [Displaying matched metavariables in rule messages](../pattern-syntax.md#display-matched-metavariables-in-rule-messages).



Run the following example in Semgrep Playground to see the message (click **Open in Editor**, and then **Run**, unroll the **1 Match** to see the message):



  
[Offline playground rule and complete test cases](../../playground/Dr0G.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=Dr0G](https://semgrep.dev/embed/editor?snippet=Dr0G) (external).



