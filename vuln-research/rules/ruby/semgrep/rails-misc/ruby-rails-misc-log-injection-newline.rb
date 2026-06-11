# Fixture for log forging via unsanitized input.

class AuditController < ApplicationController
  def track
    # ruleid: ruby-rails-misc-log-injection-newline
    Rails.logger.info("user searched for #{params[:q]}")
  end

  def track_safe
    clean = params[:q].to_s.gsub(/[\r\n]/, " ")
    # ok: ruby-rails-misc-log-injection-newline
    Rails.logger.info("user searched for #{clean}")
  end
end
