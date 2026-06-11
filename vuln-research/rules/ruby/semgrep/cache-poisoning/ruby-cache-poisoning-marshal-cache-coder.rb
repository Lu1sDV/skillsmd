# Fixture for cache store coder configuration.
# Flagged configs select the executing Marshal coder; safe config uses JSON.

module CacheConfig
  def self.setup(config)
    # ruleid: ruby-cache-poisoning-marshal-cache-coder
    config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"], coder: Marshal }

    # ruleid: ruby-cache-poisoning-marshal-cache-coder
    ActiveSupport::Cache::RedisCacheStore.new(coder: Marshal, url: ENV["REDIS_URL"])
  end

  def self.safe_setup(config)
    # ok: ruby-cache-poisoning-marshal-cache-coder
    config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"], coder: JSON }
  end
end
