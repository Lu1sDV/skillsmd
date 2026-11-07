# Accessible React UI

Baseline: **WCAG 2.2** (W3C Recommendation since 2023-10-05, nine criteria added
over 2.1), React 19.3, Next.js 16 App Router. "AA is the target" is the auditor's
convention, not stated by W3C. Each rule ends with its source. Pages on
`legacy.reactjs.org` are the retired React docs; no react.dev equivalent was found.

## Contents

- [Semantics and ARIA](#semantics-and-aria)
- [Names and labels](#names-and-labels)
- [Keyboard and focus](#keyboard-and-focus)
- [Route changes](#route-changes)
- [Live regions](#live-regions)
- [Dialogs](#dialogs)
- [Validation errors](#validation-errors)
- [Visual: contrast, motion](#visual-contrast-motion)
- [Automated tooling and its limits](#automated-tooling-and-its-limits)
- [XSS: dangerouslySetInnerHTML](#xss-dangerouslysetinnerhtml)

## Semantics and ARIA

- Native element first: "If you can use a native HTML element or attribute with the
  semantics and behavior you require already built in... then do so." The rule is
  "native first", not "never ARIA": exceptions include missing user-agent support,
  styling limits and semantics absent from HTML.
  [MDN: ARIA](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA),
  [Deque: top 5 rules](https://www.deque.com/blog/top-5-rules-of-aria)
- W3C "Using ARIA" is a discontinued draft kept for history; cite MDN or APG.
  [Using ARIA](https://w3c.github.io/using-aria/)
- "Incorrect ARIA misrepresents visual experiences, with potentially devastating
  effects" for non-visual users; a role on a `div` is "a promise" that the author
  also supplies the keyboard behavior.
  [APG read me first](https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/)
- "Slapping accessibility attributes willy nilly is not only unnecessary... but it
  can also confuse screen readers and their users."
  [Common mistakes](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)
- Do not change native semantics unless essential.
  [Deque: top 5 rules](https://www.deque.com/blog/top-5-rules-of-aria)
- Never put `role="presentation"` or `aria-hidden="true"` on a focusable element:
  some users "focus on nothing".
  [Deque: top 5 rules](https://www.deque.com/blog/top-5-rules-of-aria)
- If you do use ARIA you must mimic the native browser behavior in script.
  [MDN: ARIA](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA)
- In JSX, `aria-*` attributes keep their hyphenated names.
  [Legacy React accessibility](https://legacy.reactjs.org/docs/accessibility.html)
- Use Fragments instead of wrapper `<div>`s where a div would break `<ol>`/`<ul>`/
  `<dl>`/`<table>` semantics.
  [Legacy React accessibility](https://legacy.reactjs.org/docs/accessibility.html)

```tsx
// Native first: no role, no tabIndex, no key handler needed
<button type="button" onClick={save}>Save</button>
// Not: <div role="button" tabIndex={0} onClick={save}>Save</div>
```

## Names and labels

- All interactive elements need an accessible name.
  [Deque: top 5 rules](https://www.deque.com/blog/top-5-rules-of-aria)
- Use native naming: the HTML `label` element for form elements. Prefer visible
  text as the name; use `aria-label` when no visible text serves, such as an
  icon-only button.
  [APG names and descriptions](https://www.w3.org/WAI/ARIA/apg/practices/names-and-descriptions/)
- Avoid `aria-label`/`aria-labelledby` overriding content on roles named from
  content (button, link, heading) except in rare cases.
  [APG names and descriptions](https://www.w3.org/WAI/ARIA/apg/practices/names-and-descriptions/)
- A placeholder is not a substitute for a label.
  [Testing Library queries](https://testing-library.com/docs/queries/about/#priority)
- In JSX use `htmlFor`. `useId` generates unique IDs for accessibility attributes;
  hardcoded IDs break when a component renders twice. `useId` "should not be used to
  generate keys in a list". Nesting the `<input>` inside the `<label>` makes the
  association implicit, so `for`/`id` are not needed, though MDN recommends explicit
  association with `for`.
  [useId](https://react.dev/reference/react/useId),
  [Legacy React accessibility](https://legacy.reactjs.org/docs/accessibility.html),
  [MDN: label](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/label)

```tsx
function Field({ label }: { label: string }) {
  const id = useId();
  return (<><label htmlFor={id}>{label}</label><input id={id} /></>);
}
```

## Keyboard and focus

- All functionality exposed through mouse or pointer events must also work by
  keyboard alone.
  [Legacy React accessibility](https://legacy.reactjs.org/docs/accessibility.html)
- Scope: the normative bar is WCAG 2.1.1 (Level A), which requires a keyboard way
  to perform the same or comparable actions, not that every control be separately
  focusable (a mouse-only submit button passes if Enter in the field submits).
  Custom ARIA widgets still must be keyboard-usable.
  [Understanding 2.1.1](https://www.w3.org/WAI/WCAG22/Understanding/keyboard.html)
- Do not remove the focus outline (`outline: 0`) unless you replace it with another
  visible focus indicator. SC 2.4.7 (AA) requires a visible keyboard focus
  indicator; 2.4.13 Focus Appearance is AAA. WCAG 2.2 adds 2.4.11 Focus Not
  Obscured (Minimum), AA.
  [Legacy React accessibility](https://legacy.reactjs.org/docs/accessibility.html),
  [Understanding 2.4.7](https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html),
  [New in 2.2](https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/)
- React updates can drop focus; restore it programmatically with refs.
  [Legacy React accessibility](https://legacy.reactjs.org/docs/accessibility.html)
- Focus effects must fire when a value changes, not on initial mount.
  [MDN: Accessibility in React](https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Frameworks_libraries/React_accessibility)

## Route changes

- Do not move focus when a static page loads; browsers focus the top. In a
  single-page app, set focus to the first unique heading on navigation.
  [VA focus management](https://design.va.gov/accessibility/focus-management)
- A heading is not focusable by default; add `tabindex="-1"` so script can focus it.
  Update `document.title` on navigation; check whether the router already does.
  [Orange SPA guide](https://a11y-guidelines.orange.com/en/articles/single-page-app)
- **Next.js:** a route announcer is included by default so client-side transitions
  reach assistive technology, so route-change announcement is partly handled. Other
  routers may need manual focus or announcement; check the router's docs.
  [Next.js accessibility](https://nextjs.org/docs/architecture/accessibility)
- Disagreement on the focus target: Orange focuses the heading with `tabindex="-1"`;
  VA also says to "move focus to interactive elements like buttons, links, and
  inputs" when available, and warns that some browser/AT pairs behave unpredictably
  on non-interactive focus targets (an unverified CSS-Tricks reader comment reports
  silent `aria-hidden` focus targets). Both give the first heading for SPA navigation;
  the interactive-target advice applies to other focus moves. Test with the
  assistive technology your users have.
  [VA focus management](https://design.va.gov/accessibility/focus-management),
  [Orange SPA guide](https://a11y-guidelines.orange.com/en/articles/single-page-app),
  [CSS-Tricks (reader comment)](https://css-tricks.com/how-we-improved-the-accessibility-of-our-single-page-app-menu)

## Live regions

- Normally only `aria-live="polite"` is used, for updates that matter but are not
  rapid. `role="alert"` is handled specially by browsers.
  [MDN: live regions](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Guides/Live_regions)
- "Establish the live region before updating its content": start empty, render it
  in the initial markup. A region mounted in the same render as its text may not be
  announced; behavior varies by browser and AT.
  [MDN: live regions](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Guides/Live_regions)
- Disagreement: VA prefers focus announcements ("announced more reliably") and says
  to consider removing `aria-live` when you also manage focus because the two can
  conflict; Orange offers either per case.
  [VA focus management](https://design.va.gov/accessibility/focus-management)

```tsx
// Mounted empty with the page; update only its text
<div role="status" aria-live="polite">{message}</div>
```

## Dialogs

- On open, focus moves inside the dialog. On close, focus returns to the invoking
  element unless an exception in the pattern applies. Modal dialogs contain Tab and
  Shift+Tab; Escape closes.
  [APG modal dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
- Mark `aria-modal="true"` only when app code blocks all interaction outside and
  visual styling obscures it; misuse has "severe negative ramifications".
  [APG modal dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
- A dialog needs an accessible name: `aria-labelledby` to a visible title, or
  `aria-label`.
  [APG modal dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
- **Radix Dialog:** use `Dialog.Title` (announced when the dialog opens); hide it
  with the Visually Hidden utility if the design has no visible title. In
  `@radix-ui/react-dialog` 1.1.15 a missing Title logs a console error; it is absent
  from 1.2.0 and 1.3.1 (inferred from the bundles, no changelog entry found), where
  a missing Title sets no `aria-labelledby` silently. Enforce by review or axe.
  shadcn's `DialogTitle` wraps the same primitive.
  [Radix Dialog](https://www.radix-ui.com/primitives/docs/components/dialog),
  [Radix source](https://raw.githubusercontent.com/radix-ui/primitives/main/packages/react/dialog/src/dialog.tsx),
  [shadcn dialog](https://raw.githubusercontent.com/shadcn-ui/ui/main/apps/v4/registry/new-york-v4/ui/dialog.tsx)

## Validation errors

GOV.UK and VA patterns; community design systems, not React APIs.

- Always show an error summary when validation fails, even for one error; move
  keyboard focus to it. Also show an error message next to each field.
  [GOV.UK error summary](https://design-system.service.gov.uk/components/error-summary/)
- When an error blocks the next action, move focus to the first input with an error;
  if the error is not tied to an input, to the first interactive element that fixes it.
  [VA focus management](https://design.va.gov/accessibility/focus-management)
- Prefix the page `<title>` with "Error: " as one way to follow the validation
  pattern; GOV.UK gives it as an example, not a mandate.
  [GOV.UK error summary](https://design-system.service.gov.uk/components/error-summary/)

## Visual: contrast, motion

- SC 1.4.3 (AA): text contrast at least 4.5:1; large-scale text (18pt, or 14pt bold)
  at least 3:1. No rounding (4.499:1 fails). Exceptions: inactive UI, pure
  decoration, logotypes. UI components and graphics have a separate 3:1 rule (1.4.11).
  [Understanding 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
- React does not disable animations for users who prefer less motion. React
  recommends gating `<ViewTransition>` animations behind
  `@media (prefers-reduced-motion)`. For interaction-triggered animation such as
  ViewTransition this is 2.3.3 (AAA); animation that starts automatically and lasts
  more than five seconds falls under 2.2.2 (Level A). Treat the reduced-motion gate
  as best practice, not an AA requirement.
  [ViewTransition](https://react.dev/reference/react/ViewTransition),
  [Understanding 2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html),
  [Understanding 2.2.2](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html)

## Automated tooling and its limits

- `eslint-plugin-jsx-a11y` catches errors in static code only; pair it with
  rendered-DOM testing. Its README still names `@axe-core/react`, which says "This
  package does not support React 18 and above"; use axe-core through jest-axe,
  vitest-axe or Playwright instead.
  [jsx-a11y README](https://github.com/jsx-eslint/eslint-plugin-jsx-a11y),
  [@axe-core/react README](https://raw.githubusercontent.com/dequelabs/axe-core-npm/develop/packages/react/README.md),
  [jest-axe](https://raw.githubusercontent.com/NickColley/jest-axe/main/README.md),
  [vitest-axe](https://raw.githubusercontent.com/chaance/vitest-axe/main/README.md),
  [Playwright accessibility testing](https://playwright.dev/docs/accessibility-testing)
- axe finds "on average 57% of WCAG issues automatically". Treat axe like a linter:
  it finds common issues "but cannot guarantee that what you build works for users".
  [axe-core README](https://raw.githubusercontent.com/dequelabs/axe-core/develop/README.md),
  [jest-axe README](https://raw.githubusercontent.com/NickColley/jest-axe/main/README.md)
- Colour-contrast checks do not work in jsdom, so jest-axe turns them off; check
  contrast in a real browser (for example axe through Playwright) or by design review.
  [jest-axe README](https://raw.githubusercontent.com/NickColley/jest-axe/main/README.md)
- Test authored ARIA with actual assistive technology; emulators "are not really
  effective for testing full support". Use automation as one step of a larger
  process.
  [MDN: ARIA](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA),
  [jsx-a11y README](https://raw.githubusercontent.com/jsx-eslint/eslint-plugin-jsx-a11y/main/README.md)
- Testing Library's role-first queries double as an accessibility check: if you
  cannot get an element by role, "it's possible your UI is inaccessible".
  [Query priority](https://testing-library.com/docs/queries/about/#priority)

```tsx
import { axe } from "jest-axe"; // plus expect.extend(toHaveNoViolations)
const { container } = render(<App />);
expect(await axe(container)).toHaveNoViolations();
```

## XSS: dangerouslySetInnerHTML

- "Unless the markup is coming from a completely trusted source, it is trivial to
  introduce an XSS vulnerability this way." If your site enforces Trusted Types, pass
  a `TrustedHTML` value; "Your policy must still ensure that any input used to create
  the value is trusted and sanitized." Only the react.dev reference was fetched; it
  names no sanitizer library.
  [React DOM common components](https://react.dev/reference/react-dom/components/common)
