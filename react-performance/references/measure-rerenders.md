# Measure first and re-render mechanics

Baseline: React 19.3, React Compiler 1.0, Zustand v5, TanStack Query v5. Every
rule has a source URL. Rules keep the source's conditions.

Contents: [Measure](#measure) · [Re-render mechanics](#re-render-mechanics) ·
[Fix structure before memoizing](#fix-structure-before-memoizing) ·
[Context](#context) · [Store and query subscriptions](#store-and-query-subscriptions) ·
[Refs and component identity](#refs-and-component-identity)

## Measure

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| M1 | Order for a slow interaction: (1) confirm a production build, (2) confirm state is not higher than necessary, (3) run the DevTools Profiler and wrap the most expensive subtrees with `memo()`. Dan: "Development builds are intentionally slower, in extreme cases even by an order of magnitude." | Interaction latency. For load time see M12. | <https://overreacted.io/before-you-memo/> |
| M2 | "Fix your slow renders first. Then deal with the 'unnecessary re-renders' (if you still need to)." Kent: reducing re-renders while leaving a slow render can leave you worse off. | A re-render does not imply a DOM update. | <https://kentcdodds.com/blog/fix-the-slow-render-before-you-fix-the-re-render> |
| M3 | If an interaction "still feels laggy", use the React DevTools Profiler to find which components benefit most from memoization, then add it where needed. | Default stance before the compiler is "don't memoize broadly"; see [memoization-compiler](memoization-compiler.md). | <https://react.dev/reference/react/memo> |
| M4 | Use the Profiler to see which components render in each commit, find unexpected ones and use DevTools to find out why each rendered (enable "Record why each component rendered while profiling"). | Fix options named by Erikson: `React.memo()` or the parent memoizing the props it passes. | <https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/> · <https://www.joshwcomeau.com/react/why-react-re-renders/> |
| M5 | The `<Profiler>` component "is disabled in the production build by default" because profiling adds overhead; use it "only when necessary". Compare `actualDuration` to `baseDuration` to see whether memoization works in a subtree. | `baseDuration` is an estimate of worst-case render cost, not a measured unoptimized run. Production profiling needs a profiling build. | <https://react.dev/reference/react/Profiler> |
| M6 | Memoize only after timing: wrap a suspected slow calculation in `console.time`; "say, `1ms` or more" may justify `useMemo`. | 1 ms is react.dev's illustration, not a rule. Also test with CPU throttling. "Unless you're creating or looping over thousands of objects, it's probably not expensive." | <https://react.dev/reference/react/useMemo> |
| M7 | Test on lower-end hardware: the 90th-percentile user is not on a developer machine. | Lighthouse scores do not equal real user experience (Josh). | <https://www.joshwcomeau.com/react/why-react-re-renders/> · <https://shopify.engineering/improve-ui-performance-understanding-your-user> |
| M8 | Optimizations "ALWAYS come with a cost but do NOT always come with a benefit"; most of the time do not optimize unnecessary re-renders, and measure before `React.memo`. | Kent allows that heavy charts/graphs/animations can need it. | <https://kentcdodds.com/blog/usememo-and-usecallback> |
| M9 | Reuse expensive setup objects (e.g. one `Intl.DateTimeFormat`) instead of constructing per call. | Shopify's 64.7 ms → 0.5 ms combined one reused `Intl.DateTimeFormat` with memoizing two other date-formatting utilities; self-reported, React dev mode. Do not treat as production numbers. | <https://shopify.engineering/improve-ui-performance-understanding-your-user> |
| M10 | Concurrent features used enthusiastically can cause unwanted re-renders; check their impact in the Profiler. | Sentry guidance. | <https://blog.sentry.io/react-js-performance-guide/> |
| M11 | Pin an exact React Compiler version (not a `^` range) when test coverage is weak; upgrade deliberately. | Compiler 1.0 only; see [memoization-compiler](memoization-compiler.md). | <https://react.dev/blog/2025/10/07/react-compiler-1> |
| M12 | Load-time metrics: Vercel's ordering is waterfalls first, then bundle size ("a request waterfall adds 600ms ... doesn't matter how optimized your `useMemo` calls are"). Meta: "initiating network queries earlier" was the most impactful change. | Vercel's own ranking ("usually"), not independent evidence; interaction latency follows M1/M2. Data-fetching mechanics belong to `react-server-data`. | <https://vercel.com/blog/introducing-react-best-practices> · <https://engineering.fb.com/2024/10/02/android/react-at-meta-connect-2024/> |

## Re-render mechanics

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| R1 | Default: when a parent renders, React recursively renders all children regardless of props. | Exceptions: `memo` child with stable props, reused element reference, `children` passed in from an outer component. | <https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/> |
| R2 | "Every re-render in React starts with a state change." | Erikson also lists `useSyncExternalStore` updates and root `render` calls. | <https://www.joshwcomeau.com/react/why-react-re-renders/> |
| R3 | Anything defined inside a component (object, array, function) is a new reference every render, and `Object.is({}, {})` is `false`. `memo` on a child receiving it can't skip. | Only matters for a `memo` child or a hook dependency (see R4). | <https://www.joshwcomeau.com/react/why-react-re-renders/> · <https://react.dev/reference/react/memo> |
| R4 | An inline function does not itself cause a re-render. `useCallback` is "only valuable" for a `memo` child or when the function is a dependency of another Hook. Extracting inline props to `useCallback` only to avoid child re-renders: "don't. It doesn't work." | Stabilize only for those two cases; no concern for DOM-element handlers. With the compiler on, see M11/[memoization-compiler](memoization-compiler.md). | <https://react.dev/reference/react/useCallback> · <https://www.developerway.com/posts/how-to-write-performant-react-code> |
| R5 | `memo` on host components (`<div>`, `<button>`) has no point. | Erikson. | <https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/> |
| R6 | `memo` costs a prop comparison every render; with many props and few descendants it can be slower than re-rendering. | Josh says he has no source for the claim; treat as an author claim. | <https://www.joshwcomeau.com/react/why-react-re-renders/> |
| R7 | In React 18+ with `createRoot`, updates are batched "no matter where they originate from". | `createRoot` only. | <https://github.com/reactwg/react-18/discussions/21> |

## Fix structure before memoizing

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| S1 | "Before you apply optimizations like `memo` or `useMemo`, it might make sense to look if you can split the parts that change from the parts that don't change." Move state down into the component that uses it. | Josh: "this won't always be an option" when state must live high. | <https://overreacted.io/before-you-memo/> · <https://www.joshwcomeau.com/react/usememo-and-usecallback/> |
| S2 | Colocate state: "every update to that state results in an invalidation of the entire React tree" when it lives higher than needed. | Shared state goes to the closest common parent. `memo`/`useMemo` are "less effective" than colocating. | <https://kentcdodds.com/blog/state-colocation-will-make-your-react-app-faster> |
| S3 | When a component visually wraps others, let it accept JSX as `children`; when the wrapper updates its own state React knows children needn't re-render. | A `children` value written inline by an ancestor is itself a new reference each time (Erikson). | <https://react.dev/reference/react/memo> · <https://overreacted.io/before-you-memo/> |
| S4 | Passing the same element reference skips re-rendering it; hoisting static JSX out of the component does this. | Small benefit except for big static subtrees under frequently updating parents; `children` is usually cleaner. The compiler hoists static JSX itself (Vercel's own note). | <https://kentcdodds.com/blog/optimize-react-re-renders> · <https://raw.githubusercontent.com/vercel-labs/agent-skills/main/skills/react-best-practices/rules/rendering-hoist-jsx.md> |
| S5 | Memoizing a prop alone does not stop a child re-rendering when its parent re-renders; the child must be `memo`. Only when "every single prop and the component itself are memoized" does it pay off. | One always-new prop defeats `memo` for the whole component. Nadia's "only one scenario" is stronger than react.dev, which also lists hook dependencies. | <https://www.developerway.com/posts/react-re-renders-guide> · <https://www.developerway.com/posts/how-to-use-memo-use-callback> |

## Context

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| C1 | A consumer cannot skip updates caused by a new context value, even if it reads part of it; `memo` doesn't stop fresh context values reaching it. | Erikson (2020, updated Oct 2022) says context selectors had no movement; `useContext` docs list none. Treat as still true unless docs change. | <https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/> · <https://react.dev/reference/react/useContext> |
| C2 | To re-render only when part of a context changes: read the context in an outer component, pass the needed part to a `memo` child as a prop. | react.dev. | <https://react.dev/reference/react/memo> |
| C3 | Context suits low-frequency values (locale/theme). Its re-renders "may lead to performance issues, depending on the size of the state value, how many components are subscribed ... and how often they re-render". | Not "never for frequent data": the source is conditional. Frequently changing shared state is a reason to consider an external store (state tool choice belongs to `react-hooks-state`). | <https://blog.isquaredsoftware.com/2021/01/context-redux-differences/> |
| C4 | Memoize the provider `value` when the provider isn't at the app root and can re-render because its ancestors do. | At a rarely re-rendering root it is unnecessary [converse is inference]. Memoizing doesn't prevent consumer re-renders from real value changes. | <https://www.developerway.com/posts/react-re-renders-guide> |
| C5 | Split logically separate contexts ("you can (and probably should) have multiple"). The component directly under a provider should probably use `memo` or take `children`. | Kent's reason is logical separation; the re-render rationale comes from C1. | <https://kentcdodds.com/blog/how-to-use-react-context-effectively> · <https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/> |

## Store and query subscriptions

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| Q1 | Zustand: subscribe with selectors; a selector returning a new object/array is "always considered a change". Wrap such selectors in `useShallow`. | Zustand v5: a fresh-object selector can throw "Maximum update depth exceeded", not merely re-render; the v4 `shallow` second-argument form (TkDodo's example) is gone from `create`; migrate with `useShallow` or `createWithEqualityFn` (`zustand/traditional`). | <https://zustand.docs.pmnd.rs/learn/guides/prevent-rerenders-with-use-shallow> · <https://raw.githubusercontent.com/pmndrs/zustand/main/docs/reference/migrations/migrating-to-v5.md> · <https://github.com/pmndrs/zustand/releases/tag/v5.0.0> · <https://tkdodo.eu/blog/working-with-zustand> |
| Q2 | Don't subscribe to dynamic state (e.g. `searchParams`, `localStorage`) you only read inside callbacks. | Generic rule from Vercel; `useSearchParams` is Next-specific. | <https://raw.githubusercontent.com/vercel-labs/agent-skills/main/skills/react-best-practices/rules/rerender-defer-reads.md> |
| Q3 | TanStack Query v5: leave `notifyOnChangeProps` unset (default `undefined`) and property access is tracked automatically; the component re-renders only when a field it read changes. `'all'` opts out; an array pins fields. `'tracked'` is not a v5 value. | Tracking has "a bit of an overhead" and only counts fields read during render. Object rest destructuring observes all fields. Both caveats are from TkDodo's post (last updated 2023-10-21), which documents `'tracked'` as opt-in; recheck against v5. | <https://raw.githubusercontent.com/TanStack/query/main/packages/query-core/src/types.ts> · <https://raw.githubusercontent.com/TanStack/query/main/packages/query-core/src/queryObserver.ts> · <https://tkdodo.eu/blog/react-query-render-optimizations> |
| Q4 | Keep structural sharing enabled unless a measured problem requires disabling it. | Only JSON-compatible values are shared. | <https://tanstack.com/query/latest/docs/framework/react/guides/important-defaults> |

## Refs and component identity

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| F1 | A value that doesn't affect rendering (timer id, last pointer position) belongs in a ref, not state: "If your component needs to store some value, but it doesn't impact the rendering logic, choose refs." | Anything displayed stays in state. Don't read or write `ref.current` during render. Avoid mutating React-managed DOM nodes. Airbnb used instance variables for never-rendered scroll state. | <https://react.dev/learn/referencing-values-with-refs> · <https://react.dev/reference/react/useRef> · <https://react.dev/learn/manipulating-the-dom-with-refs> |
| F2 | Never nest component definitions: a new function per render is a different component type, so React resets state below ("leads to bugs and performance problems"). Declare at top level; pass props instead of closing over parent variables. | Applies equally to `lazy()` (see [loading-bundles-lists](loading-bundles-lists.md)). Component design belongs to `react-components-typescript`. | <https://react.dev/learn/preserving-and-resetting-state> · <https://react.dev/learn/your-first-component> |
| F3 | Pass a function to `useState` for an expensive initial value: otherwise `createInitialTodos()` runs "on every render". | Not an SSR fix: the initializer also runs during server render (inference from the render model). The sourced fix is the didMount Effect pattern (`useState(false)` + `useEffect`, useEffect page) or `useSyncExternalStore` + `getServerSnapshot`; hydration needs identical initial output on client and server. Unnecessary for cheap primitives. | <https://react.dev/reference/react/useState> · <https://react.dev/reference/react/useEffect> · <https://react.dev/reference/react/useSyncExternalStore> |
