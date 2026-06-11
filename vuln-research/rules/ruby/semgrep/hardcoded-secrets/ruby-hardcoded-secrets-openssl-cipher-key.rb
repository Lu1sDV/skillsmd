# Fixture for hardcoded OpenSSL cipher key material.
# Flagged assignment inlines the symmetric key; the safe line derives it from a secret.

class Encryptor
  def cipher
    c = OpenSSL::Cipher.new("aes-256-cbc")
    c.encrypt
    # ruleid: ruby-hardcoded-secrets-openssl-cipher-key
    c.key = "0123456789abcdef0123456789abcdef"
    c
  end

  def cipher_safe
    c = OpenSSL::Cipher.new("aes-256-cbc")
    c.encrypt
    # ok: ruby-hardcoded-secrets-openssl-cipher-key
    c.key = OpenSSL::PKCS5.pbkdf2_hmac(ENV["MASTER_SECRET"], salt, 20_000, 32, "sha256")
    c
  end
end
