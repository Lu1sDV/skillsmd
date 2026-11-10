# Embedded deep-module design and active domain modeling

## Vocabulary and tests

- **Module:** coherent function, class, package or cross-layer slice with behavior and an **interface**.
- **Interface:** *all* caller obligations: methods/data, invariants, ordering, errors, configuration, effects, resources, compatibility and performance.
- **Implementation:** behavior and policy hidden from callers. **Depth:** useful capability/knowledge hidden relative to interface burden, not a lines-of-code ratio.
- **Seam:** a location where behavior can change without editing that location's callers. **Adapter:** a concrete implementation at a seam; one or two adapters alone cannot justify a seam.
- **Leverage:** useful decisions reused across callers. **Locality:** changes, failures, knowledge and verification concentrated in their proper owner.

Use precise vocabulary without suppressing valid HTTP API or DDD terminology or literal project identifiers. **Deletion test:** what necessary behavior, policy, isolation, knowledge or safety guarantee would callers have to replace if this module disappeared? Thin adapters may be essential. Ask why this responsibility belongs together before merging modules with different lifecycles. Prefer common behavioral tests through meaningful external interfaces, but retain targeted internal tests that protect important invariants; fewer methods do not imply fewer behaviors. Effects are legitimate: expose failure, transaction, retry and idempotency obligations explicitly.

## Active domain-modeling procedure

**Passive reading is not active modeling.** Before recommending a seam, establish the relevant domain terms, identities, ownership, states, lifecycle rules and invariant-bearing scenarios. During the selected-design conversation:

1. **Read conventions:** `GLOSSARY.md` and `GLOSSARY-MAP.md` if present; honor existing project `CONTEXT.md`/`CONTEXT-MAP.md` if that is its glossary convention. In mapped multi-context repositories, use the specific context's glossary and ADR directory; never create competing glossary conventions or collapse genuinely different meanings across contexts.
2. **Challenge meaning:** flag an overloaded or conflicting word immediately; propose precise alternatives and ask for a choice only when business meaning cannot be established from code/docs. Contrast any claimed rule with actual code and tests; surface disagreements rather than silently treating either as true.
3. **Stress-test:** use a concrete normal and edge-case scenario to check identities, ownership, invariant boundaries, transitions, and whether two similarly named concepts really coincide. If the scenario changes architecture, revisit the affected candidate evidence.
4. **Record only settled domain language, with consent:** keep the glossary *only* for canonical domain concepts. Each entry defines what the thing **is** in 1–2 sentences; `_Avoid_` lists rejected synonyms. Exclude general programming terms, implementation decisions, meeting notes and running specs. Create a missing glossary lazily when the first genuine term is resolved. If permission to maintain docs was granted for this discussion, update each confirmed term **inline**, not as a speculative batch; otherwise offer a proposed patch without writing.
5. **Offer an ADR only if all three hold:** (a) the decision is costly to reverse; (b) future readers would find it surprising without context; (c) genuine alternatives were considered. Ask before writing, follow the repository's existing ADR format/path, and capture *context, decision, reason and meaningful alternatives*, briefly. A temporary priority or obvious/easily reversible choice is not an ADR. A rejected candidate warrants one only when its durable rationale would prevent future reviewers from suggesting it again.

**Stage separation:** G0–G4 review is read-only. At G5, the user chooses a candidate and may authorize glossary maintenance without authorizing implementation. An ADR still requires explicit acceptance. Don't change code/tests/deployments without separate approval.

## Interface alternatives and validation

For a consequential design, develop **at least two materially different interface/seam directions** from the same caller scenarios and constraints, plus unchanged/local fix when credible. You may use independent subagents if available and worthwhile, but never depend on them. Evaluate each under common, invalid, failure/retry, state/concurrency, version, caller-change and deployment/rollback scenarios as applicable. Judge depth, locality, leverage, effect semantics, security, compatibility, operational cost and test fidelity; no imaginary benchmarks.

**Dependency fidelity:** deterministic code usually deserves real tests; local substitutes (DB/filesystem) may differ in locking/timing; owned remote dependencies need contracts/version-skew checks; external providers need careful contract or test-environment validation. A fake does not prove live behavior. Choose a reversible migration slice, establish baseline outcomes, retain existing effective tests until equivalence is demonstrated, and define rollback/telemetry. The conversation ends with an agreed decision, remaining unknowns and verification plan—not automatic implementation.