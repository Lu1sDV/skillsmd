# Fixture for hardcoded MessageVerifier/MessageEncryptor secret.
# Flagged constructors inline the secret; the safe one derives it from credentials.

class TokenSealer
  def verifier
    # ruleid: ruby-hardcoded-secrets-message-verifier-secret
    ActiveSupport::MessageVerifier.new("static-signing-secret-deadbeef-cafe", serializer: JSON)
  end

  def encryptor
    # ruleid: ruby-hardcoded-secrets-message-verifier-secret
    ActiveSupport::MessageEncryptor.new("static-32-byte-encryption-key!!!")
  end

  def verifier_safe
    # ok: ruby-hardcoded-secrets-message-verifier-secret
    ActiveSupport::MessageVerifier.new(ENV["VERIFIER_SECRET"], serializer: JSON)
  end
end
