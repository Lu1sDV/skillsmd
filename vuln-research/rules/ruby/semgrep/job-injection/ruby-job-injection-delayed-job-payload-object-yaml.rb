# Fixture for loading a Delayed::Job handler column with an unsafe YAML parser.
# Flagged lines materialize the handler unsafely; safe line restricts permitted classes.

class HandlerInspector
  def reconstruct(job)
    # ruleid: ruby-job-injection-delayed-job-payload-object-yaml
    YAML.load(job.handler)
  end

  def reconstruct_unsafe(job)
    # ruleid: ruby-job-injection-delayed-job-payload-object-yaml
    Psych.load(job.handler)
  end

  def reconstruct_safe(job)
    # ok: ruby-job-injection-delayed-job-payload-object-yaml
    YAML.safe_load(job.handler, permitted_classes: [Time, Symbol])
  end
end
