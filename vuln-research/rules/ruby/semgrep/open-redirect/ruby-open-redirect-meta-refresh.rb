# Fixture for meta-refresh client-side redirects.

class GatewayController < ApplicationController
  def bounce
    # ruleid: ruby-open-redirect-meta-refresh
    html = "<meta http-equiv=\"refresh\" content=\"0;url=#{params[:url]}\">"
    render html: html.html_safe
  end

  def safe_message(user)
    # ok: ruby-open-redirect-meta-refresh
    greeting = "<p>Welcome back #{user.name}</p>"
    render html: greeting.html_safe
  end
end
