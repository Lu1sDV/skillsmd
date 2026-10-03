# Upstream Semgrep playground: X56pj

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [X56pj](https://semgrep.dev/embed/editor?snippet=X56pj). [Raw API response](X56pj.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "test",
      "mode": "taint",
      "options": {
        "taint_assume_safe_indexes": true
      },
      "pattern-sources": [
        {
          "pattern": "user_input"
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
def test():
    a = safe()
    x = a[user_input]
    # no finding here, `x` is safe
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
