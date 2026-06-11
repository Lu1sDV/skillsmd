# Fixture for the Marshal.load rule.
# The flagged lines reconstruct objects from external bytes; the safe line uses a literal.

def restore_session(blob)
  # ruleid: ruby-deserialization-marshal-load
  Marshal.load(blob)
end

def restore_from_cache(key)
  data = Rails.cache.read(key)
  # ruleid: ruby-deserialization-marshal-load
  Marshal.load(data)
end

def fixed_fixture
  # ok: ruby-deserialization-marshal-load
  Marshal.load("\x04\b0")
end
