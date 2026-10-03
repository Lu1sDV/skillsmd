# Intrafile Taint Analysis (`--taint-intrafile`) - Demo

## Overview

The `--taint-intrafile` flag enables cross-function taint analysis within a single file. This allows Opengrep
 to track how taint flows through function calls, method invocations, object constructors, and return values - detecting vulnerabilities that span multiple functions in the same file.

**Key Insight**: Without `--taint-intrafile`, taint analysis is limited to single functions. With this flag, Opengrep
 builds function signatures and uses topological ordering to propagate taint across function boundaries.

## How to Run These Examples

### Setup

Save this rule file as `demo_taint.yaml`:

```yaml
rules:
  - id: demo-taint
    mode: taint
    message: Taint flow detected from source to sink
    pattern-sources:
      - pattern: source(...)
    pattern-sinks:
      - pattern: sink(...)
    languages:
      - python
      - javascript
    severity: ERROR
```

### Running Opengrep


```bash
# Without cross-function analysis (baseline)
opengrep scan -c demo_taint.yaml example.py

# With cross-function analysis
opengrep scan -c demo_taint.yaml example.py --taint-intrafile
```

### Running Semgrep 1.139.0 (for comparison)

```bash
# Semgrep's cross-function analysis
semgrep scan -c demo_taint.yaml example.py --pro-intrafile
```

---

## Example 1: Basic Cross-Function Taint Propagation

**File: `example1.py`**

```python
def pass_through(value):
    return value

def get_input():
    return source()

def main():
    input_data = get_input()
    result = pass_through(input_data)
    sink(result)
```

**What happens:**
- `get_input()` returns tainted value from `source()`
- Taint flows through `main()` into `pass_through()` function
- Returns from `pass_through()`
- Reaches `sink()`

**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ✅ **Finding detected**
- Semgrep with `--pro-intrafile`: ✅ **Finding detected**

---

## Example 2: Constructor-Based Taint Tracking

**File: `example2.py`**

```python
class User:
    def __init__(self, user_name):
        self.name = user_name

    def get_profile(self):
        query = self.name
        sink(query)

def main():
    tainted_input = source()
    user = User(tainted_input)
    user.get_profile()
```

**What happens:**
- Taint from `source()` enters `User.__init__()` as parameter
- Assigned to instance field `self.name`
- Field is read in `get_profile()` method
- Assigned to local variable and reaches `sink()`

**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ✅ **Finding detected**
- Semgrep with `--pro-intrafile`: ❌ **No finding** (Semgrep doesn't track taint through constructors in this pattern)

---

## Example 3: Field Assignment After Construction

**File: `example3.py`**

```python
class FieldUser:
    def __init__(self):
        self.name = ""

    def get_profile(self):
        query = self.name
        sink(query)

def main():
    tainted_input = source()
    field_user = FieldUser()
    field_user.name = tainted_input
    field_user.get_profile()
```

**What happens:**
- Object created with clean fields
- Tainted value assigned to field after construction
- Field read in method
- Reaches sink

**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ✅ **Finding detected**
- Semgrep with `--pro-intrafile`: ❌ **No finding** (Semgrep doesn't track taint through field assignments)

---

## Example 4: Inter-Method Taint Flow

**File: `example4.py`**

```python
class IntermethodClass:
    def taint_method(self):
        return source()

    def sink_method(self):
        data = self.taint_method()
        sink(data)

def main():
    obj = IntermethodClass()
    obj.sink_method()
```

**What happens:**
- `taint_method()` returns tainted value
- `sink_method()` calls `taint_method()`
- Taint flows from method call to sink

**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ✅ **Finding detected**
- Semgrep with `--pro-intrafile`: ❌ **No finding** (Semgrep doesn't track taint through inter-method calls)

---

## Example 5: Multi-Hop Propagation

**File: `example5.py`**

```python
class User:
    def __init__(self, user_name):
        self.name = user_name

    def get_profile(self):
        query = self.name
        sink(query)

def create_user():
    tainted_input = source()
    user = User(tainted_input)
    return user

def process_user(user):
    return user.get_profile()

def main():
    user = create_user()
    process_user(user)
```

**What happens:**
- `source()` → `create_user()` → `User.__init__()` → `user.name`
- `user` object passed to `process_user()`
- `process_user()` calls `get_profile()`
- Taint reaches sink through multiple function hops

**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ✅ **Finding detected**
- Semgrep with `--pro-intrafile`: ❌ **No finding** (Semgrep doesn't track taint through constructors and multi-hop propagation)

---

## Example 6: Nested Functions

**File: `example6.py`**

```python
def outer():
    def inner():
        return source()

    x = inner()
    sink(x)

outer()
```

**What happens:**
- Nested function `inner()` returns tainted value
- `outer()` calls `inner()` and receives taint
- Taint flows to sink

**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ✅ **Finding detected**
- Semgrep with `--pro-intrafile`: ✅ **Finding detected**

---

## Example 7: Topological Ordering - Functions Defined Out of Order (JavaScript)

**File: `example7.js`**

**Rule file for JavaScript: `demo_taint_js.yaml`**
```yaml
rules:
  - id: demo-taint-js
    mode: taint
    message: Taint flow detected from source to sink
    pattern-sources:
      - pattern: source(...)
    pattern-sinks:
      - pattern: sink(...)
    languages:
      - javascript
    severity: ERROR
```

```javascript
// Caller defined BEFORE helper
function caller() {
    const userInput = source();
    sink(helper(userInput));
}

// Helper defined AFTER caller - but analyzed first!
function helper(data) {
    return data;
}

caller();
```

**What happens:**
- Call graph determines `helper()` must be analyzed first
- Even though `helper()` appears after `caller()` in the file
- Signature of `helper()` is available when analyzing `caller()`
- Taint propagates correctly

**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ✅ **Finding detected**
- Semgrep with `--pro-intrafile`: ✅ **Finding detected**

---

## Example 8: Higher order functions. 
```typescript
function test_custom_foreach() {
  const arr = [source()];
  customForEach(arr, (x) => {
    sink(x); 
  });
}
```

This is a complex issue. Support for various constructs is subtle and language dependent. We support as many use cases as possible.  Details are discussed in [Higher order functions tutorial](Higher-order-functions-tutorial.md).
**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ✅ **Finding detected**
- Semgrep with `--pro-intrafile` ❌ No finding (but simpler use cases are detected)

---

## Example 9: methods that taint

Consider the following:
```python
def test_list_append():
    tainted = source()
    lst = []
    lst.append(tainted)
    sink(lst) 
```
the `lst` gets tainted by the append and so it should flow into the sink.
**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ✅ **Finding detected**
- Semgrep with `--pro-intrafile` ❌ No finding

---

## Example 10: variadic functions

Taint is propagated also through variadic arguments. For example:

```python
def process_elements(*args):
    for x in args:
        sink(x)

process_elements('a', 'b', source(), 'z')
``` 

**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ✅ **Finding detected**
- Semgrep with `--pro-intrafile` ❌ No finding

---

## Features not yet implemented:
1. Inheritance is not yet supported, for example the following gives a false negative:
```python
class BaseClass:
    def __init__(self):
        self.name = source()

class ChildClass(BaseClass):
    def method(self):
        sink(self.name)
 
```
**Results:**
- Opengrep
 without `--taint-intrafile`: ❌ No finding
- Opengrep
 with `--taint-intrafile`: ❌ No finding
- Semgrep with `--pro-intrafile`: ❌ No finding

---

## Summary Table

| Example | Description | Opengrep without flag | Opengrep `--taint-intrafile` | Semgrep `--pro-intrafile` |
|---------|-------------|-------------------|------------------------------|---------------------------|
| 1 | Basic cross-function | ❌ | ✅  | ✅ |
| 2 | Constructor taint | ❌ | ✅ | ❌ |
| 3 | Field assignment | ❌ | ✅ | ❌ |
| 4 | Inter-method flow | ❌ | ✅ | ❌ |
| 5 | Multi-hop propagation | ❌ | ✅ | ❌ |
| 6 | Nested functions | ❌ | ✅ | ✅ |
| 7 | Topological order (JS) | ❌ | ✅ | ✅ |
| 8 | Higher order functions | ❌ | ✅ | partial |
| 9 | Tainting methods | ❌ | ✅ | ❌ |
| 10 | Variadic functions | ❌ | ✅ | ❌ |
| 11 | Inheritance | ❌ | ❌ | ❌ |
**Key Findings:**
- **Opengrep
 with `--taint-intrafile` finds  7/9 examples** ✅
- **Semgrep with `--pro-intrafile` finds 4 out of 9 examples** 
- **Opengrep
's advantages over Semgrep**: Constructor-based taint tracking (examples 2, 5), field assignment propagation (example 3), inter-method flows (example 4)

