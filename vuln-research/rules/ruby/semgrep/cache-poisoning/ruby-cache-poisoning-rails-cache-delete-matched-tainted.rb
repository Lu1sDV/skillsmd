# Fixture for pattern-based cache invalidation from request data.
# Flagged calls take the match pattern from params; safe call uses a fixed glob.

class CacheAdminController < ApplicationController
  def purge
    # ruleid: ruby-cache-poisoning-rails-cache-delete-matched-tainted
    Rails.cache.delete_matched(params[:pattern])

    # ruleid: ruby-cache-poisoning-rails-cache-delete-matched-tainted
    Rails.cache.delete_matched("views/#{params[:scope]}/*")
  end

  def safe_purge
    # ok: ruby-cache-poisoning-rails-cache-delete-matched-tainted
    Rails.cache.delete_matched("views/account-#{current_user.id}/*")
  end
end
