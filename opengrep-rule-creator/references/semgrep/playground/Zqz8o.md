# Upstream Semgrep playground: Zqz8o

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [Zqz8o](https://semgrep.dev/embed/editor?snippet=Zqz8o). [Raw API response](Zqz8o.json).

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
          "pattern": "\"taint\"\n"
        }
      ],
      "pattern-sanitizers": [
        {
          "pattern": "sanitize(...)",
          "exact": true
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
sanitize(sink("taint"))
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
