# STATIC SCANNER INPUT: never execute this file.
# read_request_field() and shell_exec() are deliberately undefined educational
# boundary APIs: the first returns an untrusted HTTP field; the second executes
# its FIRST argument as a shell command. Its audit keyword is stored as data,
# never interpreted by a shell. These are contracts, not real library names.
# All factories, constructors, methods, helpers, and callbacks below have real
# bodies. In particular, load_command() is NOT a source merely by name, and
# neither normalize_command() nor the callback dispatcher is a sanitizer.
#
# Verified native OpenGrep 1.30.0 behavior for this fixture's exact code shapes:
#   scan -c intrafile.yaml intrafile.py                   -> no findings
#   scan -c intrafile.yaml intrafile.py --taint-intrafile -> two ruleid sites
# Without the flag, load_command() has no tainted arguments from which opaque
# call propagation could invent a tainted return. With it, same-file summaries
# must connect returns, constructor fields, collection access, methods,
# and callback parameters. This is intrafile, NOT imported/interfile analysis.


def load_command():
    # The rule scopes its source to this boundary adapter, and exactly to the
    # return value of this request read, not the string literal "command".
    value = read_request_field("command")
    return value


def normalize_command(value):
    # Whitespace normalization changes the bytes, not their trustworthiness.
    # The helper summary must preserve taint through this receiver-method call.
    return value.strip()


def allowlisted_command(value):
    # Genuine safety contract: user input selects one of two fixed commands.
    # Nothing supplied by the caller is interpolated into a shell string.
    # Rejection raises instead of returning the original dangerous value.
    action = value.strip()
    if action == "health":
        return "printf ready"
    if action == "uptime":
        return "uptime"
    raise ValueError("unsupported job action")


def checked_command(value):
    # This wrapper is NOT matched as a sanitizer by the rule. Intrafile analysis
    # must understand that its return passes through the actual allowlist API.
    return allowlisted_command(normalize_command(value))


class CommandJob:
    def __init__(self, command, audit):
        # Initialize the field with its tainted element in one expression.
        # Native 1.30.0 missed the equivalent split form self.pending=[] followed
        # by self.pending.append(command) in this constructor. That engine limit
        # is documented, not hidden by a custom propagator or a source-on-caller.
        self.pending = [command]
        # Field sensitivity matters: a tainted pending field does not justify
        # tainting audit or fallback, and a tainted audit is not a shell command.
        self.audit = audit
        self.fallback = "printf ready"

    def next_command(self):
        # pop() is the opposite boundary: ThisTaintsReturn retrieves taint from
        # the queue receiver. Then a separate helper preserves it on the return.
        # No manual propagator hides either the constructor or method body.
        return normalize_command(self.pending.pop())

    def fallback_command(self):
        # Same object, same normalization helper, different (clean) field.
        return normalize_command(self.fallback)

    def audit_text(self):
        return self.audit


def apply_command(command, audit, callback):
    # A real custom higher-order function, not an undefined opaque API: the
    # first actual argument becomes callback's first parameter; audit is second.
    # The caller supplies the callback itself, so the function signature must
    # retain that binding rather than treating callback as an unrelated name.
    return callback(command, audit)


def execute_unchecked(command, audit):
    # UNSAFE PATH B ends here. Its callsite supplies job.next_command(), reached
    # through load_command -> __init__ -> pending field -> next_command/pop ->
    # normalize_command -> apply_command -> this named callback's first arg.
    # ruleid: lab-python-intrafile-command
    shell_exec(command, audit=audit)


def execute_checked(command, audit):
    # SAFE HELPER/CALLBACK path: taint does reach this parameter, but the nested
    # checked_command -> allowlisted_command return is a fixed trusted command.
    # The original command is not sanitized in place; only the new return is.
    selected = checked_command(command)
    # ok: lab-python-intrafile-command
    shell_exec(selected, audit=audit)


def unsafe_map_entrypoint():
    # UNSAFE PATH A: factory return -> constructor queue field -> method/helper
    # return -> Python map's first callback parameter -> focused command sink.
    # list() forces Python's lazy map to run; the callback is not dead code.
    job = CommandJob(load_command(), "job-map")
    list(map(
        # strip() above did not remove taint, so this callback needs a finding.
        # ruleid: lab-python-intrafile-command
        lambda command: shell_exec(command, audit=job.audit_text()),
        [job.next_command()],
    ))


def unsafe_named_callback_entrypoint():
    # Same constructor/method state machinery; unlike PATH A, a named function
    # is passed as a value to a custom HOF, which invokes it in its own body.
    # The finding belongs at execute_unchecked's sink, not on this dispatch.
    job = CommandJob(load_command(), "job-named")
    apply_command(job.next_command(), job.audit_text(), execute_unchecked)


def safe_named_callback_entrypoint():
    # One meaningful change from the unsafe named path: the callback performs
    # allowlisting before executing. No source or dispatcher exclusion is used.
    job = CommandJob(load_command(), "job-checked")
    apply_command(job.next_command(), job.audit_text(), execute_checked)


def safe_map_callback_entrypoint():
    # The directly modelled sanitizer runs INSIDE the lambda after map binds its
    # element. 1.30.0 produced a false positive when this call was instead hidden
    # behind checked_command here; the named-callback path proves that wrapper's
    # safe return separately. Do not assume those analysis shapes are equivalent.
    job = CommandJob(load_command(), "job-safe-map")
    list(map(
        # ok: lab-python-intrafile-command
        lambda command: shell_exec(allowlisted_command(command), audit=job.audit_text()),
        [job.next_command()],
    ))


def safe_sibling_field_entrypoint():
    # One-condition negative for PATH A: job still contains an untrusted queue,
    # but the callback receives fallback_command() instead of next_command().
    # Do not repair a receiver/field false positive by excluding this function.
    job = CommandJob(load_command(), "job-fallback")
    list(map(
        # ok: lab-python-intrafile-command
        lambda command: shell_exec(command, audit=job.audit_text()),
        [job.fallback_command()],
    ))


def safe_audit_argument_entrypoint():
    # The source is present and travels through the constructor into audit,
    # while pending contains a fixed command. The dispatcher sends that source
    # to the callback's SECOND parameter. Focusing only the sink's first argument
    # is essential: matching the whole call would conflate audit with execution.
    job = CommandJob("printf ready", load_command())
    apply_command(
        job.next_command(),
        job.audit_text(),
        # ok: lab-python-intrafile-command
        lambda command, audit: shell_exec(command, audit=audit),
    )


# Deliberate analysis limits: only concrete same-file classes/functions are
# exercised, with no inheritance, reflective dispatch, imported callbacks, or
# mutually recursive call graph. Collection models are conservative: this
# one-element queue does NOT prove per-index or per-element precision for a
# mixture of clean and dirty commands. Likewise, a clean fallback field must
# remain separate from a dirty pending field; these ok sites check that contract.
# Annotations encode the intended result and require a native-version scan;
# they do not claim that every supported language or future version agrees.
