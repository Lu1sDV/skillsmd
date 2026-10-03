# Upstream Semgrep playground: JDPGP

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [JDPGP](https://semgrep.dev/embed/editor?snippet=JDPGP). [Raw API response](JDPGP.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "test",
      "mode": "taint",
      "options": {
        "taint_focus_on": "source"
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
    # finding is reported at the source's location
    x = user_input
    y = x
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
