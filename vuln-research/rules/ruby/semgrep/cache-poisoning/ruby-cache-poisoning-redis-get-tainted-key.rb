# Fixture for Redis reads under an attacker-influenced key.
# Flagged reads take the key from params; safe read namespaces by user id.

class SessionStore
  def initialize(redis)
    @redis = redis
  end

  def lookup(params)
    # ruleid: ruby-cache-poisoning-redis-get-tainted-key
    @redis.get(params[:session_id])
  end

  def lookup_iv(params)
    # ruleid: ruby-cache-poisoning-redis-get-tainted-key
    @redis.get("sess:#{params[:id]}")
  end

  def safe_lookup(user)
    # ok: ruby-cache-poisoning-redis-get-tainted-key
    @redis.get("sess:#{user.id}")
  end
end
