# Upstream Semgrep playground: wEQd

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [wEQd](https://semgrep.dev/embed/editor?snippet=wEQd). [Raw API response](wEQd.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "docs-missing-auth-annotation",
      "patterns": [
        {
          "pattern": "@$APP.route(...)\ndef $FUNC(...):\n  ...\n"
        },
        {
          "pattern-not-inside": "@$APP.route(...)\n@login_required\ndef $FUNC(...):\n  ...\n"
        }
      ],
      "message": "Route function \"$FUNC\" is missing a login annotation",
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
import flask
app = flask.Flask()

@app.route("/echo/<msg>", methods=["POST"])
@login_required
def echo(msg):
    return msg

@app.route("/reverse/<msg>")
def echo_reverse(msg):
    return msg.reverse()
```

Case metadata:

```json
{
  "filename": null,
  "language": "python",
  "highlights": []
}
```
