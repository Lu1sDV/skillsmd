# Fixture for under-sized SecureRandom tokens.

def api_key
  # ruleid: ruby-insecure-randomness-securerandom-truncated-hex
  key = SecureRandom.hex(4)
  key
end

def api_key_secure
  # ok: ruby-insecure-randomness-securerandom-truncated-hex
  key = SecureRandom.hex(32)
  key
end
