# Fixture for the PBKDF2 low-iteration rule.

def derive(password, salt)
  # ruleid: ruby-crypto-tls-pbkdf2-low-iterations
  OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 1000, 32, "sha256")
end

def derive_secure(password, salt)
  # ok: ruby-crypto-tls-pbkdf2-low-iterations
  OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 600000, 32, "sha256")
end
