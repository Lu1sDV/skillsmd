# Fixture for digest-of-time token generation.

def confirm_token
  # ruleid: ruby-insecure-randomness-digest-time-token
  token = Digest::SHA1.hexdigest(Time.now.to_s)
  token
end

def confirm_token_secure
  # ok: ruby-insecure-randomness-digest-time-token
  token = Digest::SHA256.hexdigest(SecureRandom.bytes(32))
  token
end
