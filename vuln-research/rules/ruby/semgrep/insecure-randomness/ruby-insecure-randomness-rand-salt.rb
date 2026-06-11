# Fixture for PRNG-derived KDF salts.

def hash_password(pw)
  # ruleid: ruby-insecure-randomness-rand-salt
  salt = rand(2**32).to_s
  OpenSSL::PKCS5.pbkdf2_hmac(pw, salt, 100_000, 32, "sha256")
end

def hash_password_secure(pw)
  # ok: ruby-insecure-randomness-rand-salt
  salt = SecureRandom.bytes(16)
  OpenSSL::PKCS5.pbkdf2_hmac(pw, salt, 100_000, 32, "sha256")
end
