# Upstream Semgrep playground: Dyzd

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [Dyzd](https://semgrep.dev/embed/editor?snippet=Dyzd). [Raw API response](Dyzd.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "good-metavar-taint-example",
      "languages": [
        "python"
      ],
      "message": "some_function called with $X < 256",
      "patterns": [
        {
          "pattern": "some_function($X)"
        },
        {
          "metavariable-comparison": {
            "metavariable": "$X",
            "comparison": "$X < 256"
          }
        }
      ],
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
n = 128
#ruleid: test
some_function(n)
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": [
    {
      "start": {
        "col": 1,
        "line": 3,
        "offset": 22
      },
      "end": {
        "col": 17,
        "line": 3,
        "offset": 38
      },
      "message": "some_function called with n < 256"
    }
  ]
}
```
