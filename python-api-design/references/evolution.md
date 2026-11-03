# Evolve the public surface deliberately

- [Find the actual surface](#find-the-actual-surface)
- [Classify the change](#classify-the-change-from-the-consumers-direction)
- [Migrate defaults and removals](#migrate-defaults-and-removals)
- [Review HTTP and generated schemas](#review-http-and-generated-schemas)
- [Evidence for completion](#evidence-for-completion)

## Find the actual surface

Read the documented imports, signatures, examples, re-exports, entry points,
subclass hooks and known consumers before editing. Public behavior includes
accepted inputs, output shape, ordering, error types, side effects, mutation and
resource ownership. For HTTP, include status codes, pagination, authentication,
authorization and generated-client behavior.

Use explicit re-exports and `__all__` to express intent. `__all__` controls star
imports and contributes to static export rules; it does not prevent direct imports
or erase promises made in documentation. An underscore is a privacy convention,
not access control. Usage searches and telemetry can reveal consumers, but absent
observations do not prove that external consumers do not exist.

Follow registration calls, included routers, mounted applications and feature
flags. A file containing the registration hub is not necessarily the complete
surface. Compare generated routes/OpenAPI under the relevant configuration with
the public documentation; state when only static inspection was possible.

## Classify the change from the consumer's direction

Avoid a context-free list of "safe additions". Check both existing callers and
implementations of an extension contract, including subclasses and callbacks.

| Change | Compatibility question |
|---|---|
| Add a defaulted keyword-only parameter | Do omitted calls retain behavior? Could wrappers, `**kwargs` forwarding or overrides collide with the new name? |
| Rename a parameter or make it keyword-only | Can callers supply its old keyword or position? Supporting both forms may require a transition. |
| Widen accepted inputs | Does the old subset behave identically? Can every promised implementation still accept the widened domain? |
| Narrow input types/ranges or make a field required | Which previously accepted calls or payloads now fail? |
| Add/change an output field, enum member or union variant | Do strict decoders, exhaustive matches, generated clients or serializers reject the new result? |
| Append a `NamedTuple` field | Fixed-length unpacking and tuple equality change even if constructor defaults preserve some calls. Treat as potentially breaking. |
| Add a dataclass field | Inspect constructor order/defaults, equality/hash, `__match_args__`, serialization and subclass initialization. |
| Change a default, ordering, exception or status code | Does unchanged client code now take a different path? A preserved signature is insufficient. |
| Remove or redirect an export/endpoint | Do documented imports and old deployed clients still work throughout rollout? |

For substitutability, a replacement normally accepts at least the old input
domain and maintains the old output guarantees. Required/optional changes have
different effects on requests and responses: making a request field required
restricts senders; allowing a previously guaranteed response field to disappear
weakens the promise to readers. Check nullability separately from omission.

An empty selection can be a valid result, but it must not be reported as evidence
that checks ran. A partial page sequence must not silently claim completeness.
Name the result's completeness or fail according to the contract; preserve caller
state if validation fails. These are observable API choices, not logging fixes.

## Migrate defaults and removals

Choose the release/deprecation policy the project actually promises; do not impose
semantic versioning on every project. Keep the old behavior during a documented
overlap window, name the replacement and removal condition, then update consumers.
Do not turn a temporary flag into permanent global mutable policy. Give migration
flags an owner and retirement condition; some options remain useful configuration.

Distinguish omission from an explicit old or new value when a default changes.
A sentinel enables that distinction; it does not make an immediate default flip
compatible. This Python **3.15+ example** retains input order for omitted `sort`
while announcing a later change:

```pycon
>>> import warnings
>>> from collections.abc import Sequence
>>> _UNSET = sentinel("_UNSET")
>>> def ordered_names(
...     names: Sequence[str], *, sort: bool | _UNSET = _UNSET
... ) -> tuple[str, ...]:
...     if sort is _UNSET:
...         warnings.warn(
...             "The default sort order will change in the next breaking release; "
...             "pass sort=False or sort=True explicitly.",
...             DeprecationWarning,
...             stacklevel=2,
...         )
...         sort = False
...     return tuple(sorted(names)) if sort else tuple(names)
>>> with warnings.catch_warnings(record=True) as observed:
...     warnings.simplefilter("always")
...     assert ordered_names(("z", "a")) == ("z", "a")
...     assert ordered_names(("z", "a"), sort=False) == ("z", "a")
...     assert ordered_names(("z", "a"), sort=True) == ("a", "z")
>>> assert len(observed) == 1
>>> assert observed[0].category is DeprecationWarning

```

Use `is` for sentinel comparisons; sentinels are truthy. On an older supported
Python, retain the project's private sentinel representation instead of raising
the runtime floor just for this recipe. A plain `object()` marker does not provide
the same singleton typing, copy or pickle behavior as the 3.15 builtin.

Use a warning location that reaches the consumer. `stacklevel=2` suits a direct
wrapper; deeper call stacks may need a different value or `skip_file_prefixes`
(3.12+). `warnings.deprecated` (3.13+) can also mark whole functions/classes for
runtime and supporting static checkers. `DeprecationWarning` is normally hidden
outside `__main__`; test with an explicit warnings filter and publish migration
instructions instead of relying on users seeing it.

## Review HTTP and generated schemas

Review three contracts separately: what the server accepts, what it emits, and
what OpenAPI/generated clients advertise. Confirm the actual framework versions,
schema mode and serializer configuration. A source-only model diff is insufficient.

For Pydantic v2 and FastAPI:

- `T | None` permits null; a default permits omission at input. They are different
  promises. FastAPI's separate input/output schemas can mark a defaulted output
  field required because serialization supplies it. This feature is supported
  from FastAPI 0.102.0; inspect actual output with exclusion/customization options.
- `SkipJsonSchema` hides all or part of a schema; it does not disable validation,
  remove a runtime field or provide authorization. It can preserve server-side
  acceptance while breaking regenerated clients that lose that field. Prefer
  explicit deprecation and versioned compatibility; use hiding only with a
  deliberate client migration and tests of both wire behavior and generated types.
- Match numeric bounds to the domain and storage contract. A signed 32-bit SQL
  column may need corresponding input limits; neither all SQL integers nor all
  public integers should be forced into an application-specific `Int32` alias.
- Preserve public schema names, aliases, discriminator values and operation IDs
  when generated clients depend on them. A particular union-naming convention is
  a project choice, not a framework requirement.
- Several errors may share an HTTP status. Model their documented body variants
  or stable error codes under that response; do not invent different HTTP statuses
  solely to avoid a schema collision.
- Changing implicit list filters or sort order changes behavior. Document default
  filtering and stable pagination order, including tie-breakers. Do not assume
  every list must expose every accessible resource or that offset/cursor changes
  are harmless. Treat continuation tokens as untrusted boundary input.

Keep domain errors independent of HTTP and translate them at the adapter. Use
the application's error format; introducing a second universal envelope creates
another compatibility obligation. Database deployment migrations belong with
system/transaction design, not in a catalogue of API schema tricks.

## Evidence for completion

Test through the import path or endpoint that users actually call. If an export
is promised to be a direct alias, assert identity with its canonical object;
otherwise check the wrapper's behavior rather than imposing identity.

Exercise an old caller and a new caller, omitted/explicit/null values where
applicable, warning category/location, failure-state preservation, and a malformed
boundary value. For HTTP, compare emitted payloads and schemas and exercise a
representative generated consumer when that is part of the supported surface.
Use independent expected results; a test that repeats the implementation's formula
does not establish the contract. Report concrete breakage and affected consumers,
separate policy questions from defects, and record unexecuted checks.

Primary references: [Python imports](https://docs.python.org/3.15/reference/simple_stmts.html#the-import-statement),
[typed-library exports](https://typing.python.org/en/latest/spec/distributing.html#library-interface-public-and-private-symbols),
[warnings](https://docs.python.org/3.15/library/warnings.html),
[sentinel](https://docs.python.org/3.15/builtins/functions.html#sentinel),
[FastAPI input/output schemas](https://fastapi.tiangolo.com/how-to/separate-openapi-schemas/),
[Pydantic schema omission](https://docs.pydantic.dev/latest/api/json_schema/#pydantic.json_schema.SkipJsonSchema),
and [OpenAPI response objects](https://spec.openapis.org/oas/v3.1.1.html#responses-object).
