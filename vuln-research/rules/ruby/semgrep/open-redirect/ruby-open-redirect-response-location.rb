# Fixture for response.location assignment.

class GatewayController < ApplicationController
  def proxy
    # ruleid: ruby-open-redirect-response-location
    response.location = params[:target]
    self.status = 302
  end

  def proxy_interp
    # ruleid: ruby-open-redirect-response-location
    response.location = "https://#{params[:host]}/cb"
  end

  def safe_proxy
    # ok: ruby-open-redirect-response-location
    response.location = "/home"
  end
end
