# react-server-data

React data and server guidance for **React 19.3**, Next.js 16 App Router, React
Router 8, TanStack Query **v5** and SWR: client fetching order, Effect races,
TanStack Query v5, Server Components and the `'use client'` boundary, Server
Functions and their security, React 19 Actions APIs, Suspense, streaming and
hydration. Self-contained: no sibling skill installation is needed.

## Install

From the skillsmd checkout (preserve local changes before replacing an existing
installation):

```sh
mkdir -p ~/.claude/skills
cp -r react-server-data ~/.claude/skills/
```

## Usage

- “This search box shows results for an old query after typing fast. Fix the race.”
- “Migrate these `useQuery(key, fn)` calls and `isLoading` checks to TanStack Query v5.”
- “Review these Server Actions for auth, authorization and validation gaps; add a Data Access Layer.”
- “My page waterfalls across three async Server Components. Parallelize it without hoisting everything.”
- “Why is `useFormStatus` never pending in my form, and should I switch to `useActionState`?”

## Reference index

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Trigger, version baseline, task routing, workflow, high-risk rules, skill myths table, handoffs |
| [Client fetching and Query](references/client-fetching-query.md) | Framework → library → Effect order, `ignore` flag, client waterfalls, TanStack Query v5 API, QueryClient lifetime, invalidation, server vs client state, SWR |
| [Server Components and Functions](references/server-components-functions.md) | `'use client'` module boundary, async components, `use` with server promises, `React.cache`, `Promise.all`/preload, Server Functions, DAL/`server-only`/DTO, React Router loader/action checks |
| [React 19 Actions and Suspense](references/react19-actions-suspense.md) | `use`, `useActionState`, `useTransition`, `useOptimistic`, `useFormStatus`, ref as prop, `<ViewTransition>`, Suspense/streaming, hydration, upgrade notes |

## Sources and decisions

**Evidence basis.** An auditor graded 55 claim clusters (V4, from about 179 claims in
about 35 AI skills) against community sources: react.dev, the React team, Next.js,
TanStack, SWR and React Router docs, TkDodo, Vercel, Meta, GitHub, Slack, Airbnb and
Wix engineering posts. An independent verifier re-fetched every SUPPORTED and
SUPPORTED-WITH-CAVEATS cluster on **2026-11-07** (all CONFIRMED or CONFIRMED-ADJUSTED,
none disputed). Only community-backed guidance is included; every rule in
`references/` has a source URL. This guidance was not run against an application;
it cites documentation and posts, not execution results.

**Correction decisions** (the verifier overrides the auditor):

- Effect races: the docs do not treat `AbortController` and `ignore` as equivalent.
  `ignore` is "the most reliable"; abort alone is not enough.
- "Effect fetching for small projects" became "allowed if neither a framework nor a
  cache fits, with cleanup"; "small project" is not a docs criterion.
- QueryClient: "once at the app root" is wrong for SSR. SPA module singleton; SSR
  creates it in state/ref (or browser singleton) and a fresh one per server request.
- Invalidation: `onSuccess` and `onSettled` are both in official guides (the
  optimistic guide uses `onSettled`); choose by whether refetch must run on failure.
  `setQueryData` from the response is an official alternative to "always invalidate".
- Query keys: arrays since v4, not only v5. Key factories are TkDodo's opinion; his
  later position combines a per-feature factory with `queryOptions`.
- `use(promise)`: "do not create the promise in render" applies to Client Components.
  A Server Component creating the promise and passing it down is the documented pattern.
- `React.cache` works only during a render and is per request; calls outside a
  component do not read or update it.
- React Router auth: a parent loader cannot protect child loaders; middleware does
  wrap action and loader `.data` requests. The "router guards do not cover mutations"
  point belongs to Next.js pages/layouts, not React Router.
- Next.js "choose one approach, avoid mixing" refers to HTTP APIs vs DAL vs
  component-level access, not RSC vs TanStack Query.
- `<ViewTransition>` is verified stable in React 19.3 (19.3 release post).
- Waterfall priority over memoization is Vercel's own ranking; the Meta item is a
  React Native case about starting queries earlier.
- Airbnb's upgrade-pacing quote is about React 16→18; React 19 removes legacy roots.
- 2026-11-07 source-support fact-check: 19 issues fixed (3 substantive overstatements/example bug, 15 citation or wording fixes, 1 count mismatch).

**Skill myths** (conflict, false, outdated or overstated skill claims) are listed
in the SKILL.md table with their sources: 15 entries.

**Excluded as UNSUPPORTED (7 clusters, no community source):** LRU cache instead of
`React.cache` (V4-12); hoisting static I/O and module-level mutable state rules
(V4-13; one line kept and labeled project policy, not consensus); cheap-condition-
before-await (V4-14); `@suspensive/react` ClientOnly/`useIsClient` (V4-15; library
specific); the blanket "always define `queryOptions` outside components" rule
(V4-16; only TkDodo's colocation advice is kept); React Router `meta`/`<Form
method="get">` prescriptions (V4-17; only the documented revalidation behavior is
kept); platform-specific Cloudflare, vinext and Cache Components procedures (V4-18).

**Evidence gaps.** Cache Components / `use cache` was not covered by any research
lane, so no rule depends on it. Shopify's "decide at page and component level"
item was not re-fetched and is not used. Browser support for
`<ViewTransition>`-related CSS is stated only for `view-transition-class`.
The "`useState(() => window.innerWidth)` is not SSR-safe" myth rests partly on the
auditor's reasoning about how server rendering calls components (labeled
`[INFERENCE]`) and partly on the `useSyncExternalStore` docs sentence that a
browser-only API "does not exist on the server". Version gates assume the baseline above;
verify an API exists in the project's installed versions before using it.

Optional handoffs (none is an installation dependency): **react-hooks-state**,
**react-performance**, **react-components-typescript**, **react-testing-a11y**,
**typescript-type-modeling**, **web-performance-optimization**, **test-engineering**,
**ui-taste**.
