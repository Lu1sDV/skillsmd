# Fixture for the BCrypt low-cost rule.

def hash_password(password)
  # ruleid: ruby-crypto-tls-bcrypt-low-cost
  BCrypt::Password.create(password, cost: 4)
end

def hash_password_secure(password)
  # ok: ruby-crypto-tls-bcrypt-low-cost
  BCrypt::Password.create(password, cost: 13)
end
