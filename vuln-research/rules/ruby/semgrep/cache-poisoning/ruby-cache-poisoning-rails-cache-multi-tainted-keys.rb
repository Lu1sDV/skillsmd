# Fixture for bulk cache access keyed on request data.
# Flagged calls splat param-derived keys; safe call uses ids from records.

class BulkController < ApplicationController
  def fetch_all
    # ruleid: ruby-cache-poisoning-rails-cache-multi-tainted-keys
    Rails.cache.read_multi(*params[:keys])

    # ruleid: ruby-cache-poisoning-rails-cache-multi-tainted-keys
    Rails.cache.read_multi(params[:a], params[:b])
  end

  def safe_fetch_all
    keys = current_user.records.map { |r| "rec/#{r.id}" }
    # ok: ruby-cache-poisoning-rails-cache-multi-tainted-keys
    Rails.cache.read_multi(*keys)
  end
end
