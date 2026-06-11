# Fixture for Devise post-auth path overrides returning tainted locations.

class ApplicationController < ActionController::Base
  # ruleid: ruby-open-redirect-devise-stored-location
  def after_sign_in_path_for(resource)
    session[:requested] = nil
    params[:redirect_to]
  end

  # ok: ruby-open-redirect-devise-stored-location
  def after_sign_out_path_for(resource)
    root_path
  end
end
