---
name: react-hooks-state
description: >
  Use when writing or reviewing React Effects, `useEffect` dependency arrays or
  cleanup, "You Might Not Need an Effect" derived state, `useEffectEvent`, `useRef`,
  custom hooks, Rules of Hooks, `useState`/`useReducer`, Context re-renders and prop
  drilling, where state should live, Redux Toolkit/Zustand/Jotai selectors
  (`useShallow`, infinite loop), Strict Mode double effects, `window is not defined`
  in `useState`, or stale closures.
---

# React Hooks and State

Baseline: **React 19.3**, React Compiler 1.0, `eslint-plugin-react-hooks` 7, Zustand v5,
TanStack Query v5. Gates are stated on each rule: `useEffectEvent` ≥ 19.2,
`<Context value>`, `use()` and ref cleanup callbacks ≥ 19. Preserve the project's React
version. Content is limited to official docs, React-team, library-maintainer and
respected-engineer sources; every rule in the references carries its URL.

## Route by task

| Task | Load |
|---|---|
| Is this an Effect? derived state, resets, deps, cleanup, `useEffectEvent`, Strict Mode, lint | [Effects](references/effects.md) |
| `useState`/`useReducer`, state shape, colocating/lifting, Context, server vs client state, Redux/Zustand/Jotai | [State, Context, stores](references/state-context-stores.md) |
| Refs, custom hooks, Rules of Hooks, `use()`, render purity | [Refs and custom hooks](references/refs-custom-hooks.md) |

Load only the relevant file.

## Workflow

1. Read the React and plugin versions, Compiler/Strict Mode status and existing store
   library before suggesting an API; apply version gates.
2. For each Effect ask why it runs: because the user did something (handler), because
   the value can be computed (derive in render), or because the component is shown and
   must sync with an external system (Effect).
3. Fix a dependency complaint by changing the code (move, derive, split, updater,
   `useEffectEvent`), never by deleting the dependency or suppressing the linter.
4. Put state at the closest common owner; reach for Context or a store only after
   props/`children` composition stops fitting.
5. Report the structural change and any gate you relied on; don't claim runtime
   verification you didn't do.

## High-risk rules

- Calculable from props/state: compute in render. Setter called only synchronously in an
  Effect body: delete the state and derive in render (a setter called from a subscription
  or async callback inside the Effect is legitimate). Reset all state on identity change
  with `key`.
- Effects synchronize with external systems and need a start/stop cycle; make
  Strict Mode's setup→cleanup→setup invisible by fixing the cleanup, not by a ref guard.
- Dependencies must list every reactive value read. Object/function deps re-run the
  Effect: move them out, inside the Effect, or use primitive fields.
- `useEffectEvent` (≥ 19.2): only for logic that is truly an event fired from an Effect;
  omit it from deps; call it only from Effects; never pass it on or use it to dodge deps.
- Don't read/write `ref.current` during render, except one-time lazy init.
- Hooks only at the top level of components/hooks; `use()` is the exception, with limits.
- Zustand v5: a selector returning a new object/array can loop; select primitives or use
  `useShallow`. Export hooks over selectors, not the raw store.
- Context re-renders every consumer on a new value; use it for low-frequency or
  subtree-scoped data. Memoize the provider value only if ancestors can re-render it.
- `useState(() => window.x)` still runs on the server.

## Skill myths

| Myth | What the sources say |
|---|---|
| Route mount Effects through `useMountEffect` / `useEffectOnce` | react.dev: avoid custom "lifecycle" hooks; the linter only checks direct `useEffect` calls ([custom hooks](https://react.dev/learn/reusing-logic-with-custom-hooks#when-to-use-custom-hooks)). A hook named for the system it syncs is fine |
| `useState(() => window.innerWidth)` fixes SSR | The initializer runs during server render too ([useState](https://react.dev/reference/react/useState), [Next.js #51459](https://github.com/vercel/next.js/issues/51459)); it only saves re-render cost. Use a guard, `useSyncExternalStore` + `getServerSnapshot`, or an Effect |
| `useEffectEvent` results are stable | "do not have a stable identity", intentionally ([useEffectEvent](https://react.dev/reference/react/useEffectEvent)); omit from deps because non-reactive |
| Keep a latest-callback ref in Effects | Works on any version. From 19.2, the documented answer for logic that is an event fired from an Effect is `useEffectEvent` ([Dan](https://overreacted.io/a-complete-guide-to-useeffect/), [19.2](https://react.dev/blog/2025/10/01/react-19-2)) |
| Never call `useEffect` / ban it | "You *do* need Effects to synchronize with external systems" ([docs](https://react.dev/learn/you-might-not-need-an-effect)). A repo ban is team policy, not React guidance |
| ALWAYS use functional `setState` | "no harm … not always necessary" ([useState](https://react.dev/reference/react/useState)); use for batching, stable callbacks, Effect deps |
| Always `useMemo` the Context value | Only when the provider isn't at the root and ancestors re-render it ([Nadia](https://www.developerway.com/posts/react-re-renders-guide)); "In smaller apps, this is not a problem" ([useContext](https://react.dev/reference/react/useContext)) |
| No prop drilling beyond 2 levels | No depth threshold; pass props first, then extract components/`children` ([docs](https://react.dev/learn/passing-data-deeply-with-context#before-you-use-context)) |
| Custom hooks only for 2+ components / all logic in hooks | "consider" wrapping every Effect; "Some duplication is fine" ([docs](https://react.dev/learn/reusing-logic-with-custom-hooks#when-to-use-custom-hooks)) |
| Never copy server data into local state | Syncing via Effect is a smell ([TkDodo](https://tkdodo.eu/blog/deriving-client-state-from-server-state)); a form draft seeded from query data is an accepted exception when done deliberately ([TkDodo](https://tkdodo.eu/blog/react-query-and-forms)) |
| No Redux / RTK | "Not all apps need Redux" ([FAQ](https://redux.js.org/faq/general)); selection is need-driven, RTK is recommended when Redux is used ([Style Guide](https://redux.js.org/style-guide/)). A ban is project policy |
| Zustand/Jotai for small apps, Redux Toolkit for large | Libraries position themselves as scalable ([Jotai](https://jotai.org/)); Redux's criteria: amount/sharing of state, update frequency and complexity, codebase/team size, traceability ([FAQ](https://redux.js.org/faq/general)) |
| `use()` replaces `useContext()` | `use` adds conditional reads; `useContext` remains documented ([use](https://react.dev/reference/react/use)) |
| `useSyncExternalStore` is required for stores | "preferred" over Effect subscriptions ([docs](https://react.dev/learn/you-might-not-need-an-effect#subscribing-to-an-external-store)); mostly useful for integrating existing non-React code ([useSyncExternalStore](https://react.dev/reference/react/useSyncExternalStore)) |
| `useRef` guard fixes the Strict Mode double effect | It hides the second run but doesn't fix the bug; fix cleanup ([Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects)) |
| Mount Effect `[]` is `componentDidMount` | "not an exact equivalent" ([Dan](https://overreacted.io/a-complete-guide-to-useeffect/)) |

## Handoffs

Optional installed-skill handoffs (none is an installation dependency):
**react-performance** (memoization, re-render mechanics, Compiler, transitions),
**react-components-typescript** (composition, props, keys, controlled inputs, TS types),
**react-server-data** (fetching, Server Components, Actions, `use` with Promises),
**react-testing-a11y** (testing hooks/components, accessibility); plus
**typescript-type-modeling** for general types, **web-performance-optimization** for
non-React web vitals, **test-engineering** for test strategy, **ui-taste** for visual
design.

See [README](README.md#sources-and-decisions) for evidence basis, correction decisions
and excluded claims.
