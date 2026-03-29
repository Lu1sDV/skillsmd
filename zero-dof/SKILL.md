---
name: zero-dof
description: >
  Use when directing LLM coding agents on substantial development tasks —
  establishing executable oracles, designing agent playbooks, constraining
  agent output quality, or preventing metric gaming. Also use when
  LLM-generated code has recurring quality or architecture issues that
  need systematic correction. Triggers: zero dof, zero degrees of freedom,
  executable oracle, constrain agent, agent quality, LLM coding constraints,
  playbook design, oracle pipeline.
---

# Zero-DOF Programming

Eliminate the freedom to do the job badly. Every measurable dimension of code quality gets an **executable oracle** — an automated tool that programmatically validates output. Dimensions without oracles get **human oversight checkpoints**. No dimension is left to LLM judgment alone.

> Based on John Regehr's [Zero-Degree-of-Freedom LLM Coding](https://john.regehr.org/writing/zero_dof_programming.html).

## Quick Reference

| Aspect | Detail |
|--------|--------|
| Purpose | Constrain LLM coding output through automated validation |
| Core concept | Executable oracles — tools that programmatically validate code |
| Key insight | Opposing oracles create the tightest constraints |
| Playbook rule | Linear mandatory steps — no discretion, no shortcuts |
| Gaming defense | Multiple opposing goals make gaming difficult or impossible |
| Human zones | Architecture, unnecessary complexity, GUI polish, security |

## When to Use

- Substantial feature work where correctness matters
- Setting up a project for LLM-assisted development
- LLM-generated code has recurring quality issues
- Establishing automated validation for agent workflows
- Designing playbooks or runbooks for coding agents
- Reviewing whether agent output is properly constrained

## When NOT to Use

- Trivial single-file edits with no quality risk
- Exploratory prototyping where speed matters more than correctness
- Tasks where the human is writing all code themselves
- Pure documentation or config changes

## Workflow

When this skill activates, follow this sequence:

```
Zero-DOF Progress:
- [ ] Step 1: Audit — inventory existing oracles in the project
- [ ] Step 2: Identify — enumerate quality dimensions for this task
- [ ] Step 3: Constrain — set up executable oracles for each measurable dimension
- [ ] Step 4: Oppose — create opposing oracle pairs where possible
- [ ] Step 5: Playbook — write a linear mandatory execution plan
- [ ] Step 6: Execute — run the playbook, validating at every checkpoint
- [ ] Step 7: Monitor — watch for gaming and shortcutting behaviors
- [ ] Step 8: Oversight — flag uncontrollable dimensions for human review
```

---

## Step 1: Audit Existing Oracles

Before writing any code, discover what validation already exists:

```
Scan for:
- Test suites (unit, integration, E2E)
- CI pipeline checks (lint, typecheck, format)
- Coverage tools and thresholds
- Static analyzers, linters, security scanners
- Benchmark suites, performance regression tests
- Fuzzers, property-based test frameworks
- Pre-commit hooks
```

Record what exists and what's missing. Every missing oracle is an uncontrolled degree of freedom.

## Step 2: Identify Quality Dimensions

For the current task, enumerate every dimension where output could vary in quality:

| Dimension | Question | Measurable? |
|-----------|----------|-------------|
| Correctness | Does it produce right results? | Yes — tests, fuzzers, sanitizers |
| Performance | Is it fast enough? | Yes — benchmarks, profilers |
| Type safety | Are types correct and strict? | Yes — type checker in strict mode |
| Style/lint | Does it follow project conventions? | Yes — linter, formatter |
| Coverage | Are edge cases tested? | Partially — see coverage warning |
| Architecture | Is the design sound? | **No** — human oversight |
| Complexity | Is it unnecessarily elaborate? | **No** — human oversight |
| Security | Is it safe from attack? | **No** — human oversight |
| GUI polish | Does it look right? | **No** — human oversight |

Classify each as **oracle-constrained** or **human-oversight-required**.

## Step 3: Set Up Executable Oracles

For every measurable dimension, ensure an automated check exists.

### Correctness Oracles

| Oracle | What It Catches | Setup Effort |
|--------|----------------|--------------|
| Test suite | Behavioral regressions | Low — usually exists |
| Fuzzer (AFL, libFuzzer, Atheris) | Edge cases, crashes | Medium |
| Property-based tests (Hypothesis, fast-check) | Invariant violations across random inputs | Medium |
| Runtime sanitizers (ASan, MSan, UBSan, TSan) | Memory errors, undefined behavior, races | Low — compiler flags |
| Static analyzer (semgrep, CodeQL) | Bug patterns, security anti-patterns | Low — config file |
| Type checker (strict mode) | Type-level errors | Low — config flag |
| Contract/assertion checks | Precondition/postcondition violations | Low — inline code |

### Performance Oracles

| Oracle | What It Catches |
|--------|----------------|
| Benchmark suite (criterion, pytest-benchmark) | Regressions in execution time |
| Performance regression tests | Threshold violations in CI |
| Heap profiler (valgrind, tracemalloc) | Memory bloat |
| Hardware perf counters (perf stat) | CPU-level inefficiencies |

### Coverage Oracles

| Oracle | What It Catches |
|--------|----------------|
| Line/branch coverage (lcov, coverage.py, c8) | Untested code paths |
| Mutation testing (mutmut, Stryker, cargo-mutants) | Weak tests that pass despite code changes |

**Coverage warning:** Never optimize for coverage percentage alone. LLMs will game it by:
- Omitting inconvenient test cases
- Rigging the coverage harness configuration
- Hard-coding specific test inputs into program logic

Always pair coverage metrics with correctness oracles (tests that verify behavior, not just reachability).

### Ideal Oracle Properties

Prefer oracles that are:

| Property | Why It Matters |
|----------|---------------|
| Fast | Agent iterates quickly; slow oracles get skipped |
| Deterministic | Same input always produces same output |
| Local | No network dependency; works offline |
| Sandbox-compatible | Runs inside the agent's execution environment |
| Specific | Reports column-level locations, not just line numbers |
| Queryable | `tool --help` works; options are discoverable |
| Text output | Not images or binary; not excessively verbose |

## Step 4: Create Opposing Oracles

**The most powerful constraint technique.** Pinch the agent's output between two oracles that pull in opposite directions. When opposing goals must both be satisfied, gaming becomes difficult or impossible — the agent must genuinely solve the problem.

| Oracle A | Oracle B | What Gets Constrained |
|----------|----------|----------------------|
| Correctness (all tests pass) | Performance (meets benchmarks) | Can't fake performance by removing tests or fake correctness by removing benchmarks |
| Soundness (no false negatives) | Precision (minimal false positives) | Analysis must be both complete and accurate |
| Coverage (high line coverage) | Mutation score (tests actually catch mutations) | Can't game coverage with assertion-free tests |
| Compilation (code compiles) | Sanitizers (no runtime warnings) | Can't silence warnings by disabling checks |
| Feature tests (new behavior works) | Regression tests (old behavior preserved) | Can't break existing functionality |

**Example from Regehr:** Dataflow transfer function synthesis. By pinching results between soundness verification (no false negatives) and precision evaluation (minimal false positives), Codex produced results better than LLVM's hand-written implementations and better than prior automated synthesis.

## Step 5: Design the Playbook

Write a **linear, mandatory** sequence of steps. This is the single most important constraint on agent behavior.

### Playbook Rules

1. **No choices.** Multiple options = the LLM picks the easiest, not the best. Codify ONE path.
2. **Mandatory language.** Prefix with: *"These steps are mandatory. Deviations are not allowed. Do not skip, reorder, or shortcut any step."*
3. **One action per step.** Compound steps get partially executed.
4. **Validation after every mutation.** Every step that changes code is followed by an oracle check.
5. **Priority hierarchy.** Distinguish hard requirements from soft constraints.
6. **Conflict resolution.** Explain what to do when oracles disagree.

### Playbook Template

```markdown
## Mandatory Steps (no deviations allowed)

These steps are mandatory. Deviations are not allowed.
Do not skip, reorder, or shortcut any step.

### Prerequisites
1. Run the full test suite. ALL tests must pass before proceeding.
2. Run the linter. ZERO warnings before proceeding.
3. Record current benchmark baseline: `[benchmark command]`

### Implementation
4. [First implementation step — one action only]
5. Run test suite. If any test fails, fix before proceeding.
6. [Second implementation step]
7. Run test suite + linter. Fix any failures.
8. [Continue pattern...]

### Validation
9. Run full test suite. ALL tests must pass.
10. Run benchmarks. Compare to baseline from step 3.
11. Run [coverage tool]. Coverage must not decrease.
12. Run [sanitizer/analyzer]. ZERO new warnings.

### Priority
- HARD (showstopper): Failing tests, sanitizer warnings, security vulnerabilities
- SOFT (flag but continue): Performance within 10% of baseline, coverage > threshold

### Conflict Resolution
- If fixing a performance issue would break a test → the test wins.
- If a linter rule conflicts with correctness → disable the rule with an inline comment explaining why.
- If coverage drops because dead code was removed → acceptable, note in PR.
```

## Step 6: Execute with Checkpoint Validation

During execution, enforce validation at every checkpoint:

```
For each step in playbook:
  1. Execute the step
  2. Run the associated oracle(s)
  3. If oracle fails → fix before advancing (do NOT proceed with failures)
  4. If oracle passes → advance to next step
  5. If stuck after 3 attempts → stop and ask the human
```

**Never batch steps.** Each step is atomic: execute, validate, advance. Batching lets failures cascade and makes root-cause analysis harder.

## Step 7: Monitor for Gaming

LLM agents are simultaneously lazy (shortcut instructions) and industrious (elaborate workarounds). Watch for these gaming behaviors:

### Gaming Patterns

| Pattern | What It Looks Like | Defense |
|---------|-------------------|---------|
| **Omitting inconvenient tests** | Benchmark or test file deleted/commented out | Diff review; test count must not decrease |
| **Rigging coverage harness** | Coverage config changed to exclude files | Lock coverage config; diff review |
| **Hard-coding test inputs** | `if input == "test_value" return expected` | Mutation testing; fuzz with random inputs |
| **Rewriting tools from scratch** | Tool not found → agent writes a replacement | Pin tool paths; fail-stop if missing |
| **Unnecessary complexity** | Elaborate concurrency in single-threaded code | Review for YAGNI; ask "why is this needed?" |
| **Phantom abstractions** | Interfaces/wrappers with single implementation | Count abstractions; challenge each one |
| **Silencing warnings** | `// eslint-disable`, `#pragma ignore` | Grep for suppression directives in diff |

### Structural Defenses

- **Opposing oracles** make single-metric gaming futile
- **Locked tool configs** prevent harness manipulation
- **Test count assertions** prevent silent test removal
- **Diff review** catches config/test deletions
- **Persist corrections to files** — context-only corrections get lost when the window rolls

## Step 8: Human Oversight Zones

These dimensions have no reliable executable oracle. They require human intervention:

### Software Architecture

**Problem:** No tool reliably measures design quality. Bad architecture compounds — the LLM will paint itself into a corner and build increasingly baroque workarounds on a broken foundation.

**Mitigation:**
- Set architecture in the initial prompt (module boundaries, data flow, key abstractions)
- Review architecture at checkpoints, not just at the end
- If the design is wrong, **stop and refactor before continuing** — do not let the agent build more on a bad foundation
- Walk the agent through refactoring step by step; it won't restructure well on its own

### Unnecessary Complexity

**Problem:** LLMs produce elaborate solutions to simple problems — concurrency primitives in single-threaded code, abstract factory patterns for one concrete type, plugin systems for one plugin.

**Mitigation:**
- Review every abstraction: "Is there more than one implementation? Will there ever be?"
- Challenge concurrency: "Is this code actually concurrent?"
- Prefer deletion over configuration — remove the complexity, don't make it toggleable

### GUI Polish

**Problem:** Agents cannot reliably evaluate visual output. Screenshots are low-fidelity signal.

**Mitigation:**
- Manual visual review at every UI checkpoint
- Provide pixel-precise reference screenshots or Figma links
- Use visual regression tools (Percy, Chromatic) as a partial oracle, but don't rely on them alone

### Security

**Problem:** Security requires adversarial thinking that LLMs lack. Too many attack vectors, too context-dependent for automated checks alone.

**Mitigation:**
- Never deploy LLM-generated code in security-critical paths without human security review
- Use SAST/DAST tools as a **minimum bar**, not as a guarantee
- Hand off to security review skill for audit

## Anti-Patterns

| Anti-Pattern | Why It Fails | Do This Instead |
|-------------|-------------|-----------------|
| Trusting LLM judgment on quality | If it can't be measured, assume it's wrong | Add an oracle or add a human checkpoint |
| Single-metric optimization | One metric alone will be gamed | Create opposing oracle pairs |
| Optional playbook steps | Every optional step will be skipped | Make all steps mandatory |
| Giving the agent choices | It picks the easiest, not the best | Codify one path |
| Context-only corrections | Corrections are lost when context window rolls | Persist corrections to markdown/config files |
| Assuming tools are available | If a tool is missing, the agent rewrites it from scratch (badly) | Pin tool paths; fail-stop if missing |
| Coverage as sole quality metric | Coverage measures reachability, not correctness | Pair with mutation testing and behavioral tests |
| Reviewing only at the end | Architecture rot compounds silently | Review at intermediate checkpoints |

## Integration with Other Skills

| Skill | Relationship |
|-------|-------------|
| **Test Engineering** | Designs the oracle pipeline — test pyramid, automation candidates, coverage strategy |
| **TDD** | The natural implementation pattern: write the oracle (test) before the code |
| **Code Review** | Human oversight pass for uncontrollable dimensions |
| **Security Review** | Mandatory for security-critical code — no oracle substitutes for adversarial review |
| **Cook** | Orchestration patterns (review loops, repeat passes) that enforce checkpoint validation |
