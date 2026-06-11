# Fixture for redirects derived from the request Host header.

class TenantController < ApplicationController
  def switch
    # ruleid: ruby-open-redirect-redirect-to-request-host
    redirect_to "https://#{request.host}/tenants/switch"
  end

  def reload
    # ruleid: ruby-open-redirect-redirect-to-request-host
    redirect_to request.original_url
  end

  def safe_switch
    # ok: ruby-open-redirect-redirect-to-request-host
    redirect_to "https://app.example.com/tenants/switch"
  end
end
