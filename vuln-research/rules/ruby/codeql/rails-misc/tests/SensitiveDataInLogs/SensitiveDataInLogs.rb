# Fixture for SensitiveDataInLogs (RB-QL-2517)
# Tests both sub-patterns:
#   1. AppLogger.info with a user_id: keyword argument
#   2. Sidekiq middleware logger.info that dumps job['args'] raw (no loggable_arguments)

module Gitlab
  module AppLogger
    def self.info(msg); end
    def self.warn(msg); end
    def self.error(msg); end
  end

  module Json
    def self.dump(obj); end
  end

  module ErrorTracking
    module Processor
      module SidekiqProcessor
        def self.loggable_arguments(args, klass); end
      end
    end
  end
end

# ---------------------------------------------------------------------------
# Case 1 — AppLogger with user_id: keyword argument
# ---------------------------------------------------------------------------

class PipelineAuthValidator
  def perform!(current_user, project)
    pipeline_authorized = true
    log_message = pipeline_authorized ? 'authorized' : 'not authorized'

    # BAD: raw user_id exposed in log
    Gitlab::AppLogger.info(message: "Pipeline #{log_message}", project_id: project.id, user_id: current_user.id) # $ ALERT

    # GOOD: user_id removed from log call
    Gitlab::AppLogger.info(message: "Pipeline #{log_message}", project_id: project.id)
  end
end

# ---------------------------------------------------------------------------
# Case 2 — Sidekiq middleware logs raw job['args'] without loggable_arguments
# ---------------------------------------------------------------------------

module BadArgumentsLogger
  include Sidekiq::ServerMiddleware

  def call(worker, job, queue)
    # BAD: dumps job['args'] directly into the log line
    logger.info "arguments: #{Gitlab::Json.dump(job['args'])}" # $ ALERT
    yield
  end
end

module GoodArgumentsLogger
  include Sidekiq::ServerMiddleware

  def call(worker, job, queue)
    # GOOD: filters through loggable_arguments before logging
    loggable_args = Gitlab::ErrorTracking::Processor::SidekiqProcessor.loggable_arguments(job['args'], job['class'])
    logger.info "arguments: #{Gitlab::Json.dump(loggable_args)}"
    yield
  end
end
