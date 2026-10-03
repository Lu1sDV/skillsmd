# Upstream Semgrep playground: PwKY

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [PwKY](https://semgrep.dev/embed/editor?snippet=PwKY). [Raw API response](PwKY.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "taint-labels",
      "mode": "taint",
      "pattern-sources": [
        {
          "pattern": "user_input",
          "label": "INPUT"
        },
        {
          "pattern": "evil(...)",
          "requires": "INPUT",
          "label": "EVIL"
        }
      ],
      "pattern-sinks": [
        {
          "pattern": "sink(...)",
          "requires": "EVIL"
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
def bad(user_input):
    x = user_input
    y = evil(x)
    # ruleid: taint-labels
    sink(y)

def bad(user_input):
    x = user_input
    # ok: taint-labels (no evil!)
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
