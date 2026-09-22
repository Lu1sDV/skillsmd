# Test fixtures for rb/auth-session-timing-unsafe-token-compare (CWE-208).

# BAD: OAuth application secret compared with == inside secret_matches? —
#      timing side-channel allows byte-by-byte secret recovery.
module Authn
  class OauthApplication
    def secret_matches?(input)
      return false if input.nil? || secret.nil?

      input == secret   # BAD: timing-unsafe == comparison of credential
    end
  end
end

# BAD: HMAC signature verified with == instead of secure_compare.
class WebhookVerifier
  def verify_signature?(payload, provided_signature)
    expected = OpenSSL::HMAC.hexdigest("SHA256", @secret_key, payload)
    provided_signature == expected   # BAD: timing-unsafe == on signature
  end
end

# BAD: API token checked with != (inverse of ==, same timing leak).
class ApiTokenAuthenticator
  def valid_token?(token)
    token != stored_token   # BAD: timing-unsafe != comparison of token
  end
end

# GOOD: uses Rack::Utils.secure_compare for constant-time comparison.
module Authn
  class SafeOauthApplication
    def secret_matches?(input)
      return false if input.nil? || secret.nil?

      ::Rack::Utils.secure_compare(input, secret)   # GOOD: constant-time
    end
  end
end

# GOOD: uses ActiveSupport::SecurityUtils.secure_compare.
class SafeWebhookVerifier
  def verify_signature?(payload, provided_signature)
    expected = OpenSSL::HMAC.hexdigest("SHA256", @secret_key, payload)
    ActiveSupport::SecurityUtils.secure_compare(provided_signature, expected)  # GOOD
  end
end

# GOOD: == comparison in a method that is NOT a credential comparator —
#       ordinary equality check, not a timing-sensitive secret.
class UserService
  def find_by_username?(name)
    name == stored_name   # GOOD: not a credential, method not in sensitive list
  end
end

# GOOD: == on a non-credential local variable inside a credential-named method
#       — variable name has no secret/token/signature hint.
class TokenService
  def valid_token?(provided)
    count == max_retries   # GOOD: comparing retry counters, not the token itself
  end
end
