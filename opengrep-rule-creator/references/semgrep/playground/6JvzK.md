# Upstream Semgrep playground: 6JvzK

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [6JvzK](https://semgrep.dev/embed/editor?snippet=6JvzK). [Raw API response](6JvzK.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "test",
      "mode": "taint",
      "options": {
        "taint_assume_safe_booleans": true
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
    x = user_input
    # no finding here
    sink(x == "safe")

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
