# Fixture for a Redis URL with inline credentials.
# Flagged assignment embeds user:password in the URL; the safe line reads it from the environment.

class CacheConfig
  def client
    # ruleid: ruby-hardcoded-secrets-redis-url-credentials
    Redis.new(url: "redis://default:Sup3rR3disPass@cache.internal:6379/0")

    # ok: ruby-hardcoded-secrets-redis-url-credentials
    Redis.new(url: ENV["REDIS_URL"])
  end
end
