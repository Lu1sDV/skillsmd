---
name: react-testing-a11y
description: >
  Use when writing, fixing, or reviewing React tests with React Testing Library,
  user-event, MSW, jest-axe or Playwright: "not wrapped in act(...)" warnings,
  getByRole/findBy/waitFor flakiness, fireEvent vs userEvent, renderHook,
  snapshot or mock disputes, async Server Component testing; or accessible React
  UI: semantic HTML vs ARIA, labels, keyboard and focus, route-change
  announcements, live regions, dialogs, jsx-a11y/axe findings, WCAG 2.2, and
  dangerouslySetInnerHTML XSS.
---

# React Testing and Accessibility

Baseline (checked 2026-11-07): React **19.3**, React Testing Library with
**user-event 14**, **MSW 3** (current; 2.x uses `onUnhandledRequest`, 3.x
`onUnhandledFrame`; 3.x needs Node 22+), Next.js **16** App Router, **WCAG 2.2**. Preserve a project's
existing runner and test layout. Every rule carries its source and condition in
the references; gates are repeated here only where an agent is likely to miss them.

## Route by task

| Task | Load |
|---|---|
| Queries, user-event, `findBy`/`waitFor`, `act`, `renderHook`, MSW, cleanup | [Testing Library](references/testing-library.md) |
| What to test, mocking, snapshots, runner, E2E/Playwright, async RSC, lint | [Test strategy](references/testing-strategy.md) |
| Semantics/ARIA, names, keyboard, focus, route changes, live regions, dialogs, forms, contrast, motion, jsx-a11y/axe, WCAG, XSS | [Accessibility](references/accessibility.md) |

Load only what the task needs. Component design, Effects, Server Actions and
performance are handoffs, not covered here.

## Workflow

1. Read the project's runner, `setup` file, MSW/Playwright config and installed
   versions (`@testing-library/react`, `user-event`, `msw`, `@radix-ui/*`).
   Docs track the latest release; check the installed one before using a gated API.
2. Pick the lowest layer that exercises real user behavior: mostly integration
   tests through rendered UI; E2E for async Server Components and layout.
3. Write from the user's view: role/label/text queries, `userEvent`, awaited
   assertions. Assert what is rendered, not state, hooks, or source text.
4. For UI changes, start from native elements; add ARIA only where no native
   element exists, then supply the keyboard behavior it promises.
5. Run lint, typecheck, tests and build **separately**: in Next.js 16
   `next build` no longer lints
   ([source](https://nextjs.org/docs/app/guides/upgrading/version-16)) but fails on
   TypeScript errors
   ([source](https://nextjs.org/docs/app/api-reference/config/typescript)).
6. Report only checks actually run. Automated axe cannot certify accessibility.

## High-risk rules

- Test behavior users can observe; implementation-detail tests break on refactor
  while the app still works, or pass while it is broken
  ([Kent C. Dodds](https://kentcdodds.com/blog/testing-implementation-details)).
- `getByRole` first, then label/placeholder/text; `getByTestId` only when role or
  text cannot match. Avoid `container.querySelector`.
- user-event 14: call `userEvent.setup()` per test (in the test or a per-test setup
  helper) and `await` every call.
  `fireEvent` remains valid for events user-event cannot express.
- `act` warnings mean an update happened that the test did not wait for. Fix the
  wait (`findBy*`/`waitFor`/`await act`), do not silence the warning. React 18+
  no longer warns about `setState` on unmounted components.
- `renderHook` comes from `@testing-library/react`. Prefer `findBy*`/`waitFor` over
  `setTimeout` plus an assertion (inference from the async docs; use fake timers
  when the timer itself is under test,
  [Kent](https://kentcdodds.com/blog/fix-the-not-wrapped-in-act-warning)).
  `waitFor` callbacks must throw to retry and must not hold side effects.
- MSW: strict unhandled-request mode is an option, not the default (`warn`).
  Name by version: `onUnhandledFrame` (3.x) / `onUnhandledRequest` (2.x).
- jsdom has no layout; jest-axe turns colour-contrast off there. axe finds about
  57% of WCAG issues on average; keep manual and assistive-technology checks.
- Native element before ARIA; wrong ARIA is worse than none. Keyboard operability
  is WCAG 2.1.1; custom widgets owe the APG key behavior.
- Never remove a focus outline without a replacement visible focus indicator; never put
  `aria-hidden` or `role="presentation"` on a focusable element.
- Radix `Dialog` needs a `Title` (hidden with Visually Hidden if needed). Newer
  versions no longer warn when it is missing, so enforce it by review or axe.
- `dangerouslySetInnerHTML` with markup from anywhere but a completely trusted
  source is an XSS risk.

## Skill myths

| Myth | What the sources say |
|---|---|
| Test hooks with `@testing-library/react-hooks` | Import `renderHook` from `@testing-library/react`; then uninstall the old package ([README](https://raw.githubusercontent.com/testing-library/react-hooks-testing-library/main/README.md)) |
| Target WCAG 2.1 (or only Level A) | WCAG 2.2 is a W3C Recommendation since 2023-10-05 with 9 added criteria ([W3C](https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/)) |
| Add ARIA to every interactive element | Native first; "No ARIA is better than bad ARIA" ([APG](https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/), [MDN](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA)) |
| Lint-ban `useEffect` | "You *do* need Effects to synchronize with external systems" ([react.dev](https://react.dev/learn/you-might-not-need-an-effect)); avoid unnecessary ones |
| Tailwind only, avoid traditional CSS | GitHub Primer moved from runtime CSS-in-JS to CSS Modules after page-level SSR cost grew (55% less SSR time) ([GitHub](https://github.blog/engineering/architecture-optimization/improving-site-performance-by-shipping-more-css/)). Tailwind and CSS Modules are both static CSS (Tailwind class names must be "statically detectable at build-time", [Tailwind](https://tailwindcss.com/docs/detecting-classes-in-source-files)); neither is required |
| Smoke-test every component | Spend "most (not all, mind you)" effort on integration tests; logic-free components are covered by flows that render them ([Kent](https://kentcdodds.com/blog/write-tests)) |
| Snapshots only for data, never rendered output | Small focused snapshots are endorsed; avoid huge ones ([Kent](https://kentcdodds.com/blog/effective-snapshot-testing)) |
| Use `@axe-core/react` for React tests | "This package does not support React 18 and above" ([README](https://raw.githubusercontent.com/dequelabs/axe-core-npm/develop/packages/react/README.md)); alternatives: [jest-axe](https://raw.githubusercontent.com/NickColley/jest-axe/main/README.md), [vitest-axe](https://raw.githubusercontent.com/chaance/vitest-axe/main/README.md), [Playwright axe](https://playwright.dev/docs/accessibility-testing) |
| Install `@playwright/experimental-ct-react` | Those packages were removed; use `@playwright/test` with the `mount` fixture ([Playwright](https://playwright.dev/docs/test-components)) |
| Jest only (or Vitest only) | Next.js documents both ([Next.js](https://nextjs.org/docs/app/guides/testing)); RTL prefers Jest but works with any framework ([RTL intro](https://testing-library.com/docs/react-testing-library/intro)) |
| Never mock router/framework hooks | Kent's guidance is "stop mocking so much stuff", conceding "sometimes it can't be helped" ([Write tests](https://kentcdodds.com/blog/write-tests)); no source addresses framework hooks |
| Missing Radix `Title` always logs an error | Removed in newer `@radix-ui/react-dialog`; see the accessibility reference |

## Handoffs

Optional, none is an installation dependency: **react-hooks-state** (Effects,
refs), **react-components-typescript** (component API,
controlled forms, error boundaries), **react-server-data** (Server Components,
Actions, data fetching), **react-performance** (re-renders, Compiler, INP);
repo skills **test-engineering** (framework-independent strategy),
**ui-taste** (visual design), **typescript-type-modeling**,
**web-performance-optimization**.

See [README](README.md#sources-and-decisions) for the evidence basis and excluded claims.
