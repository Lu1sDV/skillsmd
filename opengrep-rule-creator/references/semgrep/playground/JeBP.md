# Upstream Semgrep playground: JeBP

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [JeBP](https://semgrep.dev/embed/editor?snippet=JeBP). [Raw API response](JeBP.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "test",
      "options": {
        "symbolic_propagation": true
      },
      "pattern": "pandas.DataFrame(...).index.set_value(...)",
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
import pandas

def test1():
    # ruleid: test
    pandas.DataFrame(x).index.set_value(a, b, c)

def test2():
    df = pandas.DataFrame(x)
    ix = df.index
    # ruleid: test
    ix.set_value(a, b, c)
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": [
    {
      "start": {
        "col": 5,
        "line": 5,
        "offset": 51
      },
      "end": {
        "col": 49,
        "line": 5,
        "offset": 95
      },
      "message": "Semgrep found a match"
    },
    {
      "start": {
        "col": 5,
        "line": 11,
        "offset": 180
      },
      "end": {
        "col": 26,
        "line": 11,
        "offset": 201
      },
      "message": "Semgrep found a match"
    }
  ]
}
```
