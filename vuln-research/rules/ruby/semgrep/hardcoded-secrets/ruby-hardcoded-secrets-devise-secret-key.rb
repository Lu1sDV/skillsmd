# Fixture for hardcoded Devise secret_key.
# Flagged line inlines the token-signing key; safe line sources it from the environment.

Devise.setup do |config|
  # ruleid: ruby-hardcoded-secrets-devise-secret-key
  config.secret_key = "f4e3d2c1b0a998877665544332211000ffeeddccbbaa99887766554433221100"

  # ok: ruby-hardcoded-secrets-devise-secret-key
  config.secret_key = ENV["DEVISE_SECRET_KEY"]
end
