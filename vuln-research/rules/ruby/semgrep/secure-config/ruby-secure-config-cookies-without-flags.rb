# Fixture for the unflagged persistent cookie rule.

class TokenController < ApplicationController
  def create
    # ruleid: ruby-secure-config-cookies-without-flags
    cookies.permanent[:auth] = current_user.api_token
  end

  def create_signed
    # ok: ruby-secure-config-cookies-without-flags
    cookies.permanent.encrypted[:auth] = current_user.api_token
  end
end
