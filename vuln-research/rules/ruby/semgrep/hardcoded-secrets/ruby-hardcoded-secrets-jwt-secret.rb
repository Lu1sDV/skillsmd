# Fixture for hardcoded JWT signing secret.
# Flagged calls hand JWT a literal HMAC key; safe calls read it from the environment.

class TokenService
  def issue(payload)
    # ruleid: ruby-hardcoded-secrets-jwt-secret
    JWT.encode(payload, "my-hardcoded-jwt-signing-key", "HS256")
  end

  def verify(token)
    # ruleid: ruby-hardcoded-secrets-jwt-secret
    JWT.decode(token, "my-hardcoded-jwt-signing-key", true, algorithm: "HS256")
  end

  def issue_safe(payload)
    # ok: ruby-hardcoded-secrets-jwt-secret
    JWT.encode(payload, ENV["JWT_SECRET"], "HS256")
  end
end
