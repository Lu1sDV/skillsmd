# Fixture for counter mutation under an attacker-influenced key.
# Flagged calls take the counter key from params; safe call uses a user id.

class RateLimitController < ApplicationController
  def bump
    # ruleid: ruby-cache-poisoning-rails-cache-counter-tainted-key
    Rails.cache.increment(params[:bucket])

    # ruleid: ruby-cache-poisoning-rails-cache-counter-tainted-key
    Rails.cache.decrement("quota/#{params[:tenant]}")
  end

  def safe_bump
    # ok: ruby-cache-poisoning-rails-cache-counter-tainted-key
    Rails.cache.increment("quota/#{current_user.id}")
  end
end
