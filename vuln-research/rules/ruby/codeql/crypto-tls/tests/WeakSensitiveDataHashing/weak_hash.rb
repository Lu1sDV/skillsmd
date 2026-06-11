require "digest"
require "openssl"

class Account
  # True positive: a password is hashed with the broken MD5 algorithm.
  def store_password(password)
    digest = Digest::MD5.hexdigest(password)
    digest
  end

  # True positive: a secret token hashed with weak SHA1.
  def fingerprint_token(token)
    OpenSSL::Digest::SHA1.hexdigest(token)
  end

  # Safe: a strong SHA-256 digest of a non-sensitive file body, no sensitive source.
  def checksum(file_body)
    Digest::SHA256.hexdigest(file_body)
  end
end
