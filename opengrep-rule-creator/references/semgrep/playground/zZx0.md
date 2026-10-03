# Upstream Semgrep playground: zZx0

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [zZx0](https://semgrep.dev/embed/editor?snippet=zZx0). [Raw API response](zZx0.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "scope-of-ellipsis-operator",
      "pattern": "foo\n...\n",
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
def parentf():
    foo

    if cond():
        bar

bar

baz
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
