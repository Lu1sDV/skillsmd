# Fixture for auth-token attributes assigned from rand.

def start_reset(user)
  # ruleid: ruby-insecure-randomness-rand-reset-attribute
  user.reset_token = rand(10**10)
  user.save!
end

def start_reset_secure(user)
  # ok: ruby-insecure-randomness-rand-reset-attribute
  user.reset_token = SecureRandom.urlsafe_base64(32)
  user.save!
end

def set_lottery(user)
  # ok: ruby-insecure-randomness-rand-reset-attribute
  user.lucky_number = rand(100)
  user.save!
end
