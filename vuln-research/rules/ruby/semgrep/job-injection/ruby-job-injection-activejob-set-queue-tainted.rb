# Fixture for user-controlled ActiveJob queue routing.
# Flagged lines route to a params-supplied queue; safe line picks the queue server-side.

class RoutingController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-activejob-set-queue-tainted
    ExportJob.set(queue: params[:queue]).perform_later(record_id)

    # ruleid: ruby-job-injection-activejob-set-queue-tainted
    ExportJob.set(queue: params[:queue], wait: 1.minute).perform_later(record_id)
  end

  def enqueue_safe
    # ok: ruby-job-injection-activejob-set-queue-tainted
    ExportJob.set(queue: :exports).perform_later(record_id)
  end
end
