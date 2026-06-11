# Fixture for Kernel#rand feeding a security-sensitive value.

def issue_reset
  # ruleid: ruby-insecure-randomness-rand-token-assignment
  reset_token = rand(1_000_000)
  store(reset_token)
end

def issue_reset_secure
  # ok: ruby-insecure-randomness-rand-token-assignment
  reset_token = SecureRandom.urlsafe_base64(32)
  store(reset_token)
end

def dice_roll
  # ok: ruby-insecure-randomness-rand-token-assignment
  roll = rand(6)
  roll + 1
end
