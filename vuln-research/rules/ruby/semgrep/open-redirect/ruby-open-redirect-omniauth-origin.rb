# Fixture for OmniAuth post-login origin redirects.

class OmniauthCallbacksController < ApplicationController
  def github
    sign_in(@user)
    # ruleid: ruby-open-redirect-omniauth-origin
    redirect_to request.env["omniauth.origin"]
  end

  def google
    sign_in(@user)
    # ruleid: ruby-open-redirect-omniauth-origin
    redirect_to params[:return_to]
  end

  def safe_callback
    sign_in(@user)
    # ok: ruby-open-redirect-omniauth-origin
    redirect_to dashboard_path
  end
end
