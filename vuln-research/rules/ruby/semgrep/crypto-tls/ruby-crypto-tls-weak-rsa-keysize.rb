# Fixture for the weak RSA key size rule.

def weak_key
  # ruleid: ruby-crypto-tls-weak-rsa-keysize
  OpenSSL::PKey::RSA.new(1024)
end

def strong_key
  # ok: ruby-crypto-tls-weak-rsa-keysize
  OpenSSL::PKey::RSA.new(3072)
end
