# Identity, rendering and error boundaries

Baseline: React 19.3 docs. Each rule carries its source URL.

## Contents

- [Keys](#keys)
- [Keys and state reset](#keys-and-state-reset)
- [Component identity: never nest definitions](#component-identity-never-nest-definitions)
- [Conditional rendering](#conditional-rendering)
- [Purity](#purity)
- [Error boundaries](#error-boundaries)

## Keys

- **Dynamic or reorderable lists: stable IDs from the data.** react.dev: "Index
  as a key often leads to subtle and confusing bugs." Erikson: keys "should be
  some kind of unique IDs from your data if at all possible - only use array
  indices as keys as a last resort fallback!" Sources:
  <https://react.dev/learn/rendering-lists>,
  <https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/>
- **Static lists: index is acceptable.** react.dev: "(This is a rare case where
  index as a key is acceptable because a poem's lines will never reorder.)"
  Makarevich: "It is okay to use array's `index` as key, if the list is
  **static**, i.e. elements are not added/removed/inserted/re-ordered." Sources:
  <https://react.dev/learn/rendering-lists>,
  <https://www.developerway.com/posts/react-re-renders-guide>
  Community positions differ in tone (Erikson: last resort; Makarevich/react.dev:
  fine when static). They agree on dynamic lists.
- **Never generate keys during render.** "do not generate keys on the fly, e.g.
  with `key={Math.random()}`" and "Keys must not change or that defeats their
  purpose! Don't generate them while rendering." For locally created data,
  generate the ID once at creation (counter, `crypto.randomUUID()`, `uuid`)
  and store it. Source: <https://react.dev/learn/rendering-lists>

  ```tsx
  // BAD: new key every render, the whole list remounts
  items.map((i) => <Row key={Math.random()} item={i} />);
  // GOOD: ID created when the item is created
  items.map((i) => <Row key={i.id} item={i} />);
  ```

- **Keys are unique among siblings only.** "Keys must be unique among siblings.
  However, it's okay to use the same keys for JSX nodes in different arrays."
  Source: <https://react.dev/learn/rendering-lists>
- **Form-library field arrays have their own rule.** React Hook Form v7: "The
  `field.id` (and not `index`) must be added as the component key". v8 renames
  it: use `key={field.key}`. Source:
  <https://react-hook-form.com/docs/usefieldarray>
- **Fragments keep list/table semantics.** Use `<Fragment key={item.id}>` instead
  of wrapper `div`s inside `ol`/`ul`/`dl`/`table`: "In these cases we should
  rather use React Fragments to group together multiple elements." Source:
  <https://legacy.reactjs.org/docs/accessibility.html>

## Keys and state reset

- "You can force a subtree to reset its state by giving it a different key."
  Source: <https://react.dev/learn/preserving-and-resetting-state>
- Use a key to reset a component per entity rather than an Effect that resets
  state: "you can tell React that each user's profile is conceptually a
  _different_ profile by giving it an explicit key." Source:
  <https://react.dev/learn/you-might-not-need-an-effect>
- Cost: unmounting discards local state (including drafts) and "you don't always
  have a stable key or a clear indication when a component should be reset."
  Source: <https://tkdodo.eu/blog/putting-props-to-use-state>
- **Changing component type at the same position also resets the subtree**,
  "just like setting a different key". Discord found wrapping the chat input in
  different root components per context remounted it on every switch; merging
  the wrappers cut a lockup from 2s to 500ms (React Native context). Source:
  <https://discord.com/blog/how-discord-achieves-native-ios-performance-with-react-native>

## Component identity: never nest definitions

- react.dev: "always declare component functions at the top level, and don't
  nest their definitions." A new function per render means React renders a
  different component at the same position and "resets all state below. This
  leads to bugs and performance problems." Source:
  <https://react.dev/learn/preserving-and-resetting-state#different-components-at-the-same-position-reset-state>
- Same rule from other sources: Markbåge ("Create a new component type" is in
  his list of things not to do during render,
  <https://gist.github.com/sebmarkbage/75f0838967cd003cd7f9ab938eb1958f>),
  Erikson ("you must never create new component types while rendering!",
  <https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/>),
  Makarevich ("Never create new components inside the render function of another
  component.", <https://www.developerway.com/posts/how-to-write-performant-react-code>).
- `React.lazy` also belongs at module level, not inside a component
  (<https://react.dev/reference/react/lazy>; code splitting is owned by
  `react-performance`).

  ```tsx
  // BAD: Item is a new type each render
  function List({ rows }: { rows: Row[] }) {
    const Item = ({ r }: { r: Row }) => <li>{r.name}</li>;
    return <ul>{rows.map((r) => <Item key={r.id} r={r} />)}</ul>;
  }
  // GOOD: define Item at module scope
  ```

## Conditional rendering

- **The `&&` hazard is a numeric left side, not `&&` itself.** react.dev:
  "Don't put numbers on the left side of `&&`." Fix: "make the left side a
  boolean: `messageCount > 0 && <p>New messages</p>`." A ternary is not the
  prescribed fix. Source: <https://react.dev/learn/conditional-rendering>

  ```tsx
  {count > 0 && <Badge n={count} />}   // boolean left side: fine
  {count && <Badge n={count} />}       // renders "0" when count is 0
  ```

- Early returns are documented by react.dev ("Conditionally returning JSX") and
  are a style choice; returning `null` "isn't common". Hooks must be called
  before any early return (Rules of Hooks, owned by `react-hooks-state`).
  Sources: <https://react.dev/learn/conditional-rendering>,
  <https://react.dev/reference/rules/rules-of-hooks>

## Purity

- "React assumes that every component you write is a pure function." Source:
  <https://react.dev/learn/keeping-components-pure>
- **Local mutation is fine.** "it's completely fine to change variables and
  objects that you've *just* created while rendering." What React forbids is
  changing pre-existing variables and objects (module state, props, state,
  context). Same source.

  ```tsx
  const rows: Row[] = [];                 // created this render
  for (const x of data) rows.push(toRow(x));   // OK
  // BAD: items.sort() on a prop, or writing to a module-level variable
  ```

- Strict Mode "calls some of your functions (only the ones that should be pure)
  twice in development" to expose impurity. Source:
  <https://react.dev/reference/react/StrictMode>
- "Keep your rendering logic pure. If re-rendering a component causes a problem
  or produces some noticeable visual artifact, it's a bug in your component!
  Fix the bug instead of adding memoization." Source:
  <https://react.dev/reference/react/useMemo>
- Side effects belong in event handlers and, as a last resort, Effects (same
  keeping-components-pure page).

## Error boundaries

- **Function components cannot be boundaries.** "There is no direct equivalent
  for `componentDidCatch` in function components yet. If you'd like to avoid
  creating class components, write a single `ErrorBoundary` component like
  above and use it throughout your app." Source:
  <https://react.dev/reference/react/Component>
  Class boundaries implement `static getDerivedStateFromError` and/or
  `componentDidCatch` (same page).
- **Library option:** `react-error-boundary` provides the boundary and
  `useErrorBoundary` ("Use `useErrorBoundary` to pass caught errors to the
  nearest boundary."). Source: <https://github.com/bvaughn/react-error-boundary>
- **What boundaries do not catch:** event handlers; asynchronous code (e.g.
  `setTimeout`, `requestAnimationFrame` callbacks); server-side rendering;
  errors thrown in the boundary itself. Exception: errors thrown inside the
  function passed to the `startTransition` returned by `useTransition` are
  caught (React 19+ per react-error-boundary); the standalone `startTransition`
  import is not (<https://react.dev/reference/react/useTransition>). Source:
  <https://react.dev/reference/react/Component>
- Boundaries also cover lifecycle and constructor errors of descendants: "Error
  boundaries catch errors during rendering, in lifecycle methods, and in
  constructors of the whole tree below them." Source:
  <https://legacy.reactjs.org/docs/error-boundaries.html>
- A rejected promise passed to `use` propagates to the nearest Error Boundary
  (<https://react.dev/reference/react/use>; `use` is owned by `react-server-data`).
- **React 19 reporting:** errors caught by a boundary go to `console.error`,
  uncaught errors to `window.reportError`; pass `onCaughtError` /
  `onUncaughtError` to `createRoot` for custom reporting (React 19+). Source:
  <https://react.dev/blog/2024/04/25/react-19-upgrade-guide#errors-in-render-are-not-re-thrown>
- **Placement is not mandated.** No community source requires a boundary per
  route; react.dev frames one reusable boundary used where needed. Next.js
  `error.js` and React Router route `ErrorBoundary` are framework conventions
  ([Next.js](https://nextjs.org/docs/app/getting-started/error-handling),
  [React Router](https://reactrouter.com/how-to/error-boundary)).
  *Project policy, not consensus:* a root-level boundary plus route- or
  feature-level fallbacks is a sensible default for production apps.
- Because boundaries skip event handlers and async callbacks, handle those errors
  yourself, or forward them into a boundary with `useErrorBoundary`
  (<https://github.com/bvaughn/react-error-boundary>).
