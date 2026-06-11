# Fixture for the public caching of user content rule.

class ProfilesController < ApplicationController
  def show
    # ruleid: ruby-secure-config-public-caching-user-content
    expires_in 5.minutes, public: true
    render :show
  end

  def public_page
    # ok: ruby-secure-config-public-caching-user-content
    expires_in 5.minutes, public: false
    render :public_page
  end
end
