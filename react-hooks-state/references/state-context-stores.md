# State, Context, and stores

Baseline: React 19.3, Zustand v5, TanStack Query v5. Every rule ends with its source.
Where the community disagrees, each position and its context are stated.

## Contents

1. [`useState`, updaters, `useReducer`](#1-usestate-updaters-usereducer)
2. [State structure and immutability](#2-state-structure-and-immutability)
3. [Where state lives: colocate, lift, then share](#3-where-state-lives-colocate-lift-then-share)
4. [Context](#4-context)
5. [Server state vs client state](#5-server-state-vs-client-state)
6. [External stores: `useSyncExternalStore`, Zustand, Redux, Jotai](#6-external-stores)
7. [Storage and transitions](#7-storage-and-transitions)

## 1. `useState`, updaters, `useReducer`

- `setState` doesn't change the value you already hold; it schedules the next render and
  each render sees a snapshot. Updates are batched after handlers finish. Refs differ:
  mutating `ref.current` is immediate. Sources:
  [State as a Snapshot](https://react.dev/learn/state-as-a-snapshot),
  [Queueing a Series of State Updates](https://react.dev/learn/queueing-a-series-of-state-updates).
- Use an updater (`setN(n => n + 1)`) for several updates in one event, when reading state
  is inconvenient, or to drop an Effect dependency. The docs say a plain value is "no harm
  … but it is also not always necessary"; always writing updaters is a consistency
  preference, not a requirement. Sources:
  [useState (updater DeepDive)](https://react.dev/reference/react/useState),
  [Removing Effect Dependencies](https://react.dev/learn/removing-effect-dependencies).
- Pass a function to `useState` when the initial value is expensive:
  `useState(() => build())`. `useState(build())` calls `build()` every render ("no
  observable difference in behavior, but this code is less efficient"). The initializer
  must be pure and take no arguments. For cheap values it is unnecessary. Source:
  [useState](https://react.dev/reference/react/useState).
- The lazy initializer still runs during server rendering, so `useState(() => window.x)`
  throws on the server just like `useState(window.x)`. Lazy init is a re-render-cost fix,
  not an SSR fix. For browser-only values use a `typeof window` guard with a hydration-safe
  pattern, `useSyncExternalStore` with `getServerSnapshot`, or set it after mount in an
  Effect. Sources: [useState](https://react.dev/reference/react/useState),
  [Next.js issue 51459](https://github.com/vercel/next.js/issues/51459),
  [useSyncExternalStore](https://react.dev/reference/react/useSyncExternalStore).
- `useReducer` is an option, not the default for all complex state: use it when you often
  hit bugs from incorrect updates and want structure; "feel free to mix and match". With
  `useState` you generally write less code upfront. Source:
  [Extracting State Logic into a Reducer](https://react.dev/learn/extracting-state-logic-into-a-reducer).
- Reducers must be pure (they run during rendering: no requests, timeouts, or side
  effects; no mutation). Each action describes one user interaction, even if it changes
  several fields (`reset_form`, not five `set_field`). Source:
  [Extracting State Logic into a Reducer](https://react.dev/learn/extracting-state-logic-into-a-reducer#writing-reducers-well).

```tsx
type Action = { type: "added"; text: string } | { type: "toggled"; id: number };
function tasksReducer(tasks: Task[], action: Action): Task[] {
  switch (action.type) {
    case "added":
      return [...tasks, { id: nextId(tasks), text: action.text, done: false }];
    case "toggled":
      return tasks.map((t) => (t.id === action.id ? { ...t, done: !t.done } : t));
  }
}
```

## 2. State structure and immutability

- Group variables that always change together; avoid contradictory, duplicated, and
  deeply nested state; prefer flat state (normalize by id if nesting is hard to update).
  Source: [Choosing the State Structure](https://react.dev/learn/choosing-the-state-structure).
- Replace booleans that must never be true together (`isSending`, `isSent`) with one
  `status` variable; derive the booleans. Sources:
  [Choosing the State Structure](https://react.dev/learn/choosing-the-state-structure#avoid-contradictions-in-state).
- For selection, keep the id (or index) in state and look the object up during render.
  The Redux FAQ gives the same advice for store state. Sources:
  [Choosing the State Structure](https://react.dev/learn/choosing-the-state-structure#avoid-duplication-in-state),
  [Redux FAQ: organizing state](https://redux.js.org/faq/organizing-state).
- Treat state and props as read-only: don't mutate inputs (props, state, context). Mutating
  values you created during the same render is fine. Sources:
  [Keeping Components Pure](https://react.dev/learn/keeping-components-pure),
  [Updating Objects in State](https://react.dev/learn/updating-objects-in-state).
- `.sort()` and `.reverse()` mutate; copy first (`[...list].sort()`). `toSorted()` is the
  copying equivalent (ES2023: Chrome 110, Firefox 115, Safari 16, Node 20, TS 5.2 typings);
  check the browser/TS baseline. Sources:
  [Updating Arrays in State](https://react.dev/learn/updating-arrays-in-state),
  [MDN: Array.prototype.toSorted](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/toSorted).

## 3. Where state lives: colocate, lift, then share

- Place state in the closest common parent of the components that render from it; don't
  lift further than necessary. Transient state (forms, hover) doesn't belong at the top of
  the tree or in a global library. Sources:
  [Sharing State Between Components](https://react.dev/learn/sharing-state-between-components),
  [Thinking in React](https://react.dev/learn/thinking-in-react#step-4-identify-where-your-state-should-live),
  [memo (DeepDive)](https://react.dev/reference/react/memo),
  [State Colocation (Kent C. Dodds)](https://kentcdodds.com/blog/state-colocation-will-make-your-react-app-faster).
- Higher-placed state invalidates a larger subtree on each update; colocation reduces the
  work React does. In Redux, keep only truly global state there. Source:
  [State Colocation (Kent C. Dodds)](https://kentcdodds.com/blog/state-colocation-will-make-your-react-app-faster).
- Before reaching for Context, pass props, then extract components and pass JSX as
  `children`. Passing props several levels deep is not by itself a reason for context; the
  docs give no depth threshold ("it's not unusual to pass a dozen props down through a
  dozen components"). Source:
  [Passing Data Deeply with Context](https://react.dev/learn/passing-data-deeply-with-context#before-you-use-context).
- A provider component that owns a reducer can let any component below read and dispatch
  without drilling; use it for a scoped subtree, not as the default for every sharing
  problem. Sources: [Scaling Up with Reducer and Context](https://react.dev/learn/scaling-up-with-reducer-and-context),
  [Application State Management with React (Kent C. Dodds)](https://kentcdodds.com/blog/application-state-management-with-react).

## 4. Context

- Version gate: React ≥ 19 renders `<SomeContext value={…}>` directly; `<SomeContext.Provider>`
  still works (the docs call it legacy; the 19 post says it will be deprecated). In
  React < 19 use `.Provider`. Sources: [createContext](https://react.dev/reference/react/createContext),
  [React 19 blog](https://react.dev/blog/2024/12/05/react-19#context-as-a-provider).
- Split state and dispatch into separate contexts, and split unrelated concerns into
  separate providers ("multiple logically separated contexts"). Cost: provider nesting;
  Mark Erikson's opinion is that past 2–3 state contexts you are reinventing React-Redux.
  Sources: [Scaling Up with Reducer and Context](https://react.dev/learn/scaling-up-with-reducer-and-context),
  [Application State Management with React](https://kentcdodds.com/blog/application-state-management-with-react),
  [How to use React Context effectively (Kent C. Dodds)](https://kentcdodds.com/blog/how-to-use-react-context-effectively)
  ("you can (and probably should) have multiple logically separated contexts in your app"),
  [Context vs Redux (Mark Erikson)](https://blog.isquaredsoftware.com/2021/01/context-redux-differences/).
- Consumers re-render when the value reference changes, and `memo` doesn't stop it; a
  consumer can't skip updates for part of the value. React docs: "In smaller apps, this is
  not a problem." No selector API exists in `useContext` (the context-selector RFC is
  still open). To react to part of a context, read it in an outer component and pass the
  part to a memoized child. Sources: [useContext](https://react.dev/reference/react/useContext),
  [memo](https://react.dev/reference/react/memo),
  [React rendering behavior (Mark Erikson)](https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior),
  [Context selectors RFC](https://github.com/reactjs/rfcs/pull/119).
- Memoize the provider `value` only when the provider is not at the app root and can
  re-render from ancestor changes; it removes spurious updates but can't prevent
  re-renders of consumers when the value really changes. A provider at the root whose own
  state is the only trigger has nothing to memoize. With React Compiler enabled it
  memoizes automatically in most cases; components that break the Rules of React are
  skipped ("automatically skips over those components and hooks"). Sources:
  [React re-renders guide (Nadia Makarevich)](https://www.developerway.com/posts/react-re-renders-guide),
  [React Compiler introduction](https://react.dev/learn/react-compiler/introduction),
  [eslint-plugin-react-hooks reference](https://react.dev/reference/eslint-plugin-react-hooks).
- Where sources differ: Mark Erikson and TkDodo describe Context as a dependency-injection
  transport, not a state manager (state lives in `useState`/`useReducer` or a store);
  react.dev teaches reducer + context for subtree state. Both agree it is valid for scoped
  subtree state and low-frequency data (locale, theme), not a general store for
  high-frequency updates. "Never" is a threshold judgment: Markbage's 2018 guidance was
  that context is "ready to be used for low frequency unlikely updates (like
  locale/theme)". Sources: [Context vs Redux](https://blog.isquaredsoftware.com/2021/01/context-redux-differences/),
  [React Query and React Context (TkDodo)](https://tkdodo.eu/blog/react-query-and-react-context)
  ("React Context is a *dependency injection* tool"),
  [Markbage on React issue 14110](https://github.com/facebook/react/issues/14110),
  [Scaling Up with Reducer and Context](https://react.dev/learn/scaling-up-with-reducer-and-context).
- `use(context)` (React ≥ 19) can be called in loops and conditionals but is not available
  in Server Components, and `useContext` remains documented; `use` doesn't deprecate it.
  Sources: [use](https://react.dev/reference/react/use), [useContext](https://react.dev/reference/react/useContext).

## 5. Server state vs client state

- Keep server state in a server-state library or framework; the global client state left
  after that is usually "very tiny". Apps with a lot of synchronous client-only state
  (a visual designer, music production) still want a client store. Source:
  [TanStack Query: does this replace client state](https://tanstack.com/query/latest/docs/framework/react/guides/does-this-replace-client-state).
- Don't copy `useQuery` data into `useState` through an Effect (you opt out of background
  updates and create staleness). Exception, a form draft seeded from query data: keep it
  small, mount it after data arrives or `key` it, and track only the user's edits.
  Sources: [Practical React Query (TkDodo)](https://tkdodo.eu/blog/practical-react-query),
  [React Query and Forms (TkDodo)](https://tkdodo.eu/blog/react-query-and-forms),
  [Putting props to useState (TkDodo)](https://tkdodo.eu/blog/putting-props-to-use-state).
- Without a framework, Effect-based fetching is acceptable if it ignores stale responses;
  extract it into a custom Hook. Source:
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect).

## 6. External stores

- Choosing a library is need-driven; none of the sources reviewed names a default or makes
  app size the deciding criterion. Redux lists five criteria: large amounts of state
  needed in many places, frequent updates, complex update logic, large codebase/many
  contributors, need to see how state changes over time. Jotai and Zustand both claim to
  scale to large apps. "Not all apps need Redux." Jotai says it "scales from a simple
  `useState` replacement to an enterprise TypeScript application"; TkDodo uses Zustand in
  "projects small and large". Dan Abramov's quote in the Redux FAQ: "don't use Redux until
  you have problems with vanilla React". Mark Erikson: Redux isn't dead. Sources:
  [Redux FAQ](https://redux.js.org/faq/general),
  [Jotai](https://jotai.org/),
  [Working with Zustand (TkDodo)](https://tkdodo.eu/blog/working-with-zustand),
  [Redux isn't dead yet (Mark Erikson)](https://blog.isquaredsoftware.com/2018/03/redux-not-dead-yet).
- Project policy, not consensus: follow the repository's existing store library; if it has
  none, choose by the criteria above rather than by habit, and avoid mixing two stores for
  the same category of state.
- `useSyncExternalStore`: "preferred" over an Effect subscription, mostly useful for
  integrating existing non-React code (Zustand and react-redux already wrap it). `getSnapshot`
  must return the same cached, immutable value while the store is unchanged; declare
  `subscribe` outside the component; provide `getServerSnapshot` for server rendering. Where
  possible use built-in state first. Sources:
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#subscribing-to-an-external-store),
  [useSyncExternalStore](https://react.dev/reference/react/useSyncExternalStore),
  [Zustand `react.ts`](https://raw.githubusercontent.com/pmndrs/zustand/main/src/react.ts)
  (`React.useSyncExternalStore`),
  [react-redux `useSelector.ts`](https://raw.githubusercontent.com/reduxjs/react-redux/master/src/hooks/useSelector.ts)
  (`useSyncExternalStoreWithSelector`).
- Zustand selectors (v5): use a selector for each read; TkDodo's rule is "always use
  selectors", even though Zustand treats them as optional. Selectors must return stable
  results. In v4 a new object/array from a selector only caused extra re-renders; in v5
  "if a selector returns a new reference, it may cause infinite loops", so select
  primitives (atomic selectors) or wrap object/array selections in `useShallow`. Sources:
  [Working with Zustand (TkDodo)](https://tkdodo.eu/blog/working-with-zustand),
  [Migrating to v5](https://raw.githubusercontent.com/pmndrs/zustand/main/docs/reference/migrations/migrating-to-v5.md),
  [Prevent rerenders with useShallow](https://zustand.docs.pmnd.rs/learn/guides/prevent-rerenders-with-use-shallow).
- Zustand structure (TkDodo): export custom hooks around selectors, not the raw store
  hook; keep actions in a separate `actions` object (static, not state); prefer several
  small stores to one app-wide store. Source: [Working with Zustand (TkDodo)](https://tkdodo.eu/blog/working-with-zustand).
- Redux (Redux Style Guide): never mutate state in reducers or elsewhere (Immer via
  Redux Toolkit makes "mutating" syntax safe); reducers do no async work, random/time
  values, or outside mutation; keep Promises, Maps/Sets, functions, class instances out of
  state and actions (middleware-intercepted actions are an exception); one store, passed
  via `Provider`; Redux Toolkit is the recommended toolset when using Redux (not required).
  Sources: [Redux Style Guide](https://redux.js.org/style-guide/),
  [RTK is Redux today](https://redux.js.org/introduction/why-rtk-is-redux-today),
  [Immer in Redux Toolkit](https://redux.js.org/toolkit/usage/immer-reducers).
- Jotai: keep render functions cheap and idempotent (they may run several times, even at
  mount); do heavy computation outside the React lifecycle (in actions); split state into
  atoms and use `selectAtom`/`focusAtom` for rarely changing parts of a large object; keep
  derived-atom chains shallow, model long collections as data in one atom. The page says it
  "has room for improvement". Source: [Jotai performance guide](https://jotai.org/docs/guides/performance).
- High-frequency values that don't drive UI: Zustand documents transient updates
  (subscribe without re-rendering); a ref is the React-level equivalent
  (see [refs-custom-hooks.md](refs-custom-hooks.md)). Source:
  [Zustand README: transient updates](https://raw.githubusercontent.com/pmndrs/zustand/main/README.md).

```tsx
// Zustand v5: atomic selectors return primitives/stable refs
const count = useCounterStore((s) => s.count);
const { a, b } = useCounterStore(useShallow((s) => ({ a: s.a, b: s.b })));
// Avoid in v5: useCounterStore((s) => ({ a: s.a, b: s.b })) -> may loop
```

## 7. Storage and transitions

- `localStorage`: wrap the property access as well as `setItem` in `try/catch`.
  `setItem` throws `QuotaExceededError`; reading `window.localStorage` can throw
  `SecurityError` when storage is blocked; some browsers in private mode give a
  zero-quota storage. Sources:
  [MDN: Storage.setItem](https://developer.mozilla.org/en-US/docs/Web/API/Storage/setItem),
  [MDN: Window.localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage),
  [MDN: Using the Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API/Using_the_Web_Storage_API).
- `useTransition` (async Actions, React ≥ 19) provides `isPending` for updates you wrap in
  `startTransition`; it can't control text inputs, and state updates after an `await` in an
  Action currently must be re-wrapped in `startTransition` (a documented limitation). It
  doesn't replace loading state owned
  by a fetch library or an Effect. Sources: [useTransition](https://react.dev/reference/react/useTransition),
  [React 19 blog](https://react.dev/blog/2024/12/05/react-19). Actions and forms:
  **react-server-data**; responsiveness: **react-performance**.
