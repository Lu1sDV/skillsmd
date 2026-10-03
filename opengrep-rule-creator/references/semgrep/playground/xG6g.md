# Upstream Semgrep playground: xG6g

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [xG6g](https://semgrep.dev/embed/editor?snippet=xG6g). [Raw API response](xG6g.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "taint-example",
      "languages": [
        "python"
      ],
      "message": "Found dangerous HTML output",
      "mode": "taint",
      "pattern-sources": [
        {
          "pattern": "get_user_input(...)"
        }
      ],
      "pattern-sanitizers": [
        {
          "pattern": "sanitize_input(...)"
        }
      ],
      "pattern-sinks": [
        {
          "pattern": "html_output(...)"
        },
        {
          "pattern": "eval(...)"
        }
      ],
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
def route1():
    data = get_user_input()
    data = sanitize_input(data)
    # ok: taint-example
    return html_output(data)

def route2():
    data = get_user_input()
    # ruleid: taint-example
    return html_output(data)
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
