# Fixture for raw params enqueued as Resque arguments.
# Flagged lines pass request params as job args; safe line passes a scalar id.

class ResqueArgsController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-resque-args-raw-params
    Resque.enqueue(ImportJob, params)

    # ruleid: ruby-job-injection-resque-args-raw-params
    Resque.enqueue(ImportJob, params.to_h, current_user.id)
  end

  def enqueue_safe
    # ok: ruby-job-injection-resque-args-raw-params
    Resque.enqueue(ImportJob, current_user.id)
  end
end
