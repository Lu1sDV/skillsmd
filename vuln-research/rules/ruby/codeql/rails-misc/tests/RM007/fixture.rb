# frozen_string_literal: true

# Simulated helpers
module Gitlab
  module AuthLogger
    def self.error(payload); end
    def self.warn(payload); end
    def self.info(payload); end
  end
end

module Rails
  def self.logger; @logger ||= Logger.new($stdout); end
end

class ApplicationController
  def request
    @request ||= ActionDispatch::Request.new({})
  end

  # BAD: request.fullpath passes raw query string to auth logger
  def log_blocked_bad
    Gitlab::AuthLogger.error(
      env: :blocklist,
      remote_ip: "127.0.0.1",
      request_method: "GET",
      path: request.fullpath
    )
  end

  # BAD: request.fullpath passed to Rails.logger
  def log_rate_limit_bad
    Rails.logger.warn(
      message: "rate limited",
      path: request.fullpath,
      user_id: 42
    )
  end

  # GOOD: request.filtered_path used instead — tokens are masked
  def log_blocked_good
    Gitlab::AuthLogger.error(
      env: :blocklist,
      remote_ip: "127.0.0.1",
      request_method: "GET",
      path: request.filtered_path
    )
  end

  # GOOD: only non-sensitive parts logged
  def log_path_only
    Rails.logger.info(
      message: "page visited",
      path: request.path
    )
  end
end

class RateLimiter
  def initialize(req)
    @request = req
  end

  # BAD: fullpath via instance variable reader
  def log_bad
    Rails.logger.info(
      env: :rate_limited,
      path: @request.fullpath
    )
  end
end
