# Upstream Semgrep playground: 5rvkj

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [5rvkj](https://semgrep.dev/embed/editor?snippet=5rvkj). [Raw API response](5rvkj.json).

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
    sink(y.a) # finding
    sink(y.b) # OK

def test(x):
    x.a = user_input
    x.b = "safe"
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
