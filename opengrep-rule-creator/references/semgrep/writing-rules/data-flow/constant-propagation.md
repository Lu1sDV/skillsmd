> **Upstream Semgrep documentation snapshot — NOT an OpenGrep compatibility promise.** Retrieved and locally modified 2026-10-03 (offline links, presentation wrappers, resolved playground examples). Semgrep and upstream contributors; LGPL-2.1, provided without warranty. [License](../../LICENSE); [offline index](../../INDEX.md). Source: https://docs.semgrep.dev/writing-rules/data-flow/constant-propagation.md

> ## Documentation Index
> Local adaptation: read the [downloaded documentation index](../../discovery/llms.txt) rather than fetching https://docs.semgrep.dev/llms.txt.
> Use this file to discover all available pages before exploring further.

# Constant propagation


Constant propagation
 tracks whether a variable *must* carry a constant value at a given point in the program. Semgrep performs constant folding when matching literal patterns. Semgrep can track Boolean, numeric, and string constants.

Semgrep AppSec Platform supports interprocedural (cross-function), interfile (cross-file) constant propagation. Semgrep Community Edition (CE) supports intrafile (single-file) constant propagation.



  
[Offline playground rule and complete test cases](../../playground/Gw7z.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=Gw7z](https://semgrep.dev/embed/editor?snippet=Gw7z) (external).




## `metavariable-comparison`

Using constant propagation, the [`metavariable-comparison`](../rule-syntax.md#metavariable-comparison) operator works with any constant variable instead of just literals.



  
[Offline playground rule and complete test cases](../../playground/Dyzd.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=Dyzd](https://semgrep.dev/embed/editor?snippet=Dyzd) (external).




## Mutable objects

In general, Semgrep assumes that constant objects are immutable and won't be modified by function calls. This can lead to false positives, especially in languages where strings are mutable, such as C and Ruby.

The only exceptions are method calls whose returning value is ignored. In these cases, Semgrep assumes that the method call may be mutating the object that's called. This helps reduce false positives in Ruby. For example:



  
[Offline playground rule and complete test cases](../../playground/08yB.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=08yB](https://semgrep.dev/embed/editor?snippet=08yB) (external).




If constant propagation doesn't seem to work, consider whether the constant may be unexpectedly mutable. For example, given the following rule designed to taint the `REGEX` class variable:

```yaml
rules:
  - id: redos-detection
    message: Potential ReDoS vulnerability detected with $REGEX
    severity: HIGH
    languages:
      - java
    mode: taint
    options:
      symbolic_propagation: true
    pattern-sources:
      - patterns:
          - pattern: $REDOS
          - metavariable-analysis:
              analyzer: redos
              metavariable: $REDOS
    pattern-sinks:
      - pattern: Pattern.compile(...)
```

Semgrep fails to match its use in `Test2` when presented with the following code:

```java
import java.util.regex.Pattern;

public String REGEX = "(a+)+$";

public class Test2 {
   public static void main(String[] args) {
        Pattern pattern = Pattern.compile(REGEX);
   }
}
```

However, if you change the variable from `public` to `private`, Semgrep returns a match:

```java
import java.util.regex.Pattern;

private String REGEX = "(a+)+$";

public class Test2 {
   public static void main(String[] args) {
        Pattern pattern = Pattern.compile(REGEX);
   }
}
```

Because `REGEX` is public in the first code snippet, Semgrep doesn't propagate its value to other classes on the assumption that it could have mutated. However, in the second example, Semgrep understands that `REGEX` is private and only assigned to once. Therefore, Semgrep assumes it is immutable.

The rule would also work with:

```java
...
public final String REGEX = "(a+)+$";
...
```

## Disable constant propagation

You can disable constant propagation on a per-rule basis using rule [`options:`](../rule-syntax.md#options) by setting `constant_propagation: false`.



  
[Offline playground rule and complete test cases](../../playground/jwvn.md). Original interactive execution: [https://semgrep.dev/embed/editor?snippet=jwvn](https://semgrep.dev/embed/editor?snippet=jwvn) (external).



