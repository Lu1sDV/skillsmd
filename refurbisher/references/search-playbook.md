# Search playbook

Use this reference when you cannot yet name the problem or identify a productive source.
A search is useful when its answer can change what you implement.

## Move from a symptom to a search hypothesis

Describe the structure using the evidence available. Avoid diagnosing by analogy alone.

| Observed difficulty | A productive question | Possible search direction |
|---|---|---|
| Fairness rules keep accumulating | Which resource should be accounted for, and can work be interrupted? | Network, OS, and storage scheduling |
| A checker is acquiring its own parser and call graph | Who already represents the relationships this check needs? | Compiler tooling and static analysis |
| Each geometric edge case needs another tolerance | Which numerical decision becomes unreliable near the failure? | Robust computational geometry |
| Synchronization error grows with elapsed time | Is the error an offset, drift, or bursty delay? | Audio clocks, communications, control |
| A faster-language port preserves repeated computation | Can the computation be expressed or scheduled differently? | Query engines, numerical methods, incremental computation |
| A new platform repeats familiar infrastructure | Which part of the user's workflow is actually specific? | Existing internal systems, adjacent product categories, standards |

These are hypotheses, not a lookup table. Reject a direction when its assumptions do not
match the task. An established answer to a neighboring problem can still be a poor fit.

## Work outward only as needed

1. **Current execution path.** Read the failing path and its immediate configuration.
   Check what the installed version already supports. Inspect relevant history when it
   explains an intentional tradeoff or previous failed approach.
2. **Problem vocabulary.** Search the relationship, invariant, workload, or failure class.
   Use a paper, specification, or implementation rationale to refine the vocabulary.
3. **Existing mechanisms.** Inspect the smallest plausible implementation boundary.
   Sometimes it is an option in the runtime; sometimes it is an entire existing product.
4. **Transfer conditions.** Read the details that decide fit: input model, guarantees,
   cost units, resource limits, platform assumptions, extension boundaries, and failure
   behavior.
5. **Counterevidence.** Look for a relevant limitation, unsuccessful workload, or
   incompatible operating model. Seek evidence that could overturn the favorite.

Use the user's accessible project and authorized sources. Do not roam through unrelated
repositories or private stores just to increase the candidate list.

## Query shapes

Start from the uncertain property, not an assumed product:

- `<resource> <fairness requirement> variable work cost nonpreemptive`
- `<relationship to analyze> existing program analysis query`
- `<failure class> implementation rationale limitations`
- `<existing dependency> <needed capability> <installed version>`
- `<required behavior> reference implementation conformance tests`
- `<candidate> <constraint that could disqualify it>`

Search results, comparison pages, and practitioner reports are discovery leads. Verify
technical decisions in the relevant implementation, primary documentation, specification,
or reproducible experiment. A source is useful for the claim it establishes; it need not
be an authority on every aspect of the project.

## Inspect enough to choose

Follow the code path that supplies the needed behavior, its tests, and its boundary.
A familiar project name does not establish that a sample, mirror, optional extension,
or commercial edition has the capability needed here.

For a potential source extraction, inspect dependencies beyond calls: initialization,
types, generated data, allocation, concurrency, build flags, and expected environment.
The visible function may be smaller than the mechanism it relies on.

For a potential platform adoption, exercise the user's workflow end to end. Include
installation and operations in the comparison; a small integration diff can hide a large
new service obligation.

For an apparent missing feature, first determine whether the existing feature is being
used correctly. Research may end with a configuration change or deletion.

## When the useful prior art is a small piece of source

Research early when a short function carries a difficult correctness obligation: a
numerical sign must be right near degeneracy, a binary length must never overflow, or a
state transition must preserve ownership through an interruption. If a mature system
has faced that exact obligation, its implementation and accumulated regressions can be
more valuable than a new implementation that passes a few examples.

Find the mechanism before looking for a conveniently sized snippet:

1. Search the invariant, failure class, and likely domain: for example, `combine CRC
   concatenated blocks length` or `robust orientation predicate cancellation`. Follow
   references into canonical repositories, implementation notes, and regression fixes.
2. Use repository code search or `rg` to trace the discovered symbol. Read its actual
   body, callers, helpers, constants, generated tables, initialization, and build guards.
   Do not stop at a wrapper or copy the first plausible search result.
3. Read the tests and relevant history. A linked bug or `git log -S '<symbol>' -- <path>`
   can explain an odd branch or constraint that a clean rewrite would accidentally lose.
   Stable, old code may be the right source; recent activity is not the criterion.
4. Check the target's arithmetic, encoding, memory, concurrency, and input assumptions.
   Reproduce a relevant hard case and compare against an independent reference where
   practical. Keep the upstream cases that test the guarantees being imported.
5. Compare calling the existing API with extracting or porting the complete mechanism.
   Record the exact origin, required notices, and meaningful local changes using the
   project's existing conventions. Do not import the donor's whole subsystem for one
   separable function, or separate a function whose correctness depends on that subsystem.

"Battle-tested" is a reason to inspect specific evidence. It does not transfer correctness
automatically across changed integer widths, precision, ordering, or lifetime rules.

## Bound the investigation

Do not impose a minimum number of candidates, searches, subagents, or benchmarks.
Parallelize only genuinely independent questions that can affect the decision. Stop a
line of inquiry when its remaining uncertainty is immaterial or its assumptions fail.

Keep the next action tied to a decision: what will be inspected, what uncertainty it
resolves, and how either result changes the plan. Report supported conclusions and
remaining limits. Search failure establishes what was not found in the inspected
sources; it does not establish that a solution does not exist.
