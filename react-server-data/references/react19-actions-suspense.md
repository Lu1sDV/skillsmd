# React 19 Actions, `use`, Suspense and hydration

Baseline: React 19.3. Gates: `use`, Actions (async Transitions), `useActionState`,
`useOptimistic`, `useFormStatus`, ref as prop, `<Context>` as provider are **React
19+**; `<ViewTransition>` is stable from **19.3**. Every rule carries its source.

## Contents

- [`use`](#use)
- [Actions and `useActionState`](#actions-and-useactionstate)
- [`useTransition` for Actions](#usetransition-for-actions)
- [`useOptimistic`](#useoptimistic)
- [`useFormStatus`](#useformstatus)
- [Ref as prop, Context as provider](#ref-as-prop-context-as-provider)
- [`<ViewTransition>` (19.3)](#viewtransition-193)
- [Suspense and streaming](#suspense-and-streaming)
- [Hydration and browser-only values](#hydration-and-browser-only-values)
- [Upgrading to 19](#upgrading-to-19)

## `use`

```tsx
'use client';
import { use } from 'react';

type PostComment = { id: string; text: string };

export function Comments({ commentsPromise }: { commentsPromise: Promise<PostComment[]> }) {
  const comments = use(commentsPromise);   // promise created by a Server Component
  return comments.map(c => <p key={c.id}>{c.text}</p>);
}
// parent (Server Component): <Suspense fallback={<Skeleton />}><Comments commentsPromise={getComments(id)} /></Suspense>
```

| Rule | Source |
|---|---|
| "The `use` API can only be called in render, similar to hooks. Unlike hooks, `use` can be called conditionally." It must be called inside a Component or a Hook. | [React 19 post](https://react.dev/blog/2024/12/05/react-19#new-api-use), [react.dev: use](https://react.dev/reference/react/use) |
| "The component calling `use` *suspends* while the Promise is pending." Wrap it in a Suspense boundary so React can show a fallback. This is a docs recommendation; Wix states a hard "must" for promises, which is stricter than the React docs. | [react.dev: use](https://react.dev/reference/react/use), [Wix Engineering](https://www.wix.engineering/post/40-faster-interaction-how-wix-solved-react-s-hydration-problem-with-selective-hydration-and-suspen) |
| In Client Components the promise must be stable: "Promises created during render are recreated on every render, which causes React to show the Suspense fallback repeatedly and prevents content from appearing." Source it from a cache (a module-level `Map` keyed by input is documented), a Suspense-enabled framework, or a Server Component; never `use(fetch(...))`, `use(asyncFn())` or `use(cached().then(...))` in render. A Suspense-enabled library such as `useSuspenseQuery` also fits. | [react.dev: use](https://react.dev/reference/react/use), [React 19 post](https://react.dev/blog/2024/12/05/react-19#new-api-use) |
| "`use` cannot be called inside a try-catch block. Instead, wrap your component in an Error Boundary". | [react.dev: use](https://react.dev/reference/react/use#promise-caveats) |
| Do not conditionally `use(promise)` based on whether the promise is already settled. | [react.dev: use](https://react.dev/reference/react/use#conditional-use) |
| `use(Context)` can run in loops/conditions and after early returns, unlike `useContext`. It is not a replacement: `useContext` is not deprecated ("Client Components rendered inside this provider can read its value with `use` or `useContext`"), and "Reading context with `use` is not supported in Server Components." | [react.dev: Server Components](https://react.dev/reference/rsc/server-components), [react.dev: use](https://react.dev/reference/react/use) |

## Actions and `useActionState`

```tsx
'use client';
import { useActionState } from 'react';

type State = { error: string | null; title: string };

function RenameForm({ renameAction }: { renameAction: (prev: State, data: FormData) => Promise<State> }) {
  // The action returns { error, title } on failure and { error: null, title: '' } on success.
  const [state, formAction, isPending] = useActionState(renameAction, { error: null, title: '' });
  return (
    <form action={formAction}>
      <input name="title" defaultValue={state.title} disabled={isPending} />
      <button disabled={isPending}>Save</button>
      {state.error && <p role="alert">{state.error}</p>}
    </form>
  );
}
```

| Rule | Source |
|---|---|
| React 19 supports async functions in Transitions "to handle pending states, errors, forms, and optimistic updates automatically." `useActionState`, `useFormStatus`, `useOptimistic` are its building blocks. Use for new form and mutation code on React 19 only. | [React 19 post](https://react.dev/blog/2024/12/05/react-19#actions) |
| Signature: `useActionState` returns exactly three values `[state, dispatchAction, isPending]`, imported from `react`. `isPending` covers Actions dispatched by this Hook, not every loading state. | [react.dev: useActionState](https://react.dev/reference/react/useActionState) |
| Dispatch order: "React queues and executes multiple calls to `dispatchAction` sequentially. Each call to `reducerAction` receives the result of the previous call." | [react.dev: useActionState](https://react.dev/reference/react/useActionState#caveats) |
| "`dispatchAction` must be called from an Action." Calls outside that scope are not treated as part of the Transition and log an error in development. | [react.dev: useActionState](https://react.dev/reference/react/useActionState#caveats) |
| "If `dispatchAction` throws an error, React cancels all queued actions and shows the nearest Error Boundary." Return expected validation errors as state instead of throwing. | [react.dev: useActionState](https://react.dev/reference/react/useActionState#caveats) |
| Unlike `useReducer` reducers, `reducerAction` can be async and perform side effects. With Server Functions, `initialState` must be serializable. | [react.dev: useActionState](https://react.dev/reference/react/useActionState#caveats) |
| "When a `<form>` Action succeeds, React will automatically reset the form for uncontrolled components." For a manual reset call `requestFormReset`. The reset happens whenever the Action completes, including when it returns an error state, so return the submitted values and use `defaultValue`: "Return validation errors and submitted values from the Action to display an error without clearing the affected fields." | [React 19 post](https://react.dev/blog/2024/12/05/react-19#react-dom-form-actions), [react.dev: useActionState](https://react.dev/reference/react/useActionState) |
| `useFormState` is the old Canary name: React "renamed it and deprecated `useFormState`." It was still exported from `react-dom@19.3.1` as a deprecated alias (not removed); the upgrade guide lists a `replace-use-form-state` codemod. | [React 19 post](https://react.dev/blog/2024/12/05/react-19), [Upgrade guide](https://react.dev/blog/2024/04/25/react-19-upgrade-guide) |

## `useTransition` for Actions

| Rule | Source |
|---|---|
| By convention a callback passed to `startTransition` is named `action` or carries an "Action" suffix. | [react.dev: useTransition](https://react.dev/reference/react/useTransition#functions-called-in-starttransition-are-called-actions) |
| Fits mutations and navigations run as Actions. It does not replace a query library's status for a data fetch. | [react.dev: useTransition](https://react.dev/reference/react/useTransition) |
| "You must wrap any state updates after any async requests in another `startTransition` to mark them as Transitions." The docs call this a known limitation. | [react.dev: useTransition](https://react.dev/reference/react/useTransition) |
| Concurrent Actions in plain `useTransition` do not guarantee order: use `useActionState` or `<form action>` "that handle ordering for you" when order matters. | [react.dev: useTransition](https://react.dev/reference/react/useTransition) |
| "You can wrap an update into a Transition only if you have access to the `set` function of that state." For a prop or custom-Hook value use `useDeferredValue`. Transitions cannot control text inputs. | [react.dev: useTransition](https://react.dev/reference/react/useTransition#starttransition-caveats) |
| Call a Server Function in a Transition; a form `action` does this automatically. | [react.dev: 'use server'](https://react.dev/reference/rsc/use-server#caveats) |

## `useOptimistic`

| Rule | Source |
|---|---|
| The setter must run inside an Action: "If you call the setter outside an Action, React will show a warning and the optimistic state will briefly render." | [react.dev: useOptimistic](https://react.dev/reference/react/useOptimistic#setoptimistic-caveats) |
| "Optimistic state only renders while an Action is in progress, otherwise `value` is rendered." When the update finishes or errors, React switches back to the real value (rollback is automatic). | [react.dev: useOptimistic](https://react.dev/reference/react/useOptimistic#optimistic-state-is-temporary), [React 19 post](https://react.dev/blog/2024/12/05/react-19#new-hook-optimistic-updates) |
| Reducers and updater functions passed to it must be pure. | [react.dev: useOptimistic](https://react.dev/reference/react/useOptimistic#parameters) |

## `useFormStatus`

```tsx
import { useFormStatus } from 'react-dom';

function SubmitButton() {              // must be rendered INSIDE the <form>
  const { pending } = useFormStatus();
  return <button disabled={pending}>Save</button>;
}
```

| Rule | Source |
|---|---|
| "`useFormStatus` will only return status information for a parent `<form>`. It will not return status information for any `<form>` rendered in that same component or children components." | [react.dev: useFormStatus](https://react.dev/reference/react-dom/hooks/useFormStatus) |
| The pitfall comment reads "`pending` will never be true" for the same-component case; the fix is to call it from a component located inside the form. It is documented behavior, not a React 19 bug. | [react.dev: useFormStatus](https://react.dev/reference/react-dom/hooks/useFormStatus) |

## Ref as prop, Context as provider

| Rule | Source |
|---|---|
| React 19: "you can now access `ref` as a prop for function components"; "New function components will no longer need `forwardRef`". Existing `forwardRef` still works; React plans deprecation, and the docs still say it "will be deprecated in a future release". | [React 19 post](https://react.dev/blog/2024/12/05/react-19#ref-as-a-prop), [react.dev: forwardRef](https://react.dev/reference/react/forwardRef) |
| Gates: React 18 apps and libraries targeting both versions still need `forwardRef`. "`ref`s passed to classes are not passed as props since they reference the component instance." | [React 19 post](https://react.dev/blog/2024/12/05/react-19#ref-as-a-prop) |
| "In React 19, you can render `<Context>` as a provider instead of `<Context.Provider>`." The docs now call `.Provider` "legacy"; it still works and is required on React 18. | [React 19 post](https://react.dev/blog/2024/12/05/react-19#context-as-a-provider), [react.dev: createContext](https://react.dev/reference/react/createContext) |

## `<ViewTransition>` (19.3)

| Rule | Source |
|---|---|
| Stable from React 19.3 (released 2026-09-09). Before that it was experimental/canary. | [React 19.3 post](https://react.dev/blog/2026/09/09/react-19-3) |
| Only updates wrapped in a Transition, `<Suspense>` or `useDeferredValue` activate it; a plain `setState` does not. "React automatically calls `startViewTransition` itself behind the scenes so you should never do that yourself." | [react.dev: ViewTransition](https://react.dev/reference/react/ViewTransition) |
| Honor `@media (prefers-reduced-motion)`: the docs recommend disabling or toning down animations. | [react.dev: ViewTransition](https://react.dev/reference/react/ViewTransition) |
| `view-transition-class` is Chrome 125+, Firefox 144+, Safari 18.2+ in browser-compat data; check the browser floor of your own project. | [MDN browser-compat-data](https://raw.githubusercontent.com/mdn/browser-compat-data/main/css/properties/view-transition-class.json) |

## Suspense and streaming

| Rule | Source |
|---|---|
| Wrap slow components in `<Suspense>` so the rest streams: "you can tell the server to deprioritize that component's rendering and hydration, letting other components load in without getting blocked by the heavier ones." | [Vercel: Understanding RSC](https://vercel.com/blog/understanding-react-server-components) |
| Place the boundary near the uncached/runtime data access: Next.js recommends `<Suspense>` "closer to the runtime or uncached data access" over route-level `loading.js`. "The key to maximizing what streams instantly is to defer dynamic data access to the component that actually needs it." | [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data), [Next.js: Streaming](https://nextjs.org/docs/app/guides/streaming) |
| Each boundary is an independent streaming point; boundaries do not block each other. | [Next.js: Streaming](https://nextjs.org/docs/app/guides/streaming) |
| Layout shift: "If the fallback and the resolved content are different sizes, the surrounding layout shifts." Size skeletons to match. | [Next.js: Streaming](https://nextjs.org/docs/app/guides/streaming) |
| Bots and crawlers: Next.js "waits for data fetching to finish and sends the fully rendered page instead of streaming it progressively". SEO-critical content is a framework-dependent concern, not an automatic reason to skip Suspense. | [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data) |
| `useSearchParams` in a static route: "During production builds, a static page that calls `useSearchParams` from a Client Component must be wrapped in a `Suspense` boundary, otherwise the build fails", and "the Client Component tree up to the closest `Suspense` boundary" is client-side rendered. Without a boundary on a prerendered route the whole page is opted into client rendering (the cause of the build error); with one, only the subtree is. A dynamically rendered route reads it on the server during the initial render. | [Next.js: useSearchParams](https://nextjs.org/docs/app/api-reference/functions/use-search-params), [Next.js: missing Suspense with CSR bailout](https://nextjs.org/docs/messages/missing-suspense-with-csr-bailout) |
| With Suspense mode in a query library, loading and error states live in `<Suspense>` fallbacks and error boundaries. | [TanStack: Suspense](https://tanstack.com/query/latest/docs/framework/react/guides/suspense) |

## Hydration and browser-only values

| Rule | Source |
|---|---|
| "`hydrateRoot()` expects the rendered content to be identical with the server-rendered content. You should treat mismatches as bugs and fix them." | [react.dev: hydrateRoot](https://react.dev/reference/react-dom/client/hydrateRoot) |
| `suppressHydrationWarning` is for an unavoidable single-element difference such as a timestamp: "It only works one level deep, and is intended to be used as an escape hatch. Don't overuse it." React will not patch mismatched text content, so it silences the warning only. | [react.dev: Common components](https://react.dev/reference/react-dom/components/common#common-props), [hydrateRoot](https://react.dev/reference/react-dom/client/hydrateRoot) |
| Effects do not run on the server. Browser values (`window`, storage) belong in an Effect, after mount, or in an external store; `useSyncExternalStore` docs: "If you're connecting to a browser-only API, it won't work because it does not exist on the server". `useState(() => window.innerWidth)` still runs the initializer on the server [INFERENCE: auditor reasoning from how server rendering invokes components; the docs sentence above supports the browser-only half], so it neither avoids the error nor, if guarded, a mismatch. React ≥ 19.3's `use(browser())` is another documented option for browser-only components. It opts the component out of server HTML (the nearest `<Suspense>` fallback is rendered instead), must sit inside a `<Suspense>` boundary during server rendering ("Without one, server rendering fails"), and in a Server Components app must be called from a Client Component. | [react.dev: useEffect](https://react.dev/reference/react/useEffect#caveats), [useSyncExternalStore](https://react.dev/reference/react/useSyncExternalStore), [use](https://react.dev/reference/react/use), [React 19.3 post](https://react.dev/blog/2026/09/09/react-19-3) |
| `useSyncExternalStore` for hydration-safe external reads: omitting `getServerSnapshot` throws on the server, and the server snapshot "must be the same between the client and the server". | [react.dev: useSyncExternalStore](https://react.dev/reference/react/useSyncExternalStore#parameters) |
| Content that differs between server and client can render after mount from state. Airbnb moved such content to a mount-time state update to fix a hydration checksum warning (2017, class `componentDidMount`; the same idea applies with an Effect). | [Airbnb Engineering](https://medium.com/airbnb-engineering/recent-web-performance-fixes-on-airbnb-listing-pages-6cd8d93df6f4) |
| Selective hydration: Wix hydrates below-the-fold parts only when they enter the viewport, using Suspense and IntersectionObserver (reported about 20% less JS and about 40% better INP on their sites; field data, React 18, relied on an unofficial throw-a-promise pattern; Wix says part of the INP gain came from separate main-thread optimizations). "Ensure that the same Suspense boundaries are rendered in both environments - even if the client defers their resolution." | [Wix Engineering](https://www.wix.engineering/post/40-faster-interaction-how-wix-solved-react-s-hydration-problem-with-selective-hydration-and-suspen) |

## Upgrading to 19

| Rule | Source |
|---|---|
| "We recommend upgrading to React 18.3 first to help identify any issues before upgrading to React 19." | [Upgrade guide](https://react.dev/blog/2024/04/25/react-19-upgrade-guide) |
| React 19 removes `ReactDOM.render` and `ReactDOM.hydrate`; apps still on legacy roots must move to `createRoot`/`hydrateRoot`. Render errors are no longer re-thrown; `createRoot`/`hydrateRoot` gain `onCaughtError`/`onUncaughtError`. "Only change the API surface" omits these behavior changes. | [Upgrade guide](https://react.dev/blog/2024/04/25/react-19-upgrade-guide) |
| Adopt new APIs after the upgrade settles is team practice, not a docs rule: Airbnb "intentionally held off for a few weeks on adopting these features until the upgrade had settled" (their React 16→18 upgrade, an analogy). | [Airbnb Engineering](https://medium.com/airbnb-engineering/how-airbnb-smoothly-upgrades-react-b1d772a565fd) |
