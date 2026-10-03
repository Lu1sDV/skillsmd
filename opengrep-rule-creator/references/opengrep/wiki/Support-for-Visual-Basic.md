## What’s Supported

Opengrep supports Visual Basic (also known as Visual Basic .NET) based on language specification **version 16.9**. The implementation covers the full spec except for a few items listed in the **TODO** section below.

To enable Visual Basic support in your rules, set the language to `vb`.  
Intra-file taint analysis (`--taint-intrafile`) is available for VB files.

## Notes on Patterns

- **No distinction between subs, functions, and lambdas**  
  Opengrep treats Sub and Function the same, both for top-level declarations and lambdas.  
  It also doesn’t differentiate between single-line and multi-line versions of If statements or lambda expressions.  
  This means a pattern like:

  ```
  Sub
    ...
    DoSth()
    ...
  End Sub
  ```

  can also match a single-line lambda such as `Sub DoSth()`.

- **Case sensitivity**  
  Matching of identifiers and keywords is case-insensitive.  
  Regular expressions used in metavariable-regexp are not case-insensitive by default because they match the exact program text.  
  If your regex needs to match identifiers or keywords, remember to use (?i) for case-insensitive mode.

- **Using = in different contexts**  
  Since Visual Basic uses = for both assignment and comparison, Opengrep lets you distinguish them in patterns:

  - `$X = $Y`  
    Matches assignments, including field initializers inside `New With { .field = value }`.

  - `($X = $Y)`  
    Matches comparisons. A parenthesized assignment isn’t a valid statement, so this is interpreted as an expression.

  These patterns work naturally inside larger constructs, such as:

  - `If $X = $Y Then ...`
  - `New Obj With { ..., .$FOO = True, ... }`

- **Typed metavariables**  
  Typed metavariables use the syntax `($XYZ As Integer)`.  
  The parentheses are part of the syntax. For example, to match a call to foo that receives an Integer, use:

  ```
  foo(($XYZ As Integer))
  ```

- **Dim with inferred initialization**  
  A pattern like `Dim foo As C = New C(...)` also matches forms such as `Dim foo As New C(...)`.

## TODOs / Known Limitations in Opengrep 1.12.0

- **LINQ constructor semantics**  
  Opengrep doesn’t currently interpret LINQ query constructors semantically.  
  You can still match them, but taint analysis might not propagate through them correctly.  
  Expressions inside LINQ queries behave as expected.

- **Incomplete contextual XML lexing**  
  Some contextual lexing rules for embedded XML aren’t implemented yet.  
  Certain valid XML fragments—especially those containing `'` or `#`—may not parse correctly.

- **Complex type-system features**  
  Matching isn’t supported for some advanced type-system constructs, such as type constraints.
