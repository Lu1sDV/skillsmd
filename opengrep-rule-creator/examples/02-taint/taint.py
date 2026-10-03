# STATIC SCANNER INPUT: never execute this file; the APIs below are undefined models.
# One detection, not a survey of separate rules:
# persisted client job -> JOB -> render_shell_command -> JOB + SHELL
# -> batch.add(command) mutates receiver -> batch.pop() -> run_shell(command).
#
# Educational API contracts (not claims about a real Python library):
# - load_untrusted_job(key, ...) returns a deserialized, client-controlled job.
# - read_untrusted_job_into(job) overwrites a mutable job object from that store.
# - render_shell_command(job) interpolates the job into a mutable CommandBuffer
#   without shell escaping; it preserves input taint and adds the SHELL stage.
# - set.add/pop model worker staging; run_shell executes ONLY its first argument.
#   audit= is logged as data, never interpreted as code or as a command.
# - allowlisted_command(command) returns a NEW buffer reconstructed from fixed
#   allowed commands; it neither mutates command nor merely quotes attacker text.
# - assert_allowlisted_command(command) checks the ENTIRE buffer against that same
#   fixed allowlist, raises on failure, and returns normally only for safe buffers.
#   It is not a boolean predicate, substring check, or shell-quoting function.
#
# All annotations concern THIS second-order pipeline. In particular, a raw JOB
# sent directly to a shell is OUTSIDE THIS RULE'S TARGET, not safe in general.
# Distinct functions keep intraprocedural taint states independent. There are no
# runnable helpers or scanner mocks; comments explain the expected scanner paths.


def persisted_job_through_worker_batch():
    job = load_untrusted_job("pending/client-42")  # JOB only: source return.
    command = render_shell_command(job)  # JOB flows through; requires JOB adds SHELL.
    pending = set()
    pending.add(command)  # Propagator copies BOTH labels onto this l-value receiver.
    # pop() obtains taint from the receiver under ordinary opaque-call propagation.
    # The staging mutation, not the return of add(), connects producer to consumer.
    # ruleid: lab-python-shell-taint
    run_shell(pending.pop(), audit="worker-7")


def a_missing_stage_is_not_the_target():
    clean_job = {"operation": "status"}
    clean_command = render_shell_command(clean_job)  # No JOB, so no extra SHELL label.
    # ok: lab-python-shell-taint
    run_shell(clean_command)
    job = load_untrusted_job("pending/client-42")
    # Only JOB reaches this sink: no dependent rendering transition occurred.
    # Deliberate coverage boundary, NOT a statement that executing raw input is safe.
    # ok: lab-python-shell-taint
    run_shell(job)


def side_effect_source_changes_a_later_render():
    job = MutableJob({"operation": "status"})
    pending = set()
    pending.add(render_shell_command(job))  # Neither JOB nor SHELL yet.
    # ok: lab-python-shell-taint
    run_shell(pending.pop())
    read_untrusted_job_into(job)  # Focused source mutates JOB taint on later reads.
    pending.add(render_shell_command(job))  # The SAME renderer now gains SHELL.
    # ruleid: lab-python-shell-taint
    run_shell(pending.pop())


def using_the_return_sanitizer_changes_the_batch_input():
    command = render_shell_command(load_untrusted_job("pending/client-42"))
    safe_command = allowlisted_command(command)  # A new clean buffer, not an assertion.
    pending = set()
    pending.add(safe_command)  # No labels copied: the unsafe original stays separate.
    # ok: lab-python-shell-taint
    run_shell(pending.pop(), audit=command)
    # The same original still has JOB + SHELL. Sanitizing a copy didn't change it.
    # ruleid: lab-python-shell-taint
    run_shell(command)


def discarding_the_return_does_not_sanitize_the_original():
    command = render_shell_command(load_untrusted_job("pending/client-42"))
    allowlisted_command(command)  # Return discarded; caller-local command stays tainted.
    pending = set()
    pending.add(command)  # Both labels survive through the mutating propagator.
    # ruleid: lab-python-shell-taint
    run_shell(pending.pop())


def an_in_place_check_cleans_later_reads_but_not_future_writes():
    command = render_shell_command(load_untrusted_job("pending/client-42"))
    # ruleid: lab-python-shell-taint
    run_shell(command)  # An earlier execution cannot be undone by a later check.
    assert_allowlisted_command(command)  # Normal return establishes the buffer is safe.
    pending = set()
    pending.add(command)  # Focus + by-side-effect removed labels from later reads.
    # ok: lab-python-shell-taint
    run_shell(pending.pop())
    command = render_shell_command(load_untrusted_job("pending/client-99"))
    pending.add(command)  # New untrusted content reintroduces BOTH labels to the batch.
    # ruleid: lab-python-shell-taint
    run_shell(pending.pop())


def audit_data_is_not_the_focused_execution_argument():
    audit_data = render_shell_command(load_untrusted_job("pending/client-42"))
    # Both labels exist, but ONLY on audit=. Focusing $COMMAND avoids a false alarm.
    # ok: lab-python-shell-taint
    run_shell("status", audit=audit_data)
    # Moving the identical value into the dangerous argument changes the outcome.
    # ruleid: lab-python-shell-taint
    run_shell(audit_data, audit="worker-7")


def nested_sanitization_happens_before_or_after_execution():
    # Inner load -> render -> sanitizer return -> shell: the sink receives clean data.
    # ok: lab-python-shell-taint
    run_shell(allowlisted_command(render_shell_command(load_untrusted_job("pending/42"))))
    # Here load -> render -> shell happens FIRST. The outer sanitizer cannot undo it.
    # exact:true sanitization applies only to its own result, not descendant sinks.
    # ruleid: lab-python-shell-taint
    allowlisted_command(run_shell(render_shell_command(load_untrusted_job("pending/42"))))


def exact_sources_do_not_backdate_label_transitions():
    # The outer loader only taints its own result, AFTER its argument is evaluated.
    # Its enclosing source match does not make a nested clean renderer/sink untrusted.
    # ok: lab-python-shell-taint
    load_untrusted_job(run_shell(render_shell_command({"operation": "status"})))
    job = load_untrusted_job("pending/client-42")
    # The dependent SHELL source is also exact: it labels its result, not nested
    # arguments. This inner shell receives JOB only, before the transition exists.
    # As above, this raw execution bypass is outside the target, not a safe idiom.
    # ok: lab-python-shell-taint
    render_shell_command(run_shell(job))
    # Changing the nesting puts the dependent transition BEFORE the shell executes.
    # ruleid: lab-python-shell-taint
    run_shell(render_shell_command(job))
