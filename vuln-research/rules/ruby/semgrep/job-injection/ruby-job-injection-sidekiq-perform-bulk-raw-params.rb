# Fixture for perform_bulk fed from raw request input.
# Flagged lines build the batch from params; safe line maps validated ids.

class BulkArgsController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-sidekiq-perform-bulk-raw-params
    NotifyWorker.perform_bulk(params[:batches])

    # ruleid: ruby-job-injection-sidekiq-perform-bulk-raw-params
    NotifyWorker.perform_bulk(params.to_h.values)
  end

  def enqueue_safe
    # ok: ruby-job-injection-sidekiq-perform-bulk-raw-params
    NotifyWorker.perform_bulk(current_user.team.member_ids.map { |id| [id] })
  end
end
