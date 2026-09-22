# Custom Semgrep Rule Authoring (TDD)

> When the curated packs (`sinks-catalog.md`) and the PHP mega-pack don't cover a target-specific
> dangerous pattern, **author** a precise rule instead of grepping. Distilled from the Trail of
> Bits `semgrep-rule-creator` skill. This is the *authoring* methodology; running existing packs
> and ingesting hits is `references/methodology/tool-ingest-recipes.md`.

## Normalization — what is config vs what is a finding

A Semgrep rule is **tool configuration**, not a run artifact. **Per-target** authored rules live
under the audit workspace at `.vuln-research/rules/` (the CodeQL data-extension analogue lives at
`.vuln-research/codeql-extensions/`); a rule that proves **generally reusable** graduates into the
committed `semgrep-rules/<lang>/` packs (the PHP mega-pack precedent). Either location is tool
config and is **not** a subagent file-write of audit data. So the authored detection is inspectable
and reused across rounds without a second store, **record each one as a reusable
`agent_observations` row** (orchestrator-flushed — single-writer intact): `obs_kind` (e.g.
`detection_authored`), `target_id`, `rule_id`, the on-disk path, and the wrapper/sink it models.
The next round's prior-fetch then sees what detections already exist for this target.
The rule's *hits*, however, are audit data: the orchestrator runs the rule and ingests each match
as a `candidate` `gr_findings` row (`finding_kind='semgrep_taint'` if `extra.dataflow_trace` is
present, else `semgrep_pattern`) plus candidate `sinks`/`sources`, exactly per the tool-ingest
contract. A green custom rule never inflates the confirmed count — every hit re-enters the
five-gate Confirm as a hypothesis. Tag every authored rule with a `vuln-research-domain` metadata
field so swarm output routes to the right verifier (mega-pack convention).

## When to author vs reuse

- **Reuse a pack** when an official/third-party rule already matches the sink (`p/<lang>`, 0xdea,
  Trail of Bits). Authoring duplicates are waste. For C/C++ targets, consult
  `references/methodology/0xdea-semgrep-rules.md` — 50 rules cover the full native-code bug
  taxonomy; check the cluster-to-rule table there before authoring.
- **Author** when: a project-specific wrapper hides a sink from name matching; a framework's
  custom source/sink isn't modeled; you need a precise taint path the packs over- or under-match.

## Approach: prefer taint mode over pattern matching

Pattern matching finds *syntax*; it can't tell `eval(user_input)` from `eval("literal")`. Taint
mode tracks data flow and only alerts when an untrusted source actually reaches a sink — far fewer
false positives for injection classes. Reach for `mode: taint` first; fall back to pattern
matching only for syntactic checks with no data-flow component, or when taint won't propagate
cleanly. It's fine to switch approaches mid-iteration.

```yaml
rules:
  - id: project-eval-of-request
    languages: [python]
    severity: ERROR
    message: Request data reaches eval() — code execution
    metadata: { vuln-research-domain: rce }
    mode: taint
    pattern-sources:
      - pattern: request.args.get(...)
    pattern-sinks:
      - pattern: eval(...)
    pattern-sanitizers:
      - pattern: ast.literal_eval(...)
```

## The strict TDD loop (do not skip steps)

```
- [ ] 1. Analyze the problem — what exact pattern, which language, what is source/sink/sanitizer
- [ ] 2. Write tests FIRST — a test file with `# ruleid:` (must match) and `# ok:` (must NOT) lines
- [ ] 3. Dump the AST — `semgrep --dump-ast --lang <lang> sample.<ext>` to see how Semgrep parses it
- [ ] 4. Write the rule (taint preferred)
- [ ] 5. Iterate to 100% — `semgrep --test --config <rule-id>.yaml <rule-id>.<ext>` (NOT "most pass")
- [ ] 6. Optimize — remove redundant patterns, re-run --test (no regressions)
- [ ] 7. Final run against the real target; ingest hits as candidates
```

Test annotations live as comments in the test file:

```python
# ruleid: project-eval-of-request
eval(request.args.get('x'))

# ok: project-eval-of-request
eval(ast.literal_eval(request.args.get('x')))   # sanitized
# ok: project-eval-of-request
eval("print('safe')")                            # literal, not tainted
```

Cover edge cases: different coding styles, sanitized paths, safe alternatives, boundary cases.
A rule that only matches the vulnerable case is half-done — verify safe cases do **not** match,
or you ship false positives that poison triage trust.

## Output convention

One YAML file = **one** rule, in a directory named after the rule id:
```
<rule-id>/
├── <rule-id>.yaml
└── <rule-id>.<ext>
```

## Rules to enforce

- **Test-first is mandatory** — never write a rule without its test file.
- **100% pass required** — "most tests pass" is not acceptable.
- **No generic `languages: generic`** when targeting a specific language.
- **`todoruleid:` / `todook:` are forbidden** — no deferred-improvement annotations.
- **Read the docs first** for any non-trivial rule: Semgrep rule syntax, pattern syntax, taint
  overview + advanced, constant propagation, and the ToB Semgrep handbook chapter (WebFetch).

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| `pattern: $FUNC(...)` (matches everything) | Name the dangerous call or use taint source→sink |
| `pattern: os.system("rm " + $VAR)` (one exact shape) | `mode: taint`, sink `os.system(...)` — catches all shapes |
| Tests with only the vulnerable case | Add `# ok:` safe + sanitized cases |
| Optimizing patterns before tests pass | Correct first, optimize last |

## Where this plugs in

- **Phase L3.5 (Tech-Stack Discovery / Sink Loading)** — author target-specific rules after the
  per-language sink files reveal a wrapper the packs miss.
- **Phase L4.5 (SAST FP Calibration)** — `references/phases/sast-triage.md`; a precise custom rule
  is the antidote to a high-FP generic rule (calibrate, then replace).
- Ingest: `references/methodology/tool-ingest-recipes.md` §2.
