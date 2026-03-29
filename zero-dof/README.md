# zero-dof

Zero Degrees of Freedom programming for LLM coding agents — constrain every measurable dimension of code quality with executable oracles, eliminate agent discretion through mandatory playbooks, and flag uncontrollable dimensions for human oversight.

Based on John Regehr's [Zero-Degree-of-Freedom LLM Coding](https://john.regehr.org/writing/zero_dof_programming.html).

## Installation

### Claude Code Plugin (recommended)

```
/plugin install zero-dof@Lu1sDV/skillsmd
```

Or browse the marketplace:

```
/plugin marketplace add Lu1sDV/skillsmd
```

Then select **Browse and install plugins** > **Lu1sDV/skillsmd** > **zero-dof**.

### Manual install

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/zero-dof ~/.claude/skills/
```

### npx

```bash
npx skills add Lu1sDV/skillsmd
```

### Verify

In Claude Code:

```
What skills are available?
```

Or mention it directly:

```
Use the zero-dof skill to set up oracle constraints for this project
```

## What It Does

When activated, the skill guides Claude through an 8-step workflow:

1. **Audit** existing oracles in the project (tests, linters, CI checks)
2. **Identify** quality dimensions for the current task
3. **Constrain** each measurable dimension with an executable oracle
4. **Oppose** — create opposing oracle pairs (correctness vs performance, soundness vs precision)
5. **Playbook** — write a linear mandatory execution plan with no agent discretion
6. **Execute** with checkpoint validation after every mutation
7. **Monitor** for gaming behaviors (test deletion, coverage rigging, hard-coded inputs)
8. **Oversight** — flag architecture, complexity, GUI, and security for human review

## Key Concepts

- **Executable oracle**: Any automated tool that validates a dimension of code quality (test suite, fuzzer, linter, benchmark, sanitizer)
- **Opposing oracles**: Two oracles that pull in opposite directions, making gaming impossible (e.g., all tests must pass AND benchmarks must be met)
- **Mandatory playbook**: Linear sequence of steps with no choices, no optional steps, and validation after every mutation
- **Human oversight zones**: Dimensions with no reliable oracle (architecture, complexity, GUI polish, security) that require human checkpoints

## When to Use

- Substantial feature work where correctness matters
- Setting up a project for LLM-assisted development
- LLM-generated code has recurring quality issues
- Designing playbooks or runbooks for coding agents
