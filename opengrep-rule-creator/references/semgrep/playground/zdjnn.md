# Upstream Semgrep playground: zdjnn

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [zdjnn](https://semgrep.dev/embed/editor?snippet=zdjnn). [Raw API response](zdjnn.json).

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
def test(x, y):
    z = x + y
    # finding, x and y may be strings
    sink(z)
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
