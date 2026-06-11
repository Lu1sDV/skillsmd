# Fixture for dynamic Sidekiq bulk class dispatch.
# Flagged lines derive the worker class from params; safe line uses a fixed worker.

class BulkController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-sidekiq-push-bulk-dynamic-class
    Sidekiq::Client.push_bulk(class: params[:worker], args: [[1], [2], [3]])

    # ruleid: ruby-job-injection-sidekiq-push-bulk-dynamic-class
    Sidekiq::Client.push_bulk("class" => params[:worker], "args" => [[1], [2]])
  end

  def enqueue_safe
    # ok: ruby-job-injection-sidekiq-push-bulk-dynamic-class
    Sidekiq::Client.push_bulk(class: ThumbnailWorker, args: [[1], [2], [3]])
  end
end
