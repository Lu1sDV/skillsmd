# Fixture for raw params enqueued as Que arguments.
# Flagged lines pass request params as job args; safe line passes a scalar id.

class QueArgsController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-que-job-args-raw-params
    Que.enqueue(ChargeJob, params)

    # ruleid: ruby-job-injection-que-job-args-raw-params
    ChargeJob.enqueue(params)
  end

  def enqueue_safe
    # ok: ruby-job-injection-que-job-args-raw-params
    Que.enqueue(ChargeJob, current_user.id)
  end
end
