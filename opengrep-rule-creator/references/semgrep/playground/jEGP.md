# Upstream Semgrep playground: jEGP

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [jEGP](https://semgrep.dev/embed/editor?snippet=jEGP). [Raw API response](jEGP.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "docs-express-sandbox-code-injection",
      "mode": "taint",
      "pattern-sanitizers": [
        {
          "pattern": "sanitizing_func(...)"
        }
      ],
      "pattern-sinks": [
        {
          "patterns": [
            {
              "pattern-inside": "$SANDBOX = require('sandbox');\n...\n"
            },
            {
              "pattern": "new $SANDBOX(...).run(...)"
            }
          ]
        }
      ],
      "pattern-sources": [
        {
          "patterns": [
            {
              "pattern-inside": "function ... ($REQ, $RES) {...}"
            },
            {
              "pattern-either": [
                {
                  "pattern": "$REQ.$QUERY"
                },
                {
                  "pattern": "$REQ.$BODY.$PARAM"
                }
              ]
            }
          ]
        }
      ],
      "languages": [
        "typescript"
      ],
      "message": "Make sure that unverified user data can not reach `sandbox`.",
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
const Sandbox = require('sandbox');
const express = require('express');
const app = express();
const port = 3000;

const cb = () => {
    console.log('ok')
}

app.get('/', (req, res) => res.send('Hello World!'))

app.get('/test3', function (req, res) {
    // ruleid:express-sandbox-code-injection
    new Sandbox().run(`lol(${req.query.userInput})`, cb);
    res.send('Hello world');
})


app.get('/test3', function (req, res) {
    // ok:express-sandbox-code-injection
    new Sandbox().run(`lol(${sanitizing_func(req.query.userInput)})`, cb);
    res.send('Hello world');
})

app.get('/ok-test1', function (req, res) {
    // ok:express-sandbox-code-injection
    const s = new Sandbox();
    s.run('lol("hi")', cb);
    res.send('Hello world');
})

app.get('/ok-test2', function (req, res) {
    // ok:express-sandbox-code-injection
    var code = 'lol("hi")'
    const s = new Sandbox().run(code, cb);
    res.send('Hello world');
})

app.get('/test1', function (req, res) {
    // ok:express-sandbox-code-injection
    const s = new Sandbox();
    s.run(`lol("hi")`, cb);
    res.send('Hello world');
})

app.listen(port, () => console.log(`Example app listening at http://localhost:${port}`))

```

Case metadata:

```json
{
  "filename": null,
  "language": "ts",
  "highlights": []
}
```
