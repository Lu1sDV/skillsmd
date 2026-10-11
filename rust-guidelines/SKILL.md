---
name: rust-guidelines
description: >
  Use when writing, refactoring, or reviewing Rust against API and engineering
  guidelines, auditing crate readiness, or defining ownership, error, safety,
  and allocation contracts. Covers naming, public APIs, interoperability,
  documentation, macros, and verification. Not a Rust tutorial or profiling playbook.
---

# Rust Guidelines

Apply an idiomatic API baseline plus requirement-driven engineering checks.
Correctness and soundness are mandatory; design recommendations are defaults,
not reasons to break a public contract.

## Workflow

1. Read repository instructions, affected callers, and Cargo configuration.
   Identify crate versus application, edition, minimum supported Rust version
   (MSRV), targets, features, and explicit resource or compatibility promises.
2. Open only references implicated by the task. For a broad audit, scope coverage
   using the table first. Do not preload the bundle or routinely fetch upstream.
3. Make the smallest contract-preserving change. Separate defects, contract
   violations, and optional improvements. Do not add dependencies, upgrade the
   MSRV, or impose heapless execution merely to satisfy a checklist.
4. Verify affected behavior and callers with the project's checks. Record
   configurations, results, and unexecuted checks.

## Load by topic

| Task or question | Read |
|---|---|
| Naming, ownership, types, builders, ergonomics, evolution | [API shape](references/api-shape.md) |
| Standard traits, conversions, errors, features, Send/Sync | [Interoperability](references/interoperability.md) |
| Validation, panics, output-buffer errors, unsafe or FFI | [Correctness](references/correctness.md) |
| Memory profiles, bounded work, performance claims | [Memory and performance](references/memory-performance.md) |
| Public Rust macro design or review | [Macros](references/macros.md) |
| Rustdoc, releases, Cargo checks, lints, verification | [Documentation and tooling](references/documentation-tooling.md) |

## Decision rules

Make ownership, mutation, failure, blocking, and resource obligations explicit.
Return ordinary values unless caller-owned storage has a real purpose; an owned
result is not automatically an allocation. Use allocation-conscious code unless
stricter requirements are established. A project policy is not a language guarantee.

## Completion

For reviews, report a location, observable consequence, minimal correction, and
verification status for each actionable finding; omit speculation. For changes,
summarize behavior, compatibility effects, checks, and limitations. Performance
and allocation guarantees must not exceed their evidence.

[Sources and adaptation](README.md) is maintainer context, not a prerequisite read.
