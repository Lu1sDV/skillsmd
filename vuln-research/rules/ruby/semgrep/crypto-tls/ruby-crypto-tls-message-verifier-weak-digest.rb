# Fixture for the MessageVerifier weak digest rule.

def verifier(secret)
  # ruleid: ruby-crypto-tls-message-verifier-weak-digest
  ActiveSupport::MessageVerifier.new(secret, digest: "SHA1")
end

def verifier_secure(secret)
  # ok: ruby-crypto-tls-message-verifier-weak-digest
  ActiveSupport::MessageVerifier.new(secret, digest: "SHA256")
end
