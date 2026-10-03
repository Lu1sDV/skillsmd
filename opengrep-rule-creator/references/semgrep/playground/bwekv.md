# Upstream Semgrep playground: bwekv

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [bwekv](https://semgrep.dev/embed/editor?snippet=bwekv). [Raw API response](bwekv.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "test",
      "mode": "taint",
      "options": {
        "taint_only_propagate_through_assignments": true
      },
      "pattern-sources": [
        {
          "pattern": "\"password\"\n"
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
def test1():
    a = "password"
    b = a
    # finding here
    sink(b)
    # functions are safe ...
    c = f(b)
    # ... so no finding here
    sink(c)

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
