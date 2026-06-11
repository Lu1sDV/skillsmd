# Fixture for the host-header poisoning via default_url_options detector.

class ApplicationController < ActionController::Base
  before_action :set_mailer_host

  def set_mailer_host
    # ruleid: ruby-mail-header-injection-default-url-options-host
    default_url_options[:host] = request.host
  end

  def set_from_param
    # ruleid: ruby-mail-header-injection-default-url-options-host
    default_url_options[:host] = params[:host]
  end

  def set_mailer_host_safe
    # ok: ruby-mail-header-injection-default-url-options-host
    default_url_options[:host] = Rails.application.config.canonical_host
  end
end
