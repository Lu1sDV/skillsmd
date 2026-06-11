# Fixture for raw bytes from the non-cryptographic generator.

def make_key
  # ruleid: ruby-insecure-randomness-default-prng-bytes
  key = Random.bytes(32)
  key
end

def make_key_secure
  # ok: ruby-insecure-randomness-default-prng-bytes
  key = SecureRandom.bytes(32)
  key
end
