# Fixture for clock-derived identifiers.

def new_token
  # ruleid: ruby-insecure-randomness-timestamp-token
  token_id = Time.now.to_i
  token_id.to_s
end

def new_token_secure
  # ok: ruby-insecure-randomness-timestamp-token
  token_id = SecureRandom.uuid
  token_id
end

def log_started_at
  # ok: ruby-insecure-randomness-timestamp-token
  started_at = Time.now.to_i
  started_at
end
