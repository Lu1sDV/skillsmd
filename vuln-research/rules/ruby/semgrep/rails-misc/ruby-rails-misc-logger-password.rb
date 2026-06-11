# Fixture for secret values written to the log.

class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    # ruleid: ruby-rails-misc-logger-password
    Rails.logger.info("login attempt pw=#{params[:password]}")
    sign_in(user)
  end

  def debug_token(account)
    # ruleid: ruby-rails-misc-logger-password
    Rails.logger.debug("calling api with #{account.api_key}")
  end

  def create_safe
    # ok: ruby-rails-misc-logger-password
    Rails.logger.info("login attempt for #{params[:email]}")
  end
end
