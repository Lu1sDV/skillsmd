# Fixture for the truncated SecureRandom entropy rule.

def short_token
  # ruleid: ruby-crypto-tls-securerandom-truncated
  SecureRandom.hex(4)
end

def strong_token
  # ok: ruby-crypto-tls-securerandom-truncated
  SecureRandom.hex(16)
end
