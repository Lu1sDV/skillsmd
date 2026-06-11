# Fixture for an ENV secret lookup that falls back to a hardcoded default.
# Flagged lines default to a literal secret; the safe lines fail loudly when unset.

class Settings
  def api_secret
    # ruleid: ruby-hardcoded-secrets-env-default-password
    ENV["API_SECRET"] || "fallback-default-secret-value"
  end

  def signing_password
    # ruleid: ruby-hardcoded-secrets-env-default-password
    ENV.fetch("SIGNING_PASSWORD", "default-signing-pass")
  end

  def required_secret
    # ok: ruby-hardcoded-secrets-env-default-password
    ENV.fetch("API_SECRET")
  end

  def non_secret_default
    # ok: ruby-hardcoded-secrets-env-default-password
    ENV["APP_HOST"] || "localhost"
  end
end
