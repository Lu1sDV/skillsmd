# Fixture for default_url_options host poisoning.

class ApplicationController < ActionController::Base
  before_action :set_host

  def set_host
    # ruleid: ruby-open-redirect-default-url-options-host
    default_url_options[:host] = request.host
  end

  def set_host_param
    # ruleid: ruby-open-redirect-default-url-options-host
    default_url_options[:host] = params[:host]
  end

  def set_host_safe
    # ok: ruby-open-redirect-default-url-options-host
    default_url_options[:host] = "app.example.com"
  end
end
