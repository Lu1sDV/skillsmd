# Upstream Semgrep playground: qNwez

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [qNwez](https://semgrep.dev/embed/editor?snippet=qNwez). [Raw API response](qNwez.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "test",
      "languages": [
        "python"
      ],
      "message": "Test",
      "mode": "taint",
      "pattern-sources": [
        {
          "pattern": "tainted"
        }
      ],
      "pattern-sinks": [
        {
          "pattern": "sink(...)",
          "exact": false
        }
      ],
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
sink("foo" if tainted else "bar")
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
