# Upstream Semgrep playground: jNnn

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [jNnn](https://semgrep.dev/embed/editor?snippet=jNnn). [Raw API response](jNnn.json).

## Rule definition

```json
{
  "rules": [
    {
      "equivalences": [
        {
          "equivalence": "request.$W.get(...) <==> request.$W[...]"
        }
      ],
      "id": "equivalences-example",
      "languages": [
        "python"
      ],
      "message": "Found request data",
      "pattern": "request.POST.get(...)",
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
def route(request):
   # ruleid: equivalences-example
   username = request.POST["username"]
   # ruleid: equivalences-example
   password = request.POST.get("password")
   return auth(username, password)
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": [
    {
      "start": {
        "col": 15,
        "line": 3
      },
      "end": {
        "col": 39,
        "line": 3
      },
      "message": "Found request data"
    },
    {
      "start": {
        "col": 15,
        "line": 5
      },
      "end": {
        "col": 43,
        "line": 5
      },
      "message": "Found request data"
    }
  ]
}
```
