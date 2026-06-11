# Fixture for a hardcoded Devise pepper.
# Flagged line inlines the pepper; the safe line sources it from the environment.

Devise.setup do |config|
  # ruleid: ruby-hardcoded-secrets-warden-secret
  config.pepper = "aa11bb22cc33dd44ee55ff66aa77bb88cc99dd00ee11ff22aa33bb44cc55dd66"

  # ok: ruby-hardcoded-secrets-warden-secret
  config.pepper = ENV["DEVISE_PEPPER"]
end
