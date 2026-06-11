# Fixture for Redis writes under an attacker-influenced key.
# Flagged writes take the key from params; safe write namespaces by user id.

class TokenStore
  def initialize(redis)
    @redis = redis
  end

  def save(params)
    # ruleid: ruby-cache-poisoning-redis-set-tainted-key
    @redis.set(params[:token_key], "1")

    # ruleid: ruby-cache-poisoning-redis-set-tainted-key
    @redis.setex("tok:#{params[:id]}", 60, "1")
  end

  def safe_save(user)
    # ok: ruby-cache-poisoning-redis-set-tainted-key
    @redis.set("tok:#{user.id}", "1")
  end
end
