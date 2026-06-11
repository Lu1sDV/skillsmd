# Fixture for Sidekiq client push with a request-controlled queue.
# Flagged lines route to a params queue; safe line names a fixed queue.

class ClientQueueController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-sidekiq-client-push-dynamic-queue
    Sidekiq::Client.push(class: ReportWorker, queue: params[:queue], args: [1])

    # ruleid: ruby-job-injection-sidekiq-client-push-dynamic-queue
    Sidekiq::Client.push("class" => ReportWorker, "queue" => params[:queue], "args" => [1])
  end

  def enqueue_safe
    # ok: ruby-job-injection-sidekiq-client-push-dynamic-queue
    Sidekiq::Client.push(class: ReportWorker, queue: "reports", args: [1])
  end
end
