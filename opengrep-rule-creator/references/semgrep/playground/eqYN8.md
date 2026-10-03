# Upstream Semgrep playground: eqYN8

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [eqYN8](https://semgrep.dev/embed/editor?snippet=eqYN8). [Raw API response](eqYN8.json).

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
          "pattern": "source(...)"
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
source(sink(x))

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
