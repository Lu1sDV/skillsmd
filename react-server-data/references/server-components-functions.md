# Server Components and Server Functions

Baseline: React 19.3 RSC, Next.js 16 App Router, React Router 8 framework mode.
Every rule carries its source. "Server Component by default" is a framework
convention (App Router); React itself has no Server Component directive.

## Contents

- [Boundaries and `'use client'`](#boundaries-and-use-client)
- [Fetching in Server Components](#fetching-in-server-components)
- [`React.cache`](#reactcache)
- [Waterfalls and parallelism](#waterfalls-and-parallelism)
- [Server Functions](#server-functions)
- [Security: authentication, authorization, DAL](#security-authentication-authorization-dal)
- [React Router framework mode](#react-router-framework-mode)

## Boundaries and `'use client'`

| Rule | Source |
|---|---|
| In the App Router, layouts and pages are Server Components by default. In React, "there is no directive for Server Components"; `'use server'` marks Server Functions, not components. | [Next.js: Server and Client Components](https://nextjs.org/docs/app/getting-started/server-and-client-components), [react.dev: Server Components](https://react.dev/reference/rsc/server-components) |
| Use a Client Component for state and event handlers, lifecycle Effects, browser-only APIs, custom hooks. "Server Components cannot use most Hooks"; event handlers like `onClick` "can only be defined in Client Components". Exceptions to the hook limit: `use` and `useId`. | [Next.js](https://nextjs.org/docs/app/getting-started/server-and-client-components), [react.dev: 'use client'](https://react.dev/reference/rsc/use-client) |
| Server Components keep secrets off the client: "Use API keys, tokens, and other secrets without exposing them to the client." | [Next.js](https://nextjs.org/docs/app/getting-started/server-and-client-components) |
| Put `'use client'` on leaf interactive files: "To reduce the size of your client JavaScript bundles, add `'use client'` at the top of the files that define your interactive components instead of marking large parts of your UI as Client Components." | [Next.js](https://nextjs.org/docs/app/getting-started/server-and-client-components) |
| It is a module-graph boundary: "`'use client'` defines the boundary between server and client code on the _module dependency tree_, not the render tree." All client-subtree code ships to the browser, not only components. A `'use client'` module imported from another client module has no extra effect. | [react.dev: 'use client'](https://react.dev/reference/rsc/use-client) |
| Importing a Server Component from a Client Component file turns it into client code. Compose instead: "Client Components can render Server Components because you can pass JSX as props" (`children`). | [react.dev: 'use client'](https://react.dev/reference/rsc/use-client), [Next.js: Server and client boundary](https://nextjs.org/docs/app/guides/server-and-client-boundary) |
| Values a server module takes from a `'use client'` module must be components or serializable props. Serializable props go wider than JSON (Date, Map, Set, Promises, JSX, Server Functions); plain functions and class instances do not cross. | [react.dev: 'use client'](https://react.dev/reference/rsc/use-client) |
| Server Components are not the same as SSR: Client Components "are still SSR'ed on initial load". | [Vercel: Understanding RSC](https://vercel.com/blog/understanding-react-server-components) |
| Framework/bundler authors: RSC bundler APIs "do not follow semver and may break between minors in React 19.x"; pin the React version or use Canary. Applies to framework authors, not app code. | [react.dev: Server Components](https://react.dev/reference/rsc/server-components) |

Fit for adoption is disputed: Vercel says "A healthy application utilizes both RSCs
for dynamic data fetching and Client Components for rich interactivity"; Wix says
Server Components "must be static, can't use hooks or context, which make them
difficult to integrate into a large codebase" ([Wix](https://www.wix.engineering/post/40-faster-interaction-how-wix-solved-react-s-hydration-problem-with-selective-hydration-and-suspen)).
It depends on the codebase; do not claim either as consensus.

## Fetching in Server Components

```tsx
// Server Component: no directive needed in the App Router.
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const post = await getPost(id);          // fetch / ORM / DB
  return <Post post={post} comments={<Comments postId={id} />} />;
}
```

| Rule | Source |
|---|---|
| Fetch with any async I/O (`fetch`, ORM, DB) directly in the component: "With Server Components, you can read the data and render it in the component". Fetching in the body is canonical on the server and wrong in a Client Component render. | [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data), [react.dev: Server Components](https://react.dev/reference/rsc/server-components) |
| Async components are server-only: "Since async components are not supported on the client, we await the promise with `use`." Await the critical data on the server; start low-priority work as a promise and call `use` in the Client Component. | [react.dev: Server Components](https://react.dev/reference/rsc/server-components#async-components-with-server-components) |
| Streaming data: "Data can be streamed from the server to the client by passing a Promise as a prop from a Server Component to a Client Component." Creating the promise in the Server Component render is the documented pattern (the "do not create the promise in render" rule is for Client Components). Do not `await` it there. | [react.dev: use](https://react.dev/reference/react/use), [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data) |
| Do not put a Server-Component-created promise high in a context: "Avoid setting the Promise in context high in the tree, since that would refetch large parts of the app unnecessarily." | [react.dev: use](https://react.dev/reference/react/use) |
| Fetch in the component that needs the data. Identical `fetch` requests in a render tree are memoized by default, so you need not drill props. Hoist or preload only when a parent depends on the result or to start a request early. | [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data) |
| Component-level DB queries are for "quick prototypes"; they make it "easier to accidentally expose private data to the client". Use a Data Access Layer for new projects or HTTP APIs for existing ones (see below). | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| Next.js data-security guide recommends one server-side approach (HTTP APIs, DAL, or component-level access) and not mixing them. This is about those three server approaches, not RSC vs TanStack Query. | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| Version-dependent caching: today's Next.js docs say `fetch` is not cached by default and point to `use cache`. Older RSC posts said fetched data was static by default; do not carry that forward. Cache Components / `use cache` is outside this skill's evidence. | [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data) |

## `React.cache`

```tsx
// lib/user.ts — one module exports the memoized function
import { cache } from 'react';
export const getUser = cache(async (id: string) => db.user.findUnique({ where: { id } }));
```

| Rule | Source |
|---|---|
| Server Components only: "`cache` is for use in Server Components only." React invalidates it "for each server request", so it is not a cross-request or client cache. | [react.dev: cache](https://react.dev/reference/react/cache) |
| It works only during a React render: outside a component the function "will still evaluate the function but not read or update the cache". | [react.dev: cache](https://react.dev/reference/react/cache) |
| Each call to `cache(fn)` makes a new, separate cache: create the memoized function once and export it from one module. | [react.dev: cache](https://react.dev/reference/react/cache) |
| Hits compare arguments with shallow equality / `Object.is`, so a fresh inline object argument misses. Errors are cached too. | [react.dev: cache](https://react.dev/reference/react/cache) |
| Request-scoped helpers such as `getCurrentUser` can use `cache` instead of being threaded through props. | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| Preload: call the cached function early without awaiting it, so the query runs while other work proceeds. | [react.dev: cache (Preload data)](https://react.dev/reference/react/cache) |
| For data that must survive across requests use the framework cache with tag/path revalidation, not an assumption that `React.cache` persists. A hand-rolled in-process LRU has no community endorsement either way. Cache Components / `use cache` is the Next 16 model and is outside this skill's evidence. | [react.dev: cache](https://react.dev/reference/react/cache), [Next.js: Caching (previous model, `unstable_cache`/tags)](https://nextjs.org/docs/app/guides/caching-without-cache-components) |

## Waterfalls and parallelism

| Rule | Source |
|---|---|
| "within *any* component, multiple `async`/`await` requests can still be sequential if placed after the other." Fix: "Start multiple requests by calling `fetch`, then await them with Promise.all." Requests begin when `fetch` is called. | [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data) |
| `Promise.all` is fail-fast; use `Promise.allSettled` when partial results are acceptable. | [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data) |
| "By default, layouts and pages are rendered in parallel. So each segment starts fetching data as soon as possible." Waterfalls come from stacked awaits in one component, or a parent that awaits before returning a child. | [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data), [Next.js 14 patterns](https://nextjs.org/docs/14/app/building-your-application/data-fetching/patterns) |
| Preloading starts a request earlier "so it can run in parallel with that work and avoid a request waterfall." | [Next.js: Fetching data](https://nextjs.org/docs/app/getting-started/fetching-data) |
| Splitting independent fetches into sibling async components (or sibling Suspense boundaries) is a valid fix, but the documented primary fixes are `Promise.all` and preload. "Each `<Suspense>` boundary is an independent streaming point... They don't block each other." No official sentence states siblings start concurrently; a third-party tutorial demonstrates it. | [Next.js: Streaming](https://nextjs.org/docs/app/guides/streaming), [Demystifying RSC](https://demystifying-rsc.vercel.app/server-components/async/) |
| Run independent async work concurrently. Vercel reports an API that was "waiting for one database call to finish before starting the next, even though they didn't depend on each other"; running them at the same time "cut the total wait in half" (one case). Applies to any async code, not only React. | [Vercel: React Best Practices](https://vercel.com/blog/introducing-react-best-practices) |
| Heuristic (single vendor, request-handler examples): move an `await` into the branch that needs the value. Benefit scales with how often the skipped branch runs. | [Vercel rule: async-defer-await](https://raw.githubusercontent.com/vercel-labs/agent-skills/main/skills/react-best-practices/rules/async-defer-await.md) |

## Server Functions

| Rule | Source |
|---|---|
| Mutations only: "Server Functions are designed for mutations that update server-side state; they are not recommended for data fetching." Frameworks typically run one at a time and have no way to cache the return value. | [react.dev: 'use server'](https://react.dev/reference/rsc/use-server#caveats) |
| Call them in a Transition. Functions passed to `<form action>` or `formAction` "will automatically be called in a transition." | [react.dev: 'use server'](https://react.dev/reference/rsc/use-server#caveats) |
| `'use server'` must be at the very beginning of the function or module and only on async functions. | [react.dev: 'use server'](https://react.dev/reference/rsc/use-server) |
| Arguments and returns must be serializable; not supported as arguments: React elements/JSX, functions that are not Server Functions, class instances. `useActionState` `initialState` must also be serializable when used with Server Functions. | [react.dev: 'use server'](https://react.dev/reference/rsc/use-server#serializable-parameters-and-return-values), [useActionState](https://react.dev/reference/react/useActionState#caveats) |
| Continuous updates (WebSockets, polling) need client-side fetching; Server Components cannot push. | [Vercel: Understanding RSC](https://vercel.com/blog/understanding-react-server-components) |

## Security: authentication, authorization, DAL

```ts
'use server';
export async function updatePost(postId: string, input: unknown) {
  const session = await verifySession();               // authenticate
  const data = UpdatePostSchema.parse(input);          // validate (any validator)
  const post = await getPostForUser(postId, session);  // DAL: authorizes per resource
  await db.post.update({ where: { id: post.id }, data });
}
```

| Rule | Source |
|---|---|
| "Server Functions are exposed server endpoints and can be called anywhere in client code." By default an exported Server Action is reachable "via a direct POST request, not just through your application's UI." | [react.dev: 'use server'](https://react.dev/reference/rsc/use-server), [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| "Arguments to Server Functions are fully client-controlled. For security, always treat them as untrusted input, and make sure to validate and escape arguments as appropriate." | [react.dev: 'use server'](https://react.dev/reference/rsc/use-server#security) |
| "In any Server Function, make sure to validate that the logged-in user is allowed to perform that action." | [react.dev: 'use server'](https://react.dev/reference/rsc/use-server) |
| "A page-level authentication check does not extend to the Server Actions defined within it. Always re-verify inside the action". Treat each as directly reachable and verify authentication and authorization inside each one. | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| Authentication is not enough: check "does this user have permission to act on this specific resource?" to prevent IDOR. Which validator you use (Zod or other) is a library choice. | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| Proxy/middleware checks are first-line only: "it should not be your only line of defense"; do checks "close to your data source or the component that'll be conditionally rendered". Returning `null` in a layout is UI, not protection. | [Next.js: Authentication](https://nextjs.org/docs/app/guides/authentication) |
| Data Access Layer: "keeps authentication, authorization, and database logic in a dedicated `server-only` module, while `"use server"` actions stay thin." It should "Only run on the server. Perform authorization checks. Return safe, minimal Data Transfer Objects (DTOs)." | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| Sanitize before passing to a Client Component: only fields the client needs cross the boundary. | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| `import 'server-only'` makes importing a module from client code a build error: it "stays on the server by causing a build error if the module is imported in the client environment". | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| Only the DAL should read secrets: "only the Data Access Layer should access `process.env`". | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| Tainting is an extra layer only: "you should still filter and sanitize the data in your DAL before passing it to React's render context." Taint APIs are experimental (`experimental_taintObjectReference`, `experimental_taintUniqueValue`). | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| Adopting Server Components in an existing project: "follow a Zero Trust model". | [Next.js: Data security](https://nextjs.org/docs/app/guides/data-security) |
| Project policy, not consensus: keep per-request data out of mutable module-level server state. It is consistent with TanStack's "NEVER DO THIS" for a module-level `QueryClient` on a server, but no source states the general rule. | [TanStack: SSR](https://tanstack.com/query/latest/docs/framework/react/guides/ssr) |

## React Router framework mode

| Rule | Source |
|---|---|
| Mutations go through route actions: "When the action completes, all loader data on the page is revalidated". Applies when called from `<Form>`, `useFetcher`, or `useSubmit`; revalidation can be tuned or skipped. | [React Router: Actions](https://reactrouter.com/start/framework/actions), [Route module](https://reactrouter.com/start/framework/route-module) |
| Loaders run in parallel, so "it is not possible for a parent loader to 'protect' child route loaders or actions via authentication checks." "Unless guarded by appropriate server middleware, each protected loader and action must authenticate the request and authorize access to the data or operation before proceeding." | [React Router: Data loading](https://reactrouter.com/start/framework/data-loading) |
| Middleware is "a singular place to do things like logging, authentication, and post-processing of responses". Client-side navigations run server middleware only when a `.data` request goes to the server for an action/loader. | [React Router: Route module](https://reactrouter.com/start/framework/route-module), [Middleware](https://reactrouter.com/how-to/middleware) |
| `.server` modules (suffix or `.server/` directory) fail the build "if any code in a `.server` file or `.server` directory accidentally ends up in the client module graph." Framework mode only; do not mark route modules `.server`. Server `action`/`loader` are already server-only; the risk is code reachable from `clientAction`, `clientLoader` or components. | [React Router: Server modules](https://reactrouter.com/api/framework-conventions/server-modules) |
| Client-side checks in a layout or component do not protect nested routes, loaders or actions; authenticate and authorize in each loader/action or in middleware. UI may still read the user object to render conditionally. | [Next.js: Authentication](https://nextjs.org/docs/app/guides/authentication), [React Router: Data loading](https://reactrouter.com/start/framework/data-loading) |
