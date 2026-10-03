This document summarizes the level of support for features of more recent editions of the C# language.

## Supported features

Here are the features as listed in What's New document for each version of the language

| Feature | Support | Notes |
|--------|---------|-------|
| **C# 12** || [learn.microsoft.com/.../whats-new/csharp-12](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-12) |
| - Primary constructors | ✅ | Syntactic sugar, see [note](#primary-constructors) |
| - Collection expressions | ✅ | [Note](#collection-expressions) |
| - `ref readonly` parameters | ✅ ||
| - Default lambda parameters | ✅ | E.g., `(int x = 2) => x + 1` |
| - Alias any type | ✅ ||
| - Inline arrays |  ✅ ||
| - `Experimental` attribute | ✅ ||
| - Interceptors | 🟡 | Supported syntactically, not supported for function call resolution |
| **C# 13** || [learn.microsoft.com/.../whats-new/csharp-13](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-13) |
| - `params` collections | ✅ ||
| - New lock object | ✅ ||
| - New escape sequence | ✅ ||
| - Method group natural type | 🟡 | Overloading resulution is supported by Opengrep only partially |
| - Implicit index access | 🟡 | Supported syntactically, no constant/taint propagation |
| - `ref` and `unsafe` in iterators | ✅ ||
| - `allows ref struct` | ✅ ||
| - `ref struct` interfaces | ✅ ||
| - More partial members | ✅ ||
| - Overload resolution priority | 🟡 | Overloading resolution is supported by Opengrep only partially |
| - The `field` keyword | ✅ | see the [note](#properties) on properties |
| **C# 14** || [learn.microsoft.com/.../whats-new/csharp-14](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14) |
| - Extension members | ✅ | see the [note](#extension-methods-and-blocks) on extension methods and blocks |
| - Implicit span conversions | ✅ ||
| - Unbound generic types and `nameof` | ✅ ||
| - Simple lambda parameters with modifiers | ❌ ||
| - User defined compound assignment |  🟡 | Supported syntactically, no constant/taint propagation ||
| - Null-conditional assignment | ✅ | ||


## Primary constructors

Opengrep treats primary constructors as non-direct declaration of fields in a class. For example, the following two definitions are indistinguishable:

```C#
public struct C(double x) { }

public struct C
{
    public double x;
}
```

## Collection expressions

Example:

```C#
int[] row0 = [1, 2, 3];
int[] row1 = [4, source(), 6];
int[] row2 = [7, 8, 9];
int[] single = [.. row0, .. row1, .. row2];
sink(single);
```

## Properties

Properties like

```C#
public int X
{
    get => ...;
    set => ...;
}
```

are equivalent to their expanded form

```C#
int get_X() { ... }
void set_X(int value) { ... }
```

use the latter syntax to safely match on the `value` parameter in taint flow analysis. Note that simply matching on `value` in the non-expanded form is not safe, as it will match on every occurrence of `value` in the body of the getter/setter, even if it was previously sanitized.

As a shorthand, one can specify a `[get]` and `[set]` property to match only expanded getters and setters respectively.

Example:

```C#
class C
{
    public string Message
    {
        set => sink(value);
    }
}
```

If we want to consider `value` to be taitned, we can specify the rule as:

```yaml
rules:
- id: taint_prop_value_no_field
  languages: [csharp]
  message: "tainted values reaches sink"
  severity: WARNING
  mode: taint
  pattern-sources:
    - patterns:
      - pattern-inside: |
          [set] $T $F($VALUE) { ... }
      - focus-metavariable: $VALUE
      - metavariable-regex:
          metavariable: $VALUE
          regex: value
  pattern-sinks:
    - pattern: |
        sink(...)
```

To match the data accessaible by the `field` keyword, add it to the expanded form pattern as a additional argument. NOTE: This is a deviation from the C# syntax, but curently there is no meaningful way in Opengrep to make fields in a class sources of taint.

Example:

```C#
class C
{
    public string Message2
    {
        get => sink(field);
        set => sink(field);
    }
}
```

If we want to make `field` tainted in `Message`, we can use the following rules:

```yaml
rules:
- id: taint_prop_field
  languages: [csharp]
  message: "tainted field reaches sink"
  severity: WARNING
  mode: taint
  pattern-sources:
    - patterns:
      - pattern-inside: |
          [get] $T $F($FIELD) { ... }
      - focus-metavariable: $FIELD
      - metavariable-regex:
          metavariable: $FIELD
          regex: field
    - patterns:
      - pattern-inside: |
          [set] $T $F($VALUE, $FIELD) { ... }
      - focus-metavariable: $FIELD
      - metavariable-regex:
          metavariable: $FIELD
          regex: field
  pattern-sinks:
    - pattern: |
        sink(...)
```

## Extension methods and blocks

Extension methods like

```C#
void foo(this SomeClass c, int a) { ... }
```

match both patterns with and without the `this` parameter, so the above function will match both

```C#
$T $F(int $X) { ... }
```

and 

```C#
$T $F(this $C $P, int $X)
```

Extension blocks like

```C#
static public class C
{
  extension(SomeClass c)
  {
    void foo(int a) { ... }
  }
}
```

are treated as syntactic sugar for the old-style extension methods, so the above is indistinguishable from


```C#
static public class C
{
  void foo(this SomeClass c, int a) { ... }
}
```

If you want to match extension methods for taint flow analysis, it's better to use the latter syntax.

For matching extension properties, it's best to match using:

```yaml
- patterns:
  - pattern-inside: |
      [set] $T $F(this $P $C, $VALUE, $FIELD) { ... }
```
