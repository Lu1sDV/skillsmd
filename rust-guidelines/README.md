# rust-guidelines

Compact Rust implementation/review guidance, complementing the repository's
specialized Rust skills rather than replacing their tutorials and playbooks.
[SKILL.md](SKILL.md) routes to six independently readable topic references; none
requires a sibling skill. References are loaded by task, not all at startup.

## Install and use

Copy the complete `rust-guidelines/` directory into your agent's skills directory.
For Claude Code, from this repository checkout, first ensure that no local copy
would be overwritten:

```sh
mkdir -p ~/.claude/skills
cp -r rust-guidelines ~/.claude/skills/
```

Example: “Use rust-guidelines to review this crate's API and failure contracts.”
For a bounded parser, explicitly request its memory profile as part of the task.

## Sources and adaptation

Reviewed on 2026-10-11. Only the two requested source families are included:

- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/about.html),
  including its checklist and topical chapters: API shape, interoperability,
  macros, documentation, and compatibility.
- [auser's Rust Engineering Best Practices gist](https://gist.github.com/auser/c3161f55a8393faa8af5ddda68c6befa):
  selected engineering checks, condensed and qualified rather than adopted as a
  universal project standard.

The references are original summaries and review instructions, not vendored copies.
Source links sit beside each topic. Third-party guides are not embedded; expanding
this source set requires maintainer approval.

Integration decisions: output buffers remain a deliberate reuse/bounded-storage
exception; strict memory profiles are opt-in. Corrected buffer-error semantics,
FFI integer assumptions, allocator-test guarantees, unsafe lint scope, and
unconditional allocation/panic claims are recorded in the relevant reference.
Dependency choices remain project-specific.

This bundle supplies no Rust program, allocator harness, or new dependency.
Validation covers skill metadata, local links, isolated installation, topic routing,
and size; Cargo commands in the references apply to the consumer's Rust project.
