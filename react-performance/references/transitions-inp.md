# Transitions, deferred values and INP

Baseline: React 19.3 (async Actions/transitions ≥ 19; `<Activity>` ≥ 19.2).
Every rule has a source URL.

| # | Rule | Conditions / gate | Source |
|---|---|---|---|
| T1 | Mark a state update as a Transition so it is non-blocking and shows no unwanted loading indicators. Criterion: the update is non-urgent and slow to render, not "frequent" [inference]. | Transition updates are interruptible by other updates. | <https://react.dev/reference/react/useTransition> |
| T2 | You can wrap an update only if you have its `set` function. For a prop or custom-Hook value, use `useDeferredValue`. For updates from outside components (e.g. a data library) call the standalone `startTransition`. | | <https://react.dev/reference/react/useTransition> |
| T3 | "Transition updates can't be used to control text inputs." | Keep the input's own state urgent; transition the dependent update. | <https://react.dev/reference/react/useTransition> |
| T4 | State updates in a `setTimeout` inside `startTransition` are not Transitions; after an `await`, wrap later updates in another `startTransition`. | React 19 async Actions handle pending state, errors, forms and optimistic updates, but the post-`await` limitation is documented as known. | <https://react.dev/reference/react/useTransition> · <https://react.dev/blog/2024/12/05/react-19#actions> |
| T5 | `isPending` fits the pending state of an update you wrapped in a transition or Action. | It does not replace loading flags for fetches started in Effects, work after an `await` without re-wrapping, or controlled text inputs. | <https://react.dev/reference/react/useTransition> |
| T6 | `useDeferredValue` only defers the value you pass it. To keep a child from re-rendering during the urgent update, also memoize: wrap the child in `memo`, or `useMemo(() => <Child query={deferred} />, [deferred])`. | Clark (React team) gives both forms; react.dev shows `memo`. | <https://github.com/reactwg/react-18/discussions/129> · <https://react.dev/reference/react/useDeferredValue> |
| T7 | Pass primitives, or objects created outside render, to `useDeferredValue`; a fresh object during render causes "unnecessary background re-renders". | | <https://react.dev/reference/react/useDeferredValue> |
| T8 | `useDeferredValue` "does not by itself prevent extra network requests"; debounce/throttle stay useful to "fire fewer network requests". | So `useDeferredValue`/`useTransition` are not a replacement for debouncing requests. | <https://react.dev/reference/react/useDeferredValue> |
| T9 | INP at or below 200 ms at the 75th percentile of field page loads (mobile and desktop segmented) is "good responsiveness"; above 500 ms is poor. | Web-wide threshold from web.dev, not React docs. Non-React web vitals work → `web-performance-optimization`. | <https://web.dev/articles/inp> |
| T10 | Keep event callbacks light ("do as little work as possible in them") and yield to the main thread, ideally immediately after the callback that updates the UI so rendering runs sooner. | Yielding indiscriminately is still better than not yielding. | <https://web.dev/articles/optimize-inp> |

```tsx
// Typing stays urgent; the heavy list updates in the background.
function Search({ items }: { items: Item[] }) {
  const [query, setQuery] = useState('');
  const deferred = useDeferredValue(query);     // primitive: OK (T7)
  return (
    <>
      <input value={query} onChange={(e) => setQuery(e.target.value)} />
      <SlowList items={items} query={deferred} />   {/* SlowList = memo(...) (T6) */}
    </>
  );
}
// Network work still needs debounce/throttle (T8).
```
