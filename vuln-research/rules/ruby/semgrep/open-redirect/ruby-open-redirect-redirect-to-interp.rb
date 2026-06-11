# Fixture for interpolated redirect_to targets.

class ReturnController < ApplicationController
  def go
    # ruleid: ruby-open-redirect-redirect-to-interp
    redirect_to "#{params[:next]}"
  end

  def go_paren
    # ruleid: ruby-open-redirect-redirect-to-interp
    redirect_to("https://#{params[:host]}/welcome")
  end

  def safe_relative
    # ok: ruby-open-redirect-redirect-to-interp
    redirect_to "/users/#{current_user.id}"
  end
end
