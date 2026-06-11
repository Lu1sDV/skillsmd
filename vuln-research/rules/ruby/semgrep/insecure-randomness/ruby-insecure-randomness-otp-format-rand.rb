# Fixture for numeric OTP generation via rand.

def send_otp(user)
  # ruleid: ruby-insecure-randomness-otp-format-rand
  code = format("%06d", rand(1_000_000))
  deliver(user, code)
end

def send_otp_secure(user)
  # ok: ruby-insecure-randomness-otp-format-rand
  code = format("%06d", SecureRandom.random_number(1_000_000))
  deliver(user, code)
end
