# TypeScript with React

Baseline: React 19.3 with `@types/react` 19, TypeScript 5.x. Version gates are
stated per rule. Every rule carries its source URL. General type modeling
belongs to the optional `typescript-type-modeling` skill.

## Contents

- [Setup](#setup)
- [Typing props](#typing-props)
- [`interface` vs `type`](#interface-vs-type)
- [Children](#children)
- [`React.FC`](#reactfc)
- [Events, state, reducers, context, styles](#events-state-reducers-context-styles)
- [React 19 type and API changes](#react-19-type-and-api-changes)
- [`any`](#any)

## Setup

- Every file containing JSX must use `.tsx`. Install `@types/react` and
  `@types/react-dom`; `tsconfig` needs the `dom` lib and a valid `jsx` option
  (`preserve` suffices for most applications). Source:
  <https://react.dev/learn/typescript>
- `strict: true` and a `tsc --noEmit` gate are not stated by the React docs
  (the page lists only `dom` and `jsx` as required). *Project policy, not
  consensus:* near-universal practice in TypeScript projects.

## Typing props

- **Inline is fine for tiny components; extract as fields grow.** react.dev:
  "This inline syntax is the simplest way to provide types for a component,
  though once you start to have a few fields to describe it can become
  unwieldy. Instead, you can use an `interface` or `type` to describe the
  component's props." Source: <https://react.dev/learn/typescript>

  ```tsx
  interface MyButtonProps {
    /** The text to display inside the button */
    title: string;
    /** Whether the button can be interacted with */
    disabled: boolean;
  }
  ```

  (This is react.dev's own example shape; doc comments are per prop.)
- **Export the props type with the component.** Pocock: "Type aliases should
  always be exported along with the component - that way you can use them in
  other files if needed." An anonymous inline type cannot be exported. Source:
  <https://www.totaltypescript.com/react-props-typescript>
- `Readonly<Props>` wrapping and mandatory JSDoc on every component have no
  community source; props are already immutable ("props are immutable", react.dev:
  <https://react.dev/learn/passing-props-to-a-component>).
- **Mutually exclusive props:** model with a discriminant prop (cheatsheet:
  "A better alternative might be to use a discriminant prop like this:"). It
  also lists a `never`-based "one or the other" alternative. Source:
  <https://react-typescript-cheatsheet.netlify.app/docs/advanced/patterns_by_usecase/>
- **Avoid contradictory state** by grouping it into a union of states
  (`status: 'idle' | 'loading' | 'success' | 'error'`), as react.dev shows for
  `useState`, and "Avoid contradictions in state." Sources:
  <https://react.dev/learn/typescript>,
  <https://react.dev/learn/choosing-the-state-structure>

  ```tsx
  type Props =
    | { type: "link"; href: string }
    | { type: "button"; onClick: () => void };
  ```

- **Replacing `defaultProps` / `propTypes` (React 19+).** React 19 removes
  `propTypes` checks ("using them will be silently ignored") and `defaultProps`
  for function components. Use TypeScript types and ES default parameters.
  Class components keep `defaultProps` "since there is no ES6 alternative".
  Source: <https://react.dev/blog/2024/04/25/react-19-upgrade-guide#removed-proptypes-and-defaultprops>

  ```tsx
  function Heading({ text = "Hello, world!" }: { text?: string }) {
    return <h1>{text}</h1>;
  }
  ```

- If a prop is meant only as a starting value, name it `initial*`/`default*`
  (see [composition-props.md](composition-props.md#props-and-state)).

## `interface` vs `type`

Practitioners disagree; react.dev is neutral ("an `interface` or `type`").

- Pocock, in the props article: "In general, you should use `interface` to
  declare your props. They're the most performant, and with a code snippet,
  they're fast to write." He is general here and adds that for extending other
  types (`ComponentProps<"input">`) you should use `interface ... extends`
  instead of intersections ("So in situations where you're extending from other
  types, use interfaces."). Source: <https://www.totaltypescript.com/react-props-typescript>
- The same author's general stance: "I'd recommend you use `type` by default.
  It's a little more flexible and a little less surprising." Interfaces remain
  his recommendation for object inheritance. Source:
  <https://www.totaltypescript.com/type-vs-interface-which-should-you-use>
- Unions and mapped types require `type`. On existing code he says not to
  refactor over this (props article).
- Pick one convention per codebase; do not treat either as a rule.

## Children

- Type `children` as `React.ReactNode`: "a union of all the possible types that
  can be passed as children in JSX". `React.ReactElement` "is only JSX elements
  and not JavaScript primitives like strings or numbers". Source:
  <https://react.dev/learn/typescript>
- Pocock: "In everyday use, you should use `React.ReactNode`. You rarely need to
  use the more specific type of `JSX.Element`." Source:
  <https://www.totaltypescript.com/jsx-element-vs-react-reactnode>
- **React 19 types:** the global `JSX` namespace is removed "in favor of
  `React.JSX`", so a bare `JSX.Element` needs to become `React.JSX.Element`.
  Source: <https://react.dev/blog/2024/04/25/react-19-upgrade-guide#the-jsx-namespace-in-typescript>
- You cannot restrict `children` to certain element types with TypeScript (for
  example a component that accepts only `<li>` children). Pass the data as a prop
  instead: `<Select options={[{ value: "1", label: "One" }]} />`. Sources:
  <https://react.dev/learn/typescript#typing-children>,
  <https://www.totaltypescript.com/type-safe-children-in-react-and-typescript>

## `React.FC`

- Consensus: not needed. Cheatsheet: "the general consensus today is that
  `React.FunctionComponent` (or the shorthand `React.FC`) is not needed. If
  you're still using React 17 or TypeScript lower than 5.1, it is even
  discouraged." With current types and TS 5.1 it is "mostly a stylistic choice".
  Source: <https://react-typescript-cheatsheet.netlify.app/docs/basic/getting-started/function_components>
- Pocock (React 18 types and TS 5.1+): "React.FC is now officially 'fine'. It no
  longer implicitly includes children in the props type." He still recommends
  annotating props; "if you do use `React.FC` in your codebase, there's no
  reason to remove it." Source: <https://www.totaltypescript.com/you-can-stop-hating-react-fc>
- Hard reason to avoid it: `FunctionComponent<P = {}>` fixes `P` on the
  interface and its call signature has no type parameter, so generic components
  (`<T,>(props: ListProps<T>) => ...`) cannot be annotated as `FC`. Source:
  <https://raw.githubusercontent.com/DefinitelyTyped/DefinitelyTyped/master/types/react/index.d.ts>

  ```tsx
  function List<T>({ items, getKey, render }: {
    items: T[];
    getKey: (t: T) => React.Key;
    render: (t: T) => React.ReactNode;
  }) {
    return <ul>{items.map((t) => <li key={getKey(t)}>{render(t)}</li>)}</ul>;
  }
  ```

## Events, state, reducers, context, styles

All from <https://react.dev/learn/typescript> (anchors per topic).

- **Events.** "When you want to extract a function to be passed to an event
  handler, you will need to explicitly set the type of the event." Inline
  handlers are inferred. Anchor `#typing-dom-events`.

  ```tsx
  function handleChange(event: React.ChangeEvent<HTMLInputElement>) {
    setValue(event.currentTarget.value);
  }
  ```

- **`useState`.** Inferred from the initial value; pass a type argument when the
  state is a union: `useState<Status>("idle")`. Anchor `#typing-usestate`.
- **`useReducer`.** "it is often better to set the type on the initial state
  instead"; the page also shows the explicit `useReducer<State>(...)` form.
  Type the action as a union. Anchor `#typing-usereducer`.
- **`useContext` with a `null` default.** "Our recommendation is to have the Hook
  do a runtime check for it's existence and throw an error when not present."
  Anchor `#typing-usecontext`.

  ```tsx
  const useTheme = () => {
    const theme = useContext(ThemeContext);   // ThemeContext: createContext<Theme | null>(null)
    if (!theme) throw new Error("useTheme must be used within ThemeProvider");
    return theme;
  };
  ```

- **Style objects.** Use `React.CSSProperties`. Anchor `#typing-style-props`.

## React 19 type and API changes

- `ReactElement` props default to `unknown` instead of `any` (React 19 types).
  Element introspection "only exists as an escape hatch, and you should make it
  explicit that your props access is unsound via an explicit `any`." Source:
  <https://react.dev/blog/2024/04/25/react-19-upgrade-guide#changes-to-the-reactelement-typescript-type>
- With the new JSX transform you do not need `import React` for JSX; React 19
  requires the new transform for ref-as-prop and JSX speed improvements, and
  most environments already enable it. Source:
  <https://react.dev/blog/2024/04/25/react-19-upgrade-guide#installing>
- `defaultProps`/`propTypes`: see [Typing props](#typing-props).

## `any`

- typescript-eslint: `any` is "a dangerous 'escape hatch'... generally best used
  only as a last resort or when prototyping code". Prefer `unknown` and narrow.
  Source: <https://typescript-eslint.io/rules/no-explicit-any/>
- The documented exception is React 19's explicit `any` for unsound props
  access (above).
- Block's AI-migration lint set: "do not add new `as any` casts" (team rule, not
  general React guidance). Source:
  <https://engineering.block.xyz/blog/from-base-web-to-fluent-ui-without-a-flag-day>
