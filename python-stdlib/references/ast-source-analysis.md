# AST construction and source-analysis compatibility

## Contents

- [Parse source without importing it](#parse-source-without-importing-it)
- [Construct complete syntax trees](#construct-complete-syntax-trees)
- [Preserve intended analysis fidelity](#preserve-intended-analysis-fidelity)
- [Separate parser support from semantic support](#separate-parser-support-from-semantic-support)

## Parse source without importing it

For source inspection, read text/bytes under the caller's encoding and size
policy, then use `ast.parse` without importing or executing the target package.
Importing a package can run `__init__` code, registration, extension imports and
3.15 startup hooks in the *scanner's* interpreter. Source parsing alone does not
need those effects. Bound files and input complexity; parsing an untrusted,
enormous or deeply nested input is not an unlimited-resource sandbox.

`ast.parse(source, feature_version=(3, minor))` requests a best-effort grammar
restriction; it is not an emulator for all earlier runtime semantics. Parse on
each actually supported interpreter when compatible syntax matters, and do not
infer an older parser can handle 3.15-only lazy imports or comprehension
unpacking. Source-level text (including comments and formatting) is not preserved
by an ordinary AST.

```pycon
>>> import ast
>>> source = "def increment(value: int) -> int:\\n    return value + 1\\n"
>>> parsed = ast.parse(source)
>>> assert isinstance(parsed, ast.Module)
>>> assert sum(isinstance(n, ast.Return) for n in ast.walk(parsed)) == 1
```

## Construct complete syntax trees

Python 3.13 warned about absent required fields or unknown constructor keyword
arguments; **3.15 raises `TypeError`** instead. Construct the fields described by
the target grammar, including required child nodes and expression contexts.
Use `ast.fix_missing_locations` to supply missing source positions in generated
trees and `ast.copy_location` when replacing an existing node. Those helpers do
not repair malformed node shape, incorrect identifier binding, missing domain
validation or invalid control flow.

```pycon
>>> import ast
>>> expression = ast.Expression(body=ast.BinOp(
...     left=ast.Constant(value=7), op=ast.Add(), right=ast.Constant(value=2)))
>>> expression = ast.fix_missing_locations(expression)
>>> assert eval(compile(expression, "<owned-generated-expression>", "eval")) == 9
>>> try:
...     ast.Name(id="item", ctx=ast.Load(), unknown_field=True)
... except TypeError:
...     pass
... else:
...     raise AssertionError("3.15 constructor accepted an unknown field")
```

The `eval` here executes **only fixed, trusted, generated example code**. Do
not use `eval`/`exec` to validate hostile source; compiling or running an
untrusted program changes the trust boundary and may consume arbitrary resources.
Also avoid treating `ast.literal_eval` as safe for unlimited hostile input:
nested/large literals can exhaust resources.

## Preserve intended analysis fidelity

`ast.parse(..., optimize=...)` (3.13+) may produce an optimized tree. If a
scanner must retain source-level constructs, analyze the non-optimized tree;
optimization can eliminate nodes (3.14+ optimization level 2 removes docstrings).
Do not equate source-code lines with tree nodes or character offsets: AST
`col_offset`/`end_col_offset` represent UTF-8 byte offsets. `ast.unparse`
can reconstruct equivalent syntax, not the original comments, spacing or
source byte sequence.

`ast.compare` (3.14+) tests structural equality, with an option for comparing
attributes. It does not prove behavioral equivalence or name-resolution
correctness.

```pycon
>>> import ast
>>> assert ast.compare(ast.parse("x = 1"), ast.parse("x=1"))
>>> assert not ast.compare(ast.parse("x=1"), ast.parse("x=2"))
```

Visitor migrations use `visit_Constant` rather than obsolete `visit_Num`,
`visit_Str` or `visit_NameConstant` implementations. For transformations
that change statements, return a list from `NodeTransformer` only where
supported, and validate the resulting program's intended behavior.

## Separate parser support from semantic support

When updating a source analyzer, check these capabilities independently:

| Layer | Evidence to require |
|---|---|
| Grammar | Parse fixtures from each supported Python release, including 3.15 `lazy import` and unpacking-comprehension forms |
| Tree shape | Confirm current fields, contexts, function/type parameters, and 3.15 lazy-import and comprehension node representations |
| Symbol model | Resolve new binders, imports and annotations without assuming evaluation at definition/import time |
| Semantic/modeling | Verify new `sentinel` and `frozendict` values and library/framework call behavior, not only AST acceptance |
| Data flow | Exercise real source-to-sink or rewrite results with independent expected outcomes and false-positive controls |
| Publication | Keep claimed parser/model coverage distinct from runtime version coverage; report missing fixtures and unsupported builds |

Keep source inspection import-free unless executing the target is explicitly
required and authorized. Avoid optimized trees when the intended proof concerns
source semantics. Hand off security-rule or interprocedural analysis to a
dedicated security-analysis skill if available; ordinary stdlib AST handling
requires no sibling install.

First-party sources: [AST](https://docs.python.org/3.15/library/ast.html),
[Python 3.15 changes](https://docs.python.org/3.15/whatsnew/3.15.html),
[Python 3.14 changes](https://docs.python.org/3.15/whatsnew/3.14.html),
[Python 3.13 changes](https://docs.python.org/3.15/whatsnew/3.13.html).
