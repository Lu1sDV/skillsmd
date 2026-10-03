# Upstream Semgrep playground: Zq5ow

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [Zq5ow](https://semgrep.dev/embed/editor?snippet=Zq5ow). [Raw API response](Zq5ow.json).

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
          "pattern": "source(...)",
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
#ok: test
source(sink(x))

y = source()
#ruleid: test
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
