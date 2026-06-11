# Fixture for blob URL host taken from the request.

class ApplicationController < ActionController::Base
  def set_storage_host
    # ruleid: ruby-rails-misc-active-storage-host-from-request
    ActiveStorage::Current.url_options = { host: request.host }
  end

  def set_storage_host_attr
    # ruleid: ruby-rails-misc-active-storage-host-from-request
    ActiveStorage::Current.host = request.host
  end

  def set_storage_host_safe
    # ok: ruby-rails-misc-active-storage-host-from-request
    ActiveStorage::Current.url_options = { host: Rails.application.config.canonical_host }
  end
end
