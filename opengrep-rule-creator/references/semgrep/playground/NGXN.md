# Upstream Semgrep playground: NGXN

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [NGXN](https://semgrep.dev/embed/editor?snippet=NGXN). [Raw API response](NGXN.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "docs-invalid-port",
      "languages": [
        "generic"
      ],
      "message": "Detected an invalid port number. Valid ports are 0 through 65535.",
      "metadata": {
        "references": [
          "https://github.com/hadolint/hadolint/wiki/DL3011"
        ],
        "source-rule-url": "https://github.com/hadolint/hadolint/wiki/DL3011"
      },
      "paths": {
        "include": [
          "*dockerfile*",
          "*Dockerfile*"
        ]
      },
      "patterns": [
        {
          "pattern-either": [
            {
              "patterns": [
                {
                  "pattern": "EXPOSE $PORT"
                },
                {
                  "metavariable-comparison": {
                    "comparison": "$PORT > 65535",
                    "metavariable": "$PORT"
                  }
                }
              ]
            },
            {
              "pattern": "EXPOSE -$PORT"
            }
          ]
        }
      ],
      "severity": "ERROR"
    }
  ]
}
```

## Test case 1

```text
FROM busybox

# ruleid: invalid-port
EXPOSE 65536

# ok: invalid-port
EXPOSE 65535
```

Case metadata:

```json
{
  "filename": null,
  "language": "generic",
  "highlights": []
}
```
