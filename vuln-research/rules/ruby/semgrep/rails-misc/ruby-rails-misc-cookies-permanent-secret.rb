# Fixture for sensitive value in a plain cookie.

class TokensController < ApplicationController
  def issue
    # ruleid: ruby-rails-misc-cookies-permanent-secret
    cookies.permanent[:auth_token] = generate_token
  end

  def issue_plain
    # ruleid: ruby-rails-misc-cookies-permanent-secret
    cookies[:auth_token] = generate_token
  end

  def issue_safe
    # ok: ruby-rails-misc-cookies-permanent-secret
    cookies.encrypted[:auth_token] = { value: generate_token, expires: 1.hour }
  end
end
