# Behavioral decisions: operations, events, and state

## Selection table

| Pattern | Start with | Use when | Contract to settle |
|---|---|---|---|
| Strategy | Function/closure; enum for closed choices | One algorithm or policy varies | Inputs, outputs, stateful invocation, error semantics |
| Observer | Borrowed callbacks; channels for decoupling | One event reaches multiple consumers | Ordering, subscription lifetime, lag, failures, reentrancy |
| State | Enum holding state-specific data | Runtime-selected states and transitions | Allowed transitions and state on failure |
| Command | Owned enum or closure | Queue, replay, undo, or audit an operation | Consumption, identity, validation, repeatability |
| Iterator | Standard adapters, then a named `Iterator` | Expose traversal without representation | Progress, termination, borrowing, truthful size bounds |
| Chain of responsibility | Ordered functions plus `Result<Option<T>, E>` | Stop at first handler or first failure | Distinguish not-handled, handled, and failed |
| Visitor | Match/fold, then traversal plus visitor | Many operations over a stable structure | Traversal order, early stop, mutable access |
| Typestate | State-bearing structs/consuming transitions | Restrict operations based on prior validated work | Recovery of owned state on failed transitions |
| RAII | Owning value/guard, `Drop` fallback | Scope-bound resource ownership | Explicit fallible finish; abort/leak limitations |
| Newtype | Private wrapper with meaningful operations | Distinct IDs, units, validated values | Conversion and mutation must preserve invariants |

## Strategy and chain: closures already are policy objects

Use `FnOnce` when the operation is consumed once, `FnMut` when invocation may
change captured state, and `Fn` when repeated calls through a shared reference are
required. A `move` closure is not necessarily `FnOnce`-only: capture mode and what
its body does are different questions. Avoid boxing a closure unless storage or
erasure actually requires it.

For a handler chain, `None` means “try the next handler,” not “this handler failed.”
This command parser uses two real parsers. Once `get` matches, a missing key is an
error; it must not fall through to some permissive fallback.

```rust
#[derive(Debug, PartialEq, Eq)]
enum Command<'a> { Help, Get(&'a str) }

fn help(input: &str) -> Result<Option<Command<'_>>, &'static str> {
    Ok((input == "help").then_some(Command::Help))
}
fn get(input: &str) -> Result<Option<Command<'_>>, &'static str> {
    if input == "get" { return Err("missing key"); }
    match input.strip_prefix("get ") {
        Some("") => Err("missing key"),
        Some(key) => Ok(Some(Command::Get(key))),
        None => Ok(None),
    }
}
fn parse(input: &str) -> Result<Command<'_>, &'static str> {
    if let Some(command) = help(input)? { return Ok(command); }
    get(input)?.ok_or("unknown command")
}

assert_eq!(parse("help"), Ok(Command::Help));
assert_eq!(parse("get rust"), Ok(Command::Get("rust")));
assert_eq!(parse("get "), Err("missing key"));
assert_eq!(parse("delete rust"), Err("unknown command"));
```

This grammar deliberately takes the remainder after `get ` as a key; whitespace
normalization is a separate contract, not an unrequested parser feature. A fixed
two-stage chain needs neither linked handler nodes nor a DI framework.

## Observer: delivery semantics are part of the interface

For synchronous observers, a borrowed callback list can avoid `'static` captures.
Use `FnMut(&Event)` when callbacks mutate local state. Decide registration order,
whether one error stops subsequent observers, and whether callbacks may subscribe,
unsubscribe, or recursively emit during dispatch. Do not call arbitrary callbacks
while holding an internal mutex or a `RefCell` mutable borrow; reentrancy can
otherwise deadlock or panic.

For retained subscriptions, return an unsubscribe handle/token and specify when
it stops delivery. Strong references from publisher to observer and observer back
to publisher create cycles; use an owner, weak links, or explicit teardown.

A channel is not automatically broadcast: cloned receivers on a work queue can
compete for messages rather than each receiving a copy. For asynchronous fan-out,
choose an actual broadcast primitive and specify bounded capacity, lag recovery,
closed-channel behavior, and shutdown. A loop that stops on *any* receive error
can confuse lag with closure. Do not silently drop send errors or claim delivery
once an event was merely enqueued. Use rust-concurrency if installed for concrete
runtime-specific implementation.

## Runtime state: failure must leave a usable value

Use enums when input or persistence determines state at runtime. Keep the data
that belongs to a state in that variant, not in a bag of unrelated `Option`s.
Transitions can consume a value to move its data without cloning. If failure
should permit correction/retry, return the original owner in the error.

Here a draft is actually validated before becoming a published document. The
representation stores data directly instead of `PhantomData` plus unchecked
optional fields. It is typestate via distinct concrete types.

```rust
mod publication {
    #[derive(Debug)]
    pub struct Draft(String);
    #[derive(Debug)]
    pub struct Published(String);

    impl Draft {
        pub fn new(text: String) -> Self { Self(text) }
        pub fn replace(&mut self, text: String) { self.0 = text; }
        pub fn publish(self) -> Result<Published, (Self, &'static str)> {
            if self.0.trim().is_empty() { return Err((self, "empty draft")); }
            Ok(Published(self.0))
        }
    }
    impl Published {
        pub fn text(&self) -> &str { &self.0 }
    }
}

use publication::Draft;
let (mut draft, reason) = Draft::new(String::from(" \n"))
    .publish().expect_err("blank draft rejected");
assert_eq!(reason, "empty draft");
draft.replace(String::from("publishable"));
let published = draft.publish().expect("nonblank draft");
assert_eq!(published.text(), "publishable");
```

The negative check below is intentionally invalid: a draft cannot use the
published-only `text` operation. It is self-contained; the successful example
above separately checks the real transition and runtime validation.

```rust,compile_fail
mod publication {
    pub struct Draft(String);
    pub struct Published(String);
    impl Draft {
        pub fn new(text: String) -> Self { Self(text) }
        pub fn publish(self) -> Result<Published, Self> {
            if self.0.trim().is_empty() { Err(self) } else { Ok(Published(self.0)) }
        }
    }
    impl Published {
        pub fn text(&self) -> &str { &self.0 }
    }
}
let draft = publication::Draft::new(String::from("unpublished"));
let visible = draft.text(); // no such operation for Draft
```

Typestate does not prevent a network disconnection, prove authorization, or stop
external mutation of a resource. It proves only the state relationships your
constructors/transitions actually enforce. For dynamic states stored in one
collection, an enum is often clearer than erased typestate objects. For `&mut self`
transitions, validate before mutation or deliberately document a temporary/recovery
state; `mem::replace` is not rollback if subsequent code panics.

## Commands: represent operations, not shared mutable owner graphs

Pass `&mut Model` to a command executor rather than putting the same
`Rc<RefCell<Model>>` in every command. Use an enum for a closed vocabulary and
`Box<dyn FnOnce(&mut Model)>` for owned one-shot actions that need no serialization.
Closures are usually a poor durable log format; versioned data commands are easier
to validate and replay.

An undo record must capture enough state and validate that its preconditions still
hold. On execution error, do not add a history entry; after undo then a new edit,
discard the obsolete redo branch. Byte positions in Rust strings require UTF-8
boundary checks. This complete command owns only its inverse data and consumes it
on undo; a failed execution returns before modifying the string.

```rust
#[derive(Debug)]
struct UndoInsert { start: usize, end: usize }

fn insert(text: &mut String, at: usize, added: &str) -> Result<UndoInsert, &'static str> {
    if !text.is_char_boundary(at) { return Err("invalid byte boundary"); }
    let end = at.checked_add(added.len()).ok_or("position overflow")?;
    text.insert_str(at, added);
    Ok(UndoInsert { start: at, end })
}

impl UndoInsert {
    // Contract: no intervening mutation; caller applies undo in reverse order.
    fn undo(self, text: &mut String) {
        text.drain(self.start..self.end);
    }
}

let mut text = String::from("é!");
assert!(insert(&mut text, 1, "x").is_err());
assert_eq!(text, "é!");
let undo = insert(&mut text, 2, "lan").expect("character boundary");
assert_eq!(text, "élan!");
undo.undo(&mut text);
assert_eq!(text, "é!");
```

This is a single linear undo operation with an explicit caller precondition, not
an arbitrary concurrent editor. If history can outlive or race unrelated edits,
store/check a model revision or use the application's existing edit log instead
of trusting stale offsets. “Undo” of an external payment is a compensating domain
operation, not automatic reversal of side effects.

## Iterator and visitor: separate progression from operation

For ordinary traversal, return a standard iterator or compose adapters first.
Implement a custom iterator only when it needs real traversal state. An in-order
tree iterator can hold `current: Option<&Node>` and a stack: push a left spine,
pop and yield one node, then set `current` to that node's right child. Every call
must make progress; repeatedly examining `stack.last()` without moving/popping
never terminates. Test an empty tree, one node, both subtrees, and exhaustion.

The [Iterator contract](https://doc.rust-lang.org/std/iter/trait.Iterator.html#tymethod.next)
allows returning `Some` again after `None`; use `fuse` or implement `FusedIterator`
only when permanent exhaustion is guaranteed. Truthful `size_hint` bounds matter;
implement `ExactSizeIterator` only with an exact remaining count. Reject a zero
chunk size instead of silently returning no data. General iterator mechanics
belong to rust-idiomatic; algorithmic traversal belongs to rust-algorithms.

For a closed AST, start with an exhaustive `match` or fold. A visitor becomes useful
when many operations share one traversal. Keep walking separate from per-node
callbacks and prefer `&mut Visitor` for accumulation over `Cell` merely because an
OO example used `&self`. Define pre/post-order, whether a visitor may skip children,
and whether `ControlFlow::Break` or a `Result` stops traversal. Adding a node kind
changes the visitor interface; adding an operation adds a visitor. Pick that
tradeoff intentionally rather than assuming visitors make every extension easy.

## RAII and newtypes: protect real invariants

Use ownership and guards for ordinary scope-bound cleanup, including early return
and panic unwinding. Destruction is not guaranteed on process exit/abort, explicit
leaks, or strong reference cycles. A destructor cannot return `Result`; provide
`finish`, `flush`, `commit`, or `close` when success must be observed, then use
nonpanicking cleanup as fallback. Do not commit a transaction implicitly in `Drop`,
or claim database rollback succeeded after ignoring its error. See the
[Rust destructor rules](https://doc.rust-lang.org/reference/destructors.html#not-running-destructors).

Newtypes distinguish `UserId` from `OrderId` or bytes from item counts with no need
for an inheritance hierarchy. A private constructor can establish a numeric range,
but `DerefMut` or public fields can break it again. Do not present “contains @” as
email validation or dummy credential checking as authentication. Use the real
domain/parser library where correctness requires it.

## Sources

Adapted from StructWeave [11 behavioral patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/11-design-patterns-behavioral.md)
and [12 anti-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/12-anti-patterns-best-practices.md).
First-party Iterator and destructor references above qualify the upstream
termination, broadcast, and unconditional-cleanup claims.
