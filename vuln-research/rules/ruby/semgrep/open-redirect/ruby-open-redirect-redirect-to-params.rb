# Fixture for the redirect_to-with-params rule.
# The first call leaks the destination to user input; the guarded calls are safe.

class SessionsController < ApplicationController
  def after_login
    # ruleid: ruby-open-redirect-redirect-to-params
    redirect_to params[:return_to]
  end

  def after_login_paren
    # ruleid: ruby-open-redirect-redirect-to-params
    redirect_to(params[:url])
  end

  def safe_fixed
    # ok: ruby-open-redirect-redirect-to-params
    redirect_to "/dashboard"
  end

  def safe_same_origin
    # ok: ruby-open-redirect-redirect-to-params
    redirect_to(params[:url], allow_other_host: false)
  end
end
