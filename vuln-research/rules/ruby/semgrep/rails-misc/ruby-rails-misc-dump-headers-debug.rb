# Fixture for wholesale request header/env dump.

class DiagnosticsController < ApplicationController
  def headers
    # ruleid: ruby-rails-misc-dump-headers-debug
    render json: request.headers.to_h
  end

  def env_log
    # ruleid: ruby-rails-misc-dump-headers-debug
    Rails.logger.debug(request.env.to_json)
  end

  def headers_safe
    # ok: ruby-rails-misc-dump-headers-debug
    render json: { content_type: request.content_type, method: request.method }
  end
end
