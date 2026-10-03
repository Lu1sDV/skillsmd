# Upstream Semgrep playground: GgZG

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [GgZG](https://semgrep.dev/embed/editor?snippet=GgZG). [Raw API response](GgZG.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "generic-entropy-assignment",
      "patterns": [
        {
          "pattern": "string $A = \"$B\";"
        },
        {
          "metavariable-analysis": {
            "analyzer": "entropy",
            "metavariable": "$B"
          }
        }
      ],
      "message": "Found a high-entropy assignment to $A",
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
    public string getSomeString(){
        //ruleid: generic-entropy-assignment
        string high_entropy_string = "d3a447630194bd4b";
        return high_entropy_string;
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
        "offset": 99
      },
      "end": {
        "col": 56,
        "line": 4,
        "offset": 146
      },
      "message": "Found a high-entropy assignment to high_entropy_string"
    }
  ]
}
```
