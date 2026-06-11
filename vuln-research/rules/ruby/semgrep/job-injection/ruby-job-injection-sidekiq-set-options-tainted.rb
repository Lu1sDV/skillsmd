# Fixture for Sidekiq set-options queue routing from request input.
# Flagged lines route via a params queue; safe line names a fixed queue.

class SidekiqRouteController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-sidekiq-set-options-tainted
    EmailWorker.set(queue: params[:queue]).perform_async(current_user.id)

    # ruleid: ruby-job-injection-sidekiq-set-options-tainted
    EmailWorker.set(queue: params[:queue], retry: 3).perform_async(current_user.id)
  end

  def enqueue_safe
    # ok: ruby-job-injection-sidekiq-set-options-tainted
    EmailWorker.set(queue: :mailers).perform_async(current_user.id)
  end
end
