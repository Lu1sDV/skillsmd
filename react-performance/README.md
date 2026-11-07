# react-performance

Measure-first React performance: Profiler workflow, re-render mechanics,
`memo`/`useMemo`/`useCallback`, React Compiler 1.0, code splitting, barrels,
long lists, `<Activity>`, transitions and INP. Baseline: React 19.3, React
Compiler 1.0, eslint-plugin-react-hooks 7, Next.js 16 App Router. Self-contained:
no sibling skill installation is needed.

## Install

From the skillsmd checkout (preserve local changes before replacing an existing
installation):

```sh
mkdir -p ~/.claude/skills
cp -r react-performance ~/.claude/skills/
```

## Usage

- “This list lags when I type in the filter; find out why and fix it without sprinkling `useMemo`.”
- “We enabled React Compiler. Which manual `useMemo`/`useCallback` can go, and how do I verify?”
- “Review this PR that wraps every callback in `useCallback` and every component in `memo`.”
- “Our first load is heavy: audit barrel imports, `next/dynamic` and third-party scripts in the Next.js 16 app.”
- “Should this 5,000-row table be virtualized? How do I decide?”

## Reference index

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Trigger, symptom routing, workflow, high-risk rules, skill myths, handoffs |
| [Measure and re-renders](references/measure-rerenders.md) | Production build, Profiler, re-render mechanics, state placement, context, Zustand/TanStack Query subscriptions, refs, component identity |
| [Memoization and compiler](references/memoization-compiler.md) | `useMemo`/`useCallback`/`memo` triggers, compiler new vs existing code, setup, `"use no memo"`, source disagreements |
| [Loading, bundles, lists](references/loading-bundles-lists.md) | `lazy`/`next/dynamic`, prefetch, third-party scripts, barrels, virtualization, `content-visibility`, `<Activity>`, imperative DOM |
| [Transitions and INP](references/transitions-inp.md) | `useTransition`, `useDeferredValue`, limits, INP thresholds, yielding |

## Sources and decisions

**Evidence basis.** An auditor checked about 126 skill claims (52 clusters)
against official docs, React team posts, library maintainers, respected
engineers and company engineering blogs; an independent verifier then re-fetched
the sources for every supported cluster on 2026-11-07 (34 clusters: 0 disputed).
Claims found only in other AI skills are not used. The detailed rule tables in
`references/` link primary sources; numeric figures from company blogs
(Meta, Shopify, Slack, Wix) are self-reported and single-source.

**Correction decisions (verifier overrides auditor).**
- `next/dynamic` already wraps `React.lazy` + Suspense; `ssr: false` is not
  allowed in Server Components, so Vercel's analytics-in-layout example is
  invalid in the App Router.
- `<Activity>` needs React ≥ 19.2; hidden Effects are destroyed.
- "Non-compiled consumer" is not a React-documented reason to keep manual memo;
  the documented one is effect/hook-dependency identity and precise control.
- Default values in a `memo` component's own destructuring do not break that
  component's `memo`; hoisting matters for onward props, Hook dependencies and
  parents passing fresh literals.
- `useMemo` has three triggers on its own page (slow calculation, `memo` child,
  Hook dependency); react.dev's useContext page adds a Context provider `value`.
  A lookup `Map`/`Set` is justified by the `memo`-child or Hook-dependency trigger even if cheap.
- Passive listeners: advice applies to manual `addEventListener`, not JSX
  handlers.
- Zustand v5: fresh-object selectors can throw; the v4 `shallow` argument is
  gone from `create`; migrate with `useShallow` or `createWithEqualityFn`.
- TanStack Query v5: `notifyOnChangeProps` default `undefined` tracks accessed
  fields automatically; `'tracked'` is not a v5 value.
- 2026-11-07 source-support fact-check: 25 issues fixed (1 WRONG, 9 OVERSTATED,
  3 unconfirmed, 3 miscited, 5 non-verbatim quotes, 1 omitted dissent, 2 minor,
  1 undeclared `select` in a TSX example).

**Disagreements stated, not resolved.** Memoize broadly (react.dev: "no
significant harm"; Erikson: likely net gain) versus measure first (Dan, Kent,
Nadia, TkDodo, Josh). Removing memo under the compiler (blog: leave or test; lint
page and memo FAQ: "can safely remove"). Barrels (Vercel: avoid/optimize; Discord React Native:
whole-library import cheaper). Vercel ranks waterfalls/bundle first for load time;
Dan and Kent order interaction work differently.

**Excluded claims.**
- Unsupported (7 clusters): numeric virtualization thresholds (kept only as a
  myth), internal barrel exports, React Hook Form rules (use the library's
  docs), statically analyzable import paths, `Map` instead of repeated `.find()`,
  compiler-analyzer reporting rules, compiler lint severity at `error` (kept
  only as a labeled project-policy line).
- Out of scope, owned by siblings: Suspense/streaming and waterfall mechanics
  (`react-server-data`); effect hygiene (`react-hooks-state`).

**Not covered.** Context selectors in newer React are not verified beyond the
`useContext` reference; INP guidance for non-React sites is in
`web-performance-optimization`; no benchmark was reproduced.
