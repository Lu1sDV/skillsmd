# Fixture for the predictable-random token rule.

def reset_token
  # ruleid: ruby-crypto-tls-rand-for-token
  token = rand(1_000_000).to_s
  token
end

def reset_token_secure
  # ok: ruby-crypto-tls-rand-for-token
  token = SecureRandom.urlsafe_base64(32)
  token
end
