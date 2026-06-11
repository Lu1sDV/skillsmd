# Fixture for the SHA-1 weak-hash rule.

def cert_fingerprint(certificate)
  # ruleid: ruby-crypto-tls-sha1-digest
  OpenSSL::Digest.new("SHA1").digest(certificate)
end

def sign(data)
  # ruleid: ruby-crypto-tls-sha1-digest
  Digest::SHA1.hexdigest(data)
end

def cert_fingerprint_secure(certificate)
  # ok: ruby-crypto-tls-sha1-digest
  OpenSSL::Digest.new("SHA256").digest(certificate)
end
