# Upstream Semgrep playground: WAYzL

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [WAYzL](https://semgrep.dev/embed/editor?snippet=WAYzL). [Raw API response](WAYzL.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "test",
      "mode": "taint",
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
    if cond():
        x = user_input
    else:
        y = user_input
    sink(x if cond() else y)

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
