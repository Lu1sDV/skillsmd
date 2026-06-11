# Fixture for PRNG-derived cipher keys.

def build_cipher
  cipher = OpenSSL::Cipher.new("aes-256-cbc")
  cipher.encrypt
  # ruleid: ruby-insecure-randomness-rand-cipher-key
  cipher.key = Array.new(32) { rand(256) }.pack("C*")
  cipher
end

def build_cipher_secure
  cipher = OpenSSL::Cipher.new("aes-256-gcm")
  cipher.encrypt
  # ok: ruby-insecure-randomness-rand-cipher-key
  cipher.key = cipher.random_key
  cipher
end
