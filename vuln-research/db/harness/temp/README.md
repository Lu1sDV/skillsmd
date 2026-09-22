<!-- README.md — declares the contract for the harness `temp/` scratchpad directory. -->
<!-- Exists so anyone (human or agent) opening this folder knows it is throwaway-by-default and how to graduate code out of it. -->
<!-- How: drop ad-hoc analytics / one-off migrations / exploratory scripts here with a 3-line header; when a tool stabilises, move it up into `db/harness/` proper and add tests. -->

# `db/harness/temp/` — scratchpad

On-demand expansion area for the vuln-research DuckDB harness.

## What goes here

- One-off analytics scripts (Go, Python, SQL) that hit the audit DB.
- Custom queries the orchestrator does not need to embed.
- Experimental migrations / column probes before they are committed to `../schema.sql`.
- Quick repro scripts for a specific finding or bypass.

## What does NOT go here

- Anything imported by `vrdb.go`, `put.go`, or `cmd/vrdb/main.go`.
- Anything other code depends on for correctness.
- Anything covered by tests in `../vrdb_test.go`.

## Rules

1. Every file gets a **3-line header** describing *what*, *why*, *how + when*.
2. Files in `temp/` are throwaway: no API stability, no compatibility guarantee, no test requirement.
3. If a script proves useful, promote it: move it up into `db/harness/`, add a test, and remove the copy here.
4. Do not put credentials, real exploit payloads, or anything that should not survive a `git clean -fdx`.
