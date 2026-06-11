# Fixture for deserializing cache contents with the unsafe YAML loader.
# Flagged reads pass cached bytes to YAML.load; safe read uses safe_load.

class SettingsStore
  def load_blob(key)
    # ruleid: ruby-cache-poisoning-yaml-cache-coder
    YAML.load(Rails.cache.read(key))
  end

  def load_redis(redis, key)
    # ruleid: ruby-cache-poisoning-yaml-cache-coder
    YAML.load(redis.get(key))
  end

  def safe_load_blob(key)
    # ok: ruby-cache-poisoning-yaml-cache-coder
    YAML.safe_load(Rails.cache.read(key), permitted_classes: [Symbol])
  end
end
