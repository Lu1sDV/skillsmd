# Fixture for reading cache entries under an attacker-influenced key.
# Flagged reads take the key from request data; safe read scopes by server id.

class ProfileController < ApplicationController
  def show
    # ruleid: ruby-cache-poisoning-rails-cache-read-tainted-key
    Rails.cache.read(params[:cache_key])

    # ruleid: ruby-cache-poisoning-rails-cache-read-tainted-key
    Rails.cache.read("profile/#{params[:id]}")
  end

  def safe_show
    # ok: ruby-cache-poisoning-rails-cache-read-tainted-key
    Rails.cache.read("profile/#{current_user.id}")
  end
end
