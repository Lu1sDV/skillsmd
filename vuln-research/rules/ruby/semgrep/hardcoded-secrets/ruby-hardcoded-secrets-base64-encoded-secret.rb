# Fixture for a Base64-encoded secret masquerading as protected.
# Flagged call decodes a literal; the safe call decodes a value sourced from the environment.

class KeyLoader
  def signing_key
    # ruleid: ruby-hardcoded-secrets-base64-encoded-secret
    Base64.decode64("c3VwZXItc2VjcmV0LXNpZ25pbmcta2V5LXZhbHVl")
  end

  def signing_key_safe
    # ok: ruby-hardcoded-secrets-base64-encoded-secret
    Base64.decode64(ENV["SIGNING_KEY_B64"])
  end
end
