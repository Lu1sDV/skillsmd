# Upstream Semgrep playground: v83Rb

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [v83Rb](https://semgrep.dev/embed/editor?snippet=v83Rb). [Raw API response](v83Rb.json).

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
          "pattern": "sanitize(...)"
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
