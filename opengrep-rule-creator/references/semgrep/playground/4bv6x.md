# Upstream Semgrep playground: 4bv6x

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [4bv6x](https://semgrep.dev/embed/editor?snippet=4bv6x). [Raw API response](4bv6x.json).

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
          "patterns": [
            {
              "pattern": "if something($FROM):\n  ...\n  $TO()\n  ...\n"
            }
          ],
          "from": "$FROM",
          "to": "$TO",
          "by-side-effect": false
        }
      ],
      "pattern-sinks": [
        {
          "pattern": "sink()"
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
    if something(user_input):
        sink() # sink is tainted here
    sink() # but not here

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
