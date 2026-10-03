> **Status:** experimental. The flag only takes effect when `--experimental` is
> also passed. It is off by default.

## What it does

When Opengrep follows tainted data across function calls (intra-file
inter-procedural taint), a sink is sometimes only reached when a condition
holds — for example, an argument has a particular value or length.

`--guarded-taint-signatures` makes the analysis **pay attention to those
conditions**. If Opengrep can prove that the condition guarding a sink is
impossible for a given call, it drops the would-be finding. If the condition
holds, or can't be decided, the finding is reported as usual.

In short: **fewer false positives on code where the dangerous path is gated by a
check on the arguments**, without missing real findings — a finding is only
suppressed when Opengrep can *prove* the guard can never be true at that call.

## Example

```python
def consumer(opts, x):
    if len(opts["data"]) == 2:
        sink(x)

consumer({"data": [1]},    source())   # no finding — len(...) == 2 can't hold here
consumer({"data": [1, 2]}, source())   # finding    — len(...) == 2 holds
```

Without the flag, both calls report a finding, because the analysis ignores the
`if` and assumes any call to `consumer` can reach `sink`. With the flag,
Opengrep carries the guarding condition `len(opts["data"]) == 2` along with the
flow and checks it against each call's actual arguments.

## Which conditions it understands

The guard has to be a check on a parameter (or on a local that was assigned one
of the arguments). Recognised forms include:

- **truthiness** — `if flag:`
- **equality to a constant** — `if code == 0:`
- **length** — `len(path) == 3`
- **a nested field** — `if opts.config.enabled:`

Guards are tracked through **returns, l-value writes, forwarding chains, and
higher-order callbacks**, so the condition still applies even if the value is
passed through several functions before reaching the sink.

Opengrep can also spot contradictory combinations and suppress the finding even
when it doesn't know the underlying value — e.g. a path that would require both
`a == 1` and `a == 2`, or both `len(v) == 1` and `len(v) == 2`.

## How to enable it

### On the command line

```
opengrep --experimental --guarded-taint-signatures --config <rules> <target>
```

The flag **requires `--experimental`**, and is normally used alongside
`--taint-intrafile`.

### Per rule

You can also switch it on for a single rule via the `guarded_taint_signatures`
option, instead of globally:

```yaml
rules:
  - id: my-taint-rule
    mode: taint
    options:
      guarded_taint_signatures: true
    # pattern-sources / pattern-sinks ...
```

## Notes

- **Off by default, and free when off.** With the flag off, no guard tracking
  happens at all. (The one built-in exception is Clojure, which always uses
  arity conditions internally to tell multi-arity function definitions apart —
  this is not something you configure.)
- **Performance.** Guard tracking is designed to stay cheap even on long call
  chains. Sometimes the flag makes the analysis a bit faster (as the engine is
  able to discover, for example, that a given call will not produce taint and
  so it doesn't need to track it), but often it is slightly slower than the
  default algorithm. This is why it is an opt-in functionality.
- **Inspecting guards.** `opengrep show dump-taint-signatures ...` prints the
  full conditions attached to a function's taint signature, which is useful when
  you want to understand why a particular finding was or wasn't reported.
