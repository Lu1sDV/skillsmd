# Fixture for selecting a worker via method dispatch on request input.
# Flagged lines send a params method name to pick the worker; safe line uses a lookup table.

class DispatchController < ApplicationController
  WORKERS = { "resize" => ResizeWorker, "scan" => ScanWorker }.freeze

  def enqueue
    # ruleid: ruby-job-injection-sidekiq-job-class-send
    registry.public_send(params[:kind]).perform_async(current_user.id)

    # ruleid: ruby-job-injection-sidekiq-job-class-send
    Object.const_get(params[:worker]).perform_async(current_user.id)
  end

  def enqueue_safe
    # ok: ruby-job-injection-sidekiq-job-class-send
    WORKERS.fetch(params[:kind]).perform_async(current_user.id)
  end
end
