# Fixture for dynamic Sidekiq class dispatch via Client.push.
# Flagged lines take the worker class from params; safe line names a fixed worker.

class PushController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-sidekiq-client-push-dynamic-class
    Sidekiq::Client.push(class: params[:worker], queue: "default", args: [1])

    # ruleid: ruby-job-injection-sidekiq-client-push-dynamic-class
    Sidekiq::Client.push("class" => params[:worker], "queue" => "default", "args" => [1])
  end

  def enqueue_safe
    # ok: ruby-job-injection-sidekiq-client-push-dynamic-class
    Sidekiq::Client.push(class: EmailWorker, queue: "default", args: [1])
  end
end
