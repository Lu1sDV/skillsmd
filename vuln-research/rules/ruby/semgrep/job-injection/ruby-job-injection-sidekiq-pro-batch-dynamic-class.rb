# Fixture for dynamic worker dispatch inside a Sidekiq batch.
# Flagged lines constantize a params class then enqueue; safe line uses a fixed worker.

class BatchController < ApplicationController
  def enqueue
    batch = Sidekiq::Batch.new
    batch.jobs do
      # ruleid: ruby-job-injection-sidekiq-pro-batch-dynamic-class
      params[:worker].constantize.perform_async(current_user.id)

      # ruleid: ruby-job-injection-sidekiq-pro-batch-dynamic-class
      params[:worker].safe_constantize.perform_async(current_user.id)
    end
  end

  def enqueue_safe
    batch = Sidekiq::Batch.new
    batch.jobs do
      # ok: ruby-job-injection-sidekiq-pro-batch-dynamic-class
      ExportWorker.perform_async(current_user.id)
    end
  end
end
