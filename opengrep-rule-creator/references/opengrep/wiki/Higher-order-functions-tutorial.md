# Higher-Order Function (HOF) Taint Analysis Tutorial

## Overview

Opengrep's `--taint-intrafile` flag enables taint tracking through higher-order functions (HOFs) - functions that take other functions as arguments. This is critical for modern JavaScript/TypeScript codebases that heavily use array methods like `.map()`, `.forEach()`, `.filter()`, and custom callback patterns.

## The Problem

Consider this common pattern:

```typescript
const userInput = getUserInput();  // source
const items = [userInput];
items.forEach((x) => {
    executeCommand(x);  // sink - should be detected!
});
```

Without HOF-aware taint analysis, the connection between `userInput` and the callback parameter `x` is lost. Opengrep with `--taint-intrafile` solves this.

## Quick Start

```bash
opengrep scan --f rule.yaml code.ts --taint-intrafile
```

## Example Rule

```yaml
rules:
  - id: hof-taint-flow
    message: Taint flows through higher-order function
    languages: [ts]
    severity: WARNING
    mode: taint
    pattern-sources:
      - pattern: source(...)
    pattern-sinks:
      - pattern: sink(...)
```

## Comparison: Opengrep vs Semgrep

We tested both tools on a [comprehensive HOF test file](https://github.com/opengrep/opengrep/blob/v1.14.0/tests/rules/cross_function_tainting/test_hof_comprehensive_ts.ts) with 16 taint flows:

```bash
# Opengrep
opengrep scan --config rule.yaml test.ts --taint-intrafile

# Semgrep Pro
semgrep scan --config rule.yaml test.ts --pro-intrafile
```


## All 16 Test Cases

> **Test file**: [`tests/rules/cross_function_tainting/test_hof_comprehensive_ts.ts`](https://github.com/opengrep/opengrep/blob/v1.14.0/tests/rules/cross_function_tainting/test_hof_comprehensive_ts.ts)

### Custom HOF Definitions

These user-defined functions demonstrate HOF patterns that Opengrep can analyze through signature generation:

```typescript
function customMap(arr, callback) {
  const result = [];
  for (let i = 0; i < arr.length; i++) {
    result.push(callback(arr[i]));
  }
  return result;
}

function customForEach(arr, callback) {
  for (let i = 0; i < arr.length; i++) {
    callback(arr[i]);
  }
}

function directCall(callback) {
  callback(source());
}
```

---

### Case 1: Custom Map

**Problem**: User-defined HOFs that iterate over arrays and apply callbacks are common in codebases. Taint must flow from `arr[i]` through the `callback` invocation to the callback's parameter.

**Why it matters**: Libraries and application code frequently define custom iteration utilities. Without analyzing the HOF body, the taint connection is invisible.

```typescript
function test_custom_map() {
  const arr = [source()];
  customMap(arr, (x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
  });
}
```

---

### Case 2: Custom ForEach

**Problem**: Similar to Case 1, but the HOF doesn't return a value - it just executes the callback for side effects.

**Why it matters**: Side-effect-based iteration (logging, sending data, etc.) is a common pattern where taint flows to dangerous operations.

```typescript
function test_custom_foreach() {
  const arr = [source()];
  customForEach(arr, (x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
  });
}
```

---

### Case 3: Direct Call

**Problem**: An HOF that directly calls its callback with a tainted value (not from an array).

**Why it matters**: This is the simplest HOF pattern. The source is inside the HOF, and taint must flow through the callback parameter. Both tools detect this because the taint source is directly passed to the callback.

```typescript
function test_direct_call() {
  directCall((x) => {
    sink(x);  // ✅ Opengrep | ✅ Semgrep
  });
}
```

---

### Case 4: Built-in Map

**Problem**: JavaScript's native `Array.prototype.map` iterates over elements, passing each to the callback.

**Why it matters**: `.map()` is one of the most common array methods. Tainted array elements must flow to callback parameters.

```typescript
function test_builtin_map() {
  const arr = [source()];
  arr.map((x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
  });
}
```

---

### Case 5: Built-in FlatMap

**Problem**: `flatMap` combines mapping with flattening - each callback can return multiple values.

**Why it matters**: Common in data transformation pipelines, especially when processing nested structures.

```typescript
function test_builtin_flatMap() {
  const arr = [source()];
  arr.flatMap((x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
  });
}
```

---

### Case 6: Built-in Filter

**Problem**: `filter` passes each element to a predicate callback that decides inclusion.

**Why it matters**: Even though `filter` is typically used for boolean decisions, the callback receives tainted data that could be leaked in the predicate logic.

```typescript
function test_builtin_filter() {
  const arr = [source()];
  arr.filter((x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
    return true;
  });
}
```

---

### Case 7: Built-in ForEach

**Problem**: `forEach` executes a callback for each element purely for side effects.

**Why it matters**: This is the most direct iteration pattern for executing operations on each array element - very common for logging, API calls, or DOM updates.

```typescript
function test_builtin_forEach() {
  const arr = [source()];
  arr.forEach((x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
  });
}
```

---

### Case 8: Built-in Find

**Problem**: `find` returns the first element matching a predicate.

**Why it matters**: Search operations still expose tainted data to the callback, even if only one element is ultimately selected.

```typescript
function test_builtin_find() {
  const arr = [source()];
  arr.find((x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
    return true;
  });
}
```

---

### Case 9: Built-in FindIndex

**Problem**: `findIndex` returns the index of the first matching element.

**Why it matters**: Like `find`, the callback receives each element even though only an index is returned.

```typescript
function test_builtin_findIndex() {
  const arr = [source()];
  arr.findIndex((x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
    return true;
  });
}
```

---

### Case 10: Built-in Some

**Problem**: `some` tests whether at least one element satisfies a predicate.

**Why it matters**: Boolean aggregation methods still pass each element to the callback, creating taint exposure.

```typescript
function test_builtin_some() {
  const arr = [source()];
  arr.some((x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
    return true;
  });
}
```

---

### Case 11: Built-in Every

**Problem**: `every` tests whether all elements satisfy a predicate.

**Why it matters**: Same as `some` - the predicate receives tainted data regardless of the boolean result.

```typescript
function test_builtin_every() {
  const arr = [source()];
  arr.every((x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
    return true;
  });
}
```

---

### Case 12: Built-in Reduce

**Problem**: `reduce` accumulates a result by processing each element with an accumulator.

**Why it matters**: Reduce has a different callback signature `(acc, x)` where taint flows to the second parameter, not the first. This requires understanding the HOF's semantics.

```typescript
function test_builtin_reduce() {
  const arr = [source()];
  arr.reduce((acc, x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
    return acc;
  }, []);
}
```

---

### Case 13: Built-in ReduceRight

**Problem**: `reduceRight` is like `reduce` but processes elements from right to left.

**Why it matters**: Same callback signature as `reduce` - ensures both reduction directions are handled.

```typescript
function test_builtin_reduceRight() {
  const arr = [source()];
  arr.reduceRight((acc, x) => {
    sink(x);  // ✅ Opengrep | ❌ Semgrep
    return acc;
  }, []);
}
```

---

### Case 14: Real-World FlatMap

**Problem**: A realistic pattern where taint flows through a function return value, then through `flatMap` to process nested data structures.

**Why it matters**: This pattern appears frequently in real codebases - fetching data from an API (source), then transforming nested response structures. Requires both cross-function taint tracking AND HOF callback binding.

```typescript
function getHistory(name, owner) {
  const result = source();
  return result;
}

async function test_original_example() {
  const history = await getHistory("name", "owner");
  const items = history.flatMap((node) => {
    const changes = node.associatedPullRequests.nodes;
    return sink(changes);  // ✅ Opengrep | ❌ Semgrep
  });
}
```

---

### Case 15: Top-Level Lambda

**Problem**: A lambda defined at module scope (not inside any function) that is immediately called with tainted data.

**Why it matters**: Top-level code executes on module load. Taint analysis must handle lambdas that aren't nested inside function definitions.

```typescript
const toplevelSink = (x) => sink(x);  // ✅ Opengrep | ✅ Semgrep
toplevelSink(source());
```

---

### Case 16: Top-Level Named Callback

**Problem**: A named function used as a callback reference in a top-level HOF call.

**Why it matters**: When callbacks are passed by reference (not inline), the analyzer must resolve the function name to its definition and bind tainted data to its parameters. This is harder than inline lambdas because it requires cross-referencing function definitions.

```typescript
function toplevelHandler(x) {
  sink(x);  // ✅ Opengrep | ❌ Semgrep
}

const toplevelItems = [source()];
toplevelItems.forEach(toplevelHandler);
```

---

## Summary Table

| # | Test Case | Pattern | Opengrep | Semgrep Pro |
|---|-----------|---------|----------|-------------|
| 1 | Custom Map | User-defined HOF with array iteration | ✅ | ❌ |
| 2 | Custom ForEach | User-defined HOF with side effects | ✅ | ❌ |
| 3 | Direct Call | HOF passes source directly to callback | ✅ | ✅ |
| 4 | Built-in Map | `arr.map(cb)` | ✅ | ❌ |
| 5 | Built-in FlatMap | `arr.flatMap(cb)` | ✅ | ❌ |
| 6 | Built-in Filter | `arr.filter(cb)` | ✅ | ❌ |
| 7 | Built-in ForEach | `arr.forEach(cb)` | ✅ | ❌ |
| 8 | Built-in Find | `arr.find(cb)` | ✅ | ❌ |
| 9 | Built-in FindIndex | `arr.findIndex(cb)` | ✅ | ❌ |
| 10 | Built-in Some | `arr.some(cb)` | ✅ | ❌ |
| 11 | Built-in Every | `arr.every(cb)` | ✅ | ❌ |
| 12 | Built-in Reduce | `arr.reduce(cb)` - taint to 2nd param | ✅ | ❌ |
| 13 | Built-in ReduceRight | `arr.reduceRight(cb)` | ✅ | ❌ |
| 14 | Real-World FlatMap | Cross-function + nested data | ✅ | ❌ |
| 15 | Top-Level Lambda | Module-scope lambda call | ✅ | ✅ |
| 16 | Top-Level Named Callback | Named function as callback reference | ✅ | ❌ |

---

## Language Support

HOF taint tracking works across multiple languages:

| Language | Built-in HOFs | Custom HOFs |
|----------|--------------|-------------|
| JavaScript/TypeScript | `map`, `flatMap`, `filter`, `forEach`, `find`, `findIndex`, `some`, `every`, `reduce`, `reduceRight` | ✅ |
| Python | `map()`, `filter()` | ✅ |
| Ruby | `map`, `each`, `select`, `filter`, `flat_map`, `collect`, `find`, `detect` | ✅ |
| PHP | `array_map`, `array_filter`, `array_walk` | ✅ |
| Java | `map`, `filter`, `forEach`, `flatMap` (Stream API) | ✅ |
| Kotlin | `map`, `filter`, `forEach`, `flatMap`, `find`, `any`, `all` | ✅ |
| Swift | `map`, `filter`, `forEach`, `flatMap`, `compactMap`, `first`, `contains` | ✅ |
| Scala | `map`, `filter`, `foreach`, `flatMap`, `find`, `exists`, `forall` | ✅ |
| C# | `Select`, `Where`, `ForEach`, `SelectMany`, `First`, `Any`, `All` (LINQ) | ✅ |
| Rust | `map`, `for_each`, `filter`, `flat_map`, `find`, `any`, `all` | ✅ |
| Julia | `map`, `foreach`, `filter` | ✅ |
| C++ | `for_each`, `transform` (STL algorithms) | ✅ |
| Elixir | `Enum.map`, `Enum.each`, `Enum.filter`, `Enum.flat_map`, `Enum.find` | ✅ |

