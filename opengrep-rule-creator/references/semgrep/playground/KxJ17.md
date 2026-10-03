# Upstream Semgrep playground: KxJ17

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [KxJ17](https://semgrep.dev/embed/editor?snippet=KxJ17). [Raw API response](KxJ17.json).

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
