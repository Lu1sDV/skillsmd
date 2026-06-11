# Fixture for cache invalidation under an attacker-influenced key.
# Flagged deletes take the key from params; safe delete scopes by user id.

class InvalidationController < ApplicationController
  def purge
    # ruleid: ruby-cache-poisoning-cache-delete-tainted-key
    Rails.cache.delete(params[:key])

    # ruleid: ruby-cache-poisoning-cache-delete-tainted-key
    Rails.cache.delete("profile/#{params[:id]}")
  end

  def safe_purge
    # ok: ruby-cache-poisoning-cache-delete-tainted-key
    Rails.cache.delete("profile/#{current_user.id}")
  end
end
