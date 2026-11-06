# test-engineering skill

Claude Code skill for deciding which evidence a change needs and whether the tests provide it: test strategy, review of AI-generated tests, flaky-test triage, and reading coverage and mutation results. Framework-agnostic.

## What it covers

- Task stage (regression augmentation, bug discovery, bug repair, characterization) and what a new failing test means in each
- Test-quality gate: independent oracles, real runs, detection evidence, no change just to get green, cheapest faithful check, which new tests to keep
- Security TDD integrated into ordinary test planning and red–green–refactor: security invariants, negative/abuse cases, real-boundary checks, permanent vulnerability regressions and risk-based CI gates
- Safe execution, versioned OWASP/NIST traceability, scanner findings kept separate from behavioral evidence, and explicit residual risk
- Coverage versus adequacy, mutation and fault injection
- Flaky-test procedure
- Strategy workflow, automate-or-manual questions, output template

Language-specific test writing is out of scope: use `go-tdd`, `python-tdd`, `rust-tdd` or `typescript-tooling-tdd`. Fuzzing a target: `fuzzgpt`.

## Layout

```
test-engineering/
├── SKILL.md                      router, task stages, quality gate, strategy workflow
└── references/
    ├── test-review.md            buggy/fixed outcomes, oracles, assertion strength, doubles, properties, mutation
    ├── flaky-tests.md            policy, triggers, procedure, causes
    └── security-tdd.md           threats, invariants, TDD, test levels, safe execution, gates, evidence, examples, standards
```

## Install

Copy `test-engineering/` into `~/.claude/skills/`.

Or install via:

```bash
npx skills add Lu1sDV/skillsmd
```

## Decisions

| Decision | Rationale |
|---|---|
| Delete fixed pyramid ratios, coverage targets, the pass-rate and flake-rate thresholds, the selection-matrix weights and the ROI multipliers | None had a source, the old file contradicted itself (60/30/10 at one place, 70/20/10 at another; two naming conventions), and `go-tdd`, `python-tdd`, `rust-tdd` and `typescript-tooling-tdd` already reject numeric targets and fixed ratios |
| Replace the matrix and ROI table with four questions (consequence, recurrence, existing evidence, cost to build/run/diagnose/maintain) | Keeps the cost-benefit reasoning without invented numbers |
| Make the task stage the first decision | A rule that drops first-run failures is correct for regression augmentation and destroys findings in bug discovery. TestGen-LLM states this scope itself |
| Oracle independence, with characterization tests as a labelled exception | LLM-written assertions mostly capture actual behavior. Not adopted as "specification before reading code": the Spec-Driven Test Generation study (arXiv 2608.17177) gave the agent the fixed source and built specs from code plus docs, tests and callers |
| Detection evidence only when claiming detection or calling an assertion weak | Requiring every test to prove it can fail would produce redundant assertions. The `assertion-quality` skill's rule is to name a wrong result before calling an assertion weak |
| Evaluate generated tests on all four buggy/fixed outcomes | "Passes on the buggy version" merges "does not distinguish this defect" with "encodes the bug" |
| Test doubles: default real, named exceptions, no strict ranking | A stub injects rare faults and a mock fits "sent at most once". A strict real > fake > stub > mock ladder is wrong for those cases |
| Rejected: universal mutation, universal reruns, an above-unit minimum, a "must pass first run" retention filter, one assertion per test | No source supports them as universal rules, and each adds work without a stated trigger. Flaky checks and mutation have named triggers; one behavior per test is the better rule than one assertion |
| Kept exploratory testing as a bounded charter | An agent can state expected result, risk, entrypoint, isolation and exit condition and turn confirmed defects into regression checks |
| Treat security tests as first-class citizens across test layers | Security failures belong in the same risk-based strategy and quality gate as functional failures; tool-specific scanner configuration is separate from security verification strategy |
| Make security relevance mandatory to assess; select individual tests by actual threats | Avoids both optional end-of-development scanning and blanket security checklists or redundant test quotas |
| Keep Security TDD details in a linked reference, with planning, generation and reporting hooks in the entrypoint | Makes the workflow reachable without loading detailed security guidance for unrelated testing tasks; language skills retain runner and fixture ownership |
| Use SAMM for the testing lifecycle, ASVS for web requirements, WSTG for techniques, Cheat Sheets for controls and NIST for process/complementary verification | Reuses established guidance without claiming that the standards prescribe this exact TDD cycle; ASVS L2 is a risk-adjustable skill default |
| Pin reference baselines and verify requirement IDs; do not repeat an undated “latest stable” claim | Requirement numbering and release status change; coverage is not compliance or proof of security |
| Rejected from the research corpus: framework API recipes, TDD discipline variants, product-specific workflows, vendor marketing, fuzzing handbooks, accessibility/visual/mobile/web3 niches | Duplicated by the language skills, tied to one product, or unactionable as a check |
| Description triggers on test review and flaky triage; entrypoint tells the model to load the language TDD skill first | The four language skills scope test-engineering to system-wide strategy; this version also adds language-neutral review and flaky policy, so the overlap needs an explicit tie-break |

## Sources

Checked against the paper's own text or abstract while writing this version:

- Mathews and Nagappan, [Design choices made by LLM-based test generators prevent them from finding bugs](https://arxiv.org/abs/2412.14137), full text: four-outcome table, 287 samples
- Alshahwan et al., [Automated Unit Test Improvement using LLMs at Meta](https://arxiv.org/abs/2402.09171), full text: filter scope, 75/57/25% are shares of test classes
- Konstantinou et al., [Can we find bugs using LLM-generated oracles?](https://arxiv.org/abs/2410.21136): oracles mostly capture actual behavior
- Berndt et al., [On the Flakiness of LLM-Generated Tests for Industrial and Open-Source Database Management Systems](https://arxiv.org/abs/2601.08998): 63% unordered collections, flakiness transferred through prompt context
- Gruber et al., [An Empirical Study of Flaky Tests in Python](https://arxiv.org/abs/2101.09077), PDF: 59%/28% causes; medians of 170 reruns (non-order-dependent) and 31 random-order runs for 95% confidence; 10-rerun detection ceilings
- Banik et al., [All Smoke, No Alarm](https://arxiv.org/abs/2606.18168): 80.2% of agent-authored test patches had weak or no oracle signals
- Tufano et al., [Spec-Driven Test Generation](https://arxiv.org/abs/2608.17177), full text: method and setup
- Konstantinou et al., [How well LLM-based test generation techniques perform with newer LLM versions?](https://arxiv.org/abs/2601.09695): every approach, including the plain baseline, used up to five execution-feedback repair iterations
- Al-Ahmad et al., [class-level LLM test suites](https://arxiv.org/abs/2609.24341): coverage near its ceiling, model choice before prompt tuning

Taken from a research corpus's per-skill rule extracts and article summaries (the corpus is kept locally outside the skill directory and is not published), not re-read from the original files: the `test-guard`, `assertion-quality`, `writing-unit-tests`, `testing-changes`, `property-based-testing`, `test-collaboration` and `rea-ci-tests-audit` skills it describes; the Tanzu and Enterprise Craftsmanship test-double articles; the coverage-versus-mutation "Mind the Gap" paper. Rules drawn from these are phrased as defaults, not universal requirements.

Security guidance and primary sources are linked in [Security TDD — Reference policy](references/security-tdd.md#reference-policy). ASVS 5.0.0, WSTG 4.2 and SSDF 1.1 were checked against official release/publication pages on 2026-11-06; they are explicit baselines, not self-updating “latest” claims. The operational TDD cycle is this skill's integration of the guidance, not a claim that each standard mandates TDD.

## Validation status

Security TDD update (2026-11-06): the five static skill checks passed without findings or parser warnings; local skill-document links/anchors, code fences and table-row delimiters passed structural checks. A prompt smoke using the entrypoint and security reference exercised six planning scenarios: cross-tenant invoice access, reset-token replay, concurrent voucher redemption, documentation-only change, a failing mandatory security gate, and unsafe third-party reproduction. Outputs selected real-boundary checks, preserved blocking failures, avoided unnecessary tests for the documentation-only case, and did not invent execution evidence. This is guidance smoke evidence, not application-security verification, compliance evidence or a measured agent-effectiveness comparison.

Agent-effectiveness comparison not measured. The earlier version is in git history (`git show HEAD:test-engineering/SKILL.md`). Suggested comparison before treating this as an improvement: the earlier version, a cleanup-only version (contradictory and unsourced numbers removed), and this version, on tasks that include correct code, a wrongly-pinned expectation, an integration failure hidden by a stub, behavior already covered, and a blocked environment. Score defective/fixed outcomes separately, repeat agent runs, and record cost.

## Credits

Merged from community skills:
- [testing-strategies](https://github.com/1Mangesh1/dev-skills-collection/tree/main/skills/testing-strategies) by @1Mangesh1
- [automation-strategy](https://github.com/melodic-software/claude-code-plugins/tree/main/plugins/test-strategy/skills/automation-strategy) by @melodic-software

## Triggers

Activates when designing test strategies, deciding which tests a change needs, applying Security TDD, planning security regression or abuse tests, reviewing or generating tests for weak or self-confirming assertions, triaging flaky tests, or interpreting coverage and mutation results.
