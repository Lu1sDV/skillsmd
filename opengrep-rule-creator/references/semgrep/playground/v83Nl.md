# Upstream Semgrep playground: v83Nl

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [v83Nl](https://semgrep.dev/embed/editor?snippet=v83Nl). [Raw API response](v83Nl.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "taint-example",
      "message": "Test",
      "severity": "WARNING",
      "languages": [
        "python"
      ],
      "mode": "taint",
      "pattern-sources": [
        {
          "pattern": "tainted"
        }
      ],
      "pattern-sinks": [
        {
          "patterns": [
            {
              "pattern": "sink($SINK, ...)"
            },
            {
              "focus-metavariable": "$SINK"
            }
          ]
        }
      ]
    }
  ]
}
```

## Test case 1

```text
# ruleid: taint-example
sink(tainted, ok)

#ok: taint-example
sink(ok, tainted)

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
