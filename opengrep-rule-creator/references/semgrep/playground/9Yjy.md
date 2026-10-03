# Upstream Semgrep playground: 9Yjy

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [9Yjy](https://semgrep.dev/embed/editor?snippet=9Yjy). [Raw API response](9Yjy.json).

## Rule definition

```json
{
  "rules": [
    {
      "fix-regex": {
        "regex": "(autoescape.*?)False",
        "replacement": "\\1True"
      },
      "id": "docs-context-autoescape-off",
      "languages": [
        "python"
      ],
      "message": "Detected a Context with autoescape diabled. If you are\nrendering any web pages, this exposes your application to cross-site\nscripting (XSS) vulnerabilities. Remove 'autoescape: False' or set it\nto 'True'.\n",
      "metadata": {
        "cwe": "CWE-79: Improper Neutralization of Input During Web Page Generation ('Cross-site Scripting')",
        "owasp": "A7: Cross-site Scripting (XSS)",
        "references": [
          "https://docs.djangoproject.com/en/3.1/ref/settings/#templates",
          "https://docs.djangoproject.com/en/3.1/topics/templates/#django.template.backends.django.DjangoTemplates"
        ]
      },
      "patterns": [
        {
          "pattern-either": [
            {
              "pattern": "{..., \"autoescape\": False, ...}"
            },
            {
              "pattern": "$D[\"autoescape\"] = False"
            }
          ]
        }
      ],
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
from django.shortcuts import render

def xss_path(request, path='default'):
    # ruleid: context-autoescape-off
    env = {'autoescape': False, 'path': path}
    return render(request, 'vulnerable/xss/path.html', env)

def file_access(request):
    msg = request.GET.get('msg', '')
    # ok: context-autoescape-off
    return render(request, 'ok.html',  {'msg': msg})
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
