# Upstream Semgrep playground: jwvn

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [jwvn](https://semgrep.dev/embed/editor?snippet=jwvn). [Raw API response](jwvn.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "constant-propagation-example",
      "options": {
        "constant_propagation": false
      },
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
   x = "constant"
   # We have disabled constant propagation!
   # ruleid: constant-propagation-example
   eval(x)
   # ok: constant-propagation-example
   eval("constant")
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
        "line": 5,
        "offset": 122
      },
      "end": {
        "col": 11,
        "line": 5,
        "offset": 129
      },
      "message": "Found call to 'eval' on non-constant data"
    }
  ]
}
```
