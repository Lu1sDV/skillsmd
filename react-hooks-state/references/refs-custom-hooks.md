# Refs, custom hooks, Rules of Hooks

Baseline: React 19.3, `eslint-plugin-react-hooks` 7, React Compiler 1.0. Every rule ends
with its source.

## Contents

1. [Rules of Hooks and `use()`](#1-rules-of-hooks-and-use)
2. [Refs](#2-refs)
3. [Custom hooks](#3-custom-hooks)
4. [Render purity](#4-render-purity)

## 1. Rules of Hooks and `use()`

- Call Hooks only at the top level of a component or custom Hook, before any early return.
  Not inside loops, conditions, nested functions, or `try`/`catch`/`finally`; not from
  regular JavaScript functions. Enforce with `eslint-plugin-react-hooks`. Sources:
  [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks),
  [The Rules of React (Sebastian Markbåge)](https://gist.github.com/sebmarkbage/75f0838967cd003cd7f9ab938eb1958f).
- `use` is not a Hook: unlike Hooks it can be called in loops and conditionals. Limits: only
  inside a Component or Hook (not event handlers or Effects), not inside `try`/`catch`
  (use an Error Boundary), Promises passed to it must be cached rather than created during
  render, and reading context with `use` isn't supported in Server Components. React ≥ 19.
  Details of `use` with Promises: **react-server-data**. Source:
  [use](https://react.dev/reference/react/use).
- Lint plugin v7 `recommended` includes the compiler-powered rules (e.g. `refs`,
  `set-state-in-effect`). Source: [eslint-plugin-react-hooks reference](https://react.dev/reference/eslint-plugin-react-hooks).

## 2. Refs

- Use a ref for a value the component needs to remember that doesn't impact rendering
  (timeout/interval ids, DOM nodes, other objects not needed to calculate the JSX). Use
  state for anything that appears in the output. Sources:
  [Referencing Values with Refs](https://react.dev/learn/referencing-values-with-refs),
  [useRef](https://react.dev/reference/react/useRef).
- Treat refs as an escape hatch for external systems and browser APIs; if much of the
  application logic relies on refs, rethink the approach. "Never use refs" is not the
  rule either. Source: [Referencing Values with Refs](https://react.dev/learn/referencing-values-with-refs).
- Don't read or write `ref.current` during rendering. Only exception: one-time lazy
  initialization `if (!ref.current) ref.current = new Thing()`. Use state when render
  output depends on the value. Sources: [useRef](https://react.dev/reference/react/useRef),
  [Referencing Values with Refs](https://react.dev/learn/referencing-values-with-refs).
- Setting `ref.current` doesn't re-render; a mutation is visible immediately (unlike state
  snapshots). Sources: [useRef](https://react.dev/reference/react/useRef),
  [Referencing Values with Refs](https://react.dev/learn/referencing-values-with-refs).
- DOM refs: non-destructive actions such as focusing and scrolling are safe; avoid changing
  DOM nodes React manages, since manual modification can conflict with React's updates.
  Source: [Manipulating the DOM with Refs](https://react.dev/learn/manipulating-the-dom-with-refs).
- Transient or high-frequency values that don't drive UI (pointer position, scroll offset)
  may live in a ref instead of state; direct DOM mutation for them sits in escape-hatch
  territory. Sources: [Referencing Values with Refs](https://react.dev/learn/referencing-values-with-refs),
  [Zustand README: transient updates](https://raw.githubusercontent.com/pmndrs/zustand/main/README.md).
- A `useRef` guard can hide Strict Mode's development double-run of an Effect (the log
  appears once) but doesn't fix the bug (e.g. a connection is still never closed). Fix the
  cleanup; a ref guard is only defensible for a run-once Effect with nothing to undo. See
  [effects.md](effects.md#4-cleanup-and-strict-mode). Sources:
  [Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects),
  [exhaustive-deps lint](https://react.dev/reference/eslint-plugin-react-hooks/lints/exhaustive-deps),
  [Reusable State in Effects (Brian Vaughn)](https://github.com/reactwg/react-18/discussions/18).
- Ref callbacks may return a cleanup function (React ≥ 19), called on detach instead of
  calling the ref with `null`; Strict Mode re-runs ref callbacks in development. Sources:
  [React 19 blog](https://react.dev/blog/2024/12/05/react-19),
  [StrictMode](https://react.dev/reference/react/StrictMode). `ref` as a prop and
  `forwardRef`: **react-server-data** / **react-components-typescript**.
- Latest-callback ref pattern: works on any version. From React 19.2 the documented answer
  for logic that is an event fired from an Effect is `useEffectEvent` (see
  [effects.md](effects.md#5-useeffectevent-react--192)). If you write the ref pattern,
  update `ref.current` in an Effect, not during render. Sources:
  [A Complete Guide to useEffect](https://overreacted.io/a-complete-guide-to-useeffect/),
  [React 19.2 blog](https://react.dev/blog/2025/10/01/react-19-2),
  [useRef](https://react.dev/reference/react/useRef).

```tsx
// Lazy ref init is the one allowed render-time write
const clientRef = useRef<Client | null>(null);
if (clientRef.current === null) clientRef.current = new Client();

// Transient value: ref, not state
const intervalId = useRef<number | null>(null);
```

## 3. Custom hooks

- Hook names start with `use` + capital letter. Give a function the `use` prefix only if it
  calls at least one Hook; the convention isn't enforced by React (a placeholder that will
  call Hooks later may use it). Source:
  [Reusing Logic with Custom Hooks](https://react.dev/learn/reusing-logic-with-custom-hooks#hook-names-always-start-with-use).
- Custom hooks share stateful logic, not state; each call is independent. When state itself
  must be shared, lift it up and pass it down. Source:
  [Reusing Logic with Custom Hooks](https://react.dev/learn/reusing-logic-with-custom-hooks#custom-hooks-let-you-share-stateful-logic-not-state-itself).
- Extract a hook to hide external-system or browser-API details behind an intent-named
  API; "whenever you write an Effect, consider whether it would be clearer to also wrap it
  in a custom Hook". Name it for the concrete use case (`useChatRoom`, `useOnlineStatus`);
  jargon specific to the system is acceptable when you synchronize with that system. Source:
  [Reusing Logic with Custom Hooks](https://react.dev/learn/reusing-logic-with-custom-hooks#when-to-use-custom-hooks).
- No gate on reuse count or "all logic in hooks": the docs say "You don't need to extract a
  custom Hook for every little duplicated bit of code. Some duplication is fine." Extract
  for clarity or to hide external-system detail, including with a single caller. Source:
  [Reusing Logic with Custom Hooks](https://react.dev/learn/reusing-logic-with-custom-hooks#when-to-use-custom-hooks).
- Don't create generic lifecycle wrappers (`useMount`, `useEffectOnce`, `useUpdateEffect`).
  "Keep custom Hooks focused on concrete high-level use cases." The linter only checks
  direct `useEffect` calls, so a wrapper's `[]` bypasses `exhaustive-deps` unless you
  register it with `additionalEffectHooks` (plugin ≥ 6.1.1). Sources:
  [Reusing Logic with Custom Hooks (DeepDive)](https://react.dev/learn/reusing-logic-with-custom-hooks#when-to-use-custom-hooks),
  [exhaustive-deps lint](https://react.dev/reference/eslint-plugin-react-hooks/lints/exhaustive-deps).
  A team lint policy that routes all Effects through one audited file is a local
  convention (project policy, not consensus).
- Custom hooks must be pure and their bodies run on every render of the caller; treat them
  as part of the component body. Source:
  [Reusing Logic with Custom Hooks](https://react.dev/learn/reusing-logic-with-custom-hooks).
- Without a framework, extract fetching from Effects into a custom Hook with a declarative
  API (`useData`). Source: [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect).
- Library-style subscription hooks (`useOnlineStatus`) should build on
  `useSyncExternalStore`, and you typically call it from your own custom Hook rather than
  directly in components. Source: [useSyncExternalStore](https://react.dev/reference/react/useSyncExternalStore).

```tsx
function useOnlineStatus(): boolean {
  return useSyncExternalStore(
    subscribe, // defined outside the component
    () => navigator.onLine,
    () => true, // server snapshot
  );
}
```

## 4. Render purity

- Components must be pure: same input, same output. Don't call `Math.random()` or
  `Date.now()` during render, don't call `setState` during render (except the same
  component's `prev` check), don't create a new component type inside render, and issue no
  network writes or persistent I/O during render. Sources:
  [The Rules of React (Sebastian Markbåge)](https://gist.github.com/sebmarkbage/75f0838967cd003cd7f9ab938eb1958f),
  [Keeping Components Pure](https://react.dev/learn/keeping-components-pure),
  [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#adjusting-some-state-when-a-prop-changes).
- Objects and closures created during render are implicitly frozen after render
  completes; don't mutate them. Local mutation of values created in the same render is
  fine. Lazy initialization is allowed, but once initialized the value must not change.
  Sources: [The Rules of React (Sebastian Markbåge)](https://gist.github.com/sebmarkbage/75f0838967cd003cd7f9ab938eb1958f),
  [Keeping Components Pure](https://react.dev/learn/keeping-components-pure).
