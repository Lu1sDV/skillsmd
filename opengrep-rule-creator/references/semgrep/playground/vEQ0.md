# Upstream Semgrep playground: vEQ0

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [vEQ0](https://semgrep.dev/embed/editor?snippet=vEQ0). [Raw API response](vEQ0.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "docs-deprecated-api",
      "pattern": "django.utils.http.is_safe_url(...)",
      "message": "is_safe_url() is deprecated as of Django 4.0. Use url_has_allowed_host_and_scheme() instead.",
      "severity": "WARNING",
      "languages": [
        "python"
      ]
    }
  ]
}
```

## Test case 1

```text
from django.utils.http import is_safe_url
# ruleid: deprecated-api
is_safe_url("https://semgrep.dev")
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
