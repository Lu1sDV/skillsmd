# Upstream Semgrep playground: dGRE

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [dGRE](https://semgrep.dev/embed/editor?snippet=dGRE). [Raw API response](dGRE.json).

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
      "pattern-propagators": [
        {
          "pattern": "$S.add($E)",
          "from": "$E",
          "to": "$S"
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
def test(s):
    x = user_input
    s = set([])
    s.add(x)
    #ruleid: test
    sink(s.pop())

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
