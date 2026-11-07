# Test strategy for React apps

Framework-independent strategy lives in the optional **test-engineering** skill.
This file covers React-specific, community-backed choices. Each rule ends with
its source.

## Contents

- [What to test](#what-to-test)
- [Mocking](#mocking)
- [Snapshots](#snapshots)
- [Runner choice](#runner-choice)
- [Browser layer: E2E and component tests](#browser-layer-e2e-and-component-tests)
- [Lint and verification](#lint-and-verification)

## What to test

- Spend "most (not all, mind you)" of the effort on integration tests: they balance
  confidence against speed and cost.
  [Write tests](https://kentcdodds.com/blog/write-tests)
- Mandating 100% coverage for applications is "a really bad idea". Kent calls his
  own 70% figure unscientific, so there is no community authority for per-metric
  coverage floors.
  [Write tests](https://kentcdodds.com/blog/write-tests)
- Do not write dedicated tests for components with no logic: "Maintaining tests
  like this actually really slow you and your team down." Test logic and edge
  cases; render simple components through the integration tests that use them.
  [Write tests](https://kentcdodds.com/blog/write-tests),
  [Why I never use shallow rendering](https://kentcdodds.com/blog/why-i-never-use-shallow-rendering)
- Verify the user path, not only the build. Tests should check that the app works
  for end users and avoid implementation details; the React team recommends
  continuous end-to-end testing so compiler upgrades can be made with confidence.
  [Playwright best practices](https://playwright.dev/docs/best-practices),
  [React Compiler 1.0](https://react.dev/blog/2025/10/07/react-compiler-1)
- RTL documents a custom `render` with a `wrapper` for providers (QueryClient,
  router, theme): "It's often useful to define a custom render method that includes
  things like global context providers, data stores, etc."
  [RTL setup](https://testing-library.com/docs/react-testing-library/setup#custom-render)
  File placement is project policy, not consensus; follow the repository's existing
  helper rather than inventing a second one.

## Mocking

- "When you mock something you're removing all confidence in the integration
  between what you're testing and what's being mocked." Mock as little as possible;
  Kent concedes "sometimes it can't be helped".
  [Write tests](https://kentcdodds.com/blog/write-tests)
- Do not shallow render in React tests: it lets you refactor and break tests, or
  break the app while tests still pass. Kent writes "I generally am against mocking
  even third party components 100% of the time", yet his own example mocks a heavy
  `<CSSTransition />`; narrow, explicit mocks of heavy children are an accepted
  exception.
  [Why I never use shallow rendering](https://kentcdodds.com/blog/why-i-never-use-shallow-rendering)
- Framework hooks (router and similar): no fetched source addresses them; a
  pragmatic mock is a project decision, not a violation of the sources above.

## Snapshots

- Kent shares Justin Searls's critique but says "there is value in them if you use
  them effectively": error messages and logs, `babel-plugin-tester`, and
  CSS-plus-DOM serializers such as `jest-glamor-react`. Avoid "HUGE snapshots";
  prefer explicit assertions where possible.
  [Effective snapshot testing](https://kentcdodds.com/blog/effective-snapshot-testing)
- Disagreement: a strict "snapshots only for pure data" stance is stricter than
  this source. Small focused snapshots and custom serializers are endorsed;
  large rendered-DOM snapshots are not.
  [Effective snapshot testing](https://kentcdodds.com/blog/effective-snapshot-testing)
- Do not put snapshot assertions inside `waitFor`.
  [Common mistakes](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)

## Runner choice

- The runner is a project choice. Next.js documents Vitest with RTL and Jest with
  RTL as peers for unit testing; Jest is named for snapshot testing too.
  [Next.js Vitest](https://nextjs.org/docs/app/guides/testing/vitest),
  [Next.js Jest](https://nextjs.org/docs/app/guides/testing/jest)
- Vitest positions itself as the runner of choice for Vite projects and "a solid
  alternative even for projects not using Vite".
  [Vitest: why](https://vitest.dev/guide/why.html)
- RTL: "though we recommend Jest as our preference, the library works with any
  framework". Follow the project's existing runner; Vitest is the natural default
  in a Vite app.
  [RTL intro](https://testing-library.com/docs/react-testing-library/intro)

## Browser layer: E2E and component tests

- jsdom returns zeros for many layout properties and does not calculate layout, so
  layout and visual regression need a real browser.
  [jsdom README](https://raw.githubusercontent.com/jsdom/jsdom/main/README.md)
- **Async Server Components:** Next.js recommends End-to-End testing over unit
  testing, because some tools do not fully support them yet (guide updated
  2026-02-03).
  [Next.js testing guide](https://nextjs.org/docs/app/guides/testing)
- **Playwright component tests** run in a real browser. The experimental
  `@playwright/experimental-ct-react`/`-ct-vue` packages "have been removed and are
  no longer published"; component tests are ordinary `@playwright/test` tests
  using the built-in `mount` fixture against a story page served by your dev
  server. Do not install the removed packages on Playwright 1.63 or later (the 1.63
  release notes say they "will no longer be updated"). In this
  model "The story owns everything the component needs: providers, mock data,
  state, callbacks."
  [Playwright component testing](https://playwright.dev/docs/test-components),
  [Playwright 1.63 release notes](https://playwright.dev/docs/release-notes#version-163)
- Playwright E2E: prefer user-facing locators (`getByRole`) over CSS/XPath, use
  web-first assertions (`await expect(...).toBeVisible()`), and keep each test
  isolated, while accepting "a little duplication".
  [Playwright best practices](https://playwright.dev/docs/best-practices)

```ts
// Playwright, user-facing locator + web-first assertion
await page.getByRole("button", { name: "Add to cart" }).click();
await expect(page.getByRole("status")).toHaveText("Added");
```

## Lint and verification

- Install and use `eslint-plugin-testing-library`: "Install and use the ESLint
  plugin for Testing Library." Kent rates it medium importance.
  [Common mistakes](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)
- Next.js 16: `next lint` was removed and `next build` no longer lints, but it
  fails on TypeScript errors. Run ESLint/Biome, `tsc --noEmit`, tests and the build
  as separate steps.
  [Next.js 16 upgrade](https://nextjs.org/docs/app/guides/upgrading/version-16),
  [Next.js TypeScript](https://nextjs.org/docs/app/api-reference/config/typescript)
- Upgrades: with weak test coverage the React team recommends pinning the compiler
  to an exact version. Check an installed version before using a gated API; React
  docs track only the latest release.
  [React Compiler 1.0](https://react.dev/blog/2025/10/07/react-compiler-1),
  [React versions](https://react.dev/versions)
