# Composition and props patterns

Baseline: React 19.3 docs. Every rule carries its source; conditions come from
the source, not from this file. Anything labeled "project policy" is not
community consensus.

## Contents

- [Prop drilling, context and `children`](#prop-drilling-context-and-children)
- [Splitting components](#splitting-components)
- [Variants, booleans and discriminated props](#variants-booleans-and-discriminated-props)
- [Controlled vs uncontrolled](#controlled-vs-uncontrolled)
- [Props and state](#props-and-state)
- [Data flow](#data-flow)
- [Logic in hooks](#logic-in-hooks)
- [Exports and naming](#exports-and-naming)
- [Class components](#class-components)

## Prop drilling, context and `children`

- **Start with props.** Passing many props through many components is normal and
  keeps data use explicit. React docs: "If your components are not trivial, it's
  not unusual to pass a dozen props down through a dozen components." Source:
  <https://react.dev/learn/passing-data-deeply-with-context#before-you-use-context>
- **Depth alone is not a reason for context.** "Just because you need to pass
  some props several levels deep doesn't mean you should put that information
  into context." Same source.
- **When intermediates only forward props, extract components and pass JSX as
  `children`.** react.dev: "this often means that you forgot to extract some
  components along the way." Same source.

  ```tsx
  // Intermediate <Layout> no longer needs `posts`.
  <Layout><Posts posts={posts} /></Layout>
  ```

- `children` composition makes data flow easier to follow and reduces props
  plumbed through the tree (Abramov, "Before You memo()"). He adds that
  Server Components could later send `children` from the server. Source:
  <https://overreacted.io/before-you-memo/>
- **Context is dependency injection, not a state manager** (TkDodo; Erikson
  makes the same point: "It is a transport mechanism"). Use it for information
  needed by distant parts of the tree (react.dev); every consumer re-renders when
  the value changes (Erikson), so frequently changing state is a poor fit. State
  design is owned by `react-hooks-state`. Sources:
  <https://react.dev/learn/passing-data-deeply-with-context>,
  <https://tkdodo.eu/blog/react-query-and-react-context>,
  <https://blog.isquaredsoftware.com/2021/01/context-redux-differences/>

## Splitting components

- **Single responsibility, hedged.** react.dev: "a component should ideally only
  be concerned with one thing. If it ends up growing, it should be decomposed
  into smaller subcomponents." Source:
  <https://react.dev/learn/thinking-in-react#step-1-break-the-ui-into-a-component-hierarchy>
  Comeau agrees ("Each component should have a single responsibility"):
  <https://www.joshwcomeau.com/react/usememo-and-usecallback/>
- **Premature extraction is the opposite trap.** Makarevich: extract components
  "only when there is an actual need for it"; early extraction yields
  "over-engineered code". Source:
  <https://www.developerway.com/posts/components-composition-how-to-get-it-right>
- **Duplication before the wrong abstraction.** Dodds (AHA): "I'm fine with code
  duplication until you feel pretty confident that you know the use cases for
  that duplicate code." He says not to be dogmatic about it. Source:
  <https://kentcdodds.com/blog/aha-programming>
- **No numeric size limit.** Line-count limits ("under 200 lines") have no
  community source; use the single-responsibility guideline above.
- **Container/presentational is not a default.** Abramov's 2019 update: "I don't
  *suggest* splitting your components like this anymore. If you find it natural
  in your codebase, this pattern can be handy. But I've seen it enforced
  without any necessity and with almost dogmatic fervor far too many times."
  Hooks give the same logic separation "without an arbitrary division". Source:
  <https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0>
- **State placement.** Keep transient state (form drafts, hover) low in the tree,
  not in a global library (react.dev, useMemo DeepDive); push state down before
  lifting it (Comeau; Dodds on colocation). Sources:
  <https://react.dev/reference/react/useMemo>,
  <https://www.joshwcomeau.com/react/usememo-and-usecallback/>,
  <https://kentcdodds.com/blog/state-colocation-will-make-your-react-app-faster>
- **File layout is a team choice.** React "doesn't have opinions on how you put
  files into folders" (<https://legacy.reactjs.org/docs/faq-structure.html>).
  Light support exists for one file per reusable component (Wieruch,
  <https://www.robinwieruch.de/react-folder-structure/>) and for feature
  folders (Redux style guide, <https://redux.js.org/style-guide/>). Wieruch
  starts with one file and splits as needed, so a "monolith files prohibited"
  rule has no consensus.

## Variants, booleans and discriminated props

- **One boolean is idiomatic.** react.dev's own props example is
  `disabled: boolean` (<https://react.dev/learn/typescript>).
- **Several booleans for one concern are a smell, by one engineer's opinion.**
  Shevlin: "multiple boolean `props` or `state` in a component is probably a
  code smell"; remedy is "a single prop with an enumerated set of strings"
  (a `variant`). He labels it "just my opinion". The harm is contradictory
  combinations, not the existence of booleans; no source gives a numeric
  threshold. Not React-team guidance. Source:
  <https://kyleshevlin.com/multiple-boolean-props-are-a-code-smell/>
- **Alternatives to option-prop growth.** Composition (children/slots), or an
  overrides API for sub-element customization instead of top-level props for
  each case (Uber Base Web, "No top-level properties API overload"). Source:
  <https://www.uber.com/us/en/blog/introducing-base-web>

  ```tsx
  type ButtonProps = { variant: "primary" | "danger" | "ghost"; disabled?: boolean };
  ```

- **Mutually exclusive props: use a discriminant.** The React TypeScript
  Cheatsheet: "A better alternative might be to use a discriminant prop like
  this:" (`{ type: "foo"; foo: string } | { type: "bar"; bar: string }`). It
  applies to genuinely exclusive shapes, not every component. Source:
  <https://react-typescript-cheatsheet.netlify.app/docs/advanced/patterns_by_usecase/>
- **Render props vs `children`.** A render prop is "a function prop that a
  component uses to know what to render", and `children` itself can be the
  function. Rule of thumb (inference, not stated in these docs): use `children`
  as JSX for content; use a function prop when the
  component supplies data to the caller. These are archived pre-Hooks docs, so
  treat as pattern description, not current guidance. Sources:
  <https://legacy.reactjs.org/docs/composition-vs-inheritance.html>,
  <https://legacy.reactjs.org/docs/render-props.html>

## Controlled vs uncontrolled

- **Trade-off, not a binary.** "Uncontrolled components are easier to use within
  their parents because they require less configuration. But they're less
  flexible when you want to coordinate them together. Controlled components are
  maximally flexible, but they require the parent components to fully configure
  them with props." The docs add: "'controlled' and 'uncontrolled' aren't
  strict technical terms--each component usually has some mix of both local
  state and props." Source:
  <https://react.dev/learn/sharing-state-between-components>
- **Notifying the parent: no Effect.** Either update both components' state in
  the same event handler, or make the child fully controlled by the parent.
  react.dev: "Whenever you try to keep two different state variables
  synchronized, try lifting state up instead!" Source:
  <https://react.dev/learn/you-might-not-need-an-effect#notifying-parent-components-about-state-changes>
- You can change your mind later and refactor (same sharing-state page).

## Props and state

- **Do not mirror a prop into state.** "The state is only initialized during the
  first render," so the copy goes stale. Mirroring is fine only when you
  intentionally ignore later updates; then name the prop `initial*`/`default*`
  ("By convention, start the prop name with `initial` or `default`"). Source:
  <https://react.dev/learn/choosing-the-state-structure#avoid-redundant-state>
- Legacy React-team post: instead of mirroring, "make the component
  **controlled**". Source:
  <https://legacy.reactjs.org/blog/2018/06/07/you-probably-dont-need-derived-state.html>
- A `key` is the reset tool when you want derived draft state to restart for a
  new entity; see [identity-rendering.md](identity-rendering.md#keys-and-state-reset).
  TkDodo notes the cost: unmounting discards state and "you don't always have a
  stable key". Source: <https://tkdodo.eu/blog/putting-props-to-use-state>

## Data flow

- Data flows down. If parent and child need the same data, "let the parent
  component fetch that data, and pass it down to the child". Source:
  <https://react.dev/learn/you-might-not-need-an-effect#passing-data-to-the-parent>
  (fetching strategy itself belongs to `react-server-data`).
- Shared state goes to the "closest common parent" and is passed down via props.
  Source: <https://react.dev/learn/sharing-state-between-components>

## Logic in hooks

- Extract a custom Hook to hide external-system or browser-API details:
  "The code of your components expresses your intent, not the implementation."
  "whenever you write an Effect, consider whether it would be clearer to also
  wrap it in a custom Hook." But "Some duplication is fine." Source:
  <https://react.dev/learn/reusing-logic-with-custom-hooks>
- The scope is Effect/external-system logic and real duplication. Absolute forms
  ("move all logic into hooks", "never fetch in a component body") overreach:
  in Server Components and frameworks, awaiting data in an async component is
  the documented pattern (<https://react.dev/reference/rsc/server-components>).
- Hook naming: names must start with `use` + capital letter, and a function gets
  the `use` prefix only if it calls at least one Hook. Components start with a
  capital. Source:
  <https://react.dev/learn/reusing-logic-with-custom-hooks#hook-names-always-start-with-use>

## Exports and naming

- **Default and named exports are both first-class.** react.dev: "People often
  use default exports if the file exports only one component, and use named
  exports if it exports multiple components and values." and "some teams choose
  to only stick to one style (default or named)... Do what works best for you!"
  Source: <https://react.dev/learn/importing-and-exporting-components>
- A one-style team policy is legitimate, but it needs exceptions: "Using this
  pattern requires that the lazy component you're importing was exported as the
  `default` export" (`React.lazy`,
  <https://react.dev/reference/react/lazy>). Check your framework's docs for
  file conventions (such as route files) that may also require defaults.
- Name your component functions. "Components without names, like
  `export default () => {}`, are discouraged." Same importing/exporting page.
- With the new JSX transform you don't need `import React` for JSX
  (<https://legacy.reactjs.org/blog/2020/09/22/introducing-the-new-jsx-transform.html>); that
  is not a ban on `React.` type access: react.dev's own TypeScript guide writes
  `React.ChangeEvent` and `React.ReactNode`
  (<https://react.dev/learn/typescript>). If a team enforces named imports,
  use `import type { ReactNode } from "react"`. Project policy, not consensus.

## Class components

- "Class components are still supported by React, but we don't recommend using
  them in new code." and "We recommend defining components as functions instead
  of classes." Source: <https://react.dev/reference/react/Component>
- The legacy Hooks FAQ: "There are no plans to remove classes from React".
  Source: <https://legacy.reactjs.org/docs/hooks-faq.html>
- Exception for new code: an Error Boundary (see
  [identity-rendering.md](identity-rendering.md#error-boundaries)).
