# Upstream Semgrep playground: zEXn

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [zEXn](https://semgrep.dev/embed/editor?snippet=zEXn). [Raw API response](zEXn.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "docs-react-dangerouslysetinnerhtml",
      "languages": [
        "typescript",
        "javascript"
      ],
      "message": "Setting HTML from code is risky because it\u2019s easy to inadvertently expose your users to a cross-site scripting (XSS) attack.\n",
      "pattern-either": [
        {
          "pattern": "<$X dangerouslySetInnerHTML=... />\n"
        },
        {
          "pattern": "{dangerouslySetInnerHTML: ...}\n"
        }
      ],
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
function TestComponent() {
    // ruleid:react-dangerouslysetinnerhtml
    return <div dangerouslySetInnerHTML={createMarkup()} />;
}

function OkComponent() {
    // OK
    return {__html: 'Первый &middot; Второй'};
}


```

Case metadata:

```json
{
  "filename": null,
  "language": "ts",
  "highlights": []
}
```
