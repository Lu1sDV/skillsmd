# Upstream Semgrep playground: OrAzB

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [OrAzB](https://semgrep.dev/embed/editor?snippet=OrAzB). [Raw API response](OrAzB.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "taint-example",
      "message": "Test",
      "severity": "WARNING",
      "languages": [
        "python"
      ],
      "mode": "taint",
      "pattern-sources": [
        {
          "by-side-effect": true,
          "patterns": [
            {
              "pattern": "$FILE = open(...)"
            },
            {
              "focus-metavariable": "$FILE"
            }
          ]
        }
      ],
      "pattern-sanitizers": [
        {
          "by-side-effect": true,
          "patterns": [
            {
              "pattern": "$FILE.close(...)"
            },
            {
              "focus-metavariable": "$FILE"
            }
          ]
        }
      ],
      "pattern-sinks": [
        {
          "at-exit": true,
          "pattern-either": [
            {
              "pattern": "return ..."
            },
            {
              "pattern": "$F(...)"
            }
          ]
        }
      ]
    }
  ]
}
```

## Test case 1

```text
def test():
    file = open("test.txt")
    content = file.read()
    #ruleid: taint-example
    print(content)

```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
