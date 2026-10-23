# Language and object semantics

## Contents

- [Names, values, and mutation](#names-values-and-mutation)
- [Numbers, truth, and collections](#numbers-truth-and-collections)
- [Text and indexing](#text-and-indexing)
- [Functions, scope, and ordinary classes](#functions-scope-and-ordinary-classes)

## Names, values, and mutation

Assignment binds a name; it does not copy an object. Mutation through any alias
is visible through the others. `+=` may mutate a list but rebind an integer or
string. Check the actual type before treating augmented assignment as a copy.
Use `==` for values and `is` for identity (`None`, a private sentinel, or an
explicit alias check). Integer caches, string interning, tuple reuse, and memory
addresses are implementation details, not portable contracts.

```pycon
>>> original = [[1], [2]]
>>> alias = original
>>> shallow = original.copy()
>>> shallow is original, shallow[0] is original[0]
(False, True)
>>> shallow[0].append(3)
>>> alias
[[1, 3], [2]]
>>> import copy
>>> independent = copy.deepcopy(original)
>>> independent[0].append(4)
>>> original[0], independent[0]
([1, 3], [1, 3, 4])
>>> matrix = [[0] * 2 for _ in range(2)]
>>> matrix[0][0] = 1
>>> matrix
[[1, 0], [0, 0]]

```

A shallow copy retains children; `deepcopy` is not a universal isolation tool:
it uses a memo to preserve graph sharing/cycles, honors custom copy hooks, and
cannot meaningfully clone every external resource. A tuple can contain mutable
children. A frozen dataclass prevents normal field assignment, not nested mutation
or malicious modification. Uppercase names and `Final` are conventions/static
contracts, not runtime constants.

Defaults are evaluated at definition time, including calls such as `datetime.now()`.
Use `is None`, not `items or []`, when an explicitly passed empty container must
be retained. Use `object()` as a private sentinel if `None` is valid data.

```pycon
>>> def append_tag(tag, tags=None):
...     if tags is None:
...         tags = []
...     tags.append(tag)
...     return tags
>>> provided = []
>>> append_tag('a', provided) is provided
True
>>> append_tag('b'), append_tag('c')
(['b'], ['c'])

```

## Numbers, truth, and collections

- Integers have arbitrary precision, subject to memory; conversions, arithmetic,
  and huge decimal strings still have resource limits. `bool` subclasses `int`:
  `isinstance(True, int)` is true. Use `type(value) is int` when the contract
  deliberately rejects booleans and subclasses, not as a universal style rule.
- `//` floors, including negative operands; `int(float_value)` truncates toward
  zero. `%` follows the divisor's sign. Floats are approximate; use
  `math.isclose` with application-specific tolerances, not blind rounding.
  `float('nan') != float('nan')`; reject nonfinite input when required.
  Complex values have `.real`/`.imag`, but no natural ordering.
- `and`/`or` return operands, not necessarily bools. `value or default` replaces
  valid zero/empty values too. Objects may implement `__bool__` or `__len__`;
  truth testing can execute user code or raise.
- Chained comparisons evaluate the middle expression once. Membership means
  different things for mappings (keys), sequences (elements), and strings
  (substrings). Avoid assuming truth, equality, and identity are interchangeable.
- Lists are mutable sequences; tuples are fixed containers (the comma creates
  a singleton tuple); sets deduplicate hashable values; `{}` is an empty dict,
  not a set. Dicts preserve insertion order, but equality ignores order.
  Updating a key keeps its position; deleting and reinserting moves it last.
- Equal hashable numeric values share dict/set entries: `1`, `1.0`, and `True`
  collide by equality, not just hash. A hash collision alone does not imply equality.
  Dict views are live. Avoid changing container size during iteration; build a
  filtered result or deliberately iterate a snapshot.

```pycon
>>> -7 // 3, -7 % 3, int(-7 / 3)
(-3, 2, -2)
>>> zero = 0
>>> zero if zero is not None else 99
0
>>> values = {1: 'integer', 1.0: 'float', True: 'boolean'}
>>> len(values), values[1]
(1, 'boolean')
>>> data = {'a': 1}
>>> keys = data.keys()
>>> data['b'] = 2
>>> list(keys)
['a', 'b']

```

## Text and indexing

`str` contains Unicode code points, `bytes` contains integers 0–255. Encode and
decode explicitly at boundaries; `str(bytes_value)` is a representation, not a
decoder. A code point is not necessarily a displayed grapheme. Slices use an
exclusive stop, allow negative indices/steps, and clamp out-of-range bounds;
indexing can raise `IndexError`. A zero slice step is invalid.

Prefer `f'{value:.2f}'` for display, `repr`/`!r` for debugging, and `join` when
assembling pieces. Strings are immutable. Do not claim a measured speedup or
universal quadratic cost for every `+=` loop: CPython has optimizations, but
`join` makes assembly intent portable. `split()` collapses whitespace;
`split(',')` preserves empty fields. `strip(chars)` removes a set of edge
characters, not a literal prefix/suffix. `find` returns -1; `index` raises on
absence. `isdigit()` is Unicode-aware and is not proof `int(text)` will accept it.
Raw literals still have syntax restrictions (notably an odd trailing backslash).

```pycon
>>> text = 'é'
>>> len(text), len(text.encode('utf-8'))
(1, 2)
>>> ' a  b '.split(), 'a,,b'.split(',')
(['a', 'b'], ['a', '', 'b'])
>>> 'report.txt'.removesuffix('.txt'), 'Python'[::-1]
('report', 'nohtyP')
>>> f'{42:05d}', f'{3.14159:.2f}'
('00042', '3.14')

```

## Functions, scope, and ordinary classes

Use `def` for named logic, lambdas for small key/callback expressions. `/` marks
positional-only parameters; parameters after `*` are keyword-only. `*args` is a
tuple, `**kwargs` a dict. `f(*args, **kwargs)` expands arguments; duplicate keyword
bindings raise, unlike `{**left, **right}`/`left | right`, where right wins.
Tuple-return and extended unpacking express fixed structure; starred assignment
collects a list and requires enough input elements.

Normal function lookup follows local/enclosing/global/builtins. Binding anywhere
in a function normally makes the name local throughout that function, so reading
before binding raises `UnboundLocalError`. `nonlocal` rebinds an enclosing
function variable; `global` rebinds a module name. Prefer returned values to
unnecessary global state. Avoid shadowing `list`, `id`, or `str`. Comprehension
loop variables have their own scope; assignment expressions have special binding
rules, so do not use walrus-heavy comprehensions as scope puzzles.

```pycon
>>> def make_counter():
...     count = 0
...     def increment():
...         nonlocal count
...         count += 1
...         return count
...     return increment
>>> counter = make_counter()
>>> counter(), counter()
(1, 2)
>>> callbacks = [lambda value, factor=i: value * factor for i in range(3)]
>>> [callback(10) for callback in callbacks]
[0, 10, 20]
>>> def label(value, /, *, prefix='id'):
...     return f'{prefix}:{value}'
>>> label(7, prefix='user')
'user:7'

```

Closures resolve captured variables when called. Default capture binds the
current object reference, not a deep copy and not a new closure cell.

`__init__` initializes an instance; ordinary methods receive `self`.
`@classmethod` receives `cls` (useful for alternate constructors), while
`@staticmethod` binds neither; a module function often suffices. Put per-instance
mutable state in `__init__` or a dataclass `field(default_factory=list)`, never a
shared class list accidentally. Properties can validate assignments; run the same
validation during construction (e.g. `self.radius = radius`, not bypassing the
setter with `self._radius = radius`). Inheritance supports overriding and
`isinstance` includes subclasses; prefer composition when substitutability is absent.

Implement protocols only when useful: `__repr__` for debugging, `__str__` for
users, `__len__`/`__iter__` for containers, `__getitem__` with appropriate boundary
errors, and operators for genuine domain operations. For unsupported operands,
return `NotImplemented` from comparisons/arithmetic rather than accessing unknown
attributes; it is not `NotImplementedError`. Equal hashable objects must have
equal, stable hashes: do not hash mutable coordinate fields as upstream does.
Detailed MRO, descriptors, `__new__`, metaclasses, API typing, and class-pattern
contracts are optional **python-api-design** handoffs.

Sources: [data model](https://docs.python.org/3.14/reference/datamodel.html),
[expressions](https://docs.python.org/3.14/reference/expressions.html),
[execution model](https://docs.python.org/3.14/reference/executionmodel.html),
[copy](https://docs.python.org/3.14/library/copy.html).
