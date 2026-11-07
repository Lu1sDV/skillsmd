---
name: react-performance
description: >
  Use when a React UI is slow, janky or has poor INP; reviewing `useMemo`,
  `useCallback`, `memo` or React Compiler (`babel-plugin-react-compiler`,
  `"use no memo"`) changes; diagnosing re-renders with the Profiler; using
  `useTransition`, `useDeferredValue`, `<Activity>`, `React.lazy`,
  `next/dynamic`, `optimizePackageImports`, barrel imports, or virtualizing
  and `content-visibility` for long lists.
---

# React Performance

Baseline: **React 19.3**, **React Compiler 1.0**, eslint-plugin-react-hooks 7,
**Next.js 16** App Router. Version gates: `<Activity>` ≥ 19.2; async
transitions/Actions ≥ 19; compiler runs on React 17/18 via `target` +
`react-compiler-runtime`. Evidence: audit plus independent verification on
2026-11-07 (see [README](README.md#sources-and-decisions)). Every rule in the
references carries its source URL and conditions.

## Route by symptom

| Task | Load |
|---|---|
| Slow interaction, "why does this re-render", Profiler, state placement, context/store re-renders | [Measure and re-renders](references/measure-rerenders.md) |
| Adding or removing `memo`/`useMemo`/`useCallback`, enabling or debugging the compiler | [Memoization and compiler](references/memoization-compiler.md) |
| Bundle size, `lazy`/`next/dynamic`, barrels, long lists, `<Activity>`, third-party scripts | [Loading, bundles, lists](references/loading-bundles-lists.md) |
| Typing lag, `useTransition`/`useDeferredValue`, INP | [Transitions and INP](references/transitions-inp.md) |

Load only the relevant file.

## Workflow

1. **Measure in a production build** (dev builds can be an order of magnitude
   slower). Reproduce with CPU throttling or low-end hardware. Use the React
   DevTools Profiler; `<Profiler>` is off in production unless you use a
   profiling build.
2. **Fix a slow render before reducing re-renders.** Then check state placement:
   move state down, or pass the expensive subtree as `children`.
3. **Check the compiler.** Is it enabled for this file? If yes, don't add
   memoization by default in new code; if no, memoize only for the `useMemo` /
   `useCallback` triggers under High-risk rules.
4. **Change one thing, re-profile.** Compare before/after on the same
   interaction. Keep the change only if it measurably helps.
5. **Load-time problems** are different: waterfalls and bundle size come first
   (Vercel's ranking, not independent evidence); see the loading reference.

## High-risk rules

- `useMemo` is for: a noticeably slow calculation with rarely changing deps; a
  prop to a `memo` component; a value used as a Hook/Effect dependency; a
  Context provider `value` when the provider can re-render from ancestors
  (measure-rerenders C4). `useCallback`: a `memo` child, a Hook dependency, or
  a function inside such a context value. Nothing else.
- With the compiler on, new code relies on it; `useMemo`/`useCallback` remain an
  escape hatch (effect-dependency identity, precise control). For **existing**
  memoization: leave it, or test per component before removing.
- An incomplete manual-memo dependency array makes the compiler skip that
  component. Keep `exhaustive-deps` on.
- `<Activity>` (≥ 19.2) keeps state and DOM but **destroys Effects while
  hidden**, and hidden children still re-render at lower priority.
- `ssr: false` in `next/dynamic` is not allowed in Server Components.
  `next/dynamic` already wraps `lazy` + Suspense. Declare `lazy` at module scope.
- Transitions can't drive text inputs; updates after an `await` need another
  `startTransition`; `useDeferredValue` doesn't cancel network requests.
- Don't nest component definitions (state resets, subtree remounts).
- In Zustand v5 a selector returning a new object/array can throw "Maximum
  update depth exceeded"; use `useShallow` (or atomic selectors).
- Virtualization has no sourced row-count threshold: measure. It has a cost
  (Slack measured a regression in one scenario).
- Project policy, not consensus: failing CI on compiler lint warnings is a
  team ratchet; React's guidance is gradual adoption.

## Skill myths

| Myth (seen in other skills) | What the sources say | Link |
|---|---|---|
| "NEVER write manual `useMemo`/`useCallback`/`memo` in React 19" | The compiler is not React 19 itself; with it on, "rely on the compiler ... using `useMemo`/`useCallback` where needed to achieve precise control". Without it, manual memo is a normal tool. | [blog](https://react.dev/blog/2025/10/07/react-compiler-1) |
| "MUST NOT create functions in JSX (causes re-renders)" | You don't *have to* use `useCallback`; stabilize only for a `memo` child or hook dependency. Extracting inline props "to avoid re-renders of children components: don't. It doesn't work." | [useCallback](https://react.dev/reference/react/useCallback) · [Nadia](https://www.developerway.com/posts/how-to-write-performant-react-code) |
| "`<Activity>` keeps Effects mounted" | Hidden Activity "will also destroy their Effects". State and DOM are kept. | [Activity](https://react.dev/reference/react/Activity) |
| "React Compiler requires React 19" | "Designed to work best with React 19, but it also supports React 17 and 18" (set `target`, add `react-compiler-runtime`). | [installation](https://react.dev/learn/react-compiler/installation) |
| "Virtualize at ~50 / 1000+ rows" or "`content-visibility` instead of virtualization under 10,000 items" | No source gives a threshold. `content-visibility` skips layout/paint, but items stay in the DOM and React still renders them. Measure. | [web.dev](https://web.dev/articles/content-visibility) · [Slack](https://slack.engineering/rebuilding-slacks-emoji-picker-in-react/) |
| "After enabling the compiler, delete all manual memo" | "Either leaving existing memoization in place (removing it can change compilation output) or carefully testing before removing the memoization." | [blog](https://react.dev/blog/2025/10/07/react-compiler-1) |
| "`useState(() => window.innerWidth)` fixes SSR" | The initializer fixes only "on every render"; it still runs during server render. Use `useState(false)` + an Effect to switch to client-only output, or `useSyncExternalStore` with a `getServerSnapshot` that matches the client's first render. A bare `typeof window` guard avoids the crash but risks a hydration mismatch [inference]. | [useState](https://react.dev/reference/react/useState) · [useEffect](https://react.dev/reference/react/useEffect) |
| "Always memoize the Context value" | Memoize when the provider can re-render from ancestors; at a rarely re-rendering root, unnecessary [converse is inference]. | [Nadia](https://www.developerway.com/posts/react-re-renders-guide) |
| "Memoize every callback/object/prop" | Memoizing props alone doesn't stop a child re-rendering; the child must be `memo` and all props stable. | [Nadia](https://www.developerway.com/posts/react-re-renders-guide) |
| "`useTransition`/`useDeferredValue`, not debounce" | `useDeferredValue` "does not by itself prevent extra network requests". | [useDeferredValue](https://react.dev/reference/react/useDeferredValue) |
| "Barrels are the #1 bundle-size issue; never use them" | Vercel's measured cost is dev/build/cold start for huge-surface packages; Next ≥ 13.5 `optimizePackageImports` handles popular libraries. | [Vercel](https://vercel.com/blog/how-we-optimized-package-imports-in-next-js) |
| "`dynamic(..., { ssr: false })` in a Server Component layout defers analytics" | `ssr: false` "is not supported in Server Components"; use a Client wrapper or `next/script`. | [Next.js](https://nextjs.org/docs/app/guides/lazy-loading) · [next/script](https://nextjs.org/docs/app/api-reference/components/script) |
| "`{ passive: true }` on JSX `onWheel`/`onTouchStart`" | JSX takes no options; React ≥ 17 already keeps these passive. | [React 17](https://legacy.reactjs.org/blog/2020/08/10/react-v17-rc.html) |

## Handoffs (optional, none is an installation dependency)

**react-hooks-state** (Effects, refs, state/Context/store design, StrictMode),
**react-components-typescript** (composition, keys, component identity),
**react-server-data** (fetching, Suspense, streaming, Server Components),
**react-testing-a11y** (tests, a11y of virtualized lists).
Repo skills: **web-performance-optimization** (non-React web vitals),
**test-engineering** (strategy for compiler-upgrade regression tests),
**typescript-type-modeling**, **ui-taste**.
