# Upstream Semgrep playground: w6Qx

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [w6Qx](https://semgrep.dev/embed/editor?snippet=w6Qx). [Raw API response](w6Qx.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "go-command-injection",
      "mode": "taint",
      "pattern-sources": [
        {
          "pattern": "($REQ : *http.Request)\n"
        }
      ],
      "pattern-sinks": [
        {
          "patterns": [
            {
              "pattern-either": [
                {
                  "pattern-inside": "syscall.Exec($PATH, $ARGS, ...)"
                },
                {
                  "pattern-inside": "syscall.ForkExec($PATH, $ARGS, ...)"
                },
                {
                  "pattern-inside": "&exec.Cmd {$PATH, $ARGS, ...}\n"
                },
                {
                  "patterns": [
                    {
                      "pattern-inside": "&exec.Cmd { ... }\n"
                    },
                    {
                      "pattern-either": [
                        {
                          "pattern": "Path: $PATH\n"
                        },
                        {
                          "pattern": "Args: $ARGS\n"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "focus-metavariable": [
                "$PATH",
                "$ARGS"
              ]
            }
          ]
        }
      ],
      "message": "Possible command injection vulnerability",
      "languages": [
        "go"
      ],
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
package main

import (
    "fmt"
    "os/exec"
    "io"
    "os"
    "net/http"
)

type App struct{}

func (a *App) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    username, _, _ := r.BasicAuth()

    cmd := &exec.Cmd {
        // ruleid: go-command-injection
        Path: username,
        Args: []string{ "tr", "--help" },
        Stdout: os.Stdout,
        Stderr: os.Stderr,
    }

    cmd2 := &exec.Cmd {
        Path: "/usr/bin/tr",
        // ruleid: go-command-injection
        Args: []string{ username, "--help" },
        Stdout: os.Stdout,
        Stderr: os.Stderr,
    }
    // ruleid: go-command-injection
    syscall.Exec("ls", []string{username, "-l", "-h"})

    // ruleid: go-command-injection
    syscall.Exec(username, []string{"-a", "-l", "-h"})
}

```

Case metadata:

```json
{
  "filename": null,
  "language": "go",
  "highlights": []
}
```
