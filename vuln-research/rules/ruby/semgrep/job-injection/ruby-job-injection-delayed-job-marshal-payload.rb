# Fixture for Delayed::Job payloads built from unmarshalled bytes.
# Flagged lines reconstruct a handler from Marshal/YAML; safe line enqueues a plain object.

class DelayedController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-delayed-job-marshal-payload
    Delayed::Job.enqueue(Marshal.load(stored_blob))

    # ruleid: ruby-job-injection-delayed-job-marshal-payload
    Delayed::Job.enqueue(YAML.unsafe_load(stored_yaml))
  end

  def enqueue_safe
    # ok: ruby-job-injection-delayed-job-marshal-payload
    Delayed::Job.enqueue(NotificationJob.new(current_user.id))
  end
end
