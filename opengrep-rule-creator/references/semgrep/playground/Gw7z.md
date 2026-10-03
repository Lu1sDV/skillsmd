# Upstream Semgrep playground: Gw7z

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [Gw7z](https://semgrep.dev/embed/editor?snippet=Gw7z). [Raw API response](Gw7z.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "constant-propagation-example",
      "patterns": [
        {
          "pattern": "eval(...)"
        },
        {
          "pattern-not": "eval(\"...\")"
        }
      ],
      "message": "Found call to 'eval' on non-constant data",
      "languages": [
        "python"
      ],
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
def test(arg):
   if arg is not None:
      x = arg
      y = "y"
      z = "z1"
   else:
      x = "x"
      y = "y"
      z = "z2"
   # `x` is not guaranteed to be constant (it could be an alias for `arg`)
   # ruleid: constant-propagation-example
   eval(x)
   # `y` is always the constant string `"y"`
   # ok: constant-propagation-example
   eval(y)
   # `z` is always a constant, either `"z1"` or `"z2"`
   # ok: constant-propagation-example
   eval(z)
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": [
    {
      "start": {
        "col": 4,
        "line": 12
      },
      "end": {
        "col": 11,
        "line": 12
      },
      "message": "Found call to 'eval' on non-constant data"
    }
  ]
}
```
