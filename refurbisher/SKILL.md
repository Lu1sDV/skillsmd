---
name: refurbisher
description: >
  Use before committing to a substantial subsystem, dependency, rewrite, or growing
  series of workarounds, or a small critical function whose correctness is harder
  than its size suggests, when existing capabilities or mature solutions could
  reduce the work. Investigate the
  uncertain premise behind the proposed implementation, discover and test relevant
  prior art, and deliver the required outcome with the least total maintenance
  burden. Applies to build-versus-reuse decisions, unfamiliar technical cores,
  repeated failures, and OSS adoption or extraction. Keep understood, bounded
  local changes local.
---

# Refurbisher

Earn each new mechanism. Treat maintained code, dependencies, configuration, state,
services, forks, and recovery procedures as obligations. Optimize for the requested
outcome with the least total responsibility left to the project.

The ability to implement the first plausible idea does not establish that it is worth
owning. Interrupt that reflex before the design hardens: look for the mature problem
inside the request, and let evidence earn the mechanism you retain.

Use research to change a decision. A successful investigation can lead to a corrected
configuration, deletion, better use of an installed component, a borrowed algorithm,
a narrow extraction, adoption of a whole system, or justified new code. Count the
responsibilities removed as well as those introduced. Fewer local lines alone do not
establish an improvement.

Assume strong engineering knowledge. Use what you know to generate candidates; do
not perform ignorance or search merely to rediscover a known fact. Investigate the
consequential uncertainty: whether the chosen mechanism is necessary and fits this
system.

## Before enlarging the solution

### Recover the outcome and the uncertain premise

Separate the user's required behavior and constraints from a proposed implementation.
Respect explicit technology, compatibility, deployment, and scope requirements.

Identify what would have to be true for the proposed new machinery to be necessary.
Look especially for a substantial plan built on an untested diagnosis, a representation
with no demonstrated consumer, or patches that keep multiplying around one failure
class. State the consequential unknown briefly when it helps the user follow the work.

Do not turn every task into an architecture review. If nearby code and a clear contract
already support a bounded fix, make it.

Size is not a proxy for difficulty or consequence. A short primitive governing numerical
classification, binary interpretation, resource ownership, or recovery can have subtle
failure conditions that dominate the system's correctness. When such a function is needed,
and the behavior has been exercised in mature systems, investigate their implementation
and regression history before inventing another version. Prefer a supported existing API
when it fits; extract a snippet only when its dependencies and guarantees survive the move.

### Inspect what is already available

Follow a representative case through the relevant existing code, data, configuration,
and dependencies. Establish where the current mechanism stops satisfying the outcome.
Check whether a needed capability is already present but unused, misconfigured, or
connected at the wrong boundary.

Prefer a targeted read or measurement over a complete inventory. Do not add a cache,
retry layer, parser, model, service, or abstraction just because it is a familiar
response to the symptom.

### Search by the structure of the problem

When local evidence is insufficient, describe the problem without the product's
vocabulary: the resource being allocated, relationship being queried, invariant being
preserved, computation being repeated, or error being accumulated.

Identify where engineers have faced that structure under sustained pressure. Form one
or two plausible search hypotheses and say why they might transfer. Scheduling could
lead toward networks, operating systems, or storage; the job's actual constraints must
decide which lead matters. No domain is automatically the best source.

Use recall to start, then inspect relevant source, specifications, implementation
rationale, or research. Look for mechanisms at the appropriate scale: existing options,
functions, modules, libraries, protocols, or complete systems. Treat a remembered name
as a lead, not a verdict. Check the assumptions under which the borrowed idea works,
including a case where the analogy would fail.

Look inside mature projects for reusable pieces, not only for published packages. Search
for the behavior and its likely implementation terms; follow relevant symbols into
callers, helpers, tests, and fixes. A small internal routine can embody years of useful
engineering. Establish its complete dependencies and assumptions before copying or
porting it; the project's reputation alone does not validate the extracted piece.

Read [the search playbook](references/search-playbook.md) when the search space or
vocabulary is unclear. Do not browse every category or collect a quota of candidates.

### Resolve the decision with the smallest useful inquiry

Choose evidence that distinguishes the live alternatives: a source read, reduced
failure, representative trace, exact reference result, integration spike, or focused
benchmark. Identify what result would change the implementation before expanding the
investigation.

A probe may involve code. Keep it proportionate and avoid turning exploratory
instrumentation into permanent architecture without a reason. Reuse existing tools and
fixtures where they answer the question.

Challenge an attractive candidate with the real awkward case. Confirm the relevant
behavior and the cost of integrating it; a feature list or prestigious origin is
insufficient. If access prevents verification, state that limit and continue with
supported local work. Do not claim that an option was tested or that no solution exists
when the search could not establish it.

Stop when evidence supports a sufficient option and remaining uncertainty is unlikely
to change the decision at a cost proportionate to the task. Do not pursue a globally
"best" solution, exhaustive certainty, or research for its own sake.

## Choose the responsibility to keep

Compare plausible interventions by their actual consequences, not a fixed reuse ladder:

- What required behavior does this satisfy, and what remains unsupported?
- What code, state, concepts, interfaces, deployments, and recovery paths remain ours?
- What existing mechanism can be retired? Does the new option merely duplicate it?
- What migration, compatibility, update, and exit costs does adoption create?

Reuse the current system when it can meet the need. Adopt an external component when it
removes more responsibility than its integration adds. Extract or port a narrow part
when its dependency closure and assumptions are understood. Borrow a design when that
avoids an unsuitable runtime. Write a small custom implementation when the requirement
is genuinely local or the alternatives impose more burden.

For material external reuse, read [the reuse review](references/reuse-review.md).
Check the exact source and intended reuse mode. Repository popularity, activity counts,
AI authorship clues, and organizational prestige cannot replace inspection of the
behavior and maintenance obligations being adopted.

Do not silently weaken a requirement to make reuse fit. Do not preserve obsolete
mechanisms indefinitely beside their replacement. Preserve useful behavior and retire
redundant parts once the replacement has been verified.

## Finish the authorized work

Research is part of execution. Proceed with the supported implementation and verify the
behavior that motivated the choice. Do not stop at a shortlist, request permission for
routine engineering judgment, or offer to perform the decisive probe later.

Ask only when an unresolved decision changes a user requirement or creates a material
commitment beyond existing authorization. Complete the safe, useful investigation
first, then present the concrete tradeoff and recommendation. Do not ask the user to
resolve uncertainty that inspecting the system can settle.

Report the decisive evidence, the chosen intervention, the responsibility removed or
avoided, and the verification or remaining limit. A few sentences usually suffice.
Create a comparison table or decision document only when the decision warrants one.
Do not require a research report, trust score, approval form, or extra project files.

## Calibration examples

Read [the worked examples](references/worked-examples.md) when calibrating the behavior
or revising this skill. They begin with an uncertain premise and show how evidence can
change the implementation, including when to reject an analogy or write directly.
The tool names are possible discoveries, not answers to memorize.
