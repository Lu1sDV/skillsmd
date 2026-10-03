# Upstream Semgrep playground: OrAAe

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [OrAAe](https://semgrep.dev/embed/editor?snippet=OrAAe). [Raw API response](OrAAe.json).

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
          "pattern": "sink(...)"
        }
      ]
    }
  ]
}
```

## Test case 1

```text
sink(tainted, ok) # first argument is a sink

sink(ok, tainted) # second argument is a sink too

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
