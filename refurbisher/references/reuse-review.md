# Review the reuse you actually propose

Use this reference when adopting, depending on, copying, porting, or forking external
software. Scale the inquiry to the code and authority being imported. Reading an
algorithm for insight does not require a procurement workflow.

## Establish identity and behavior

Verify the exact project, package, version or revision, and relevant implementation.
Check that the published artifact corresponds to the source being inspected. A familiar
name or registry-to-repository link is a starting point, not sufficient provenance.

Read the path that implements the required behavior and its meaningful tests. Check
that claimed features exist, failure paths do not report fake success, and tests exercise
the behavior being relied on. Exercise a representative failure or boundary when that
resolves a material uncertainty. Check
whether the feature belongs to the actual edition, platform, or build being adopted.

Use maintenance history, substantive reviews, downstream experience, advisories, and
known limitations as evidence for specific concerns. Inspect the real upstream when
GitHub is a mirror. Distinguish a stable, deliberately finished component from one with
unresolved defects that the project would inherit.

Do not infer correctness or human review from stars, age, contributor counts, commit
trailers, writing style, or the presence or absence of agent configuration files.
AI involvement alone is not a defect; demonstrated broken behavior, unreviewed changes,
or opaque release provenance are concrete concerns to investigate.

## Check the intended reuse terms

Read the applicable license and notices for the exact code and reuse mode. Check
subdirectories, generated or bundled assets, and model or dataset terms where relevant.
Distinguish running a service, linking a dependency, distributing code, and copying or
modifying files; do not apply a blanket verdict from a license-family label or an
`enterprise/` directory name.

Retain required attribution and notices. If permission or compatibility cannot be
established, do not incorporate the code while describing that uncertainty as settled.
Choose a supported alternative, use an independently expressed design where permitted,
or surface the concrete unresolved constraint when it materially affects the outcome.
Do not turn an uncertain licensing question into an automatic request for user approval
of an otherwise unexamined candidate.

## Match the integration boundary

- **Existing feature or package:** use the supported boundary and the project's normal
  dependency/version mechanism. Avoid creating an adapter without a concrete purpose.
- **Platform:** include data ownership, deployment, upgrades, recovery, and export in
  the fit check. Add only the integration the user actually needs.
- **Copied or ported component:** identify the smallest semantically complete part,
  including types, initialization, generated data, memory/concurrency assumptions,
  and relevant upstream tests. Record origin, revision, notices, and local changes.
- **Fork or vendor:** make the ongoing patch and update responsibility explicit.
  Prefer the project's existing provenance convention; do not add a documentation
  structure merely to satisfy this skill.
- **Borrowed design:** preserve the assumptions that make the mechanism appropriate.
  Implement only the required boundary and attribute the source of the design where useful.

Verify the integration against the original outcome and retire superseded paths when
safe. Reuse succeeds when it reduces the responsibility the project must carry while
preserving the required behavior.
