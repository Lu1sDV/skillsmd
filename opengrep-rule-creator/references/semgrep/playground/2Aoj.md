# Upstream Semgrep playground: 2Aoj

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [2Aoj](https://semgrep.dev/embed/editor?snippet=2Aoj). [Raw API response](2Aoj.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "redos-example",
      "patterns": [
        {
          "pattern": "Regex $A = new Regex($B);"
        },
        {
          "metavariable-analysis": {
            "analyzer": "redos",
            "metavariable": "$B"
          }
        }
      ],
      "message": "Regex $B is vulnerable to catastrophic backtracking.",
      "languages": [
        "csharp"
      ],
      "severity": "ERROR"
    }
  ]
}
```

## Test case 1

```text
class Foo{
    public Regex getRegex(){
        //ruleid: redos-example
        Regex r = new Regex("^([a-zA-Z0-9])(([\-.]|[_]+)?([a-zA-Z0-9]+))*(@){1}[a-z0-9]+[.]{1}(([a-z]{2,3})|([a-z]{2,3}[.]{1}[a-z]{2,3}))$");
        return r;
    }
}
```

Case metadata:

```json
{
  "filename": null,
  "language": "csharp",
  "highlights": [
    {
      "start": {
        "col": 9,
        "line": 4,
        "offset": 80
      },
      "end": {
        "col": 141,
        "line": 4,
        "offset": 212
      },
      "message": "Regex \"^([a-zA-Z0-9])(([\\-.]|[_]+)?([a-zA-Z0-9]+))*(@){1}[a-z0-9]+[.]{1}(([a-z]{2,3})|([a-z]{2,3}[.]{1}[a-z]{2,3}))$\" is vulnerable to catastrophic backtracking."
    }
  ]
}
```
