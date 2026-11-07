# react-hooks-state

React Effects (when needed and when not), derived state, dependencies and cleanup,
`useEffectEvent` (≥ 19.2), refs, custom hooks, Rules of Hooks, `useState`/`useReducer`,
Context, lifting/colocating state, Redux/Zustand/Jotai, and Strict Mode. Baseline:
React 19.3, React Compiler 1.0, `eslint-plugin-react-hooks` 7, Zustand v5, TanStack Query
v5. Self-contained: no sibling skill installation is needed.

## Install

From the skillsmd checkout (preserve local changes before replacing an existing
installation):

```sh
mkdir -p ~/.claude/skills
cp -r react-hooks-state ~/.claude/skills/
```

## Usage

- “Review this component: which `useEffect` calls are unnecessary and what replaces them?”
- “This Effect re-subscribes on every render. Fix the dependency array without suppressing the linter.”
- “Why does my Zustand v5 selector cause ‘Maximum update depth exceeded’?”
- “Our Context provider re-renders every consumer on each keystroke. Where should this state live?”
- “`window is not defined` from `useState(() => window.innerWidth)` — fix it for SSR.”

## Reference index

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Trigger, route table, workflow, high-risk rules, skill myths, handoffs |
| [Effects](references/effects.md) | When Effects are/aren't needed, derived state and resets, dependencies, cleanup, Strict Mode, `useEffectEvent`, `useLayoutEffect`, lint rules |
| [State, Context, stores](references/state-context-stores.md) | `useState`/updaters/`useReducer`, state shape, colocation, Context, server vs client state, `useSyncExternalStore`, Zustand/Redux/Jotai, storage |
| [Refs and custom hooks](references/refs-custom-hooks.md) | Rules of Hooks, `use()`, refs, custom-hook design and naming, render purity |

## Sources and decisions

Evidence basis: an auditor classified 57 claim clusters (V1) drawn from about 46 agent
skills against community sources (react.dev, React-team posts, library maintainers,
respected engineers); an independent verifier re-fetched the sources for every
supported cluster on **2026-11-07** (all CONFIRMED or CONFIRMED-ADJUSTED, none disputed).
Only that evidence is used; a claim found only in other agent skills is not.

Correction decisions (verifier overrides auditor):

- **Zustand selectors**: TkDodo's “always use selectors” stands, but in v5 an unstable
  selector can loop; `useShallow` or primitive selectors are required, not optional.
- **`set-state-in-effect`**: in plugin v7+ it is in `recommended` at error severity (opt-in
  in v6); it flags only synchronous `setState`, and ref/measurement-driven updates are valid.
- **`useEffectEvent`**: version-gated to 19.2 with the linter upgrade; call-site limits
  stated; “stable identity” rationale rejected.
- **`use()`**: also not allowed in `try`/`catch`, only in render, and not for context in
  Server Components.
- **`useLayoutEffect`**: “after paint” is a tendency; scope is visual flicker/layout, not
  measurement only.
- **`localStorage`**: guard the property access as well as `setItem`; private-mode limits
  are documented by MDN.
- **Library size mapping** (Zustand/Jotai small, RTK large): Zustand and Jotai position
  themselves as scalable, and Redux lists codebase size among several need criteria, so
  size alone doesn't decide; replaced by Redux's need criteria.
- **`useTransition` vs `isLoading`**: updates after `await` need re-wrapping; not a
  replacement for fetch-library loading state.
- **Lifecycle-wrapper linter point**: a default blind spot only; `additionalEffectHooks`
  (plugin ≥ 6.1.1) can register wrappers.
- **2026-11-07 source-support fact-check**: 15 issues fixed (1 WRONG, 4 OVERSTATED, 8
  MISCITED, 2 nits): the `useRef` guard wording (it hides the double-run but doesn't fix
  the bug), the “synchronously” qualifier, the app-size claim, the latest-callback ref
  version gate, the transition limitation, and missing or misattributed source URLs.

Intra-community disagreements are stated, not resolved: Context as a state manager
(react.dev reducer+context vs Erikson/TkDodo “dependency injection”), context re-render
severity (scale-dependent), and Redux need (Abramov 2016 vs Erikson vs TanStack).

Excluded (no community source found, so not presented as consensus): preferring Zustand
with `subscribeWithSelector` or “one library per category” (V1-13; kept only as a labelled
project-policy line), URL-state/router-loader rules (V1-14), reading store state on demand
with `getState()` (V1-15), a `{state, actions, meta}` context shape (V1-16), no `async`
Effect callbacks (V1-17; kept only as a labelled project-policy line), `useForm` return in
dependencies (V1-18), and non-hook “actions” modules (V1-19). Claims owned by other
skills (data-fetching mechanics, memo/Compiler details, ref-as-prop, hydration) are left to
their handoff skills.

Limits: sources are documentation and engineering writing, not execution of the examples;
the snippets are short illustrations and were not compiled.
