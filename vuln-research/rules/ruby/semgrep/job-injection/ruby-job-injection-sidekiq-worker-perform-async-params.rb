# Fixture for raw params enqueued as Sidekiq worker args.
# Flagged lines pass request params into perform_async; safe line passes a scalar id.

class ReportController < ApplicationController
  def create
    # ruleid: ruby-job-injection-sidekiq-worker-perform-async-params
    ReportWorker.perform_async(params)

    # ruleid: ruby-job-injection-sidekiq-worker-perform-async-params
    ReportWorker.perform_async(params.to_h, current_user.id)
  end

  def create_safe
    # ok: ruby-job-injection-sidekiq-worker-perform-async-params
    ReportWorker.perform_async(current_user.id)
  end
end
