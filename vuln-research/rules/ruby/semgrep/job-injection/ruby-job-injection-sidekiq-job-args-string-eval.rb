# Fixture for a worker that evaluates a stored job argument as code.
# The flagged perform evals its argument; the safe one branches on a fixed operation.

class FormulaWorker
  include Sidekiq::Job

  # ruleid: ruby-job-injection-sidekiq-job-args-string-eval
  def perform(expr, record_id)
    result = eval(expr)
    Record.find(record_id).update!(value: result)
  end
end

class SafeFormulaWorker
  include Sidekiq::Job

  # ok: ruby-job-injection-sidekiq-job-args-string-eval
  def perform(op, record_id)
    result = OPERATIONS.fetch(op).call
    Record.find(record_id).update!(value: result)
  end
end
