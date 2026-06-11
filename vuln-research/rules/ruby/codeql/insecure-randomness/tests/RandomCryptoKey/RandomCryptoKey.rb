require "openssl"
require "securerandom"

# Insecure: a predictable random value is fed into a cryptographic operation.
nonce = rand(2 ** 128)
cipher = OpenSSL::Cipher.new("aes-128-cbc")
cipher.encrypt
cipher.key = "0" * 16
ct = cipher.update(nonce.to_s)

# Safe: a cryptographically secure value is used instead.
secure = SecureRandom.bytes(16)
c2 = OpenSSL::Cipher.new("aes-128-cbc")
c2.encrypt
c2.key = "0" * 16
ct2 = c2.update(secure)
