# Testing Library mechanics

Baseline: React Testing Library (RTL) on React 19.3, user-event **14**, MSW **3**
(current; 2.x uses `onUnhandledRequest`). Each rule ends with its source.

## Contents

- [Principles](#principles)
- [Queries](#queries)
- [Interactions: user-event](#interactions-user-event)
- [Async: findBy, waitFor, act](#async-findby-waitfor-act)
- [Hooks and cleanup](#hooks-and-cleanup)
- [Network: MSW](#network-msw)

## Principles

- The more tests resemble how the software is used, the more confidence they give.
  The same page concedes trade-offs because tests run in a simulated browser.
  [Guiding principles](https://testing-library.com/docs/guiding-principles)
- Work with DOM nodes, not component instances.
  [Guiding principles](https://testing-library.com/docs/guiding-principles)
- An implementation detail is anything users of the code "will not typically use,
  see, or even know about". Testing one produces false negatives on refactor
  (test breaks, app fine) and false positives (app breaks, test passes). Kent's
  worked example uses enzyme; the principle is general.
  [Testing implementation details](https://kentcdodds.com/blog/testing-implementation-details)
- Avoid tests that inspect source text or merely assert hooks are absent: they
  assert what no user observes. This applies the sources' definition; neither
  source names these cases explicitly.
  [Avoid the test user](https://kentcdodds.com/blog/avoid-the-test-user)

## Queries

Priority order: role, label, placeholder, text, display value; then alt text and
title; test IDs last.
[Query priority](https://testing-library.com/docs/queries/about/#priority)

- `getByRole` is "your top preference for just about everything"; if you cannot
  get an element this way, "it's possible your UI is inaccessible".
  [Query priority](https://testing-library.com/docs/queries/about/#priority)
- `getByLabelText` is also called the top preference for form fields. Role-first and
  label-first are context choices, not a conflict.
  [Query priority](https://testing-library.com/docs/queries/about/#priority)
- A placeholder is not a substitute for a label.
  [Query priority](https://testing-library.com/docs/queries/about/#priority)
- `getByTestId` only where you "can't match by role or text or it doesn't make
  sense (e.g. the text is dynamic)".
  [Query priority](https://testing-library.com/docs/queries/about/#priority)
- Avoid `container` to query elements ("reconsider", not an absolute ban).
  [render API](https://testing-library.com/docs/react-testing-library/api/)
- Disagreement: Kent recommends querying by actual visible text (default locale)
  rather than test IDs, noting "not everyone agrees with me on this". Compatible
  with role-first, different emphasis.
  [Common mistakes](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)
- Use `query*` only to assert absence; `get*`/`find*` throw with useful DOM output.
  [Common mistakes](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)
- Use jest-dom matchers (`toBeDisabled`, `toBeInTheDocument`): "the error messages
  you get with it are much better".
  [Common mistakes](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)

```tsx
const user = userEvent.setup();
render(<Login />);
await user.type(screen.getByLabelText(/email/i), "a@b.co");
await user.click(screen.getByRole("button", { name: /sign in/i }));
expect(await screen.findByRole("alert")).toHaveTextContent(/invalid/i);
expect(screen.queryByRole("progressbar")).not.toBeInTheDocument();
```

## Interactions: user-event

- `fireEvent` dispatches single DOM events; `user-event` simulates full
  interactions (several events plus checks). Prefer user-event. Use `fireEvent`
  for concrete events user-event cannot yet describe.
  [user-event intro](https://testing-library.com/docs/user-event/intro/)
- **user-event 14 only:** every API returns a Promise, so `await` each call.
  v13 was synchronous.
  [v14.0.0 release](https://github.com/testing-library/user-event/releases/tag/v14.0.0)
- Call `userEvent.setup()` per test, before rendering: "This can be done in the test
  itself, or by using a setup function". "We discourage rendering or using any
  userEvent functions outside of the test itself - e.g. in a before/after hook".
  [user-event intro](https://testing-library.com/docs/user-event/intro/)

```tsx
test("toggles", async () => {
  const user = userEvent.setup();
  render(<Toggle />);
  await user.click(screen.getByRole("switch", { name: /notifications/i }));
  expect(screen.getByRole("switch")).toBeChecked();
});
```

## Async: findBy, waitFor, act

- `findBy*` suits elements that appear "but the change to the DOM might not happen
  immediately"; async methods return Promises, so `await` them.
  [Async methods](https://testing-library.com/docs/dom-testing-library/api-async/)
- Prefer `findBy*`/`waitFor` over a timer plus assertion. The docs present these as
  the retrying mechanism; "setTimeout then assert is flaky" is an inference, not
  a verbatim doc rule.
  [Async methods](https://testing-library.com/docs/dom-testing-library/api-async/)
- `waitFor` retries only when its callback throws; "Returning a falsy condition is
  not sufficient".
  [Async methods](https://testing-library.com/docs/dom-testing-library/api-async/)
- Do not pass an empty `waitFor` callback; wait on a specific assertion. Keep side
  effects out of it because it may run many times.
  [Common mistakes](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)
- An `act` warning says something happened to the component "when we weren't
  expecting anything to happen"; the usual cause is an update after the test
  stopped waiting. Fix the cause rather than silence it.
  [Fix the act warning](https://kentcdodds.com/blog/fix-the-not-wrapped-in-act-warning)
- RTL wraps `render` and `fireEvent` in `act`; its async utilities are also wrapped,
  so manual `act` is rarely needed (Kent's cases include fake timers).
  [Cheatsheet](https://testing-library.com/docs/react-testing-library/cheatsheet/),
  [Fix the act warning](https://kentcdodds.com/blog/fix-the-not-wrapped-in-act-warning)
- When you must call `act`: "We recommend using `act` with `await` and an `async`
  function"; outside RTL set `global.IS_REACT_ACT_ENVIRONMENT = true` (RTL sets it).
  [act reference](https://react.dev/reference/react/act)
- **React 18+:** no warning about `setState` on an unmounted component, and act
  warnings are opt-in via `IS_REACT_ACT_ENVIRONMENT`. Older posts that treat an
  unmounted-setState warning as an act symptom are dated; Kent's post is 2020 and
  uses pre-v14 un-awaited `user.type`.
  [React 18 upgrade guide](https://react.dev/blog/2022/03/08/react-18-upgrade-guide)

```tsx
// Wrong: asserts before the async update lands, later logs an act warning
await user.click(screen.getByRole("button", { name: /load/i }));
expect(screen.getByText("Done")).toBeInTheDocument();
// Right: wait for the result
expect(await screen.findByText("Done")).toBeInTheDocument();
```

## Hooks and cleanup

- Import `renderHook` from `@testing-library/react` (React 18+); then
  `@testing-library/react-hooks` can be uninstalled.
  [react-hooks-testing-library README](https://raw.githubusercontent.com/testing-library/react-hooks-testing-library/main/README.md)
- Cleanup is automatic in most runners; `afterEach(cleanup)` is unnecessary.
  [Common mistakes](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)
- Avoid heavy `describe`/`beforeEach` nesting. Kent says nesting itself is not the
  problem; using hooks for reuse makes tests hard to trace. Playwright accepts
  `beforeEach` (login) and "a little duplication"; both are defensible, so follow
  the project's style.
  [Avoid nesting](https://kentcdodds.com/blog/avoid-nesting-when-youre-testing),
  [Playwright best practices](https://playwright.dev/docs/best-practices)

## Network: MSW

- Mock at the network boundary instead of mocking `fetch` or an API-client module.
  Kent: mocking `fetch` means "re-implementing your entire backend... everywhere
  in your tests"; with a server handler, a wrong call fails the test. Caveat: MSW
  is still a mock, at a different boundary, and Kent also reports a centralized
  `mockFetch` worked well for a long time.
  [Stop mocking fetch](https://kentcdodds.com/blog/stop-mocking-fetch)
- MSW's goal: "your application and tests would know *nothing* about mocking in
  place".
  [MSW philosophy](https://mswjs.io/docs/philosophy)
- Node lifecycle: `beforeAll(listen)`, `afterEach(() => server.resetHandlers())`,
  `afterAll(close)`.
  [MSW quick start](https://mswjs.io/docs/quick-start)
- Unhandled requests: default strategy is `"warn"`; `"error"` prints an error and
  halts the frame. **MSW 3.0+** (current) names the option `onUnhandledFrame`;
  **MSW 2.x** used `onUnhandledRequest` (for example
  `server.listen({ onUnhandledRequest: "error" })`). Check the installed version;
  strict mode is a sound choice, not the default.
  [listen API](https://mswjs.io/docs/api/setup-server/listen),
  [2.x to 3.x migration](https://mswjs.io/docs/migrations/2.x-to-3.x)
- MSW 3 gates: the minimum supported Node.js version is 22.0.0, and `http` and
  `HttpResponse` are imported from `msw/http` instead of `msw`.
  [2.x to 3.x migration](https://mswjs.io/docs/migrations/2.x-to-3.x)

```ts
// MSW 3.x (Node 22+; handlers import { http, HttpResponse } from "msw/http")
beforeAll(() => server.listen({ onUnhandledFrame: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
// MSW 2.x: same lifecycle, but pass { onUnhandledRequest: "error" }
```
