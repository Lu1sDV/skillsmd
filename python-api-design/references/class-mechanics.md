# Class mechanics that change API behavior

- [SOLID decisions](#solid-without-five-new-layers)
- [State and public boundaries](#state-and-public-boundaries)
- [Substitutability](#inheritance-must-preserve-consumer-contracts)
- [Cooperative MRO](#super-follows-the-mro-not-the-lexical-parent)
- [Properties and descriptors](#properties-before-custom-descriptors)
- [Hooks and metaclasses](#hooks-before-metaclasses)

## SOLID without five new layers

| Principle | Useful decision | Guardrail |
|---|---|---|
| Single responsibility | Group operations that protect the same invariant or change together | No line-count or method-count rule; an orchestrator may coordinate several operations |
| Open/closed | Expose a stable callable/capability where consumers genuinely need extension | A closed `if`/`match` is often clearer than a plugin registry |
| Liskov substitution | Require no more and promise no less, including errors, units, ordering, mutation and lifetime | Matching method signatures cannot prove behavior; do not truncate silently or report outages as misses |
| Interface segregation | Accept only what the caller needs: `Iterable`, `Mapping`, a callback, or small protocol | Do not split each method into an interface without an actual consumer |
| Dependency inversion | High-level rules receive a policy/resource instead of discovering globals | Define needed capabilities near consumers; direct concrete dependencies are fine when no boundary needs inversion |

For example, normalization can be a pure function and persistence an injected
callable. That separates change reasons without requiring `NormalizerService`,
`RepositoryFactory`, or an abstract base for each. Saving and then notifying still
has a partial-failure problem; rearranging classes does not make it transactional.

## State and public boundaries

- Prefer a function for stateless work. Use a dataclass for a data value, or a class
  when operations jointly protect state/invariants. A large cohesive class need not
  be split solely for a method-count rule; unrelated responsibilities should be.
- `self.items = []` creates per-instance state; a class-level list is shared across
  instances and often subclasses. `ClassVar` documents intended sharing but does
  not create isolation. `field(default_factory=list)` is the dataclass spelling
  for a fresh list; a factory can still intentionally return a shared object.
- `self.count += 1` reads through normal attribute lookup then assigns back. With
  an ordinary class integer attribute, that shadows it on the instance rather
  than updating the class. Mutable values and descriptors can behave differently.
- `_name` is a convention, and `__name` is name-mangling to avoid accidental subclass
  clashes, not security. Exposing a mutable list through a property still exposes
  that list. Return an immutable value/view or documented copy as the contract needs.
- Construction should establish usable state. Do not require a secret sequence of
  setter calls. Resource creation in a constructor is not universally forbidden,
  but must document blocking, failure and cleanup; separate plain data from I/O.
- Identity and equality differ. Dataclasses normally compare equal field values
  only for identical runtime types; compare logical IDs explicitly when that is
  the domain contract. Equal hashable values must have equal stable hashes. Avoid
  mutable equality-bearing dict keys and `unsafe_hash` as a workaround.

## Inheritance must preserve consumer contracts

An override may accept broader inputs or return narrower outputs, but cannot
require more, promise less, silently drop content, or add unsupported mutation.
A square with coupled setters is not substitutable for a mutable rectangle whose
width/height can be set independently. Prefer separate values with a common area
operation or composition; an ABC does not make the semantics sound.

Use inheritance for a genuine substitutable abstraction or a controlled framework
extension point. Compose independently varying policies rather than creating a
subclass for every combination. Mixins should have small documented requirements;
do not hide connection acquisition, global registration, or mutable state in them.

## `super` follows the MRO, not the lexical parent

Python uses C3 linearization; inspect `Type.__mro__` when behavior is surprising.
The next class depends on the **runtime object's** hierarchy, so `super()` in one
mixin may call a sibling rather than the base named in its class declaration.

```pycon
>>> class Base:
...     def steps(self) -> list[str]:
...         return ["base"]
>>> class Left(Base):
...     def steps(self) -> list[str]:
...         return ["left"] + super().steps()
>>> class Right(Base):
...     def steps(self) -> list[str]:
...         return ["right"] + super().steps()
>>> class Combined(Left, Right):
...     def steps(self) -> list[str]:
...         return ["combined"] + super().steps()
>>> assert Combined().steps() == ["combined", "left", "right", "base"]
>>> assert [cls.__name__ for cls in Combined.__mro__] == ["Combined", "Left", "Right", "Base", "object"]

```

For cooperative initialization, every participating class must call `super()`
exactly once with compatible arguments. A mixin may consume its named keyword
arguments and forward the rest, but the final endpoint must not pass unexpected
arguments to `object.__init__`. Do not mix direct `Base.__init__` calls with a
cooperative diamond; that can initialize a base twice or skip a sibling. A generated
dataclass `__init__` does not automatically call a non-dataclass base's `__init__`.
If that initialization is needed, design it deliberately, often in `__post_init__`.

If `B(A)`, subclasses must put `B` **before** `A` in their MRO; `class C(A, B)`
contradicts that ordering and raises `TypeError` during class creation. It is not
because B must follow its ancestor. C3 is not simple depth-first or breadth-first
traversal. Reordering bases changes behavior and can be a compatibility break.

## Properties before custom descriptors

A property is usually enough for one validated attribute. A reusable descriptor is
appropriate when the same access/validation rule applies to several attributes.
Store each target object's value on that object, **not on the shared descriptor**.
Handle class access (`obj is None`) and missing values intentionally.

For ordinary instance lookup, Python first finds the class attribute through the
MRO, then applies precedence: data descriptor, instance dictionary, non-data
descriptor/ordinary class attribute. `__getattr__` is a fallback when normal lookup
raises `AttributeError`. A data descriptor defines `__set__` or `__delete__`; a
non-data descriptor only defines `__get__`. Read-only `property` is still a data
descriptor, and regular functions on classes are non-data descriptors that bind
methods. Custom `__getattribute__` can change the machinery; avoid it without a
specific need and preserve default behavior via `object.__getattribute__`.

```pycon
>>> class NonnegativeInt:
...     def __set_name__(self, owner, name):
...         self._storage = "_" + name
...     def __get__(self, instance, owner=None):
...         if instance is None:
...             return self
...         return instance.__dict__[self._storage]
...     def __set__(self, instance, value):
...         if type(value) is not int or value < 0:
...             raise ValueError("expected nonnegative integer")
...         instance.__dict__[self._storage] = value
>>> class Inventory:
...     quantity = NonnegativeInt()
...     reserved = NonnegativeInt()
...     def __init__(self, quantity, reserved=0):
...         self.quantity = quantity
...         self.reserved = reserved
>>> first, second = Inventory(3), Inventory(8)
>>> assert isinstance(Inventory.quantity, NonnegativeInt)
>>> first.quantity = 2
>>> assert (first.quantity, first.reserved, second.quantity) == (2, 0, 8)
>>> first.__dict__["quantity"] = 999
>>> assert first.quantity == 2
>>> first.quantity = -1
Traceback (most recent call last):
...
ValueError: expected nonnegative integer
>>> assert first.quantity == 2

```

The descriptor validates each field separately; it does not enforce `reserved <=
quantity`. Cross-field invariants need an atomic operation or validated immutable
value, not independent setters that permit intermediate invalid combinations.
Private backing state can still be modified deliberately; this is an API for
cooperating Python code, not a tamper-proof security boundary.

`__set_name__` runs at class creation, not when assigning a descriptor to an
already-created class. Do not reuse one stateful descriptor instance under several
names, since it would overwrite its stored name. This recipe expects an instance
`__dict__` and initialized fields; a slotted object or uninitialized access needs
a different storage/missing-value policy. Its dynamic descriptor types would need
proper `__get__` overloads for a strict static API; runtime doctests do not prove
such typing precision. Do not add descriptor machinery where a property suffices.

`cached_property` is non-data: it stores a result in the instance dictionary, and
ordinary writes can replace it. A slots-only dataclass lacks that dictionary by
default. `slots=True` is a layout choice, not immutability, flyweight sharing, or a
universal speed guarantee; subclasses may regain a dictionary if not also slotted.

## Hooks before metaclasses

A class decorator suffices for an explicit transformation. `__init_subclass__`
handles many subclass registration/validation hooks; call `super()` cooperatively
and consume only your own keywords. Specify duplicate registrations rather than
silently overwriting them. Choose a metaclass only when class-creation semantics
really need one; it can conflict with ABC/framework metaclasses.

Metaclass `__new__` participates in creating the class object. Normal instance
construction is handled by the metaclass's `__call__`, typically invoking the
class's `__new__` and then `__init__`. Do not confuse these phases or attempt
per-instance validation only in a class-definition hook. ABC abstractness blocks
instance construction, not class definition or signature-incompatible overrides.

First-party references: [descriptor guide](https://docs.python.org/3.14/howto/descriptor.html),
[dataclasses](https://docs.python.org/3.14/library/dataclasses.html), and
[Python data model](https://docs.python.org/3.14/reference/datamodel.html).
