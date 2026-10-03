# Upstream Semgrep playground: PeBXv

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [PeBXv](https://semgrep.dev/embed/editor?snippet=PeBXv). [Raw API response](PeBXv.json).

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
def baz(z):
    # found !
    sink(z)

def bar(y):
    baz(y)

def foo(x):
    bar(x)

def test():
    foo(user_input)
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
