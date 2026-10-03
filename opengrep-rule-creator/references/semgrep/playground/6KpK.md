# Upstream Semgrep playground: 6KpK

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [6KpK](https://semgrep.dev/embed/editor?snippet=6KpK). [Raw API response](6KpK.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "docs-metavariable-message-example",
      "pattern": "$MODEL.set_password(...)",
      "message": "Setting a password on $MODEL",
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
user.set_password(new_password)
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
