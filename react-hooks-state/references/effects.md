# Effects, derived state, dependencies, Strict Mode

Baseline: React 19.3, `eslint-plugin-react-hooks` 7, React Compiler 1.0. Every rule
ends with its source. Version gates are stated on the rule.

## Contents

1. [Do you need an Effect?](#1-do-you-need-an-effect)
2. [Derived state and resets](#2-derived-state-and-resets)
3. [Dependencies](#3-dependencies)
4. [Cleanup and Strict Mode](#4-cleanup-and-strict-mode)
5. [`useEffectEvent` (React ≥ 19.2)](#5-useeffectevent-react--192)
6. [`useLayoutEffect`, one-time init, lint rules](#6-uselayouteffect-one-time-init-lint-rules)

## 1. Do you need an Effect?

- Effects synchronize a component with an external system (non-React widget, network,
  browser DOM). Without an external system you probably don't need one. Sources:
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect),
  [useEffect](https://react.dev/reference/react/useEffect).
- Effects remain the sanctioned tool for external synchronization; the docs say
  "You *do* need Effects to synchronize with external systems". "Most Effects are
  unnecessary" is supported; "never call `useEffect`" is not. Sources:
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect),
  [Compiler 1.0 post](https://react.dev/blog/2025/10/07/react-compiler-1) ("While we
  encourage useEffect only for synchronization, your codebase may have useEffects that
  cover other use cases").
- Criterion: logic caused by a particular interaction stays in the event handler;
  logic caused by the user seeing the component stays in the Effect. Mount-time
  analytics logging legitimately stays an Effect. Sources:
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect),
  [Separating Events from Effects](https://react.dev/learn/separating-events-from-effects).
- Think in one start/stop synchronization cycle per Effect, not mount/update/unmount.
  Each Effect is one independent synchronization process; split unrelated work into
  separate Effects. Sources:
  [Lifecycle of Reactive Effects](https://react.dev/learn/lifecycle-of-reactive-effects),
  [Removing Effect Dependencies](https://react.dev/learn/removing-effect-dependencies).
- Subscribing to an external store: prefer `useSyncExternalStore` over a hand-written
  Effect. Source: [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#subscribing-to-an-external-store).
- Chains of Effects that set state to trigger other Effects: compute during render and
  set the next state in the handler. Exception: when the next step depends on
  network-fetched data (dropdown options depending on the previous selection), a chain
  is appropriate. Source: [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#chains-of-computations).
- Notifying a parent: update both states in the same event handler, or lift state up
  ("Whenever you try to keep two different state variables synchronized, try lifting
  state up instead!"). Let the parent fetch and pass data down instead of the child
  pushing it up from an Effect. Source: [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#passing-data-to-the-parent).
- Effects run only on the client, never during server rendering. Source:
  [Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects).
- Effects read the props/state of the render that created them, not the latest values.
  Source: [A Complete Guide to useEffect (Dan Abramov)](https://overreacted.io/a-complete-guide-to-useeffect/).
- Fetching in an Effect is acceptable without a framework (add ignore/abort cleanup;
  consider extracting a custom Hook); a framework or server-state library is more
  efficient. Client fetching mechanics belong to **react-server-data**. Sources:
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect),
  [TanStack: does this replace client state](https://tanstack.com/query/latest/docs/framework/react/guides/does-this-replace-client-state).

## 2. Derived state and resets

- When something can be calculated from existing props or state, calculate it during
  rendering; don't store it in state and sync with an Effect. Sources:
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect),
  [Don't Sync State. Derive It! (Kent C. Dodds)](https://kentcdodds.com/blog/dont-sync-state-derive-it),
  [Don't over-use state (TkDodo)](https://tkdodo.eu/blog/dont-over-use-state)
  ("Whenever a state setter function is only used synchronously in an effect, get rid of the state!").
- Expensive derivation: wrap the pure calculation in `useMemo`; the docs say "Usually,
  this code is fine!" for plain derivation, and measure before memoizing. With the
  React Compiler on, manual `useMemo` is needed less ("in many cases"). Sources:
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#caching-expensive-calculations),
  [Writing Resilient Components (Dan Abramov)](https://overreacted.io/writing-resilient-components/).
  Memoization mechanics: **react-performance**.
- Don't mirror props into state. A mirror is correct only when you want to ignore later
  prop updates; then name the prop `initial*` / `default*`. Sources:
  [Choosing the State Structure](https://react.dev/learn/choosing-the-state-structure#avoid-redundant-state),
  [Writing Resilient Components](https://overreacted.io/writing-resilient-components/).
- Reset all state when an identity changes: render the child with `key={id}`. Cost: React
  recreates the DOM and state of that component and all its children. Sources:
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#resetting-all-state-when-a-prop-changes).
- Reset only part of the state: store ids and derive the object (`selectedId` +
  `items.find(...)`), or adjust state during render with a `prev` check. The render-time
  adjustment is more efficient than an Effect, "but most components shouldn't need it";
  it needs a condition like `items !== prevItems` to avoid loops and only works on the
  same component's state. Sources:
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#adjusting-some-state-when-a-prop-changes),
  [Choosing the State Structure](https://react.dev/learn/choosing-the-state-structure).
- Form draft from fetched data: mount the form after data arrives (or `key` it), keep the
  draft small, and separate server state from the user's edits. Sources:
  [Putting props to useState (TkDodo)](https://tkdodo.eu/blog/putting-props-to-use-state),
  [React Query and Forms (TkDodo)](https://tkdodo.eu/blog/react-query-and-forms).
- Don't set a default or validated selection from query data in an Effect; derive it at
  read time from server state plus the client's selection. Source:
  [Deriving Client State from Server State (TkDodo)](https://tkdodo.eu/blog/deriving-client-state-from-server-state).

```tsx
// Derive; do not mirror in state + Effect
const visible = todos.filter((t) => (showDone ? true : !t.done));

// Partial reset: keep the id, derive the object
const [selectedId, setSelectedId] = useState<string | null>(null);
const selected = items.find((i) => i.id === selectedId) ?? null;

// Full reset: new identity, new state
<Profile key={userId} userId={userId} />;
```

## 3. Dependencies

- Dependencies must include every reactive value the Effect reads; the linter enforces
  it and you can't "choose" them. Don't suppress `exhaustive-deps`; restructure instead.
  `useLayoutEffect` has the same dependency contract, so switching hooks doesn't dodge
  it. Sources: [Lifecycle of Reactive Effects](https://react.dev/learn/lifecycle-of-reactive-effects),
  [exhaustive-deps lint](https://react.dev/reference/eslint-plugin-react-hooks/lints/exhaustive-deps),
  [useLayoutEffect](https://react.dev/reference/react/useLayoutEffect) (same `dependencies` verification),
  [A Complete Guide to useEffect](https://overreacted.io/a-complete-guide-to-useeffect/)
  ("removing a dependency you use (or blindly specifying `[]`) is usually the wrong fix").
- To remove a dependency, change the code so it is provably non-reactive (move the value
  outside the component, inside the Effect, or read fields); don't just delete it.
  Source: [Removing Effect Dependencies](https://react.dev/learn/removing-effect-dependencies).
- Object and function dependencies are new each render and re-run the Effect. Remedies, in
  the docs' order: move outside the component, move inside the Effect, extract primitive
  fields; a memoized object/function is a valid dependency when it must keep identity
  (`useMemo`/`useCallback`, better yet remove the need). "Primitives only" is not a rule;
  never drop a real dependency to get one. Sources:
  [Removing Effect Dependencies](https://react.dev/learn/removing-effect-dependencies),
  [useMemo](https://react.dev/reference/react/useMemo),
  [useCallback](https://react.dev/reference/react/useCallback),
  [A Complete Guide to useEffect](https://overreacted.io/a-complete-guide-to-useeffect/).
- State used only to compute the next state: pass an updater (`setMsgs(m => [...m, x])`)
  and the Effect no longer depends on it. If the Effect needs the latest value without
  re-running, that is the `useEffectEvent` case. Source:
  [Removing Effect Dependencies](https://react.dev/learn/removing-effect-dependencies#are-you-reading-some-state-to-calculate-the-next-state).
- Stable values (set functions, `useRef` objects) are not reactive and may be omitted.
  Source: [Lifecycle of Reactive Effects](https://react.dev/learn/lifecycle-of-reactive-effects).
- Lint blind spot: the linter checks direct `useEffect` calls, not custom wrapper hooks.
  Custom effect hooks can be registered via `settings["react-hooks"].additionalEffectHooks`
  (plugin ≥ 6.1.1). Source: [exhaustive-deps lint](https://react.dev/reference/eslint-plugin-react-hooks/lints/exhaustive-deps).

## 4. Cleanup and Strict Mode

- Cleanup mirrors setup: connect/disconnect, subscribe/unsubscribe, fetch/cancel-or-ignore,
  timers. It is needed "if needed": an Effect with nothing to stop or undo (e.g.
  analytics-on-visit) needs none. Sources:
  [Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects),
  [How to support Reusable State in Effects (Brian Vaughn)](https://github.com/reactwg/react-18/discussions/18).
- Rule of thumb: the user shouldn't be able to distinguish one run (production) from
  setup → cleanup → setup (development). Source:
  [Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects).
- Create imperative objects inside the Effect that destroys them, not in a ref initialized
  during render, so remounting works. Source:
  [Reusable State in Effects (Brian Vaughn)](https://github.com/reactwg/react-18/discussions/18).
- Strict Mode (React 18+, development only) re-runs Effects to expose missing cleanup, and
  in React 19 also re-runs ref callbacks. "The right question isn't 'how to run an Effect
  once', but 'how to fix my Effect so that it works after remounting'". Production runs
  once. Sources: [StrictMode](https://react.dev/reference/react/StrictMode),
  [Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects).
- Wrap the whole app in `<StrictMode>`; there is no opt-out inside the tree, and Effects
  are not re-run on initial mount if it isn't at the root. Source:
  [StrictMode](https://react.dev/reference/react/StrictMode#enabling-strict-mode-for-entire-app).
- A `useRef` guard can hide the development double-run (the log appears once) but doesn't
  fix the bug: the connection is still never closed. Fix the cleanup. A ref guard is only
  defensible for a run-once Effect with nothing to undo. Sources:
  [Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects)
  ("Don't use refs to prevent Effects from firing": it "doesn't fix the bug"),
  [exhaustive-deps lint](https://react.dev/reference/eslint-plugin-react-hooks/lints/exhaustive-deps),
  [Reusable State in Effects (Brian Vaughn)](https://github.com/reactwg/react-18/discussions/18).
- Debugging a double-run: it is a dev-only check, not a React bug; the missing cleanup or
  impure render is the defect. Source: [StrictMode](https://react.dev/reference/react/StrictMode).

```tsx
useEffect(() => {
  const connection = createConnection(serverUrl, roomId);
  connection.connect();
  return () => connection.disconnect(); // mirrors setup
}, [serverUrl, roomId]);
```

## 5. `useEffectEvent` (React ≥ 19.2)

- Version gate: `useEffectEvent` ships in React 19.2. Upgrade `eslint-plugin-react-hooks`
  too, otherwise the linter keeps inserting Effect Events as dependencies. Source:
  [React 19.2 blog](https://react.dev/blog/2025/10/01/react-19-2).
- Use it only for logic that is genuinely an event fired from an Effect (read the latest
  props/state without re-synchronizing). Don't use it to skip dependencies or to silence
  the linter; that hides bugs. Sources:
  [useEffectEvent](https://react.dev/reference/react/useEffectEvent),
  [React 19.2 blog](https://react.dev/blog/2025/10/01/react-19-2).
- Effect Events are not reactive and must be omitted from dependencies. Their identity is
  intentionally unstable ("do not have a stable identity"), so a wrong dependency shows
  up as a re-running Effect. Don't describe them as "stable". Sources:
  [Separating Events from Effects](https://react.dev/learn/separating-events-from-effects#declaring-an-effect-event),
  [useEffectEvent](https://react.dev/reference/react/useEffectEvent).
- Call them only from inside Effects (`useEffect`, `useLayoutEffect`, `useInsertionEffect`)
  or other Effect Events, never during rendering, and never pass them to components or
  Hooks. Declare them next to the Effect that uses them. Sources:
  [useEffectEvent](https://react.dev/reference/react/useEffectEvent),
  [Separating Events from Effects](https://react.dev/learn/separating-events-from-effects#limitations-of-effect-events).
- A latest-callback ref works on any version: update `ref.current` inside an Effect, never
  during render. From 19.2, the documented answer for logic that is an event fired from an
  Effect is `useEffectEvent`. Sources:
  [A Complete Guide to useEffect](https://overreacted.io/a-complete-guide-to-useeffect/),
  [React 19.2 blog](https://react.dev/blog/2025/10/01/react-19-2),
  [useRef](https://react.dev/reference/react/useRef).

```tsx
function Room({ roomId, theme }: { roomId: string; theme: string }) {
  const onConnected = useEffectEvent(() => showToast("Connected", theme));
  useEffect(() => {
    const c = createConnection(roomId);
    c.on("connected", onConnected);
    c.connect();
    return () => c.disconnect();
  }, [roomId]); // theme and onConnected are not dependencies
  return null;
}
```

## 6. `useLayoutEffect`, one-time init, lint rules

- Prefer `useEffect`. Use `useLayoutEffect` when a visual Effect (positioning a tooltip,
  measuring layout) flickers because the paint happens first; it doesn't run on the
  server and can hurt performance. "Runs after paint" is a tendency: an Effect caused by
  a discrete interaction (click) may run before paint. Sources:
  [useLayoutEffect](https://react.dev/reference/react/useLayoutEffect),
  [useEffect](https://react.dev/reference/react/useEffect),
  [useEffect vs useLayoutEffect (Kent C. Dodds)](https://kentcdodds.com/blog/useeffect-vs-uselayouteffect).
- `useEffect(fn, [])` is not an exact `componentDidMount`; Effects synchronize rather than
  map to lifecycle methods. Source: [A Complete Guide to useEffect](https://overreacted.io/a-complete-guide-to-useeffect/).
- Components must be resilient to remounting, including the top-level `App`. For logic that
  must run once per app load, the docs show two shapes: a module-level `didInit` flag
  checked inside an Effect, or code at module top level (guard `typeof window`). Don't
  overuse the module-level form (it runs on import); keep it in root modules or the
  entry point. Source: [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#initializing-the-application).
- `react-hooks/set-state-in-effect` flags synchronous `setState` in an Effect body. In
  plugin v7+ it is in the `recommended` preset at error severity (it was opt-in in v6).
  A `setState` driven by a ref/DOM measurement is documented as valid. Sources:
  [set-state-in-effect lint](https://react.dev/reference/eslint-plugin-react-hooks/lints/set-state-in-effect),
  [eslint-plugin-react-hooks reference](https://react.dev/reference/eslint-plugin-react-hooks),
  [plugin CHANGELOG](https://raw.githubusercontent.com/facebook/react/main/packages/eslint-plugin-react-hooks/CHANGELOG.md),
  [plugin README](https://raw.githubusercontent.com/facebook/react/main/packages/eslint-plugin-react-hooks/README.md)
  (lists `'react-hooks/set-state-in-effect': 'error'`).
- Project policy, not consensus: don't pass an `async` function directly to `useEffect`;
  declare an inner async function (the Effect callback should return nothing or a cleanup
  function). No community source in the evidence covers this line.
