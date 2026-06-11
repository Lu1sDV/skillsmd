# Fixture for an inline PEM private key.
# Flagged heredoc embeds the key material; the safe line loads it from a file path.

class SigningKey
  def material
    # ruleid: ruby-hardcoded-secrets-private-key-pem
    pem = "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA\n-----END RSA PRIVATE KEY-----"

    # ok: ruby-hardcoded-secrets-private-key-pem
    pem_safe = File.read(ENV["SIGNING_KEY_PATH"])
    [pem, pem_safe]
  end
end
