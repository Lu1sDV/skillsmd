# Verification without false completion

Use when selecting evidence, interpreting a green suite, resolving oracle changes, or
reviewing a handoff. Testing strategy and language-specific techniques remain project
choices; this reference defines the relationship between an obligation and its evidence.

## Keep three questions separate

1. **What is required?** The owner/adopted contract supplies intent.
2. **What happened?** A command, inspection or observation supplies evidence.
3. **Does that observation support this claim?** This is a reasoning step that can be wrong.

A trace link proves a link exists. A quote match proves text appears. Neither proves the
linked evidence entails the claim. Record the predicate checked, not just “verified”.
A second model can challenge an interpretation but is not a statistically independent oracle.

## Stage determines the expected evidence

| Stage | Useful evidence | Mistake to avoid |
|---|---|---|
| New behavior | Agreed outcome through its consumer boundary, with relevant preserved behavior | An implementation-only helper test as the entire acceptance claim |
| Regression augmentation | A previously true obligation plus a plausible regression the new check detects | Discarding useful tests merely because they pass initially |
| Characterization | Current behavior observed and labelled as such | Treating snapshots as the owner's intended contract |
| Bug discovery | Supported reproduction/finding and scope of uncertainty | Hiding the finding to make the suite green, or silently repairing out-of-scope code |
| Repair | Targeted defect absent afterward; reproduction before/after where available; relevant regressions | A crash from unrelated setup counted as the intended failing-before result |
| Refactoring | Agreed behavior preserved through meaningful consumer checks | Requiring a manufactured red phase |

Do not classify a project-wide strategy task as implementation merely to force it through
this table. Its deliverable and evidence may be an analysis or reviewed plan.

## A useful check must discriminate the relevant wrong outcome

For a doubtful or high-consequence claim, ask what realistic incorrect implementation
would still pass. Use a targeted negative control or known defective state when needed.
Do not require a mutant per test or replace consumer assertions with implementation checks.

Examples:
- A refund cap passes when the handler refuses every refund. A success/progress case
  complements the cap; neither test has to reject every wrong implementation alone.
- Equal retry responses can hide duplicate durable side effects. Count the relevant
  business effects at the durable/provider boundary.
- A test for an empty batch correctly passes a no-op handler. A positive-batch test can
  reject the no-op; judge the obligation and the complementary set, not each test alone.
- Tests asserting private helper names can reject valid solutions. Keep such constraints
  only if the adopted contract actually requires them.

A spec-derived probe can expose an incorrect reference implementation before it judges
other work. Passing that probe does not certify the reference. Use stronger independent
scrutiny for pivotal interpretations, safety claims or author-built scoring references.

## Test changes versus changing the meaning of success

New tests and legitimate expectation updates are ordinary implementation work when they
are authorized. A change in retention policy should change its boundary tests.

Distinguish:
- **Behavior amendment:** the owner changes the obligation; update code and expectations
  together, preserving the rationale and affected work.
- **Instrument repair:** a test, fixture or scorer misapplied an unchanged obligation;
  fix it, retain the earlier result and rerun relevant controls/results.
- **Acceptance weakening:** an assertion, tolerance, skip or called implementation is
  changed so an otherwise unacceptable result now passes; obtain the required decision,
  never conceal it as a test repair.

Protecting test files alone is insufficient: implementation code can make an assertion
vacuous. Inspect the relevant path when the consequence or observed behavior warrants it.
Host restrictions on test/scorer modification can help in unattended or audited work;
they are conditional capabilities, not supplied by this Markdown skill.

## Report the real status

| Observation | What can be claimed |
|---|---|
| Relevant check passed on delivered state | That check's supported obligation, within its scope |
| Check failed | The observed failure and whether it is the expected reproduction or an unexpected defect |
| Check skipped, quarantined or not run | Missing evidence for the affected obligation, unless other evidence establishes it |
| Expected-fail | Expected failure status; not proof the product obligation is satisfied |
| No automated oracle, but required behavior inspected | The specific inspection result and its limits |
| Required external environment unavailable | Reachable evidence plus the unverified external criterion |
| Owner explicitly waived a criterion | A waiver and its scope—not a passing check |

A deliberately expected-failing reproduction may be the correct investigation deliverable
under existing project policy. Report the defect as present. Do not impose a new red,
quarantine or xfail policy on unrelated CI. Newly excluded gating checks must be visible
and traceable to actual authority; existing authorized exclusions need not be renegotiated.

## Delivered-state and integration evidence

Evidence belongs to the contract, implementation and environment it examined. A changed
requirement can invalidate the expectation; a changed implementation can invalidate the
result; a different database isolation level can invalidate a concurrency conclusion.

Rerun affected cheap deterministic checks at the final state. For expensive, external or
manual checks, identify the state and conditions observed and whether relevant changes
occurred afterward. Never cite an earlier complete run as if it covered later edits.

For multiple workers, exercise the shared outcome after integration. For example, a retry
client and deduplicating server can each pass their own tests yet double-charge together.
Use a real compatible boundary for the claim; a mock can support a unit claim, not prove
production persistence, live provider behavior or permission enforcement.

After a review, verify fixes and review materially changed reasoning/callers. A full review
loop ending only when a model has no comments is not a reliable stopping rule. A review
verdict covers its reviewed scope and revision, not every subsequent edit.

## Compact completion form

Use this only when several obligations make a single sentence unclear:

```markdown
Change/stage: <what was authorized and delivered>
| Obligation | Basis | Evidence and observed state | Status / limit |
| ... | ... | command, inspection or end-state result | ... |
Open decisions / defects: <what remains and what it blocks>
Authorization: <unperformed actions such as commit/deploy, where relevant>
```

For a small change: “Help now says 'retrieve'; observed in local help output; no other
behavior changed.” For a partial implementation: state exactly which acceptance remains
unverified. For an investigation: “Defect reproduced; no repair authorized” can be complete.
Neither verbosity nor a green aggregate is a substitute for the actual completion claim.
