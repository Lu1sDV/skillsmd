# `memo` / `useMemo` / `useCallback` and React Compiler 1.0

Baseline: React 19.3, React Compiler 1.0 (stable 2025-10-07),
eslint-plugin-react-hooks 7. Every rule has a source URL.

Contents: [Manual memoization](#manual-memoization) ·
[Compiler: new vs existing code](#compiler-new-vs-existing-code) ·
[Compiler setup and versions](#compiler-setup-and-versions) ·
[Compiler debugging](#compiler-debugging) ·
[Where sources disagree](#where-sources-disagree)

Examples assume the compiler is **off** unless stated.

## Manual memoization

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| MM1 | `useMemo` is "only valuable in a few cases": (a) the calculation is noticeably slow and its dependencies rarely change; (b) the value is a prop to a `memo` component; (c) the value is later a dependency of another Hook (including `useEffect`). | These are the three triggers on the useMemo page; react.dev's useContext page adds memoizing a provider `value` (see measure-rerenders C4). A fresh `Map`/`Set` is a non-primitive, so (b)/(c) justify memoizing it even if cheap. "1 ms" is react.dev's illustration. | <https://react.dev/reference/react/useMemo> · <https://react.dev/reference/react/useContext> |
| MM2 | `useCallback` is "only valuable in a few cases": pass to a `memo` child, or the function is later a dependency of some Hook. | Otherwise "you don't *have to*" use it. | <https://react.dev/reference/react/useCallback> |
| MM3 | `memo` is "only valuable when your component re-renders often with the same exact props, and its re-rendering logic is expensive." If no perceptible lag, it is unnecessary. | All three conditions together. React Flow recommends that custom node/edge components passed to `<ReactFlow>` should either be memoized with `React.memo` or declared outside the parent component (stable component reference). | <https://react.dev/reference/react/memo> · <https://reactflow.dev/learn/advanced-use/performance> |
| MM4 | Don't wrap constants (e.g. a literal array) in `useMemo`: "it's probably worse ... we're making a function call". Hoist constants to module scope. | Cost is overhead, not breakage; react.dev: "There is no significant harm to doing that either" (see [disagreements](#where-sources-disagree)). | <https://kentcdodds.com/blog/usememo-and-usecallback> · <https://react.dev/reference/react/memo> |
| MM5 | A `useMemo` whose dependencies change every render does nothing ("essentially becomes useless"). Remove or stabilize the unstable dependency at its source, or find which dependency breaks memoization. | | <https://www.developerway.com/posts/how-to-write-performant-react-code> · <https://react.dev/reference/react/useMemo> |
| MM6 | When passing a function to a memoized component, either declare it outside the component, or use `useCallback`. For an object prop, create it with `useMemo` in the parent. Move values that don't depend on props/state outside the component. | Applies when the child is `memo` or the value is a dependency. A default in a `memo` component's own destructuring does not break that component's `memo` (inference from react.dev + MDN default-parameter semantics); the hoist matters when the value is passed on to a further `memo` child or Hook dependency, or the parent passes a fresh `() => {}`/`[]`. | <https://react.dev/reference/react/memo> · <https://react.dev/learn/removing-effect-dependencies> |
| MM7 | `useMemo`/`useCallback` help only on re-renders; they add work on first render. Their cache is a performance hint: don't rely on it for correctness, use state or a ref when a value must persist. | React may discard cache (e.g. editing the file in development, suspending during initial mount). | <https://www.developerway.com/posts/how-to-use-memo-use-callback> · <https://react.dev/reference/react/useMemo> |
| MM8 | Typical `useMemo` target: heavy parts of the render tree (React elements), not cheap array/object operations. A lookup `Map`/`Set` or single-pass partition for list rendering is fine when the collection is large or the work measurably costly. | | <https://www.developerway.com/posts/react-re-renders-guide> · <https://react.dev/reference/react/useMemo> |
| MM9 | Airbnb: a filter that returns a new array each render "will deoptimize any pure components receiving this array as a prop"; memoizing the derived array fixed it. | Case study; applies to pure/`memo` children. | <https://medium.com/airbnb-engineering/recent-web-performance-fixes-on-airbnb-listing-pages-6cd8d93df6f4> |
| MM10 | Keep `exhaustive-deps` on: it validates dependency arrays including those for `useMemo`/`useCallback`. Dependency list must have a constant number of items, written inline. | | <https://react.dev/reference/eslint-plugin-react-hooks> · <https://react.dev/reference/react/useMemo> |

```tsx
// Without the compiler: stabilize only what a memo child receives.
const Row = memo(function Row({ item, onSelect }: RowProps) { /* … */ });

function List({ items }: { items: Item[] }) {
  const [, setSelectedId] = useState<string | null>(null);
  const onSelect = useCallback((id: string) => setSelectedId(id), []); // child is memo
  return items.map((i) => <Row key={i.id} item={i} onSelect={onSelect} />);
}
// <button onClick={() => setSelectedId(id)}> on a DOM element needs no useCallback.
```

## Compiler: new vs existing code

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| CP1 | New code: "we recommend relying on the compiler for memoization and using `useMemo`/`useCallback` where needed to achieve precise control." | Only when the compiler is actually enabled for that file/project; check the build config first. Without it, MM1–MM3 apply. | <https://react.dev/blog/2025/10/07/react-compiler-1> · <https://react.dev/learn/react-compiler/introduction> |
| CP2 | Existing code: "either leaving existing memoization in place (removing it can change compilation output) or carefully testing before removing the memoization." | Remove per component with tests and profiling, never as a bulk sweep. "Changing memoization can occasionally have unexpected results." | <https://react.dev/blog/2025/10/07/react-compiler-1> |
| CP3 | `useMemo`/`useCallback` remain an escape hatch: a memoized value used as an effect dependency keeps an effect from firing repeatedly. | The documented keep-case is effect/hook dependency identity and wanting precise control. React docs name no "non-compiled consumer" case. Where a component is skipped or opted out (`"use no memo"`, incompatible library, Rules of React violation) manual memo is the only memoization there. | <https://react.dev/blog/2025/10/07/react-compiler-1> · <https://react.dev/learn/react-compiler/debugging> · <https://react.dev/reference/eslint-plugin-react-hooks/lints/incompatible-library> |
| CP4 | The compiler memoizes components and hooks, "not every function", and "memoization is not shared across multiple components or hooks". For a truly expensive pure function, consider memoizing outside React (module-level cache or data layer). | Profile first "before making code more complicated". | <https://react.dev/learn/react-compiler/introduction> |
| CP5 | The compiler can memoize conditionally (including after an early return), which manual `useMemo` can't. | Stated as capability; no benchmark in the post. | <https://react.dev/blog/2025/10/07/react-compiler-1> |
| CP6 | An incomplete manual-memo dependency array makes the compiler skip the component: "will only compile components and hooks if its inference matches or exceeds the existing manual memoization". Fix the deps or let the compiler handle it. | Skipping means losing compiler optimization for that component, not a build failure. | <https://react.dev/reference/eslint-plugin-react-hooks/lints/preserve-manual-memoization> |
| CP7 | A component that relies on memoized references for correctness is the main way the compiler can break an app (effects that rely on referential equality, deps that need stable references, reference-check conditionals). | Treat memoization as an optimization, not semantics. | <https://react.dev/learn/react-compiler/debugging> |
| CP8 | The compiler hoists static JSX and applies the equivalent of `memo` to all components, so manual hoisting and `memo` are mostly redundant with it on. | Meta reports "up to 12%" faster loads and "more than 2.5×" faster some interactions: vendor-reported, one app, no methodology. | <https://react.dev/reference/react/memo> · <https://react.dev/blog/2025/10/07/react-compiler-1> · <https://raw.githubusercontent.com/vercel-labs/agent-skills/main/skills/react-best-practices/rules/rendering-hoist-jsx.md> |

## Compiler setup and versions

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| CS1 | The compiler "is designed to work best with React 19, but it also supports React 17 and 18". | For 17/18: set `target` (e.g. `'18'`) and install `react-compiler-runtime`. | <https://react.dev/learn/react-compiler/installation> · <https://react.dev/reference/react-compiler/configuration> |
| CS2 | Keep `compilationMode: 'infer'` (default). `'all'` is "Not recommended as it may compile non-React functions" and "may negatively impact performance". | `infer` needs PascalCase/`use`-prefixed names that create JSX or call hooks, or an explicit `"use memo"`. | <https://react.dev/reference/react-compiler/compilationMode> |
| CS3 | Incremental adoption: `compilationMode: 'annotation'` compiles only functions marked `"use memo"`. | Per-file rollout. | <https://react.dev/reference/react-compiler/compilationMode> |
| CS4 | Compiler diagnostics surface through `eslint-plugin-react-hooks` even if the compiler isn't adopted; use the `recommended` preset. The compiler skips offending components and keeps the rest compiled. "You don't need to fix all violations immediately." | **Project policy, not consensus:** promoting these lints to `error` in CI is not a React-team recommendation (React's guidance is gradual). Teams may do it as a no-regression ratchet. | <https://react.dev/reference/eslint-plugin-react-hooks> · <https://react.dev/blog/2025/10/07/react-compiler-1> |
| CS5 | Pin an exact compiler version (e.g. `1.0.0`, not `^1.0.0`) without good test coverage; future versions may change how memoization applies. | | <https://react.dev/blog/2025/10/07/react-compiler-1> |

## Compiler debugging

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| CD1 | To isolate a compiler-related runtime bug, add `"use no memo"` to the component; if the bug persists with all manual memoization removed, it's a Rules of React violation to fix. | Look for violations the ESLint rule did not catch. | <https://react.dev/learn/react-compiler/debugging> |
| CD2 | Use `"use no memo"` "sparingly and temporarily" and document why each time. It must be the first statement in the function body and overrides `all`/`infer`. | "A temporary debugging tool, not a permanent solution." | <https://react.dev/reference/react-compiler/directives/use-no-memo> |

## Where sources disagree

- **Memoize broadly?** react.dev: wrapping in `memo` elsewhere has "no significant harm ... so some teams choose to not think about individual cases, and memoize as much as possible"; Erikson thinks widespread `memo` is "likely a net gain". Dan, Kent, Nadia, TkDodo and Josh advise not memoizing without measurement, or cite comparison cost. Consensus is "don't by default, measure"; the "harmless" question is unresolved. Sources: <https://react.dev/reference/react/memo>, <https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/>, <https://kentcdodds.com/blog/usememo-and-usecallback>.
- **Removing memo under the compiler.** The blog says leave or test carefully (CP2). The lint page <https://react.dev/reference/eslint-plugin-react-hooks/lints/preserve-manual-memoization> shows a simple example and says "You can safely remove it if using React Compiler". The memo page FAQ likewise says "you can safely remove `React.memo` from your components when using React Compiler." (<https://react.dev/reference/react/memo>, "Do I still need React.memo if I use React Compiler?"). Follow the blog's more cautious, later statement for general guidance; the lint page and FAQ show removal is possible when verified.
