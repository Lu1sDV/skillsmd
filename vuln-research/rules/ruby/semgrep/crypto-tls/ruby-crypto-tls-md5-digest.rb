# Fixture for the MD5 weak-hash rule.

def fingerprint(password)
  # ruleid: ruby-crypto-tls-md5-digest
  Digest::MD5.hexdigest(password)
end

def digest_md5(data)
  # ruleid: ruby-crypto-tls-md5-digest
  OpenSSL::Digest.new("MD5").digest(data)
end

def fingerprint_secure(password)
  # ok: ruby-crypto-tls-md5-digest
  Digest::SHA256.hexdigest(password)
end
