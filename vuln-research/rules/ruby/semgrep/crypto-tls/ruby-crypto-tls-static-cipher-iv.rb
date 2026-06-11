# Fixture for the static cipher IV rule.

def encrypt(data, key)
  cipher = OpenSSL::Cipher.new("aes-256-cbc")
  cipher.encrypt
  cipher.key = key
  # ruleid: ruby-crypto-tls-static-cipher-iv
  cipher.iv = "0000000000000000"
  cipher.update(data) + cipher.final
end

def encrypt_secure(data, key)
  cipher = OpenSSL::Cipher.new("aes-256-cbc")
  cipher.encrypt
  cipher.key = key
  # ok: ruby-crypto-tls-static-cipher-iv
  cipher.iv = cipher.random_iv
  cipher.update(data) + cipher.final
end
