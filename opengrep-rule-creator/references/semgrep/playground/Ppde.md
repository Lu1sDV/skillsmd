# Upstream Semgrep playground: Ppde

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [Ppde](https://semgrep.dev/embed/editor?snippet=Ppde). [Raw API response](Ppde.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "is-comparison",
      "languages": [
        "python"
      ],
      "message": "The operator 'is' is for reference equality, not value equality! Use `==` instead!",
      "pattern": "$SOMEVAR is \"...\"",
      "severity": "ERROR"
    }
  ]
}
```

## Test case 1

```text
import application
if __name__ is '__main__':
    application.run()
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": null
}
```
