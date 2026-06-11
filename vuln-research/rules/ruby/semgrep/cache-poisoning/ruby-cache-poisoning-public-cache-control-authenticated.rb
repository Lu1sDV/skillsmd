# Fixture for Cache-Control directives on authenticated responses.
# Flagged lines mark the response publicly cacheable; safe line keeps it private.

class AccountController < ApplicationController
  before_action :authenticate_user!

  def statement
    @data = current_user.statement
    # ruleid: ruby-cache-poisoning-public-cache-control-authenticated
    response.headers["Cache-Control"] = "public, max-age=600"
  end

  def invoice
    @data = current_user.invoice
    # ruleid: ruby-cache-poisoning-public-cache-control-authenticated
    response.cache_control[:public] = true
  end

  def safe_statement
    @data = current_user.statement
    # ok: ruby-cache-poisoning-public-cache-control-authenticated
    response.headers["Cache-Control"] = "private, no-store"
  end
end
