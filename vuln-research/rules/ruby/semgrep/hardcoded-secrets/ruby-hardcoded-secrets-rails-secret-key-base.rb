# Fixture for hardcoded Rails secret_key_base.
# Flagged assignments inline the master secret; the safe line reads it from the environment.

Rails.application.configure do
  # ruleid: ruby-hardcoded-secrets-rails-secret-key-base
  config.secret_key_base = "0a1b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcdef"

  # ok: ruby-hardcoded-secrets-rails-secret-key-base
  config.secret_key_base = ENV["SECRET_KEY_BASE"]
end
