# Fixture for redirect targets pulled from the session return path.

class SessionsController < ApplicationController
  def create
    sign_in(@user)
    # ruleid: ruby-open-redirect-session-return-path
    redirect_to session[:return_to]
  end

  def create_paren
    sign_in(@user)
    # ruleid: ruby-open-redirect-session-return-path
    redirect_to(session[:forward_url])
  end

  def create_safe
    sign_in(@user)
    # ok: ruby-open-redirect-session-return-path
    redirect_to root_path
  end
end
