# react-testing-a11y

Community-backed guidance for testing React with React Testing Library, user-event
14, MSW and Playwright, and for building accessible React UI (WCAG 2.2). Baseline
checked **2026-11-07**: React 19.3, Next.js 16 App Router, MSW 3 (2.x noted).
Self-contained: no sibling skill is needed.

## Install

From the skillsmd checkout (preserve local changes before replacing an existing
installation):

```sh
mkdir -p ~/.claude/skills
cp -r react-testing-a11y ~/.claude/skills/
```

## Usage

- "This test logs 'not wrapped in act(...)'. Find the un-awaited update and fix it."
- "Rewrite these `fireEvent` and `getByTestId` tests with user-event 14 and role queries."
- "Replace our `fetch` mocks with MSW and make unhandled requests fail the test."
- "Review this modal and its route changes for focus, names, and screen-reader announcements."
- "Triage these jest-axe and jsx-a11y findings: what do they cover and what still needs manual testing?"

## Reference index

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Trigger, version baseline, routing, workflow, high-risk rules, skill myths, handoffs |
| [Testing Library](references/testing-library.md) | Principles, queries, user-event 14, `findBy`/`waitFor`/`act`, `renderHook`, cleanup, MSW 3 (2.x noted) |
| [Test strategy](references/testing-strategy.md) | Integration-first, mocking limits, snapshots, runner choice, jsdom limits, Playwright `mount`, async Server Components, lint order |
| [Accessibility](references/accessibility.md) | Native semantics and ARIA, names, keyboard, focus, route changes, live regions, dialogs, validation errors, contrast/motion, jsx-a11y/axe limits, XSS |

Optional handoffs (none is an installation dependency): `react-hooks-state`,
`react-components-typescript`, `react-server-data`, `react-performance`, and the
repo skills `test-engineering`, `ui-taste`, `typescript-type-modeling`,
`web-performance-optimization`.

## Sources and decisions

**Evidence basis.** An auditor classified claims from community sources (official
docs, React and library maintainers, respected engineers, company engineering
blogs) against agent-skill claims (cluster set V5), and an independent verifier
re-fetched every supported cluster on **2026-11-07** (batches 7 and 8: 0 disputed).
No claim appears only because another AI skill states it. Static review, not
execution: no test, lint, or link check was run against these files by the author.

**Corrections applied (verifier overrides auditor).**

- Playwright component tests: `@playwright/experimental-ct-*` packages were
  removed; use `@playwright/test` with the `mount` fixture (V5-27).
- axe: add jsdom's disabled colour-contrast rule and the ~57% average coverage;
  `@axe-core/react` is not a React 18+ option (V5-28).
- Test runner: Vitest and Jest are peers; RTL states a Jest preference but works
  with any runner, so "Jest is outdated" is not asserted (V5-29).
- Lint/typecheck/build: separate steps because Next.js 16 `next build` no longer lints (V5-32).
- Route focus: VA and Orange agree on the first heading; Next.js ships a route
  announcer (V5-34).
- Radix Title: the runtime warning exists in 1.1.15 but not in later versions;
  removal inferred from bundles, no changelog entry found (V5-35).
- MSW option: `onUnhandledFrame` from 3.0 (current; Node 22+, `msw/http` import);
  `onUnhandledRequest` through 2.x (V5-24).
- `act`: no unmounted-`setState` warning since React 18; warnings gated by
  `IS_REACT_ACT_ENVIRONMENT` (V5-42).
- user-event: awaiting every call is a v14 rule (V5-40).
- Keyboard: normative bar is WCAG 2.1.1 (functionality), not every control being
  focusable (V5-49). Reduced motion is AAA, best practice (V5-53).
- `setTimeout` is flaky, and source-inspection tests assert implementation detail:
  both are marked as inferences from the docs (V5-41, V5-43).
- 2026-11-07 source-support fact-check: 21 issues fixed (1 wrong, 8 overstated,
  10 miscited/misquoted, 1 outdated baseline, 1 example defect).

**Skill myths** (V5-3, 4, 6, 7, 8, 10, 11, 26, 28, 29, 35): see the table in
[SKILL.md](SKILL.md).

**Excluded and why.**

- Twelve UNSUPPORTED clusters (V5-12 to V5-23): design tokens, shadcn/Tailwind
  conventions, design-taste rules, per-metric coverage thresholds, test-file
  colocation, loader/action unit tests, `data-invalid`, compiler-lint severity,
  import style, agent-workflow rules, Next.js `instant()` tests, generator-specific
  conventions. One labeled "project policy" line covers file placement of custom
  `render` helpers (RTL documents the `wrapper` mechanism itself).
- Owned by other skills or outside this scope: framework and CRA/Vite defaults
  (V5-1, 33, 47), React Compiler and React version pins (V5-2, 5, 46),
  `eslint-plugin-react-hooks` and `exhaustive-deps` (V5-44, 45), View Transitions
  (V5-36; only the reduced-motion rule is used), "always latest" (V5-9) and
  verify-installed-version (V5-37; kept only as a workflow step).
- No community evidence was found for sanitizer libraries, CSP, or `href` URL
  schemes, so the XSS section states only react.dev's warning and its Trusted Types note.
- Link markup in several quotes was truncated in the evidence; quotes were taken
  from the verifier's fetched text.
