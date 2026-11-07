# Client fetching and TanStack Query

Baseline: React 19.3, TanStack Query **v5**, SWR. Every rule carries its source;
quotes are verbatim from pages fetched or recorded in the evidence files.

## Contents

- [Choosing the data path](#choosing-the-data-path)
- [Effect fetching](#effect-fetching)
- [Waterfalls on the client](#waterfalls-on-the-client)
- [TanStack Query v5](#tanstack-query-v5)
- [Server state vs client state](#server-state-vs-client-state)
- [Loading, empty and error states](#loading-empty-and-error-states)
- [SWR](#swr)

## Choosing the data path

| Rule | Source |
|---|---|
| Use the framework's data fetching first: "If you use a framework, use its built-in data fetching mechanism." | [react.dev: Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects) |
| Otherwise use or build a client-side cache. Next.js lists exactly two client options: React's `use` API and a community library such as SWR or React Query. | [react.dev: useEffect](https://react.dev/reference/react/useEffect), [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data) |
| An Effect is the fallback: "You can continue fetching data directly in Effects if neither of these approaches suit you." The docs list the downsides (no SSR, waterfalls, no preload/cache, boilerplate and races). "Small project" is not a docs criterion. | [react.dev: Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects), [useEffect](https://react.dev/reference/react/useEffect) |
| In a new Server Components app, start with the framework's data tools and "avoid bringing in React Query until you actually need it." | [TanStack: Advanced SSR](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr) |
| Query/SWR cannot receive continuous server pushes from Server Components: "RSCs do not support continuous updates, such as through WebSockets. In these cases, a client-side fetching or polling approach would be necessary." | [Vercel: Understanding RSC](https://vercel.com/blog/understanding-react-server-components) |

Disagreement, stated as sources have it: React docs call Effect fetching legitimate
but second-best; TkDodo calls both fetch-once and refetch-on-mount Effect patterns
"sub-optimal" ([TkDodo](https://tkdodo.eu/blog/react-query-as-a-state-manager));
framework docs recommend loaders or Server Components. All three agree on the order
framework → library → Effect; only the wording ("anti-pattern" vs "acceptable") differs.

## Effect fetching

```tsx
useEffect(() => {
  let ignore = false;
  setResults(null);
  fetchResults(query).then(json => {
    if (!ignore) setResults(json);
  });
  return () => { ignore = true; };
}, [query]);
```

| Rule | Source |
|---|---|
| An Effect that fetches needs cleanup: "fetch" needs either "cancel" or "ignore". | [react.dev: Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects) |
| Fix the race with an `ignore` flag in cleanup: "add a cleanup function to ignore stale responses". Only the last requested response is applied. | [react.dev: You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#fetching-data) |
| `AbortController` alone is not enough: "by itself this is not enough to protect against race conditions. More asynchronous steps could be chained after the fetch, so using an explicit flag like `ignore` is the most reliable way to fix this type of problem." Adding abort on top is fine to save network work. | [react.dev: Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects) |
| Without a framework, extract the Effect into a custom Hook; this "won't be as efficient as using a framework's built-in data fetching mechanism" but eases a later move. | [react.dev: You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect#fetching-data) |
| A child must not fetch and push data to its parent from an Effect: "let the parent component fetch that data, and *pass it down* to the child instead". This is about data flow direction, not "hoist every fetch". | [react.dev: You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect) |
| `use(promise)` is not an Effect replacement in Client Components: "Promises created during render are recreated on every render, which causes React to show the Suspense fallback repeatedly and prevents content from appearing." Pass a promise from a cache, a Suspense-enabled framework, or a Server Component; a module-level cache is documented for apps without a framework. | [react.dev: use](https://react.dev/reference/react/use) |

## Waterfalls on the client

| Rule | Source |
|---|---|
| Effects fetching in nested components create "network waterfalls"; the React docs call a child that loads only after its parent renders "an expensive client-server waterfall". | [react.dev: Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects), [Server Components](https://react.dev/reference/rsc/server-components) |
| Start fetches on navigation intent, not when the target renders. Meta: "The most impactful improvement that our teams made was initiating network queries earlier." (Meta Horizon mobile app, React Native, Relay; related but not a web-React benchmark.) | [Meta Engineering](https://engineering.fb.com/2024/10/02/android/react-at-meta-connect-2024/) |
| Waterfalls first: Vercel's own ranking puts "Eliminate waterfalls" and bundle size before other React tuning. One vendor's ordering ("usually"), not independently measured. | [Vercel: React Best Practices](https://vercel.com/blog/introducing-react-best-practices) |
| Stale-while-revalidate: "render instantly from locally available data, then revalidate in the background." GitHub notes this is not free; stop background prefetch at a bound on very large data sets (Slack). | [GitHub Engineering](https://github.blog/engineering/architecture-optimization/from-latency-to-instant-modernizing-github-issues-navigation-performance/), [Slack Engineering](https://slack.engineering/making-slack-faster-by-being-lazy/) |

## TanStack Query v5

```tsx
const { data, isPending, isError } = useQuery({
  queryKey: ['todos', filter],
  queryFn: () => fetchTodos(filter),
  staleTime: 60_000,
});
```

| Rule (v5 gate) | Source |
|---|---|
| Object signature only: "now we only support the object format." Positional `useQuery(key, fn)` is a v4 form and fails on v5. | [Migrating to v5](https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5) |
| Query status `loading` → `pending`; derived `isLoading` → `isPending`. Mutations too. v5 adds a new derived `isLoading` meaning `isPending && isFetching`, so `isLoading` still exists with new semantics. | [Migrating to v5](https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5) |
| `cacheTime` → `gcTime`; `keepPreviousData: true` → `placeholderData: keepPreviousData`. | [Migrating to v5](https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5) |
| `gcTime` controls when inactive queries leave the cache (default 5 minutes). It is not `staleTime`. | [Important defaults](https://tanstack.com/query/latest/docs/framework/react/guides/important-defaults), [TkDodo: Practical React Query](https://tkdodo.eu/blog/practical-react-query) |
| Cached data is stale by default. To reduce refetching: "Setting `staleTime` is the recommended way to avoid excessive refetches". Tune `refetchOnMount` / `refetchOnWindowFocus` / `refetchOnReconnect` only for specific points. | [Important defaults](https://tanstack.com/query/latest/docs/framework/react/guides/important-defaults) |
| Query keys are arrays: "Query keys have to be an Array at the top level"; keys must be JSON-serializable and unique to the data. (Arrays have been required since v4.) | [Query keys](https://tanstack.com/query/latest/docs/framework/react/guides/query-keys), [TkDodo](https://tkdodo.eu/blog/effective-react-query-keys) |
| Key organization is style, not a rule. TkDodo: generic → specific, "these points reflect my personal opinion"; colocate keys with their queries in a feature directory, one factory per feature. His later position: separating the key from the query function "was a mistake"; combine a per-feature factory with `queryOptions` so key and `queryFn` stay together. | [TkDodo: Effective keys](https://tkdodo.eu/blog/effective-react-query-keys), [TkDodo: The queryOptions API](https://tkdodo.eu/blog/the-query-options-api) |
| After a mutation, targeted invalidation is the documented default: Query "prescribes targeted invalidation, background-refetching and ultimately atomic updates". The invalidation guide and Quick Start use `onSuccess`; the optimistic-updates guide uses `onSettled` ("Always refetch after error or success") because refetch must also run on failure. Pick by that criterion. | [Invalidation from mutations](https://tanstack.com/query/latest/docs/framework/react/guides/invalidations-from-mutations), [Query invalidation](https://tanstack.com/query/latest/docs/framework/react/guides/query-invalidation), [Optimistic updates](https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates) |
| "Always invalidate" is too strong: when the mutation response already carries the new data, `setQueryData` is an official alternative that avoids a wasted request. | [Updates from mutation responses](https://tanstack.com/query/latest/docs/framework/react/guides/updates-from-mutation-responses) |
| `invalidateQueries({ queryKey: ['todos'] })` matches every key starting with `todos`; pass `exact: true` to invalidate only that key. | [Query invalidation](https://tanstack.com/query/latest/docs/framework/react/guides/query-invalidation) |
| Optimistic updates are optional. The migration guide's simplified approach "works best if we only have one place where we need to show the optimistic update." Design the rollback UX first. | [Migrating to v5](https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5) |

### QueryClient lifetime

```tsx
'use client';
export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () => new QueryClient({ defaultOptions: { queries: { staleTime: 60 * 1000 } } }),
  );
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}
```

| Rule | Source |
|---|---|
| Server rendering: create the client in React state or a ref so data is not shared between users and requests. A module-level `new QueryClient()` on a server is marked "NEVER DO THIS": the cache is shared and "_all_ data gets passed to _all_ users." | [TanStack: SSR](https://tanstack.com/query/latest/docs/framework/react/guides/ssr) |
| Advanced SSR pattern: "Server: always make a new query client"; "Browser: make a new query client if we don't already have one". | [TanStack: Advanced SSR](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr) |
| Use the browser-singleton variant (not `useState`) when no `<Suspense>` boundary sits between the client creation and code that may suspend: "React will throw away the client on the initial render if it suspends and there is no boundary". | [TanStack: Advanced SSR](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr) |
| SPA only: a module-level `const queryClient = new QueryClient()` is the documented Quick Start. | [TanStack: Quick Start](https://tanstack.com/query/latest/docs/framework/react/quick-start) |
| With SSR, set a default `staleTime` above 0: "With SSR, we usually want to set some default staleTime above 0 to avoid refetching immediately on the client". | [TanStack: SSR](https://tanstack.com/query/latest/docs/framework/react/guides/ssr), [TanStack: Advanced SSR](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr) |

### With Server Components

| Rule | Source |
|---|---|
| Documented App Router pattern: prefetch on the server, `dehydrate`, wrap in `<HydrationBoundary>`; the `initialData` approach from the SSR guide also works with Server Components. | [TanStack: Advanced SSR](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr) |
| Components using Query hooks need `'use client'`: Server Components cannot use most Hooks, and the Provider file needs it too ("QueryClientProvider relies on useContext under the hood"). | [react.dev: 'use client'](https://react.dev/reference/rsc/use-client), [TanStack: Advanced SSR](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr) |
| From Query v5.40.0, prefetches need not be awaited: pending queries can be dehydrated and streamed, so a slow prefetch does not block the Suspense boundary. | [TanStack: Advanced SSR](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr) |
| Treat Server Components as a place to prefetch, not to render Query results: "avoid rendering the result of `queryClient.query` on the server or passing it to another component". Server and client may each own some data; keep them from drifting out of sync. | [TanStack: Advanced SSR](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr) |
| Do not use Server Actions in a `queryFn`: client-invoked Server Actions run serially, which conflicts with how Query fetches; they "remain a good fit for **mutations** (`useMutation`)". | [TanStack: Advanced SSR](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr) |

## Server state vs client state

| Rule | Source |
|---|---|
| "TanStack Query is a server-state library"; it "is not a replacement for local/client state management". After moving async data to it, remaining global client state is "usually very tiny". | [TanStack: Does this replace client state?](https://tanstack.com/query/latest/docs/framework/react/guides/does-this-replace-client-state) |
| The app does not own server data: it displays a snapshot and revalidates. Copying it elsewhere stops Query doing its job. | [TkDodo: Query as a state manager](https://tkdodo.eu/blog/react-query-as-a-state-manager) |
| Do not copy query data into state with an Effect to set a default selection: "This effect is not only verbose, it also has a bug" where it overwrites the current selection when new data arrives. Derive it at read time (`selection ?? users?.[0]`). | [TkDodo: Deriving client state](https://tkdodo.eu/blog/deriving-client-state-from-server-state) |
| Exception: a form draft initialized from server data is a legitimate copy "if you are doing it deliberately and know about the tradeoffs". Keep the draft small and re-mount with `key` when the source changes. The copy stops receiving background refetches unless you raise `staleTime` or derive per field. | [TkDodo: Query and forms](https://tkdodo.eu/blog/react-query-and-forms), [TkDodo: Putting props to useState](https://tkdodo.eu/blog/putting-props-to-use-state) |

## Loading, empty and error states

| Rule | Source |
|---|---|
| Without Suspense: check `isPending`, then `isError`, then render success. `status` and `fetchStatus` can combine freely because of background refetches. | [TanStack: Queries](https://tanstack.com/query/latest/docs/framework/react/guides/queries) |
| With Suspense mode, `status`/`error` handling moves to `<Suspense>` fallbacks and error boundaries. | [TanStack: Suspense](https://tanstack.com/query/latest/docs/framework/react/guides/suspense) |
| Model one `status`, not several `isLoading` booleans. | [Kent C. Dodds](https://kentcdodds.com/blog/stop-using-isloading-booleans) |
| Do not leave an empty area when nothing loaded: say it is loading, errored, or has no content. This is a UX guideline, not a React API requirement. | [NN/g: Empty states](https://www.nngroup.com/articles/empty-state-interface-design/) |

## SWR

| Rule | Source |
|---|---|
| `null` (or a function returning a falsy value) as the key skips the request: "Use `null` or pass a function as `key` to conditionally fetch data." | [SWR: Conditional fetching](https://swr.vercel.app/docs/conditional-fetching) |
| Same key requested by several components in one render: "only 1 network request will be made" (built-in dedup and cache). TanStack Query also lists dedup among what it solves. | [SWR: Performance](https://swr.vercel.app/docs/advanced/performance), [TanStack: Overview](https://tanstack.com/query/latest/docs/framework/react/overview) |
| SWR vs Query is a preference: Next.js presents both as equal client options. | [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data) |
