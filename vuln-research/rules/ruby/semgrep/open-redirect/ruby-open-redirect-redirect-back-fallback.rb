# Fixture for redirect_back fallback poisoning.

class ProfileController < ApplicationController
  def update
    # ruleid: ruby-open-redirect-redirect-back-fallback
    redirect_back(fallback_location: params[:return])
  end

  def destroy
    # ruleid: ruby-open-redirect-redirect-back-fallback
    redirect_back(fallback_location: params[:next], allow_other_host: false)
  end

  def safe_update
    # ok: ruby-open-redirect-redirect-back-fallback
    redirect_back(fallback_location: root_path)
  end
end
