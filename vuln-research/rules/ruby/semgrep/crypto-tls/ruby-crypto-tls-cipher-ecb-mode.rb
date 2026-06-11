# Fixture for the ECB-mode cipher rule.

def seal(data, key)
  # ruleid: ruby-crypto-tls-cipher-ecb-mode
  cipher = OpenSSL::Cipher.new("aes-256-ecb")
  cipher.encrypt
  cipher.key = key
  cipher.update(data) + cipher.final
end

def seal_secure(data, key, iv)
  # ok: ruby-crypto-tls-cipher-ecb-mode
  cipher = OpenSSL::Cipher.new("aes-256-gcm")
  cipher.encrypt
  cipher.key = key
  cipher.iv = iv
  cipher.update(data) + cipher.final
end
