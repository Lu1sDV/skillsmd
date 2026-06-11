# Fixture for the hardcoded secret_key_base detector.

# ruleid: ruby-auth-session-hardcoded-secret-key-base
Rails.application.secret_key_base = "0a1b2c3d4e5f6071829304a5b6c7d8e9"

# ok: ruby-auth-session-hardcoded-secret-key-base
Rails.application.secret_key_base = ENV.fetch("SECRET_KEY_BASE")
