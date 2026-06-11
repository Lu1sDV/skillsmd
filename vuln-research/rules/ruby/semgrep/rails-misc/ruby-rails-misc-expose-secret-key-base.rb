# Fixture for secret_key_base disclosure.

class AdminDebugController < ApplicationController
  def show
    # ruleid: ruby-rails-misc-expose-secret-key-base
    render plain: Rails.application.secret_key_base
  end

  def dump_creds
    # ruleid: ruby-rails-misc-expose-secret-key-base
    render json: Rails.application.credentials.config
  end

  def show_safe
    # ok: ruby-rails-misc-expose-secret-key-base
    render plain: Rails.application.config.x.build_sha
  end
end
