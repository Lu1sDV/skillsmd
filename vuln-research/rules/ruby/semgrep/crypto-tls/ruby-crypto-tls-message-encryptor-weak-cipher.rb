# Fixture for the MessageEncryptor non-AEAD cipher rule.

def encryptor(secret)
  # ruleid: ruby-crypto-tls-message-encryptor-weak-cipher
  ActiveSupport::MessageEncryptor.new(secret, cipher: "aes-256-cbc")
end

def encryptor_secure(secret)
  # ok: ruby-crypto-tls-message-encryptor-weak-cipher
  ActiveSupport::MessageEncryptor.new(secret, cipher: "aes-256-gcm")
end
