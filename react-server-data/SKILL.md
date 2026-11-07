---
name: react-server-data
description: >
  Use when fetching data in React (Effect races and stale responses, waterfalls,
  TanStack Query v5 `isPending`/`gcTime`/`staleTime`/invalidation, SWR), choosing
  Server vs Client Components (`'use client'` boundary, async components,
  `use(promise)`, `React.cache`), writing Server Functions (`'use server'`, auth,
  validation, Data Access Layer, `server-only`), using React 19 Actions
  (`useActionState`, `useOptimistic`, `useFormStatus`, ref as prop), or debugging
  Suspense, streaming and hydration mismatches.
---

# React Server Data

Baseline: **React 19.3**, Next.js 16 App Router, React Router 8, TanStack Query
**v5**, SWR. Evidence: official docs, React team, library maintainers, company
engineering blogs; checked 2026-11-07. Gates are stated per rule; preserve the
project's declared React/library versions and confirm an API exists before using it.

## Route by task

| Task | Load |
|---|---|
| Effect fetching, races, TanStack Query/SWR, server vs client state, forms and drafts | [Client fetching and Query](references/client-fetching-query.md) |
| Server/Client boundary, async components, `React.cache`, waterfalls, Server Functions, DAL, secrets | [Server Components and Functions](references/server-components-functions.md) |
| `use`, `useActionState`, `useOptimistic`, `useFormStatus`, ref as prop, Suspense, streaming, hydration | [React 19 Actions and Suspense](references/react19-actions-suspense.md) |

Load only the relevant file. Detail and source URLs live there.

## Workflow

1. Read `package.json`, the framework, and existing data layer first. Match what is
   there; do not add a second fetching approach without a reason.
2. Pick the data path in this order, per React's own guidance: **framework
   mechanism** (Server Component, loader) → **client cache library** (TanStack
   Query, SWR) → **Effect with an `ignore` cleanup** when neither fits.
3. Decide where each fetch runs. Server: `await` in the component that needs the
   data. Client: library or Effect. Mutations: Server Function / route action /
   `useMutation`, never a read path.
4. Remove waterfalls before tuning anything else: independent requests start
   together (`Promise.all`, early start, `preload`), and `<Suspense>` sits near the
   data that is slow.
5. For every Server Function or action, write auth, per-resource authorization and
   input validation inside it. Then check what crosses to the client.
6. Report what was changed, version gates relied on, and anything not run.

## High-risk rules

- Server Function arguments are fully client-controlled. Validate them, check the
  user is allowed to act on that specific resource, and re-check inside each action:
  a page-level auth check does not cover actions defined in that page.
- Server Functions are for **mutations**, not data fetching (typically serial and
  uncached in frameworks); TanStack also warns against them in a `queryFn`.
- `'use client'` marks a **module-graph** boundary, not a render-tree one: its whole
  import subtree ships to the browser. Put it on leaf interactive files; pass Server
  Components in as `children`/JSX props.
- An Effect that fetches needs cleanup. The React docs call an `ignore` flag the most
  reliable fix; `AbortController` alone does not guard against chained async steps.
- `use(promise)` needs a promise that is stable across renders (from a cache, a
  Suspense-enabled framework, or a Server Component) and cannot sit in `try/catch`;
  never `use(fetch(...))`, `use(asyncFn())` or `use(cached().then(...))` in render.
- TanStack Query on a server: a **new** `QueryClient` per request, never module-level
  there. Browser: one stable instance.
- `useFormStatus` reads the **parent** `<form>`; call it from a child component.
- `React.cache` works only during a Server Component render, per request.
- Project policy, not consensus: no module-level mutable state that holds
  per-request data in server code (it can leak between concurrent requests).

## Skill myths

| Myth in circulation | What the sources say |
|---|---|
| "`use()` + Suspense replaces effect fetching; never Effect + state" | `use` needs a cached promise: ["Promises created during render are recreated on every render"](https://react.dev/reference/react/use), so the fallback repeats. A cache (a module-level `Map` is documented), a framework or a Server Component supplies it. The docs still allow [Effect fetching](https://react.dev/reference/react/useEffect) when no framework or cache fits. |
| "Hoist fetches to the highest common ancestor" | Next.js: [fetch where the data is needed](https://nextjs.org/docs/app/getting-started/fetching-data); dedupe by memoization. React: pass data down only to avoid a child [pushing it up through an Effect](https://react.dev/learn/you-might-not-need-an-effect). |
| "Never / anti-pattern: fetch in `useEffect`" | Order is framework, then cache library, then Effect with cleanup. Reasons to avoid are [no cache, no preload, waterfalls, races](https://react.dev/reference/react/useEffect), not a ban. |
| "AbortController is the preferred fix for Effect races" | Docs: abort alone [is not enough](https://react.dev/learn/synchronizing-with-effects); an `ignore` flag is "the most reliable". Abort in addition only to save network work. |
| "`useSearchParams` forces the whole page to client render" | Conditional, not old. On a prerendered route, `useSearchParams()` without `<Suspense>` [opts the *entire page* into client rendering](https://nextjs.org/docs/messages/missing-suspense-with-csr-bailout), and a production build of a static page [now fails on it](https://nextjs.org/docs/app/api-reference/functions/use-search-params). With a boundary, only the subtree up to the nearest boundary is client-rendered. A dynamically rendered route (e.g. after `connection()`) renders it on the server. |
| "`useFormStatus` is always false: a React 19 bug" | [Documented](https://react.dev/reference/react-dom/hooks/useFormStatus): it reports the parent `<form>`, not one rendered in the same component. Call it from a child. |
| "`useQuery(key, fn, opts)`" | Removed in v5: ["now we only support the object format"](https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5). |
| "`useState(() => window.innerWidth)` is SSR-safe" | The initializer also runs during server render. Use [`useSyncExternalStore` with `getServerSnapshot`](https://react.dev/reference/react/useSyncExternalStore) (docs: a browser-only API "does not exist on the server") or read after mount. [INFERENCE: that the `useState` initializer runs on the server is auditor reasoning, not a docs sentence] |
| "`use()` replaces `useContext`" | `use(Context)` can be conditional, but [`useContext` is not deprecated](https://react.dev/reference/rsc/server-components) (Client Components in a provider "can read its value with `use` or `useContext`") and reading context with [`use` is unsupported in Server Components](https://react.dev/reference/react/use). |
| "Never call `fetch` in a Client Component; always `queryFn`" | Within a Query app, reads go through `queryFn`; writes (`useMutation`, Server Function mutations) are [legitimate](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr), including [event-handler writes](https://tanstack.com/query/latest/docs/framework/react/guides/mutations). |
| "Use React Query (or SWR) for ALL data fetching" | Both are [client-side options](https://nextjs.org/docs/app/getting-started/fetching-data); Server Components fetch without them. Neither wins by rule. |
| "Create QueryClient once at the app root" | True for SPAs only. With SSR/RSC [make a new one per server request](https://tanstack.com/query/latest/docs/framework/react/guides/ssr). |
| "Optimistic updates for every mutation" | An option with a [rollback cost](https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates); with one place to show the result, `variables` needs no rollback handling. Design the failure UX first. |
| "RSCs execute sequentially within a tree" | Layouts/pages [render in parallel](https://nextjs.org/docs/app/getting-started/fetching-data); sequencing comes from stacked `await`s or [a parent that awaits before returning a child](https://nextjs.org/docs/14/app/building-your-application/data-fetching/patterns). |
| "Query DB directly in components is the Server Component way" | Next.js: [prototype tier](https://nextjs.org/docs/app/guides/data-security); prefer a Data Access Layer. |

## Handoffs (optional; none is an installation dependency)

**react-hooks-state** (Effect cleanup, derived state, Zustand), **react-performance**
(transitions, code splitting, INP), **react-components-typescript** (error
boundaries, non-Action forms, prop types), **react-testing-a11y** (MSW, form and
Suspense tests). Repo skills: **typescript-type-modeling**,
**web-performance-optimization**, **test-engineering**, **ui-taste**.

See [README](README.md#sources-and-decisions) for evidence basis and excluded claims.
