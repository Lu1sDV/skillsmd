# Upstream Semgrep playground: gBD0

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [gBD0](https://semgrep.dev/embed/editor?snippet=gBD0). [Raw API response](gBD0.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "taint-rule",
      "languages": [
        "js"
      ],
      "message": "Tainted sink!",
      "mode": "taint",
      "options": {
        "taint_assume_safe_functions": true
      },
      "pattern-sources": [
        {
          "pattern": "tainted"
        }
      ],
      "pattern-propagators": [
        {
          "patterns": [
            {
              "pattern": "$F(..., $X, ...)"
            },
            {
              "focus-metavariable": "$F"
            },
            {
              "pattern-either": [
                {
                  "pattern": "some_unsafe_function"
                }
              ]
            }
          ],
          "from": "$X",
          "to": "$F"
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
var x = some_safe_function(tainted);
// ok: taint-rule
sink(x);

var y = some_unsafe_function(tainted);
// ruleid: taint-rule
sink(y)
```

Case metadata:

```json
{
  "filename": null,
  "language": "js",
  "highlights": []
}
```
