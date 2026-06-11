# Fixture for the DES weak-cipher rule.

def encrypt(plaintext, key)
  # ruleid: ruby-crypto-tls-cipher-des
  cipher = OpenSSL::Cipher.new("DES-CBC")
  cipher.encrypt
  cipher.key = key
  cipher.update(plaintext) + cipher.final
end

def encrypt_secure(plaintext, key)
  # ok: ruby-crypto-tls-cipher-des
  cipher = OpenSSL::Cipher.new("aes-256-gcm")
  cipher.encrypt
  cipher.key = key
  cipher.update(plaintext) + cipher.final
end
