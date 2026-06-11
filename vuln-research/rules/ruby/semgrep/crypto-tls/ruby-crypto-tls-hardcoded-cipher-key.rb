# Fixture for the hardcoded cipher key rule.

def encrypt(data)
  cipher = OpenSSL::Cipher.new("aes-256-cbc")
  cipher.encrypt
  # ruleid: ruby-crypto-tls-hardcoded-cipher-key
  cipher.key = "this_is_a_hardcoded_32_byte_key!"
  cipher.update(data) + cipher.final
end

def encrypt_secure(data)
  cipher = OpenSSL::Cipher.new("aes-256-cbc")
  cipher.encrypt
  # ok: ruby-crypto-tls-hardcoded-cipher-key
  cipher.key = ENV.fetch("DATA_ENCRYPTION_KEY")
  cipher.update(data) + cipher.final
end
