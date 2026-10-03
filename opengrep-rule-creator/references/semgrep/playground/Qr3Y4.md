# Upstream Semgrep playground: Qr3Y4

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [Qr3Y4](https://semgrep.dev/embed/editor?snippet=Qr3Y4). [Raw API response](Qr3Y4.json).

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
          "patterns": [
            {
              "pattern-inside": "def foo($X, ...):\n  ...\n"
            },
            {
              "pattern": "$X"
            }
          ]
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
def foo(x):
    #ruleid: test
    sink(x)

def foo(x):
    x = sanitize(x)
    #ok: test
    sink(x) # false positive
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
