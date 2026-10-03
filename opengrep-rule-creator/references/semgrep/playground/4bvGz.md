# Upstream Semgrep playground: 4bvGz

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [4bvGz](https://semgrep.dev/embed/editor?snippet=4bvGz). [Raw API response](4bvGz.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "taint-example-copy",
      "languages": [
        "python"
      ],
      "message": "Matched",
      "mode": "taint",
      "pattern-sources": [
        {
          "pattern": "source(...)"
        }
      ],
      "pattern-sanitizers": [
        {
          "patterns": [
            {
              "pattern": "check_if_safe($X)"
            },
            {
              "focus-metavariable": "$X"
            }
          ],
          "by-side-effect": true
        }
      ],
      "pattern-sinks": [
        {
          "pattern": "sink(...)"
        }
      ],
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
x = source()
check_if_safe(x)
#ok: taint-example
sink(x)

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
