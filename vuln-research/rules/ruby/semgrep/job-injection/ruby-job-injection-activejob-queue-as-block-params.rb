# Fixture for queue_as deriving the queue from job arguments.
# The flagged job routes by an argument value; the safe one routes by a constant.

class RoutedJob < ApplicationJob
  # ruleid: ruby-job-injection-activejob-queue-as-block-params
  queue_as do
    target = arguments.first
    target[:queue]
  end

  def perform(target); end
end

class FixedJob < ApplicationJob
  # ok: ruby-job-injection-activejob-queue-as-block-params
  queue_as do
    :default
  end

  def perform(record_id); end
end
