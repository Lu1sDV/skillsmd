# Fixture for hardcoded Sidekiq Redis password.
# Flagged config inlines the password; the safe config sources it from the environment.

Sidekiq.configure_server do |config|
  # ruleid: ruby-hardcoded-secrets-sidekiq-redis-password
  config.redis = { url: "redis://cache.internal:6379/1", password: "S1dekiqRedisPass" }
end

Sidekiq.configure_client do |config|
  # ok: ruby-hardcoded-secrets-sidekiq-redis-password
  config.redis = { url: "redis://cache.internal:6379/1", password: ENV["REDIS_PASSWORD"] }
end
