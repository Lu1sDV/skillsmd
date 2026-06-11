# Fixture for PRNG-derived cipher IVs.

def encrypt(data, key)
  cipher = OpenSSL::Cipher.new("aes-256-cbc")
  cipher.encrypt
  cipher.key = key
  # ruleid: ruby-insecure-randomness-rand-iv
  cipher.iv = Array.new(16) { rand(256) }.pack("C*")
  cipher.update(data) + cipher.final
end

def encrypt_secure(data, key)
  cipher = OpenSSL::Cipher.new("aes-256-gcm")
  cipher.encrypt
  cipher.key = key
  # ok: ruby-insecure-randomness-rand-iv
  cipher.iv = cipher.random_iv
  cipher.update(data) + cipher.final
end
