# Fixture for forging Sidekiq jobs by pushing raw items onto the Redis queue list.
# Flagged lines write request input directly to the queue; safe line uses the client API.

class RawQueueController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-sidekiq-raw-redis-lpush
    redis.lpush("queue:#{params[:queue]}", params[:payload])

    # ruleid: ruby-job-injection-sidekiq-raw-redis-lpush
    redis.rpush("queue:default", params[:payload])
  end

  def enqueue_safe
    # ok: ruby-job-injection-sidekiq-raw-redis-lpush
    HardenedWorker.perform_async(current_user.id)
  end
end
