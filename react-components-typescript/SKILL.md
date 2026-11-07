---
name: react-components-typescript
description: >
  Use when designing or reviewing React components: composition and `children`,
  prop drilling, boolean-prop sprawl, discriminated props, list `key` bugs and
  state resets, components defined inside components, error boundaries,
  `{count && <X/>}` rendering "0", controlled vs uncontrolled inputs, impure
  render, default vs named exports, or TypeScript with React (`ReactNode`,
  `React.FC`, event types, typing hooks, `defaultProps`/`propTypes` removed in
  19, `JSX` namespace).
---

# React Components and TypeScript

Community-backed guidance only (react.dev, React team, library maintainers,
respected engineers, company blogs). Baseline: **React 19.3**, React Compiler 1.0,
eslint-plugin-react-hooks 7, Next.js 16 App Router, React Router 8, TypeScript 5.x
with `@types/react` 19. State a version gate wherever a rule has one.
Statements marked "project policy" are not consensus.

## Route by task

| Task | Load |
|---|---|
| Prop drilling, `children`, splitting components, variants/booleans, controlled vs uncontrolled, prop-to-state copies, exports, class components | [Composition and props](references/composition-props.md) |
| `key` bugs and state reset, nested component definitions, `&&` rendering, purity, error boundaries | [Identity and rendering](references/identity-rendering.md) |
| Typing props/children/events/hooks, `React.FC`, `interface` vs `type`, `any`, React 19 type changes | [TypeScript with React](references/typescript-react.md) |

Load only the needed file; each rule there carries its source URL.

## Workflow

1. Read the project's React/TypeScript versions, lint rules and existing
   conventions (exports, props typing). Follow them unless they cause a bug.
2. Classify the symptom: lost state or remounts (identity/keys), stray `0` or
   wrong output (conditional rendering), stale props copy (state), an uncaught
   error (boundaries), an `any` or wrong children type (TypeScript).
3. Fix the cause at the shared definition (hoist the component, correct the key,
   fix the prop type), then update every caller.
4. Where sources disagree (index keys, `interface` vs `type`, `React.FC`,
   default vs named exports), state both positions and follow the repo's
   convention; do not "fix" style that is not a defect.
5. Report which rules were applied, version gates, and what was not run.

## High-risk rules

- **Never define a component inside another component** (new type each render:
  subtree remounts, state lost). Declare at module top level.
- **Keys:** stable IDs from data for dynamic/reorderable lists; index is
  acceptable only for static, never-reordering lists. **Never generate keys in
  render** (`Math.random()`); create IDs when the item is created. Unique among
  siblings only.
- A **different `key`** (or a different component type at the same position)
  resets the subtree's state; that also discards local drafts.
- **Conditional `&&`:** put a boolean on the left (`count > 0 && <X/>`); a numeric
  left side renders `0`. Ternary is not the documented fix.
- **Pass props first.** Depth alone is not a reason for context. Extract
  components and pass `children` when intermediates only forward data.
- **Do not mirror props into state** unless intentionally ignoring later updates;
  then name it `initial*`/`default*`.
- **Purity:** do not mutate pre-existing values (props, state, module variables)
  while rendering. Mutating objects created in the same render is fine.
- **Error boundaries** must be classes (or `react-error-boundary`). They do not
  catch event-handler errors, errors in asynchronous callbacks (e.g.
  `setTimeout`), SSR errors, or errors in the boundary itself. Errors thrown in
  the function passed to the `startTransition` returned by `useTransition` are
  caught (React 19+ per react-error-boundary); the standalone `startTransition`
  import is not caught.
- **TypeScript:** `children: React.ReactNode`; `React.JSX.Element` instead of bare
  `JSX.Element` (React 19 types); explicit event types when a handler is
  extracted; `useState<Union>()` for unions; consumer hook that throws for a
  null-default context. React 19 ignores `propTypes` and removes `defaultProps`
  on function components: use TS types and default parameters.
- `React.FC` is not needed (fine since TS 5.1 with React 18 types); it cannot
  type generic components. Prefer `unknown` + narrowing to `any`.

## Skill myths

| Myth | What the sources say |
|---|---|
| Prop drilling beyond ~2 levels means use composition or context | "it's not unusual to pass a dozen props down through a dozen components"; depth is not a reason for context. [react.dev](https://react.dev/learn/passing-data-deeply-with-context#before-you-use-context) |
| Functional components only, never classes | "Class components are still supported", not recommended for new code; Error Boundaries still need a class. [react.dev](https://react.dev/reference/react/Component) |
| Use a ternary instead of `&&` | Danger is a number on the left; fix is a boolean left side. [react.dev](https://react.dev/learn/conditional-rendering) |
| Error boundaries are required on every route | One reusable boundary where it makes sense ([react.dev](https://react.dev/reference/react/Component)); per-route is a framework convention ([Next.js](https://nextjs.org/docs/app/getting-started/error-handling), [React Router](https://reactrouter.com/how-to/error-boundary)) or a team choice. |
| Inline props only; never extract `XxxProps` | Inline is simplest, "unwieldy" as fields grow; export the props type. [react.dev](https://react.dev/learn/typescript), [Pocock](https://www.totaltypescript.com/react-props-typescript) |
| Named exports only (or default only) | "Do what works best for you!" ([react.dev](https://react.dev/learn/importing-and-exporting-components)); plain `lazy(() => import(...))` needs a default export ([react.dev/lazy](https://react.dev/reference/react/lazy)). |
| Never `import React` / never use the `React.` namespace | The JSX transform drops the import for JSX ([React blog](https://legacy.reactjs.org/blog/2020/09/22/introducing-the-new-jsx-transform.html)); react.dev's own TS guide uses `React.ReactNode`. [react.dev](https://react.dev/learn/typescript) |
| Split container (logic) and presentational (UI) components | Its author no longer suggests it; "dogmatic fervor"; Hooks separate logic without a split. [Abramov](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0) |
| Never use array index as a key | Fine for static lists that never reorder. [react.dev](https://react.dev/learn/rendering-lists) |
| No mutation at all during render | Changing variables and objects you just created is fine. [react.dev](https://react.dev/learn/keeping-components-pure) |
| Move all logic into hooks; never fetch in a component body | Hooks for Effects/duplication ("Some duplication is fine") ([react.dev](https://react.dev/learn/reusing-logic-with-custom-hooks)); async Server Components await data directly ([react.dev](https://react.dev/reference/rsc/server-components#async-components-with-server-components)). |
| `React.FC` is an anti-pattern to remove | "Fine" since TS 5.1; no reason to remove existing use. [Pocock](https://www.totaltypescript.com/you-can-stop-hating-react-fc) |
| `interface` is the rule for props | Contested: Pocock's props article says "In general, you should use `interface` to declare your props"; his later article says "use `type` by default", with interfaces for object inheritance; react.dev accepts either. [props](https://www.totaltypescript.com/react-props-typescript), [type vs interface](https://www.totaltypescript.com/type-vs-interface-which-should-you-use) |

## Handoffs (optional; none is an installation dependency)

- **react-hooks-state** for Effects, derived state, custom Hook rules, Context
  and state libraries; **react-performance** for memoization, `lazy`, re-render
  cost; **react-server-data** for `use`, Server Components, Suspense, ref as
  prop; **react-testing-a11y** for tests, ARIA, focus.
- **typescript-type-modeling** for general type design; **test-engineering** for
  test strategy; **web-performance-optimization** for non-React web vitals;
  **ui-taste** for visual design.

Evidence basis, decisions and excluded claims: [README](README.md#sources-and-decisions).
