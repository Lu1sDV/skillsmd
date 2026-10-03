# Upstream Semgrep playground: yyjrx

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [yyjrx](https://semgrep.dev/embed/editor?snippet=yyjrx). [Raw API response](yyjrx.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "test",
      "message": "Test",
      "severity": "WARNING",
      "languages": [
        "python"
      ],
      "mode": "taint",
      "pattern-sources": [
        {
          "pattern": "foo()",
          "control": true
        }
      ],
      "pattern-sinks": [
        {
          "pattern": "bar()"
        }
      ]
    }
  ]
}
```

## Test case 1

```text
def wrap():
    bar()

def test():
    foo()
    wrap()
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
