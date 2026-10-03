# Upstream Semgrep playground: ZoA4

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [ZoA4](https://semgrep.dev/embed/editor?snippet=ZoA4). [Raw API response](ZoA4.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "docs-use-re2",
      "languages": [
        "python"
      ],
      "message": "The default 're' module is vulnerable to denial of services. Use 're2' instead.",
      "pattern": "import re",
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
import re

m = re.search(get_regex(), 'abcdef')
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
