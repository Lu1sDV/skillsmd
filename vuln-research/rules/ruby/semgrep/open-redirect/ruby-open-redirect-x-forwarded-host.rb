# Fixture for X-Forwarded-Host driven URL construction.

class PasswordsController < ApplicationController
  def create
    # ruleid: ruby-open-redirect-x-forwarded-host
    host = request.headers["X-Forwarded-Host"]
    UserMailer.reset(@user, "https://#{host}/reset").deliver_later
  end

  def create_env
    # ruleid: ruby-open-redirect-x-forwarded-host
    host = request.env["HTTP_X_FORWARDED_HOST"]
    UserMailer.reset(@user, "https://#{host}/reset").deliver_later
  end

  def create_safe
    # ok: ruby-open-redirect-x-forwarded-host
    host = Rails.application.config.canonical_host
    UserMailer.reset(@user, "https://#{host}/reset").deliver_later
  end
end
