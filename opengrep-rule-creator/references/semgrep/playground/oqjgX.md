# Upstream Semgrep playground: oqjgX

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [oqjgX](https://semgrep.dev/embed/editor?snippet=oqjgX). [Raw API response](oqjgX.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "test",
      "mode": "taint",
      "options": {
        "taint_assume_safe_numbers": true
      },
      "pattern-sources": [
        {
          "patterns": [
            {
              "pattern": "def $FUN(..., $X, ...):\n  ...\n"
            },
            {
              "focus-metavariable": "$X"
            }
          ]
        }
      ],
      "pattern-sinks": [
        {
          "pattern": "sink(...)"
        }
      ],
      "message": "Semgrep found a match",
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
def test(x):
    y = x + 1
    # no finding here
    sink(y)
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
