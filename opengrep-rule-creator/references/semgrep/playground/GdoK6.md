# Upstream Semgrep playground: GdoK6

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [GdoK6](https://semgrep.dev/embed/editor?snippet=GdoK6). [Raw API response](GdoK6.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "test-copy",
      "languages": [
        "python"
      ],
      "message": "Test",
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
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
def foo(y):
    sink(y[0]) # OK
    sink(y[42]) # finding

def test(x):
    x[0] = "safe"
    x[42] = user_input
    foo(x)

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
