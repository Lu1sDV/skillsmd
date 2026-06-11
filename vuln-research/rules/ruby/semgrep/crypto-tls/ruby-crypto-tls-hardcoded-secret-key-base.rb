# Fixture for the hardcoded secret_key_base rule.

def configure(config)
  # ruleid: ruby-crypto-tls-hardcoded-secret-key-base
  config.secret_key_base = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6"
end

def configure_secure(config)
  # ok: ruby-crypto-tls-hardcoded-secret-key-base
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")
end
