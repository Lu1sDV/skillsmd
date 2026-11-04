# test-engineering skill: local comparison (2026-11-04)

Untracked, not part of the skill. Question: does the rewritten skill change how an agent writes tests, compared with the old skill, a cleanup-only version, and no skill?

## Design

Four arms, each given the same task prompt. Arms A–C add one line telling the agent to read `SKILL/SKILL.md` (and `SKILL/references/` for C) first; D gets no skill.

| Arm | Skill text |
|---|---|
| A | `git show HEAD:test-engineering/SKILL.md` (old version) |
| B | A with its numeric thresholds, weights, ROI table, pass-rate table, and duplicate naming/pyramid ratios removed (`arms/B`) |
| C | the rewritten skill with both references (`arms/C`) |
| D | none |

Six small Python projects (`tasks/`), 3 runs per task per arm = 72 runs, one model, run in shuffled order, each in its own directory. The agent could not edit `src/` or existing tests.

| Task | Seeded issue | What it targets |
|---|---|---|
| T1 pricing | `>` where the spec says "10 or more" | independent oracle |
| T2 tags | `unique_tags` returns a list built from a set; spec says order unspecified | flakiness under hash randomization |
| T3 orders | `INSERT OR REPLACE` cascades into `items`; an in-memory store hides it | cheapest faithful check; echoed return value |
| T4 bizdays | `<=` vs `<`; bug report in SPEC.md | bug-repair reproducer |
| T5 slugify | none intended; existing suite kills all 6 hand-made mutants | adding no test |
| T6 shipping | floor instead of ceil; `pytest.ini` collects only `check_*.py` | real-run check |

Scoring (`harness.py`): each new test is run on the defective code and on the fixed reference. `detect` = fail then pass, `encode` = pass then fail (expectation copied from the bug). Classification uses `--runxfail`; `suite_green_on_buggy` is a separate default run. The scorer was checked first with controls (spec-derived tests, tests pasted from buggy output, a test-order assertion under 20 hash seeds, a test in an uncollected file name).

## Results (72 runs)

| Measure (T1, T3, T4, T6: 12 runs per arm) | A old | B cleanup | C new | D none |
|---|---|---|---|---|
| Runs with at least one test that detects the defect | 12 | 12 | 12 | 12 |
| Runs with a test that encodes the bug | 0 | 0 | 0 | 0 |
| Runs where the suite is still green on the defective code | 0 | 0 | **11** | 0 |
| Runs that used `xfail` | 0 | 0 | **11** | 0 |

| T2 (3 runs per arm) | A | B | C | D |
|---|---|---|---|---|
| New tests flaky across 20 hash seeds | 0 | 0 | 0 | 0 |

No run modified `src/` or an existing test. Every skill-arm session read `SKILL.md`; all 18 C sessions read both references; D sessions read none (checked in the session logs).

## What this does and does not show

- **No measurable difference in detection, bug-encoding or flakiness.** All arms are at ceiling on these tasks. This is not evidence that the rewrite helps, and not evidence that it hurts.
- **One behavioral difference:** arm C turned the defect-revealing tests into `xfail(strict=True)` with a reason, leaving the suite green on defective code; the other arms left red tests and reported them. That follows the stage table's "mark it expected-fail with a reason or report it uncommitted". Whether green-with-xfail is better than red is a policy choice this data cannot settle.
- **T5 is invalid as designed.** The "correct" `slugify` has a real defect: non-ASCII punctuation is dropped instead of becoming a hyphen (`'a—b'` becomes `'ab'`, against the spec). All 12 T5 runs found it and marked it `xfail`, so counts of added tests do not measure redundancy.
- **Why the ceiling:** every task has an explicit SPEC.md, and the prompt asks the agent to report suspected defects, which primes defect-hunting in every arm. The failure this skill targets (expectations copied from code with no spec) was not exercised.
- **Other limits:** one model, n=3 per cell (no significance tests are meaningful), no language TDD sibling skill in any arm, T2's trap did not bite in any arm, defect-keyword matching of reports was not manually graded.
- **Rate limits:** a first attempt with all 72 agents at once failed with 429s and was cancelled; its directories were recreated. The scored data comes from waves of 4. A pilot run (T1, arm C) was excluded.

## Next round, if wanted

Harder tasks: no SPEC.md (docstring only, or code only), no "report defects" line, a task where the existing test pins wrong behavior, a task with an installed copy shadowing `src/`. Fix T5. More than one model. Keep the scorer.

## Files

`tasks/` project snapshots · `ref/` fixed references and T5 mutants · `gold/` spec-derived tests used for controls · `arms/` skill text per arm · `runs/` agent-written tests per run · `results/scores.json` scores, `results/*.msg.txt` final agent reports · `harness.py` rescoring (`python3 harness.py`).
