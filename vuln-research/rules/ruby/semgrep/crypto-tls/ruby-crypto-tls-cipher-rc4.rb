# Fixture for the RC4 weak-cipher rule.

def obfuscate(data, key)
  # ruleid: ruby-crypto-tls-cipher-rc4
  cipher = OpenSSL::Cipher.new("RC4")
  cipher.encrypt
  cipher.key = key
  cipher.update(data) + cipher.final
end

def obfuscate_secure(data, key)
  # ok: ruby-crypto-tls-cipher-rc4
  cipher = OpenSSL::Cipher.new("chacha20-poly1305")
  cipher.encrypt
  cipher.key = key
  cipher.update(data) + cipher.final
end
