# Semgrep Pattern Examples by Language (offline cheatsheet)

> Upstream Semgrep content, NOT an OpenGrep compatibility promise. Retrieved 2026-10-03. No examples executed.

Extracted from the static data used by the [upstream cheatsheet](https://semgrep.dev/embed/cheatsheet). All language keys are retained, including internal TEMPLATE and unsupported/null entries. Exact match coordinates and original paths are in [cheatsheet.json](cheatsheet.json). Null values mean upstream provides no pattern/target, not a download failure.

## TEMPLATE

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/concrete_syntax.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_call.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_var.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_args.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_string.TEMPLATE",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## bash

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo <... bar ...>

```

Target:

```text
baz() {
  # MATCH:
  foo bar

  foo bar baz

  # MATCH:
  foo "$(echo 'hello' | bar)"
}

```

Match coordinates and source paths:

```json
{
  "code_path": "bash/deep_expr_operator.bash",
  "highlights": [
    {
      "end": {
        "col": 10,
        "line": 3,
        "offset": 28
      },
      "start": {
        "col": 3,
        "line": 3,
        "offset": 21
      }
    },
    {
      "end": {
        "col": 30,
        "line": 8,
        "offset": 85
      },
      "start": {
        "col": 3,
        "line": 8,
        "offset": 58
      }
    }
  ],
  "pattern_path": "bash/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo
bar

```

Target:

```text
foo() {
  # ERROR: match
  foo
  bar
  # ERROR: not sure this should match really
  foo
  x=$(bar)
  # ERROR: match
  foo
  foo2 "$(bar)"
  # ERROR: match, but not sure it should match really
  foo
  bloo | bar > /dev/null
}

```

Match coordinates and source paths:

```json
{
  "code_path": "bash/deep_exprstmt.bash",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 4,
        "offset": 36
      },
      "start": {
        "col": 3,
        "line": 3,
        "offset": 27
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 98
      },
      "start": {
        "col": 3,
        "line": 6,
        "offset": 84
      }
    },
    {
      "end": {
        "col": 16,
        "line": 10,
        "offset": 137
      },
      "start": {
        "col": 3,
        "line": 9,
        "offset": 118
      }
    },
    {
      "end": {
        "col": 13,
        "line": 13,
        "offset": 210
      },
      "start": {
        "col": 3,
        "line": 12,
        "offset": 194
      }
    }
  ],
  "pattern_path": "bash/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo bar

```

Target:

```text
# ERROR:
foo bar

# ERROR:
foo "bar"

foo "$bar"

# ERROR:
foo 'bar'

```

Match coordinates and source paths:

```json
{
  "code_path": "bash/concrete_syntax.bash",
  "highlights": [
    {
      "end": {
        "col": 8,
        "line": 2,
        "offset": 16
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 10,
        "line": 5,
        "offset": 36
      },
      "start": {
        "col": 1,
        "line": 5,
        "offset": 27
      }
    },
    {
      "end": {
        "col": 10,
        "line": 10,
        "offset": 68
      },
      "start": {
        "col": 1,
        "line": 10,
        "offset": 59
      }
    }
  ],
  "pattern_path": "bash/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo $X 2

```

Target:

```text
# ERROR:
foo 1 2

# ERROR:
foo "$(date)" 2

foo 2

```

Match coordinates and source paths:

```json
{
  "code_path": "bash/metavar_arg.bash",
  "highlights": [
    {
      "end": {
        "col": 8,
        "line": 2,
        "offset": 16
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 16,
        "line": 5,
        "offset": 42
      },
      "start": {
        "col": 1,
        "line": 5,
        "offset": 27
      }
    }
  ],
  "pattern_path": "bash/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$CMD foo bar

```

Target:

```text
# ERROR:
something foo bar

# ERROR:
"$thing" foo bar

```

Match coordinates and source paths:

```json
{
  "code_path": "bash/metavar_call.bash",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 2,
        "offset": 26
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 17,
        "line": 5,
        "offset": 53
      },
      "start": {
        "col": 1,
        "line": 5,
        "offset": 37
      }
    }
  ],
  "pattern_path": "bash/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $F() {
  ...
}

```

Target:

```text
# ERROR:
foo() {
  echo hello
}

# ERROR:
function foo() {
  echo hello
}


```

Match coordinates and source paths:

```json
{
  "code_path": "bash/metavar_func_def.bash",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 4,
        "offset": 31
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 2,
        "line": 9,
        "offset": 73
      },
      "start": {
        "col": 1,
        "line": 7,
        "offset": 42
      }
    }
  ],
  "pattern_path": "bash/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
cp ... $X ... $X

```

Target:

```text
# ERROR:
cp a b c b

cp a b c d

```

Match coordinates and source paths:

```json
{
  "code_path": "bash/metavar_equality_expr.bash",
  "highlights": [
    {
      "end": {
        "col": 11,
        "line": 2,
        "offset": 19
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "bash/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$FILE=''
touch "${$FILE}"

```

Target:

```text
# ERROR:
out=''
touch "$out"

```

Match coordinates and source paths:

```json
{
  "code_path": "bash/metavar_equality_var.bash",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 28
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "bash/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo ... 5

```

Target:

```text
foo

# ERROR:
foo 5

# ERROR:
foo 1 2 3 4 5

foo 5 6

```

Match coordinates and source paths:

```json
{
  "code_path": "bash/dots_args.bash",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 4,
        "offset": 19
      },
      "start": {
        "col": 1,
        "line": 4,
        "offset": 14
      }
    },
    {
      "end": {
        "col": 14,
        "line": 7,
        "offset": 43
      },
      "start": {
        "col": 1,
        "line": 7,
        "offset": 30
      }
    }
  ],
  "pattern_path": "bash/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.bash",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if ...; then
  ...
else
  ...
fi

```

Target:

```text
# MATCH:
if [[ -e foo ]]; then
  echo "foo exists"
else
  echo "error: foo is missing"
  exit 1
fi

```

Match coordinates and source paths:

```json
{
  "code_path": "bash/dots_nested_stmts.bash",
  "highlights": [
    {
      "end": {
        "col": 9,
        "line": 6,
        "offset": 95
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "bash/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V=$(cat)
...
eval ${$V}

```

Target:

```text
# ERROR:
CMD=$(cat)
eval $CMD

# ERROR:
cmd=$(cat)
echo "User entered: $cmd"
eval $cmd

```

Match coordinates and source paths:

```json
{
  "code_path": "bash/dots_stmts.bash",
  "highlights": [
    {
      "end": {
        "col": 10,
        "line": 3,
        "offset": 29
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 10,
        "line": 8,
        "offset": 86
      },
      "start": {
        "col": 1,
        "line": 6,
        "offset": 40
      }
    }
  ],
  "pattern_path": "bash/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo "..."

```

Target:

```text
# simple strings
foo bar
foo "bar"
foo 'bar'

# string made of multiple fragments
# ERROR:
foo "${HOME}/bar"


```

Match coordinates and source paths:

```json
{
  "code_path": "bash/dots_string.bash",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 8,
        "offset": 108
      },
      "start": {
        "col": 1,
        "line": 8,
        "offset": 91
      }
    }
  ],
  "pattern_path": "bash/dots_string.sgrep"
}
```

## c

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
int main() {
    int bar = 0;
    //ERROR: match
    foo(bar + 42);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "c/deep_expr_operator.c",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 53
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
int main(int argc, char *argv[]) {
	//ERROR: match
        foo();
	bar();
	//ERROR: match
        foo();
	int x = bar();
	//ERROR: match
        foo();
	foo(bar());
	//ERROR: match
        foo();
	return bar();
}

```

Match coordinates and source paths:

```json
{
  "code_path": "c/deep_exprstmt.c",
  "highlights": [
    {
      "end": {
        "col": 8,
        "line": 4,
        "offset": 73
      },
      "start": {
        "col": 9,
        "line": 3,
        "offset": 59
      }
    },
    {
      "end": {
        "col": 15,
        "line": 7,
        "offset": 119
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 98
      }
    },
    {
      "end": {
        "col": 13,
        "line": 10,
        "offset": 164
      },
      "start": {
        "col": 9,
        "line": 9,
        "offset": 145
      }
    },
    {
      "end": {
        "col": 14,
        "line": 13,
        "offset": 209
      },
      "start": {
        "col": 9,
        "line": 12,
        "offset": 189
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
void foo() {
 //ERROR:
    foo(1,2);

 //ERROR:
 foo(1,
     2);

 //ERROR:
 foo (1, // comment
      2);

 foo(2,1);
}



```

Match coordinates and source paths:

```json
{
  "code_path": "c/concrete_syntax.c",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 35
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 27
      }
    },
    {
      "end": {
        "col": 8,
        "line": 7,
        "offset": 63
      },
      "start": {
        "col": 2,
        "line": 6,
        "offset": 49
      }
    },
    {
      "end": {
        "col": 9,
        "line": 11,
        "offset": 104
      },
      "start": {
        "col": 2,
        "line": 10,
        "offset": 77
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.c",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

### Named Placeholders ($X)

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
void foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(a_very_long_constant_name,
        2);

    //ERROR:
    foo (unsafe(), // indeed
         2);

    //ERROR:
    foo(bar(1,3), 2);

    foo(2,1);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "c/metavar_arg.c",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 38
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 99
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 58
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 155
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 119
      }
    },
    {
      "end": {
        "col": 21,
        "line": 14,
        "offset": 191
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 175
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
void foo() {
    x = 1;
    //ERROR:
    if (x > 2)
        foo();
}


```

Match coordinates and source paths:

```json
{
  "code_path": "c/metavar_cond.c",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 5,
        "offset": 66
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 41
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
void foo() {
    //ERROR:
    foo(1,2);

    return 1;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "c/metavar_call.c",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 38
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.c",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
#include $X

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.c",
  "highlights": [],
  "pattern_path": "c/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.c",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
void foo() {
    v = 1;
    //ERROR:
    if (v > 2)
        return 1;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "c/metavar_stmt.c",
  "highlights": [
    {
      "end": {
        "col": 17,
        "line": 5,
        "offset": 68
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 41
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.c",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(char *$X) == $Y

```

Target:

```text
int test_equal() {
    int a = 1;
    int b = 2;
    if (a == b) return 1;
    if (3 == 4) return 2;

    int *p = malloc(sizeof(int));
    int *q = malloc(sizeof(int));
    if (p == q) return 1;

    char *x = "hello";
    char *y = "bye";
    //ERROR: match
    if (x == y) return 2;
    //ERROR: match
    if (x == "nope") return 3;
    //ERROR: match
    if ("lit1" == "lit2") return 4;
    return 0;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "c/metavar_typed.c",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 14,
        "offset": 274
      },
      "start": {
        "col": 9,
        "line": 14,
        "offset": 268
      }
    },
    {
      "end": {
        "col": 20,
        "line": 16,
        "offset": 324
      },
      "start": {
        "col": 9,
        "line": 16,
        "offset": 313
      }
    },
    {
      "end": {
        "col": 25,
        "line": 18,
        "offset": 379
      },
      "start": {
        "col": 9,
        "line": 18,
        "offset": 363
      }
    }
  ],
  "pattern_path": "c/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.c",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
void foo() {
    //ERROR: match
    char path = "/location/1";
}


```

Match coordinates and source paths:

```json
{
  "code_path": "c/regexp_string.c",
  "highlights": [
    {
      "end": {
        "col": 30,
        "line": 3,
        "offset": 61
      },
      "start": {
        "col": 10,
        "line": 3,
        "offset": 41
      }
    }
  ],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
void test_equal() {
    a = 1;
    b = 2;
    //ERROR: match
    if (a+b == a+b)
        return 1;
    return 0;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "c/metavar_equality_expr.c",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 5,
        "offset": 79
      },
      "start": {
        "col": 9,
        "line": 5,
        "offset": 69
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
void foo() {
    //ERROR:
    if (x > 2) {
        foo();
        bar();
    } else {
        foo();
        bar();
    }

    if (x > 2) {
        foo();
        bar();
    } else {
        foo();
    }
}




```

Match coordinates and source paths:

```json
{
  "code_path": "c/metavar_equality_stmt.c",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 9,
        "offset": 121
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
void foo() {
  //ERROR:
    myfile = open();
    close(myfile);
}




```

Match coordinates and source paths:

```json
{
  "code_path": "c/metavar_equality_var.c",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 63
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
void foo() {
  //ERROR:
    foo(1,2,3,4,5);
  //ERROR:
    foo(5);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "c/dots_args.c",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 65
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 59
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.c",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.c",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
void foo() {

    //ERROR:
    user_data = get();
    print("do stuff");
    foobar();
    eval(user_data);
}



```

Match coordinates and source paths:

```json
{
  "code_path": "c/dots_stmts.c",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 7,
        "offset": 107
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 31
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
void foo() {
    //ERROR:
    foo("whatever sequence of chars");
}


```

Match coordinates and source paths:

```json
{
  "code_path": "c/dots_string.c",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 63
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## cpp

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
int main() {
    int bar = 0;
    //ERROR: match
    foo(bar + 42);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/deep_expr_operator.cpp",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 53
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
int main(int argc, char *argv[]) {
	//ERROR: match
        foo();
	bar();
	//ERROR: match
        foo();
	int x = bar();
	//ERROR: match
        foo();
	foo(bar());
	//ERROR: match
        foo();
	return bar();
}

```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/deep_exprstmt.cpp",
  "highlights": [
    {
      "end": {
        "col": 8,
        "line": 4,
        "offset": 73
      },
      "start": {
        "col": 9,
        "line": 3,
        "offset": 59
      }
    },
    {
      "end": {
        "col": 15,
        "line": 7,
        "offset": 119
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 98
      }
    },
    {
      "end": {
        "col": 13,
        "line": 10,
        "offset": 164
      },
      "start": {
        "col": 9,
        "line": 9,
        "offset": 145
      }
    },
    {
      "end": {
        "col": 15,
        "line": 13,
        "offset": 210
      },
      "start": {
        "col": 9,
        "line": 12,
        "offset": 189
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
void foo() {
 //ERROR:
    foo(1,2);

 //ERROR:
 foo(1,
     2);

 //ERROR:
 foo (1, // comment
      2);

 foo(2,1);
}



```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/concrete_syntax.cpp",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 35
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 27
      }
    },
    {
      "end": {
        "col": 8,
        "line": 7,
        "offset": 63
      },
      "start": {
        "col": 2,
        "line": 6,
        "offset": 49
      }
    },
    {
      "end": {
        "col": 9,
        "line": 11,
        "offset": 104
      },
      "start": {
        "col": 2,
        "line": 10,
        "offset": 77
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
void foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(a_very_long_constant_name,
        2);

    //ERROR:
    foo (unsafe(), // indeed
         2);

    //ERROR:
    foo(bar(1,3), 2);

    foo(2,1);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/metavar_arg.cpp",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 38
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 99
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 58
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 155
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 119
      }
    },
    {
      "end": {
        "col": 21,
        "line": 14,
        "offset": 191
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 175
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
void foo() {
    x = 1;
    //ERROR:
    if (x > 2)
        foo();
}


```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/metavar_cond.cpp",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 5,
        "offset": 66
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 41
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
void foo() {
    //ERROR:
    foo(1,2);

    return 1;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/metavar_call.cpp",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 38
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
void foo() {
    v = 1;
    //ERROR:
    if (v > 2)
        return 1;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/metavar_stmt.cpp",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 5,
        "offset": 69
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 41
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
void foo() {
    //ERROR: match
    char path = "/location/1";
}


```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/regexp_string.cpp",
  "highlights": [
    {
      "end": {
        "col": 30,
        "line": 3,
        "offset": 61
      },
      "start": {
        "col": 10,
        "line": 3,
        "offset": 41
      }
    }
  ],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
void test_equal() {
    a = 1;
    b = 2;
    //ERROR: match
    if (a+b == a+b)
        return 1;
    return 0;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/metavar_equality_expr.cpp",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 5,
        "offset": 79
      },
      "start": {
        "col": 9,
        "line": 5,
        "offset": 69
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
void foo() {
    //ERROR:
    if (x > 2) {
        foo();
        bar();
    } else {
        foo();
        bar();
    }

    if (x > 2) {
        foo();
        bar();
    } else {
        foo();
    }
}




```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/metavar_equality_stmt.cpp",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 9,
        "offset": 121
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
void foo() {
  //ERROR:
    myfile = open();
    close(myfile);
}




```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/metavar_equality_var.cpp",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 63
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
void foo() {
  //ERROR:
    foo(1,2,3,4,5);
  //ERROR:
    foo(5);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/dots_args.cpp",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 65
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 59
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.cpp",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
void foo() {

    //ERROR:
    user_data = get();
    print("do stuff");
    foobar();
    eval(user_data);
}



```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/dots_stmts.cpp",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 7,
        "offset": 107
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 31
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
void foo() {
    //ERROR:
    foo("whatever sequence of chars");
}


```

Match coordinates and source paths:

```json
{
  "code_path": "cpp/dots_string.cpp",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 63
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## csharp

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
<... 12 ...>
```

Target:

```text
public class Test
{
    public static void Test()
    {
        int x = 13;
        //ERROR:
        Console.WriteLine(x + 12 + x);
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/deep_expr_operator.cs",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 7,
        "offset": 130
      },
      "start": {
        "col": 9,
        "line": 7,
        "offset": 101
      }
    },
    {
      "end": {
        "col": 33,
        "line": 7,
        "offset": 125
      },
      "start": {
        "col": 27,
        "line": 7,
        "offset": 119
      }
    },
    {
      "end": {
        "col": 37,
        "line": 7,
        "offset": 129
      },
      "start": {
        "col": 27,
        "line": 7,
        "offset": 119
      }
    },
    {
      "end": {
        "col": 33,
        "line": 7,
        "offset": 125
      },
      "start": {
        "col": 31,
        "line": 7,
        "offset": 123
      }
    }
  ],
  "pattern_path": "csharp/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
using System;

class HelloWorldFuncCall
{
    public static string Test()
    {
        //ERROR:
        foo();
        bar();

        //ERROR:
        foo();
        Console.WriteLine(bar());

        //ERROR:
        foo();
        var x = bar();

	//ERROR:
        foo();
	return bar();
    }

    private static string bar()
    {
        return "hello world";
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/deep_exprstmt.cs",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 9,
        "offset": 126
      },
      "start": {
        "col": 9,
        "line": 8,
        "offset": 105
      }
    },
    {
      "end": {
        "col": 34,
        "line": 13,
        "offset": 193
      },
      "start": {
        "col": 9,
        "line": 12,
        "offset": 153
      }
    },
    {
      "end": {
        "col": 22,
        "line": 17,
        "offset": 248
      },
      "start": {
        "col": 9,
        "line": 16,
        "offset": 220
      }
    },
    {
      "end": {
        "col": 15,
        "line": 21,
        "offset": 290
      },
      "start": {
        "col": 9,
        "line": 20,
        "offset": 269
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
Foo(1, 2)
```

Target:

```text
public class ConcreteSyntax
{
    public static void Main()
    {
        // ERROR:
        Foo(1, 2);

        // ERROR:
        Foo(1,
            2);

        // ERROR:
        Foo(1, // comment
            2);

        Foo(2, 1);

        Foo(1, 2, 3);
    }

    private static void Foo(int a, int b, int c = 3)
    {
    }
}
```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/concrete_syntax.cs",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 6,
        "offset": 101
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 92
      }
    },
    {
      "end": {
        "col": 15,
        "line": 10,
        "offset": 151
      },
      "start": {
        "col": 9,
        "line": 9,
        "offset": 130
      }
    },
    {
      "end": {
        "col": 15,
        "line": 14,
        "offset": 212
      },
      "start": {
        "col": 9,
        "line": 13,
        "offset": 180
      }
    }
  ],
  "pattern_path": "csharp/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
Console.WriteLine("world");
```

Target:

```text
public class Test
{
    public static void Test()
    {
        String x = "world";
        //ERROR:
        Console.WriteLine(x);
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/equivalence_constant_propagation.cs",
  "highlights": [
    {
      "end": {
        "col": 30,
        "line": 7,
        "offset": 130
      },
      "start": {
        "col": 9,
        "line": 7,
        "offset": 109
      }
    }
  ],
  "pattern_path": "csharp/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.cs",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
[$ANNO]
class $CLASS{ ... }
```

Target:

```text
// ERROR:
[Serializable]
public class Test {
}
```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_anno.cs",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 4,
        "offset": 46
      },
      "start": {
        "col": 2,
        "line": 2,
        "offset": 11
      }
    }
  ],
  "pattern_path": "csharp/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
Foo($X, 2)

```

Target:

```text
public class MetaVar
{
    public static void Main()
    {
        // ERROR:
        Foo(1, 2);

        // ERROR:
        Foo(int.MaxValue,
            2);

        // ERROR:
        Foo(int.Parse("3"), // comment
            2);

        // ERROR:
        Foo(Bar(1, 3), 2);

	// OK:
        Foo(2, 1);

	// OK:
	Foo(1, 2, 3);
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_arg.cs",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 6,
        "offset": 94
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 85
      }
    },
    {
      "end": {
        "col": 15,
        "line": 10,
        "offset": 155
      },
      "start": {
        "col": 9,
        "line": 9,
        "offset": 123
      }
    },
    {
      "end": {
        "col": 15,
        "line": 14,
        "offset": 229
      },
      "start": {
        "col": 9,
        "line": 13,
        "offset": 184
      }
    },
    {
      "end": {
        "col": 26,
        "line": 17,
        "offset": 275
      },
      "start": {
        "col": 9,
        "line": 17,
        "offset": 258
      }
    }
  ],
  "pattern_path": "csharp/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $KLASS {}
```

Target:

```text
// ERROR:
class Foo {
}

interface Foo {
}

namespace Foo {
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_class_def.cs",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 3,
        "offset": 23
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 10
      }
    }
  ],
  "pattern_path": "csharp/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($COND) { ... }

```

Target:

```text
public class Test
{
    public static void Test()
    {
        //ERROR:
        if (x == some_cond)
            Console.WriteLine("matched");
        else
            Console.WriteLine("not matched");
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_cond.cs",
  "highlights": [
    {
      "end": {
        "col": 46,
        "line": 9,
        "offset": 201
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 81
      }
    }
  ],
  "pattern_path": "csharp/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
public class Test
{
    public static int Test()
    {
        // ERROR:
        Foo(1, 2);
        return 1;
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_call.cs",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 6,
        "offset": 90
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 81
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
$RETURNTYPE $FUNC(...) {...}
```

Target:

```text
public class Test
{
    // ERROR:
    public static int Test()
    {
        Foo(1, 2);
        return 1;
    }

    // ERROR:
    int Test2() {
        return 1;
    }

    // ERROR:
    public static void Main()
    {
        Foo(1, 2);
        return 1;
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_func_def.cs",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 8,
        "offset": 111
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 38
      }
    },
    {
      "end": {
        "col": 6,
        "line": 13,
        "offset": 168
      },
      "start": {
        "col": 5,
        "line": 11,
        "offset": 131
      }
    },
    {
      "end": {
        "col": 6,
        "line": 20,
        "offset": 262
      },
      "start": {
        "col": 5,
        "line": 16,
        "offset": 188
      }
    }
  ],
  "pattern_path": "csharp/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
using $X;
```

Target:

```text
// ERROR:
using System;
// ERROR:
using System.IO;

class Test {}
```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_import.cs",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 2,
        "offset": 23
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 10
      }
    },
    {
      "end": {
        "col": 17,
        "line": 4,
        "offset": 50
      },
      "start": {
        "col": 1,
        "line": 4,
        "offset": 34
      }
    }
  ],
  "pattern_path": "csharp/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
Foo(..., bar: 42, ...);
```

Target:

```text
class Test 
{
    public static void Main()
    {
        // OK:
        Foo(42, "baz");

        // ERROR:
        Foo(bar: 42, baz: "baz");
        // ERROR:
        Foo(baz: "baz", bar: 42);
    }
}
```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_key_value.cs",
  "highlights": [
    {
      "end": {
        "col": 34,
        "line": 9,
        "offset": 141
      },
      "start": {
        "col": 9,
        "line": 9,
        "offset": 116
      }
    },
    {
      "end": {
        "col": 34,
        "line": 11,
        "offset": 193
      },
      "start": {
        "col": 9,
        "line": 11,
        "offset": 168
      }
    }
  ],
  "pattern_path": "csharp/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E) {
    $S;
}

```

Target:

```text
public class Test
{
    public static void Test()
    {
        //ERROR:
        if (true)
            Console.WriteLine("same");
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_stmt.cs",
  "highlights": [
    {
      "end": {
        "col": 39,
        "line": 7,
        "offset": 129
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 81
      }
    }
  ],
  "pattern_path": "csharp/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.cs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
$X == (String $Y)

```

Target:

```text
public class Foo {
    public static void main() {
        String x;
        String y;
        int a;
        int b;
        //ERROR: match
        if (x == y) x = y;
        if (a == b) a = b;
   }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_typed.cs",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 8,
        "offset": 158
      },
      "start": {
        "col": 13,
        "line": 8,
        "offset": 152
      }
    }
  ],
  "pattern_path": "csharp/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.cs",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.cs",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X

```

Target:

```text
public class Test
{
    public static void Test()
    {
        //ERROR:
        if (1+2 == 1+2)
            Console.WriteLine("matched");
        else
            Console.WriteLine("not matched");
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_equality_expr.cs",
  "highlights": [
    {
      "end": {
        "col": 23,
        "line": 6,
        "offset": 95
      },
      "start": {
        "col": 13,
        "line": 6,
        "offset": 85
      }
    }
  ],
  "pattern_path": "csharp/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E) {
    $S;
} else {
    $S;
}

```

Target:

```text
public class Test
{
    public static void Test()
    {
        //ERROR:
        if (true)
            Console.WriteLine("same");
        else
            Console.WriteLine("same");
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_equality_stmt.cs",
  "highlights": [
    {
      "end": {
        "col": 39,
        "line": 9,
        "offset": 181
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 81
      }
    }
  ],
  "pattern_path": "csharp/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = Open();
Close($V);


```

Target:

```text
public class Test
{
    public static void Test()
    {
        // ERROR:
        myFile = Open();
        Close(myFile);
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/metavar_equality_var.cs",
  "highlights": [
    {
      "end": {
        "col": 23,
        "line": 7,
        "offset": 121
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 82
      }
    }
  ],
  "pattern_path": "csharp/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
Foo(..., 5)

```

Target:

```text
public class Test
{
    public static void Test()
    {
        // ERROR:
        Foo(1, 2, 3, 4, 5);
        // ERROR:
        Foo(5);
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/dots_args.cs",
  "highlights": [
    {
      "end": {
        "col": 27,
        "line": 6,
        "offset": 100
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 82
      }
    },
    {
      "end": {
        "col": 15,
        "line": 8,
        "offset": 134
      },
      "start": {
        "col": 9,
        "line": 8,
        "offset": 128
      }
    }
  ],
  "pattern_path": "csharp/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
class Foo {

  void test() {

    //ERROR: match
    f = this.foo().m().h().bar().z();

    //ERROR: match
    f = this.foo().bar();

    f = this.foo().m().h().z();

    //ERROR: match $O can match o.before()
    f = this.before().foo().m().h().bar().z();
  }
}


```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/dots_method_chaining.cs",
  "highlights": [
    {
      "end": {
        "col": 37,
        "line": 6,
        "offset": 85
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 53
      }
    },
    {
      "end": {
        "col": 25,
        "line": 9,
        "offset": 131
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 111
      }
    },
    {
      "end": {
        "col": 46,
        "line": 14,
        "offset": 255
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 214
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
{
    ...
}

```

Target:

```text
public class Test
{
    public static void Test()
    {
        //ERROR:
        if (x == some_cond)
            Console.WriteLine("matched");
        else
            Console.WriteLine("not matched");
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/dots_nested_stmts.cs",
  "highlights": [
    {
      "end": {
        "col": 46,
        "line": 9,
        "offset": 201
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 81
      }
    }
  ],
  "pattern_path": "csharp/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$X = Get();
...
Eval($X)

```

Target:

```text
public class Test
{
    public static void Test()
    {
        //ERROR:
        userData = Get();
        Console.WriteLine("do stuff");
        FooBar();
        Eval(userData);
        FooBar();
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/dots_stmts.cs",
  "highlights": [
    {
      "end": {
        "col": 24,
        "line": 9,
        "offset": 179
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 81
      }
    }
  ],
  "pattern_path": "csharp/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
Foo("...")

```

Target:

```text
public static void Bar(input) {
    //ERROR:
    Foo("whatever sequence of chars");

    //OK:
    Foo("not a constant string: " + input);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "csharp/dots_string.cs",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 82
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 49
      }
    }
  ],
  "pattern_path": "csharp/dots_string.sgrep"
}
```

## dockerfile

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo
bar

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.dockerfile",
  "highlights": [],
  "pattern_path": "dockerfile/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
FROM ubuntu
RUN echo hello

```

Target:

```text
# ERROR:
FROM ubuntu
RUN echo hello

FROM debian
RUN echo hello

# ERROR:
FROM ubuntu:testing
RUN echo hello

```

Match coordinates and source paths:

```json
{
  "code_path": "dockerfile/concrete_syntax.dockerfile",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 3,
        "offset": 35
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 15,
        "line": 10,
        "offset": 108
      },
      "start": {
        "col": 1,
        "line": 9,
        "offset": 74
      }
    }
  ],
  "pattern_path": "dockerfile/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo $X 2

```

Target:

```text
# ERROR:
RUN foo 1 2

# ERROR:
RUN foo "$(date)" 2

RUN foo 2

```

Match coordinates and source paths:

```json
{
  "code_path": "dockerfile/metavar_arg.dockerfile",
  "highlights": [
    {
      "end": {
        "col": 12,
        "line": 2,
        "offset": 20
      },
      "start": {
        "col": 5,
        "line": 2,
        "offset": 13
      }
    },
    {
      "end": {
        "col": 20,
        "line": 5,
        "offset": 50
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 35
      }
    }
  ],
  "pattern_path": "dockerfile/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$CMD foo bar

```

Target:

```text
# ERROR:
RUN something foo bar

# ERROR:
CMD "$thing" foo bar

```

Match coordinates and source paths:

```json
{
  "code_path": "dockerfile/metavar_call.dockerfile",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 2,
        "offset": 30
      },
      "start": {
        "col": 5,
        "line": 2,
        "offset": 13
      }
    },
    {
      "end": {
        "col": 21,
        "line": 5,
        "offset": 61
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 45
      }
    }
  ],
  "pattern_path": "dockerfile/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
RUN $FILE='' && touch "${$FILE}"

```

Target:

```text
# ERROR:
RUN out='' && touch "$out"

```

Match coordinates and source paths:

```json
{
  "code_path": "dockerfile/metavar_equality_var.dockerfile",
  "highlights": [
    {
      "end": {
        "col": 27,
        "line": 2,
        "offset": 35
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "dockerfile/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo ... 5

```

Target:

```text
RUN foo

# ERROR:
RUN foo 5

# ERROR:
RUN foo 1 2 3 4 5

RUN foo 5 6

```

Match coordinates and source paths:

```json
{
  "code_path": "dockerfile/dots_args.dockerfile",
  "highlights": [
    {
      "end": {
        "col": 10,
        "line": 4,
        "offset": 27
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 22
      }
    },
    {
      "end": {
        "col": 18,
        "line": 7,
        "offset": 55
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 42
      }
    }
  ],
  "pattern_path": "dockerfile/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.dockerfile",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if ...; then
  ...
else
  ...
fi

```

Target:

```text
# MATCH:
RUN if [[ -e foo ]]; then \
      echo "foo exists"; \
    else \
      echo "error: foo is missing"; \
      exit 1; \
    fi

```

Match coordinates and source paths:

```json
{
  "code_path": "dockerfile/dots_nested_stmts.dockerfile",
  "highlights": [
    {
      "end": {
        "col": 7,
        "line": 6,
        "offset": 119
      },
      "start": {
        "col": 5,
        "line": 2,
        "offset": 13
      }
    }
  ],
  "pattern_path": "dockerfile/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
FROM debian
...
RUN apt-get ...

```

Target:

```text
# ERROR:
FROM debian:testing
RUN echo hello
RUN apt-get update && apt-get install -y fortune

```

Match coordinates and source paths:

```json
{
  "code_path": "dockerfile/dots_stmts.dockerfile",
  "highlights": [
    {
      "end": {
        "col": 49,
        "line": 4,
        "offset": 92
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "dockerfile/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo "..."

```

Target:

```text
# simple strings
RUN foo bar
RUN foo "bar"
RUN foo 'bar'

# string made of multiple fragments
# ERROR:
RUN foo "${HOME}/bar"

```

Match coordinates and source paths:

```json
{
  "code_path": "dockerfile/dots_string.dockerfile",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 8,
        "offset": 124
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 107
      }
    }
  ],
  "pattern_path": "dockerfile/dots_string.sgrep"
}
```

## elixir

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/concrete_syntax.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_call.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_var.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_args.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_string.elixir",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## generic

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
// Generic mode sees words, punctuation, and indented blocks.
class Foo {
  void foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(1,
        2);  // whitespace is ignored.

    foo (1,  // comments aren't ignored :-(
         2);

    foo (1,
  2);  // nonsensical indentation.

    //ERROR:
    foo (1,
    2);  // acceptable indentation.

    foo(2,1);
  }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "generic/concrete_syntax.generic",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 5,
        "offset": 114
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 106
      }
    },
    {
      "end": {
        "col": 11,
        "line": 9,
        "offset": 151
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 134
      }
    },
    {
      "end": {
        "col": 7,
        "line": 19,
        "offset": 318
      },
      "start": {
        "col": 5,
        "line": 18,
        "offset": 304
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
class Foo {
  void foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    Bar.Baz(
     1,
     2
    );

    return 1;
  }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "generic/metavar_call.generic",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 4,
        "offset": 52
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 44
      }
    },
    {
      "end": {
        "col": 6,
        "line": 10,
        "offset": 101
      },
      "start": {
        "col": 9,
        "line": 7,
        "offset": 76
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
  ...;

```

Target:

```text
class Foo {
  void foo() {
    v = 1;

    //ERROR:
    if (v > 2)
      return 1;

    //ERROR:
    if (v > 2)
      x++;

    // If the pattern contains an indented block, it must match an indented
    // block in the program. Usually, indentation in the pattern is
    // best avoided.
    //
    if (v > 2) return 1;

    // Another tricky case that doesn't match. This is due to indentation
    // in the pattern after the closing parenthesis ')', but no indentation
    // in the program between ')' and '{'.
    //
    if (v > 2) {
      x++;
    }

    return 0;
  }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "generic/metavar_stmt.generic",
  "highlights": [
    {
      "end": {
        "col": 16,
        "line": 7,
        "offset": 82
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 56
      }
    },
    {
      "end": {
        "col": 11,
        "line": 11,
        "offset": 122
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 101
      }
    }
  ],
  "pattern_path": "generic/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
...
close($V);

```

Target:

```text
class Foo {
  void foo() {
    //ERROR:
    myfile = open();
    try {
      foo(myfile);
    }
    finally {
      close(myfile);
    }
  }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "generic/metavar_equality_var.generic",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 9,
        "offset": 130
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 44
      }
    }
  ],
  "pattern_path": "generic/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(
  ... 5 ...
)

```

Target:

```text
class Foo {
  void bar() {
    //ERROR:
    foo(1,2,3,4,5);

    //ERROR:
    foo ( 5 );

    //ERROR:
    foo("5");  // this matches too.

    //ERROR:
    foo(5, ")");  // quoted strings are not understood.

    //ERROR:
    foo(5.5);  // '.' is generic punctuation.

    foo(55);  // '55' is a single word of the form [A-Za-z0-9_]+

    /*
       Matching nested parentheses requires an indented pattern:

       Do:
           foo(
             ...
           )

       Don't:

           foo(...)
    */

    //ERROR:
    foo(bar(baz(5)));

    //ERROR:
    foo(
      bar(
        baz(5)
      )
    );

    foo(
      5
      );  // strange indentation fails to match indentation in the pattern.

    // Dots ('...') can match at most 10 lines.
    // Use '... ...' to match up to 20 lines.
    foo(
     5,
     6,
     7,
     8,
     9,
     10,
     11,
     12,
     13,
     14,
     15,
     16,
     17
    );
  }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "generic/dots_args.generic",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 58
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 44
      }
    },
    {
      "end": {
        "col": 14,
        "line": 7,
        "offset": 87
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 78
      }
    },
    {
      "end": {
        "col": 13,
        "line": 10,
        "offset": 115
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 107
      }
    },
    {
      "end": {
        "col": 14,
        "line": 13,
        "offset": 166
      },
      "start": {
        "col": 5,
        "line": 13,
        "offset": 157
      }
    },
    {
      "end": {
        "col": 13,
        "line": 16,
        "offset": 235
      },
      "start": {
        "col": 5,
        "line": 16,
        "offset": 227
      }
    },
    {
      "end": {
        "col": 21,
        "line": 34,
        "offset": 543
      },
      "start": {
        "col": 5,
        "line": 34,
        "offset": 527
      }
    },
    {
      "end": {
        "col": 6,
        "line": 41,
        "offset": 607
      },
      "start": {
        "col": 5,
        "line": 37,
        "offset": 563
      }
    },
    {
      "end": {
        "col": 6,
        "line": 63,
        "offset": 923
      },
      "start": {
        "col": 5,
        "line": 49,
        "offset": 802
      }
    }
  ],
  "pattern_path": "generic/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.generic",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
class Foo {
  void foo() {

    //ERROR:
    user_data = get();
    print("do stuff");
    foobar();
    eval(user_data);
  }
}


```

Match coordinates and source paths:

```json
{
  "code_path": "generic/dots_stmts.generic",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 8,
        "offset": 121
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 45
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo(
  "..."
)

```

Target:

```text
class Foo {
  void bar () {
    //ERROR:
    foo("whatever sequence of chars");

    //ERROR:
    foo("abc", "def");  // generic mode doesn't understand strings.

    //ERROR:
    foo("hello \"world\"");

    foo("broken);
  }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "generic/dots_string.generic",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 4,
        "offset": 78
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 45
      }
    },
    {
      "end": {
        "col": 22,
        "line": 7,
        "offset": 115
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 98
      }
    },
    {
      "end": {
        "col": 27,
        "line": 10,
        "offset": 202
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 180
      }
    }
  ],
  "pattern_path": "generic/dots_string.sgrep"
}
```

## go

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
package Foo

func bar() {
	baz := 0
	//ERROR: match
	foo(baz + 42)
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/deep_expr_operator.go",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 6,
        "offset": 66
      },
      "start": {
        "col": 2,
        "line": 6,
        "offset": 53
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
package Foo

func foo() {
	//ERROR: match
        foo()
	bar()
	//ERROR: match
        foo()
	x = bar()
	//ERROR: match
        foo()
	foo2(bar())
	//ERROR: match
        foo()
	return bar()
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/deep_exprstmt.go",
  "highlights": [
    {
      "end": {
        "col": 7,
        "line": 6,
        "offset": 62
      },
      "start": {
        "col": 9,
        "line": 5,
        "offset": 50
      }
    },
    {
      "end": {
        "col": 11,
        "line": 9,
        "offset": 103
      },
      "start": {
        "col": 9,
        "line": 8,
        "offset": 87
      }
    },
    {
      "end": {
        "col": 13,
        "line": 12,
        "offset": 146
      },
      "start": {
        "col": 9,
        "line": 11,
        "offset": 128
      }
    },
    {
      "end": {
        "col": 14,
        "line": 15,
        "offset": 190
      },
      "start": {
        "col": 9,
        "line": 14,
        "offset": 171
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
package Foo

func foo() {
    //ERROR:
    foo(1,2);
    
    //ERROR:
    foo(1,
        2);
    
    //ERROR:
    foo (1, // comment
         2)
    
    foo(2,1)
    
}


```

Match coordinates and source paths:

```json
{
  "code_path": "go/concrete_syntax.go",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 5,
        "offset": 51
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 43
      }
    },
    {
      "end": {
        "col": 11,
        "line": 9,
        "offset": 92
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 75
      }
    },
    {
      "end": {
        "col": 12,
        "line": 13,
        "offset": 146
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 116
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
package Foo

const Bar = "password"

func foo() {
     //ERROR: match!
     dangerous1("password");

     //ERROR: match!
     dangerous2(Bar);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/equivalence_constant_propagation.go",
  "highlights": [
    {
      "end": {
        "col": 28,
        "line": 7,
        "offset": 98
      },
      "start": {
        "col": 6,
        "line": 7,
        "offset": 76
      }
    },
    {
      "end": {
        "col": 21,
        "line": 10,
        "offset": 142
      },
      "start": {
        "col": 6,
        "line": 10,
        "offset": 127
      }
    }
  ],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
subprocess.open(...)
```

Target:

```text
package Foo

import "a/subprocess"

import sub "subprocess"

func foo() {
  //ERROR:
  result = subprocess.open("ls")
  //ERROR:
  result = sub.open("ls")

  result = sub.not_open("ls")

}
```

Match coordinates and source paths:

```json
{
  "code_path": "go/equivalence_naming_import.go",
  "highlights": [
    {
      "end": {
        "col": 33,
        "line": 9,
        "offset": 117
      },
      "start": {
        "col": 12,
        "line": 9,
        "offset": 96
      }
    },
    {
      "end": {
        "col": 26,
        "line": 11,
        "offset": 154
      },
      "start": {
        "col": 12,
        "line": 11,
        "offset": 140
      }
    }
  ],
  "pattern_path": "go/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
package Foo

func bar() {
    //ERROR:
    foo(1,2)

    //ERROR:
    foo(a_very_long_constant_name,
        2)

    //ERROR:
    foo (unsafe(), // indeed
         2)

    //ERROR:
    foo(bar(1,3), 2)

    foo(2,1)
}



```

Match coordinates and source paths:

```json
{
  "code_path": "go/metavar_arg.go",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 5,
        "offset": 51
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 43
      }
    },
    {
      "end": {
        "col": 11,
        "line": 9,
        "offset": 111
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 70
      }
    },
    {
      "end": {
        "col": 12,
        "line": 13,
        "offset": 166
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 130
      }
    },
    {
      "end": {
        "col": 21,
        "line": 16,
        "offset": 201
      },
      "start": {
        "col": 5,
        "line": 16,
        "offset": 185
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E) { 
  foo() 
}
```

Target:

```text
package Foo

func foo() {
    x = 1
    //ERROR:
    if (x > 2) {
        foo()
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/metavar_cond.go",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 8,
        "offset": 85
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 53
      }
    }
  ],
  "pattern_path": "go/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
package Foo

func foo() {
    //ERROR:
    foo(1,2)

    return 1
}




```

Match coordinates and source paths:

```json
{
  "code_path": "go/metavar_call.go",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 5,
        "offset": 51
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 43
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
func $X(...) {
    ...
}

```

Target:

```text
package Foo

// ERROR:
func foo() {
    foo (1,2)
}

// ERROR:
func bar(bar1, bar2, bar3) {
    return 1
}

// ERROR:
func foobar(bar1) int {
    bar(1, 2, 3)
    foo()
    return 2
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/metavar_func_def.go",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 6,
        "offset": 51
      },
      "start": {
        "col": 1,
        "line": 4,
        "offset": 23
      }
    },
    {
      "end": {
        "col": 2,
        "line": 11,
        "offset": 106
      },
      "start": {
        "col": 1,
        "line": 9,
        "offset": 63
      }
    },
    {
      "end": {
        "col": 2,
        "line": 18,
        "offset": 183
      },
      "start": {
        "col": 1,
        "line": 14,
        "offset": 118
      }
    }
  ],
  "pattern_path": "go/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.go",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
config{..., $KEY:$VALUE, ...}

```

Target:

```text
package Foo 

func foo() {
    // ERROR:
    foo = config {
        key: value,
        key2: value2,
        key3: value3
    }

    bar = config2 {
        key: value,
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/metavar_key_value.go",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 9,
        "offset": 128
      },
      "start": {
        "col": 11,
        "line": 5,
        "offset": 51
      }
    }
  ],
  "pattern_path": "go/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y) {
   $S;
}
```

Target:

```text
package Foo

func bar() {
	var a = 1
	var b = 2
	var c = 3
	//ERROR:
	if a > b {
		c = 0
	}
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/metavar_stmt.go",
  "highlights": [
    {
      "end": {
        "col": 3,
        "line": 10,
        "offset": 91
      },
      "start": {
        "col": 2,
        "line": 8,
        "offset": 70
      }
    }
  ],
  "pattern_path": "go/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.go",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
$X == ($Y : string)
```

Target:

```text
package Foo

func main() {
    var x string
    var y string
    var a int
    var b int
    //ERROR:
    if x == y {
       x = y
    }
    if a == b {
       a = b
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/metavar_typed.go",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 9,
        "offset": 115
      },
      "start": {
        "col": 8,
        "line": 9,
        "offset": 109
      }
    }
  ],
  "pattern_path": "go/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.go",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
package Foo

func foo() {
	//ERROR: match
	var path = "/location/1"
	var d1 = "notamatch"
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/regexp_string.go",
  "highlights": [
    {
      "end": {
        "col": 26,
        "line": 5,
        "offset": 67
      },
      "start": {
        "col": 6,
        "line": 5,
        "offset": 47
      }
    }
  ],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
package Foo

func test_equal() {
    a = 1
    b = 2
    //ERROR: match
    if (a+b == a+b) {
        return 1
    }
    return 0
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/metavar_equality_expr.go",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 7,
        "offset": 90
      },
      "start": {
        "col": 9,
        "line": 7,
        "offset": 80
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if $E {
  $S;
} else {
  $S;
}

```

Target:

```text
package main

import "fmt"

func main() {
	//ERROR:
	if x > 2 {
		fmt.Println("hello world")
	} else {
		fmt.Println("hello world")
	}

	if x > 2 {
		fmt.Println("hello world")
	} else {
		fmt.Println("goodbye world")
	}
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/metavar_equality_stmt.go",
  "highlights": [
    {
      "end": {
        "col": 3,
        "line": 11,
        "offset": 134
      },
      "start": {
        "col": 2,
        "line": 7,
        "offset": 53
      }
    }
  ],
  "pattern_path": "go/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
package Foo

func foo() {
   //ERROR:
    myfile = open()
    close(myfile)
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/metavar_equality_var.go",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 6,
        "offset": 75
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 42
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
package Foo

func bar() {
    //ERROR:
    foo(1,2,3,4,5)
    //ERROR:
    foo(5)
}




```

Match coordinates and source paths:

```json
{
  "code_path": "go/dots_args.go",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 5,
        "offset": 57
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 43
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 81
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 75
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
func foo() {
    
  //ERROR: match
  f = o.foo().m().h().bar().z()

  //ERROR: match
  f = o.foo().bar()

  // this one does not contain the bar()
  f = o.foo().m().h().z()

  //ERROR: match $O can match o.before()
  f = o.before().foo().m().h().bar().z()

}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/dots_method_chaining.go",
  "highlights": [
    {
      "end": {
        "col": 32,
        "line": 4,
        "offset": 66
      },
      "start": {
        "col": 3,
        "line": 4,
        "offset": 37
      }
    },
    {
      "end": {
        "col": 20,
        "line": 7,
        "offset": 104
      },
      "start": {
        "col": 3,
        "line": 7,
        "offset": 87
      }
    },
    {
      "end": {
        "col": 41,
        "line": 13,
        "offset": 255
      },
      "start": {
        "col": 3,
        "line": 13,
        "offset": 217
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if $E {
  ...
}
```

Target:

```text
package foo

func foo() {
     //ERROR: match
     if 1 {
        return 1
     }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/dots_nested_stmts.go",
  "highlights": [
    {
      "end": {
        "col": 7,
        "line": 7,
        "offset": 81
      },
      "start": {
        "col": 6,
        "line": 5,
        "offset": 51
      }
    }
  ],
  "pattern_path": "go/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$X = get()
...
eval($X)
```

Target:

```text
package Foo

func foo() {
    //ERROR:
    user_data = get()
    print("do stuff")
    foobar()
    eval(user_data)
    foobar()
}

```

Match coordinates and source paths:

```json
{
  "code_path": "go/dots_stmts.go",
  "highlights": [
    {
      "end": {
        "col": 20,
        "line": 8,
        "offset": 115
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 43
      }
    }
  ],
  "pattern_path": "go/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
package Foo

func bar () {
    //ERROR:
    foo("whatever sequence of chars")
}


```

Match coordinates and source paths:

```json
{
  "code_path": "go/dots_string.go",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 5,
        "offset": 77
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 44
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## hack

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
//ERROR:
foo($bar + 42);

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/deep_expr_operator.hack",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 2,
        "offset": 23
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
class Foo
{
    public function foo()
    {
        //ERROR: match
        foo();
        bar();
        //ERROR: match
        foo();
        $x = bar();
        //ERROR: match
        foo();
        foo2(bar());
        //ERROR: match
        foo();
        return bar();
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/deep_exprstmt.hack",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 7,
        "offset": 96
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 75
      }
    },
    {
      "end": {
        "col": 20,
        "line": 10,
        "offset": 154
      },
      "start": {
        "col": 9,
        "line": 9,
        "offset": 128
      }
    },
    {
      "end": {
        "col": 21,
        "line": 13,
        "offset": 213
      },
      "start": {
        "col": 9,
        "line": 12,
        "offset": 186
      }
    },
    {
      "end": {
        "col": 22,
        "line": 16,
        "offset": 273
      },
      "start": {
        "col": 9,
        "line": 15,
        "offset": 245
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
function foo()
{
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(1,
        2);

    //ERROR:
    foo (1, // comment
        2);

    foo (2,1);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/concrete_syntax.hack",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 4,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 11,
        "line": 8,
        "offset": 79
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 62
      }
    },
    {
      "end": {
        "col": 11,
        "line": 12,
        "offset": 128
      },
      "start": {
        "col": 5,
        "line": 11,
        "offset": 99
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.hack",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.hack",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.hack",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
function foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(a_very_long_constant_name,
        2);

    //ERROR:
    foo (unsafe(), //comment
         2);

    //ERROR:
    foo(bar(1,3),  2);

    foo(2,1);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/metavar_arg.hack",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 103
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 62
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 159
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 123
      }
    },
    {
      "end": {
        "col": 22,
        "line": 14,
        "offset": 196
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 179
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
//ERROR:
class Foo
{
    public function member()
    {
        echo 'Member function';
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/metavar_class_def.hack",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 8,
        "offset": 95
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E) {
   foo();
}

```

Target:

```text
function foo() {
    $x = 1;
    //ERROR:
    if ($x > 2) {
        foo();
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/metavar_cond.hack",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 6,
        "offset": 80
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 46
      }
    }
  ],
  "pattern_path": "hack/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
function foo() {
    //ERROR:
    foo(1,2);

    return 1;
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/metavar_call.hack",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
//ERROR:
function foo()
{
    return 'This is a function';
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/metavar_func_def.hack",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 5,
        "offset": 60
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
require $A;
include $B;
require_once $C;
include_once $D;

```

Target:

```text
// ERROR:
require "a.hack";
include($dir.'/import.hack');
require_once('blah');
include_once "d.hack";

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/metavar_import.hack",
  "highlights": [
    {
      "end": {
        "col": 23,
        "line": 5,
        "offset": 102
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 10
      }
    }
  ],
  "pattern_path": "hack/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.hack",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
function foo() {
    $v = 1;
    //ERROR:
    if ($v > 2)
        return 1;
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/metavar_stmt.hack",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 5,
        "offset": 75
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 46
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.hack",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.hack",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.hack",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.hack",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
function foo() {
    $a = 1;
    $b = 2;
    //ERROR:
    if ($a + $b == $a + $b) {
        return 1;
    }
    return 0;
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/metavar_equality_expr.hack",
  "highlights": [
    {
      "end": {
        "col": 27,
        "line": 5,
        "offset": 80
      },
      "start": {
        "col": 9,
        "line": 5,
        "offset": 62
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
function foo() {
    //ERROR:
    if ($x > 2) {
        foo();
        bar();
    } else {
        foo();
        bar();
    }

    if ($x > 2) {
        foo();
        bar();
    }
    else {
        foo();
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/metavar_equality_stmt.hack",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 9,
        "offset": 126
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
function foo() {
    //ERROR:
    $myfile = open();
    close($myfile);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/metavar_equality_var.hack",
  "highlights": [
    {
      "end": {
        "col": 20,
        "line": 4,
        "offset": 71
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
function foo() {
    //ERROR:
    foo(1,2,3,4,5);
    //ERROR:
    foo(5);

    $fun = 5;
    //ERROR: 
    foo($test, $fun);

    foo($not_this);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/dots_args.hack",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 3,
        "offset": 48
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 73
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 67
      }
    },
    {
      "end": {
        "col": 21,
        "line": 9,
        "offset": 124
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 108
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$var->{...}->test_made();

```

Target:

```text
// ERROR:
$var->test1()->test2()->test3()->test_made();

// ERROR:
$var->test1()->test_made();

$eof = <<<EOF
// ERROR:
{$var->$var->test1()->test_made()}
EOF;

$eof = <<<EOF
// TODO: This should be a valid match but is not.
{$var->test1()->test_made()}
EOF;

//ERROR: match, ellipsis can also match 0 elts
$var->test_made();

// ERROR:
$var->test->test_made();

$test->test1()->test_made();

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/dots_method_chaining.hack",
  "highlights": [
    {
      "end": {
        "col": 45,
        "line": 2,
        "offset": 54
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 10
      }
    },
    {
      "end": {
        "col": 27,
        "line": 5,
        "offset": 93
      },
      "start": {
        "col": 1,
        "line": 5,
        "offset": 67
      }
    },
    {
      "end": {
        "col": 34,
        "line": 9,
        "offset": 153
      },
      "start": {
        "col": 8,
        "line": 9,
        "offset": 127
      }
    },
    {
      "end": {
        "col": 18,
        "line": 18,
        "offset": 324
      },
      "start": {
        "col": 1,
        "line": 18,
        "offset": 307
      }
    },
    {
      "end": {
        "col": 24,
        "line": 21,
        "offset": 360
      },
      "start": {
        "col": 1,
        "line": 21,
        "offset": 337
      }
    }
  ],
  "pattern_path": "hack/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...) {
    ...
} else {
    ...
}

```

Target:

```text
function foo()
{
    $var = 10;
    
    if ($var === 42) {
        echo('matched');
    }

    //ERROR:
    if ($var === 42) {
        echo('matched');
    } else {
        echo('not matched');
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/dots_nested_stmts.hack",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 14,
        "offset": 200
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 109
      }
    }
  ],
  "pattern_path": "hack/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
function foo() {
    //ERROR:
    $user_data = get();
    print("do stuff");
    foobar();
    eval($user_data);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/dots_stmts.hack",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 6,
        "offset": 112
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
function foo() {
    //ERROR:
    foo("whatever sequence of chars");
}

```

Match coordinates and source paths:

```json
{
  "code_path": "hack/dots_string.hack",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## hcl

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/concrete_syntax.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
"data-science"

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.hcl",
  "highlights": [],
  "pattern_path": "hcl/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_call.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
resource "..." "..." {

$V = open()
...
$RES = close($V)

}
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_var.hcl",
  "highlights": [],
  "pattern_path": "hcl/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_args.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_string.hcl",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## html

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/concrete_syntax.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_call.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_var.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_args.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_string.html",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## java

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
class Foo {
    void bar() {
        int baz = 0;
        //ERROR: match
        foo(baz + 42);
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "java/deep_expr_operator.java",
  "highlights": [
    {
      "end": {
        "col": 23,
        "line": 5,
        "offset": 95
      },
      "start": {
        "col": 9,
        "line": 5,
        "offset": 81
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
class Foo {
    void foo() {
        //ERROR: match
        foo();
        bar();
        //ERROR: match
        foo();
        x = bar();
        //ERROR: match
        foo();
        foo2(bar());
        //ERROR: match
        foo();
        return bar();
      }
  }
      

```

Match coordinates and source paths:

```json
{
  "code_path": "java/deep_exprstmt.java",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 5,
        "offset": 81
      },
      "start": {
        "col": 9,
        "line": 4,
        "offset": 60
      }
    },
    {
      "end": {
        "col": 19,
        "line": 8,
        "offset": 138
      },
      "start": {
        "col": 9,
        "line": 7,
        "offset": 113
      }
    },
    {
      "end": {
        "col": 21,
        "line": 11,
        "offset": 197
      },
      "start": {
        "col": 9,
        "line": 10,
        "offset": 170
      }
    },
    {
      "end": {
        "col": 21,
        "line": 14,
        "offset": 256
      },
      "start": {
        "col": 9,
        "line": 13,
        "offset": 229
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
class Foo {
    void foo() {
        //ERROR:
        foo(1,2);

        //ERROR:
        foo(1,
            2);

        //ERROR:
        foo (1, // comment
             2);

        foo(2,1);
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "java/concrete_syntax.java",
  "highlights": [
    {
      "end": {
        "col": 17,
        "line": 4,
        "offset": 62
      },
      "start": {
        "col": 9,
        "line": 4,
        "offset": 54
      }
    },
    {
      "end": {
        "col": 15,
        "line": 8,
        "offset": 111
      },
      "start": {
        "col": 9,
        "line": 7,
        "offset": 90
      }
    },
    {
      "end": {
        "col": 16,
        "line": 12,
        "offset": 173
      },
      "start": {
        "col": 9,
        "line": 11,
        "offset": 139
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
foo("password")
```

Target:

```text
class Foo {
	final String pwd = "password";	
 	void main()	{
        //ERROR: match
		foo(pwd);
	}

    void diff_word() {
        foo("hello");
    }
    void diff_func() {
        bar("password");
    }

    void same_const() {
        //ERROR: match
        foo("password");
    }

    void all_diff() {
        bar("hello");
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "java/equivalence_constant_propagation.java",
  "highlights": [
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 94
      },
      "start": {
        "col": 3,
        "line": 5,
        "offset": 86
      }
    },
    {
      "end": {
        "col": 24,
        "line": 17,
        "offset": 276
      },
      "start": {
        "col": 9,
        "line": 17,
        "offset": 261
      }
    }
  ],
  "pattern_path": "java/equivalence_constant_propagation.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
// ERROR:
@AnnoFoo
class Foo {
    int foo = 1;
}

// ERROR:
@Anno1
@Anno2
class FooBar {
    int foobar = 2;
}

@AnnoBar(bar = "bar")
class Bar {
    int bar = 1;
}

class NoAnno {
    int noanno = 2;
}

```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_anno.java",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 5,
        "offset": 49
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 10
      }
    },
    {
      "end": {
        "col": 2,
        "line": 12,
        "offset": 111
      },
      "start": {
        "col": 1,
        "line": 8,
        "offset": 61
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
class Foo {
  void bar() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(a_very_long_constant_name,
        2);

    //ERROR:
    foo (unsafe(), // indeed
         2);

    //ERROR:
    foo(bar(1,3), 2);

    foo(2,1);
  }
}


```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_arg.java",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 4,
        "offset": 52
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 44
      }
    },
    {
      "end": {
        "col": 11,
        "line": 8,
        "offset": 113
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 72
      }
    },
    {
      "end": {
        "col": 12,
        "line": 12,
        "offset": 169
      },
      "start": {
        "col": 5,
        "line": 11,
        "offset": 133
      }
    },
    {
      "end": {
        "col": 21,
        "line": 15,
        "offset": 205
      },
      "start": {
        "col": 5,
        "line": 15,
        "offset": 189
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
// ERROR:
public class Foo {
    int foo = 5;

    public static void foo() {
        int foo1 = 4;
    }
}

// ERROR:
private class Bar extends Foo {
    int bar = 3;
}

// ERROR:
abstract class Foobar {
    public abstract void foobar();
}


```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_class_def.java",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 8,
        "offset": 107
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 10
      }
    },
    {
      "end": {
        "col": 2,
        "line": 13,
        "offset": 169
      },
      "start": {
        "col": 1,
        "line": 11,
        "offset": 119
      }
    },
    {
      "end": {
        "col": 2,
        "line": 18,
        "offset": 241
      },
      "start": {
        "col": 1,
        "line": 16,
        "offset": 181
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
class Foo {
void foo() {
    x = 1;
    //ERROR:
    if (x > 2)
        foo();
}

}
```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_cond.java",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 6,
        "offset": 78
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 53
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
class Foo {
void foo() {
    //ERROR:
    foo(1,2);

    return 1;
}
}



```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_call.java",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 4,
        "offset": 50
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 42
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
void $X(...) {
    ...
}

```

Target:

```text
class Foo {
    // ERROR:
    void foo() {
        foo(1,2);
    }

    // ERROR:
    public static void bar(int bar1, int bar2, int bar3) {
        foo(1,2,3);
        bar(1,2);
    } 

    // ERROR:
    public void foobar(int bar1) {
        foo();
    }

    public static String str() {
        return "hello";
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_func_def.java",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 5,
        "offset": 66
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    },
    {
      "end": {
        "col": 6,
        "line": 11,
        "offset": 184
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 86
      }
    },
    {
      "end": {
        "col": 6,
        "line": 16,
        "offset": 256
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 205
      }
    }
  ],
  "pattern_path": "java/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
import java.util.$X;
```

Target:

```text
//ERROR: match
import java.util.ArrayList;
//ERROR: match
import java.util.List;

class Foo {

}
```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_import.java",
  "highlights": [
    {
      "end": {
        "col": 27,
        "line": 2,
        "offset": 41
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 15
      }
    },
    {
      "end": {
        "col": 22,
        "line": 4,
        "offset": 79
      },
      "start": {
        "col": 1,
        "line": 4,
        "offset": 58
      }
    }
  ],
  "pattern_path": "java/metavar_import.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
class Foo {
void foo() {
    v = 1;
    //ERROR:
    if (v > 2)
        return 1;
}
}



```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_stmt.java",
  "highlights": [
    {
      "end": {
        "col": 17,
        "line": 6,
        "offset": 80
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 53
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.java",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
$X == (String $Y)

```

Target:

```text
public class Foo {
    public static void main() {
        String x;
        String y;
        int a;
        int b;
        //ERROR: match
        if (x == y) x = y;
        if (a == b) a = b;
   }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_typed.java",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 8,
        "offset": 158
      },
      "start": {
        "col": 13,
        "line": 8,
        "offset": 152
      }
    }
  ],
  "pattern_path": "java/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.java",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
class Foo {
    void foo() {
        //ERROR: match
        path = "/location/1";
    }
}
```

Match coordinates and source paths:

```json
{
  "code_path": "java/regexp_string.java",
  "highlights": [
    {
      "end": {
        "col": 29,
        "line": 4,
        "offset": 80
      },
      "start": {
        "col": 9,
        "line": 4,
        "offset": 60
      }
    }
  ],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
class Foo {
void test_equal() {
    a = 1;
    b = 2;
    //ERROR: match
    if (a+b == a+b)
        return 1;
    return 0;
}

}

```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_equality_expr.java",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 6,
        "offset": 91
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 81
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
class foo {

void foo() {
    //ERROR:
    if (x > 2) {
        foo();
        bar();
    } else {
        foo();
        bar();
    }

    if (x > 2) {
        foo();
        bar();
    } else {
        foo();
    }
}


}
```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_equality_stmt.java",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 11,
        "offset": 134
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 43
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
class Foo {
void foo() {
   //ERROR:
    myfile = open();
    close(myfile);
}
}





```

Match coordinates and source paths:

```json
{
  "code_path": "java/metavar_equality_var.java",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 5,
        "offset": 76
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 41
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
class Foo {
  void bar() {
    //ERROR:
    foo(1,2,3,4,5);
    //ERROR:
    foo(5);
  }
}



```

Match coordinates and source paths:

```json
{
  "code_path": "java/dots_args.java",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 58
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 44
      }
    },
    {
      "end": {
        "col": 11,
        "line": 6,
        "offset": 83
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 77
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
class Foo {

  void test() {

    //ERROR: match
    f = this.foo().m().h().bar().z();

    //ERROR: match
    f = this.foo().bar();

    f = this.foo().m().h().z();

    //ERROR: match $O can match o.before()
    f = this.before().foo().m().h().bar().z();
  }
}


```

Match coordinates and source paths:

```json
{
  "code_path": "java/dots_method_chaining.java",
  "highlights": [
    {
      "end": {
        "col": 37,
        "line": 6,
        "offset": 85
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 53
      }
    },
    {
      "end": {
        "col": 25,
        "line": 9,
        "offset": 131
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 111
      }
    },
    {
      "end": {
        "col": 46,
        "line": 14,
        "offset": 255
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 214
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
class Foo {
  void main() {

    //ERROR: match
    if (x == 1) 
        return 2; 
  }
}


```

Match coordinates and source paths:

```json
{
  "code_path": "java/dots_nested_stmts.java",
  "highlights": [
    {
      "end": {
        "col": 17,
        "line": 6,
        "offset": 81
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 52
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
class Foo {
void foo() {

    //ERROR:
    user_data = get();
    print("do stuff");
    foobar();
    eval(user_data);
}

}



```

Match coordinates and source paths:

```json
{
  "code_path": "java/dots_stmts.java",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 8,
        "offset": 119
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 43
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
class Foo { 
  void bar () {
    //ERROR:
    foo("whatever sequence of chars");
  }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "java/dots_string.java",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 4,
        "offset": 79
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 46
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## js

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
function bar() {
    baz = 0;
    //ERROR: match
    foo(baz + 42);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "js/deep_expr_operator.js",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 53
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
function foo() {
    //ERROR: match
    foo();
    bar();
    //ERROR: match
    foo();
    x = bar();
    //ERROR: match
    foo();
    print(bar());
    //ERROR: match
    foo();
    return bar();
}

```

Match coordinates and source paths:

```json
{
  "code_path": "js/deep_exprstmt.js",
  "highlights": [
    {
      "end": {
        "col": 11,
        "line": 4,
        "offset": 57
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 40
      }
    },
    {
      "end": {
        "col": 15,
        "line": 7,
        "offset": 102
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 81
      }
    },
    {
      "end": {
        "col": 18,
        "line": 10,
        "offset": 150
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 126
      }
    },
    {
      "end": {
        "col": 18,
        "line": 13,
        "offset": 198
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 174
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
function foo() {
 //ERROR:
    foo(1, 2);
 //ERROR:
    foo(1,2);
 //ERROR:
    foo (1, 2);
 //ERROR:
 foo(1,
     2);
 //ERROR:
 foo(1, // comment
     2);

 foo(2,1)
}



```

Match coordinates and source paths:

```json
{
  "code_path": "js/concrete_syntax.js",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 3,
        "offset": 40
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 31
      }
    },
    {
      "end": {
        "col": 13,
        "line": 5,
        "offset": 64
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 56
      }
    },
    {
      "end": {
        "col": 15,
        "line": 7,
        "offset": 90
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 80
      }
    },
    {
      "end": {
        "col": 8,
        "line": 10,
        "offset": 117
      },
      "start": {
        "col": 2,
        "line": 9,
        "offset": 103
      }
    },
    {
      "end": {
        "col": 8,
        "line": 13,
        "offset": 155
      },
      "start": {
        "col": 2,
        "line": 12,
        "offset": 130
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
const Bar = "password";

function foo() {
     //ERROR: match!
     password(Bar);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "js/equivalence_constant_propagation.js",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 5,
        "offset": 81
      },
      "start": {
        "col": 6,
        "line": 5,
        "offset": 68
      }
    }
  ],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.js",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
// ERROR:
@Anno1
class Foo {
    foo() {
        var foo = 1;
    }
}

// ERROR:
@Anno1()
@Anno2()
class FooBar {
    foo() {
        var foo = 2;
    }
}

@AnnoVar("Bar")
class Bar {
    bar() {
        var bar = 1;
    }
}

class NoAnno {
    noanno() {
        var no_anno = 1;
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_anno.js",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 7,
        "offset": 69
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 10
      }
    },
    {
      "end": {
        "col": 2,
        "line": 16,
        "offset": 154
      },
      "start": {
        "col": 1,
        "line": 10,
        "offset": 81
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
function foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(a_very_long_constant_name,
        2);

    //ERROR:
    foo (unsafe(), // indeed
         2);

    //ERROR:
    foo(bar(1,3), 2);

    foo(2,1);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_arg.js",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 103
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 62
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 159
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 123
      }
    },
    {
      "end": {
        "col": 21,
        "line": 14,
        "offset": 195
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 179
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
// ERROR:
class Foo {
    constructor(foo) {
        this.foo = foo;
    }

    get foo() {
        return this.foo;
    }
}

// ERROR:
class Bar extends Foo {
    constructor (bar) {
        this.bar = bar;
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_class_def.js",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 10,
        "offset": 124
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 10
      }
    },
    {
      "end": {
        "col": 2,
        "line": 17,
        "offset": 215
      },
      "start": {
        "col": 1,
        "line": 13,
        "offset": 136
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
function foo() {
    x = 1;
    //ERROR:
    if (x > 2)
        foo();
}


```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_cond.js",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 5,
        "offset": 70
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 45
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
function foo() {
    //ERROR:
    foo(1,2);

    return 1;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_call.js",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
// ERROR:
function foo() {
    foo(1,2);
}

// ERROR:
function bar(bar1, bar2, bar3) {
    foo(1,2);
    bar(1,2,3);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_func_def.js",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 4,
        "offset": 42
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 10
      }
    },
    {
      "end": {
        "col": 2,
        "line": 10,
        "offset": 118
      },
      "start": {
        "col": 1,
        "line": 7,
        "offset": 54
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
import $X from 'foo';

```

Target:

```text
//ERROR: match
import jwt from 'foo';
let a = jwt.sign({}, 'a');

```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_import.js",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 2,
        "offset": 36
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 15
      }
    }
  ],
  "pattern_path": "js/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
function foo() {
    // ERROR:
    var foo = {key: value, key2: value2, key3: value3};

    // ERROR:
    var bar = {foo: bar, foo2: bar2, foo3: bar3};
}

```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_key_value.js",
  "highlights": [
    {
      "end": {
        "col": 55,
        "line": 3,
        "offset": 85
      },
      "start": {
        "col": 15,
        "line": 3,
        "offset": 45
      }
    },
    {
      "end": {
        "col": 49,
        "line": 6,
        "offset": 150
      },
      "start": {
        "col": 15,
        "line": 6,
        "offset": 116
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
function foo() {
    v = 1;
    //ERROR:
    if (v > 2)
        return 1;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_stmt.js",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 5,
        "offset": 73
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 45
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.js",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
var $X = {"=~/[lL]ocation/": $Y};

```

Target:

```text
//ERROR: match
var x = {"Location": 1};

```

Match coordinates and source paths:

```json
{
  "code_path": "js/regexp_fieldname.js",
  "highlights": [
    {
      "end": {
        "col": 24,
        "line": 2,
        "offset": 38
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 15
      }
    }
  ],
  "pattern_path": "js/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
//ERROR: match
path = "/location/1";
```

Match coordinates and source paths:

```json
{
  "code_path": "js/regexp_string.js",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 2,
        "offset": 35
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 15
      }
    }
  ],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
function test_equal() {
    a = 1;
    b = 2;
    //ERROR: match
    if (a+b == a+b)
        return 1;
    return 0;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_equality_expr.js",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 5,
        "offset": 83
      },
      "start": {
        "col": 9,
        "line": 5,
        "offset": 73
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
function foo() {
    //ERROR:
    if (x > 2) {
        foo();
        bar();
    } else {
        foo();
        bar();
    }

    if (x > 2) {
        foo();
        bar();
    } else {
        foo();
    }
}




```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_equality_stmt.js",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 9,
        "offset": 125
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
function foo() {
  //ERROR:
    myfile = open();
    close(myfile);
}




```

Match coordinates and source paths:

```json
{
  "code_path": "js/metavar_equality_var.js",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
function foo() {
  //ERROR:
    foo(1,2,3,4,5);
  //ERROR:
    foo(5);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "js/dots_args.js",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 3,
        "offset": 46
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 69
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 63
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
//ERROR: match
f = o.foo().m().h().bar().z();

//ERROR: match
f = o.foo().bar();

f = o.foo().m().h().z();

//ERROR: match $O can match o.before()
f = o.before().foo().m().h().bar().z();

```

Match coordinates and source paths:

```json
{
  "code_path": "js/dots_method_chaining.js",
  "highlights": [
    {
      "end": {
        "col": 30,
        "line": 2,
        "offset": 44
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 15
      }
    },
    {
      "end": {
        "col": 18,
        "line": 5,
        "offset": 79
      },
      "start": {
        "col": 1,
        "line": 5,
        "offset": 62
      }
    },
    {
      "end": {
        "col": 39,
        "line": 10,
        "offset": 185
      },
      "start": {
        "col": 1,
        "line": 10,
        "offset": 147
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
function foo() {

    //ERROR: match
    if (x == 1) 
        return 2;
}

```

Match coordinates and source paths:

```json
{
  "code_path": "js/dots_nested_stmts.js",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 5,
        "offset": 71
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 41
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
function foo() {

    //ERROR:
    user_data = get();
    print("do stuff");
    foobar();
    eval(user_data);
}



```

Match coordinates and source paths:

```json
{
  "code_path": "js/dots_stmts.js",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 7,
        "offset": 111
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 35
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
function foo() {
    //ERROR:
    foo("whatever sequence of chars");
    //ERROR:
    foo('whatever sequence of chars');
}


```

Match coordinates and source paths:

```json
{
  "code_path": "js/dots_string.js",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 38,
        "line": 5,
        "offset": 119
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 86
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## json

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/concrete_syntax.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_call.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_var.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_args.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_string.json",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## julia

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/concrete_syntax.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_call.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_var.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_args.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_string.julia",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## kotlin

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo()
bar()

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.kotlin",
  "highlights": [],
  "pattern_path": "kotlin/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/concrete_syntax.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
    foo()

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.kotlin",
  "highlights": [],
  "pattern_path": "kotlin/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_call.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
fun $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.kotlin",
  "highlights": [],
  "pattern_path": "kotlin/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
import java.util.$X

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.kotlin",
  "highlights": [],
  "pattern_path": "kotlin/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
    $S

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.kotlin",
  "highlights": [],
  "pattern_path": "kotlin/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S
else $S

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.kotlin",
  "highlights": [],
  "pattern_path": "kotlin/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
val $V = open()
close($V)


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_var.kotlin",
  "highlights": [],
  "pattern_path": "kotlin/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_args.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
val $V = get()
...
eval($V)

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.kotlin",
  "highlights": [],
  "pattern_path": "kotlin/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_string.kotlin",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## lua

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
function foo()
    --ERROR: match
    foo()
    bar()
    --ERROR: match
    foo()
    x = bar()
    --ERROR: match
    foo()
    print(bar())
    --ERROR: match
    foo()
    return bar()
end

```

Match coordinates and source paths:

```json
{
  "code_path": "lua/deep_exprstmt.lua",
  "highlights": [
    {
      "end": {
        "col": 10,
        "line": 4,
        "offset": 53
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 38
      }
    },
    {
      "end": {
        "col": 14,
        "line": 7,
        "offset": 96
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 77
      }
    },
    {
      "end": {
        "col": 17,
        "line": 10,
        "offset": 142
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 120
      }
    },
    {
      "end": {
        "col": 17,
        "line": 13,
        "offset": 188
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 166
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
function foo()
 --ERROR:
    foo(1,2)

 --ERROR:
 foo(1,
     2)

 --ERROR:
 foo (1, -- comment
      2)

 foo(2,1)
end

```

Match coordinates and source paths:

```json
{
  "code_path": "lua/concrete_syntax.lua",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 37
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 29
      }
    },
    {
      "end": {
        "col": 8,
        "line": 7,
        "offset": 64
      },
      "start": {
        "col": 2,
        "line": 6,
        "offset": 50
      }
    },
    {
      "end": {
        "col": 9,
        "line": 11,
        "offset": 104
      },
      "start": {
        "col": 2,
        "line": 10,
        "offset": 77
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
function foo()
    --ERROR:
    foo(1,2)

    --ERROR:
    foo(a_very_long_constant_name,
        2)

    --ERROR:
    foo (unsafe(), -- indeed
         2)

    --ERROR:
    foo(bar(1,3), 2)

    foo(2,1)
end


```

Match coordinates and source paths:

```json
{
  "code_path": "lua/metavar_arg.lua",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 40
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 100
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 59
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 155
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 119
      }
    },
    {
      "end": {
        "col": 21,
        "line": 14,
        "offset": 190
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 174
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
function foo()
    --ERROR:
    foo(1,2)

    return 1
end



```

Match coordinates and source paths:

```json
{
  "code_path": "lua/metavar_call.lua",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 40
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
function foo()
  --ERROR:
    myfile = open()
    close(myfile)
end





```

Match coordinates and source paths:

```json
{
  "code_path": "lua/metavar_equality_var.lua",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 4,
        "offset": 63
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
function foo()
  --ERROR:
    foo(1,2,3,4,5)
  --ERROR:
    foo(5)
end



```

Match coordinates and source paths:

```json
{
  "code_path": "lua/dots_args.lua",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 3,
        "offset": 44
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 66
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 60
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.lua",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...) then
  ...
end



```

Target:

```text
function foo()

    --ERROR: match
    if (x == 1) then
        return 2
    end
end


```

Match coordinates and source paths:

```json
{
  "code_path": "lua/dots_nested_stmts.lua",
  "highlights": [
    {
      "end": {
        "col": 17,
        "line": 5,
        "offset": 72
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 39
      }
    }
  ],
  "pattern_path": "lua/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get()
...
eval($V)



```

Target:

```text
function foo()

    --ERROR:
    user_data = get()
    print("do stuff")
    foobar()
    eval(user_data)
end

```

Match coordinates and source paths:

```json
{
  "code_path": "lua/dots_stmts.lua",
  "highlights": [
    {
      "end": {
        "col": 20,
        "line": 7,
        "offset": 105
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 33
      }
    }
  ],
  "pattern_path": "lua/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
function foo()
    --ERROR:
    foo("whatever sequence of chars")
    --ERROR:
    foo('whatever sequence of chars')
end
```

Match coordinates and source paths:

```json
{
  "code_path": "lua/dots_string.lua",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 65
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    },
    {
      "end": {
        "col": 38,
        "line": 5,
        "offset": 116
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 83
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## ocaml

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo 1 2

```

Target:

```text
(* ERROR: *)
let foo = foo 1 2

(* ERROR: *)
let foo1 = foo 1
               2

(* ERROR: *)
let foo2 = foo 1 (* comment *)
              2

let foo3 = foo 2 1

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/concrete_syntax.ml",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 2,
        "offset": 30
      },
      "start": {
        "col": 11,
        "line": 2,
        "offset": 23
      }
    },
    {
      "end": {
        "col": 17,
        "line": 6,
        "offset": 78
      },
      "start": {
        "col": 12,
        "line": 5,
        "offset": 56
      }
    },
    {
      "end": {
        "col": 16,
        "line": 10,
        "offset": 139
      },
      "start": {
        "col": 12,
        "line": 9,
        "offset": 104
      }
    }
  ],
  "pattern_path": "ocaml/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Argument

Pattern:

```text
foo $X 2

```

Target:

```text
(* ERROR: *)
let foo = foo 1 2

(* ERROR: *)
let foo1 = foo a_very_long_constant_name 2

(* ERROR: *)
let foo2 = foo unsafe (* indeed *) 2

(* ERROR: *)
let foo3 = foo (bar 1 3) 2

let foo4 = foo 2 1

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/metavar_arg.ml",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 2,
        "offset": 30
      },
      "start": {
        "col": 11,
        "line": 2,
        "offset": 23
      }
    },
    {
      "end": {
        "col": 43,
        "line": 5,
        "offset": 87
      },
      "start": {
        "col": 12,
        "line": 5,
        "offset": 56
      }
    },
    {
      "end": {
        "col": 37,
        "line": 8,
        "offset": 138
      },
      "start": {
        "col": 12,
        "line": 8,
        "offset": 113
      }
    },
    {
      "end": {
        "col": 27,
        "line": 11,
        "offset": 179
      },
      "start": {
        "col": 12,
        "line": 11,
        "offset": 164
      }
    }
  ],
  "pattern_path": "ocaml/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if $E then foo else $X

```

Target:

```text
let foo = 
  let x = 1 in
  (* ERROR: *)
  if x > 2 then foo else bar

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/metavar_cond.ml",
  "highlights": [
    {
      "end": {
        "col": 29,
        "line": 4,
        "offset": 69
      },
      "start": {
        "col": 3,
        "line": 4,
        "offset": 43
      }
    }
  ],
  "pattern_path": "ocaml/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F 1 2

```

Target:

```text
(* ERROR: *)
let foo = foo 1 2

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/metavar_call.ml",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 2,
        "offset": 30
      },
      "start": {
        "col": 11,
        "line": 2,
        "offset": 23
      }
    }
  ],
  "pattern_path": "ocaml/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
let $X ... = ...

```

Target:

```text
let foo = foo 1 2

(* ERROR: *)
let bar bar1 bar2 = bar 1 2

(* ERROR: *)
let rec foobar bar1 = foobar 1 2

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/metavar_func_def.ml",
  "highlights": [
    {
      "end": {
        "col": 28,
        "line": 4,
        "offset": 59
      },
      "start": {
        "col": 1,
        "line": 4,
        "offset": 32
      }
    },
    {
      "end": {
        "col": 33,
        "line": 7,
        "offset": 106
      },
      "start": {
        "col": 1,
        "line": 7,
        "offset": 74
      }
    }
  ],
  "pattern_path": "ocaml/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Statement

Pattern:

```text
if $X > $Y then $S else $M

```

Target:

```text
let foo = 
  let v = 1 in
  (* ERROR: *)
  if v > 2 then 1 else 2

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/metavar_stmt.ml",
  "highlights": [
    {
      "end": {
        "col": 25,
        "line": 4,
        "offset": 65
      },
      "start": {
        "col": 3,
        "line": 4,
        "offset": 43
      }
    }
  ],
  "pattern_path": "ocaml/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
let $X = "=~//[lL]ocation.*/"

```

Target:

```text
(* ERROR: *)
let foo = "/location/l"

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/regexp_string.ml",
  "highlights": [
    {
      "end": {
        "col": 24,
        "line": 2,
        "offset": 36
      },
      "start": {
        "col": 5,
        "line": 2,
        "offset": 17
      }
    }
  ],
  "pattern_path": "ocaml/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X = $X

```

Target:

```text
let foo = 
  let a = 1 in
  let b = 2 in
  (* ERROR: *)
  if a+b = a+b then 1 else 2

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/metavar_equality_expr.ml",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 5,
        "offset": 70
      },
      "start": {
        "col": 6,
        "line": 5,
        "offset": 61
      }
    }
  ],
  "pattern_path": "ocaml/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if $E then $S else $S

```

Target:

```text
let foo = 
  (* ERROR: *)
  if x > 2 then 
    foo
  else 
    foo

let foo2 = 
  if x > 2 then
    bar
  else 
    foo

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/metavar_equality_stmt.ml",
  "highlights": [
    {
      "end": {
        "col": 8,
        "line": 6,
        "offset": 66
      },
      "start": {
        "col": 3,
        "line": 3,
        "offset": 28
      }
    }
  ],
  "pattern_path": "ocaml/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
let $A = open_file "file" in
close $A

```

Target:

```text
let foo = 
  (* ERROR: *)
  let myfile = open_file "file" in
  close myfile

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/metavar_equality_var.ml",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 4,
        "offset": 75
      },
      "start": {
        "col": 7,
        "line": 3,
        "offset": 32
      }
    }
  ],
  "pattern_path": "ocaml/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo ... 5

```

Target:

```text
(* ERROR: *)
let foo = foo 1 2 3 4 5

(* ERROR: *)
let foo2 = foo 5




```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/dots_args.ml",
  "highlights": [
    {
      "end": {
        "col": 24,
        "line": 2,
        "offset": 36
      },
      "start": {
        "col": 11,
        "line": 2,
        "offset": 23
      }
    },
    {
      "end": {
        "col": 17,
        "line": 5,
        "offset": 67
      },
      "start": {
        "col": 12,
        "line": 5,
        "offset": 62
      }
    }
  ],
  "pattern_path": "ocaml/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if ... then ... else ...

```

Target:

```text
(* ERROR: *)
let foo = if x = 1 then 2 else 2

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/dots_nested_stmts.ml",
  "highlights": [
    {
      "end": {
        "col": 33,
        "line": 2,
        "offset": 45
      },
      "start": {
        "col": 11,
        "line": 2,
        "offset": 23
      }
    }
  ],
  "pattern_path": "ocaml/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.ml",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo "..."

```

Target:

```text
(* ERROR: *)
let bar = foo "whatever sequence of chars"

```

Match coordinates and source paths:

```json
{
  "code_path": "ocaml/dots_string.ml",
  "highlights": [
    {
      "end": {
        "col": 43,
        "line": 2,
        "offset": 55
      },
      "start": {
        "col": 11,
        "line": 2,
        "offset": 23
      }
    }
  ],
  "pattern_path": "ocaml/dots_string.sgrep"
}
```

## php

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
<?php

//ERROR: match
foo($bar + 42);

```

Match coordinates and source paths:

```json
{
  "code_path": "php/deep_expr_operator.php",
  "highlights": [
    {
      "end": {
        "col": 16,
        "line": 4,
        "offset": 37
      },
      "start": {
        "col": 1,
        "line": 4,
        "offset": 22
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
<?php

class Foo
{
    public function foo()
    {
        //ERROR: match
        foo();
        bar();
        //ERROR: match
        foo();
        $x = bar();
        //ERROR: match
        foo();
        foo2(bar());
        //ERROR: match
        foo();
        return bar();
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "php/deep_exprstmt.php",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 9,
        "offset": 103
      },
      "start": {
        "col": 9,
        "line": 8,
        "offset": 82
      }
    },
    {
      "end": {
        "col": 20,
        "line": 12,
        "offset": 161
      },
      "start": {
        "col": 9,
        "line": 11,
        "offset": 135
      }
    },
    {
      "end": {
        "col": 21,
        "line": 15,
        "offset": 220
      },
      "start": {
        "col": 9,
        "line": 14,
        "offset": 193
      }
    },
    {
      "end": {
        "col": 21,
        "line": 18,
        "offset": 279
      },
      "start": {
        "col": 9,
        "line": 17,
        "offset": 252
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
<?php
function foo()
{
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(1,
        2);

    //ERROR:
    foo (1, // comment
        2);

    foo (2,1);
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/concrete_syntax.php",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 5,
        "offset": 48
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 40
      }
    },
    {
      "end": {
        "col": 11,
        "line": 9,
        "offset": 85
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 68
      }
    },
    {
      "end": {
        "col": 11,
        "line": 13,
        "offset": 134
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 105
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
<?php

const glob1 = "password";

$glob2 = "password";
$glob2 = "bar";

function foo()
{
    // ERROR: match
    bar(glob1);

    bar($glob2);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "php/equivalence_constant_propagation.php",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 11,
        "offset": 123
      },
      "start": {
        "col": 5,
        "line": 11,
        "offset": 113
      }
    }
  ],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.php",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
#[$ATTR]
class $F { ... }

```

Target:

```text
<?php
// ERROR:
#[AnnoFoo]
class Foo {
}

// ERROR:
#[Anno1, Anno2]
class FooBar {
}

#[AnnoBar("bar")]
class Bar {
}

class NoAnno {
}

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_anno.php",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 5,
        "offset": 40
      },
      "start": {
        "col": 3,
        "line": 3,
        "offset": 18
      }
    },
    {
      "end": {
        "col": 2,
        "line": 10,
        "offset": 84
      },
      "start": {
        "col": 3,
        "line": 8,
        "offset": 54
      }
    }
  ],
  "pattern_path": "php/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
<?php
function foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(a_very_long_constant_name,
        2);

    //ERROR:
    foo (unsafe(), //comment
         2);

    //ERROR:
    foo(bar(1,3),  2);

    foo(2,1);
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_arg.php",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 4,
        "offset": 48
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 40
      }
    },
    {
      "end": {
        "col": 11,
        "line": 8,
        "offset": 109
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 68
      }
    },
    {
      "end": {
        "col": 12,
        "line": 12,
        "offset": 165
      },
      "start": {
        "col": 5,
        "line": 11,
        "offset": 129
      }
    },
    {
      "end": {
        "col": 22,
        "line": 15,
        "offset": 202
      },
      "start": {
        "col": 5,
        "line": 15,
        "offset": 185
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
<?php

# ERROR:
class Foo
{
    public function member()
    {
        echo 'Member function';
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_class_def.php",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 10,
        "offset": 102
      },
      "start": {
        "col": 1,
        "line": 4,
        "offset": 16
      }
    }
  ],
  "pattern_path": "php/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
<?php
function foo() {
    $x = 1;
    //ERROR:
    if ($x > 2) {
        foo();
    }
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_cond.php",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 7,
        "offset": 86
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 52
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
<?php
function foo() {
    //ERROR:
    foo(1,2);

    return 1;
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_call.php",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 4,
        "offset": 48
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 40
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
<?php

# ERROR:
function foo()
{
    return 'This is a function';
}

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_func_def.php",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 7,
        "offset": 67
      },
      "start": {
        "col": 1,
        "line": 4,
        "offset": 16
      }
    }
  ],
  "pattern_path": "php/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
require $A;
include $B;
require_once $C;
include_once $D;

```

Target:

```text
<?php

# ERROR:
require "a.php";
include "b.php";
require_once "c.php";
include_once "d.php";

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_import.php",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 7,
        "offset": 93
      },
      "start": {
        "col": 1,
        "line": 4,
        "offset": 16
      }
    }
  ],
  "pattern_path": "php/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.php",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
<?php
function foo() {
    $v = 1;
    //ERROR:
    if ($v > 2)
        return 1;
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_stmt.php",
  "highlights": [
    {
      "end": {
        "col": 17,
        "line": 6,
        "offset": 80
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 52
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.php",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.php",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.php",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
<?php
function foo() {
    //ERROR:
    $path = "/location/1";
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/regexp_string.php",
  "highlights": [
    {
      "end": {
        "col": 26,
        "line": 4,
        "offset": 61
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 40
      }
    }
  ],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
<?php
function foo() {
    $a = 1;
    $b = 2;
    //ERROR:
    if ($a+$b == $a+$b) {
        return 1;
    }
    return 0;
}

?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_equality_expr.php",
  "highlights": [
    {
      "end": {
        "col": 23,
        "line": 6,
        "offset": 82
      },
      "start": {
        "col": 9,
        "line": 6,
        "offset": 68
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
<?php
function foo() {
    //ERROR:
    if ($x > 2) {
        foo();
        bar();
    } else {
        foo();
        bar();
    }

    if ($x > 2) {
        foo();
        bar();
    }
    else {
        foo();
    }
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_equality_stmt.php",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 10,
        "offset": 132
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 40
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
<?php
function foo() {
    //ERROR:
    $myfile = open();
    close($myfile);
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/metavar_equality_var.php",
  "highlights": [
    {
      "end": {
        "col": 20,
        "line": 5,
        "offset": 77
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 40
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
<?php
function foo() {
  //ERROR:
    foo(1,2,3,4,5);
  //ERROR:
    foo(5);
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/dots_args.php",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 52
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 38
      }
    },
    {
      "end": {
        "col": 11,
        "line": 6,
        "offset": 75
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 69
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O->foo()-> ... ->bar()-> ...;


```

Target:

```text
<?php

function test() {

    //ERROR: match
    $f = this->foo()->m()->h()->bar()->z();

    //ERROR: match
    $f = this->foo()->bar();

    $f = this->foo()->m()->h()->z();

    //ERROR: match $O can match o.before()
    $f = this->before()->foo()->m()->h()->bar()->z();
}



```

Match coordinates and source paths:

```json
{
  "code_path": "php/dots_method_chaining.php",
  "highlights": [
    {
      "end": {
        "col": 44,
        "line": 6,
        "offset": 88
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 49
      }
    },
    {
      "end": {
        "col": 29,
        "line": 9,
        "offset": 137
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 113
      }
    },
    {
      "end": {
        "col": 54,
        "line": 14,
        "offset": 273
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 224
      }
    }
  ],
  "pattern_path": "php/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...) {
    ...
}

```

Target:

```text
<?php

function foo()
{
    $var = 10;

    //ERROR: match
    if ($var === 42) {
        echo('matched');
    }

    if ($var === 42) {
        echo('matched');
    } else {
        echo('not matched');
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "php/dots_nested_stmts.php",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 10,
        "offset": 112
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 63
      }
    }
  ],
  "pattern_path": "php/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
<?php
function foo() {
    //ERROR:
    $user_data = get();
    print("do stuff");
    foobar();
    eval($user_data);
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/dots_stmts.php",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 7,
        "offset": 118
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 40
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
<?php
function foo() {
    //ERROR:
    foo("whatever sequence of chars");
}
?>

```

Match coordinates and source paths:

```json
{
  "code_path": "php/dots_string.php",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 4,
        "offset": 73
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 40
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## python

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>)

```

Target:

```text
bar = 0
#ERROR: match
foo(bar + 42)

```

Match coordinates and source paths:

```json
{
  "code_path": "python/deep_expr_operator.py",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 3,
        "offset": 35
      },
      "start": {
        "col": 1,
        "line": 3,
        "offset": 22
      }
    }
  ],
  "pattern_path": "python/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo()
bar()
```

Target:

```text
def foo():
    # ERROR: match
    foo()
    bar()
    # ERROR: match
    foo()
    x = bar()
    # ERROR: match
    foo()
    foo2(bar())
    # ERROR: match
    foo()
    return bar()

```

Match coordinates and source paths:

```json
{
  "code_path": "python/deep_exprstmt.py",
  "highlights": [
    {
      "end": {
        "col": 10,
        "line": 4,
        "offset": 49
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 14,
        "line": 7,
        "offset": 92
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 73
      }
    },
    {
      "end": {
        "col": 16,
        "line": 10,
        "offset": 137
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 116
      }
    },
    {
      "end": {
        "col": 17,
        "line": 13,
        "offset": 183
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 161
      }
    }
  ],
  "pattern_path": "python/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
def foo():
    # ERROR:
    foo(1,2)

    # ERROR:
    foo(1, 
        2)

    # ERROR:
    foo(1,   # comment 
        2)

    foo(2, 1)

```

Match coordinates and source paths:

```json
{
  "code_path": "python/concrete_syntax.py",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 36
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 73
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 55
      }
    },
    {
      "end": {
        "col": 11,
        "line": 11,
        "offset": 122
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 92
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
bar("secret")
```

Target:

```text
CONST_GLOBAL = "secret"

# this is modifed somewhere, so not inferred as a constant
GLOBAL = "secret"

def foo():
    # ERROR: match
    bar(CONST_GLOBAL)


def bar():
    global GLOBAL
    GLOBAL="x"

```

Match coordinates and source paths:

```json
{
  "code_path": "python/equivalence_constant_propagation.py",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 8,
        "offset": 154
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 137
      }
    }
  ],
  "pattern_path": "python/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
subprocess.open(...)
```

Target:

```text
import subprocess.open
from subprocess import open as sub_open

import subprocess as sub


# TODO
# import os as subprocess


def foo():
    # ERROR:
    result = subprocess.open("ls")
    # ERROR:
    result = sub_open("ls")
    # ERROR:
    result = sub.open("ls")

    result = sub.not_open("ls")

```

Match coordinates and source paths:

```json
{
  "code_path": "python/equivalence_naming_import.py",
  "highlights": [
    {
      "end": {
        "col": 35,
        "line": 13,
        "offset": 184
      },
      "start": {
        "col": 14,
        "line": 13,
        "offset": 163
      }
    },
    {
      "end": {
        "col": 28,
        "line": 15,
        "offset": 225
      },
      "start": {
        "col": 14,
        "line": 15,
        "offset": 211
      }
    },
    {
      "end": {
        "col": 28,
        "line": 17,
        "offset": 266
      },
      "start": {
        "col": 14,
        "line": 17,
        "offset": 252
      }
    }
  ],
  "pattern_path": "python/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
def $FUNC(...):
    ...

```

Target:

```text
# ERROR:
@anno1
def bar(foo: 'foo'):
    x = 2

# ERROR:
@anno1
@anno2
def foobar():
    x = 3

@app.route('/foo')
def foo():
    x = 1

def no_anno():
    x = 2



```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_anno.py",
  "highlights": [
    {
      "end": {
        "col": 10,
        "line": 4,
        "offset": 46
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 10,
        "line": 10,
        "offset": 94
      },
      "start": {
        "col": 1,
        "line": 7,
        "offset": 57
      }
    }
  ],
  "pattern_path": "python/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
def foo():
    # ERROR:
    foo(1, 2)

    # ERROR:
    foo(a_very_long_constant_name, 2)

    # ERROR:
    foo(unsafe(), 2)  # indeed

    # ERROR:
    foo(bar(1, 3), 2)

    foo(2, 1)

```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_arg.py",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 3,
        "offset": 37
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    },
    {
      "end": {
        "col": 38,
        "line": 6,
        "offset": 89
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 56
      }
    },
    {
      "end": {
        "col": 21,
        "line": 9,
        "offset": 124
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 108
      }
    },
    {
      "end": {
        "col": 22,
        "line": 12,
        "offset": 170
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 153
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X:
    ...

```

Target:

```text
# ERROR:
class Foo:
    def foo ():
        foo (3)
# ERROR:
class Anything(Foo):
    def foos ():
        foo (4)

def foo(var):
    foo (3)



```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_class_def.py",
  "highlights": [
    {
      "end": {
        "col": 16,
        "line": 4,
        "offset": 51
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 16,
        "line": 8,
        "offset": 114
      },
      "start": {
        "col": 1,
        "line": 6,
        "offset": 61
      }
    }
  ],
  "pattern_path": "python/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if $E:
   foo()

```

Target:

```text
def foo():
    x = 1
    # ERROR:
    if x > 2:
        foo()

```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_cond.py",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 5,
        "offset": 61
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 38
      }
    }
  ],
  "pattern_path": "python/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
def foo():
    # ERROR:
    foo(1, 2)

    return 1

```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_call.py",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 3,
        "offset": 37
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
def $X(...):
    ...

```

Target:

```text
# ERROR:
def foo():
    foo(1,2)

# ERROR:
def bar(bar1, bar2, bar3):
    bar (1,2,3)

# ERROR:
def foobar(bar1) -> int:
    bar(1,2,3)
    foo()
    return 3

```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_func_def.py",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 32
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 16,
        "line": 7,
        "offset": 85
      },
      "start": {
        "col": 1,
        "line": 6,
        "offset": 43
      }
    },
    {
      "end": {
        "col": 13,
        "line": 13,
        "offset": 158
      },
      "start": {
        "col": 1,
        "line": 10,
        "offset": 96
      }
    }
  ],
  "pattern_path": "python/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
import foo.$BAR
```

Target:

```text
#ERROR: match
import foo.something
```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_import.py",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 2,
        "offset": 34
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 14
      }
    }
  ],
  "pattern_path": "python/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
def foo():
    # ERROR:
    thisdict = {
        key:value,
        key2:value2,
        key3:value3
    }

    # ERROR:
    foo = {
        foo:bar
    }

```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_key_value.py",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 7,
        "offset": 106
      },
      "start": {
        "col": 16,
        "line": 3,
        "offset": 39
      }
    },
    {
      "end": {
        "col": 6,
        "line": 12,
        "offset": 154
      },
      "start": {
        "col": 11,
        "line": 10,
        "offset": 131
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if var > 2:
   $S

```

Target:

```text
def foo():
    var = 1
    # ERROR:
    if var > 2:
        return 1

```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_stmt.py",
  "highlights": [
    {
      "end": {
        "col": 17,
        "line": 5,
        "offset": 68
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 40
      }
    }
  ],
  "pattern_path": "python/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.py",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.py",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
#ERROR: match
path = "/location/1";
```

Match coordinates and source paths:

```json
{
  "code_path": "python/regexp_string.py",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 2,
        "offset": 34
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 14
      }
    }
  ],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
def test_equal():
    a = 1
    b = 2
    # ERROR: match
    if a + b == a + b:
        return 1
    return 0

```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_equality_expr.py",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 5,
        "offset": 78
      },
      "start": {
        "col": 8,
        "line": 5,
        "offset": 64
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if $E:
  $S
else:
  $S

```

Target:

```text
def foo():
    # ERROR:
    if x > 2:
        foo()
        bar()
    else:
        foo()
        bar()

    if x > 2:
        foo()
        bar()
    else:
        foo()

```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_equality_stmt.py",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 8,
        "offset": 103
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    }
  ],
  "pattern_path": "python/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open()
close($V)

```

Target:

```text
def foo():
    # ERROR:
    myfile = open()
    close(myfile)

```

Match coordinates and source paths:

```json
{
  "code_path": "python/metavar_equality_var.py",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 4,
        "offset": 61
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    }
  ],
  "pattern_path": "python/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
def foo():
    # ERROR:
    foo(1, 2, 3, 4, 5)
    # ERROR:
    foo(5)

```

Match coordinates and source paths:

```json
{
  "code_path": "python/dots_args.py",
  "highlights": [
    {
      "end": {
        "col": 23,
        "line": 3,
        "offset": 46
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 70
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 64
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
def foo():
    
  #ERROR: match
  f = o.foo().m().h().bar().z()

  #ERROR: match
  f = o.foo().bar()

  # this one does not contain the bar()
  f = o.foo().m().h().z()

  #ERROR: match $O can match o.before()
  f = o.before().foo().m().h().bar().z()

```

Match coordinates and source paths:

```json
{
  "code_path": "python/dots_method_chaining.py",
  "highlights": [
    {
      "end": {
        "col": 32,
        "line": 4,
        "offset": 63
      },
      "start": {
        "col": 3,
        "line": 4,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 20,
        "line": 7,
        "offset": 100
      },
      "start": {
        "col": 3,
        "line": 7,
        "offset": 83
      }
    },
    {
      "end": {
        "col": 41,
        "line": 13,
        "offset": 249
      },
      "start": {
        "col": 3,
        "line": 13,
        "offset": 211
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...):
  ...


```

Target:

```text
def foo():
    #ERROR: match
    if (x == some_cond):
        print('matched')
    else:
        print('not matched')
    


```

Match coordinates and source paths:

```json
{
  "code_path": "python/dots_nested_stmts.py",
  "highlights": [
    {
      "end": {
        "col": 29,
        "line": 6,
        "offset": 117
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 33
      }
    }
  ],
  "pattern_path": "python/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get()
...
eval($V)

```

Target:

```text
def foo():

    # ERROR:
    user_data = get()
    print("do stuff")
    foobar()
    eval(user_data)

```

Match coordinates and source paths:

```json
{
  "code_path": "python/dots_stmts.py",
  "highlights": [
    {
      "end": {
        "col": 20,
        "line": 7,
        "offset": 101
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 29
      }
    }
  ],
  "pattern_path": "python/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
def foo():
    # ERROR:
    foo("whatever sequence of chars")
    # foo('whatever sequence of chars')

    # ERROR:
    foo(f'constant string')

    # this string is not a constant, and therefore will not be matched.
    foo(f'string {var} interpolation')

```

Match coordinates and source paths:

```json
{
  "code_path": "python/dots_string.py",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 61
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 28
      }
    },
    {
      "end": {
        "col": 28,
        "line": 7,
        "offset": 143
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 120
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## r

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
foo <- function () {
 --ERROR:
    foo(1,2)

 #ERROR:
 foo(1,
     2)

 #ERROR:
 foo (1, #comment
      2)

 foo(2,1)
}
```

Match coordinates and source paths:

```json
{
  "code_path": "r/concrete_syntax.r",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 43
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 35
      }
    },
    {
      "end": {
        "col": 8,
        "line": 7,
        "offset": 69
      },
      "start": {
        "col": 2,
        "line": 6,
        "offset": 55
      }
    },
    {
      "end": {
        "col": 9,
        "line": 11,
        "offset": 106
      },
      "start": {
        "col": 2,
        "line": 10,
        "offset": 81
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
foo <- function () {
    #ERROR:
    foo(1,2)

    #ERROR:
    foo(a_very_long_constant_name,
        2)

    #ERROR:
    foo (unsafe(), #indeed
         2)

    #ERROR:
    foo(bar(1,3), 2)

    foo(2,1)
}


```

Match coordinates and source paths:

```json
{
  "code_path": "r/metavar_arg.r",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 45
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 37
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 104
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 63
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 156
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 122
      }
    },
    {
      "end": {
        "col": 21,
        "line": 14,
        "offset": 190
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 174
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
foo <- function () {
    #ERROR:
    foo(1,2)

    return 1
}



```

Match coordinates and source paths:

```json
{
  "code_path": "r/metavar_call.r",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 45
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 37
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
foo <- function () {
  #ERROR:
    myfile = open()
    close(myfile)
}





```

Match coordinates and source paths:

```json
{
  "code_path": "r/metavar_equality_var.r",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 4,
        "offset": 68
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 35
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
foo <- function () {
  #ERROR:
    foo(1,2,3,4,5)
  #ERROR:
    foo(5)
}



```

Match coordinates and source paths:

```json
{
  "code_path": "r/dots_args.r",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 3,
        "offset": 49
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 35
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 70
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 64
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.r",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
foo <- function () {
    #ERROR: match
    if (x == 1) then
        return 2
    end
}


```

Match coordinates and source paths:

```json
{
  "code_path": "r/dots_nested_stmts.r",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 3,
        "offset": 59
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 43
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V <- get()
...
eval($V)


```

Target:

```text
foo <- function () {
    #ERROR:
    user_data <- get()
    print("do stuff")
    foobar()
    eval(user_data)
}

```

Match coordinates and source paths:

```json
{
  "code_path": "r/dots_stmts.r",
  "highlights": [
    {
      "end": {
        "col": 20,
        "line": 6,
        "offset": 110
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 37
      }
    }
  ],
  "pattern_path": "r/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
foo <- function() {
    #ERROR:
    foo("whatever sequence of chars")
    #ERROR:
    foo('whatever sequence of chars')
}
```

Match coordinates and source paths:

```json
{
  "code_path": "r/dots_string.r",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 69
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 36
      }
    },
    {
      "end": {
        "col": 38,
        "line": 5,
        "offset": 119
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 86
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## ruby

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>)

```

Target:

```text
def bar()
    baz = 0
    #ERROR: match
    foo(baz + 42)
    #ERROR: match
    foo(/hello #{world + 42}/)
end

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/deep_expr_operator.rb",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 4,
        "offset": 57
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 44
      }
    },
    {
      "end": {
        "col": 31,
        "line": 6,
        "offset": 106
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 80
      }
    }
  ],
  "pattern_path": "ruby/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo()
bar()
```

Target:

```text
def foo()
    #ERROR: match
    foo()
    bar()
    #ERROR: match
    foo()
    x = bar()
    #ERROR: match
    foo()
    print(bar())
    #ERROR: match
    foo()
    return bar()
end

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/deep_exprstmt.rb",
  "highlights": [
    {
      "end": {
        "col": 10,
        "line": 4,
        "offset": 47
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    },
    {
      "end": {
        "col": 14,
        "line": 7,
        "offset": 89
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 70
      }
    },
    {
      "end": {
        "col": 17,
        "line": 10,
        "offset": 134
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 112
      }
    },
    {
      "end": {
        "col": 17,
        "line": 13,
        "offset": 179
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 157
      }
    }
  ],
  "pattern_path": "ruby/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
def foo()
    # ERROR:
    foo(1,2)

    # ERROR:
    foo(1,
        2)

    # ERROR:
    foo(1, # comment 
        2)
 
    foo(2, 1)
end

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/concrete_syntax.rb",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 35
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 27
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 71
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 54
      }
    },
    {
      "end": {
        "col": 11,
        "line": 11,
        "offset": 118
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 90
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
PASSWORD = "password"
def foo()
    #ERROR: match
    func(PASSWORD)
end

# we even handle this case!
A=PASSWORD
def foo2()
    #ERROR: match
    func(A)
end

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/equivalence_constant_propagation.rb",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 68
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 54
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 153
      },
      "start": {
        "col": 5,
        "line": 11,
        "offset": 146
      }
    }
  ],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

### Named Placeholders ($X)

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
def foo()
    # ERROR:
    foo(1, 2)

    # ERROR:
    foo(a_very_long_constant_name, 2)

    # ERROR:
    foo(unsafe(), # indeed
        2)

    # ERROR:
    foo(bar(1, 3), 2)

    foo(2, 1)
end

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_arg.rb",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 3,
        "offset": 36
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 27
      }
    },
    {
      "end": {
        "col": 38,
        "line": 6,
        "offset": 88
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 55
      }
    },
    {
      "end": {
        "col": 11,
        "line": 10,
        "offset": 140
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 107
      }
    },
    {
      "end": {
        "col": 22,
        "line": 13,
        "offset": 176
      },
      "start": {
        "col": 5,
        "line": 13,
        "offset": 159
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X
    ...
end

```

Target:

```text
# ERROR:
class Foo
  def foo()
    foo(1,2)
  end 
end

# ERROR:
class Foo::Bar
end

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_class_def.rb",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 4,
        "offset": 43
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 15,
        "line": 9,
        "offset": 79
      },
      "start": {
        "col": 1,
        "line": 9,
        "offset": 65
      }
    }
  ],
  "pattern_path": "ruby/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if $E
   foo()
end

```

Target:

```text
def foo()
    x = 1
    # ERROR:
    if x > 2
        foo()
    end
end


```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_cond.rb",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 5,
        "offset": 59
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 37
      }
    }
  ],
  "pattern_path": "ruby/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
def foo()
    # ERROR:
    foo(1, 2)

    return 1
end


```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_call.rb",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 3,
        "offset": 36
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 27
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
def $X(...)
    ...
end

```

Target:

```text
# ERROR:
def foo()
  foo(1,2)
end

# ERROR:
def bar(bar1, bar2, bar3)
  foo(1,2)
  bar(1,2,3)
end


```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_func_def.rb",
  "highlights": [
    {
      "end": {
        "col": 11,
        "line": 3,
        "offset": 29
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    },
    {
      "end": {
        "col": 13,
        "line": 9,
        "offset": 93
      },
      "start": {
        "col": 1,
        "line": 7,
        "offset": 44
      }
    }
  ],
  "pattern_path": "ruby/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
require $R

```

Target:

```text
#ERROR: match
require 'foo'

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_import.rb",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 2,
        "offset": 27
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 14
      }
    }
  ],
  "pattern_path": "ruby/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
#ERROR: match
options = { key1: 41, key2: 42, key3: 43 }
options[:key2]  # => 42

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_key_value.rb",
  "highlights": [
    {
      "end": {
        "col": 43,
        "line": 2,
        "offset": 56
      },
      "start": {
        "col": 11,
        "line": 2,
        "offset": 24
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if $X > $Y
   $S
end


```

Target:

```text
def foo()
    var = 1
    # ERROR:
    if var > 2
        return 1
    end
end


```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_stmt.rb",
  "highlights": [
    {
      "end": {
        "col": 17,
        "line": 5,
        "offset": 66
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 39
      }
    }
  ],
  "pattern_path": "ruby/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.rb",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.rb",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~/\/[lL]ocation.*/"
```

Target:

```text
# ERROR:
path = "/location/1"

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/regexp_string.rb",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 2,
        "offset": 29
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "ruby/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
def test_equal()
    a = 1
    b = 2
    # ERROR: match
    if a + b == a + b
        return 1
    end
    return 0
end


```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_equality_expr.rb",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 5,
        "offset": 77
      },
      "start": {
        "col": 8,
        "line": 5,
        "offset": 63
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if $E
  $S
else
  $S
end


```

Target:

```text
def foo()
    # ERROR:
    if x > 2
        foo()
        bar()
    else
        foo()
        bar()
    end

    if x > 2
        foo()
        bar()
    else
        foo()
    end
end


```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_equality_stmt.rb",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 8,
        "offset": 100
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 27
      }
    }
  ],
  "pattern_path": "ruby/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open()
close($V)

```

Target:

```text
def foo()
    # ERROR:
    myfile = open()
    close(myfile)
end


```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/metavar_equality_var.rb",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 4,
        "offset": 60
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 27
      }
    }
  ],
  "pattern_path": "ruby/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
def foo()
    # ERROR:
    foo(1, 2, 3, 4, 5)
    # ERROR:
    foo(5)
end


```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/dots_args.rb",
  "highlights": [
    {
      "end": {
        "col": 23,
        "line": 3,
        "offset": 45
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 27
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 69
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 63
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
def foo()
    
  #ERROR: match
  f = o.foo().m().h().bar().z()

  #ERROR: match
  f = o.foo().bar()

  # this one does not contain the bar()
  f = o.foo().m().h().z()

  #ERROR: match $O can match o.before()
  f = o.before().foo().m().h().bar().z()
end

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/dots_method_chaining.rb",
  "highlights": [
    {
      "end": {
        "col": 32,
        "line": 4,
        "offset": 62
      },
      "start": {
        "col": 3,
        "line": 4,
        "offset": 33
      }
    },
    {
      "end": {
        "col": 20,
        "line": 7,
        "offset": 99
      },
      "start": {
        "col": 3,
        "line": 7,
        "offset": 82
      }
    },
    {
      "end": {
        "col": 41,
        "line": 13,
        "offset": 248
      },
      "start": {
        "col": 3,
        "line": 13,
        "offset": 210
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if ... then
  ...
end

```

Target:

```text
def foo
    # ERROR:
    if 1 != 3 then
        foo()
    end

    # ERROR:
    if 1 != 3
        foo()
    end

    # ERROR:
    if 1 == 1
        foo()
        bar()
        baz()
    end
end


```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/dots_nested_stmts.rb",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 4,
        "offset": 53
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 25
      }
    },
    {
      "end": {
        "col": 14,
        "line": 9,
        "offset": 103
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 80
      }
    },
    {
      "end": {
        "col": 14,
        "line": 16,
        "offset": 181
      },
      "start": {
        "col": 5,
        "line": 13,
        "offset": 130
      }
    }
  ],
  "pattern_path": "ruby/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get_data user
...
eval $V


```

Target:

```text
def foo(user)
    # ERROR:
    user_data = get_data user
    puts "... more stuff here ..."
    eval user_data

end

```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/dots_stmts.rb",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 5,
        "offset": 110
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 31
      }
    }
  ],
  "pattern_path": "ruby/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
def foo()
    # ERROR:
    foo("whatever sequence of chars")
    # foo('whatever sequence of chars')

    # this string is not a constant, and therefore will not be matched.
    foo("string #{var} interpolation")
end


```

Match coordinates and source paths:

```json
{
  "code_path": "ruby/dots_string.rb",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 60
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 27
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## rust

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/concrete_syntax.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_call.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_var.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_args.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
Command::new(...). ... .expect(...)

```

Target:

```text
use std::process::Command;

fn main() -> io::Result<()> {
    // ERROR: match
    let proc = Command::new("semgrep-core")
        .args(["-l", "rust"])
        .args(["-rules", "test.yaml"])
        .output()
        .expect("failed to execute process");

    Ok(())
}

```

Match coordinates and source paths:

```json
{
  "code_path": "rust/dots_method_chaining.rs",
  "highlights": [
    {
      "end": {
        "col": 45,
        "line": 9,
        "offset": 253
      },
      "start": {
        "col": 16,
        "line": 5,
        "offset": 93
      }
    }
  ],
  "pattern_path": "rust/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_string.rs",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## scala

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
def bar() = {
	//ERROR: match
	return foo(baz + 42)
}
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/deep_expr_operator.scala",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 3,
        "offset": 51
      },
      "start": {
        "col": 9,
        "line": 3,
        "offset": 38
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
object Foo {

def foo() {
    //ERROR: match
    foo()
    bar()
    //ERROR: match
    foo()
    x = bar()
    //ERROR: match
    foo()
    print(bar())
    //ERROR: match
    foo()
    return bar()
}
}

```

Match coordinates and source paths:

```json
{
  "code_path": "scala/deep_exprstmt.scala",
  "highlights": [
    {
      "end": {
        "col": 10,
        "line": 6,
        "offset": 64
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 49
      }
    },
    {
      "end": {
        "col": 14,
        "line": 9,
        "offset": 107
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 88
      }
    },
    {
      "end": {
        "col": 17,
        "line": 12,
        "offset": 153
      },
      "start": {
        "col": 5,
        "line": 11,
        "offset": 131
      }
    },
    {
      "end": {
        "col": 17,
        "line": 15,
        "offset": 199
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 177
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
object Foo { 

def foo() {
 //ERROR:
    foo(1,2)

 //ERROR:
 foo(1,
     2)

 //ERROR:
 foo (1, // comment
      2)

 foo(2,1)
}
}

```

Match coordinates and source paths:

```json
{
  "code_path": "scala/concrete_syntax.scala",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 5,
        "offset": 49
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 41
      }
    },
    {
      "end": {
        "col": 8,
        "line": 9,
        "offset": 76
      },
      "start": {
        "col": 2,
        "line": 8,
        "offset": 62
      }
    },
    {
      "end": {
        "col": 9,
        "line": 13,
        "offset": 116
      },
      "start": {
        "col": 2,
        "line": 12,
        "offset": 89
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text

def ohno = {
    val bad = "password"

    //ERROR: match
    f("password");

    //ERROR: match
    f(bad);
}
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/equivalence_constant_propagation.scala",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 6,
        "offset": 76
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 63
      }
    },
    {
      "end": {
        "col": 11,
        "line": 9,
        "offset": 108
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 102
      }
    }
  ],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
subprocess.open(...)
```

Target:

```text

import subprocess.open
import subprocess.{open => sub_open}

def foo = {
    //ERROR: match
    result = subprocess.open("ls")

    //ERROR: match
    result = sub_open("ls")

}
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/equivalence_naming_import.scala",
  "highlights": [
    {
      "end": {
        "col": 35,
        "line": 7,
        "offset": 127
      },
      "start": {
        "col": 14,
        "line": 7,
        "offset": 106
      }
    },
    {
      "end": {
        "col": 28,
        "line": 10,
        "offset": 175
      },
      "start": {
        "col": 14,
        "line": 10,
        "offset": 161
      }
    }
  ],
  "pattern_path": "scala/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text

//ERROR: match
@Anno
class Foo1 {}

//ERROR: match
@Anno1
@Anno2
class Foo2 {}

//OK:
@Anno(x)
class Foo3 {}

//OK:
class Foo4 {}
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_anno.scala",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 4,
        "offset": 35
      },
      "start": {
        "col": 1,
        "line": 3,
        "offset": 16
      }
    },
    {
      "end": {
        "col": 14,
        "line": 9,
        "offset": 79
      },
      "start": {
        "col": 1,
        "line": 7,
        "offset": 52
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
object Foo {
def foo() {
    //ERROR:
    foo(1,2)

    //ERROR:
    foo(a_very_long_constant_name,
        2)

    //ERROR:
    foo (unsafe(), // indeed
         2)

    //ERROR:
    foo(bar(1,3), 2)

    foo(2,1)
}
}


```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_arg.scala",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 4,
        "offset": 50
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 42
      }
    },
    {
      "end": {
        "col": 11,
        "line": 8,
        "offset": 110
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 69
      }
    },
    {
      "end": {
        "col": 12,
        "line": 12,
        "offset": 165
      },
      "start": {
        "col": 5,
        "line": 11,
        "offset": 129
      }
    },
    {
      "end": {
        "col": 21,
        "line": 15,
        "offset": 200
      },
      "start": {
        "col": 5,
        "line": 15,
        "offset": 184
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
//ERROR:
class Foo {
    val x = 0

    def bar (x : Int) : Int = x
}
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_class_def.scala",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 6,
        "offset": 69
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E) {
    foo()
}
```

Target:

```text
object Foo {
    def f(x : Bool) : Int = {
        //ERROR:
        if (x) {
            return foo()
        }
    }
}
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_cond.scala",
  "highlights": [
    {
      "end": {
        "col": 25,
        "line": 5,
        "offset": 101
      },
      "start": {
        "col": 9,
        "line": 4,
        "offset": 68
      }
    }
  ],
  "pattern_path": "scala/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
object Foo {
def foo() {
    //ERROR:
    foo(1,2)

    return 1
}
}




```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_call.scala",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 4,
        "offset": 50
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 42
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
def $FUNC(...) : $T = ...
```

Target:

```text
object Test {
    // ERROR:
    def foo() : Int = 1

    // ERROR:
    def bar(bar1 : Int, bar2 : Bool, bar3 : String) : Bool = {
        return bar2
    }

}
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_func_def.scala",
  "highlights": [
    {
      "end": {
        "col": 24,
        "line": 3,
        "offset": 51
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    },
    {
      "end": {
        "col": 20,
        "line": 7,
        "offset": 149
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 71
      }
    }
  ],
  "pattern_path": "scala/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
import $A._
import $B.Thingy
import $C.{ $X => $Y }

```

Target:

```text
//ERROR:
import Lib._
import Lib.Thingy
import Lib.{ ThingA => ThingB, ThingC => ThingD }
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_import.scala",
  "highlights": [
    {
      "end": {
        "col": 30,
        "line": 4,
        "offset": 69
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "scala/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
Map(..., $KEY -> $VALUE, ...)
```

Target:

```text
//ERROR: match
def x = Map("x" -> 1, "y" -> 2)

//OK:
def y = Map2("x" -> 1, "y" -> 2)
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_key_value.scala",
  "highlights": [
    {
      "end": {
        "col": 32,
        "line": 2,
        "offset": 46
      },
      "start": {
        "col": 9,
        "line": 2,
        "offset": 23
      }
    }
  ],
  "pattern_path": "scala/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E) {
    $S
}
```

Target:

```text
object Foo {
    def foo () : Int = {
        //ERROR:
        if (cond) {
            return 1
        }
    }
}
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_stmt.scala",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 5,
        "offset": 95
      },
      "start": {
        "col": 9,
        "line": 4,
        "offset": 63
      }
    }
  ],
  "pattern_path": "scala/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.scala",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
foo($X : Int)
```

Target:

```text
def foo = {
  val x: Int = 0
  val y: String = ""
  //ERROR: match
  foo(x);

  //OK:
  foo(y);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_typed.scala",
  "highlights": [
    {
      "end": {
        "col": 9,
        "line": 5,
        "offset": 75
      },
      "start": {
        "col": 3,
        "line": 5,
        "offset": 69
      }
    }
  ],
  "pattern_path": "scala/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.scala",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.scala",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
object Foo {
    //ERROR:
    val x = (a + b - foo()) == (a + b - foo())
}
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_equality_expr.scala",
  "highlights": [
    {
      "end": {
        "col": 46,
        "line": 3,
        "offset": 71
      },
      "start": {
        "col": 14,
        "line": 3,
        "offset": 39
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E) {
    $S
}
else {
    $S
}
```

Target:

```text
object Foo {
    def foo() = {

        //ERROR:
        if (cond) {
            bar()
        }
        else {
            bar()
        }

        if (cond) {
            bar()
        }
        else {
            baz()
        }

    }
}
```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_equality_stmt.scala",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 9,
        "offset": 129
      },
      "start": {
        "col": 9,
        "line": 5,
        "offset": 57
      }
    }
  ],
  "pattern_path": "scala/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
object Foo {
def foo() {
  //ERROR:
    myfile = open()
    close(myfile)
}
}






```

Match coordinates and source paths:

```json
{
  "code_path": "scala/metavar_equality_var.scala",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 5,
        "offset": 73
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 40
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
object Foo {

def foo() {
  //ERROR:
  foo(1,2,3,4,5)
  //ERROR:
  foo(5)
}
}




```

Match coordinates and source paths:

```json
{
  "code_path": "scala/dots_args.scala",
  "highlights": [
    {
      "end": {
        "col": 17,
        "line": 5,
        "offset": 53
      },
      "start": {
        "col": 3,
        "line": 5,
        "offset": 39
      }
    },
    {
      "end": {
        "col": 9,
        "line": 7,
        "offset": 73
      },
      "start": {
        "col": 3,
        "line": 7,
        "offset": 67
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
def $X = $O.foo(). ... .bar(). ...

```

Target:

```text
    
//ERROR: match
def f = o.foo().m().h().bar().z()

//ERROR: match
def f = o.foo().bar()

  // this one does not contain the bar()
def f = o.foo().m().h().z()

  //ERROR: match $O can match o.before()
def f = o.before().foo().m().h().bar().z()


```

Match coordinates and source paths:

```json
{
  "code_path": "scala/dots_method_chaining.scala",
  "highlights": [
    {
      "end": {
        "col": 34,
        "line": 3,
        "offset": 53
      },
      "start": {
        "col": 1,
        "line": 3,
        "offset": 20
      }
    },
    {
      "end": {
        "col": 22,
        "line": 6,
        "offset": 91
      },
      "start": {
        "col": 1,
        "line": 6,
        "offset": 70
      }
    },
    {
      "end": {
        "col": 43,
        "line": 12,
        "offset": 246
      },
      "start": {
        "col": 1,
        "line": 12,
        "offset": 204
      }
    }
  ],
  "pattern_path": "scala/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
object Foo {

def foo() {

    //ERROR: match
    if (x == 1) {
        return 2
    }
}
}



```

Match coordinates and source paths:

```json
{
  "code_path": "scala/dots_nested_stmts.scala",
  "highlights": [
    {
      "end": {
        "col": 17,
        "line": 7,
        "offset": 80
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 50
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
object Foo {
def foo() {

    //ERROR:
    user_data = get()
    print("do stuff")
    foobar()
    eval(user_data)
}
}


```

Match coordinates and source paths:

```json
{
  "code_path": "scala/dots_stmts.scala",
  "highlights": [
    {
      "end": {
        "col": 20,
        "line": 8,
        "offset": 115
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 43
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
object Foo {
def foo() {
    //ERROR:
    foo("whatever sequence of chars")
    //ERROR:
    foo(s"whatever sequence of chars")
    //ERROR:
    foo("""whatever sequence of chars""")
}
}

```

Match coordinates and source paths:

```json
{
  "code_path": "scala/dots_string.scala",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 4,
        "offset": 75
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 42
      }
    },
    {
      "end": {
        "col": 39,
        "line": 6,
        "offset": 127
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 93
      }
    },
    {
      "end": {
        "col": 42,
        "line": 8,
        "offset": 182
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 145
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## solidity

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
function foo() {
    //ERROR: match
    foo();
    bar();
    //ERROR: match
    foo();
    x = bar();
    //ERROR: match
    foo();
    print(bar());
    //ERROR: match
    foo();
    return bar();
}

```

Match coordinates and source paths:

```json
{
  "code_path": "solidity/deep_exprstmt.sol",
  "highlights": [
    {
      "end": {
        "col": 11,
        "line": 4,
        "offset": 57
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 40
      }
    },
    {
      "end": {
        "col": 15,
        "line": 7,
        "offset": 102
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 81
      }
    },
    {
      "end": {
        "col": 18,
        "line": 10,
        "offset": 150
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 126
      }
    },
    {
      "end": {
        "col": 18,
        "line": 13,
        "offset": 198
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 174
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
function foo() {
 //ERROR:
    foo(1,2);

 //ERROR:
 foo(1,
     2);

 //ERROR:
 foo (1, // comment
      2);

 foo(2,1);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "solidity/concrete_syntax.sol",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 39
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 31
      }
    },
    {
      "end": {
        "col": 8,
        "line": 7,
        "offset": 67
      },
      "start": {
        "col": 2,
        "line": 6,
        "offset": 53
      }
    },
    {
      "end": {
        "col": 9,
        "line": 11,
        "offset": 108
      },
      "start": {
        "col": 2,
        "line": 10,
        "offset": 81
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
function foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(a_very_long_constant_name,
        2);

    //ERROR:
    foo (unsafe(), // indeed
         2);

    //ERROR:
    foo(bar(1,3), 2);

    foo(2,1);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "solidity/metavar_arg.sol",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 103
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 62
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 159
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 123
      }
    },
    {
      "end": {
        "col": 21,
        "line": 14,
        "offset": 195
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 179
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
function foo() {
    //ERROR:
    foo(1,2);

    return 1;
}



```

Match coordinates and source paths:

```json
{
  "code_path": "solidity/metavar_call.sol",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
function foo() {
  //ERROR:
    myfile = open();
    close(myfile);
}





```

Match coordinates and source paths:

```json
{
  "code_path": "solidity/metavar_equality_var.sol",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
function foo() {
  //ERROR:
    foo(1,2,3,4,5);
  //ERROR:
    foo(5);
}



```

Match coordinates and source paths:

```json
{
  "code_path": "solidity/dots_args.sol",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 3,
        "offset": 46
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 69
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 63
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.sol",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
function foo() {

    //ERROR: match
    if (x == 1) {
        return 2;
    }
}


```

Match coordinates and source paths:

```json
{
  "code_path": "solidity/dots_nested_stmts.sol",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 6,
        "offset": 78
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 41
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
function foo() {

    //ERROR:
    user_data = get();
    print("do stuff");
    foobar();
    eval(user_data);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "solidity/dots_stmts.sol",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 7,
        "offset": 111
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 35
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
function foo() {
    //ERROR:
    foo("whatever sequence of chars");
    //ERROR:
    foo('whatever sequence of chars');
}
```

Match coordinates and source paths:

```json
{
  "code_path": "solidity/dots_string.sol",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 38,
        "line": 5,
        "offset": 119
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 86
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## swift

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
func foo() {
    //ERROR: match
    foo();
    bar();
    //ERROR: match
    foo();
    let x = bar();
    //ERROR: match
    foo()
    print(bar());
    //ERROR: match
    foo();
    return bar();
}

```

Match coordinates and source paths:

```json
{
  "code_path": "swift/deep_exprstmt.swift",
  "highlights": [
    {
      "end": {
        "col": 11,
        "line": 4,
        "offset": 53
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 36
      }
    },
    {
      "end": {
        "col": 18,
        "line": 7,
        "offset": 101
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 77
      }
    },
    {
      "end": {
        "col": 18,
        "line": 10,
        "offset": 149
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 126
      }
    },
    {
      "end": {
        "col": 18,
        "line": 13,
        "offset": 197
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 173
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
func foo() {
    //ERROR:
    foo(1, 2);
    //ERROR:
    foo(1,2);
    //ERROR:
    foo (1, 2);
    //ERROR:
    foo(1,
      2);
    //ERROR:
    foo(1, // comment
      2);

    foo(2,1)
}



```

Match coordinates and source paths:

```json
{
  "code_path": "swift/concrete_syntax.swift",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 3,
        "offset": 39
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    },
    {
      "end": {
        "col": 13,
        "line": 5,
        "offset": 66
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 58
      }
    },
    {
      "end": {
        "col": 15,
        "line": 7,
        "offset": 95
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 85
      }
    },
    {
      "end": {
        "col": 9,
        "line": 10,
        "offset": 129
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 114
      }
    },
    {
      "end": {
        "col": 9,
        "line": 13,
        "offset": 174
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 148
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
func foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(a_very_long_constant_name,
        2);

    //ERROR:
    foo (unsafe(), // indeed
         2);

    //ERROR:
    foo(bar(1,3), 2);

    foo(2,1);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "swift/metavar_arg.swift",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 38
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 99
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 58
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 155
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 119
      }
    },
    {
      "end": {
        "col": 21,
        "line": 14,
        "offset": 191
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 175
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
func foo() {
    //ERROR:
    foo(1,2);

    return 1;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "swift/metavar_call.swift",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 38
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
func foo() {
    //ERROR:
    myfile = open();
    close(myfile);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "swift/metavar_equality_var.swift",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 65
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
func foo() {
    //ERROR:
    foo(1,2,3,4,5);
    //ERROR:
    foo(5);
    //ERROR:
    foo(1, 5);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "swift/dots_args.swift",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 3,
        "offset": 44
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 69
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 63
      }
    },
    {
      "end": {
        "col": 14,
        "line": 7,
        "offset": 97
      },
      "start": {
        "col": 5,
        "line": 7,
        "offset": 88
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.swift",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if ... {
  ...
}

```

Target:

```text
func foo() {
    //ERROR: match
    if (x == 1) {
        return 2;
    }
}

```

Match coordinates and source paths:

```json
{
  "code_path": "swift/dots_nested_stmts.swift",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 5,
        "offset": 73
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 36
      }
    }
  ],
  "pattern_path": "swift/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
func foo() {
    //ERROR:
    let user_data = get();
    print("do stuff");
    foobar();
    eval(user_data);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "swift/dots_stmts.swift",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 6,
        "offset": 110
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
func foo() {
    //ERROR:
    foo("whatever sequence of chars");
}


```

Match coordinates and source paths:

```json
{
  "code_path": "swift/dots_string.swift",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 63
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 30
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## ts

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
function bar() {
    baz = 0;
    //ERROR: match
    foo(baz + 42);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "ts/deep_expr_operator.ts",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 53
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
function foo() {
    //ERROR: match
    foo();
    bar();
    //ERROR: match
    foo();
    x = bar();
    //ERROR: match
    foo();
    print(bar());
    //ERROR: match
    foo();
    await bar();
    //ERROR: match
    foo();
    bar().then(other => stuff());
    //ERROR: match
    foo();
    return bar();
}

```

Match coordinates and source paths:

```json
{
  "code_path": "ts/deep_exprstmt.ts",
  "highlights": [
    {
      "end": {
        "col": 11,
        "line": 4,
        "offset": 57
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 40
      }
    },
    {
      "end": {
        "col": 15,
        "line": 7,
        "offset": 102
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 81
      }
    },
    {
      "end": {
        "col": 18,
        "line": 10,
        "offset": 150
      },
      "start": {
        "col": 5,
        "line": 9,
        "offset": 126
      }
    },
    {
      "end": {
        "col": 17,
        "line": 13,
        "offset": 197
      },
      "start": {
        "col": 5,
        "line": 12,
        "offset": 174
      }
    },
    {
      "end": {
        "col": 34,
        "line": 16,
        "offset": 261
      },
      "start": {
        "col": 5,
        "line": 15,
        "offset": 221
      }
    },
    {
      "end": {
        "col": 18,
        "line": 19,
        "offset": 309
      },
      "start": {
        "col": 5,
        "line": 18,
        "offset": 285
      }
    }
  ],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
function foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(1,
        2);

    //ERROR:
    foo (1, //comment
         2);

    foo (2,1);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "ts/concrete_syntax.ts",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 79
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 62
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 128
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 99
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
const Bar = "password";

function foo() {
     //ERROR: match!
     password(Bar);
}

```

Match coordinates and source paths:

```json
{
  "code_path": "ts/equivalence_constant_propagation.ts",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 5,
        "offset": 81
      },
      "start": {
        "col": 6,
        "line": 5,
        "offset": 68
      }
    }
  ],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.ts",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.ts",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
function foo() {
    //ERROR:
    foo(1,2);

    //ERROR:
    foo(a_very_long_constant_name,
        2);

    //ERROR:
    foo (unsafe(), // indeed
         2);

    //ERROR:
    foo(bar(1,3), 2);

    foo(2,1);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "ts/metavar_arg.ts",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 11,
        "line": 7,
        "offset": 103
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 62
      }
    },
    {
      "end": {
        "col": 12,
        "line": 11,
        "offset": 159
      },
      "start": {
        "col": 5,
        "line": 10,
        "offset": 123
      }
    },
    {
      "end": {
        "col": 21,
        "line": 14,
        "offset": 195
      },
      "start": {
        "col": 5,
        "line": 14,
        "offset": 179
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.ts",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
function foo() {
    x = 1;
    //ERROR:
    if (x > 2)
        foo();
}


```

Match coordinates and source paths:

```json
{
  "code_path": "ts/metavar_cond.ts",
  "highlights": [
    {
      "end": {
        "col": 15,
        "line": 5,
        "offset": 70
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 45
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
function foo() {
    //ERROR:
    foo(1,2);

    return 1;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "ts/metavar_call.ts",
  "highlights": [
    {
      "end": {
        "col": 13,
        "line": 3,
        "offset": 42
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
// ERROR:
function foo() {
    foo(1,2);
}

// ERROR:
function bar(bar1:number,bar2:number,bar2:number) {
    foo(1,2);
    bar(1,2,3);
}

// ERROR:
function foobar(bar1: number): number {
    foo();
}

```

Match coordinates and source paths:

```json
{
  "code_path": "ts/metavar_func_def.ts",
  "highlights": [
    {
      "end": {
        "col": 2,
        "line": 4,
        "offset": 42
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 10
      }
    },
    {
      "end": {
        "col": 2,
        "line": 10,
        "offset": 137
      },
      "start": {
        "col": 1,
        "line": 7,
        "offset": 54
      }
    },
    {
      "end": {
        "col": 2,
        "line": 15,
        "offset": 201
      },
      "start": {
        "col": 1,
        "line": 13,
        "offset": 149
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
import $X from 'foo';

```

Target:

```text
//ERROR:
import bar from 'foo';
let x = bar.func_call('a');

```

Match coordinates and source paths:

```json
{
  "code_path": "ts/metavar_import.ts",
  "highlights": [
    {
      "end": {
        "col": 22,
        "line": 2,
        "offset": 30
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 9
      }
    }
  ],
  "pattern_path": "ts/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
function foo(): number {
    // ERROR:
    var config = {
        key: value,
        key2: value2,
        key3: value3,
    };

    var invoke = function(obj: {key: number, key2: string}) {
        return 2;
    };
}

```

Match coordinates and source paths:

```json
{
  "code_path": "ts/metavar_key_value.ts",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 7,
        "offset": 127
      },
      "start": {
        "col": 18,
        "line": 3,
        "offset": 56
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
function foo() {
    v = 1;
    //ERROR:
    if (v > 2)
        return 1;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "ts/metavar_stmt.ts",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 5,
        "offset": 73
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 45
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.ts",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.ts",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
var $X = {"=~/[lL]ocation/": $Y};

```

Target:

```text
//ERROR: match
var x = {"Location": 1};

```

Match coordinates and source paths:

```json
{
  "code_path": "ts/regexp_fieldname.ts",
  "highlights": [
    {
      "end": {
        "col": 24,
        "line": 2,
        "offset": 38
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 15
      }
    }
  ],
  "pattern_path": "ts/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
//ERROR: match
path = "/location/1";
```

Match coordinates and source paths:

```json
{
  "code_path": "ts/regexp_string.ts",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 2,
        "offset": 35
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 15
      }
    }
  ],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
function test_equal() {
    a = 1;
    b = 2;
    //ERROR: match
    if (a+b == a+b)
        return 1;
    return 0;
}


```

Match coordinates and source paths:

```json
{
  "code_path": "ts/metavar_equality_expr.ts",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 5,
        "offset": 83
      },
      "start": {
        "col": 9,
        "line": 5,
        "offset": 73
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
function foo() {
    //ERROR:
    if (x > 2) {
        foo();
        bar();
    } else {
        foo();
        bar();
    }

    if (x > 2) {
        foo();
        bar();
    } else {
        foo();
    }
}




```

Match coordinates and source paths:

```json
{
  "code_path": "ts/metavar_equality_stmt.ts",
  "highlights": [
    {
      "end": {
        "col": 6,
        "line": 9,
        "offset": 125
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
function foo() {
  //ERROR:
    myfile = open();
    close(myfile);
}




```

Match coordinates and source paths:

```json
{
  "code_path": "ts/metavar_equality_var.ts",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 4,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    }
  ],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
function foo() {
  //ERROR:
    foo(1,2,3,4,5);
  //ERROR:
    foo(5);
}


```

Match coordinates and source paths:

```json
{
  "code_path": "ts/dots_args.ts",
  "highlights": [
    {
      "end": {
        "col": 19,
        "line": 3,
        "offset": 46
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 32
      }
    },
    {
      "end": {
        "col": 11,
        "line": 5,
        "offset": 69
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 63
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
//ERROR: match
f = o.foo().m().h().bar().z();

//ERROR: match
f = o.foo().bar();

f = o.foo().m().h().z();

//ERROR: match $O can match o.before()
f = o.before().foo().m().h().bar().z();

```

Match coordinates and source paths:

```json
{
  "code_path": "ts/dots_method_chaining.ts",
  "highlights": [
    {
      "end": {
        "col": 30,
        "line": 2,
        "offset": 44
      },
      "start": {
        "col": 1,
        "line": 2,
        "offset": 15
      }
    },
    {
      "end": {
        "col": 18,
        "line": 5,
        "offset": 79
      },
      "start": {
        "col": 1,
        "line": 5,
        "offset": 62
      }
    },
    {
      "end": {
        "col": 39,
        "line": 10,
        "offset": 185
      },
      "start": {
        "col": 1,
        "line": 10,
        "offset": 147
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
function foo() {

    //ERROR: match
    if (x == 1) 
        return 2;
}

```

Match coordinates and source paths:

```json
{
  "code_path": "ts/dots_nested_stmts.ts",
  "highlights": [
    {
      "end": {
        "col": 18,
        "line": 5,
        "offset": 71
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 41
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
function foo() {

    //ERROR:
    user_data = get();
    print("do stuff");
    foobar();
    eval(user_data);
}



```

Match coordinates and source paths:

```json
{
  "code_path": "ts/dots_stmts.ts",
  "highlights": [
    {
      "end": {
        "col": 21,
        "line": 7,
        "offset": 111
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 35
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
function foo() {
    //ERROR:
    foo("whatever sequence of chars");
    //ERROR:
    foo('whatever sequence of chars');
}


```

Match coordinates and source paths:

```json
{
  "code_path": "ts/dots_string.ts",
  "highlights": [
    {
      "end": {
        "col": 38,
        "line": 3,
        "offset": 67
      },
      "start": {
        "col": 5,
        "line": 3,
        "offset": 34
      }
    },
    {
      "end": {
        "col": 38,
        "line": 5,
        "offset": 119
      },
      "start": {
        "col": 5,
        "line": 5,
        "offset": 86
      }
    }
  ],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## vue

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
<script>
function foo() {
 //ERROR:
    foo(1, 2);
 //ERROR:
    foo(1,2);
 //ERROR:
    foo (1, 2);
 //ERROR:
 foo(1,
     2);
 //ERROR:
 foo(1, // comment
     2);

 foo(2,1)
}


</script>

```

Match coordinates and source paths:

```json
{
  "code_path": "vue/concrete_syntax.vue",
  "highlights": [
    {
      "end": {
        "col": 14,
        "line": 4,
        "offset": 49
      },
      "start": {
        "col": 5,
        "line": 4,
        "offset": 40
      }
    },
    {
      "end": {
        "col": 13,
        "line": 6,
        "offset": 73
      },
      "start": {
        "col": 5,
        "line": 6,
        "offset": 65
      }
    },
    {
      "end": {
        "col": 15,
        "line": 8,
        "offset": 99
      },
      "start": {
        "col": 5,
        "line": 8,
        "offset": 89
      }
    },
    {
      "end": {
        "col": 8,
        "line": 11,
        "offset": 126
      },
      "start": {
        "col": 2,
        "line": 10,
        "offset": 112
      }
    },
    {
      "end": {
        "col": 8,
        "line": 14,
        "offset": 164
      },
      "start": {
        "col": 2,
        "line": 13,
        "offset": 139
      }
    }
  ],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_call.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_var.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_args.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_string.vue",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```

## yaml

### Deep (Recursive) Matching

#### Deep Expression Operator

Pattern:

```text
foo(<... 42 ...>);

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_expr_operator.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_expr_operator.sgrep"
}
```

#### Expression and Statement

Pattern:

```text
foo();
bar();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/deep_exprstmt.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/deep_exprstmt.sgrep"
}
```

### Exact Matches

#### Single Statements

Pattern:

```text
foo(1, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/concrete_syntax.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/concrete_syntax.sgrep"
}
```

### Helpful Features

#### Constant Propagation

Pattern:

```text
$F("password")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_constant_propagation.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_constant_propagation.sgrep"
}
```

#### Import Renaming/Aliasing

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/equivalence_naming_import.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/equivalence_naming_import.sgrep"
}
```

### Named Placeholders ($X)

#### Annotations

Pattern:

```text
@$X
class $CLASS {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_anno.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_anno.sgrep"
}
```

#### Argument

Pattern:

```text
foo($X, 2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_arg.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_arg.sgrep"
}
```

#### Class Definitions

Pattern:

```text
class $X {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_class_def.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_class_def.sgrep"
}
```

#### Conditionals

Pattern:

```text
if ($E)
   foo();

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_cond.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_cond.sgrep"
}
```

#### Function Call

Pattern:

```text
$F(1,2)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_call.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_call.sgrep"
}
```

#### Function Definitions

Pattern:

```text
function $X(...) {
    ...
}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_func_def.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_func_def.sgrep"
}
```

#### Imports

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_import.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_import.sgrep"
}
```

#### Object or Dictionary Key Value Pairs

Pattern:

```text
{..., $KEY: $VALUE, ...}

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_key_value.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_key_value.sgrep"
}
```

#### Statement

Pattern:

```text
if ($X > $Y)
   $S;

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_stmt.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_stmt.sgrep"
}
```

#### Typed Metavariable Field Access

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed_fieldaccess.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed_fieldaccess.sgrep"
}
```

#### Typed Metavariables

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_typed.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_typed.sgrep"
}
```

### Regular Expressions '=~/regexp/'

#### Field Names

Pattern:

```text
(No pattern provided upstream.)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_fieldname.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_fieldname.sgrep"
}
```

#### Strings

Pattern:

```text
$X = "=~//[lL]ocation.*/" 


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/regexp_string.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/regexp_string.sgrep"
}
```

### Reoccurring Expressions

#### Expressions

Pattern:

```text
$X == $X
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_expr.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_expr.sgrep"
}
```

#### Statement

Pattern:

```text
if ($E)
  $S;
else
  $S;


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_stmt.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_stmt.sgrep"
}
```

#### Variables

Pattern:

```text
$V = open();
close($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/metavar_equality_var.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/metavar_equality_var.sgrep"
}
```

### Wildcard Matches (...)

#### Arguments

Pattern:

```text
foo(..., 5)
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_args.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_args.sgrep"
}
```

#### Method Chaining

Pattern:

```text
$X = $O.foo(). ... .bar(). ...

```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_method_chaining.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_method_chaining.sgrep"
}
```

#### Nested Statements

Pattern:

```text
if (...)
  ...


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_nested_stmts.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_nested_stmts.sgrep"
}
```

#### Statements

Pattern:

```text
$V = get();
...
eval($V);


```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_stmts.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_stmts.sgrep"
}
```

#### Strings

Pattern:

```text
foo("...")
```

Target:

```text
(No target code provided upstream.)
```

Match coordinates and source paths:

```json
{
  "code_path": "POLYGLOT/dots_string.yaml",
  "highlights": [],
  "pattern_path": "POLYGLOT/dots_string.sgrep"
}
```
