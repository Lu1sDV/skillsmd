# Code splitting, bundles and long lists

Baseline: React 19.3, Next.js 16 App Router. `<Activity>` needs React ≥ 19.2.
Every rule has a source URL.

Contents: [Code splitting](#code-splitting) · [Prefetch and third-party
scripts](#prefetch-and-third-party-scripts) · [Barrel imports](#barrel-imports) ·
[Long lists](#long-lists) · [`<Activity>`](#activity) ·
[Imperative DOM](#imperative-dom)

## Code splitting

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| L1 | Split at the route level first, then large components that render only on a user interaction (e.g. clicking a button). | Don't defer above-the-fold UI behind viewport-triggered loading or hydration; Wix says to prefetch its client bundle from the HTML so it hydrates immediately. web.dev: split "anything else that is offscreen and not critical". | <https://web.dev/articles/code-splitting-suspense> · <https://www.wix.engineering/post/40-faster-interaction-how-wix-solved-react-s-hydration-problem-with-selective-hydration-and-suspen> |
| L2 | Declare `lazy` components at module top level: "Do not declare `lazy` components *inside* other components" (state resets on re-render). | | <https://react.dev/reference/react/lazy> |
| L3 | `React.lazy` requires the imported module's `default` export; React doesn't call `load` until the component is first rendered. | For `next/dynamic`, Next's guide shows a named export loaded with `import(...).then((mod) => mod.Name)`. | <https://react.dev/reference/react/lazy> · <https://nextjs.org/docs/app/guides/lazy-loading> |
| L4 | Plain `React.lazy` needs a `<Suspense>` boundary. One boundary around several lazy components shows a single loading state instead of "staggered loading". | Suspense is not needed around every client component. Suspense-for-data belongs to `react-server-data`. | <https://web.dev/articles/code-splitting-suspense> |
| L5 | Next.js: "`next/dynamic` is a composite of `React.lazy()` and Suspense"; an extra outer `<Suspense>` is redundant for the dynamic component itself [inference]. Use its `loading` option. | Next.js 16 App Router. | <https://nextjs.org/docs/app/guides/lazy-loading> |
| L6 | Server Components are automatically code split; "Lazy loading applies to Client Components." A Server Component that dynamically imports a Client Component gets no automatic splitting ("currently"). | | <https://nextjs.org/docs/app/guides/lazy-loading> |
| L7 | `ssr: false` in `next/dynamic` "is not supported in Server Components" (error). Put it in a Client Component wrapper. | Pages Router unaffected [inference]; the guide says only that `next/dynamic` "behaves the same way in the `app` and `pages` directories". Vercel's `dynamic(..., { ssr: false })` analytics example in a `RootLayout` without `'use client'` is therefore invalid in App Router. | <https://nextjs.org/docs/app/guides/lazy-loading> · <https://raw.githubusercontent.com/vercel-labs/agent-skills/main/skills/react-best-practices/rules/bundle-defer-third-party.md> |
| L8 | web.dev's code-splitting article says React doesn't support Suspense during server rendering; Next's docs say Client Components are prerendered by default with `React.lazy()` + Suspense. | web.dev article is dated; prefer the framework docs. | <https://web.dev/articles/code-splitting-suspense> · <https://nextjs.org/docs/app/guides/lazy-loading> |
| L9 | `useSearchParams` on a prerendered route: the Client Component tree up to the closest `Suspense` is client-rendered; on a static page a production build fails without a `Suspense` boundary. | Next.js App Router. Dev mode hides the problem: the error shows at `next build`. With Cache Components, reading request data renders the boundary on the server at request time. | <https://nextjs.org/docs/app/api-reference/functions/use-search-params> |

```tsx
'use client'; // ssr:false is only allowed in a Client Component (Next.js 16)
import dynamic from 'next/dynamic';

const Chart = dynamic(() => import('./Chart'), {
  ssr: false,
  loading: () => <p>Loading…</p>, // next/dynamic already wraps lazy + Suspense
});
```

## Prefetch and third-party scripts

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| P1 | Prefetch lazy chunks (and their data) on intent such as hover: "a pretty clear hint that they will likely click". GitHub: "intent-based prefetching (like hover) to hide that latency without bloating the initial bundle". | Cost: bandwidth for users who never click. Adding `onFocus` for keyboard users is a sensible extension, not a sourced rule. | <https://shopify.engineering/improve-ui-performance-understanding-your-user> · <https://github.blog/engineering/architecture-optimization/from-latency-to-instant-modernizing-github-issues-navigation-performance/> |
| P2 | Third-party scripts: use `async` or `defer` unless needed for critical rendering; waiting until after critical content loads is recommended if performance is the main concern. In Next, `next/script` `afterInteractive` (default) suits tag managers and analytics. | Error tracking is the usual exception: Sentry's loader pattern loads a tiny script first, buffers events, and defers the full SDK. Use `async` if an analytics script must run early. | <https://web.dev/articles/optimizing-content-efficiency-loading-third-party-javascript> · <https://nextjs.org/docs/app/api-reference/components/script> · <https://docs.sentry.io/platforms/javascript/install/loader/> |
| P3 | Hydrate below-the-fold components only when they enter the viewport (Suspense + IntersectionObserver); Wix reports about 40% INP improvement. | Field data, single source; relies on a throw-a-Promise pattern the post calls "unofficial and undocumented in React"; written for React 18. The same post says the code still works in React 19 and that `use()` can be used instead of throwing ("now we can also use the use API instead of throwing the promise"). | <https://www.wix.engineering/post/40-faster-interaction-how-wix-solved-react-s-hydration-problem-with-selective-hydration-and-suspen> |

## Barrel imports

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| B1 | Big-surface barrels have a measured cost: some icon/component libraries have "up to 10,000 re-exports"; "For many popular React packages, it takes 200~800ms just to import them". | Cost is dev start, build and serverless cold start; Vercel notes tree-shaking works for bundled, side-effect-free code. Self-reported numbers on one machine. Not "the #1 bundle-size issue". | <https://vercel.com/blog/how-we-optimized-package-imports-in-next-js> |
| B2 | Next.js: add the package to `experimental.optimizePackageImports`, which "will only load the modules you are actually using"; many popular libraries (e.g. `lucide-react`, `date-fns`) are optimized by default. | Next ≥ 13.5 (Vercel's rule; the config page gives no version); the config option carries an "Experimental" badge. Prefer this to hand-written deep imports in Next. | <https://nextjs.org/docs/app/api-reference/config/next-config-js/optimizePackageImports> · <https://raw.githubusercontent.com/vercel-labs/agent-skills/main/skills/react-best-practices/rules/bundle-barrel-imports.md> |
| B3 | Outside Next (or for a library not covered), import from the source path or consider an ESLint rule that prevents barrel-file imports. | Some libraries (notably `lucide-react`) ship no `.d.ts` for deep paths. Tree-shaking is a bundler feature; an `external` library stays a black box. | <https://vercel.com/blog/how-we-optimized-package-imports-in-next-js> · <https://raw.githubusercontent.com/vercel-labs/agent-skills/main/skills/react-best-practices/rules/bundle-barrel-imports.md> |
| B4 | Counterexample: Discord (React Native) found importing whole `lodash` cheaper than submodules. | Bundler-specific (RAM bundles, Haul); not a web-bundler claim. Context-dependent: measure in your bundler. | <https://discord.com/blog/how-discord-achieves-native-ios-performance-with-react-native> |

Small app-internal barrels: no community source in the evidence. **Project policy, not consensus:** treat as taste; watch circular imports and dev-build time.

## Long lists

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| V1 | Virtualization ("windowing") renders only what is visible. TanStack Virtual is headless (no markup/styles). | web.dev's react-window article uses v1 APIs (`FixedSizeList`); current react-window documents `List` with `rowComponent`/`rowCount`/`rowHeight`. Check the installed version. | <https://web.dev/articles/virtualize-long-lists-react-window> · <https://tanstack.com/virtual/latest/docs/introduction> · <https://github.com/bvaughn/react-window> |
| V2 | It isn't free: Slack's emoji picker first mount fell from 318 ms to 48 ms, but "Search (many results)" rose from 17 ms to 44 ms. | Self-reported 2017 case against a jQuery-era baseline. No numeric row-count threshold has community support; decide by Profiler measurement on a production build with real row cost. | <https://slack.engineering/rebuilding-slacks-emoji-picker-in-react/> |
| V3 | `content-visibility: auto` lets the browser "skip an element's rendering work, including layout and painting"; add `contain-intrinsic-size` or the scrollbar shifts. Demo: 232 ms → 30 ms. | Does not stop React rendering all items, shrink the DOM or reduce memory; off-screen content stays in the DOM and accessibility tree. Baseline Newly available 2025-09-15 (Chrome 85, Firefox 125, Safari 18); DOM APIs that force layout on skipped subtrees defeat the benefit. Complements, doesn't replace, virtualization. | <https://web.dev/articles/content-visibility> |
| V4 | Use stable data IDs as keys. | Key semantics belong to `react-components-typescript`. | <https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/> |

## `<Activity>`

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| A1 | `<Activity>` (React ≥ 19.2, modes `visible`/`hidden`) preserves state and DOM for UI that toggles often ("React will 'save' its state"). | Hidden children use `display: "none"`. | <https://react.dev/reference/react/Activity> · <https://react.dev/blog/2025/10/01/react-19-2> |
| A2 | When hidden, React "will also destroy their Effects, cleaning up any active subscriptions". They re-create on show. | Do not assume effects keep running. | <https://react.dev/reference/react/Activity> |
| A3 | Hidden children "still re-render in response to new props, albeit at a lower priority". | Hiding is not free; weigh against remount cost of the subtree. | <https://react.dev/reference/react/Activity> |

## Imperative DOM

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| D1 | Avoid forced synchronous layouts and layout thrashing: batch style reads first, then writes. | Relevant to imperative code (refs, `useLayoutEffect`, third-party widgets), not ordinary rendering. `useLayoutEffect` and state updates scheduled from it block repainting. | <https://web.dev/articles/avoid-large-complex-layouts-and-layout-thrashing> · <https://react.dev/reference/react/useLayoutEffect> |
| D2 | Manual `addEventListener` for `wheel`/`touchstart`/`touchmove` that never call `preventDefault()` can pass `{ passive: true }`. | Defaults to `true` on `Window`/`Document`/`documentElement`/`body`; scroll events don't need it. JSX `onWheel`/`onTouchStart`/`onTouchMove` can't take options and React ≥ 17 keeps them passive. | <https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener> · <https://legacy.reactjs.org/blog/2020/08/10/react-v17-rc.html> |
